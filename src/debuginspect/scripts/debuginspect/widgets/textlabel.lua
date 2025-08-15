local DIConstants = require "debuginspect.constants"
local Image = require "widgets.image"
local Text = require "widgets.text"
local Widget = require "widgets.widget"

-- a template with a dark semi-transparent rectangle background,
-- with text on top

local DITextLabel = Class(Widget, function(
	self,
	width,
	height,
	padding,
	text,
	color
)
	Widget._ctor(self, "DITextLabel")

	self.width = width
	self.height = height
	self.padding = padding or 0
	self.color = color

	self.root = self:AddChild(Image("images/global.xml", "square.tex"))
	self.root:SetTint(unpack(DIConstants.COLORS.OVERLAY_NORMAL))
	self.text = self.root:AddChild(Text(DIConstants.FONT, DIConstants.FONTSIZE, nil, DIConstants.COLORS.FG_NORMAL))
	self.text:SetHAlign(ANCHOR_LEFT)
	self.text:SetString(text or "")
	if self.color then
		self.text:SetColour(unpack(self.color))
	else
		self.text:SetColour(unpack(DIConstants.COLORS.FG_NORMAL))
	end

	return self:Layout()
end)

function DITextLabel:Layout()
	self.root:SetSize(self.width, self.height)
	self.text:SetRegionSize(self.width -self.padding*2, self.height)
	return self
end

return DITextLabel