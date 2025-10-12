-- Overrides monster spawning on the field.

memory.registerexec(0x020751e8, function()
    memory.setregister("r0", 0xffffffff);--0x3
end)

--suraimu
-- memory.registerexec(0x020751e8, function()
--     memory.setregister("r0", 0x1);
-- end)

--buraza-zu
-- memory.registerexec(0x020751e8, function()
--     memory.setregister("r0", 0x4C);
-- end)

-- merago-suto
-- memory.registerexec(0x020751e8, function()
--     memory.setregister("r0", 0x7);
-- end)

--hagure metaru
-- memory.registerexec(0x020751e8, function()
--     memory.setregister("r0", 0x1B);
-- end)

-- Platinum king jewel
-- memory.registerexec(0x020751e8, function()
--     memory.setregister("r0", 0xf2);
-- end)
