local DIButton = require "debuginspect.widgets.button"
local DIConstants = require "debuginspect.constants"
local DIRowTextEdit = require "debuginspect.widgets.rowtextedit"

local DIRowTextEditNumeric = Class(DIRowTextEdit, function(self, width, height, padding, name, value)
	DIRowTextEdit._ctor(self, width, height, padding, name, value)

	self.color_value = {0.6, 1, 0.9, 1}
	self.color_value_edit = {0.6, 1, 0.9, 1}

	self.value = value

	return self:Layout_TextEditNumeric()
end)

function DIRowTextEditNumeric:Layout_TextEditNumeric()
	-- make space for minus/plus buttons on the right
	do
		local region_w = self.width/2 -self.padding*3 -self.height*2
		local region_h = self.height

		self.background_right:SetSize(region_w, region_h)
		self.background_right:SetPosition(self.width/2 +region_w/2, 0)
		self.textedit_value:SetPosition(0, 0)
		self.textedit_value:SetRegionSize(region_w -self.padding*2, region_h)
	end

	self.textedit_value.idle_text_color = DIConstants.COLORS.TYPES.number
	self.textedit_value.edit_text_color = DIConstants.COLORS.TYPES.number
	self.textedit_value:SetColour(unpack(DIConstants.COLORS.TYPES.number))
	self.textedit_value:SetEditCursorColour(unpack(DIConstants.COLORS.TYPES.number))
	self.textedit_value.OnTextEntered = function(user_input)
		local converted_to_number = tonumber(user_input)
		if converted_to_number then
			self.value = converted_to_number
		end

		self.textedit_value:SetString(tostring(self.value))

		self:OnValueCommitted()
	end

	self.button_minus = self:AddChild(DIButton(self.height, self.height, "-"))
	self.button_minus:SetPosition(self.width -self.button_minus.size_x/2 -self.height -self.padding*2, 0)
	self.button_minus:SetOnClick(function() self:DecreaseValue() end)

	self.button_plus = self:AddChild(DIButton(self.height, self.height, "+"))
	self.button_plus:SetPosition(self.width -self.button_plus.size_x/2 -self.padding, 0)
	self.button_plus:SetOnClick(function() self:IncreaseValue() end)

	return self
end

function DIRowTextEditNumeric:IncreaseValue()
	self.value = self.value + 1
	self.textedit_value:SetString(tostring(self.value))
	self.textedit_value:OnProcess()
	return self
end

function DIRowTextEditNumeric:DecreaseValue()
	self.value = self.value - 1
	self.textedit_value:SetString(tostring(self.value))
	self.textedit_value:OnProcess()
	return self
end

function DIRowTextEditNumeric:OnValueCommitted() end

return DIRowTextEditNumeric