local DIConstants = require "debuginspect.constants"
local DIRow = require "debuginspect.widgets.row"
local Image = require "widgets.image"
local Text = require "widgets.text"

local DIRowText = Class(DIRow, function(self, width, height, padding, name, value, color_value)
	DIRow._ctor(self, width, height, padding, name)

	self.color_value = color_value or DIConstants.COLORS.FG_NORMAL
	self.value = value

	return self:Layout_Text()
end)

function DIRowText:Layout_Text()
	local region_w = self.width/2 -self.padding
	local region_h = self.height

	self.background_right = self:AddChild(Image("images/global.xml", "square.tex"))
	self.background_right:SetSize(region_w, region_h)
	self.background_right:SetPosition(self.width/2 +region_w/2, 0)
	self.background_right:SetTint(unpack(DIConstants.COLORS.OVERLAY_NORMAL))

	self.text_value = self.background_right:AddChild(Text(DIConstants.FONT, DIConstants.FONTSIZE, self.value, self.color_value))
	self.text_value:SetRegionSize(region_w -self.padding*2, region_h)
	self.text_value:SetHAlign(ANCHOR_LEFT)

	return self
end

return DIRowText