script_name("Repairnear")
script_description("A HZRP mod that offers a repair to a nearby vehicle's occupant based on the seat number typed while a certain hotkey (configurable with /rnrkey) is held down.")
script_authors("akacross", "Bear")
script_version("0.2.1")

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

local menu = {
	isNeeded = false, str = "",
	posX = 0, posY = 0,
	boxWidth = 0, boxHeight = 0
}
local textSize = 20
local font = renderCreateFont("Calibri", textSize)

function onD3DPresent()
	if menu.isNeeded and not isPauseMenuActive() then
		renderDrawBox(menu.posX, menu.posY, menu.boxWidth, menu.boxHeight, 0xFF000000)
		renderFontDrawText(font, menu.str, menu.posX + (textSize / 2), menu.posY + (textSize / 2), 0xFFFFFFFF, true)
	end
end

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	repeat wait(50) until isSampAvailable()
	repeat wait(50) until string.find(sampGetCurrentServerName(), "Horizon Roleplay")
	
	sampAddChatMessage(script.this.name .. " | Use /rnrkey to change the bind key", -1)
	
	local isKeyEditNeeded = false
	
	sampRegisterChatCommand("rnrkey", function ()
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
	
	local maxDist = 10
	
	---------------------
	-- Change repair price here
	local repairPrice = 1
	---------------------
	
	local function isRepairKeyPressedOnFoot()
		return isKeyDown(config.General.key) and isCharOnFoot(PLAYER_PED)
	end
	
	local function get_distance_to_vehicle(veh)
		local myX, myY, myZ = getCharCoordinates(playerPed)
		local vehX, vehY, vehZ = getCarCoordinates(veh)
		return getDistanceBetweenCoords3d(myX, myY, myZ, vehX, vehY, vehZ)
	end
	
	while true do
		wait(10)
		if isRepairKeyPressedOnFoot() then
			local closestVehicle = {handle, dist}
			local myX, myY, myZ = getCharCoordinates(playerPed)
			repeat
				local result, veh = findAllRandomVehiclesInSphere(myX, myY, myZ, maxDist, true, true)
				if result then
					local distToVeh = get_distance_to_vehicle(veh)
					if closestVehicle.handle == nil or closestVehicle.dist == nil or (distToVeh and (distToVeh < closestVehicle.dist)) then
						closestVehicle.handle = veh
						closestVehicle.dist = distToVeh
					end
				end
			until not result
			
			local repairCandidates = {}
			local light, marker
			
			if closestVehicle.handle then
				local charHandle, result, playerId, playerName
				charHandle = getDriverOfCar(closestVehicle.handle)
				if charHandle then
					result, playerId = sampGetPlayerIdByCharHandle(charHandle)
					if result and sampIsPlayerConnected(playerId) then
						playerName = sampGetPlayerNickname(playerId):gsub("_", " ")
						if playerName then
							table.insert(repairCandidates, {49, "1", playerName, playerId})
						end
					end
				end
				local maxPassengers = getMaximumNumberOfPassengers(closestVehicle.handle)
				if maxPassengers > 0 then
					for i = 1, maxPassengers do
						if not isCarPassengerSeatFree(closestVehicle.handle, i - 1) then
							charHandle = getCharInCarPassengerSeat(closestVehicle.handle, i - 1)
							if charHandle then
								result, playerId = sampGetPlayerIdByCharHandle(charHandle)
								if result and sampIsPlayerConnected(playerId) then
									playerName = sampGetPlayerNickname(playerId):gsub("_", " ")
									if playerName then
										table.insert(repairCandidates, {i + 49, tostring(i + 1), playerName, playerId})
									end
								end
							end
						end
					end
				end
				
				if #repairCandidates > 0 then
					menu.str = ""
					menu.boxWidth = 0
					local candidateCount = #repairCandidates
					for candidateIndex, candidate in pairs(repairCandidates) do
						local currentLine = candidate[2] .. " - " .. candidate[3]
						menu.str = menu.str .. currentLine
						if candidateIndex ~= candidateCount then
							menu.str = menu.str .. "\n"
						end
						local currentLineLength = renderGetFontDrawTextLength(font, currentLine, true)
						if currentLineLength > menu.boxWidth then
							menu.boxWidth = currentLineLength
						end
					end
					menu.boxWidth = menu.boxWidth + textSize
					menu.boxHeight = textSize * 3 / 2 * candidateCount + textSize
				else
					menu.str = "Unoccupied vehicle"
					menu.boxWidth = renderGetFontDrawTextLength(font, menu.str, true) + textSize
					menu.boxHeight = textSize * 3 / 2 + textSize
				end
				local resX, resY = getScreenResolution()
				menu.posX = (resX / 2) - (menu.boxWidth / 2)
				menu.posY = (resY / 2) - (menu.boxHeight / 2)
				menu.isNeeded = true
				
				light = createObject(19296, 0, 0, -100)
				marker = createObject(19605, 0, 0, -100)
				attachObjectToCar(light, closestVehicle.handle, 0, 0, 0, 0, 0, 0)
				attachObjectToCar(marker, closestVehicle.handle, 0, 0, 1, 0, 0, 0)
			end
			
			while isRepairKeyPressedOnFoot() do
				for _, candidate in pairs(repairCandidates) do
					if isKeyDown(candidate[1]) and isCharOnFoot(PLAYER_PED) then
						if sampIsPlayerConnected(candidate[4]) then
							sampSendChat("/repair " .. tostring(candidate[4]) .. " " .. tostring(repairPrice))
						end
						while isKeyDown(candidate[1]) do wait(0) end
						break
					end
				end
				wait(0)
			end
			
			menu.isNeeded = false
			deleteObject(light)
			deleteObject(marker)
		end
	end	
end