local DIButton = require "debuginspect.widgets.button"
local DICommon = require "debuginspect.common"
local DIConstants = require "debuginspect.constants"
local DITextEdit = require "debuginspect.widgets.textedit"
local DITextLabel = require "debuginspect.widgets.textlabel"
local Image = require "widgets.image"
local Screen = require "widgets.screen"
local Text = require "widgets.text"

local function ui_eval_input(user_input, raw)
	local obj = nil

	if raw then
		obj = user_input
	else
		obj = DICommon.EvalLuaSafe(user_input)
	end

	if obj == nil then -- dont do "if not obj then" cuz that includes false booleans
		local texture = "symbol_type_nil.tex"
		local tint = DIConstants.COLORS.FG_MID
		return nil, texture, tint
	end

	local obj_type = type(obj)

	local texture = nil
	local tint = nil
	if obj_type == "boolean" then
		texture = "symbol_type_boolean.tex"
		tint = DIConstants.COLORS.TYPES["boolean"]
	elseif obj_type == "function" then
		texture = "symbol_type_function.tex"
		tint = DIConstants.COLORS.TYPES["function"]
	elseif obj_type == "number" then
		texture = "symbol_type_number.tex"
		tint = DIConstants.COLORS.TYPES["number"]
	elseif obj_type == "string" then
		texture = "symbol_type_string.tex"
		tint = DIConstants.COLORS.TYPES["string"]
	elseif obj_type == "table" then
		texture = "symbol_type_table.tex"
		tint = DIConstants.COLORS.TYPES["table"]
	else
		texture = "symbol_type_other.tex"
		tint = DIConstants.COLORS.TYPES["other"]
	end

	return obj, texture, tint
end

