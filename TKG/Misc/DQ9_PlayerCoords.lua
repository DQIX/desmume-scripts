-- TKG
-- USA ver

local topScreen = -192
local scale = 4096
local coords = {"X", "Y", "Z"}
local coordsd = {}
local coordsh = {}
local offset = 0

local addr = {
   0x022BBC20, -- player x
   0x022BBC24, -- player y
   0x022BBC28, -- player z
}

local function getHex(decimal, digits)
    return string.format("%0" .. digits .. "X", decimal)
end

local function renderGui()
   for i = 1, 3 do
      gui.text(11, i * 10, coords[i] .. ": " .. coordsh[i] .. " (" .. coordsd[i] .. ")")
   end
end

local function main()
   for i = 1, 3 do
      local coord = memory.readdwordsigned(addr[(i + offset)])
      coordsd[i] = string.format("%.3f", coord / scale)
      coordsh[i] = getHex(coord, 8)
   end
   renderGui()
end

gui.register(main)
