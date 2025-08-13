local InspectConsoleScreen = require "debuginspect.widgets.screens.inspectconsolescreen"
local InspectOverlayScreen = require "debuginspect.widgets.screens.inspectoverlayscreen"
local InspectFunctionPopup = require "debuginspect.widgets.screens.inspectfunctionpopup"

local DICommon = {}

function DICommon.EvalLuaSafe(str)
	local result = nil
	xpcall(function()
		result = loadstring("return "..str)()
	end, function(error) print(error) end)

	return result -- can be nil
end

function DICommon.DeserializeObject(obj_str)
	local fun, err = loadstring(obj_str)
	if err then
		print("Debug Inspect: Error deserializing:", err)
		return
	end
	local obj = fun()
	return obj
end

function DICommon.FindScreen(class)
	if not TheFrontEnd then return end

	for index,screen in ipairs(TheFrontEnd.screenstack) do
		if screen:is_a(class) then return screen, index end
	end
end

function DICommon.OpenInspectOverlay(obj, remote_explore_mode, remote_explore_query)
	if type(obj) == "function" then
		-- we have a dedicated function details ui
		local functiondetailsoverlay, index = DICommon.FindScreen(InspectFunctionPopup)
		local overlay, index = DICommon.FindScreen(InspectOverlayScreen)
		if overlay then
			-- inspect overlay always opens by default,
			-- close it since we're not using it this time
			overlay:Close()
		end

		if functiondetailsoverlay then
			overlay:Close()
			TheFrontEnd:PushScreen(InspectFunctionPopup(obj))
			return
		end
		TheFrontEnd:PushScreen(InspectFunctionPopup(obj))
		return
	end

	local remote_explore_mode = remote_explore_mode or false
	local overlay, index = DICommon.FindScreen(InspectOverlayScreen)
	local screen_on_top = overlay and index == #TheFrontEnd.screenstack

	if overlay and (not screen_on_top) then
		-- something else is covering the overlay, reopen it
		overlay:Close()
		DICommon.OpenInspectOverlay(obj, remote_explore_mode, remote_explore_query)
		return
	end

	if overlay then
		overlay:SetRemoteExploreMode(remote_explore_mode)
		overlay:SetCurrentObject(obj)
		if remote_explore_mode and remote_explore_query then
			overlay:SetCurrentObject_Remote(remote_explore_query)
		end
		return
	end

	if not overlay then
		TheFrontEnd:PushScreen(InspectOverlayScreen(obj, remote_explore_mode, remote_explore_query))
	end
end

function DICommon.ToggleInspectConsole()
	if not TheFrontEnd then return end

	local overlay, index = DICommon.FindScreen(InspectConsoleScreen)
	if overlay then
		overlay:Close()
		return
	end
	TheFrontEnd:PushScreen(InspectConsoleScreen())
end

return DICommon