local ModifyItemPopup = Class(Screen, function(self, initial_key, initial_value, callback)
	Screen._ctor(self, "ModifyItemPopup")

	self.old_key = initial_key
	self.old_value = initial_value
	self.new_key = initial_key
	self.new_value = initial_value
	self.change_key = false
	self.change_value = false
	self.has_error = false -- see Check(), this means user-inputted data is invalid and we cant continue
	self.submitfn = callback -- called on Delete/Save button click (args: new_key, new_value)

	self.ITEM_HEIGHT = 24
	self.ITEM_PADDING = 3

	self.root = self:AddChild(Image("images/global.xml", "square.tex"))
	self.root:SetHAnchor(ANCHOR_MIDDLE)
	self.root:SetVAnchor(ANCHOR_MIDDLE)
	self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
	self.root:SetTint(unpack(DIConstants.COLORS.PANEL))

	self.header = self.root:AddChild(Text(DIConstants.FONT, DIConstants.FONTSIZE, nil, DIConstants.COLORS.FG_NORMAL))
	self.header:SetHAlign(ANCHOR_LEFT)
	self.header:SetString("Modify Item")

	self.label_key = self.root:AddChild(DITextLabel(0, 0, 0, "Key"))
	self.textedit_key = self.root:AddChild(DITextEdit(0, 0, 0, "Lua expression"))
	self.textedit_key.textedit.OnTextEntered = function()
		self.change_key = true
		self:EvalInputKey()
		self:Check()
	end
	self.icon_datatype_key_old = self.root:AddChild(Image())
	self.icon_datatype_key_arrow = self.root:AddChild(Image("images/debuginspect.xml", "arrow_right.tex"))
	self.icon_datatype_key_arrow:SetSize(self.ITEM_HEIGHT*0.5, self.ITEM_HEIGHT*0.5)
	self.icon_datatype_key = self.root:AddChild(Image())

	self.label_value = self.root:AddChild(DITextLabel(0, 0, 0, "Value"))
	self.textedit_value = self.root:AddChild(DITextEdit(0, 0, 0, "Lua expression"))
	self.textedit_value.textedit.OnTextEntered = function()
		self.change_value = true
		self:EvalInputValue()
		self:Check()
	end
	self.icon_datatype_value_old = self.root:AddChild(Image())
	self.icon_datatype_value_arrow = self.root:AddChild(Image("images/debuginspect.xml", "arrow_right.tex"))
	self.icon_datatype_value_arrow:SetSize(self.ITEM_HEIGHT*0.5, self.ITEM_HEIGHT*0.5)
	self.icon_datatype_value = self.root:AddChild(Image())

	self.label_error = self.root:AddChild(Text(DIConstants.FONT, DIConstants.FONTSIZE, nil, {1,0.7,0.7,1}))
	self.label_error:SetHAlign(ANCHOR_LEFT)
	self.button_reset_key = self.root:AddChild(DIButton(self.ITEM_HEIGHT*4, self.ITEM_HEIGHT, "Reset Key"))
	self.button_reset_key:SetOnClick(function() self:ResetKey() end)
	self.button_reset_value = self.root:AddChild(DIButton(self.ITEM_HEIGHT*4, self.ITEM_HEIGHT, "Reset Value"))
	self.button_reset_value:SetOnClick(function() self:ResetValue() end)
	self.button_delete = self.root:AddChild(DIButton(self.ITEM_HEIGHT*3, self.ITEM_HEIGHT, "Delete"))
	self.button_delete:SetOnClick(function() self:Delete() end)
	self.button_save = self.root:AddChild(DIButton(self.ITEM_HEIGHT*3, self.ITEM_HEIGHT, "Save"))
	self.button_save:SetOnClick(function() self:Save() end)

	-- this doesnt change like ever so dont need to have it in Layout()
	do -- set data type icon for initial key and value in UI
		local raw = true
		local _, texture, tint = ui_eval_input(initial_key, raw)
		self.icon_datatype_key_old:SetTexture("images/debuginspect.xml", texture)
		self.icon_datatype_key_old:SetSize(self.ITEM_HEIGHT*0.75, self.ITEM_HEIGHT*0.75)
		self.icon_datatype_key_old:SetTint(unpack(tint))
		local _, texture, tint = ui_eval_input(initial_value, raw)
		self.icon_datatype_value_old:SetTexture("images/debuginspect.xml", texture)
		self.icon_datatype_value_old:SetSize(self.ITEM_HEIGHT*0.75, self.ITEM_HEIGHT*0.75)
		self.icon_datatype_value_old:SetTint(unpack(tint))
	end

	self:Layout()
	self:EvalInputKey()
	self:EvalInputValue()
	self:Check()

	return self
end)

