script_name("Bear's Flight System")
script_description("This multi-mod comprises of: (1) A vastly better-than-stock flight camera, and (2) an aircraft rotation locker that vastly reduces the amount of player key input required for aircraft articulation.")
script_version("0.2.0")

require "moonloader"
local inicfg = require "inicfg"

------------------------------------
-- Config
------------------------------------

local default_cfg = {
	CamLockKeys = {
		32 -- Spacebar: 32
	},
	CamOptions = {
		doesLockEnableUponEntry = false, doesLockDisableUponExit = true, isDefaultPlacementBehind = true
	},
	
	RotationLockKeys = {
		163 -- RCtrl: 32
	},
	PitchToggleKeys = {
		90 -- Z: 90
	},
	RollToggleKeys = {
		88 -- X; 88
	},
	YawToggleKeys = {
		67 -- C: 67
	},
	allAxesToggleKeys = {
		161 -- RShift: 161
	},
	RotationOptions = {
		isPitchUnlocked = false, isRollUnlocked = false, isYawUnlocked = false,
		doesLockEnableUponEntry = false, doesLockDisableUponExit = true
	}
}

local cfg_dir_path = getWorkingDirectory() .. "\\config\\"
if not doesDirectoryExist(cfg_dir_path) then createDirectory(cfg_dir_path) end
local cfg_file_path = cfg_dir_path .. script.this.name .. " " .. script.this.version .. ".ini"
local cfg

if doesFileExist(cfg_file_path) then
	cfg = inicfg.load(default_cfg, cfg_file_path)
else
	local new_cfg = io.open(cfg_file_path, "w")
	new_cfg:close()
	
	cfg = default_cfg
	inicfg.save(cfg, cfg_file_path)
end

------------------------------------
-- D3D
------------------------------------

--[[function onD3DPresent()
	-- All execution was originally placed here, but that caused an issue.
	-- Particularly the keystate detection code had to be moved to main() to prevent the issue.
	-- Although I did move everything to main(), I did plan on moving some code back here, particularly the camera setting logic, to limit execution to once every frame in an effort to optimize.
	-- It hasn't felt necessary to do so, but if you're keen, go ahead and move some logic here (other than keystate detection stuff)
end]]--

------------------------------------
-- Main
------------------------------------

