-- TKG

-- How to use:
-- Press Start to toggle the visibility on/off

local tbl_addr = {
   facebuttons = 0x04000130, -- face button inputs (all versions)
   en_hi = 0x02108DE0,       -- BT highbyte (USA/EUR)
   en_lo = 0x02108DDC,       -- BT lowbyte (USA/EUR)
   jp_hi = 0x02108D24,       -- BT highbyte (JPN)
   jp_lo = 0x02108D20        -- BT lowbyte (JP)
}

-- Colours based on Yab's hoimi table (in dark mode):
local tbl_colour = {
   clear = "clear",
   black = "black",
   white = "white",
   whiteStroke = "#CCCCCC",
   greyStroke = "#444444",
   indigoFill = "#000044",
   redStroke = "#DD66CC",
   redFill = "#880000",
   redText = "#FFBBDD",
   blueStroke = "#0088FF",
   blueFill = "#000088",
   blueText = "#88CCFF"
}

local frameCount = 0 -- frame counter for the toggle button
local highbyte
local lowbyte
local toggle = true
local BTable = {}   -- table for BT positions

-- Original BT code:
-- rand_seed = rand_seed * 0x5d588b656c078965 + 0x269ec3
-- return (rand_seed >> 32) & 0xffffffff
-- My attempt at 64 bit multiplication with 16 bit math:
function bt_rand()

   -- BTlowHi_aLo = higher 16 bits of BT's lowbyte * lowbyte of multiplier "a"
   -- BTlowLo_aLo = lower 16 bits of BT's lowbyte * lowbyte of multiplier "a"
   local BTlowHi_aLo = bit.rshift(lowbyte, 16) * 0x6C078965
   local BTlowLo_aLo = bit.band(lowbyte, 0xFFFF) * 0x6C078965

   -- total_1 = lowest 16 bits of BTlowLo_aLo + lower 16 bits of increment "c"
   -- total_2 = carry from total_1 + lower 16 bits of BTlowHi_aLo + middle 16 bits of BTlowLo_aLo + higher 16 bits of increment "c"
   -- total_3 = carry from total_2 + middle 16 bits of BTlowHi_aLo + highest 16 bits of BTlowLo_aLo
   -- total_4 = carry from total_3 + highest 16 bits of BTlowHi_aLo
   local total_1 = bit.band(BTlowLo_aLo, 0xFFFF) + 0x9EC3
   local total_2 = bit.rshift(total_1, 16) + bit.band(BTlowHi_aLo, 0xFFFF) + bit.rshift(BTlowLo_aLo, 16) + 0x0026
   local total_3 = bit.rshift(total_2, 16) + bit.rshift(BTlowHi_aLo, 16) + math.floor(BTlowLo_aLo / 0xFFFFFFFF)
   local total_4 = bit.rshift(total_3, 16) + math.floor(BTlowHi_aLo / 0xFFFFFFFF)

   -- BTlowHi_aHi = higher 16 bits of BT's lowbyte * highbyte of multiplier "a"
   -- BTlowLo_aHi = lower 16 bits of BT's lowbyte * highbyte of multiplier "a"
   -- BTlow_aHi = combine higher and lower results
   local BTlowHi_aHi = bit.rshift(lowbyte, 16) * 0x5D588B65
   local BTlowLo_aHi = bit.band(lowbyte, 0xFFFF) * 0x5D588B65
   local BTlow_aHi = bit.lshift(BTlowHi_aHi, 16) + BTlowLo_aHi

   -- BThighHi_aLo = higher 16 bits of BT's highbyte * lowbyte of multiplier "a"
   -- BThighLo_aLo = lower 16 bits of BT's highbyte * lowbyte of multiplier "a"
   -- BThigh_aLo = combine higher and lower results
   local BThighHi_aLo = bit.rshift(highbyte, 16) * 0x6C078965
   local BThighLo_aLo = bit.band(highbyte, 0xFFFF) * 0x6C078965
   local BThigh_aLo = bit.lshift(BThighHi_aLo, 16) + BThighLo_aLo

   -- total_5 = lower 16 bits of BThigh_aLo + lower 16 bits of BTlow_aHi + lower 16 bits of total_3
   -- total_6 = carry from total_5 + higher 16 bits of BThigh_aLo + higher 16 bits of BTlow_aHi + total_4
   local total_5 = bit.band(BThigh_aLo, 0xFFFF) + bit.band(BTlow_aHi, 0xFFFF) + bit.band(total_3, 0xFFFF)
   local total_6 = bit.rshift(total_5, 16) + bit.rshift(BThigh_aLo, 16) + bit.rshift(BTlow_aHi, 16) + total_4

   -- combine higher and lower 16 bits to complete the next highbyte/lowbyte
   lowbyte = bit.bor(bit.lshift(bit.band(total_2, 0xFFFF), 16), bit.band(total_1, 0xFFFF))
   highbyte = bit.bor(bit.lshift(total_6, 16), bit.band(total_5, 0xFFFF))

   return highbyte

