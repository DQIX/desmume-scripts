local addr = {
    camMatrix  = 0x0210A05C,
    projMatrix = 0x0210A018,
    mc         = 0x022BBBDC,
    battleFlag = 0x022A44C6
}

local monSlots = {
    0x022F0C30,
    0x022F0DC8,
    0x022F0F60,
    0x022F10F8,
    0x022F1290,
    0x022F1428,
    0x022F15C0,
    0x022F1758,
    0x022F18F0,
    0x022F1A88,
    0x022F1C20,
    0x022F1DB8
}

local monDist = {}

local scale = 4096
local screenW, screenH = 256, 192

local function getHex(decimal, digits)
   return string.format("%0"..digits.."X", decimal)
end

local function readCameraMatrix()
    local m = {}
    for i = 0, 11 do
        m[i + 1] = memory.readdwordsigned(addr.camMatrix + i * 4) / scale
    end
    return m
end

local function readProjMatrix()
    local m = {}
    for i = 0, 15 do
        m[i + 1] = memory.readdwordsigned(addr.projMatrix + i * 4) / scale
    end
    return m
end

local function matMul3x4(x, y, z, m)
    return
        x * m[1] + y * m[4] + z * m[7]  + m[10],
        x * m[2] + y * m[5] + z * m[8]  + m[11],
        x * m[3] + y * m[6] + z * m[9]  + m[12]
end

local function project4x4(x, y, z, m)
    local cx = x*m[1] + y*m[5] + z*m[9]  + m[13]
    local cy = x*m[2] + y*m[6] + z*m[10] + m[14]
    local cz = x*m[3] + y*m[7] + z*m[11] + m[15]
    local cw = x*m[4] + y*m[8] + z*m[12] + m[16]

    if cw <= 0 then return nil end

    local nx = cx / cw
    local ny = cy / cw

    local sx = (nx * 0.5 + 0.5) * screenW
    local sy = (1 - (ny * 0.5 + 0.5)) * screenH

    return sx, sy
end

local function isOnScreen(x, y)
    return x >= 0 and x < screenW and y >= 0 and y < screenH
end

local function isOnBottomScreen(sx, sy)
    return sy >= 2 and sy < screenH
end

local function clipLineToBottomScreen(x1, y1, x2, y2)
    local minY = 0
    local maxY = screenH - 1

    -- both completely outside
    if (y1 < minY and y2 < minY) or (y1 > maxY and y2 > maxY) then
        return nil
    end

    -- clip first point
    if y1 < minY then
        local t = (minY - y1) / (y2 - y1)
        x1 = x1 + t * (x2 - x1)
        y1 = minY
    elseif y1 > maxY then
        local t = (maxY - y1) / (y2 - y1)
        x1 = x1 + t * (x2 - x1)
        y1 = maxY
    end

    -- clip second point
    if y2 < minY then
        local t = (minY - y1) / (y2 - y1)
        x2 = x1 + t * (x2 - x1)
        y2 = minY
    elseif y2 > maxY then
        local t = (maxY - y1) / (y2 - y1)
        x2 = x1 + t * (x2 - x1)
        y2 = maxY
    end

    return x1, y1, x2, y2
end

local function drawWorldLine(x1,y1,z1, x2,y2,z2, cam, proj, color)
    local rx1, ry1, rz1 = matMul3x4(x1,y1,z1, cam)
    local sx1, sy1 = project4x4(rx1, ry1, rz1, proj)

    local rx2, ry2, rz2 = matMul3x4(x2,y2,z2, cam)
    local sx2, sy2 = project4x4(rx2, ry2, rz2, proj)

    if not sx1 or not sx2 then return end

    if isOnScreen(sx1, sy1) or isOnScreen(sx2, sy2) then
        gui.line(sx1, sy1, sx2, sy2, color)
    end
end

local function toSigned32(n)
    if n >= 0x80000000 then
        return n - 0x100000000
    end
    return n
