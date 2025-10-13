-- C Set a random value in the table

function printf(...) print(string.format(...)) end
reg = memory.getregister
regw = memory.setregister
read8 = memory.readbyte
read16 = memory.readword
-- read32 = memory.readdword
write8 = memory.writebyte

memory.writedword(0x2385F0C, 0x653ad96)
memory.writedword(0x2385F0C+4, 0x0)
