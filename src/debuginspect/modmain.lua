local DICommon = require "debuginspect.common"
local bind_inspectconsole = GetModConfigData("bind_inspectconsole")

if bind_inspectconsole ~= "" then
	GLOBAL.TheInput:AddKeyUpHandler(GLOBAL[bind_inspectconsole], function()
		DICommon.ToggleInspectConsole()
	end)
end

-- NOTE: client mods always load before server mods
AddClientModRPCHandler('gbj_debuginspect', 'display_obj', function(obj_serialized)
	local obj = DICommon.DeserializeObject(obj_serialized)
	if not obj then return end

	-- no sending new query, just set display object
	local remote_explore_mode = true
	DICommon.OpenInspectOverlay(obj, remote_explore_mode)
end)

-- (see: https://forums.kleientertainment.com/forums/topic/126766-tutorial-how-to-add-talking-fonts-to-the-game/#findComment-1433374)

local function load_custom_fonts()
	GLOBAL.TheSim:UnloadFont("jetbrainsmono")
	GLOBAL.TheSim:UnloadPrefabs({"gbj_debuginspect_fonts"})

	local font_prefab = GLOBAL.Prefab(
		"gbj_debuginspect_fonts",
		nil,
		{Asset("FONT", GLOBAL.resolvefilepath("fonts/jetbrainsmono.zip"))}
	)
	GLOBAL.RegisterSinglePrefab(font_prefab)
	GLOBAL.TheSim:LoadPrefabs({font_prefab.name})
    GLOBAL.TheSim:LoadFont(GLOBAL.resolvefilepath("fonts/jetbrainsmono.zip"), "jetbrainsmono")
    GLOBAL.TheSim:SetupFontFallbacks("jetbrainsmono", GLOBAL.DEFAULT_FALLBACK_TABLE)
end

local original_Start = GLOBAL.Start
function GLOBAL.Start(...)
	original_Start(...)
	load_custom_fonts()
end