end

local function fx32(n)
    return toSigned32(n) / scale
end

local function readVec3(base)
    local x = fx32(memory.readdword(base + 0x44))
    local y = fx32(memory.readdword(base + 0x48))
    local z = fx32(memory.readdword(base + 0x4C))
    return x, y, z
end

local function readRadius(base)
    return fx32(memory.readdword(base + 0x64)) / 2
end

local function drawWorldCircle(cx, cy, cz, r, cam, proj, color)
    local segments = 16
    local step = (math.pi * 2) / segments

    local prevX, prevY, prevZ

    for i = 0, segments do
        local angle = i * step
        local x = cx + math.cos(angle) * r
        local z = cz + math.sin(angle) * r
        local y = cy

        if prevX then
            drawWorldLine(prevX, prevY, prevZ, x, y, z, cam, proj, color)
        end

        prevX, prevY, prevZ = x, y, z
    end
end

local function drawWorldCross(wx, wy, wz, size, camMatrix, projMatrix, colour)
    -- horizontal line (X axis)
    do
        local x1, y1, z1 = wx - size, wy, wz
        local x2, y2, z2 = wx + size, wy, wz

        local rx1, ry1, rz1 = matMul3x4(x1, y1, z1, camMatrix)
        local sx1, sy1 = project4x4(rx1, ry1, rz1, projMatrix)

        local rx2, ry2, rz2 = matMul3x4(x2, y2, z2, camMatrix)
        local sx2, sy2 = project4x4(rx2, ry2, rz2, projMatrix)

        if sx1 and sy1 and sx2 and sy2 then
            if (isOnBottomScreen(sx1, sy1) or isOnBottomScreen(sx2, sy2)) then
                local cx1, cy1, cx2, cy2 = clipLineToBottomScreen(sx1, sy1, sx2, sy2)
                if cx1 then
                    gui.line(cx1, cy1, cx2, cy2, colour)
                end
            end
        end
    end

    -- vertical line (Z axis)
    do
        local x1, y1, z1 = wx, wy, wz - size
        local x2, y2, z2 = wx, wy, wz + size

        local rx1, ry1, rz1 = matMul3x4(x1, y1, z1, camMatrix)
        local sx1, sy1 = project4x4(rx1, ry1, rz1, projMatrix)

        local rx2, ry2, rz2 = matMul3x4(x2, y2, z2, camMatrix)
        local sx2, sy2 = project4x4(rx2, ry2, rz2, projMatrix)

        if sx1 and sy1 and sx2 and sy2 then
            if (isOnBottomScreen(sx1, sy1) or isOnBottomScreen(sx2, sy2)) then
                local cx1, cy1, cx2, cy2 = clipLineToBottomScreen(sx1, sy1, sx2, sy2)
                if cx1 then
                    gui.line(cx1, cy1, cx2, cy2, colour)
                end
            end
        end
    end
end


memory.registerexec(0x02197044, function()
    local r7 = memory.getregister("r7")
    if r7 == addr.mc then
        local r6 = memory.getregister("r6")
        local r4 = memory.getregister("r4")
        for i, base in ipairs(monSlots) do
            if r6 == base then
                monDist[i] = r4 / scale
                break
            end
        end
    end
end)

local function main()
    local cam = readCameraMatrix()
    local proj = readProjMatrix()

    local inBattle = memory.readbyte(addr.battleFlag)
    if inBattle == 0 then
        local px, py, pz = readVec3(addr.mc)
        local pr = readRadius(addr.mc)
        drawWorldCross(px, py, pz, 0.25, cam, proj, "cyan")

        for i, base in ipairs(monSlots) do
            local x, y, z = readVec3(base)
            local r = monDist[i]
            local r2 = readRadius(base)

            if r then
                drawWorldCircle(x, y, z, r, cam, proj, "red")
            end
        end
    end
end

gui.register(main)
