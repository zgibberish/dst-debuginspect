local DIConstants = require "debuginspect.constants"
local DIRow = require "debuginspect.widgets.row"
local Image = require "widgets.image"
local TextEdit = require "widgets.textedit"

local DIRowTextEdit = Class(DIRow, function(self, width, height, padding, name, value)
	DIRow._ctor(self, width, height, padding, name)

	self.value = value

	return self:Layout_TextEdit()
end)

function DIRowTextEdit:Layout_TextEdit()
	local region_w = self.width/2 -self.padding
	local region_h = self.height

	self.background_right = self:AddChild(Image("images/global.xml", "square.tex"))
	self.background_right:SetTint(unpack(DIConstants.COLORS.OVERLAY_HIGHLIGHTED))
	self.background_right:SetSize(region_w, region_h)
	self.background_right:SetPosition(self.width/2 +region_w/2, 0)

	self.textedit_value = self.background_right:AddChild(TextEdit(DIConstants.FONT, DIConstants.FONTSIZE))
	self.textedit_value:SetRegionSize(region_w -self.padding*2, region_h)
	self.textedit_value:SetPosition(0, 0)
	self.textedit_value:SetHAlign(ANCHOR_LEFT)
	self.textedit_value.idle_text_color = DIConstants.COLORS.FG_NORMAL
	self.textedit_value.edit_text_color = DIConstants.COLORS.FG_NORMAL
	self.textedit_value:SetColour(unpack(DIConstants.COLORS.FG_NORMAL))
	self.textedit_value:SetEditCursorColour(unpack(DIConstants.COLORS.FG_NORMAL))
	self.textedit_value:SetString(tostring(self.value))
	self.textedit_value:SetForceEdit(true)
	self.textedit_value.OnTextEntered = function()
		self.value = self.textedit_value:GetLineEditString()
		self:OnValueCommitted()
	end

	return self
end

function DIRowTextEdit:OnValueCommitted() end

return DIRowTextEdit