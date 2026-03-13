local spritePath = "sprites/itemIcons.bmp"
local iconSize = 25
local iconScale = 0.5
local columns = 11

local items = {
   {sprite="sprites/m05m00sgn03.bmp", addr={0x020F923C,0x020F9240}}, -- Fountain (Stornway)
   {icon=750, addr={0x020F90B8}},                       -- Medicinal herb
   {icon=753, addr={0x020F90EC,0x020F91C8}},            -- Superior medicine
   {icon=754, addr={0x020F90C4,0x020F90DC}},            -- Antidotal herb
   {icon=758, addr={0x020F910C}},                       -- Softwort
   {icon=763, addr={0x020F915C}},                       -- Yggdrasil leaf
   {icon=765, addr={0x020F9178}},                       -- Magic water
   {icon=768, addr={0x020F90F4}},                       -- Holy water
   {icon=769, addr={0x020F9220}},                       -- Chimaera wing
   {icon=771, addr={0x020F90C8}},                       -- Coagulant
   {icon=772, addr={0x020F90C0,0x020F91E8}},            -- Tangleweb
   {icon=773, addr={0x020F911C,0x020F9164,0x020F91CC}}, -- Sleeping hibiscus
   {icon=774, addr={0x020F9118,0x020F91A0,0x020F91E4}}, -- Wakerobin
   {icon=776, addr={0x020F91B8,0x020F9208}},            -- Rockbomb shard
   {icon=787, addr={0x020F9190}},                       -- Gleeban groat
   {icon=788, addr={0x020F912C,0x020F9210}},            -- Gleeban guinea
   {icon=800, addr={0x020F90E4}},                       -- Mini medal
   {icon=828, addr={0x020F90D8}},                       -- Cowpat
   {icon=829, addr={0x020F918C}},                       -- Horse manure
   {icon=830, addr={0x020F90FC,0x020F91F8}},            -- Lava lump
   {icon=831, addr={0x020F9110,0x020F919C}},            -- Fresh water
   {icon=832, addr={0x020F9120,0x020F91AC}},            -- Flurry feather
   {icon=833, addr={0x020F9100,0x020F91A4}},            -- Royal soil
   {icon=834, addr={0x020F9160,0x020F9168}},            -- Ice crystal
   {icon=835, addr={0x020F9158,0x020F91EC}},            -- Thunderball
   {icon=836, addr={0x020F913C,0x020F91BC}},            -- Evencloth
   {icon=837, addr={0x020F9144,0x020F91E0}},            -- Brighten rock
   {icon=839, addr={0x020F90F8,0x020F9104,0x020F9130}}, -- Iron ore
   {icon=840, addr={0x020F9124,0x020F9170}},            -- Platinum ore
   {icon=841, addr={0x020F9194,0x020F9214}},            -- Mythril ore
   {icon=845, addr={0x020F9128,0x020F91C0}},            -- Corundum
   {icon=846, addr={0x020F91B0,0x020F920C}},            -- Flintstone
   {icon=847, addr={0x020F9140,0x020F91B4}},            -- Resurrock
   {icon=848, addr={0x020F9184,0x020F9200}},            -- Mirrorstone
   {icon=858, addr={0x020F90E0,0x020F9198,0x020F9204}}, -- Manky mud
   {icon=859, addr={0x020F9148}},                       -- Kitty litter
   {icon=860, addr={0x020F9138,0x020F91F0}},            -- Glass frit
   {icon=861, addr={0x020F90F0,0x020F914C,0x020F91D0}}, -- Belle cap
   {icon=862, addr={0x020F90CC,0x020F9188,0x020F91F4}}, -- Fisticup
   {icon=864, addr={0x020F90E8,0x020F9154,0x020F91D4}}, -- Slipweed
   {icon=865, addr={0x020F9174,0x020F91FC,0x020F921C}}, -- Thinkincense
   {icon=866, addr={0x020F917C,0x020F91DC}},            -- Narspicious
   {icon=867, addr={0x020F9150,0x020F9218}},            -- Seashell
   {icon=868, addr={0x020F9108,0x020F91C4}},            -- Crimson coral
   {icon=869, addr={0x020F9180,0x020F91D8}},            -- Emerald moss
   {icon=870, addr={0x020F9114,0x020F916C,0x020F91A8}}  -- Nectar
}

