-- TKG

-- Hit L + R to toggle visibility on/off
-- Hit Start to restart tracking

-- Display:
-- 32bit seed (hexadecimal)
-- 15bit output (decimal)
-- Position (up to maxAdvances)
-- Map method offset (position +33)
-- Coolup counter (0-1000)

local addrAT = 0x020EEF30 -- USA/EUR
local addrCoolup = 0x020FDD4C -- USA

local mult = 1103515245
local inc = 12345
local maxAdvances = 999
local mapMethodOffset = 33

local ATable = {}
local ALookup = {}
local inputs = {}

local prevStart = false
local toggleLR = true
local prevLR = false

local grey1 = "#a5a5a5"
local grey2 = "#d6d6d6"
local grey3 = "#848484"
local grey4 = "#424242"

-- Base position (move entire GUI here)
local baseX = 0
local baseY = 0

-- Background draw data (relative coordinates)
local bgElements = {
   {"box", 9,-186,246,-176,"#000000c0","#000000c0"},

   {"line", 10,-189,245,-189,grey1},
   {"pixel", 9,-189,grey3},
   {"pixel", 246,-189,grey3},

   {"line", 9,-188,246,-188,"white"},
   {"pixel", 8,-188,grey2},
   {"pixel", 7,-188,grey3},
   {"pixel", 247,-188,grey2},
   {"pixel", 248,-188,grey3},

   {"line", 11,-187,244,-187,grey4},
   {"pixel", 10,-187,grey3},
   {"pixel", 9,-187,"white"},
   {"pixel", 8,-187,"white"},
   {"pixel", 7,-187,grey2},
   {"pixel", 245,-187,grey3},
   {"pixel", 246,-187,"white"},
   {"pixel", 247,-187,"white"},
   {"pixel", 248,-187,grey2},

   {"pixel", 9,-186,grey4},
   {"pixel", 8,-186,"white"},
   {"pixel", 6,-186,grey3},
   {"pixel", 8,-185,grey3},

   {"pixel", 246,-186,grey4},
   {"pixel", 247,-186,"white"},

   {"line", 6,-185,6,-177,grey1},
   {"line", 7,-186,7,-176,"white"},
   {"line", 8,-184,8,-177,grey4},
   {"line", 247,-185,247,-177,grey1},
   {"line", 248,-186,248,-176,"white"},
   {"line", 249,-186,249,-176,grey4},

   {"pixel", 6,-176,grey3},
   {"pixel", 8,-176,"white"},
   {"pixel", 9,-176,grey4},

   {"pixel", 246,-176,grey3},
   {"pixel", 247,-176,"white"},
   {"pixel", 249,-176,grey4},

   {"line", 10,-175,245,-175,grey1},
   {"pixel", 9,-175,"white"},
   {"pixel", 8,-175,"white"},
   {"pixel", 7,-175,grey2},
   {"pixel", 246,-175,"white"},
   {"pixel", 247,-175,"white"},
   {"pixel", 248,-175,grey3},

   {"line", 9,-174,246,-174,"white"},
   {"pixel", 8,-174,grey2},
   {"pixel", 7,-174,grey3},
   {"pixel", 247,-174,grey3},
   {"pixel", 248,-174,grey4},

   {"line", 9,-173,246,-173,grey4},
}

-- Utility functions
local function toUint32(x)
   return bit.band(x, 0xFFFFFFFF)
end

local function getHex(decimal, digits)
   return string.format("%0"..digits.."X", decimal)
end

local function getOutputColors(output)
   if output <= 128 then
      return "black", "white"
   elseif output <= 256 then
      return "red", "clear"
   elseif output <= 512 then
      return "magenta", "clear"
   elseif output <= 1024 then
      return "green", "clear"
   elseif output <= 2048 then
      return "cyan", "clear"
   elseif output <= 4096 then
      return "yellow", "clear"
   else
      return "white", "clear"
   end
end

local function getATSeed(currentSeed)
   local hi = bit.rshift(currentSeed, 16)
   local lo = (bit.band(currentSeed, 65535)) * mult + inc
   local cr = bit.rshift(lo, 16)
   lo = bit.band(lo, 65535)
   hi = bit.band(hi * mult + cr, 65535)
   return toUint32(bit.bor(bit.lshift(hi, 16), lo))
end

local function getATOutput(currentSeed)
   return bit.band(bit.rshift(currentSeed, 16), 32767)
end

-- Draw background from table
local function drawBackground(baseX, baseY)
   for _, e in ipairs(bgElements) do
      local t = e[1]

      if t == "pixel" then
         gui.pixel(baseX + e[2], baseY + e[3], e[4])

      elseif t == "line" then
         gui.line(
            baseX + e[2], baseY + e[3],
            baseX + e[4], baseY + e[5],
            e[6]
         )

      elseif t == "box" then
         gui.box(
            baseX + e[2], baseY + e[3],
            baseX + e[4], baseY + e[5],
            e[6], e[7]
         )
      end
   end
end

-- L+R toggle handler
local function handletoggleLR(inputs)
   local pressed = inputs.L and inputs.R
   if pressed and not prevLR then
      toggleLR = not toggleLR
   end
   prevLR = pressed
end

-- Text helpers
local function rightAlignText(xRight, y, text, color, bg)
   local str = tostring(text)
   local charWidth = 6
   local width = string.len(str) * charWidth
   gui.text(xRight - width, y, str, color, bg)
end

-- GUI renderer
local function renderGUI(seed_hex, output, position, mapmethod)
   local baseX = baseX
   local baseY = baseY

   drawBackground(baseX, baseY)

   local guiElements = {
      {15, -184, "0x"..seed_hex..":"},
      {123, -184, "("..position.."/"..mapmethod..")"}
   }

   for _, element in ipairs(guiElements) do
      gui.text(
         baseX + element[1],
         baseY + element[2],
         element[3],
         "white",
         "clear"
      )
   end
end

-- Main loop
local function main()
--memory.writedword(0x020EEF30, 0xf76549a9) -- AT
--memory.writedword(0x020FDD4C, 0x0000FFFF) -- coolup
--memory.writedword(0x027E38B0, 0x000216CF) -- field camera tilt
--memory.writedword(0x027E38B4, 0x00031192) -- field camera zoom

   local seed = toUint32(memory.readdword(addrAT))
   local seed_hex = getHex(seed, 8)
   local output = getATOutput(seed)

   local inputs = joypad.get(1)

   local startPressed = inputs.start and not prevStart
   prevStart = inputs.start

   handletoggleLR(inputs)

   if startPressed then
      ATable = {}
      ALookup = {}

      ATable[0] = seed
      ALookup[seed] = 0

      for i = 1, maxAdvances do
         local nextSeed = getATSeed(ATable[i-1])
         nextSeed = toUint32(nextSeed)

         ATable[i] = nextSeed
         ALookup[nextSeed] = i
      end
   end

   local position = ALookup[seed]
   local mapmethod = position and (position + mapMethodOffset) or nil

   if not position then
      position = "-"
      mapmethod = "-"
   end

   if toggleLR then
      renderGUI(seed_hex, output, position, mapmethod)

      local coolup = memory.readdword(addrCoolup)
      if coolup >= 1000 then
         coolup = "1000+"
      end
      local coolupColour = (coolup == "1000+") and "green" or "white"

      rightAlignText(baseX + 241, baseY - 184, coolup, coolupColour, "clear")
      local textColor, bgColor = getOutputColors(output)
      rightAlignText(baseX + 117, baseY - 184, output, textColor, bgColor)
   end
end

gui.register(main)
