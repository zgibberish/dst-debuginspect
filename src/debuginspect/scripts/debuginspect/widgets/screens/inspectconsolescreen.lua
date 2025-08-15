local DIConstants = require "debuginspect.constants"
local DITextEdit = require "debuginspect.widgets.textedit"
local TextEdit = require "widgets.textedit" --NOTE: need this to use TextEdit.OnRawKey
local Image = require "widgets.image"
local Screen = require "widgets.screen"
local Text = require "widgets.text"

local InspectConsoleScreen = Class(Screen, function(self)
	Screen._ctor(self, "InspectConsoleScreen")

	self.can_remote_execute = TheNet and TheNet:GetIsClient() and (TheNet:GetIsServerAdmin() or IsConsole())
	self.remote_execute = false
	self.ctrl_pasting = false -- so remote execute doesnt toggle when you RELEASE CTRL after pasting
	self.history_idx = nil

	self.ITEM_HEIGHT = 24
	self.ITEM_PADDING = 3

	local region_w = RESOLUTION_X/2
	local region_h = self.ITEM_HEIGHT*2 + self.ITEM_PADDING*3
	self.root = self:AddChild(Image("images/global.xml", "square.tex"))
	self.root:SetHAnchor(ANCHOR_MIDDLE)
	self.root:SetVAnchor(ANCHOR_MIDDLE)
	self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
	self.root:SetSize(region_w, region_h)
	self.root:SetTint(unpack(DIConstants.COLORS.PANEL))

	self.header = self.root:AddChild(Text(DIConstants.FONT, DIConstants.FONTSIZE, nil, DIConstants.COLORS.FG_NORMAL))
	self.header:SetRegionSize(region_w -self.ITEM_PADDING*4, self.ITEM_HEIGHT)
	self.header:SetHAlign(ANCHOR_LEFT)
	self.header:SetPosition(0, self.ITEM_HEIGHT/2 +self.ITEM_PADDING/2)
	self.header:SetString("Inspect Console")

	self.header_status_remote = self.root:AddChild(Text(DIConstants.FONT, DIConstants.FONTSIZE, nil))
	self.header_status_remote:SetRegionSize(region_w -self.ITEM_PADDING*2, self.ITEM_HEIGHT)
	self.header_status_remote:SetHAlign(ANCHOR_LEFT)
	self.header_status_remote:SetPosition(115, self.ITEM_HEIGHT/2 +self.ITEM_PADDING/2)
	if not self.can_remote_execute then
		self.header_status_remote:Hide()
	end
	if self.can_remote_execute and InGamePlay() then
		self:SetRemoteExecute(true) -- default to remote
	else
		self:SetRemoteExecute(self.remote_execute) -- default fallback
	end

	self.inputbar = self.root:AddChild(DITextEdit(
		region_w - self.ITEM_PADDING*2,
		self.ITEM_HEIGHT,
		self.ITEM_PADDING,
		"Lua expression"
	))
	self.inputbar:SetPosition(0, -self.ITEM_HEIGHT/2)
	self.inputbar.textedit.OnTextEntered = function()
		local query = self.inputbar.textedit:GetLineEditString()
		self:Commit(query)
		self:Close()
	end
	self.inputbar.textedit.OnStopForceEdit = function() self:Close() end
	self.inputbar.textedit:SetPassControlToScreen(CONTROL_CANCEL, true)
	self.inputbar.textedit.OnRawKey = function(s, key, down)
		if TextEdit.OnRawKey(self.inputbar.textedit, key, down) then
			return true
		end
		self:OnRawKeyHandler(key, down)
	end
	self.inputbar.textedit.validrawkeys[KEY_LCTRL] = true
	self.inputbar.textedit.validrawkeys[KEY_RCTRL] = true
	self.inputbar.textedit.validrawkeys[KEY_UP] = true
	self.inputbar.textedit.validrawkeys[KEY_DOWN] = true
	self.inputbar.textedit.validrawkeys[KEY_V] = true

	return self
end)

