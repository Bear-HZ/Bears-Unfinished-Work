script_name("Character Angle Display")
script_description("Use /ang to display the Z-angle at which your character (or the vehicle that you're using) is pointed. Precision-parking is one use case.")
script_author("Bear")
script_version("0.1.0")

local fontFlags = require("moonloader").font_flag

local isDisplayNeeded = false

local window_resX, window_resY

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
	if isDisplayNeeded and not isPauseMenuActive() and sampGetChatDisplayMode() > 0 then
		local ch_ang = tostring(getCharHeading(PLAYER_PED))
		renderFontDrawText(font, ch_ang, window_resX * 0.5, window_resY * 0.5, 0xFFFFFFFF, true)
	end
end

function main()
	repeat wait(50) until isSampAvailable()
	
	sampAddChatMessage(script.this.name .. " | Use /ang", -1)
	
	lua_thread.create(function()
		local r1_x, r1_y
		
		while true do
			r1_x, r1_y = getScreenResolution()
			wait(1000)
			fetchRes()
			
			if not (r1_x == window_resX and r1_y == window_resY) then configureFont() end
		end
	end)
	
	sampRegisterChatCommand("ang", function ()
		isDisplayNeeded = not isDisplayNeeded
	end)
end