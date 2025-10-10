-- Memory map by eidako/yab:
-- https://gamefaqs.gamespot.com/ds/937281-dragon-quest-ix-sentinels-of-the-starry-skies/faqs/68804

local tbl_addr = {
   mapCount = 0x020F98CC, -- (uint8) number of maps in inventory (0-99)
   mapBase = 0x020F98CE   -- (uint8) treasure map base addr (status + current map + type)
}

local tbl_offset = {
   mapIndex = 0x1C,
   discover = 0x1,      -- Ascii2f[10] same as ascii but characters are 0x2F less(?)
   conquer = 0xB,       -- Ascii2f[10] same as ascii but characters are 0x2F less(?)
   location = 0x15,
   treasure = 0x16,
   fqOrLegacyId = 0x17, -- (uint8) final quality (normal), boss number (legacy)
   bossLv = 0x18,       -- (uint8) legacy only
   seedOrTurns = 0x1A   -- (uint16) map seed (normal), minimum turns (legacy)
}

-- mult/inc parameters for AT positions
local tbl_param = {
   {2371908317, 2518396845}, -- 13th (environment)
   {2298363417, 639546082},  -- 14th (depth)
   {729943717, 1381971571},  -- 15th (starting monster rank)
   {1601471041, 1695770928}, -- 16th (boss)
   {4009059357, 1588911645}, -- 29th (prefix)
   {1315599961, 2518522002}, -- 30th (suffix)
   {4114186725, 33727075},   -- 31st (locale)
   {2335052929, 1680572000}, -- 32nd (level)
   {3248503605, 527630783},  -- 35th (map method monster ID)
   {2202098577, 1194991756}, -- 36th (map method deftness 1)
   {1876961981, 3253908437}  -- 37th (map method deftness 2)
}

local tbl_ascii = {
   {0x00, 0x04, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x3F, 0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x4A, 0x4B, 0x4C, 0x4D, 0x53, 0x54, 0x55, 0x58, 0x5C, 0x5D, 0x5E, 0x5F, 0x60, 0x61, 0x62, 0x63, 0x65, 0x66, 0x67, 0x69, 0x6A, 0x6B, 0x6D, 0x6F, 0x71, 0x72, 0x74, 0x76, 0x78, 0x79, 0x7A, 0x7B, 0x7C, 0x7D, 0x7E, 0x7F, 0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8A, 0x8B, 0x8D, 0x8E, 0x8F, 0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9A, 0x9B, 0x9C, 0x9D, 0x9E, 0x9F, 0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7, 0xA8, 0xA9, 0xE4, 0xE5, 0xE6, 0xE7, 0xE8, 0xE9, 0xEA, 0xEB, 0xEC, 0xED, 0xEE, 0xF0, 0xFF},

   {"", "'", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "{", "|", "}", "EUR", ",", ",,", "OE", "oe", "!", "GBP", "<<", ">>", "?", "!", '"', "#", "$", "%", "&", "(", ")", "+", "-", ".", "/", ";", "=", "?", "[", "]", "_", "A", "A", "A", "A", "AE", "C", "E", "E", "E", "E", "I", "I", "I", "I", "N", "O", "O", "O", "O", "O", "U", "U", "U", "U", "ss", "a", "a", "a", "a", "ae", "c", "e", "e", "e", "e", "i", "i", "i", "i", "n", "o", "o", "o", "o", "o", "o", "o", "o", "o", "~", ":-)", "*", "@", "cent", "a", "deg", "<-", "^", "->", "v", "-", " "}
}