function ModifyItemPopup:Layout()
	local region_w = RESOLUTION_X/2
	local region_h = self.ITEM_HEIGHT*4 + self.ITEM_PADDING*5

	self.root:SetSize(region_w, region_h)
	self.header:SetRegionSize(region_w -self.ITEM_PADDING*2, self.ITEM_HEIGHT)
	self.header:SetPosition(0, region_h/2 -self.ITEM_HEIGHT/2 -self.ITEM_PADDING)

	self.label_key.width = self.ITEM_HEIGHT*2
	self.label_key.height = self.ITEM_HEIGHT
	self.label_key.padding = self.ITEM_PADDING
	self.label_key:Layout()
	self.label_key:SetPosition( -- below header
		-region_w/2 +self.ITEM_HEIGHT +self.ITEM_PADDING,
		region_h/2 -self.ITEM_HEIGHT*1.5 -self.ITEM_PADDING*2
	)
	self.textedit_key.width = region_w -self.ITEM_HEIGHT*5 -self.ITEM_PADDING*6
	self.textedit_key.height = self.ITEM_HEIGHT
	self.textedit_key.padding = self.ITEM_PADDING
	self.textedit_key:Layout()
	self.textedit_key:SetPosition(
		region_w/2 - self.textedit_key.width/2 -self.ITEM_HEIGHT*3 -self.ITEM_PADDING*4,
		region_h/2 -self.ITEM_HEIGHT*1.5 -self.ITEM_PADDING*2
	)
	self.icon_datatype_key_old:SetPosition(
		region_w/2 -self.ITEM_HEIGHT*2.5 -self.ITEM_PADDING*3,
		region_h/2 -self.ITEM_HEIGHT*1.5 -self.ITEM_PADDING*2
	)
	self.icon_datatype_key_arrow:SetPosition(
		region_w/2 -self.ITEM_HEIGHT*1.5 -self.ITEM_PADDING*2,
		region_h/2 -self.ITEM_HEIGHT*1.5 -self.ITEM_PADDING*2
	)
	self.icon_datatype_key:SetPosition(
		region_w/2 -self.ITEM_HEIGHT/2 -self.ITEM_PADDING,
		region_h/2 -self.ITEM_HEIGHT*1.5 -self.ITEM_PADDING*2
	)

	self.label_value.width = self.ITEM_HEIGHT*2
	self.label_value.height = self.ITEM_HEIGHT
	self.label_value.padding = self.ITEM_PADDING
	self.label_value:Layout()
	self.label_value:SetPosition( -- below label_key
		-region_w/2 +self.ITEM_HEIGHT +self.ITEM_PADDING,
		region_h/2 -self.ITEM_HEIGHT*2.5 -self.ITEM_PADDING*3
	)
	self.textedit_value.width = region_w -self.ITEM_HEIGHT*5 -self.ITEM_PADDING*6
	self.textedit_value.height = self.ITEM_HEIGHT
	self.textedit_value.padding = self.ITEM_PADDING
	self.textedit_value:Layout()
	self.textedit_value:SetPosition(
		region_w/2 - self.textedit_key.width/2 -self.ITEM_HEIGHT*3 -self.ITEM_PADDING*4,
		region_h/2 -self.ITEM_HEIGHT*2.5 -self.ITEM_PADDING*3
	)
	self.icon_datatype_value_old:SetPosition(
		region_w/2 -self.ITEM_HEIGHT*2.5 -self.ITEM_PADDING*3,
		region_h/2 -self.ITEM_HEIGHT*2.5 -self.ITEM_PADDING*3
	)
	self.icon_datatype_value_arrow:SetPosition(
		region_w/2 -self.ITEM_HEIGHT*1.5 -self.ITEM_PADDING*2,
		region_h/2 -self.ITEM_HEIGHT*2.5 -self.ITEM_PADDING*3
	)
	self.icon_datatype_value:SetPosition(
		region_w/2 -self.ITEM_HEIGHT/2 -self.ITEM_PADDING,
		region_h/2 -self.ITEM_HEIGHT*2.5 -self.ITEM_PADDING*3
	)

	self.button_reset_key:SetPosition(
		region_w/2 -self.ITEM_HEIGHT*2 -self.ITEM_HEIGHT*10 -self.ITEM_PADDING*4,
		-region_h/2 +self.ITEM_HEIGHT/2 +self.ITEM_PADDING
	)
	self.button_reset_value:SetPosition(
		region_w/2 -self.ITEM_HEIGHT*2 -self.ITEM_HEIGHT*6 -self.ITEM_PADDING*3,
		-region_h/2 +self.ITEM_HEIGHT/2 +self.ITEM_PADDING
	)
	self.button_delete:SetPosition(
		region_w/2 -self.ITEM_HEIGHT*1.5 -self.ITEM_PADDING -self.ITEM_HEIGHT*3 -self.ITEM_PADDING,
		-region_h/2 +self.ITEM_HEIGHT/2 +self.ITEM_PADDING
	)
	self.button_save:SetPosition(
		region_w/2 -self.ITEM_HEIGHT*1.5 -self.ITEM_PADDING,
		-region_h/2 +self.ITEM_HEIGHT/2 +self.ITEM_PADDING
	)
	do
		local label_width = region_w -self.ITEM_HEIGHT*17 -self.ITEM_PADDING*6 -- -space taken up by buttons on the right
		local label_height = self.ITEM_HEIGHT
		self.label_error:SetRegionSize(label_width, label_height)
		self.label_error:SetPosition(
			-region_w/2 +label_width/2 +self.ITEM_PADDING,
			-region_h/2 +self.ITEM_HEIGHT/2 +self.ITEM_PADDING
		)
	end

	return self
