local rankMin = {2, 56, 61, 76, 81, 101, 121, 141, 161, 181, 201, 221}
local rankMax = {55, 60, 75, 80, 100, 120, 140, 160, 180, 200, 220, 248}

local rank, seed

local function getRank(quality)
    for i = 1, #rankMin do
        if quality >= rankMin[i] and quality <= rankMax[i] then
            return rankMin[i]
        end
    end
    return 2 -- default to rank 02
end

local function updateLink()
    if rank and seed then
        local link = string.format("https://www.yabd.org/apps/dq9/grottodetails.php?map=%02X%04X", rank, seed)
        local file = io.open("dq9mapoutput.txt", "w")
        if file then
            file:write(link)
            file:close()
        end
        print(link)
    end
end

memory.registerexec(0x020a5ec8, function()
   local FQ = memory.getregister("r0")
   rank = getRank(FQ)
end)

memory.registerexec(0x020a5ee4, function()
   seed = memory.getregister("r1")
   updateLink()
end)
