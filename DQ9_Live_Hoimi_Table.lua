-- Live Hoimi Table by TKG


-- How to use:
-- Run the script in DeSmuME (tools > lua scripting > new lua script window)
-- Press Start to toggle the visibility on/off


-- Addresses:
-- 0x04000130 = face button inputs (US and JP)
-- 0x02108DE0 = BT highbyte (US)
-- 0x02108DDC = BT lowbyte (US)
-- 0x02108D24 = BT highbyte (JP)
-- 0x02108D20 = BT lowbyte (JP)


-- Original BT code:
-- rand()
-- {
--    rand_seed = rand_seed * 0x5d588b656c078965 + 0x269ec3
--    return (rand_seed >> 32) & 0xffffffff
-- }


-- Colours based on Yab's hoimi table (in dark mode):
whiteStroke = "#CCCCCC"
greyStroke = "#444444"
indigoFill = "#000044"
redStroke = "#DD66CC"
redFill = "#880000"
redText = "#FFBBDD"
blueStroke = "#0088FF"
blueFill = "#000088"
blueText = "#88CCFF"


-- Other stuff:
count = 0 -- frame counter for the toggle button
BT = {}   -- table for BT positions


-- My attempt at 64 bit multiplication with 16 bit math
function bt_rand()

   -- BTlowHi_aLo = higher 16 bits of BT's lowbyte * lowbyte of multiplier "a"
   -- BTlowLo_aLo = lower 16 bits of BT's lowbyte * lowbyte of multiplier "a"
   BTlowHi_aLo = bit.rshift(lowbyte, 16) * 0x6C078965
   BTlowLo_aLo = bit.band(lowbyte, 0xFFFF) * 0x6C078965

   -- total_1 = lowest 16 bits of BTlowLo_aLo + lower 16 bits of increment "c"
   -- total_2 = carry from total_1 + lower 16 bits of BTlowHi_aLo + middle 16 bits of BTlowLo_aLo + higher 16 bits of increment "c"
   -- total_3 = carry from total_2 + middle 16 bits of BTlowHi_aLo + highest 16 bits of BTlowLo_aLo
   -- total_4 = carry from total_3 + highest 16 bits of BTlowHi_aLo
   total_1 = bit.band(BTlowLo_aLo, 0xFFFF) + 0x9EC3
   total_2 = bit.rshift(total_1, 16) + bit.band(BTlowHi_aLo, 0xFFFF) + bit.rshift(BTlowLo_aLo, 16) + 0x0026
   total_3 = bit.rshift(total_2, 16) + bit.rshift(BTlowHi_aLo, 16) + math.floor(BTlowLo_aLo / 0xFFFFFFFF)
   total_4 = bit.rshift(total_3, 16) + math.floor(BTlowHi_aLo / 0xFFFFFFFF)

   -- BTlowHi_aHi = higher 16 bits of BT's lowbyte * highbyte of multiplier "a"
   -- BTlowLo_aHi = lower 16 bits of BT's lowbyte * highbyte of multiplier "a"
   -- BTlow_aHi = combine higher and lower results
   BTlowHi_aHi = bit.rshift(lowbyte, 16) * 0x5D588B65
   BTlowLo_aHi = bit.band(lowbyte, 0xFFFF) * 0x5D588B65
   BTlow_aHi = bit.lshift(BTlowHi_aHi, 16) + BTlowLo_aHi

   -- BThighHi_aLo = higher 16 bits of BT's highbyte * lowbyte of multiplier "a"
   -- BThighLo_aLo = lower 16 bits of BT's highbyte * lowbyte of multiplier "a"
   -- BThigh_aLo = combine higher and lower results
   BThighHi_aLo = bit.rshift(highbyte, 16) * 0x6C078965
   BThighLo_aLo = bit.band(highbyte, 0xFFFF) * 0x6C078965
   BThigh_aLo = bit.lshift(BThighHi_aLo, 16) + BThighLo_aLo

   -- total_5 = lower 16 bits of BThigh_aLo + lower 16 bits of BTlow_aHi + lower 16 bits of total_3
   -- total_6 = carry from total_5 + higher 16 bits of BThigh_aLo + higher 16 bits of BTlow_aHi + total_4
   total_5 = bit.band(BThigh_aLo, 0xFFFF) + bit.band(BTlow_aHi, 0xFFFF) + bit.band(total_3, 0xFFFF)
   total_6 = bit.rshift(total_5, 16) + bit.rshift(BThigh_aLo, 16) + bit.rshift(BTlow_aHi, 16) + total_4

   -- combine higher and lower 16 bits to complete the next highbyte/lowbyte
   lowbyte = bit.bor(bit.lshift(bit.band(total_2, 0xFFFF), 16), bit.band(total_1, 0xFFFF))
   highbyte = bit.bor(bit.lshift(total_6, 16), bit.band(total_5, 0xFFFF))

   return highbyte

end


