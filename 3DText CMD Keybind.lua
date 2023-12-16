script_name("3DText CMD Keybind")
script_description("Submits a server command, read out of a nearby 3DText, using a hotkey configurable with /3dtkey.")
script_author("Bear")
script_version("0.3.0")

local sampev = require "lib.samp.events"
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

local cmdContaining3dtexts, cmdRange, cmdExceptions = {}, 3, {"/exceptionexample"}

function sampev.onCreate3DText(id, color, pos, dist, testLOS, pId, vId, text)
	-- Redundancy test
	for _, tabulated3dtext in pairs(cmdContaining3dtexts) do
		if pos.x == tabulated3dtext[2].x and pos.y == tabulated3dtext[2].y and pos.z == tabulated3dtext[2].z then return true end
	end
	local cmd
	if text:find("%s/%S") then
		cmd = text:match("%s(/%S+)")
	elseif text:find("^/%S") then
		cmd = text:match("^(/%S+)")
	end
	if cmd ~= nil then
		for _, exceptionedCmd in pairs(cmdExceptions) do
			if cmd == exceptionedCmd then return true end
		end
		table.insert(cmdContaining3dtexts, {id, pos, cmd})
	end
end

function main()
	repeat wait(50) until isSampAvailable()
	
	sampAddChatMessage(script.this.name .. " | Use /3dtkey to change the bind key", -1)
	
	local isKeyEditNeeded = false
	
	sampRegisterChatCommand("3dtkey", function ()
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
	
	local function isEntryKeyPressed()
		return (isKeyDown(entryKey) and not sampIsChatInputActive() and not sampIsDialogActive())
	end
	
	while true do
		if isEntryKeyPressed() then
			local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
			for _, selected3dtext in pairs(cmdContaining3dtexts) do
				if sampIs3dTextDefined(selected3dtext[1]) and getDistanceBetweenCoords3d(posX, posY, posZ, selected3dtext[2].x, selected3dtext[2].y, selected3dtext[2].z) < cmdRange then
					sampSendChat(selected3dtext[3])
					break
				end
			end
			while isEntryKeyPressed() do wait(10) end
		end
		wait(10)
	end
end