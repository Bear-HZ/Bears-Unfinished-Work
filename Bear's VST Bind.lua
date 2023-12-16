script_name("Bear's VST Bind")
script_description("A HZRP mod that selects a /vst slot based on the number typed when a hotkey (configurable with /vstkey) is held down.")
script_author("Bear")
script_version("0.1.1")

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
			key = 19 -- Pause/Break key: 19
		}
	}

	inicfg.save(config, config_file_path)
end

local requestedVstItem = nil

function sampev.onShowDialog(dialogId)
	if dialogId == 80 and requestedVstItem ~= nil then
		sampSendDialogResponse(dialogId, 1, requestedVstItem, _)
		requestedVstItem = nil
		return false
	end
end

function main()
	repeat wait(50) until isSampAvailable()
	
	sampAddChatMessage(script.this.name .. " | Use /vstkey to change the bind key", -1)
	
	local isKeyEditNeeded = false
	
	sampRegisterChatCommand("vstkey", function ()
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
	
	local function isKeyDownWithCond(key, shouldChatBeClosed, shouldDialogBeClosed)
		if isKeyDown(key) then
			if (shouldChatBeClosed and sampIsChatInputActive()) or (shouldDialogBeClosed and sampIsDialogActive()) then
				return false
			end
			return true
		else return false
		end
	end
	
	local wasReuseNonImmediate, wasChatOpenPrior = true, false
	
	repeat
		if isKeyDownWithCond(config.General.key, false, true) then
			if sampIsChatInputActive() then
				wasChatOpenPrior = true
				sampSetChatInputEnabled(false)
			end
			local vst_index_str, isKeypressNonRedundant = "", {}
			for i = 1, 10 do table.insert(isKeypressNonRedundant, true) end
			
			while isKeyDownWithCond(config.General.key, false, true) and #vst_index_str < 2 and (#vst_index_str ~= 1 or (tonumber(vst_index_str) < 3)) do
				for i = 48, 57 do
					if wasKeyReleased(i) then isKeypressNonRedundant[i - 47] = true end
					if isKeyDownWithCond(i, false, true) and #vst_index_str < 2 and isKeypressNonRedundant[i - 47] then
						if not (#vst_index_str == 0 and i == 48) then
							vst_index_str = vst_index_str .. tostring(i - 48)
						end
						isKeypressNonRedundant[i - 47] = false
					end
				end
				wait(0)
			end
			
			if #vst_index_str > 0 then
				requestedVstItem = tonumber(vst_index_str) - 1
			end
			if #vst_index_str > 0 or wasReuseNonImmediate then
				sampSendChat("/vst")
				wasReuseNonImmediate = false
			end
			
			repeat
				local areNoNumKeysPressed = true
				for i = 48, 57 do
					if isKeyDownWithCond(i, false, false) then areNoNumKeysPressed = false end
				end
				wait(0)
			until areNoNumKeysPressed
			
			if #vst_index_str > 0 then
				for i = 1, 3000 do -- 30-sec timer
					if requestedVstItem == nil then break end
					wait(10)
				end
				if requestedVstItem then requestedVstItem = nil end
			end
		else
			if not wasReuseNonImmediate then wasReuseNonImmediate = true end
			if wasChatOpenPrior then
				wasChatOpenPrior = false
				sampSetChatInputEnabled(true)
			end
		end
		wait(10)
	until false
end