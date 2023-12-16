script_name("BusinessInfo Display")
script_description("Provides a neat table displaying info on all your businesses in HZRP, toggled by a hotkey configurable with /bidkey.")
script_author("Bear")
script_version("0.12.0")

------------------------------
-- Layout and font preferences

-- Text size
local textSize = 14

-- Box opacity (0-255)
local boxOpacity = 200

-- Title bar opacity (0-255)
local titleBarOpacity = 240

-- Table line opacity (0-255)
local lineOpacity = 120

-- Font face
local fontFace = "Calibri"

-- Bold font toggle (true or false)
local isFontBold = false

-- Italics font toggle (true or false)
local isFontItalicized = false

-- Border font toggle (true or false)
local isFontBordered = true

-- Shadow font toggle (true or false)
local isFontShadowed = true

-- All-caps toggle (true or false)
local isTextAllCaps = true

-- No. of spaces b/w table cells (int)
local cellSpacing = 5

-- Table lines for the business data (true or false)
local areTableLinesNeeded = true

-- Toggle for alternating the text color in columns (grey & white) (true or false)
local isColorAlternationNeeded = true

-- Toggle the index column (true or false)
local isIndexColumnNeeded = true
------------------------------

require "lib.moonloader"
require "lib.sampfuncs"
local sampev = require "lib.samp.events"
local fontFlags = require("moonloader").font_flag
--local ffi = require "ffi"
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
			displayKey = 161 -- RShift key: 161
		}
	}

	inicfg.save(config, config_file_path)
end

boxColor = nil
titleBarColor = nil
lineColor = nil
local function setItemOpacity(colorVarName, opacity_dec, hex_color_str)
	if opacity_dec > 255 then opacity_dec = 255
	elseif opacity_dec < 0 then opacity_dec = 0
	end
	local opacity_hex = ""
	local quotient, remainder = math.floor(opacity_dec / 16), opacity_dec % 16
	
	if quotient > 9 then
		if quotient == 10 then opacity_hex = "A" elseif quotient == 11 then opacity_hex = "B" elseif quotient == 12 then opacity_hex = "C" elseif quotient == 13 then opacity_hex = "D" elseif quotient == 14 then opacity_hex = "E" elseif quotient == 15 then opacity_hex = "F" end
	elseif quotient > 0 then
		opacity_hex = tostring(quotient)
	end
	
	if remainder > 9 then
		if remainder == 10 then opacity_hex = opacity_hex .. "A" elseif remainder == 11 then opacity_hex = opacity_hex .. "B" elseif remainder == 12 then opacity_hex = opacity_hex .. "C" elseif remainder == 13 then opacity_hex = opacity_hex .. "D" elseif remainder == 14 then opacity_hex = opacity_hex .. "E" elseif remainder == 15 then opacity_hex = opacity_hex .. "F" end
	else
		opacity_hex = opacity_hex .. tostring(remainder)
	end
	
	loadstring(colorVarName .. " = " .. "0x" .. opacity_hex .. hex_color_str)()
end
setItemOpacity("boxColor", boxOpacity, "000000")
setItemOpacity("lineColor", lineOpacity, "FFFFFF")
setItemOpacity("titleBarColor", titleBarOpacity, "000000")

local textHeight = 0
local menu = {
	isNeeded = false,
	failureText = {isNeeded = false, str = "Failed to gather data"},
	loadText = {isNeeded = false, str = "Loading..."},
	titleBar = {posX = 0, posY = 0, barHeight = 0, text = {str_prefix = "My Businesses", str = "", posX = 0, posY = 0}},
	safeTotal = {str_prefix = "Total: ", balance_str = "", display_str = ""},
	posX = 0, posY = 0,
	boxWidth = 0, boxHeight = 0, tablePageCount = 0, tablePageWidth = 0, perPageBusinessCount = 0
}
local businesses, columnWidths, drawlines_pos, interColumnDist, interRowDist = {}, {}, {}, 0, 0
local isLastLineAwaited, isLineBlockingNeeded, isInfoRequestedManually, isPlayerMuted, doesPlayerOwnNoBusinesses = false, false, false, false, false
local font = renderCreateFont(fontFace, textSize, (isFontBold and fontFlags.BOLD or 0) + (isFontItalicized and fontFlags.ITALICS or 0) + (isFontBordered and fontFlags.BORDER or 0) + (isFontShadowed and fontFlags.SHADOWED or 0))