-- Speed, entrance, and access data for locations
local tbl_locData = {
   "3rd,Not Hit,-",
   "-,Hit,-",
   "-,Not Hit,Indirect",
   "-,Not Hit,-",
   "7th,Not Hit,-",
   "13th,Not Hit,-",
   "-,Not Hit,-",
   "-,Hit,-",
   "-,Not Hit,-",
   "-,Barely Hit,-",
   "-,Not Hit,-",
   "-,Not Hit,Indirect",
   "-,Hit,-",
   "-,Hit,-",
   "14th,Hit,-",
   "-,Not Hit,-",
   "-,Hit,-",
   "-,Hit,-",
   "-,Not Hit,-",
   "-,Hit,-",
   "-,Hit,-",
   "-,Not Hit,-",
   "6th,Not Hit,-",
   "-,Not Hit,-",
   "-,Hit,Indirect",
   "-,Not Hit,-",
   "-,Hit,-",
   "-,Hit,-",
   "5th,Hit,-",
   "-,Not Hit,-",
   "-,Not Hit,-",
   "10th,Not Hit,-",
   "-,Hit,-",
   "1st,Hit,-",
   "-,Not Hit,-",
   "-,Hit,-",
   "-,Hit,-",
   "-,Not Hit,-",
   "-,Not Hit,-",
   "-,Not Hit,-",
   "-,Barely Hit,-",
   "-,Not Hit,-",
   "-,Not Hit,-",
   "11th,Hit,-",
   "15th,Not Hit,-",
   "-,Not Hit,-",
   "-,Hit,Ship",
   "-,Not Hit,Ship",
   "-,Hit,Ship",
   "-,Not Hit,Ship",
   "-,Hit,Ship",
   "-,Not Hit,Ship",
   "-,Not Hit,Ship",
   "-,Hit,-",
   "-,Not Hit,-",
   "-,Barely Hit,-",
   "-,Not Hit,-",
   "-,Not Hit,-",
   "-,Not Hit,-",
   "-,Not Hit,Ship",
   "-,Not Hit,-",
   "-,Not Hit,-",
   "-,Hit,-",
   "-,Not Hit,-",
   "-,Hit,-",
   "-,Not Hit,-",
   "-,Hit,-",
   "2nd,Barely Hit,-",
   "-,Hit,-",
   "-,Not Hit,-",
   "-,Not Hit,-",
   "-,Not Hit,-",
   "-,Hit,-",
   "-,Barely Hit,-",
   "-,Not Hit,-",
   "-,Hit,-",
   "-,Barely Hit,-",
   "-,Hit,-",
   "-,Hit,-",
   "-,Not Hit,-",
   "-,Not Hit,-",
   "-,Hit,-",
   "8th,Not Hit,-",
   "-,Not Hit,-",
   "-,Not Hit,-",
   "-,Not Hit,-",
   "12th,Hit,-",
   "-,Not Hit,-",
   "-,Barely Hit,-",
   "-,Hit,-",
   "-,Not Hit,-",
   "-,Hit,-",
   "-,Hit,-",
   "-,Hit,-",
   "-,Hit,-",
   "-,Hit,-",
   "-,Not Hit,-",
   "-,Barely Hit,Ship",
   "-,Not Hit,Ship",
   "-,Hit,Ship",
   "-,Not Hit,Ship",
   "-,Hit,Ship",
   "-,Not Hit,Ship",
   "-,Not Hit,Ship",
   "4th,Not Hit,-",
   "-,Not Hit,-",
   "-,Not Hit,-",
   "-,Hit,-",
   "-,Not Hit,-",
   "-,Hit,-",
   "-,Not Hit,-",
   "-,Not Hit,-",
   "-,Barely Hit,Ship",
   "-,Not Hit,-",
   "-,Hit,-",
   "-,Hit,-",
   "-,Not Hit,-",
   "-,Not Hit,-",
   "-,Hit,-",
   "-,Not Hit,-",
   "-,Not Hit,-",
   "-,Not Hit,-",
   "-,Not Hit,-",
   "-,Not Hit,-",
   "-,Not Hit,-",
   "-,Not Hit,-",
   "-,Not Hit,-",
   "9th,Hit,-",
   "-,Hit,-",
   "-,Not Hit,Indirect",
   "-,Hit,Ship",
   "-,Hit,-",
   "-,Not Hit,-",
   "-,Hit,Train",
   "-,Not Hit,Train",
   "-,Hit,Train",
   "-,Not Hit,Train",
   "-,Hit,Train",
   "-,Not Hit,Train",
   "-,Barely Hit,Train",
   "-,Not Hit,Train",
   "-,Not Hit,Train",
   "-,Hit,Train",
   "-,Not Hit,Train",
   "-,Barely Hit,Train",
   "-,Not Hit,Train",
   "-,Not Hit,Train",
   "-,Not Hit,Train",
   "-,Hit,Train",
   "-,Not Hit,Train"
}

