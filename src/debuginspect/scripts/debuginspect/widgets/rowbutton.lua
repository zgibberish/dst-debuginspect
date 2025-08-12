local DIConstants = require "debuginspect.constants"
local DIRow = require "debuginspect.widgets.row"
local ImageButton = require "widgets.imagebutton"

local DIRowButton = Class(DIRow, function(self, width, height, padding, name, value)
	DIRow._ctor(self, width, height, padding, name)

	self.value = value

	return self:Layout_Button()
end)

function DIRowButton:Layout_Button()
	local region_w = self.width/2 -self.padding
	local region_h = self.height

	self.background_right = self:AddChild(ImageButton("images/global.xml", "square.tex"))
	self.background_right:ForceImageSize(region_w, region_h)
	self.background_right:SetPosition(self.width/2 +region_w/2, 0)
	self.background_right.scale_on_focus = false
	self.background_right:SetImageNormalColour(unpack(DIConstants.COLORS.ROWBUTTON.BG_NORMAL))
	self.background_right:SetImageFocusColour(unpack(DIConstants.COLORS.ROWBUTTON.BG_FOCUSED))
	self.background_right:SetTextColour(unpack(DIConstants.COLORS.ROWBUTTON.FG_NORMAL))
	self.background_right:SetTextFocusColour(unpack(DIConstants.COLORS.ROWBUTTON.FG_FOCUSED))
	self.background_right:SetFont(DIConstants.FONT)
	self.background_right:SetTextSize(DIConstants.FONTSIZE)
	self.background_right.text:SetRegionSize(region_w -self.padding*2, region_h)
	self.background_right.text:SetHAlign(ANCHOR_LEFT)
	self.background_right:SetText(self.value)

	return self
end

function DIRowButton:SetOnClick(fn)
	self.background_right:SetOnClick(fn)
	return self
end

return DIRowButton