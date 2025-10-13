-- Absolute flee success

function printf(...) print(string.format(...)) end
reg = memory.getregister
regw = memory.setregister
read8 = memory.readbyte
read16 = memory.readword
-- read32 = memory.readdword
write8 = memory.writebyte


memory.registerexec(0x021611e0, function()
    if reg("r0") == 0 then
        printf("2 prng called: %#.8x", reg("r0"))
        regw("r0", 1)
    end
    --regw("r0", 0)
end)

memory.registerexec(0x0209d1c0, function()
    printf("r1: %#.8x", reg("r1"))
    printf("r3: %#.8x", reg("r3"))
end)