function InspectConsoleScreen:OnBecomeActive()
	self._base.OnBecomeActive(self)

	self.inputbar.textedit:SetFocus()
	self.inputbar.textedit:SetEditing(true)
end

function InspectConsoleScreen:SetRemoteExecute(enable_remote)
	if not self.can_remote_execute then return end

	local server_integration = (MOD_RPC.gbj_debuginspect ~= nil)
	if not server_integration then -- debug inspect server-side mod not found
		self.remote_execute = false
		self.header_status_remote:SetString("(Local only - no server-side integration)")
       	self.header_status_remote:SetColour(1,0.7,0.7,1)
		return self
	end

	self.remote_execute = enable_remote

	if self.remote_execute then
		self.header_status_remote:SetString("(Remote)")
       	self.header_status_remote:SetColour(0.7,0.7,1,1)
	else
		self.header_status_remote:SetString("(Local)")
       	self.header_status_remote:SetColour(1,0.7,0.7,1)
	end

	return self
end

function InspectConsoleScreen:Commit(query_str)
	ConsoleScreenSettings:AddLastExecutedCommand(query_str, self.remote_execute)

	if not TheNet then return end
	if not TheFrontEnd then return end
	local DICommon = require "debuginspect.common"

	if self.remote_execute then
		local remote_explore_mode = true
		DICommon.OpenInspectOverlay({
			"Request sent!",
			"Waiting for server's response",
			"If you're still reading this",
			"Something probably went wrong",
			"...or is taking a while to finish :p",
		}, remote_explore_mode, query_str)
	else
		local obj = DICommon.EvalLuaSafe(query_str)
		if not obj then return self end

		local remote_explore_mode = false
		DICommon.OpenInspectOverlay(obj, remote_explore_mode)
	end

	return self
end

function InspectConsoleScreen:OnControl(control, down)
	local base_ret = self._base.OnControl(self, control, down)
	if not down and control == CONTROL_CANCEL then
		self:Close()
		return true
	end
	return base_ret
end

function InspectConsoleScreen:OnRawKeyHandler(key, down)
	-- ctrl+v down
	if TheInput:IsKeyDown(KEY_CTRL) and TheInput:IsPasteKey(key) then
		self.is_pasting = true
		return true
	end
	-- ctrl up
	if (not down) and (key == KEY_LCTRL or key == KEY_RCTRL) then
		-- user just did ctrl+v on the last rawkeyhandler call
		if self.is_pasting then
			self.is_pasting = false
			return false
		end
		-- was not pasting before
		self:SetRemoteExecute(not self.remote_execute)
		return true
	end

	-- copied from consolescreen cuz im a lazy pig
	if not down and key == KEY_UP then
		local history = ConsoleScreenSettings:GetConsoleHistory()
		local len = #history or 0
		if len <= 0 then return end
		if self.history_idx ~= nil then
			self.history_idx = math.clamp(self.history_idx - 1, 1, len)
		else
			self.history_idx = len
		end
		local historyline = history[self.history_idx]
		self.inputbar.textedit:SetString(historyline.str)
		self.inputbar.textedit:OnTextInputted()
		self:SetRemoteExecute(historyline.remote or false)
		return true
	end
	if not down and key == KEY_DOWN then
		local history = ConsoleScreenSettings:GetConsoleHistory()
		local len = #history
		if len <= 0 then return end
		if self.history_idx == nil then return end
		if self.history_idx >= len then
			self.inputbar.textedit:SetString("")
			self:SetRemoteExecute(self.can_remote_execute)
			self.history_idx = len + 1
		else
			self.history_idx = self.history_idx + 1
			local historyline = history[self.history_idx]
			self.inputbar.textedit:SetString(historyline.str)
			self:SetRemoteExecute(historyline.remote or false)
		end
		self.inputbar.textedit:OnTextInputted()
		return true
	end

	return false
end

function InspectConsoleScreen:Close()
	TheFrontEnd:PopScreen(self)
end

return InspectConsoleScreen