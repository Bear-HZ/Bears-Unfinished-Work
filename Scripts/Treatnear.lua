script_name("Treatnear")
script_description("Uses /ti (/treatinjury) on the nearest player performing one of the injury animations in HZRP, on the press of a hotkey (configurable with /tnrkey).")
script_authors("akacross", "Bear")
script_version("1.0.0")

local maxDist = 2.5

require "lib.moonloader"
require "lib.sampfuncs"
local inicfg = require "inicfg"

local config_dir_path = getWorkingDirectory() .. "\\config\\"
if not doesDirectoryExist(config_dir_path) then createDirectory(config_dir_path) end
local config_file_path = config_dir_path .. script.this.name .. " " .. script.this.version .. ".ini"
local config
if doesFileExist(config_file_path) then
	config = inicfg.load(nil, config_file_path)
else
	local new_config = io.open(config_file_path, "w")
	new_config:close()
	
	config = {
		General = {
			key = 163 -- RCtrl key: 163
		}
	}

	inicfg.save(config, config_file_path)
end

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	repeat wait(50) until isSampAvailable()
	repeat wait(50) until string.find(sampGetCurrentServerName(), "Horizon Roleplay")
	
	local isKeyEditNeeded = false
	
	sampRegisterChatCommand("tnrkey", function ()
		isKeyEditNeeded = true
	end)
	
	lua_thread.create(function ()
		while true do
			if isKeyEditNeeded then
				isKeyEditNeeded = false
				sampAddChatMessage("[" .. script.this.name .. "] Press and release the desired bind key", -1)
				repeat
					local isKeyFound = false
					for i = 0, 255 do
						if isKeyDown(i) then
							while isKeyDown(i) do wait(0) end
							config.General.key = i
							if inicfg.save(config, config_file_path) then
								sampAddChatMessage("[" .. script.this.name .. "] Key set to: " .. tostring(i) .. " (virtual key code)", -1)
							else
								sampAddChatMessage("[" .. script.this.name .. "] Saving key ID failed.", -1)
							end
							isKeyFound = true
							break
						end
					end
					wait(0)
				until isKeyFound
			end
			wait(100)
		end
	end)
	
	local function isTreatKeyPressedOnFoot()
		return isKeyDown(config.General.key) and isCharOnFoot(PLAYER_PED)
	end

	local function getClosestTreatmentCandidateId()
		local maxplayerid = sampGetMaxPlayerId(false)
		local closestCandidate = {id, dist}
		for i = 0, maxplayerid do
			if sampIsPlayerConnected(i) then
				local result, ped = sampGetCharHandleBySampPlayerId(i)
				if result then
					local dist = get_distance_to_player(i)
					if dist < maxDist then
						if isCharPlayingAnim(ped, "gnstwall_injurd") or isCharPlayingAnim(ped, "KILL_Knife_Ped_Die") then -- Anim names: ("/fallover 1": "gnstwall_injurd") | ("/hurt": "KILL_Knife_Ped_Die")
							if closestCandidate.id == nil or closestCandidate.dist == nil or dist < closestCandidate.dist then
								closestCandidate.id = i
								closestCandidate.dist = dist
							end
						end
					end
				end
			end
		end
		return closestCandidate.id or -1
	end

	function get_distance_to_player(playerId)
		local dist = -1
		if sampIsPlayerConnected(playerId) then
			local result, ped = sampGetCharHandleBySampPlayerId(playerId)
			if result then
				local myX, myY, myZ = getCharCoordinates(playerPed)
				local playerX, playerY, playerZ = getCharCoordinates(ped)
				dist = getDistanceBetweenCoords3d(myX, myY, myZ, playerX, playerY, playerZ)
				return dist
			end
		end
		return dist
	end
	
	while true do
		wait(10)
		if isTreatKeyPressedOnFoot() then
			while isTreatKeyPressedOnFoot() do wait(0) end
			if isCharOnFoot(PLAYER_PED) then
				local playerid = getClosestTreatmentCandidateId()
				if sampIsPlayerConnected(playerid) then 
					sampSendChat(string.format("/ti %d", playerid))
					wait(500)
				end
			end
		end
	end	
end
