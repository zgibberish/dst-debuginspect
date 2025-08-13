local DIButton = require "debuginspect.widgets.button"
local DIConstants = require "debuginspect.constants"
local Screen = require "widgets.screen"
local Text = require "widgets.text"
local Image = require "widgets.image"
local DIRowText = require "debuginspect.widgets.rowtext"
local DIRowTextEdit = require "debuginspect.widgets.rowtextedit"
local ScrollableList = require "widgets.scrollablelist"
local Widget = require "widgets.widget"

local function file_read_section(filename, line_start, line_end)
	local file = io.open(filename)
	local section = {}

	local currentline = 0
	for line in file:lines() do
		currentline = currentline + 1
		if currentline >= line_start
		and currentline <= line_end then
			table.insert(section, line)
		end
	end

	return section
end

local InspectFunctionPopup = Class(Screen, function(self, fn)
	Screen._ctor(self, "InspectFunctionPopup")

	self.ITEM_HEIGHT = 24
	self.ITEM_PADDING = 3

	-- this screen is pushed by inspectoverlayscreen with function values only
	assert(type(fn) == "function")
	self.info = debug.getinfo(fn)
	if self.info.what ~= "Lua" then
		return self:Layout_Unsupported("Function type \""..self.info.what.."\" is not supported.")
	end
	if not kleifileexists(self.info.source) then
		return self:Layout_Unsupported("Source file not found: "..self.info.source)
	end
	return self:Layout()
end)

function InspectFunctionPopup:Layout()
	local src_preview_region_w = RESOLUTION_X*0.8 -self.ITEM_PADDING*2
	local src_preview_region_h = self.ITEM_HEIGHT*18
	local region_w = RESOLUTION_X*0.8
	local region_h = self.ITEM_HEIGHT*4 +self.ITEM_PADDING*6 +src_preview_region_h

	self.root = self:AddChild(Image("images/global.xml", "square.tex"))
	self.root:SetHAnchor(ANCHOR_MIDDLE)
	self.root:SetVAnchor(ANCHOR_MIDDLE)
	self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
	self.root:SetSize(region_w, region_h)
	self.root:SetTint(unpack(DIConstants.COLORS.PANEL))

	self.header = self.root:AddChild(Text(DIConstants.FONT, DIConstants.FONTSIZE, nil, DIConstants.COLORS.FG_NORMAL))
	self.header:SetRegionSize(region_w -self.ITEM_PADDING*4, self.ITEM_HEIGHT)
	self.header:SetHAlign(ANCHOR_LEFT)
	self.header:SetPosition(0, region_h/2 -self.ITEM_HEIGHT/2 -self.ITEM_PADDING) -- top left
	self.header:SetString("Function Details")

	self.row_type = self.root:AddChild(DIRowText(
		region_w,
		self.ITEM_HEIGHT,
		self.ITEM_PADDING,
		"Type",
		self.info.what
	))
	self.row_type:SetPosition( -- below header
		-region_w/2,
		region_h/2 -self.ITEM_HEIGHT/2 -self.ITEM_PADDING -self.ITEM_HEIGHT-self.ITEM_PADDING
	)

	local str_source = self.info.source.."@"..tostring(self.info.linedefined)..":"..tostring(self.info.lastlinedefined)
	self.row_src = self.root:AddChild(DIRowTextEdit(
		region_w,
		self.ITEM_HEIGHT,
		self.ITEM_PADDING,
		"Source",
		str_source
	))
	self.row_src:SetPosition( -- below type
		-region_w/2,
		region_h/2 -self.ITEM_HEIGHT/2 -self.ITEM_PADDING -self.ITEM_HEIGHT*2-self.ITEM_PADDING*2
	)
	self.row_src.textedit_value.OnTextInput = function() end -- disable editing

	-- source preview
	self.src_preview_bg = self.root:AddChild(Image("images/global.xml", "square.tex"))
	self.src_preview_bg:SetSize(src_preview_region_w, src_preview_region_h)
	self.src_preview_bg:SetTint(unpack(DIConstants.COLORS.OVERLAY_HIGHLIGHTED))
	self.src_preview_bg:SetPosition(0, -self.ITEM_HEIGHT -self.ITEM_PADDING)

	local src_lines = file_read_section(self.info.source, self.info.linedefined, self.info.lastlinedefined)
		local scroll_items = {}
	for index,line_str in ipairs(src_lines) do
		local visual_line = Widget()
		visual_line.line_number = visual_line:AddChild(Text(DIConstants.FONT_MONO, DIConstants.FONTSIZE, nil, DIConstants.COLORS.FG_MID))
		visual_line.line_number:SetRegionSize(self.ITEM_HEIGHT*3, self.ITEM_HEIGHT)
		visual_line.line_number:SetHAlign(ANCHOR_RIGHT)
		visual_line.line_number:SetString(tostring(self.info.linedefined + index-1))
		visual_line.line_content = visual_line:AddChild(Text(DIConstants.FONT_MONO, DIConstants.FONTSIZE, nil, DIConstants.COLORS.FG_NORMAL))
		visual_line.line_content:SetString(line_str)
		visual_line.line_content:SetRegionSize(src_preview_region_w -self.ITEM_HEIGHT*2 -self.ITEM_PADDING*2, self.ITEM_HEIGHT)
		visual_line.line_content:SetHAlign(ANCHOR_LEFT)
		visual_line.line_content:SetPosition(src_preview_region_w/2 +self.ITEM_HEIGHT*0.5 +self.ITEM_PADDING, 0)

		table.insert(scroll_items, visual_line)
	end
	self.src_preview_scroll = self.root:AddChild(ScrollableList(
		scroll_items,
		src_preview_region_w -self.ITEM_PADDING*2,
		src_preview_region_h -16 -self.ITEM_PADDING*2,
		16, -- item height
		1, -- item padding
		nil, -- updatefn
		nil, -- widgetstoupdate
		nil, -- widgetXOffset
		nil, -- always_show_static
		nil, -- starting_offset
		nil, -- yInit
		nil, -- bar_width_scale_factor
		nil, -- bar_height_scale_factor
		"GOLD" -- scrollbar_style
	))
	self.src_preview_scroll:SetPosition(0, -8)
	self.src_preview_scroll.scroll_bar_container:SetPosition(24, -24)

	self.button_close = self.root:AddChild(DIButton(self.ITEM_HEIGHT*3, self.ITEM_HEIGHT, "Close")) -- bottom right
	self.button_close:SetPosition(region_w/2 -self.ITEM_HEIGHT*1.5 -self.ITEM_PADDING, -region_h/2 +self.ITEM_HEIGHT/2 +self.ITEM_PADDING)
	self.button_close:SetOnClick(function() self:Close() end)

	return self
