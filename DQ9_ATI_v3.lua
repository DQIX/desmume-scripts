-- Written by TKG

-- How to Use:
-- Hit L + R to toggle the view on/off
-- Hit Start to restart tracking

-- Display:
-- 32-BIT: current 32-bit AT seed (hexadecimal)
-- 15-BIT: current 15-bit AT output (decimal)
-- POSITION: current position (up to 999)
-- MAP METHOD: current position offset by 33 for map methods (up to 1032)

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
   local guiElements = {
      {10, -188, "32-BIT  0x"..seed, "white", "clear"},
      {10, -178, "15-BIT  "..output, "white", "clear"},
      {140, -188, "  P0SITI0N  "..position, "white", "clear"},
      {140, -178, "MAP METH0D  "..mapmethod, "white", "clear"},
   }

   gui.box(0, -192, 256, -168, "#000000D0", "#000000D0")
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

   local position = "-"
   local mapmethod = "-"
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