local tbl_contents = {
   statusId = {0x09, 0x0A, 0x0C, 0x11, 0x12, 0x14}, -- If a map is currently being followed: +0x20
   statusName = {"New", "Discovered", "Cleared", "New", "Discovered", "Cleared"}, -- Normal/Normal/Normal/Legacy/Legacy/Legacy

   dropId = {0, 1, 3, 5, 7}, -- 1st = +1, 2nd = +2, 3rd = +4
   dropName = {"-/-/-", "1/-/-", "1/2/-", "1/-/3", "1/2/3"},

   legacyName = {"Dragonlord", "Malroth", "Baramos", "Zoma", "Psaro", "Estark", "Nimzo", "Murdaw", "Mortamor", "Nokturnus", "Orgodemir", "Dhoulmagus", "Rhapthorne"},

   rankMin = {2, 56, 61, 76, 81, 101, 121, 141, 161, 181, 201, 221},
   rankMax = {55, 60, 75, 80, 100, 120, 140, 160, 180, 200, 220, 248},

   envMin = {0, 30, 70, 80, 90},
   envMax = {29, 69, 79, 89, 99},
   envName = {"Caves", "Ruins", "Ice", "Water", "Fire"},

   depthMod = {3, 3, 3, 5, 5, 5, 5, 7, 7, 6, 5, 3},
   depthInc = {2, 4, 4, 6, 6, 8, 10, 10, 10, 11, 12, 14},

   smrMod = {3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 2, 1},
   smrInc = {1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 8, 9},

   bossMod = {275, 275, 300, 300, 280, 205, 170, 120, 90, 80, 560, 560},
   bossInc = {0, 0, 100, 100, 200, 275, 350, 400, 450, 480, 0, 0},
   bossMin = {0, 100, 200, 275, 350, 400, 450, 480, 500, 520, 540, 550},
   bossMax = {99, 199, 274, 349, 399, 449, 479, 499, 519, 539, 549, 559},
   bossName = {"Equinox", "Nemean", "Shogum", "Trauminator", "Elusid", "Sir Sanguinus", "Atlas", "Hammibal", "Fowleye", "Excalipurr", "T-Wrecks", "Greygnarl"},

   prefixMod = {5, 5, 5, 5, 6, 6, 10, 10, 5},
   prefixInc = {1, 1, 4, 4, 7, 7, 7, 7, 12},
   prefixName = {"Clay", "Rock", "Granite", "Basalt", "Graphite", "Iron", "Copper", "Bronze", "Steel", "Silver", "Gold", "Platinum", "Ruby", "Emerald", "Sapphire", "Diamond"},

   localeMod = {2, 2, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 3},
   localeInc = {1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 4, 4, 6},
   localeName = {"Cave", "Tunnel", "Cave", "Cave", "Cave", "Mine", "Mine", "Crevasse", "Marsh", "Mine", "Lair", "Lair", "Icepit", "Lake", "Crater", "Path", "Path", "Snowhall", "Moor", "Dungeon", "Crypt", "Crypt", "Crypt", "Crypt", "Crypt", "Nest", "Ruins", "Tundra", "Waterway", "Nest", "World", "World", "World", "World", "World", "Abyss", "Maze", "Glacier", "Chasm", "Void"},

   suffixInc = {1, 1, 1, 4, 4, 4, 7, 7, 7, 10, 10, 10},
   suffixName = {"Joy", "Bliss", "Glee", "Doubt", "Woe", "Dolour", "Regret", "Bane", "Fear", "Dread", "Hurt", "Gloom", "Doom", "Evil", "Ruin", "Death"}
}

