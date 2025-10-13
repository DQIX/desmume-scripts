-- c table shows the complete trace of random numbers

reg = memory.getregister
regw = memory.setregister
read8 = memory.readbyte
write8 = memory.writebyte
read16 = memory.readword
read32 = memory.readdword

function printf(...) print(string.format(...)) end
function printhex(string, hex) 
    if hex == nil then
        print(string .. ": nil")
    else
        printf("%s: %#.8x", string, hex)
    end
end

local max=0;
local counter = 0
local LR = 0
memory.registerexec(0x02075488, function()
  
  if reg("r0") == 0x02385F0C then
    if reg("r14") ~= 0x02075628 then
      max = reg("r1")
      counter = counter + 1
      LR = reg("r14")
      -- if reg("r1") == 0x64 then
         --regw("r1", 99)
      -- end
      -- --print("c")
      -- if counter == 231 then
      --   emu.pause()
      -- end

  
      print(string.format("%#.8x %#.8x %d", reg("r14"),  reg("r1"), counter)) --c rand: 
      --print(string.format("c max: %#.8x", reg("r1")))
      --print(counter)
    end
  else
    print("b")
    --print(string.format("debug: %#.8x", memory.getregister("r14")))
  end
end)
memory.registerexec(0x2075514, function()
  if reg("r0") == 0x02385F0C then
    counter = counter + 1
    print(string.format("float: %#.8x %#.8x %#.8x %d", reg("r14"),  reg("r1"),reg("r2"), counter)) --c rand: 
  end
end)
memory.registerexec(0x20754D8, function()
  if reg("r14") ~= 0x02075534 and reg("r14") ~= 0x020754b0 then
    counter = counter + 1
    print(string.format("getFloatRand: %#.8x %d", reg("r14"), counter)) --c rand: 
  end
end)
memory.registerexec(0x02075604, function()
  counter = counter + 1
  print(string.format("randIntRange: %#.8x %d %d %d", reg("r14"),reg("r1"),reg("r2"), counter)) --c rand: 
end)
-- randIntRange ret
-- memory.registerexec(0x02075630, function()
--   print("!!")
--   if counter == 18 then
--     regw("r0", 4)
--   end
--   if counter == 19 then
--     regw("r0", 8)
--   end
-- end)


memory.registerexec(0x02075560, function()
  counter = counter + 1
  print(string.format("getFloatRandWithPower: %#.8x %d %d %d * %d", reg("r14"),reg("r1"),reg("r2"),reg("r3"), counter)) --c rand: 
end)


memory.registerexec(0x0207544c, function()
  if reg("r14") ~= 0x020754f0 then
    counter = counter + 1
    print(string.format("UpdateLGC: %#.8x %d", reg("r14"), counter)) --c rand: 
  end
end)

memory.registerexec(0x021ebd9c, function()
  print("--------start_FUN_021ebd9c_ct-------")
end)
memory.registerexec(0x0215f950, function()
  print("--------end_FUN_021ebd9c_ct-------")
end)

memory.registerexec(0x021594bc, function()
  print("--------start_FUN_021594bc-------")
end)
memory.registerexec(0x0215f980, function()
  print("--------end_FUN_021594bc-------")
end)
memory.registerexec(0x02158dfc, function()
  print("\n--------start_FUN_02158dfc-------")
end)
memory.registerexec(0x0215f924, function()
  print("--------end_FUN_02158dfc-------")
end)

-- UpdateLGC: 0x0208af20
memory.registerexec(0x0208af54, function()
  printhex("ULGC", reg("r3"));
end)
memory.registerexec(0x0208af40, function()
  printhex("ULGC", reg("r2"));
end)

memory.registerexec(0x021e88f0, function()
  printhex("dmTyD:", reg("r0"));
end)

memory.registerexec(0x021e8680, function()
  printhex("dmTyD:", reg("r0"));
end)

local counter2 = 1;
local table1 = {
  -- 0x44,
  -- 0x44,
  -- 0x44,
  -- 0x44,
  -- 0x44,
  -- 0x44,
  -- 0x44,
  -- 0x44,
  0x44+0x3A+0x30+0x26-10, -- A移動
  --0x44+0x3A+0x30+0x26+0x1B-10,
  0x44-10,
  0x44-10,
  0x44+0x3A+0x30,
  0x44+0x3A+0x30,

  -- 0x44-1,
  -- 0x44+0x3A-1, -- あやしいひとみ
  -- 0x44+0x3A-10,
  -- --0x44+0x3A+0x30+0x26-10, -- A移動
  -- --0x44+0x3A+0x30+0x26-10, -- C移動
  -- -- 0x44+0x3A-1,
  -- -- 0x44+0x3A+0x30+0x26-10, -- A移動
  -- -- 0x44+0x3A+0x30+0x26-10, -- C移動
  -- -- 0x44+0x3A+0x30+0x26+0x1B-10,
  -- 0x44,
  -- 0x44,
  -- 0x44,
  -- 0x44,
  -- 0x44+0x3A+0x30+0x26+0x1B-10,
  -- 0x44+0x3A+0x30+0x26+0x1B-10,
  -- 0x44+0x3A+0x30+0x26+0x1B-10,
};