-- Sparkly spots influenced by fountain group
local fountainSpot = {
   [0x020F923C]=true, -- Fountain 1 (Stornway)
   [0x020F9240]=true, -- Fountain 2 (Stornway)
   [0x020F9178]=true, -- Magic water (Cringle Coast)
   [0x020F9164]=true, -- Sleeping hibiscus (Snowberia)
   [0x020F9190]=true, -- Gleeban groat (Iluugazar Plains)
   [0x020F90FC]=true, -- Lava lump (Newid Isle)
   [0x020F91F8]=true, -- Lava lump (Wyrmsmaw)
   [0x020F9110]=true, -- Fresh water (Slurry Coast)
   [0x020F919C]=true, -- Fresh water (Mt Ulzuun (South))
   [0x020F9120]=true, -- Flurry feather (Bloomingdale)
   [0x020F91AC]=true, -- Flurry feather (Mt Ulbaruun)
   [0x020F9100]=true, -- Royal soil (Newid Isle)
   [0x020F91A4]=true, -- Royal soil (Mt Ulbaruun)
   [0x020F9160]=true, -- Ice crystal (Snowberia)
   [0x020F9168]=true, -- Ice crystal (Snowberian Coast)
   [0x020F9158]=true, -- Thunderball (Hermany (Island))
   [0x020F91EC]=true, -- Thunderball (Wyrmwing)
   [0x020F913C]=true, -- Evencloth (Djust Desert)
   [0x020F91BC]=true, -- Evencloth (Ondor Cliffs)
   [0x020F9144]=true, -- Brighten rock (Djust Desert)
   [0x020F91E0]=true, -- Brighten rock (Wormwood Canyon (East))
   [0x020F9170]=true, -- Platinum ore (Snowberian Coast (Northeast))
   [0x020F9128]=true, -- Corundum (Dourbridge)
   [0x020F91B4]=true, -- Resurrock (Khaalag Coast)
   [0x020F90CC]=true, -- Fisticup (Western Stornway)
   [0x020F9154]=true  -- Slipweed (Hermany)
}

-- Precompute address metadata (color + addr)
for _,item in ipairs(items) do

   item.addrInfo = {}

   for _,addr in ipairs(item.addr) do
      item.addrInfo[#item.addrInfo+1] = {
         addr = addr,
         color = fountainSpot[addr] and "cyan" or "white"
      }
   end

end

local fountainGroup = {"0RE","ST0NE","WATER","FL0WER","SEA","GRASS","MUSHR00M","SAND"}

local SpriteSheet = {}
SpriteSheet.sheetCache = {}
SpriteSheet.iconCache  = {}

local fountainGroupAddr = 0x020F90B2
local tagCountAddr = 0x020FD764
local bg = "#000000C0"

local toggle = true
local prevStart = false

local topCount = 22
local bottomCount = 24

local rowsTop = math.ceil(topCount / 2)
local rowsBottom = math.ceil(bottomCount / 2)

local colWidth = 128
local rowHeight = 16
local colStartX = 35
local topStartY = -178
local bottomStartY = 1

local itemLayout = {}

for i=1,#items do

   local screenTop = i <= topCount
   local index = screenTop and i or (i - topCount)

   local rows = screenTop and rowsTop or rowsBottom

   local pos = index - 1
   local col = math.floor(pos / rows)
   local row = pos % rows

   local x = colStartX + col * colWidth
   local y = screenTop and (topStartY + row * rowHeight)
                        or (bottomStartY + row * rowHeight)

   itemLayout[i] = {x=x,y=y}

end

local function readInt(f)
   local b1,b2,b3,b4 = f:read(1):byte(),f:read(1):byte(),f:read(1):byte(),f:read(1):byte()
   return b1 + b2*256 + b3*65536 + b4*16777216
end

function SpriteSheet.load(path)

   if SpriteSheet.sheetCache[path] then
      return SpriteSheet.sheetCache[path]
   end

   local f = assert(io.open(path,"rb"))

   f:seek("set",10)
   local pixelOffset = readInt(f)

   f:seek("set",18)
   local width  = readInt(f)
   local height = readInt(f)

   f:seek("set",pixelOffset)

   local img = {w=width,h=height,p={}}

   for y=height,1,-1 do

      img.p[y] = {}

      for x=1,width do

         local b,g,r = f:read(1):byte(),f:read(1):byte(),f:read(1):byte()

         if r==255 and g==0 and b==255 then
            img.p[y][x] = 0x00000000
         else
            img.p[y][x] = r*0x1000000 + g*0x10000 + b*0x100 + 0xFF
         end

      end

      local padding = (4 - (width*3)%4)%4
      f:read(padding)

   end

   f:close()

   SpriteSheet.sheetCache[path] = img
   return img
end