local tbl_monsterSpawn = {
   {0, 1426, 4856, 7282, 10427, 11917, 15820, 16385, 16950, 18725, 20026, 21846, 29648, 30428, 31130, 31555},
   {1425, 4855, 7281, 10426, 11916, 15819, 16384, 16949, 18724, 20025, 21845, 29647, 30427, 31129, 31554, 32767},
   {"LMS (Ruins MR7)", "-", "GS (Ruins MR11)", "-", "MM (Ruins MR3)", "-", "LMS (Fire MR4)", "LMS (Fire MR4) / GJ (Caves MR7) / MKS (Water MR8)", "GJ (Caves MR7) / MKS (Water MR8)", "-", "PKJ (Ruins MR12)", "-", "GJ (Ruins MR8)", "GJ (Ruins MR8) / MKS (Fire MR9)", "GJ (Ruins MR8) / MKS (Fire MR9) / GS (Ice MR10)", "GJ (Ruins MR8/10) / MKS (Fire MR9/Caves MR10) / GS (Ice MR10)"}
}

local scriptComplete = false

local function getHex(decimal, digits)
   return decimal and string.format("%0" .. digits .. "X", decimal) or "?"
end

local function lookup(searchKey, searchTbl1, searchTbl2, returnTbl, searchMode)
   for i = 1, #searchTbl1 do
       if (searchMode == "exact" and searchKey == searchTbl1[i]) or
          (searchMode == "range" and searchKey >= searchTbl1[i] and searchKey <= searchTbl2[i]) then
           return {index = i, value = returnTbl[i]}
       end
   end
   return {index = 1, value = "?"}
end

local function maskCurrentMap(statusType)
   local currentMap = 0x20
   return bit.band(statusType, currentMap) == currentMap and statusType - currentMap or statusType
end

local function getAscii(nameBase)
   local ascii = ""
   for i = 0, 9 do
      local char = lookup(memory.readbyte(nameBase + i), tbl_ascii[1], nil, tbl_ascii[2], "exact")
      ascii = ascii..char.value
   end
   return ascii == "" and "?????" or ascii
end

local function getOutput(seed, a, c)
   local hi = bit.rshift(seed, 16)
   local lo = bit.band(seed, 65535) * a + c
   local cr = bit.rshift(lo, 16)
   hi = bit.band(hi * a + cr, 65535)
   return bit.band(hi, 32767)
end

local function getMR(smr, depth)
   if depth >= 13 then return smr.."/"..(smr + 1).."/"..(smr + 2).."/"..(smr + 3)
   elseif depth >= 9 then return smr.."/"..(smr + 1).."/"..(smr + 2)
   elseif depth >= 5 then return smr.."/"..(smr + 1)
   end
   return smr
end

local function getSuffix(rand, bossIndex)
   local mod = 6
   if bossIndex > 9 then mod = 7 end
   local suffixIndex = rand % mod + tbl_contents.suffixInc[bossIndex]
   return tbl_contents.suffixName[suffixIndex]
end

local function getLv(rand, depth, smr, bossIndex)
   local lv = rand % 11 - 5 + (depth + smr + bossIndex - 4) * 3
   if lv < 1 then return 1
   elseif lv > 99 then return 99
   end
   return lv
end

local function getDeftness(rand)
   local dft = math.ceil(rand / 32768 * 100 - 2) * 20 -- 2 = normal encounter (not behind)
   return (dft <= 0) and 0 or (dft > 999 and "-" or dft)
end

