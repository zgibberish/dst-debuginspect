local DIButton = require "debuginspect.widgets.button"
local DIConstants = require "debuginspect.constants"
local DIRowTextEdit = require "debuginspect.widgets.rowtextedit"

local DIRowTextEditNumeric = Class(DIRowTextEdit, function(self, width, height, padding, name, value)
	DIRowTextEdit._ctor(self, width, height, padding, name, value)

	self.value = value

	return self:Layout_TextEditNumeric()
end)

function DIRowTextEditNumeric:Layout_TextEditNumeric()
	-- resize textedit make space for minus/plus buttons on the right
	do
		local new_textedit_width = self.textedit.width -self.height*2 -self.padding*2
		self.textedit.width = new_textedit_width
		self.textedit:Layout()
		local x_offset = -self.height -self.padding
		self.textedit:Nudge(Vector3(x_offset, 0, 0)) -- right aligned but pushed left a bit
	end

	self.textedit.textedit.idle_text_color = DIConstants.COLORS.TYPES.number
	self.textedit.textedit.edit_text_color = DIConstants.COLORS.TYPES.number
	self.textedit.textedit:SetColour(unpack(DIConstants.COLORS.TYPES.number))
	self.textedit.textedit:SetEditCursorColour(unpack(DIConstants.COLORS.TYPES.number))
	self.textedit.textedit.OnTextEntered = function(user_input)
		local converted_to_number = tonumber(user_input)
		if converted_to_number then
			self.value = converted_to_number
		end

		self.textedit.textedit:SetString(tostring(self.value))

		self:OnValueCommitted()
	end

	self.button_minus = self:AddChild(DIButton(self.height, self.height, "-"))
	self.button_minus:SetPosition(
		self.width -self.height*1.5 -self.padding,
		0
	)
	self.button_minus:SetOnClick(function() self:DecreaseValue() end)

	self.button_plus = self:AddChild(DIButton(self.height, self.height, "+"))
	self.button_plus:SetPosition(
		self.width -self.height/2,
		0
	)
	self.button_plus:SetOnClick(function() self:IncreaseValue() end)

	return self
end

function DIRowTextEditNumeric:IncreaseValue()
	self.value = self.value + 1
	self.textedit.textedit:SetString(tostring(self.value))
	self.textedit.textedit:OnProcess()
	return self
end

function DIRowTextEditNumeric:DecreaseValue()
	self.value = self.value - 1
	self.textedit.textedit:SetString(tostring(self.value))
	self.textedit.textedit:OnProcess()
	return self
end

function DIRowTextEditNumeric:OnValueCommitted() end

return DIRowTextEditNumeric