function SpriteSheet.sliceIcons(path)

   if SpriteSheet.iconCache[path] then return end

   local sheet = SpriteSheet.load(path)
   SpriteSheet.iconCache[path] = {}

   local rows = math.floor(sheet.h / iconSize + 0.5)

   for row=0,rows-1 do
      for col=0,columns-1 do

         local index = row*columns + col + 1
         local icon = {}

         for py=0,iconSize-1 do
            for px=0,iconSize-1 do

               local sx = col*iconSize + px + 1
               local sy = row*iconSize + py + 1

               if sy <= sheet.h and sx <= sheet.w then

                  local c = sheet.p[sy][sx]

                  if c ~= 0x00000000 then

                     local dx = math.floor(px * iconScale)
                     local dy = math.floor(py * iconScale)

                     icon[#icon+1] = {dx,dy,c}

                  end
               end
            end
         end
         SpriteSheet.iconCache[path][index] = icon
      end
   end
end

function SpriteSheet.drawIconIndex(x,y,index,path)
   local icon = SpriteSheet.iconCache[path][index]
   if not icon then return end

   for _,p in ipairs(icon) do
      gui.pixel(x+p[1],y+p[2],p[3])
   end
end

function SpriteSheet.drawImage(x,y,path)
   local img = SpriteSheet.load(path)

   for py=1,img.h do
      for px=1,img.w do
         local c = img.p[py][px]

         if c ~= 0x00000000 then
            local draw = true

            -- Thin the first vertical stroke of the Ns
            if (px == 24 or px == 42) and (py % 2 == 0) then
               draw = false
            end

            if draw then
               local dx = math.floor((px-1) * iconScale)
               local dy = math.floor((py-1) * iconScale)
               gui.pixel(x+dx,y+dy,c)
            end
         end
      end
   end
end

local function popcount(x)
   local c = 0
   while x ~= 0 do
      x = bit.band(x, x - 1)
      c = c + 1
   end
   return c
end

local function getFountainMax(addr)
    local tags = memory.readdword(tagCountAddr)
    local maxTotal = math.min(math.floor(tags / 100) + 4, 14)

    -- first node holds up to 7, second gets the remainder
    if addr == 0x020F923C then
        return math.min(maxTotal, 7)
    elseif addr == 0x020F9240 then
        return math.max(maxTotal - 7, 0)
    end
end

local function getTimer(addr)
   local bitfield = memory.readdword(addr)
   local rawMinutes = bit.band(bitfield,0x1FF)
   local maxItems = bit.band(bit.rshift(bitfield,9),0xF)
   local slotBits = bit.band(bit.rshift(bitfield,17),0xFF)
   local itemsPresent = popcount(slotBits)
   local hours = math.floor(rawMinutes / 60)
   local minutes = rawMinutes % 60
   local timer = string.format("%d:%02d", hours, minutes)
   return timer, itemsPresent, maxItems
end

local function renderTimers()
   for i,item in ipairs(items) do
      local layout = itemLayout[i]
      local x = layout.x
      local y = layout.y

      if item.icon then
         SpriteSheet.drawIconIndex(x - 18, y + 1, item.icon, spritePath)
      elseif item.sprite then
         SpriteSheet.drawImage(0, y - 1, item.sprite)
      end

      local offset = 0

      for _,a in ipairs(item.addrInfo) do
         local timer, current, max = getTimer(a.addr)

         -- override fountain capacity
         if a.addr == 0x020F923C or a.addr == 0x020F9240 then
            max = getFountainMax(a.addr)
         end

         local capacity = string.format("%d/%d", current, max)

         local capColor = "white"
         if current == 0 then
            capColor = "grey"
         elseif current == max then
            capColor = "green"
         end

         gui.text(x + offset, y, timer, a.color, "clear")
         gui.text(x + offset, y + 8, capacity, capColor, "clear")

         offset = offset + 30
      end
   end
end

local function handleToggle(inputs)
   if inputs.start and not prevStart then
      toggle = not toggle
   end
   prevStart = inputs.start
end

local function renderGUI(group)
   gui.box(0,-1,255,-192,bg,bg)
   gui.box(0,0,255,191,bg,bg)
   gui.text(35, -188, group, "cyan", "clear")
end

local function main()
   local group = memory.readbyte(fountainGroupAddr)
   local groupName = fountainGroup[group+1] or "-"
   local inputs = joypad.get(1)
   handleToggle(inputs)

   if toggle then
      renderGUI(groupName)
      renderTimers()
   end
end

SpriteSheet.sliceIcons(spritePath)

gui.register(main)
