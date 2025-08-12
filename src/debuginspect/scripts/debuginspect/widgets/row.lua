local DIConstants = require "debuginspect.constants"
local ImageButton = require "widgets.imagebutton"
local Image = require "widgets.image"
local Text = require "widgets.text"
local Widget = require "widgets.widget"

-- basic row with only the left column, no specifc functionalities
-- this is intended to be used as a base for creating rows of specific data types
-- dont use this on its own

local DIRow = Class(Widget, function(self, width, height, padding, name)
	Widget._ctor(self, "DIRow")

	self.width = width
	self.height = height
	self.padding = padding

	self.name = name

	return self:Layout()
end)

function DIRow:Layout()
	self.background_left = self:AddChild(Image("images/global.xml", "square.tex"))
	self.background_left:SetTint(unpack(DIConstants.COLORS.OVERLAY_NORMAL))
	self.background_left:SetSize(self.width/2 -self.padding*2, self.height)
	self.background_left:SetPosition(self.width/4, 0)

	self.text_name = self.background_left:AddChild(Text(DIConstants.FONT, DIConstants.FONTSIZE, tostring(self.name)))
	self.text_name:SetRegionSize(self.width/2 -self.padding*2, self.height)
	self.text_name:SetHAlign(ANCHOR_LEFT)
	self.text_name:SetPosition(self.padding, 0)

	local obj_type_k = type(self.name)
	local type_color = DIConstants.COLORS.TYPES[obj_type_k]
	if type_color then
		self.text_name:SetColour(unpack(type_color))
	end

	return self
end

return DIRow