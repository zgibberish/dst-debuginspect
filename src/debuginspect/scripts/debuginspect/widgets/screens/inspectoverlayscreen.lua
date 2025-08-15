local DITextEdit = require "debuginspect.widgets.textedit"
local DIButton = require "debuginspect.widgets.button"
local DIConstants = require "debuginspect.constants"
local DIRowButton = require "debuginspect.widgets.rowbutton"
local DIRowTextEditNumeric = require "debuginspect.widgets.rowtexteditnumeric"
local DIRowTextEdit = require "debuginspect.widgets.rowtextedit"
local DIRowText = require "debuginspect.widgets.rowtext"
local DIRowToggle = require "debuginspect.widgets.rowtoggle"
local Image = require "widgets.image"
local Screen = require "widgets.screen"
local ScrollableList = require "widgets.scrollablelist"
local TextEdit = require "widgets.textedit"
local Text = require "widgets.text"
local Widget = require "widgets.widget"
local InspectFunctionPopup = require "debuginspect.widgets.screens.inspectfunctionpopup"

local function table_key_count(obj_table)
	local count = 0
	for _,_ in pairs(obj_table) do
		count = count + 1
	end
	return count
end

local function send_query(query_str)
	local rpc = GetModRPC("gbj_debuginspect", "request_obj")
	SendModRPCToServer(rpc, query_str)
end

