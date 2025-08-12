local serpent = require "utils.serpent"
local xpcall = GLOBAL.xpcall
local loadstring = GLOBAL.loadstring

local SERPENT_OPTS = {
	metatostring = false, -- so klei classes dont get converted to string
	nocode = true, -- fixes decoding issue that can happen sometimes
	maxlevel = 1,
}

local function SerializeObject(obj)
	return serpent.dump(obj, SERPENT_OPTS)
end

local function EvalLuaSafe(str)
	local result = nil
	xpcall(function()
		result = loadstring("return "..str)()
	end, function(error) print(error) end)

	return result -- can be nil
end

AddModRPCHandler("gbj_debuginspect", "request_obj", function(player, query_str)
	local obj = EvalLuaSafe(query_str)
	if not obj then return end

	local rpc = GetClientModRPC("gbj_debuginspect", "display_obj")
	local obj_serialized = SerializeObject(obj)
	SendModRPCToClient(rpc, player.userid, obj_serialized)
end)
AddClientModRPCHandler('gbj_debuginspect', 'display_obj', function() end) -- dummy