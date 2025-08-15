local DIConstants = require "debuginspect.constants"
local DIRow = require "debuginspect.widgets.row"
local DITextLabel = require "debuginspect.widgets.textlabel"

local DIRowText = Class(DIRow, function(self, width, height, padding, name, value, color_value)
	DIRow._ctor(self, width, height, padding, name)

	self.value = value
	self.color_value = color_value or DIConstants.COLORS.FG_NORMAL

	return self:Layout_Text()
end)

function DIRowText:Layout_Text()
	local label_width = self.width/2 -self.padding/2
	self.label_value = self:AddChild(DITextLabel(label_width, self.height, self.padding, self.value, self.color_value))
	self.label_value:SetPosition(self.width - label_width/2, 0, 0) -- touching right wall

	return self
end

return DIRowText