-- getResult: calculate the percentage/healing value from the output
-- rand = BT output
-- ratio = 100 for percentage or 10 for heal/hoimi spell
function getResult(rand, ratio)

   result = rand / ((2 ^ 32) / ratio)

   if result < 0 then result = result + ratio end -- signed to unsigned

   if ratio == 100 then
      return result
   elseif ratio == 10 then
      return math.floor(result + 0.5) + 30 -- base hoimi = 30 (rounded to nearest whole number)
   end

end


-- getColour: set text and fill colours for each square on the table
function getColour(percentage, attribute)

   if attribute == "fill" then
      if percentage < 2 then colour = redFill
      elseif percentage < 10 then colour = blueFill
      else colour = "black"
      end

   elseif attribute == "text" then
      if percentage < 2 then colour = redText
      elseif percentage < 10 then colour = blueText
      else colour = "white"
      end

   end

   return colour

end


function main()

   -- Poke addresses
   --memory.writedword(0x020EEF30, 0xBE21F58F) -- AT
   --memory.writedword(0x02108DE0, 0x3C80D943) -- BT Highbyte
   --memory.writedword(0x02108DDC, 0x598FD5A5) -- BT Lowbyte

   -- Display for AT output
   ATseed = memory.readdword(0x020EEF30)
   ATout = bit.band(bit.rshift(ATseed, 16), 0x7FFF)
   gui.text(5, 10, "AT 0UT : " .. ATout, redStroke)

   -- Display for BT addresses
   gui.text(5, 20, "BT HI  : " .. string.format("%08X", memory.readdword(0x02108DE0)), blueStroke) -- Highbyte
   gui.text(5, 30, "BT L0  : " .. string.format("%08X", memory.readdword(0x02108DDC)), blueStroke) -- Lowbyte

   -- Read face button input (low nibble)
   -- 7 = start button
   buttonInput = bit.band(memory.readbyte(0x04000130), 0xF)

   -- If start is pressed, the frame counter starts
   -- The input would have to be frame perfect otherwise(?)
   -- The toggle gets triggered when the counter hits 1
   if buttonInput == 7 then
      count = count + 1
      if count == 1 then toggle = not toggle end
   else
      count = 0
   end

   if toggle then

      -- ones = numbers on the top row
      -- tens = numbers on the leftmost column
      -- position = BT position 0-89
      ones, tens, position = -1, -10, 0

      -- Create squares/labels for the top row
      for x = 15, 231, 24 do
         ones = ones + 1
         gui.box(x, -192, x + 24, -181, indigoFill, greyStroke)
         gui.text(x+9, -189, ones, "white", "clear")
      end

      -- Create squares/labels for the leftmost column
      for y = -181, -21, 20 do
         tens = tens + 10
         if tens == 0 then tens = " " .. tens end
         gui.box(0, y, 15, y + 20, indigoFill, greyStroke)
         gui.text(2, y+7, tens, "white", "clear")
      end

      -- Create square for the top left corner
      gui.box(0, -192, 15, -181, indigoFill, greyStroke)


      highbyte = memory.readdword(0x02108DE0) -- read the address for BT's highbyte (32 bits)
      lowbyte = memory.readdword(0x02108DDC)  -- read the address for BT's lowbyte (32 bits)
      BT[1] = highbyte                        -- add the current highbyte value to the table as position 0
      BT[2] = bt_rand(highbyte, lowbyte)      -- calculate and add position 1 to the table

      for i = 3, 90 do BT[i] = bt_rand() end -- calculate and add positions 2-89 to the table

      -- Create the main table
      for y = -181, -21, 20 do  -- 9 rows

         for x = 15, 231, 24 do -- 10 columns

            position = position + 1

            percent = getResult(BT[position], 100)
            hoimi = getResult(BT[position], 10)

            int = string.format("%02d", percent) -- split up integer/decimals so they can fit in each box
            dec = string.format("%.2f", percent)
            text = getColour(percent, "text")

            gui.box(x, y, x+24, y+20, getColour(percent, "fill"), greyStroke)
            gui.text(x+3, y+3, int, text, "clear")
            gui.text(x+16, y+3, string.sub(dec, -2, -2), text, "clear")
            gui.pixel(x+15, y+9, text, "clear") -- the decimal point
            gui.text(x+3, y+11, hoimi, text, "clear")

         end

      end

      gui.box(16, -180, 38, -162, "clear", whiteStroke) -- position 0 outline
      gui.box(40, -180, 62, -162, "clear", "yellow")   -- position 1 outline
      gui.box(64, -180, 86, -162, "clear", blueStroke)  -- position 2 outline
      gui.box(88, -180, 110, -162, "clear", redStroke)
      gui.box(112, -180, 134, -162, "clear", "yellow")
      gui.box(136, -180, 158, -162, "clear", redStroke)
      gui.box(160, -180, 182, -162, "clear", "yellow")

   end

end

gui.register(main)
