name = "Debug Inspect"
description = [[User-friendly dumptable frontend to explore data.

Fully functional client-side, but you can install the server integration mod to be able to view server-side objects also!

Press F1 to open the Debug Inspect console.
 - CTRL to toggle Remote/Local mode (needs server-side mod).
 - UP/DOWN for query history (using DST's console screen's history, and they both save to the same history).
 - CTRL+V to paste from clipboard.]]
author = "gibbert"
version = "0.1"
api_version = 10

rotwood_compatible = false
dont_starve_compatible = false
dst_compatible = true

client_only_mod = true

icon_atlas = "modicon.xml"
icon = "modicon.tex"

local keylist = {
	"KEY_TAB",
	"KEY_KP_0",
	"KEY_KP_1",
	"KEY_KP_2",
	"KEY_KP_3",
	"KEY_KP_4",
	"KEY_KP_5",
	"KEY_KP_6",
	"KEY_KP_7",
	"KEY_KP_8",
	"KEY_KP_9",
	"KEY_KP_PERIOD",
	"KEY_KP_DIVIDE",
	"KEY_KP_MULTIPLY",
	"KEY_KP_MINUS",
	"KEY_KP_PLUS",
	"KEY_KP_ENTER",
	"KEY_KP_EQUALS",
	"KEY_MINUS",
	"KEY_EQUALS",
	"KEY_SPACE",
	"KEY_ENTER",
	"KEY_ESCAPE",
	"KEY_HOME",
	"KEY_INSERT",
	"KEY_DELETE",
	"KEY_END",
	"KEY_PAUSE",
	"KEY_PRINT",
	"KEY_CAPSLOCK",
	"KEY_SCROLLOCK",
	"KEY_ALT",
	"KEY_CTRL",
	"KEY_SHIFT",
	"KEY_BACKSPACE",
	"KEY_PERIOD",
	"KEY_SLASH",
	"KEY_SEMICOLON",
	"KEY_LEFTBRACKET",
	"KEY_BACKSLASH",
	"KEY_RIGHTBRACKET",
	"KEY_TILDE",
	"KEY_A",
	"KEY_B",
	"KEY_C",
	"KEY_D",
	"KEY_E",
	"KEY_F",
	"KEY_G",
	"KEY_H",
	"KEY_I",
	"KEY_J",
	"KEY_K",
	"KEY_L",
	"KEY_M",
	"KEY_N",
	"KEY_O",
	"KEY_P",
	"KEY_Q",
	"KEY_R",
	"KEY_S",
	"KEY_T",
	"KEY_U",
	"KEY_V",
	"KEY_W",
	"KEY_X",
	"KEY_Y",
	"KEY_Z",
	"KEY_F1",
	"KEY_F2",
	"KEY_F3",
	"KEY_F4",
	"KEY_F5",
	"KEY_F6",
	"KEY_F7",
	"KEY_F8",
	"KEY_F9",
	"KEY_F10",
	"KEY_F11",
	"KEY_F12",
	"KEY_UP",
	"KEY_DOWN",
	"KEY_RIGHT",
	"KEY_LEFT",
	"KEY_PAGEUP",
	"KEY_PAGEDOWN",
	"KEY_0",
	"KEY_1",
	"KEY_2",
	"KEY_3",
	"KEY_4",
	"KEY_5",
	"KEY_6",
	"KEY_7",
	"KEY_8",
	"KEY_9",
}

configuration_options = {
	{
		name = "bind_inspectconsole",
		label = "Inspect Console Keybind",
		hover = "Assign a key you want to use to toggle the Debug Inspect console.",
		options = (function()
			local opts = {}
			opts[1] = {description = "Disabled", data = ""}
			for index = 1,#keylist do
				opts[index+1] = {description = keylist[index], data = keylist[index]}
			end
			return opts
		end)(),
		default = "KEY_F1",
	},
	{
		name = "watch_interval",
		label = "Watch Refresh Interval",
		hover = "When using the Watch toggle, refresh every X seconds.",
		options = {
			{description = "0.1", data = 0.1},
			{description = "0.2", data = 0.2},
			{description = "0.3", data = 0.3},
			{description = "0.4", data = 0.4},
			{description = "0.5", data = 0.5},
			{description = "0.6", data = 0.6},
			{description = "0.7", data = 0.7},
			{description = "0.8", data = 0.8},
			{description = "0.9", data = 0.9},
			{description = "1", data = 1},
			{description = "2", data = 2},
			{description = "3", data = 3},
			{description = "4", data = 4},
			{description = "5", data = 5},
		},
		default = 0.1,
	},
}