-- print(0x44+0x3A+0x30+0x26+0x1B+0x11)
-- print(0x2B+0x2A+0x2B+0x2B+0x2A+0x2B)
-- print(0x46+0x46+0x46+0x10+0x0f+0x0f)
printhex("seed2", read32(0x2385F0C + 4));
printhex("seed1", read32(0x2385F0C));
memory.registerexec(0x0208aca8, function()
  
  -- printhex("a",table1[counter2])
  -- regw("r0", table1[counter2])
  -- counter2 = counter2 + 1
  -- return 0;

  
  -- print("hit")
  print(string.format("r0: %#.8x", memory.getregister("r0")))
  print(string.format("r5: %#.8x", memory.getregister("r5")))
   --print(string.format("r5: %#.8x", read8(reg("r5"))))

  --regw("r0", 255-17) 239-255: amaiiki
  --regw("r0", 213) -- 212-239
  --regw("r0", 211) -- 212-211
  --regw("r0", 1)

  --regw("r0", 0x44-10)
  --regw("r0", 0x44+0x3A-10)
  --regw("r0", 0x44+0x3A+0x30-10)
  --regw("r0", 0x44+0x3A+0x30+0x26-10)
  --regw("r0", 0x44+0x3A+0x30+0x26+0x1B-10)
  --regw("r0", 0x44+0x3A+0x30+0x26+0x1B+0x11-1) -- 212-211


  --regw("r0", 0x46-5)
  --regw("r0", 0x46+0x46-5)
  --regw("r0", 0x46+0x46+0x46-5)
  --regw("r0", 0x46+0x46+0x46+0x10-5)
  --regw("r0", 0x46+0x46+0x46+0x10+0x0f-5)
  --regw("r0", 0x46+0x46+0x46+0x10+0x0f+0x0f-1)

  --regw("r0", 0x2B-10)
  --regw("r0", 0x2B+0x2A-10)
  --regw("r0", 0x2B+0x2A+0x2B-10)
  --regw("r0", 0x2B+0x2A+0x2B+0x2B-10)
  --regw("r0", 0x2B+0x2A+0x2B+0x2B+0x2A-10)
  --regw("r0", 0x2B+0x2A+0x2B+0x2B+0x2A+0x2B-1)
end)



memory.registerexec(0x0208ac90, function()
  printhex("actions", reg("r7") + 0x18)
  printhex("actions ptr", reg("r0") + 0x148)
end)



-- みとれ
memory.registerexec(0x021588f8, function()
  printhex("mitore: ", reg("r9"))
end)

-- kannsuu!!!!! mmahi,yasumi
memory.registerexec(0x02158258, function()
  --regw("r1", 0)
  print(string.format("r0: %#.8x", reg("r0")))
  -- --print(string.format("r1: %#.8x", memory.getregister("r1")))
 
--   --mezapani
--   if reg("r0") == 0x19 then
--     regw("r1", 25-1)
--   end

--   --otakebi
--   if reg("r0") == 0x2d then
--     regw("r1", 45)
--   end

--   --manu-sa
--  if reg("r0") == 0x3e then
--   regw("r1", 62)
--  end

--  --zuo, rukanann
--  if reg("r0") == 0x4b then
--   regw("r1", 0x4b)
--  end
--  --toppuu, pahupahu
--  if reg("r0") == 0x32 then
--   regw("r1", 0x31)
--  end

--  -- monnsuta-
--  if reg("r0") == 0x25 then
--     regw("r1", 36)
--  end
-- if reg("r0") == 0x4f then
--  regw("r1", 0x4f-1)
-- end
--amaiiki
--  if reg("r0") == 0x19 then
--   regw("r1", 24)
--  end
end)

memory.registerexec(0x021587bc, function()
  print("mikawasi", reg("r0"))
  --regw("r4", 0)
end)
memory.registerexec(0x02158258, function()
  print("kaihi", reg("r0"))
  --regw("r1", 0)
end)
memory.registerexec(0x02158700, function()
  printhex("shield(float)", reg("r4"))
  --regw("r0", 0)
end)



memory.registerexec(0x02158590, function()
  --print(reg("r0"))
    print("kaisin: 10000/".. reg("r0"))
    --regw("r4", 0)
end)

-- memory.registerexec(0x0208b210, function()
--     printhex("AI", reg("r14"))
-- end)

-- memory.registerexec(0x0208b2a0, function()
--   printhex("(code) AI", reg("r6"))
--   printhex("ret action", reg("r0"))
-- end)

memory.registerexec(0x0208acf0, function()
  if reg("r0") == 0 then
    print("isCanActionTaken: changed")
  else
    print("isCanActionTaken: no changed")
  end
end)

memory.registerexec(0x021e81a0, function()
  --print(reg("r0"))
    print("0damage, 021e81a0: ".. reg("r0"))
    --regw("r4", 0)
end)


memory.registerexec(0x021e3a18, function()
  --print(reg("r0"))
    print("doku, 021e3a18: 100/".. reg("r1"))
    --regw("r4", 0)
end)


memory.registerexec(0x02158ad0, function()
  --print(reg("r0"))
    print("doku, 02158ad0: 100/".. reg("r0"))
    --regw("r4", 0)
end)
