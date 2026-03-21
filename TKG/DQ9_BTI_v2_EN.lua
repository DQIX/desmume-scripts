-- TKG

-- Hit Start to toggle visibility on/off

local addr = {
   en_hi = 0x02108DE0, -- BT highbyte (USA/EUR)
   en_lo = 0x02108DDC, -- BT lowbyte (USA/EUR)
   jp_hi = 0x02108D24, -- BT highbyte (JPN)
   jp_lo = 0x02108D20  -- BT lowbyte (JPN)
}

-- Colours based on yab's hoimi table (in dark mode)
-- https://www.yabd.org/apps/dq9/hoimi.php
local colours = {
   clear       = "clear",
   black       = "#000000D0",
   white       = "white",
   whiteStroke = "#CCCCCC",
   greyStroke  = "#444444",
   indigoFill  = "#000044D0",
   redStroke   = "#DD66CC",
   redFill     = "#880000D0",
   redText     = "#FFBBDD",
   blueStroke  = "#0088FF",
   blueFill    = "#000088D0",
   blueText    = "#88CCFF"
}

local BTable = {}

local band = bit.band
local bor = bit.bor
local rshift = bit.rshift
local lshift = bit.lshift

local offsetX = 0
local offsetY = 0 -- bottom screen = 192

local toggle = true
local prevStart = false

local uint32_max = 2^32

local highbyte
local lowbyte

local A_hi = 0x5D588B65
local A_lo = 0x6C078965
local C_hi = 0x0026
local C_lo = 0x9EC3

local redPercent = 2
local bluePercent = 10

local function getHex(decimal, digits)
   return string.format("%0"..digits.."X", decimal)
end

local function mul_split(x, a)
    local x_hi = rshift(x, 16)
    local x_lo = band(x, 0xFFFF)
    return x_hi * a, x_lo * a
end

function bt_rand()
   local low_hi = rshift(lowbyte, 16)
   local low_lo = band(lowbyte, 0xFFFF)
   local high_hi = rshift(highbyte, 16)
   local high_lo = band(highbyte, 0xFFFF)

   local BTlowHi_aLo = low_hi * A_lo
   local BTlowLo_aLo = low_lo * A_lo

   local total_1 = band(BTlowLo_aLo, 0xFFFF) + C_lo
   local total_2 = rshift(total_1, 16)
                 + band(BTlowHi_aLo, 0xFFFF)
                 + rshift(BTlowLo_aLo, 16)
                 + C_hi

   local total_3 = rshift(total_2, 16)
                 + rshift(BTlowHi_aLo, 16)
                 + math.floor(BTlowLo_aLo / 0xFFFFFFFF)

   local total_4 = rshift(total_3, 16)
                 + math.floor(BTlowHi_aLo / 0xFFFFFFFF)

   local BTlowHi_aHi, BTlowLo_aHi = mul_split(lowbyte, A_hi)
   local BTlow_aHi = lshift(BTlowHi_aHi, 16) + BTlowLo_aHi

   local BThighHi_aLo, BThighLo_aLo = mul_split(highbyte, A_lo)
   local BThigh_aLo = lshift(BThighHi_aLo, 16) + BThighLo_aLo

   local total_5 = band(BThigh_aLo, 0xFFFF)
                 + band(BTlow_aHi, 0xFFFF)
                 + band(total_3, 0xFFFF)

   local total_6 = rshift(total_5, 16)
                 + rshift(BThigh_aLo, 16)
                 + rshift(BTlow_aHi, 16)
                 + total_4

   lowbyte = bor(
       lshift(band(total_2, 0xFFFF), 16),
       band(total_1, 0xFFFF)
   )

   highbyte = bor(
       lshift(total_6, 16),
       band(total_5, 0xFFFF)
   )

   return highbyte
end

function getResult(rand, ratio)
   local result = rand / (uint32_max / ratio)

   -- signed to unsigned
   if result < 0 then
      result = result + ratio
   end

   return result
end

function getColour(percentage, attribute)
   local colour

   if attribute == "fill" then
      if percentage < redPercent then colour = colours.redFill
      elseif percentage < bluePercent then colour = colours.blueFill
      else colour = colours.black
      end
   elseif attribute == "text" then
      if percentage < redPercent then colour = colours.redText
      elseif percentage < bluePercent then colour = colours.blueText
      else colour = colours.white
      end
   end

   return colour
