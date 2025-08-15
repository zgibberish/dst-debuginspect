local DIButton = require "debuginspect.widgets.button"
local DIConstants = require "debuginspect.constants"
local DIRow = require "debuginspect.widgets.row"

local DIRowButton = Class(DIRow, function(self, width, height, padding, name, value)
	DIRow._ctor(self, width, height, padding, name)

	self.value = value

	return self:Layout_Button()
end)

function DIRowButton:Layout_Button()
	local button_width = self.width/2 -self.padding/2
	self.button = self:AddChild(DIButton(
		button_width,
		self.height,
		self.value,
		DIConstants.COLORS.OVERLAY_NORMAL,
		DIConstants.COLORS.BUTTON.BG_NORMAL,
		DIConstants.COLORS.FG_NORMAL,
		DIConstants.COLORS.FG_NORMAL
	))
	self.button:SetPosition(self.width - button_width/2, 0, 0) -- touching right wall
	self.button.text:SetRegionSize(button_width - self.padding*2, self.height)
	self.button.text:SetHAlign(ANCHOR_LEFT)

	return self
end

function DIRowButton:SetOnClick(fn)
	self.button:SetOnClick(fn)
	return self
end

return DIRowButton