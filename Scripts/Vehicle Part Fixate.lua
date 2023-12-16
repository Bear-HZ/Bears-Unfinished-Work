script_name("Vehicle Part Fixate")
script_description("Some vehicles have aesthetic part variations that are randomly determined for every spawn. This mod ensures that only the desired part configuration is selected for every spawn. This only affects vehicle aesthetics, not functionality.")
script_author("Bear")
script_version("0.1.0")

require "moonloader"
require "sampfuncs"
local sampev = require "lib.samp.events"

local partSettings = {
	{521, 4, 3} -- FCR-900 w/ full sideskirts & no exhausts
}

local function setPartsForNextVehicle(partSetting) -- creates part settings for the next vehicle to spawn, of the specific model id
	setCarModelComponents(partSetting[1], partSetting[2], partSetting[3])
end

function sampev.onVehicleStreamIn(_, data)
	for _, partSetting in pairs(partSettings) do
		if partSetting[1] == data.type then
			setPartsForNextVehicle(partSetting) -- component settings for the vehicle streamed in AFTER the one detected here
		end
	end
end

function main()
	repeat wait(50) until isSampAvailable()
	
	if #partSettings > 0 then
		for i = 1, #partSettings do
			setPartsForNextVehicle(partSettings[i]) -- component settings for the first vehicle spawned of the given model id
		end
	end
	
	-- Part testing command
	-- NOTE: changes made using this command only last until the script terminates. Use it to test part variations and add part profiles in the partSettings table in the script itself.
	sampRegisterChatCommand("psel", function (arg)
		local _, _, veh, cmp1, cmp2 = arg:find("(%d+) (%d+) (%d+)")
		if veh == nil or cmp1 == nil or cmp2 == nil then
			sampAddChatMessage("input error", -1)
		else
			setCarModelComponents(tonumber(veh), tonumber(cmp1), tonumber(cmp2))
			sampAddChatMessage("applied: " .. veh .. " " .. cmp1 .. " " .. cmp2, -1)
		end
	end)
end