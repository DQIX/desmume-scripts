-- Shows which overlays are loaded in real time

function printf(...) print(string.format(...)) end
function printhex(string, hex) 
    if hex == nil then
        print(string .. ": nil")
    else
        printf("%s: %#.8x", string, hex)
    end
end
reg = memory.getregister
regw = memory.setregister
read8 = memory.readbyte
write8 = memory.writebyte
read16 = memory.readword
read32 = memory.readdword


local LoadedOverlayTable = 0x01FFD384 --0x01FFD385
local whereToLoadTable = 0x020e9034
local y9binStartAddr = 0x01FFD3B4
local LoadedTable = {
    {nil,nil},
    {nil,nil},
    {nil,nil},
    {nil,nil},
    {nil,nil},
};


function getStartAddr(overlayId)
    return read32(y9binStartAddr + overlayId * 0x2c + 4)
end

function getSlot(overlayId)
    return read32(whereToLoadTable + overlayId * 8);
end

memory.registerexec(0x020a36b8, function()
    overlayId = reg("r0")
    slot = getSlot(overlayId)
    LoadedTable[slot] = {overlayId1, getStartAddr(overlayId), reg("r14")}
    printf("slot %s, loaded %s, start at %#.8x, LR: %#.8x, r1: %#.8x, r2: %#.8x, r3: %#.8x", slot, overlayId, getStartAddr(overlayId), reg("r14"), reg("r1"), reg("r2"), reg("r3"))
 end)

 memory.registerexec(0x20a392c, function()
    overlayId = reg("r0")
    slot = getSlot(overlayId)
    LoadedTable[slot] = {nil, nil}
    printf("slot %s, unloaded %s", slot, overlayId);
 end)

for i = 0, 6 do
    local overlayId1 = read8(LoadedOverlayTable + i)
    if overlayId1 ~= 0xFF then
        LoadedTable[i] = {overlayId1, getStartAddr(overlayId1), nil}
    end
end
toggle = true

function main()
    buttonInput = bit.band(memory.readbyte(0x04000130), 0xF)

    x = 0
    y = -190

    if buttonInput == 7 then
        count = count + 1
        if count == 1 then toggle = not toggle end
     else
        count = 0
     end
  
     if not toggle then
        return
     end



     --gui.box(-10, -256, 256, 192, 255, 0)
     gui.box(-10, -256, 100, 192, 255, 0)

     for i = 0, 5 do
            local id = read8(LoadedOverlayTable + i)
            if id ~= 0xFF and bit.band(id, 0x40) ~= 0x40 then
                start = getStartAddr(id)
                slot = getSlot(id)
                string = "slot: " .. slot .. ", " .. "id: " .. id
                gui.text(x, y, string,"#CCCCCC", "clear")
                y = y + 10
            else
                string = "slot: " .. i .. " = nil"
                gui.text(x, y, string,"#CCCCCC", "clear")
                y = y + 10
            end
     end
     

end

gui.register(main)