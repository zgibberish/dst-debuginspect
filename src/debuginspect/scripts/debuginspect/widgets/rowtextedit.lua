local DIRow = require "debuginspect.widgets.row"
local DITextEdit = require "debuginspect.widgets.textedit"

local DIRowTextEdit = Class(DIRow, function(self, width, height, padding, name, value)
	DIRow._ctor(self, width, height, padding, name)

	self.value = value

	return self:Layout_TextEdit()
end)

function DIRowTextEdit:Layout_TextEdit()
	local textedit_width = self.width/2 -self.padding/2
	self.textedit = self:AddChild(DITextEdit(
		textedit_width,
		self.height,
		self.padding
	))
	self.textedit:SetPosition(self.width - textedit_width/2, 0) -- touching right wall
	self.textedit.textedit:SetString(tostring(self.value))
	self.textedit.textedit.OnTextEntered = function()
		self.value = self.textedit.textedit:GetLineEditString()
		self:OnValueCommitted()
	end

	return self
end

function DIRowTextEdit:OnValueCommitted() end

return DIRowTextEdit