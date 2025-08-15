local DIConstants = require "debuginspect.constants"
local Image = require "widgets.image"
local TextEdit = require "widgets.textedit"
local Text = require "widgets.text"
local Widget = require "widgets.widget"

-- a textedit template with a semi-transparent rectangle background,
-- and a placeholder text

local DITextEdit = Class(Widget, function(
	self,
	width,
	height,
	padding,
	placeholder,
	color
)
	Widget._ctor(self, "DITextEdit")

	self.width = width
	self.height = height
	self.padding = padding or 0
	self.color = color

	self.root = self:AddChild(Image("images/global.xml", "square.tex"))
	self.root:SetTint(unpack(DIConstants.COLORS.OVERLAY_HIGHLIGHTED))
	self.text_placeholder = self.root:AddChild(Text(DIConstants.FONT, DIConstants.FONTSIZE, nil, DIConstants.COLORS.FG_MID))
	self.text_placeholder:SetHAlign(ANCHOR_LEFT)
	self.text_placeholder:SetString(placeholder or "")
	self.textedit = self.root:AddChild(TextEdit(DIConstants.FONT_MONO, DIConstants.FONTSIZE, nil, DIConstants.COLORS.FG_NORMAL))
	self.textedit:SetForceEdit(true)
	self.textedit:SetHAlign(ANCHOR_LEFT)
	self.textedit.idle_text_color = self.color or DIConstants.COLORS.FG_NORMAL
	self.textedit.edit_text_color = self.color or  DIConstants.COLORS.FG_NORMAL
	if self.color then
		self.textedit:SetColour(unpack(self.color))
		self.textedit:SetEditCursorColour(unpack(self.color))
	else
		self.textedit:SetColour(unpack(DIConstants.COLORS.FG_NORMAL))
		self.textedit:SetEditCursorColour(unpack(DIConstants.COLORS.FG_NORMAL))
	end

	self.textedit.OnTextInputted = function()
		local user_input = self.textedit:GetString()
		if user_input == "" then
			self.text_placeholder:Show()
			return
		end
		self.text_placeholder:Hide()
	end

	return self:Layout()
end)

function DITextEdit:Layout()
	self.root:SetSize(self.width, self.height)
	self.text_placeholder:SetRegionSize(self.width -self.padding*2, self.height)
	self.textedit:SetRegionSize(self.width -self.padding*2, self.height)
	return self
end

return DITextEdit