end

--TODO (gibbert): maybe write a general purpose popup dialog screen?
function InspectFunctionPopup:Layout_Unsupported(message)
	local region_w = RESOLUTION_X*0.5
	local region_h = self.ITEM_HEIGHT*3 +self.ITEM_PADDING*4

	self.root = self:AddChild(Image("images/global.xml", "square.tex"))
	self.root:SetHAnchor(ANCHOR_MIDDLE)
	self.root:SetVAnchor(ANCHOR_MIDDLE)
	self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
	self.root:SetSize(region_w, region_h)
	self.root:SetTint(unpack(DIConstants.COLORS.PANEL))

	self.header = self.root:AddChild(Text(DIConstants.FONT, DIConstants.FONTSIZE, nil, DIConstants.COLORS.FG_NORMAL))
	self.header:SetRegionSize(region_w -self.ITEM_PADDING*4, self.ITEM_HEIGHT)
	self.header:SetHAlign(ANCHOR_LEFT)
	self.header:SetPosition(0, region_h/2 -self.ITEM_HEIGHT/2 -self.ITEM_PADDING) -- top left
	self.header:SetString("Function Details")

	self.row_info = self.root:AddChild(DIRowTextEdit(
		region_w,
		self.ITEM_HEIGHT,
		self.ITEM_PADDING,
		"Info",
		message
	))
	self.row_info:SetPosition( -- below header
		-region_w/2,
		region_h/2 -self.ITEM_HEIGHT/2 -self.ITEM_PADDING -self.ITEM_HEIGHT-self.ITEM_PADDING
	)

	self.button_close = self.root:AddChild(DIButton(self.ITEM_HEIGHT*3, self.ITEM_HEIGHT, "Close")) -- bottom right
	self.button_close:SetPosition(region_w/2 -self.ITEM_HEIGHT*1.5 -self.ITEM_PADDING, -region_h/2 +self.ITEM_HEIGHT/2 +self.ITEM_PADDING)
	self.button_close:SetOnClick(function() self:Close() end)

	return self
end

function InspectFunctionPopup:OnControl(control, down)
	local base_ret = self._base.OnControl(self, control, down)
	if not down and control == CONTROL_CANCEL then
		self:Close()
		return true
	end
	return base_ret
end

function InspectFunctionPopup:Close()
	TheFrontEnd:PopScreen(self)
end

return InspectFunctionPopup