local DIConstants = require "debuginspect.constants"
local ImageButton = require "widgets.imagebutton"

local DIButton = Class(ImageButton, function(
	self,
	width,
	height,
	text,
	bgcolor,
	bgcolor_focused,
	fgcolor,
	fgcolor_focused
)
	ImageButton._ctor(self, "images/global.xml", "square.tex")

	local bgcolor = bgcolor or DIConstants.COLORS.BUTTON.BG_NORMAL
	local fgcolor = fgcolor or DIConstants.COLORS.BUTTON.FG_NORMAL
	local bgcolor_focused = bgcolor_focused or DIConstants.COLORS.BUTTON.BG_FOCUSED
	local fgcolor_focused = fgcolor_focused or DIConstants.COLORS.BUTTON.FG_FOCUSED

	self:ForceImageSize(width, height)
	self.scale_on_focus = false
	self:SetImageNormalColour(unpack(bgcolor))
	self:SetImageFocusColour(unpack(bgcolor_focused))
	self:SetTextColour(unpack(fgcolor))
	self:SetTextFocusColour(unpack(fgcolor_focused))
	self:SetFont(DIConstants.FONT)
	self:SetTextSize(DIConstants.FONTSIZE)
	self:SetText(text)

	return self
end)

return DIButton