end

local function handleToggleStart(inputs)
   local pressed = inputs.start
   if pressed and not prevStart then
      toggle = not toggle
   end
   prevStart = pressed
end

local function box(x1, y1, x2, y2, fill, stroke)
   gui.box(x1 + offsetX, y1 + offsetY, x2 + offsetX, y2 + offsetY, fill, stroke)
end

local function text(x, y, str, colour, bg)
   gui.text(x + offsetX, y + offsetY, str, colour, bg)
end

local function pixel(x, y, colour)
   gui.pixel(x + offsetX, y + offsetY, colour)
end

local function rightAlignText(xRight, y, text, color, bg)
   local str = tostring(text)
   local charWidth = 6
   local width = string.len(str) * charWidth
   gui.text(xRight - width, y, str, color, bg)
end

function main()
-- Poke addresses
--memory.writedword(addr.en_hi, 0x0)
--memory.writedword(addr.en_lo, 0x31600)
--memory.writedword(0x02399190, 0x01010100) -- offsets for the opening party animation

   local inputs = joypad.get(1)
   handleToggleStart(inputs)

   if toggle then

      -- ones = numbers on the top row
      -- tens = numbers on the leftmost column
      -- position = BT position 0-99
      local ones, tens, position = -1, -10, 0

      -- Top row
      for x = 15, 231, 24 do
         ones = ones + 1
         box(x, -142, x + 24, -131, colours.indigoFill, colours.greyStroke)
         text(x + 9, -140, ones, colours.white, colours.clear)
      end

      -- Leftmost column
      for y = -131, -14, 13 do
         tens = tens + 10
         if tens == 0 then tens = " " .. tens end
         box(0, y, 15, y + 13, colours.indigoFill, colours.greyStroke)
         text(2, y + 3, tens, colours.white, colours.clear)
      end

      box(0, -142, 15, -131, colours.indigoFill, colours.greyStroke) -- Top left corner

      highbyte = memory.readdword(addr.en_hi)
      lowbyte = memory.readdword(addr.en_lo)

      box(0, -168, 255, -142, colours.black, colours.greyStroke)
      text(3, -164, "HI: 0x" .. getHex(highbyte, 8), colours.white, colours.clear)
      text(3, -152, "L0: 0x" .. getHex(lowbyte, 8), colours.white, colours.clear)
      rightAlignText(250, -164, " RED: " .. string.format("%4.1f", redPercent) .. "%", colours.redText, colours.clear)
      rightAlignText(250, -152, "BLUE: " .. string.format("%4.1f", bluePercent) .. "%", colours.blueText, colours.clear)

      BTable[1] = highbyte -- add the current highbyte value to the table as position 0
      for i = 2, 100 do
         BTable[i] = bt_rand()
      end

      -- Main table
      for y = -131, -14, 13 do  -- 10 rows
         for x = 15, 231, 24 do -- 10 columns
            position = position + 1

            local percent = getResult(BTable[position], 100)
            local int = string.format("%2d", percent) -- split up integer/decimals so they can fit in each box
            local dec = string.format("%.2f", percent)
            local fillColour = getColour(percent, "fill")
            local textColour = getColour(percent, "text")

            box(x, y, x + 24, y + 13, fillColour, colours.greyStroke)

            local dx = x
            if percent < 10 then
               dx = dx - 3
            end

            text(dx + 3, y + 3, int, textColour, colours.clear)
            pixel(dx + 15, y + 9, textColour, colours.clear) -- decimal point
            text(dx + 16, y + 3, string.sub(dec, -2, -2), textColour, colours.clear)

         end
      end

      box(16, -130, 38, -119, colours.clear, colours.whiteStroke)  -- position 0 outline
      box(40, -130, 62, -119, colours.clear, colours.redStroke)    -- position 1 outline
      box(64, -130, 86, -119, colours.clear, colours.blueStroke)   -- position 2 outline
      box(112, -130, 134, -119, colours.clear, colours.redStroke)  -- position 4 outline
      box(136, -130, 158, -119, colours.clear, colours.blueStroke) -- position 5 outline

   end

end

gui.register(main)