-- normal (local) mode:
--   - shows white header text
--   - refresh/watch button calls Update(), which redraws the scrollable list using current object
--   - uses current/prevstack/nextstack to keep track of pages
--     - prev/next page buttons uses current and normal prev/next stacks
--   - current object is the actual whole object, with all its childrens (can show child table key count)
--   - dumptable buttons calls dumptable on client
--   - uses SetCurrentObject only
-- server (remote explore) mode:
--   - shows blue header text
--   - refresh/watch button sends new inspect query (RPC)
--   - uses current_query/prevstack_query/nextstack_query to keep track of pages (doesnt contain any actual data)
--     - still uses current for the current displayed page (handle_display_obj client RPC calls SetCurrentObject)
--     - prev/next page buttons uses current_query and prev/next query stacks
--   - current object is only 1 layer of the requested object from server (child tables's contents are not fetched)
--     - when user clicks on a child table, adds its key to the current query, and send a new query for displaying that child
--   - dumptable buttons calls dumptable on server (request_dumptable RPC), which doesnt give a response, only prints dumptable on server logs
--   - uses SetCurrentObject_Remote to set the current query string, and send the request with RPC
--     - on client handle_display_obj RPC response received, uses SetCurrentObject to set the DISPLAY object

local InspectOverlayScreen = Class(Screen, function(self, obj, remote_explore_mode, remote_explore_query)
	Screen._ctor(self, "InspectOverlayScreen")

	self.BG_WIDTH = RESOLUTION_X*0.4
	self.BG_HEIGHT = RESOLUTION_Y*0.95
	self.ITEM_HEIGHT = 24
	self.ITEM_PADDING = 3

	local modname = KnownModIndex:GetModActualName("Debug Inspect")
	self.WATCH_REFRESH_INTERVAL_SECONDS = GetModConfigData("watch_interval", modname)

	self.remote_explore_mode = remote_explore_mode or false

	self.current = nil
	self.prevstack = {}
	self.nextstack = {}

	-- remote_explore_mode
	self.current_query = nil
	self.prevstack_query = {}
	self.nextstack_query = {}

	self.watching = false -- watch mode (refreshes continuously in short intervals) (toggled by button_watch)
	self.dt_elapsed = 0
	self.filter_key = nil

	self.root = self:AddChild(Image("images/global.xml", "square.tex"))
	self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
	self.root:SetHAnchor(ANCHOR_MIDDLE)
	self.root:SetVAnchor(ANCHOR_MIDDLE)
	self.root:SetSize(self.BG_WIDTH, self.BG_HEIGHT)
	self.root:SetPosition(0, 0)
	self.root:SetTint(unpack(DIConstants.COLORS.PANEL))

	self.header = self.root:AddChild(Text(DIConstants.FONT, DIConstants.FONTSIZE_HEADER, nil, DIConstants.COLORS.FG_NORMAL))
	self.header:SetRegionSize(self.BG_WIDTH * 0.9, self.ITEM_HEIGHT)
	self.header:SetHAlign(ANCHOR_LEFT)
	self.header:SetPosition(0, self.BG_HEIGHT/2 - self.ITEM_HEIGHT*1.5)

	do
		self.menu_bar = self.root:AddChild(Widget())

		--- first row
		self.button_arrow_prev = self.menu_bar:AddChild(DIButton(self.ITEM_HEIGHT, self.ITEM_HEIGHT))
		self.button_arrow_prev.arrow_image = self.button_arrow_prev:AddChild(Image("images/ui.xml", "arrow_left.tex"))
		self.button_arrow_prev.arrow_image:SetSize(self.ITEM_HEIGHT*0.5, self.ITEM_HEIGHT*0.5)
		self.button_arrow_prev:SetOnClick(function() self:GoPrevious() end)

		self.button_arrow_next = self.menu_bar:AddChild(DIButton(self.ITEM_HEIGHT, self.ITEM_HEIGHT))
		self.button_arrow_next.arrow_image = self.button_arrow_next:AddChild(Image("images/ui.xml", "arrow_right.tex"))
		self.button_arrow_next.arrow_image:SetSize(self.ITEM_HEIGHT*0.5, self.ITEM_HEIGHT*0.5)
		self.button_arrow_next:SetOnClick(function() self:GoNext() end)
		self.button_arrow_next:SetPosition(self.ITEM_HEIGHT + self.ITEM_PADDING, 0)

		self.button_refresh = self.menu_bar:AddChild(DIButton(self.ITEM_HEIGHT*3, self.ITEM_HEIGHT, "Refresh"))
		self.button_refresh:SetOnClick(function()
			if self.remote_explore_mode then
				send_query(self.current_query)
			else
				self:Update()
			end
		end)
		self.button_refresh:SetPosition(self.ITEM_HEIGHT*3 + self.ITEM_PADDING*2, 0)

		self.button_watch = self.menu_bar:AddChild(DIButton(
			self.ITEM_HEIGHT*3,
			self.ITEM_HEIGHT,
			"Watch",
			nil,
			nil,
			DIConstants.COLORS.FG_DISABLED, -- disabled color by default
			DIConstants.COLORS.FG_DISABLED
		))
		self.button_watch:SetOnClick(function() self:Update() end)
		self.button_watch:SetOnClick(function()
			self.watching = not self.watching
			if self.watching then
				self.button_watch:SetTextColour(unpack(DIConstants.COLORS.FG_NORMAL))
				self.button_watch:SetTextFocusColour(unpack(DIConstants.COLORS.FG_NORMAL))
			else
				self.button_watch:SetTextColour(unpack(DIConstants.COLORS.FG_DISABLED))
				self.button_watch:SetTextFocusColour(unpack(DIConstants.COLORS.FG_DISABLED))
			end
	 	end)
	 	self.button_watch:SetPosition(self.ITEM_HEIGHT*6 + self.ITEM_PADDING*3, 0)

		self.filter_bar = self.menu_bar:AddChild(DITextEdit(
			self.ITEM_HEIGHT*10,
			self.ITEM_HEIGHT,
			self.ITEM_PADDING,
			"Filter keys (case insensitive)"
		))
		self.filter_bar:SetPosition(self.ITEM_HEIGHT*12.5 + self.ITEM_PADDING*4, 0)
		self.filter_bar.textedit.OnTextEntered = function()
			-- maybe dont re-filter every keystroke, but only when you hit enter,
			-- cuz it lags SO BADLY on huge tables (like 1k+ items)
			local user_input = self.filter_bar.textedit:GetString()
			self.filter_key = (user_input ~= "") and user_input or nil
			self:Update()
		end

	 	self.button_clear_filter = self.menu_bar:AddChild(DIButton(self.ITEM_HEIGHT, self.ITEM_HEIGHT))
		self.button_clear_filter.icon_image = self.button_clear_filter:AddChild(Image("images/global_redux.xml", "close.tex"))
		self.button_clear_filter.icon_image:SetSize(self.ITEM_HEIGHT*0.5, self.ITEM_HEIGHT*0.5)
		self.button_clear_filter:SetOnClick(function()
			self.filter_bar.textedit:SetString("")
			self.filter_bar.textedit:OnTextInputted() -- update placeholder text
			self.filter_bar.textedit:OnTextEntered() -- update filter
		end)
		self.button_clear_filter:SetPosition(self.ITEM_HEIGHT*18 + self.ITEM_PADDING*5, 0)

		--- second row
		self.button_dump_shallow = self.menu_bar:AddChild(DIButton(self.ITEM_HEIGHT*7, self.ITEM_HEIGHT, "dumptable (shallow)"))
		self.button_dump_shallow:SetOnClick(function()
			if type(self.current) ~= "table" then return end
			dumptable(self.current, nil, 0)
		end)
		self.button_dump_shallow:SetPosition(self.ITEM_HEIGHT*3, -self.ITEM_HEIGHT -self.ITEM_PADDING)

		self.button_dump_deep = self.menu_bar:AddChild(DIButton(self.ITEM_HEIGHT*4, self.ITEM_HEIGHT, "dumptable"))
		self.button_dump_deep:SetOnClick(function()
			if type(self.current) ~= "table" then return end
			dumptable(self.current)
		end)
		self.button_dump_deep:SetPosition(self.ITEM_HEIGHT*8.5 +self.ITEM_PADDING, -self.ITEM_HEIGHT -self.ITEM_PADDING)

		self.menu_bar:SetPosition(-self.BG_WIDTH/2 +self.ITEM_HEIGHT/2 +self.ITEM_PADDING, self.BG_HEIGHT*0.38)
	end

	self.scroll = self.root:AddChild(ScrollableList(
		{},
		self.BG_WIDTH-self.ITEM_PADDING*2,
		self.BG_HEIGHT*0.9 -self.ITEM_HEIGHT*4,
		self.ITEM_HEIGHT,
		self.ITEM_PADDING,
		nil, -- updatefn
		nil, -- widgetstoupdate
		nil, -- widgetXOffset
		nil, -- always_show_static
		nil, -- starting_offset
		nil, -- yInit
		nil, -- bar_width_scale_factor
		nil, -- bar_height_scale_factor
		"GOLD" -- scrollbar_style
	))
	self.scroll:SetPosition(0, -self.ITEM_HEIGHT*2)
	self.scroll.scroll_bar_container:SetPosition(self.BG_WIDTH*0.08, -self.ITEM_HEIGHT*0.5)

	self:SetRemoteExploreMode(self.remote_explore_mode)
	self:SetCurrentObject(obj)
	if self.remote_explore_mode and remote_explore_query then
		self:SetCurrentObject_Remote(remote_explore_query)
	end

	return self
end)

function InspectOverlayScreen:SetRemoteExploreMode(on)
	self.remote_explore_mode = on

	if self.remote_explore_mode then
		self.header:SetColour(0.7,0.7,1,1)

		self.current = nil
		self.prevstack = {}
		self.nextstack = {}
	else
		self.header:SetColour(unpack(DIConstants.COLORS.FG_NORMAL))

		self.current_query = nil
		self.prevstack_query = {}
		self.nextstack_query = {}
	end

	return self:Update()
end

-- in remote explore mode, this is still used, but for setting the display object only
function InspectOverlayScreen:SetCurrentObject(newobj)
	local is_init = (not self.current)
	if is_init or self.remote_explore_mode then
		self.current = newobj
		return self:Update()
	end

	-- go backward
	if #self.prevstack > 0 and newobj == self.prevstack[1] then
		table.remove(self.prevstack, 1)
		table.insert(self.nextstack, 1, self.current)
		self.current = newobj
		return self:Update()
	end
	-- go forward
	if #self.nextstack > 0 and newobj == self.nextstack[1] then
		table.remove(self.nextstack, 1)
		table.insert(self.prevstack, 1, self.current)
		self.current = newobj
		return self:Update()
	end
	-- change path (go forward into a new object thats not known in the next stack)
	table.insert(self.prevstack, 1, self.current)
	self.current = newobj
	self.nextstack = {}
	return self:Update()
end

function InspectOverlayScreen:SetCurrentObject_Remote(query_str)
	local is_init = (not self.current_query)
	if is_init then
		self.current_query = query_str
		send_query(query_str)
		return self
	end

	-- go backward
	if #self.prevstack_query > 0 and query_str == self.prevstack_query[1] then
		table.remove(self.prevstack_query, 1)
		table.insert(self.nextstack_query, 1, self.current_query)
		self.current_query = query_str
		send_query(query_str)
		return self
	end
	-- go forward
	if #self.nextstack_query > 0 and query_str == self.nextstack_query[1] then
		table.remove(self.nextstack_query, 1)
		table.insert(self.prevstack_query, 1, self.current_query)
		self.current_query = query_str
		send_query(query_str)
		return self
	end
	-- change path (go forward into a new object thats not known in the next stack)
	table.insert(self.prevstack_query, 1, self.current_query)
	self.current_query = query_str
	self.nextstack_query = {}
	send_query(query_str)

	return self
end

function InspectOverlayScreen:Update()
	if not self.current then
		self.header:SetString("nil")
	end

	self:_SetDumpButtonsEnabled(type(self.current) == "table")

	-- rebuild list
	local items = {}
	local obj_type = type(self.current) -- type to determine how we display the list
	if obj_type == "number" then
		self.header:SetString(obj_type)
		table.insert(items, DIRowText(self.scroll.width, self.ITEM_HEIGHT, self.ITEM_PADDING, "value", self.current, DIConstants.COLORS.TYPES.number))
	elseif obj_type == "string" then
		self.header:SetString(obj_type)
		table.insert(items, DIRowText(self.scroll.width, self.ITEM_HEIGHT, self.ITEM_PADDING, "value", self.current, DIConstants.COLORS.TYPES.string))
	elseif obj_type == "boolean" then
		self.header:SetString(obj_type)
		table.insert(items, DIRowText(self.scroll.width, self.ITEM_PADDING, "value", tostring(self.current), DIConstants.COLORS.TYPES.boolean))
	elseif obj_type == "table" then
		local sorted_keys = {}

		for k,_ in pairs(self.current) do
			local filter_match = true
			if self.filter_key and not string.find(string.lower(k), string.lower(self.filter_key)) then
				filter_match = false
			end
			if filter_match then table.insert(sorted_keys, k) end
		end
		table.sort(sorted_keys, function(a, b)
			return tostring(a) < tostring(b)
		end)

		local header_str = rawstring(self.current).." ("..tostring(table_key_count(self.current)).." fields)"
		if self.filter_key then
			header_str = header_str.." ("..tostring(#sorted_keys).." found)"
		end
		self.header:SetString(header_str)

		local function add_field_row(k)
			local v = self.current[k]
			local obj_type_v = type(v) -- type to determine how to display items in a table
			if obj_type_v == "number" then
				local row = DIRowTextEditNumeric(self.scroll.width, self.ITEM_HEIGHT, self.ITEM_PADDING, k, v)
				row.OnValueCommitted = function() self.current[k] = row.value end
				table.insert(items, row)
			elseif obj_type_v == "string" then
				local row = DIRowTextEdit(self.scroll.width, self.ITEM_HEIGHT, self.ITEM_PADDING, k, v)
				row.OnValueCommitted = function() self.current[k] = row.value end
				table.insert(items, row)
			elseif obj_type_v == "boolean" then
				local row = DIRowToggle(self.scroll.width, self.ITEM_HEIGHT, self.ITEM_PADDING, k, v)
				row.OnValueCommitted = function() self.current[k] = row.state end
				table.insert(items, row)
			elseif obj_type_v == "table" then
				local row = DIRowButton(
					self.scroll.width,
					self.ITEM_HEIGHT,
					self.ITEM_PADDING,
					k,
					rawstring(v).." ("..tostring(table_key_count(v)).." fields)"
				):SetOnClick(function()
					if self.remote_explore_mode then
						local next_query = nil
						local obj_type_k = type(k)
						if obj_type_k == "string" then next_query = self.current_query.."[\""..k.."\"]" end
						if obj_type_k == "boolean" then next_query = self.current_query.."["..tostring(k).."]" end
						if obj_type_k == "number" then next_query = self.current_query.."["..tostring(k).."]" end
						if not next_query then return end
						self:SetCurrentObject_Remote(next_query)
					else
						self:SetCurrentObject(v)
					end
				end)
				row.button:SetTextColour(unpack(DIConstants.COLORS.TYPES["table"]))
				row.button:SetTextFocusColour(unpack(DIConstants.COLORS.TYPES["table"]))
				table.insert(items, row)
			elseif obj_type_v == "function" then
				local row = DIRowButton(
					self.scroll.width,
					self.ITEM_HEIGHT,
					self.ITEM_PADDING,
					k,
					rawstring(v)
				):SetOnClick(function()
					TheFrontEnd:PushScreen(InspectFunctionPopup(v))
				end)
				row.button:SetTextColour(unpack(DIConstants.COLORS.TYPES["function"]))
				row.button:SetTextFocusColour(unpack(DIConstants.COLORS.TYPES["function"]))
				table.insert(items, row)
			else -- userdata, threads, proxied objects (like TheSim), etc
				table.insert(items, DIRowText(self.scroll.width, self.ITEM_HEIGHT, self.ITEM_PADDING, k, rawstring(v), DIConstants.COLORS.TYPES.other))
			end
		end

		for _,k in ipairs(sorted_keys) do add_field_row(k) end
	else
		self.header:SetString(rawstring(self.current))
	end

	self.scroll:SetList(items)

	if self.remote_explore_mode then
		self:_SetArrowButtonEnabled(self.button_arrow_prev, (#self.prevstack_query > 0))
		self:_SetArrowButtonEnabled(self.button_arrow_next, (#self.nextstack_query > 0))
	else
		self:_SetArrowButtonEnabled(self.button_arrow_prev, (#self.prevstack > 0))
		self:_SetArrowButtonEnabled(self.button_arrow_next, (#self.nextstack > 0))
	end

	return self
end

function InspectOverlayScreen:OnUpdate(dt)
	if not self.watching then return end

	self.dt_elapsed = self.dt_elapsed + dt
	if self.dt_elapsed > self.WATCH_REFRESH_INTERVAL_SECONDS then
		if self.remote_explore_mode then
			send_query(self.current_query)
		else
			self:Update()
		end
		self.dt_elapsed = 0
	end
end

function InspectOverlayScreen:_SetArrowButtonEnabled(button_arrow, enabled)
	if enabled then
		button_arrow.arrow_image:SetTint(unpack(DIConstants.COLORS.FG_NORMAL))
	else
		button_arrow.arrow_image:SetTint(unpack(DIConstants.COLORS.FG_DISABLED))
	end

	return self
end

function InspectOverlayScreen:_SetDumpButtonsEnabled(enabled)
	if enabled then
		self.button_dump_shallow:SetTextColour(unpack(DIConstants.COLORS.FG_NORMAL))
		self.button_dump_shallow:SetTextFocusColour(unpack(DIConstants.COLORS.FG_NORMAL))
		self.button_dump_deep:SetTextColour(unpack(DIConstants.COLORS.FG_NORMAL))
		self.button_dump_deep:SetTextFocusColour(unpack(DIConstants.COLORS.FG_NORMAL))
	else
		self.button_dump_shallow:SetTextColour(unpack(DIConstants.COLORS.FG_DISABLED))
		self.button_dump_shallow:SetTextFocusColour(unpack(DIConstants.COLORS.FG_DISABLED))
		self.button_dump_deep:SetTextColour(unpack(DIConstants.COLORS.FG_DISABLED))
		self.button_dump_deep:SetTextFocusColour(unpack(DIConstants.COLORS.FG_DISABLED))
	end

	return self
end

function InspectOverlayScreen:GoPrevious()
	if self.remote_explore_mode then
		if #self.prevstack_query == 0 then return end
		self:SetCurrentObject_Remote(self.prevstack_query[1])
	else
		if #self.prevstack == 0 then return end
		self:SetCurrentObject(self.prevstack[1])
	end
	return self
end

function InspectOverlayScreen:GoNext()
	if self.remote_explore_mode then
		if #self.nextstack_query == 0 then return end
		self:SetCurrentObject_Remote(self.nextstack_query[1])
	else
		if #self.nextstack == 0 then return end
		self:SetCurrentObject(self.nextstack[1])
	end
	return self
end

function InspectOverlayScreen:OnControl(control, down)
	local base_ret = self._base.OnControl(self, control, down)
	if not down and control == CONTROL_CANCEL then
		self:Close()
		return true
	end
	return base_ret
end

function InspectOverlayScreen:Close()
	TheFrontEnd:PopScreen(self)
end

return InspectOverlayScreen