end

function ModifyItemPopup:EvalInputKey()
	local user_input = self.textedit_key.textedit:GetString()
	local obj, texture, tint = ui_eval_input(user_input)

	if not self.change_key then
		texture = self.icon_datatype_key_old.texture
		tint = self.icon_datatype_key_old.tint
	end

	if self.change_key then self.new_key = obj
	else self.new_key = self.old_key end

	self.icon_datatype_key:SetTexture("images/debuginspect.xml", texture)
	self.icon_datatype_key:SetSize(self.ITEM_HEIGHT*0.75, self.ITEM_HEIGHT*0.75)
	self.icon_datatype_key:SetTint(unpack(tint))

	if self.change_key then
		self.label_key.text:SetColour(unpack(DIConstants.COLORS.TYPES["table"]))
	else
		self.label_key.text:SetColour(unpack(DIConstants.COLORS.FG_NORMAL))
	end

	return self
end

function ModifyItemPopup:EvalInputValue()
	local user_input = self.textedit_value.textedit:GetString()
	local obj, texture, tint = ui_eval_input(user_input)

	if not self.change_value then
		texture = self.icon_datatype_value_old.texture
		tint = self.icon_datatype_value_old.tint
	end

	if self.change_value then self.new_value = obj
	else self.new_value = self.old_value end

	self.icon_datatype_value:SetTexture("images/debuginspect.xml", texture)
	self.icon_datatype_value:SetSize(self.ITEM_HEIGHT*0.75, self.ITEM_HEIGHT*0.75)
	self.icon_datatype_value:SetTint(unpack(tint))

	if self.change_value then
		self.label_value.text:SetColour(unpack(DIConstants.COLORS.TYPES["table"]))
	else
		self.label_value.text:SetColour(unpack(DIConstants.COLORS.FG_NORMAL))
	end

	return self
end

function ModifyItemPopup:Check()
	local error = nil

	if self.new_key == nil then
		error = "Key cannot be nil!"
	end

	self.has_error = (error ~= nil)
	if error then
		self.label_error:SetString(error)
		self.label_error:Show()
		self.button_save:SetTextColour(unpack(DIConstants.COLORS.FG_DISABLED))
		self.button_save:SetTextFocusColour(unpack(DIConstants.COLORS.FG_DISABLED))
		return self
	end

	self.label_error:Hide()

	self.button_save:SetTextColour(unpack(DIConstants.COLORS.FG_NORMAL))
	self.button_save:SetTextFocusColour(unpack(DIConstants.COLORS.FG_NORMAL))

	return self
end

function ModifyItemPopup:ResetKey()
	self.textedit_key.textedit:SetString("")
	self.textedit_key.textedit:OnTextInputted() -- force update placeholder text
	self.new_key = self.old_key
	self.change_key = false
	self:EvalInputKey() -- update data type icons
	self:Check()
end

function ModifyItemPopup:ResetValue()
	self.textedit_value.textedit:SetString("")
	self.textedit_value.textedit:OnTextInputted() -- force update placeholder text
	self.new_value = self.old_value
	self.change_value = false
	self:EvalInputValue() -- update data type icons
	self:Check()
end

function ModifyItemPopup:Delete()
	if self.submitfn then self.submitfn(self.old_key, nil) end
	self:Close()
end

function ModifyItemPopup:Save()
	-- this will never return a nil new_key
	-- (the user is forced to enter a valid non-nil lua expression to be able to Save)
	-- handle this appropriately according to your use case
	if self.has_error then return end
	if self.submitfn then self.submitfn(self.new_key, self.new_value) end
	self:Close()
end

function ModifyItemPopup:OnControl(control, down)
	local base_ret = self._base.OnControl(self, control, down)
	if not down and control == CONTROL_CANCEL then
		self:Close()
		return true
	end
	return base_ret
end

function ModifyItemPopup:Close()
	TheFrontEnd:PopScreen(self)
end

return ModifyItemPopup