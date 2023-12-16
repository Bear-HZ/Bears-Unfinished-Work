script_name("Emptysafe")
script_description("Use /emptysafe or press the hotkey (configurable using /esfkey) to clear out a businesses's safe in HZRP.")
script_author("Bear")
script_version("0.3.0")

require "moonloader"
require "sampfuncs"
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
			key = 74 -- J key: 74
		}
	}

	inicfg.save(config, config_file_path)
end

function main()	
	while not isSampAvailable() do wait(50) end
	sampAddChatMessage("{44FF99}Emptysafe {FFFFFF}| Use {44FF99}/emptysafe {FFFFFF}or configure hotkey with {44FF99}/esfkey", -1)
	
	local isKeyEditNeeded = false
	
	sampRegisterChatCommand("esfkey", function ()
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
	
	local isDialogAwaited = false
	local function triggerMenu()
		isDialogAwaited = true
		sampSendChat("/businessmenu")
		lua_thread.create(function ()
			wait(5000)
			isDialogAwaited = false
		end)
	end
	sampRegisterChatCommand("emptysafe", triggerMenu)
	
	local function isKeyPressed()
		return (isKeyDown(config.General.key) and not sampIsChatInputActive() and not sampIsDialogActive())
	end
	
	lua_thread.create(function ()
		while true do
			if isKeyPressed() then
				triggerMenu()
				while isKeyPressed() do wait(10) end
			end
			wait(10)
		end
	end)
	
	repeat
		repeat wait(10) until sampIsDialogActive()
		
		if sampGetDialogCaption() == "Business Menu" and isDialogAwaited then
			isDialogAwaited = false
			sampSendDialogResponse(sampGetCurrentDialogId(), 1, 3, _)
			
			repeat wait(0) until sampIsDialogActive() and sampGetDialogCaption() == "Business Menu - Safe"
			local safeBalance_str = sampGetDialogText():match("%$([%d,]+)"):gsub(",", "")
			sampCloseCurrentDialogWithButton(1)
			
			repeat wait(0) until sampIsDialogActive() and sampGetDialogCaption() == "Business Menu - Safe Withdraw"
			sampSendDialogResponse(sampGetCurrentDialogId(), 1, _, safeBalance_str)
			
			repeat wait(0) until sampIsDialogActive() and sampGetDialogCaption() == "Business Menu"
			sampCloseCurrentDialogWithButton(0)
		end
	until false
end