local function main()
   if scriptComplete then return end
   scriptComplete = true

   local maps = memory.readbyte(tbl_addr.mapCount)
   if maps > 0 then
      local HEADER_ROW = "#,Name,Lv,Status,Discovered by,Conquered by,Drops,Min Turns,FQ,Rank,Seed,@,Speed,Entrance,Access,Type,Depth,SMR,Monster Ranks,Boss,Deftness (36th), Deftness (37th), Map Method Metal Slimes (35th),Link"
      print(HEADER_ROW)

      for i = 1, maps do
         local base = tbl_offset.mapIndex * (i - 1) + tbl_addr.mapBase
         local statusMasked = maskCurrentMap(memory.readbyte(base))
         local status = lookup(statusMasked, tbl_contents.statusId, nil, tbl_contents.statusName, "exact")
         local disc = getAscii(base + tbl_offset.discover)
         local conq = getAscii(base + tbl_offset.conquer)
         local drops = lookup(memory.readbyte(base + tbl_offset.treasure), tbl_contents.dropId, nil, tbl_contents.dropName, "exact")
         local loc = memory.readbyte(base + tbl_offset.location)
         local locHex = getHex(loc, 2)
         local speedEntranceAccess = tbl_locData[loc]
         local finalQualityOrLegacyId = memory.readbyte(base + tbl_offset.fqOrLegacyId)
         local seedTurns = memory.readword(base + tbl_offset.seedOrTurns)
         local LEGACY_NEW = 0x11

         local basicData = status.value..',"'..disc..'","'..conq..'",'.."'"..drops.value

         -- Normal
         if statusMasked < LEGACY_NEW then
            local tbl_output = {}
            for p = 1, 11 do
               tbl_output[p] = getOutput(seedTurns, tbl_param[p][1], tbl_param[p][2])
            end

            local rank = lookup(finalQualityOrLegacyId, tbl_contents.rankMin, tbl_contents.rankMax, tbl_contents.rankMin, "range")
            local environ = lookup(tbl_output[1] % 100, tbl_contents.envMin, tbl_contents.envMax, tbl_contents.envName, "range")
            local depth = tbl_output[2] % tbl_contents.depthMod[rank.index] + tbl_contents.depthInc[rank.index]
            local smr = tbl_output[3] % tbl_contents.smrMod[rank.index] + tbl_contents.smrInc[rank.index]
            local mr = getMR(smr, depth)
            local bossMath = tbl_output[4] % tbl_contents.bossMod[rank.index] + tbl_contents.bossInc[rank.index]
            local boss = lookup(bossMath, tbl_contents.bossMin, tbl_contents.bossMax, tbl_contents.bossName, "range")
            local prefix = tbl_contents.prefixName[tbl_output[5] % tbl_contents.prefixMod[smr] + tbl_contents.prefixInc[smr]]
            local locale = tbl_contents.localeName[(tbl_output[7] % tbl_contents.localeMod[depth - 1] + tbl_contents.localeInc[depth - 1]) * 5 - 5 + environ.index]
            local suffix = getSuffix(tbl_output[6], boss.index)
            local lv = getLv(tbl_output[8], depth, smr, boss.index)
            local metal = lookup(tbl_output[9], tbl_monsterSpawn[1], tbl_monsterSpawn[2], tbl_monsterSpawn[3], "range")
            local dft36 = getDeftness(tbl_output[10])
            local dft37 = getDeftness(tbl_output[11])

            local rankHex = getHex(rank.value, 2)
            local seedHex = getHex(seedTurns, 4)
            local YAB_LINK = "https://www.yabd.org/apps/dq9/grottodetails.php?map=" -- Append rank and seed
            
            mapData = i..","..prefix.." "..locale.." "..suffix..","..lv..","..basicData..",-,"..finalQualityOrLegacyId..",'"..rankHex..",'"..seedHex..",'"..locHex..","..speedEntranceAccess..","..environ.value..",B"..depth..","..smr..",'"..mr..","..boss.value..","..dft36..","..dft37..","..metal.value..","..YAB_LINK..rankHex..seedHex

         -- Legacy
         elseif statusMasked >= LEGACY_NEW then
            local legacy = tbl_contents.legacyName[finalQualityOrLegacyId]
            local lv = memory.readbyte(base + tbl_offset.bossLv)
            mapData = i..","..legacy.."'s Map,"..lv..","..basicData..","..seedTurns..",-,-,-,'"..locHex..","..speedEntranceAccess..",Legacy,-,-,-,"..legacy..",-,-,-,-"
         end
         print(mapData)
         mapData = nil
      end
   end
end

memory.registerread(tbl_addr.mapBase, main)