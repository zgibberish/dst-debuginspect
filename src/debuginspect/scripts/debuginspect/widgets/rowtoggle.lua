local DIButton = require "debuginspect.widgets.button"
local DIConstants = require "debuginspect.constants"
local DIRow = require "debuginspect.widgets.row"
local Image = require "widgets.image"
local Text = require "widgets.text"

local IDRowToggle = Class(DIRow, function(self, width, height, padding, name, state)
	DIRow._ctor(self, width, height, padding, name)

	self.state = state

	return self:Layout_Toggle()
end)

function IDRowToggle:Layout_Toggle()
	local region_w = self.width/2 -self.padding*2 -self.height*3
	local region_h = self.height

	self.background_right = self:AddChild(Image("images/global.xml", "square.tex"))
	self.background_right:SetSize(region_w, region_h)
	self.background_right:SetPosition(self.width/2 +region_w/2, 0)
	self.background_right:SetTint(unpack(DIConstants.COLORS.OVERLAY_NORMAL))

	self.text_state = self.background_right:AddChild(Text(DIConstants.FONT, DIConstants.FONTSIZE, tostring(self.state), self.color_value))
	self.text_state:SetRegionSize(region_w -self.padding*2, region_h)
	self.text_state:SetHAlign(ANCHOR_LEFT)
	self.text_state:SetColour(unpack(DIConstants.COLORS.TYPES.boolean))

	self.toggle_button = self:AddChild(DIButton(self.height*3, self.height, "Toggle"))
	self.toggle_button:SetPosition(self.width - self.toggle_button.size_x/2 - self.padding, 0)
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
	self.text_state:SetString(tostring(self.state))
	return self
end

function IDRowToggle:GetState()
	return self.state
end

function IDRowToggle:OnValueCommitted() end

return IDRowToggle