end

-- getResult: calculate the percentage/healing value from the output
-- rand = BT output
-- ratio = 100 for percentage or 10 for heal/hoimi spell
local uint32_max = 2 ^ 32

function getResult(rand, ratio)

   local result = rand / (uint32_max / ratio)

   if result < 0 then result = result + ratio end -- signed to unsigned

   if ratio == 100 then
      return result
   elseif ratio == 10 then
      return math.floor(result + 0.5) + 30 -- base hoimi = 30 (rounded to nearest whole number)
   end

end


-- getColour: set text and fill colours for each square on the table
function getColour(percentage, attribute)

   local colour

   if attribute == "fill" then
      if percentage < 2 then colour = tbl_colour.redFill
      elseif percentage < 10 then colour = tbl_colour.blueFill
      else colour = tbl_colour.black
      end

   elseif attribute == "text" then
      if percentage < 2 then colour = tbl_colour.redText
      elseif percentage < 10 then colour = tbl_colour.blueText
      else colour = tbl_colour.white
      end

   end

   return colour

end


function main()

   -- Read face button input (low nibble)
   -- 7 = start button
   local buttonInput = bit.band(memory.readbyte(tbl_addr.facebuttons), 0xF)

   -- If start is pressed, the frame counter starts
   -- The toggle gets triggered when the counter hits 1
   if buttonInput == 7 then
      frameCount = frameCount + 1
      if frameCount == 1 then toggle = not toggle end
   else
      frameCount = 0
   end

   if toggle then

      -- ones = numbers on the top row
      -- tens = numbers on the leftmost column
      -- position = BT position 0-89
      local ones, tens, position = -1, -10, 0

      -- Create squares/labels for the top row
      for x = 15, 231, 24 do
         ones = ones + 1
         gui.box(x, -192, x + 24, -181, tbl_colour.indigoFill, tbl_colour.greyStroke)
         gui.text(x+9, -189, ones, tbl_colour.white, tbl_colour.clear)
      end

      -- Create squares/labels for the leftmost column
      for y = -181, -21, 20 do
         tens = tens + 10
         if tens == 0 then tens = " " .. tens end
         gui.box(0, y, 15, y + 20, tbl_colour.indigoFill, tbl_colour.greyStroke)
         gui.text(2, y+7, tens, tbl_colour.white, tbl_colour.clear)
      end

      -- Create square for the top left corner
      gui.box(0, -192, 15, -181, tbl_colour.indigoFill, tbl_colour.greyStroke)


      highbyte = memory.readdword(tbl_addr.en_hi)
      lowbyte = memory.readdword(tbl_addr.en_lo)
      BTable[1] = highbyte                        -- add the current highbyte value to the table as position 0
      BTable[2] = bt_rand(highbyte, lowbyte)      -- calculate and add position 1 to the table

      for i = 3, 90 do BTable[i] = bt_rand() end -- calculate and add positions 2-89 to the table

      -- Create the main table
      for y = -181, -21, 20 do  -- 9 rows

         for x = 15, 231, 24 do -- 10 columns

            position = position + 1

            local percent = getResult(BTable[position], 100)
            local hoimi = getResult(BTable[position], 10)

            local int = string.format("%02d", percent) -- split up integer/decimals so they can fit in each box
            local dec = string.format("%.2f", percent)
            local text = getColour(percent, "text")

            gui.box(x, y, x+24, y+20, getColour(percent, "fill"), tbl_colour.greyStroke)
            gui.text(x+3, y+3, int, text, tbl_colour.clear)
            gui.text(x+16, y+3, string.sub(dec, -2, -2), text, tbl_colour.clear)
            gui.pixel(x+15, y+9, text, tbl_colour.clear) -- the decimal point
            gui.text(x+3, y+11, hoimi, text, tbl_colour.clear)

         end

      end

      gui.box(16, -180, 38, -162, tbl_colour.clear, tbl_colour.whiteStroke) -- position 0 outline
      gui.box(40, -180, 62, -162, tbl_colour.clear, tbl_colour.redStroke)   -- position 1 outline
      gui.box(64, -180, 86, -162, tbl_colour.clear, tbl_colour.blueStroke)  -- position 2 outline

   end

end

gui.register(main)
