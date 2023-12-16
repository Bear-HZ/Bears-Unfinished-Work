script_name("Key ID Detector")
script_description("Use /kidd to display the virtual key code of a key being pressed.")
script_author("Bear")
script_version("0.1.0")

local fontFlags = require("moonloader").font_flag

local isDisplayNeeded, isAnyKeyPressed, window_resX, window_resY, kid_str = false, false

local function fetchRes()
	window_resX, window_resY = getScreenResolution()
end

fetchRes()

local function textSize()
	return window_resY / 50
end

local font

local function configureFont()
	font = renderCreateFont("Calibri", textSize(), fontFlags.BORDER + fontFlags.SHADOW)
end

configureFont()

function onD3DPresent()
	if isDisplayNeeded and isAnyKeyPressed and not isPauseMenuActive() and sampGetChatDisplayMode() > 0 then
		renderFontDrawText(font, kid_str, window_resX * 0.5, window_resY * 0.5, 0xFFFFFFFF, true)
	end
end

function main()
	repeat wait(50) until isSampAvailable()
	
	sampAddChatMessage("-- Key ID Detector - Use /kidd", -1)
	
	sampRegisterChatCommand("kidd", function ()
		isDisplayNeeded = not isDisplayNeeded
	end)
	
	lua_thread.create(function()
		local r1_x, r1_y
		
		while true do
			r1_x, r1_y = getScreenResolution()
			wait(1000)
			fetchRes()
			
			if not (r1_x == window_resX and r1_y == window_resY) then configureFont() end
		end
	end)
	
	while true do
		if isDisplayNeeded then
			for i = 0, 255 do
				if not isDisplayNeeded then
					break
				elseif isKeyDown(i) then
					kid_str = tostring(i)
					isAnyKeyPressed = true
					while isDisplayNeeded and isKeyDown(i) do wait(10) end
					isAnyKeyPressed = false
				end
			end
		end
		wait(100)
	end
end