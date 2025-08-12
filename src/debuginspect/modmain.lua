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