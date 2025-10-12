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



memory.registerexec(0x021587bc, function()
    print("mikawasi", reg("r0"))
    regw("r4", 0)
end)
memory.registerexec(0x02158258, function()
    print("kaihi", reg("r0"))
end)
memory.registerexec(0x02158700, function()
    print("shield", reg("r4"))
end)
