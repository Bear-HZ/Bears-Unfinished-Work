script_name("MyCarColors")
script_description("Use /mcc or /mycarcolors to fetch the color IDs (and the paint ID) of a vehicle you're using.")
script_author("Bear")
script_version("0.1.0")

require "moonloader"
require "sampfuncs"

function main()
	repeat wait(50) until isSampAvailable()
	
	local function mcc()
		if isCharInAnyCar(PLAYER_PED) then
			local veh = getCarCharIsUsing(PLAYER_PED)
			local primaryColor, secondaryColor = getCarColours(veh)
			local paintjob = getCurrentVehiclePaintjob(veh)
			sampAddChatMessage("Colors: " .. tostring(primaryColor or "?") .. ", " .. tostring(secondaryColor or "?") .. " | " .. "Paintjob: " .. tostring(paintjob or "?"), -1)
			
		else
			sampAddChatMessage("Not in a vehicle", -1)
		end
	end
	
	sampRegisterChatCommand("mcc", mcc)
	sampRegisterChatCommand("mycarcolors", mcc)
	
	while true do wait(10000) end
end