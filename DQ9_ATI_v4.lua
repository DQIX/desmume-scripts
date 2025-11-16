-- Written by TKG

-- How to Use:
-- Hit L + R to toggle the view on/off
-- Hit Start to restart tracking

-- Display:
-- Seed (hexadecimal), output (decimal), position (up to 999), map method offset (up to 1032)

-- Game Versions:
-- YDQ(J) = JPN (0x4A)
-- YDQ(E) = USA (0x45)
-- YDQ(P) = EUR (0x50)

local tbl_addr = {
   game_ver = 0x023FFE0F, -- Ascii
   at_jp = 0x020EEE90,    -- JPN AT address
   at_en = 0x020EEF30     -- USA/EUR AT address
}

local startCount = 0
local triggerCount = 0
local LRToggle = true
local ATable = {}
local inputs = {}

local grey1 = "#a5a5a5"
local grey2 = "#d6d6d6"
local grey3 = "#848484"
local grey4 = "#424242"

local function getHex(decimal, digits)
   if digits == 4 then return string.format("%04X", decimal)
   elseif digits == 8 then return string.format("%08X", decimal)
   end
end

local function getGameVer(ydqx)
   local version = memory.readbyte(ydqx)
   if version == 0x4A then return tbl_addr.at_jp end
   return tbl_addr.at_en
end

local function getATSeed(currentSeed)
   local hi = bit.rshift(currentSeed, 16)
   local lo = (bit.band(currentSeed, 65535)) * 1103515245 + 12345
   local cr = bit.rshift(lo, 16)
   lo = bit.band(lo, 65535)
   hi = bit.band(hi * 1103515245 + cr, 65535)
   local nextSeed = bit.bor(bit.lshift(hi, 16), lo)
   return nextSeed
end

local function getATOutput(currentSeed)
   return bit.band(bit.rshift(currentSeed, 16), 32767)
end

local function renderGUI(seed, output, position, mapmethod)
   gui.box(9,-186,246,-176,"#000000c0","#000000c0")

   gui.line(10,-189,245,-189,grey1)
   gui.pixel(9,-189,grey3)
   gui.pixel(246,-189,grey3)
   
   gui.line(9,-188,246,-188,"white")
   gui.pixel(8,-188,grey2)
   gui.pixel(7,-188,grey3)
   gui.pixel(247,-188,grey2)
   gui.pixel(248,-188,grey3)

   gui.line(11,-187,244,-187,grey4)
   gui.pixel(10,-187,grey3)
   gui.pixel(9,-187,"white")
   gui.pixel(8,-187,"white")
   gui.pixel(7,-187,grey2)
   gui.pixel(245,-187,grey3)
   gui.pixel(246,-187,"white")
   gui.pixel(247,-187,"white")
   gui.pixel(248,-187,grey2)

   gui.pixel(9,-186,grey4)
   gui.pixel(8,-186,"white")
   gui.pixel(6,-186,grey3)
   gui.pixel(8,-185,grey3)

   gui.pixel(246,-186,grey4)
   gui.pixel(247,-186,"white")

   gui.line(6,-185,6,-177,grey1)
   gui.line(7,-186,7,-176,"white")
   gui.line(8,-184,8,-177,grey4)
   gui.line(247,-185,247,-177,grey1)
   gui.line(248,-186,248,-176,"white")
   gui.line(249,-186,249,-176,grey4)

   gui.pixel(6,-176,grey3)
   gui.pixel(8,-176,"white")
   gui.pixel(9,-176,grey4)

   gui.pixel(246,-176,grey3)
   gui.pixel(247,-176,"white")
   gui.pixel(249,-176,grey4)

   gui.line(10,-175,245,-175,grey1)
   gui.pixel(9,-175,"white")
   gui.pixel(8,-175,"white")
   gui.pixel(7,-175,grey2)
   gui.pixel(246,-175,"white")
   gui.pixel(247,-175,"white")
   gui.pixel(248,-175,grey3)

   gui.line(9,-174,246,-174,"white")
   gui.pixel(8,-174,grey2)
   gui.pixel(7,-174,grey3)
   gui.pixel(247,-174,grey3)
   gui.pixel(248,-174,grey4)

   gui.line(9,-173,246,-173,grey4)

   local guiElements = {
      {18, -184, "AT: 0x"..seed.." ("..output..")", "white", "clear"},
      {160, -184, "P: "..position.." ("..mapmethod..")", "white", "clear"}
   }

   for k, element in ipairs(guiElements) do
      gui.text(element[1], element[2], element[3], element[4], element[5])
   end
end

local function main()

--memory.writedword(0x020EEF30, 0x00000000) -- poke EN address
--memory.writedword(0x020EEE90, 0x00000000) -- poke JP address
--memory.writedword(0x027E38B0, 0x000216CF) -- field camera tilt (USA)
--memory.writedword(0x027E38B4, 0x00031192) -- field camera zoom (USA)

   local at_addr = getGameVer(tbl_addr.game_ver)
   local seed = memory.readdword(at_addr)
   local seed_hex = getHex(seed, 8)
   local output = getATOutput(seed)

   inputs = joypad.get(1)
   startCount = inputs.start and startCount + 1 or 0

   if startCount == 1 then
      ATable[0] = seed
      for i = 1, 999 do
         ATable[i] = getATSeed(ATable[i-1])
      end
   end

   local position = "?"
   local mapmethod = "?"
   for p, v in pairs(ATable) do
      if getHex(v, 8) == seed_hex then
         position = p
         mapmethod = p + 33
         break
      end
   end

   --visibility toggle
   if inputs.L and inputs.R then
      triggerCount = triggerCount + 1
      if triggerCount == 1 then
         LRToggle = not LRToggle
      end
   else
      triggerCount = 0
   end

   if LRToggle then
      renderGUI(seed_hex, output, position, mapmethod)
   end

end

gui.register(main)