function sampev.onServerMessage(msg_color, msg_text)
	if not string.find(sampGetCurrentServerName(), "Horizon Roleplay") then return true end
	
	if msg_text == "___________________________________________________________________________________________________" and msg_color == -5963606 then
		if isInfoRequestedManually then return true
		elseif isLineBlockingNeeded then
			return false
		end
	
	elseif msg_text == "Businesses owned by you:" and msg_color == -5963606 then
		if isInfoRequestedManually then return true
		elseif isLineBlockingNeeded then
			return false
		end
	
	elseif msg_text:match("^Name: [^|]+| Type: [^|]+| Level: [^|]+| Location: [^|]+| Safe: %$[%d,]+$") and (msg_color == -86 or msg_color == -28246) then
		if isInfoRequestedManually then return true
		else
			if msg_text:match("{%x+} | Type: ") then
				msg_text = msg_text:gsub("{%x+} | Type: ", " | Type: ")
			end
			
			local _, _, name, type, level, location, safe = msg_text:find("^Name: ([^|]+)| Type: ([^|]+)| Level: ([^|]+)| Location: ([^|]+)| Safe: (%$[%d,]+)$")
			name, type, level, location = name:sub(1, -2), type:sub(1, -2), level:sub(1, -2), location:sub(1, -2)
			if isTextAllCaps then
				name, type, location = name:upper(), type:upper(), location:upper()
			end
			if isIndexColumnNeeded then
				local ind = #businesses + 1
				table.insert(businesses, {ind, name, type, level, location, safe})
			else
				table.insert(businesses, {name, type, level, location, safe})
			end
			
			if isLineBlockingNeeded then return false end
		end
	
	elseif msg_text:sub(1, 33) == "Total money in your businesses: $" and msg_color == -5963606 then
		if isInfoRequestedManually then
			isInfoRequestedManually = false
			
			if isLastLineAwaited then
				isLastLineAwaited = false
			end
			
			return true
		else
			menu.safeTotal.balance_str = msg_text:sub(33, -1)
			
			if isLastLineAwaited then
				isLastLineAwaited = false
			end
			
			if isLineBlockingNeeded then
				return false
			end
		end
	
	elseif msg_text == "You don't own any businesses." then
		doesPlayerOwnNoBusinesses = true
	
	elseif string.sub(msg_text, 1, 48) == "You have been muted automatically for spamming. " then
		isPlayerMuted = true
	
	end
end

