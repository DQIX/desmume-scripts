-- Allies always perform critical attacks

function printf(...) print(string.format(...)) end
reg = memory.getregister
regw = memory.setregister
read8 = memory.readbyte
read16 = memory.readword
-- read32 = memory.readdword
write8 = memory.writebyte
read32 = memory.readword

local max=0;
local counter = 0
local LR = 0
local tmp = 0
local flag = 0

--  memory.registerexec(0x02158444, function()
--      --print(string.format("r1: %#.8x", memory.getregister("r14")))
-- end)

memory.registerexec(0x02158590, function()
    --print(reg("r0"))
    tmp = reg("r0")
    if tmp ~= 0 then
        print("10000/".. reg("r0"))
    end
end)


memory.registerexec(0x0215859c, function()
    flag = 0
    if tmp ~= 0 then
        regw("r0", 1)
        flag = 1
    end
end)
