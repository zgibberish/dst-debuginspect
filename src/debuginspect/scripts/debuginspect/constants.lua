local DIConstants = {
	FONT = CODEFONT,
	FONT_MONO = "jetbrainsmono",
	FONTSIZE = 16,
	FONTSIZE_HEADER = 22,
	COLORS = {
		PANEL = {0, 0, 0, 0.75},
		OVERLAY_NORMAL = {0, 0, 0, 0.4},
		OVERLAY_HIGHLIGHTED = {0.2, 0.2, 0.2, 0.4},

		FG_NORMAL = {1, 1, 1, 1},
		FG_MID = {1, 1, 1, 0.5},
		FG_DISABLED = {1, 1, 1, 0.3},

		BUTTON = {
			BG_NORMAL = {0.4, 0.4, 0.4, 0.5},
			BG_FOCUSED = {0.8, 0.8, 0.8, 0.5},
			FG_NORMAL = {1, 1, 1, 1},
			FG_FOCUSED = {1, 1, 1, 1},
		},

		TYPES = {
			["string"] = {1, 1, 1, 1},
			["number"] = {0.6, 1, 0.9, 1},
			["table"] = {1, 0.7, 0.5, 1},
			["boolean"] = {0.67, 0.8, 0.96, 1},
			["function"] = {0.8, 0.6, 1, 1},
			["other"] = {0.8, 0.6, 1, 1},
		},
	},
}

-- debug colors
-- DIConstants.COLORS.PANEL = {0, 0, 0, 1}
-- DIConstants.COLORS.OVERLAY_NORMAL = {1, 0, 0, 0.4}
-- DIConstants.COLORS.OVERLAY_HIGHLIGHTED = {0.2, 1, 0.2, 0.4}
-- DIConstants.COLORS.BUTTON.BG_NORMAL = {0.4, 0.4, 1, 0.5}
-- DIConstants.COLORS.BUTTON.BG_FOCUSED = {0.8, 0.8, 1, 0.5}

return DIConstants