function onD3DPresent()
	if menu.isNeeded and not isPauseMenuActive() and not sampIsScoreboardOpen() and sampGetChatDisplayMode() > 0 then
		renderDrawBox(menu.posX, menu.posY, menu.boxWidth, menu.boxHeight, boxColor)
		if menu.failureText.isNeeded then
			renderFontDrawText(font, menu.failureText.str, menu.posX + (interColumnDist / 2), menu.posY + (interRowDist / 2), 0xFFFFFFFF, false)
		elseif menu.loadText.isNeeded then
			renderFontDrawText(font, menu.loadText.str, menu.posX + (interColumnDist / 2), menu.posY + (interRowDist / 2), 0xFFFFFFFF, false)
		else
			renderDrawBox(menu.titleBar.posX, menu.titleBar.posY, menu.boxWidth, menu.titleBar.barHeight, titleBarColor)
			renderFontDrawText(font, menu.titleBar.text.str, menu.titleBar.text.posX, menu.titleBar.text.posY, 0xFFFFFFFF, false)
			
			if areTableLinesNeeded then
				for _, drawline_pos in pairs(drawlines_pos) do
					renderDrawLine(drawline_pos[1], drawline_pos[2], drawline_pos[3], drawline_pos[4], 1, lineColor)
				end
			end
			
			for pageInd = 1, menu.tablePageCount do
				local text_posY = menu.posY + interRowDist
				local rowIndA = ((pageInd - 1) * menu.perPageBusinessCount) + 1
				local rowIndB = rowIndA + ((pageInd == menu.tablePageCount) and (#businesses - rowIndA) or (menu.perPageBusinessCount - 1))
				
				for rowInd = rowIndA, rowIndB do
					if rowInd > rowIndA then
						text_posY = text_posY + textHeight + interRowDist
					end
					local text_posX = menu.posX + interColumnDist + ((pageInd - 1) * (menu.tablePageWidth + (interColumnDist * 2)))
					local textColor = (isColorAlternationNeeded and rowInd % 2 == 0) and 0xFFAAAAAA or 0xFFFFFFFF
					
					for columnInd = 1, #businesses[rowInd] do
						if columnInd > 1 then
							text_posX = text_posX + columnWidths[columnInd - 1] + interColumnDist
						end
						renderFontDrawText(font, businesses[rowInd][columnInd], text_posX, text_posY, textColor, false)
					end
				end
			end
			
			local text_posX = menu.posX + interColumnDist
			local text_posY = menu.posY + menu.boxHeight - interRowDist - textHeight
			renderFontDrawText(font, menu.safeTotal.display_str, text_posX, text_posY, 0xFFFFFFFF, false)
		end
	end
end

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	repeat wait(50) until isSampAvailable()
	repeat wait(50) until string.find(sampGetCurrentServerName(), "Horizon Roleplay")
	
	sampAddChatMessage(script.this.name .. " | Use /bidkey to change the bind key", -1)
	
	local isKeyEditNeeded = false
	
	sampRegisterChatCommand("bidkey", function ()
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
							config.General.displayKey = i
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
	
	local interColumnStr, interRowStr = string.rep(" ", tonumber(cellSpacing)), string.rep(" ", tonumber(cellSpacing))
	interColumnDist, interRowDist = renderGetFontDrawTextLength(font, interColumnStr, false), renderGetFontDrawTextLength(font, interRowStr, false)
	textHeight = textSize * 2

	--[[local function isSampVerR3() -- Adapted from: Gamefixer.lua 3.0 - https://www.youtube.com/watch?v=2gaLqO8rR8M&start=0
		if samp_base == nil or samp_base == 0 then
			samp_base = getModuleHandle("samp.dll")
		end
		if samp_base ~= 0 then
			local e_lfanew = ffi.cast("long*", samp_base + 60)[0]
			local nt_header = samp_base + e_lfanew
			local entry_point_addr = ffi.cast("unsigned int*", nt_header + 40)[0]
			--if entry_point_addr == 0x31DF13 then
				--return "r1"
			-- elseif entry_point_addr == 0x3195DD then
				--return "r2"
			if entry_point_addr == 0xCC4D0 then
				return true
			--elseif entry_point_addr == 0xCBCB0 then
				--return "r4"
			--elseif entry_point_addr == 0xFDB60 then
				--return "dl"
			end
		end
		return false
	end]]--
	
	--if not isSampVerR3() then -- try this logic if facing alignment issues in 0.3.7 R3-1
		interRowDist, textHeight = interRowDist * 3 / 4, textHeight * 3 / 4
	--end
	
	sampRegisterChatCommand("businessinfo", function ()
	if string.find(sampGetCurrentServerName(), "Horizon Roleplay") then
		isInfoRequestedManually = true
		isLastLineAwaited = true
	end
		sampSendChat("/businessinfo")
	end)
	
	-- An extra thread that initiates a 13-second spam cooldown
	lua_thread.create(function()
		while true do
			wait(200)
			if isPlayerMuted then wait(13000) isPlayerMuted = false end
		end
	end)
	
	while true do
		wait(10)
		if isKeyDown(config.General.displayKey) then
			menu.boxWidth = renderGetFontDrawTextLength(font, menu.loadText.str, true) + interColumnDist
			menu.boxHeight = textHeight + interRowDist
			local resX, resY = getScreenResolution()
			menu.posX = (resX / 2) - (menu.boxWidth / 2)
			menu.posY = (resY / 2) - (menu.boxHeight / 2)
			
			menu.failureText.isNeeded = false
			menu.loadText.isNeeded = true
			menu.isNeeded = true
			
			while isLineBlockingNeeded do wait(0) end
			while isLastLineAwaited do wait(0) end
			while isPlayerMuted do wait(0) end
			
			businesses = {}
			isLastLineAwaited = true
			isLineBlockingNeeded = true
			doesPlayerOwnNoBusinesses = false
			sampSendChat("/businessinfo")
			
			for i = 1, 50 do -- ~5 second loop
				if not isLastLineAwaited or doesPlayerOwnNoBusinesses then
					break
				else
					wait(100)
				end
			end
			
			menu.isNeeded = false
			
			lua_thread.create(function()
				wait(1000)
				isLineBlockingNeeded = false
			end)
			
			if not isLastLineAwaited then
				local businessCount = #businesses
				
				if isIndexColumnNeeded then
					columnWidths = {0, 0, 0, 0, 0, 0}
				else
					columnWidths = {0, 0, 0, 0, 0}
				end
				for _, business in pairs(businesses) do
					for columnInd, columnWidth in pairs(columnWidths) do
						local textLen = renderGetFontDrawTextLength(font, business[columnInd], false)
						if textLen > columnWidth then columnWidths[columnInd] = textLen end
					end
				end
				
				menu.tablePageWidth = 0
				for i = 1, #columnWidths do
					menu.tablePageWidth = menu.tablePageWidth + columnWidths[i]
				end
				menu.tablePageWidth = menu.tablePageWidth + (#columnWidths * interColumnDist)
				menu.boxWidth = menu.tablePageWidth + interColumnDist
				
				menu.boxHeight = (textHeight * (businessCount + 1)) + (interRowDist * (businessCount + 2))
				menu.titleBar.barHeight = textHeight + interRowDist
				
				local resX, resY = getScreenResolution()
				local screenAspRatio = resX / resY
				local menuAspRatio = menu.boxWidth / (menu.boxHeight + menu.titleBar.barHeight)
				menu.tablePageCount = 1
				repeat
					menu.tablePageCount = menu.tablePageCount + 1
					local menuWidth_new = ((menu.tablePageWidth + interColumnDist) * menu.tablePageCount) + (interColumnDist * (menu.tablePageCount - 1))
					local perPageBusinessCount_new = math.ceil(businessCount / menu.tablePageCount)
					local menuHeight_new = menu.titleBar.barHeight + (textHeight * (perPageBusinessCount_new + 1)) + (interRowDist * (perPageBusinessCount_new + 2))
					local menuAspRatio_new = menuWidth_new / menuHeight_new
					if math.abs(screenAspRatio - menuAspRatio_new) < math.abs(screenAspRatio - menuAspRatio) then
						menuAspRatio = menuAspRatio_new
						menu.boxWidth = menuWidth_new
						menu.boxHeight = menuHeight_new - menu.titleBar.barHeight
					else
						menu.tablePageCount = menu.tablePageCount - 1
						break
					end
				until false
				menu.perPageBusinessCount = math.ceil(businessCount / menu.tablePageCount)
				menu.boxWidth = menu.boxWidth + 1
				
				menu.titleBar.posX = (resX / 2) - (menu.boxWidth / 2)
				menu.posX = menu.titleBar.posX
				menu.titleBar.posY = (resY / 2) - ((menu.boxHeight + menu.titleBar.barHeight) / 2)
				menu.posY = menu.titleBar.posY + menu.titleBar.barHeight
				menu.titleBar.text.str = menu.titleBar.text.str_prefix .. " (" .. tostring(businessCount) .. ")"
				menu.titleBar.text.posX = menu.titleBar.posX + interColumnDist -- To center: menu.titleBar.posX + ((menu.boxWidth - renderGetFontDrawTextLength(font, menu.titleBar.text.str, false)) / 2)
				menu.titleBar.text.posY = menu.titleBar.posY + ((menu.titleBar.barHeight - textHeight) / 2)
				menu.safeTotal.display_str = menu.safeTotal.str_prefix .. menu.safeTotal.balance_str
				if isTextAllCaps then
					menu.failureText.str, menu.loadText.str, menu.titleBar.text.str, menu.safeTotal.display_str = menu.failureText.str:upper(), menu.loadText.str:upper(), menu.titleBar.text.str:upper(), menu.safeTotal.display_str:upper()
				end
				
				if areTableLinesNeeded then
					drawlines_pos = {}
					for i = 1, menu.tablePageCount do
						local topY = menu.posY + (interRowDist / 2)
						local bottomY = menu.posY + menu.boxHeight - textHeight - (interRowDist * 1.5) - (i == menu.tablePageCount and (((menu.tablePageCount * menu.perPageBusinessCount) - businessCount) * (textHeight + interRowDist)) or 0)
						local leftX = menu.posX + (interColumnDist / 2) + ((i - 1) * (menu.tablePageWidth + (interColumnDist * 2))) + 1
						local rightX = leftX + menu.tablePageWidth + 1
						
						-- Top border
						table.insert(drawlines_pos, {
							leftX,
							topY,
							rightX,
							topY
						})
						-- Bottom border
						table.insert(drawlines_pos, {
							leftX,
							bottomY,
							rightX,
							bottomY
						})
						-- Left border
						table.insert(drawlines_pos, {
							leftX,
							topY,
							leftX,
							bottomY
						})
						-- Right border
						table.insert(drawlines_pos, {
							rightX,
							topY,
							rightX,
							bottomY
						})
						
						-- Inter-column lines
						local line_posX_last = 0
						for columnInd, columnWidth in pairs(columnWidths) do
							if columnInd ~= #columnWidths then
								local line_posX = columnWidths[columnInd] + interColumnDist + (columnInd > 1 and line_posX_last or leftX)
								line_posX_last = line_posX
								table.insert(drawlines_pos, {
									line_posX,
									topY,
									line_posX,
									bottomY
								})
							end
						end
						
						-- Inter-row lines
						local line_posY_last = 0
						for j = 1, menu.perPageBusinessCount - 1 - (i == menu.tablePageCount and ((menu.tablePageCount * menu.perPageBusinessCount) - businessCount) or 0) do
							if i ~= menu.perPageBusinessCount then
								local line_posY = textHeight + interRowDist + (j > 1 and line_posY_last or topY)
								line_posY_last = line_posY
								table.insert(drawlines_pos, {
									leftX,
									line_posY,
									rightX,
									line_posY
								})
							end
						end
					end
				end
				
				menu.loadText.isNeeded = false
				menu.isNeeded = true
				
				while isKeyDown(config.General.displayKey) do wait(0) end
				repeat wait(0) until isKeyDown(config.General.displayKey)
				
				menu.isNeeded = false
			elseif doesPlayerOwnNoBusinesses then
				isLastLineAwaited = false
				isLineBlockingNeeded = false
			else
				menu.boxWidth = renderGetFontDrawTextLength(font, menu.failureText.str, true) + interColumnDist
				menu.boxHeight = textHeight + interRowDist
				local resX, resY = getScreenResolution()
				menu.posX = (resX / 2) - (menu.boxWidth / 2)
				menu.posY = (resY / 2) - (menu.boxHeight / 2)
				
				menu.failureText.isNeeded = true
				menu.isNeeded = true
				
				repeat wait(0) until isKeyDown(config.General.displayKey)
				
				menu.isNeeded = false
			end
			
			while isKeyDown(config.General.displayKey) do wait(0) end
		end
	end	
end