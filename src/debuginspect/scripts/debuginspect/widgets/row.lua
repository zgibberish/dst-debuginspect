local DIConstants = require "debuginspect.constants"
local DITextLabel = require "debuginspect.widgets.textlabel"
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
	local label_width = self.width/2 -self.padding/2
	self.label_key = self:AddChild(DITextLabel(label_width, self.height, self.padding, tostring(self.name)))
	self.label_key:SetPosition(label_width/2, 0)

	local obj_type_k = type(self.name)
	local type_color = DIConstants.COLORS.TYPES[obj_type_k] or DIConstants.COLORS.TYPES["other"]
	if type_color then
		self.label_key.text:SetColour(unpack(type_color))
	end

	return self
end

return DIRow