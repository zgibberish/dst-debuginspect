local DIButton = require "debuginspect.widgets.button"
local DIConstants = require "debuginspect.constants"
local DIRow = require "debuginspect.widgets.row"
local DITextLabel = require "debuginspect.widgets.textlabel"

local IDRowToggle = Class(DIRow, function(self, width, height, padding, name, state)
	DIRow._ctor(self, width, height, padding, name)

	self.state = state

	return self:Layout_Toggle()
end)

function IDRowToggle:Layout_Toggle()
	local label_width = self.width/2 -self.padding/2
	label_width = label_width - self.height*3 -self.padding -- make space for toggle button
	self.label_state = self:AddChild(DITextLabel(label_width, self.height, self.padding, tostring(self.state), self.color_value))
	self.label_state:SetPosition(self.width - label_width/2 - self.height*3 -self.padding, 0) -- touching right wall but pushed left a bit
	self.label_state.text:SetColour(unpack(DIConstants.COLORS.TYPES["boolean"]))

	self.toggle_button = self:AddChild(DIButton(self.height*3, self.height, "Toggle"))
	self.toggle_button:SetPosition(self.width - self.toggle_button.size_x/2, 0)
	self.toggle_button:SetOnClick(function() self:Toggle() end)

	return self
end

function IDRowToggle:Toggle()
	self:SetState(not self.state)
	self:OnValueCommitted()
	return self
end

function IDRowToggle:SetState(newstate)
	assert(type(newstate) == "boolean")
	self.state = newstate
	self.label_state.text:SetString(tostring(self.state))
	return self
end

function IDRowToggle:GetState()
	return self.state
end

function IDRowToggle:OnValueCommitted() end

return IDRowToggle