function main()
	------------------------------------
	-- Vars & funcs
	------------------------------------
	
	------------------
	-- Commons
	------------------
	
	
	local chat_msg_color = "{FF00CC}"
	local chat_msg_prefix = chat_msg_color .. "[===={FFFFFF} " .. script.this.name .. " " .. chat_msg_color .. "====]{FFFFFF} "
	local print_msg_prefix = "[" .. script.this.name .. "] "
	
	--[[
	-- Memory hacking library
	
	local saMem = require "SAMemory"
	saMem.require 'CCamera'
	--saMem.require 'CVehicle'
	local cam = saMem.camera
	local aCams = saMem.camera.aCams[0]
	]]--
	
	--local pi = math.pi
	--[[local function heading_centered_radians()
		local heading = math.atan2(saMem.player_vehicle[0].pMatrix.at.y, saMem.player_vehicle[0].pMatrix.at.x) - (pi / 2)
		if heading < -pi then
			heading = heading + (2 * pi)
		end
		return heading
	end]]--
	
	local isSampRunning, isConfigSaveNeeded = false, false
	
	local isKeyReleaseAwaited = {
		camToggle = {true},
		rot = {
			lockToggle = {true}, pitchToggle = {true}, rollToggle = {true}, yawToggle = {true}, allAxesToggle = {true}
		}
	}
	
	local function processOnKeyPress(t_keyCodes, t_keyReleaseAwaitState, isConfigSaveFlagNeeded, funcToExec)
		for _, keyCode in pairs(t_keyCodes) do
			if isKeyDown(keyCode) then
				if not t_keyReleaseAwaitState[1] then
					t_keyReleaseAwaitState[1] = true
					funcToExec()
					
					if isConfigSaveFlagNeeded then
						if not isConfigSaveNeeded then isConfigSaveNeeded = true end
					end
				end
			elseif t_keyReleaseAwaitState[1] then
				t_keyReleaseAwaitState[1] = false
			end
		end
	end
	
	local function isSampChatOrDialogOpen()
		return isSampRunning and (sampIsChatInputActive() or sampIsDialogActive())
	end
	
	------------------
	-- Cam lock
	------------------
	
	local isCamLockNeeded, shouldCamBeBehindPlayer = cfg.CamOptions.doesLockEnableUponEntry, cfg.CamOptions.isDefaultPlacementBehind
	
	------------------
	-- Rotation lock
	------------------
	
	local rotationTrackingProp, currentFlyingVehicle
	local isRotationLockNeeded, isRotationTrackingReady = cfg.RotationOptions.doesLockEnableUponEntry, false
	
	
	------------------------------------
	-- Execution
	------------------------------------
	
	lua_thread.create(function ()
		repeat wait(1000) until isSampAvailable ~= nil and isSampAvailable()
		
		isSampRunning = true
		
		sampAddChatMessage(chat_msg_prefix .. "Use /bfc to Configure", -1)
		
		sampRegisterChatCommand("bfc", function ()
			sampAddChatMessage(chat_msg_prefix .. "Menu Undeveloped", -1)
		end)
	end)
	
	repeat
		if isCharInFlyingVehicle(PLAYER_PED) and isCharSittingInAnyCar(PLAYER_PED) then
			------------------------------------
			-- Flight control
			------------------------------------
			
			while isCharInFlyingVehicle(PLAYER_PED) and isCharSittingInAnyCar(PLAYER_PED) do
				------------------
				-- Cam lock
				------------------
				
				processOnKeyPress(cfg.CamLockKeys, isKeyReleaseAwaited.camToggle, false, function ()
					if not isSampChatOrDialogOpen() then
						if isCamLockNeeded then
							shouldCamBeBehindPlayer = not shouldCamBeBehindPlayer
						else
							if shouldCamBeBehindPlayer ~= cfg.CamOptions.isDefaultPlacementBehind then
								shouldCamBeBehindPlayer = cfg.CamOptions.isDefaultPlacementBehind
							end
							
							isCamLockNeeded = true
						end
					end
				end)
				
				local mouseX, mouseY = getPcMouseMovement()
				
				if isCamLockNeeded then
					if mouseX == 0 and mouseY == 0 then
						if shouldCamBeBehindPlayer then
							--------------------------
							-- DEVELOPMENT EXPLANATION
							
							--[[
							
							I wanted to create a GTA V-sty;e flight cam, but while down the rabbit hole of figuring the easiest implementation, I quit playing SAMP and abandoned all development.
							
							I'll leave some code that I was testing if someone wants to carry on.
							
							]]--
							--------------------------
							
							-- This gets you to a GTA V-style cam most of the way, but the cam doesn't tilt vertically. Ideally the vehicle's speed vector direction would determine the camera tilt.
							setCameraBehindPlayer()
							
							--------------------------
							
							-- From-scratch relative camera, which would take a lot of effort to develop
							-- attachCameraToVehicle(currentFlyingVehicle, 0, -15, 5, 0, 30, 0, 0, 2)
							
							--------------------------
							
							-- Everyting below is a rat's nest of memory-hacking code that I was testing.
							-- While I DID manage to create a GTA V-style camera (or something even better), the camera had this stuttering issue that I couldn't find a way to address after countless hours of attempt.
							-- Don't just un-comment all the code below. Some snippets were created to work alone or with specific other ones.
							-- If you're enough of a flight nut and have the programming skill, you'll find a way to get to where I got and maybe my code can help you get there sooner.
							-- And of course, getting the vertical tilt is just one problem. There are other algorithms I created to optimize visibility and prevent rapid camera movements.
							
							--[[local newVertAng, newHorzAng
							
							local vehHeading = getCarHeading(currentFlyingVehicle)
							newHorzAng = math.rad(vehHeading - ((vehHeading > 270) and 450 or 90))
							
							local spX, spY, spZ = getCarSpeedVector(currentFlyingVehicle)
							
							local speedPitch = math.atan2(spZ, math.sqrt(spX^2 + spY^2))
							
							local maxCamRotSp = 0.01
							local currentVertAng, currentHorzAng = aCams.fVerticalAngle, aCams.fHorizontalAngle
							local camPitchDelta = speedPitch - currentVertAng
							if camPitchDelta > maxCamRotSp then
								newVertAng = currentVertAng + maxCamRotSp
							elseif camPitchDelta < (- maxCamRotSp) then
								newVertAng = currentVertAng - maxCamRotSp
							else
								newVertAng = speedPitch
							end
							--local camHeadingDelta = newHorzAng - currentHorzAng
							--if camHeadingDelta > maxCamRotSp then
								--newHorzAng = currentHorzAng + maxCamRotSp
							--elseif camHeadingDelta < (- maxCamRotSp) then
								--newHorzAng = currentHorzAng - maxCamRotSp
							--end
							
							local speedHeading = math.atan2(spY, spX) + pi
							if speedHeading > pi then
								speedHeading = speedHeading - (pi * 2)
							end
							
							local headingDelta = newHorzAng - speedHeading
							if headingDelta > pi then
								headingDelta = headingDelta - (pi * 2)
							elseif headingDelta < (- pi) then
								headingDelta = headingDelta + (pi * 2)
							end
							headingDelta = math.abs(headingDelta)
							--if math.abs(headingDelta) > (pi / 2) then
								newVertAng = newVertAng - ((headingDelta / pi) * (newVertAng * 2))
							--end
							
							--setCameraPositionUnfixed(newVertAng, newHorzAng)
							aCams.fHorizontalAngle = newHorzAng
							aCams.fVerticalAngle = newVertAng]]--
							
							--[[ha = ha == nil and 0 or ha + 0.01
							if ha > pi then ha = ha - (pi * 2) end
							va = va == nil and -(pi/4) or va + 0.01
							if va > pi/4 then va = va - (pi/2) end
							
							aCams.fHorizontalAngle = ha
							aCams.fVerticalAngle = va]]--
							
							--------------------------
						else
							-- The bulk of the code was supposed to be outside this if statement, and inside it there would be minor mechanics tweaks for both forward and backward viewing.
							setCameraInFrontOfPlayer()
						end
					else
						isCamLockNeeded = false
					end
				end
				
				------------------
				-- Rotation lock
				------------------
				
				if isRotationTrackingReady then
					if getDriverOfCar(currentFlyingVehicle) == PLAYER_PED and not isSampChatOrDialogOpen() then
						processOnKeyPress(cfg.RotationLockKeys, isKeyReleaseAwaited.rot.lockToggle, false, function() isRotationLockNeeded = not isRotationLockNeeded end)
						processOnKeyPress(cfg.PitchToggleKeys, isKeyReleaseAwaited.rot.pitchToggle, true, function () cfg.RotationOptions.isPitchUnlocked = not cfg.RotationOptions.isPitchUnlocked end)
						processOnKeyPress(cfg.RollToggleKeys, isKeyReleaseAwaited.rot.rollToggle, true, function () cfg.RotationOptions.isRollUnlocked = not cfg.RotationOptions.isRollUnlocked end)
						processOnKeyPress(cfg.YawToggleKeys, isKeyReleaseAwaited.rot.yawToggle, true, function () cfg.RotationOptions.isYawUnlocked = not cfg.RotationOptions.isYawUnlocked end)
						processOnKeyPress(cfg.allAxesToggleKeys, isKeyReleaseAwaited.rot.allAxesToggle, true, function ()
							if cfg.RotationOptions.isPitchUnlocked or cfg.RotationOptions.isRollUnlocked or cfg.RotationOptions.isYawUnlocked then
								cfg.RotationOptions.isPitchUnlocked, cfg.RotationOptions.isRollUnlocked, cfg.RotationOptions.isYawUnlocked = false, false, false
							else
								cfg.RotationOptions.isPitchUnlocked, cfg.RotationOptions.isRollUnlocked, cfg.RotationOptions.isYawUnlocked = true, true, true
							end
						end)
						
						if isRotationLockNeeded and isCarInAirProper(currentFlyingVehicle) then
							local areAddedObjsUntouched = true
							for _, addedObj in pairs(getAllObjects()) do
								if isVehicleTouchingObject(currentFlyingVehicle, addedObj) then
									areAddedObjsUntouched = false
									break
								end
							end
							
							if areAddedObjsUntouched then
								local propRotVelX, propRotVelY, propRotVelZ = getObjectRotationVelocity(rotationTrackingProp)
								
								if cfg.RotationOptions.isPitchUnlocked or isButtonPressed(0, 1) then -- pitch
									propRotVelX = 0
								end
								if cfg.RotationOptions.isRollUnlocked or isButtonPressed(0, 0) then -- roll
									propRotVelY = 0
								end
								if cfg.RotationOptions.isYawUnlocked or isButtonPressed(0, 5) or isButtonPressed(0, 7) then -- yaw
									propRotVelZ = 0
								end
								
								addToCarRotationVelocity(currentFlyingVehicle, - propRotVelX, - propRotVelY, - propRotVelZ)
							end
						end
					end
				else
					currentFlyingVehicle = getCarCharIsUsing(PLAYER_PED)
					
					rotationTrackingProp = createObject(1862, 0, 0, -100)
					setObjectScale(rotationTrackingProp, 0) -- makes the prop invisible
					attachObjectToCar(rotationTrackingProp, currentFlyingVehicle, 0, 0, 0, 0, 0, 0)
					
					isRotationTrackingReady = true
				end
				
				------------------
				-- Config save
				------------------
				
				if isConfigSaveNeeded then
					lua_thread.create(function ()
						isConfigSaveNeeded = false
						
						if not inicfg.save(cfg, cfg_file_path) then
							if isSampRunning then
								sampAddChatMessage(chat_msg_prefix .. "Unable to Save Data to Config - Contact the Developer for Help", -1)
							else
								printStringNow(print_msg_prefix .. "Unable to Save Data to Config - Contact the Developer for Help", 10000)
							end
						end
					end)
				end
				
				wait(0)
			end
			
			------------------------------------
			-- Exit processing
			------------------------------------
			
			------------------
			-- Cam lock
			------------------
			
			if cfg.CamOptions.doesLockEnableUponEntry and not isCamLockNeeded then
				isCamLockNeeded = true
			elseif cfg.CamOptions.doesLockDisableUponExit and isCamLockNeeded then
				isCamLockNeeded = false
			end
			
			if shouldCamBeBehindPlayer ~= cfg.CamOptions.isDefaultPlacementBehind then
				shouldCamBeBehindPlayer = cfg.CamOptions.isDefaultPlacementBehind
			end
			
			------------------
			-- Rotation lock
			------------------
			
			isRotationTrackingReady = false
			currentFlyingVehicle = nil
			
			if doesObjectExist(rotationTrackingProp) then
				deleteObject(rotationTrackingProp)
			end
			
			if cfg.RotationOptions.doesLockEnableUponEntry and not isRotationLockNeeded then
				isRotationLockNeeded = true
			elseif cfg.RotationOptions.doesLockDisableUponExit and isRotationLockNeeded then
				isRotationLockNeeded = false
			end
		end
		
		wait(10)
	until false
end