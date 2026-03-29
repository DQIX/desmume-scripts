-- TKG

local addr = {
    p1Coords = 0x022BBC20,
    p2Coords = 0x022CD2E0,
    p3Coords = 0x022DE9A0,
    p4Coords = 0x022F0060,
    tilt = 0x027E38B0,
    zoom = 0x027E38B4,
    coolup = 0x020FDD4C,
    camMatrix = 0x0210A05C,
    projMatrix = 0x0210A018,
    basePointer = 0x020FDD60,
    endPointer  = 0x020FDD64,
    battleFlag = 0x022A44C6,
}

local partyAddrs = {
    addr.p1Coords,
    addr.p2Coords,
    addr.p3Coords,
    addr.p4Coords
}

local nodeScores = {}
local nodeScoresStable = {}

local prevR10 = nil

-- FUN_02074f88 (JPN) = FUN_02073dfc (USA)
-- 0x0207502c (JPN) = 0x2073ea0 (USA)

local instr =  0x02073ea0 -- cmp r0,#0x3800
local instr2 = 0x02073984 -- cmp r0,#0x0
local r0 = 0

local scale = 4096

local screenW, screenH = 256, 192
local centerX, centerY = screenW / 2, screenH / 2

local nodeRadius = 3.5

local tiltCustom  = 0x00037000
local zoomCustom  = 0x00038000
local coolupCustom = 0x0000FFFF

local prevStart = false
local showGrid = true
local prevAB = false

local function getHex(decimal, digits)
   return string.format("%0"..digits.."X", decimal)
end

local function copyTable(t)
    local new = {}
    for k, v in pairs(t) do
        new[k] = v
    end
    return new
end

local function getRange()
   r0 = memory.getregister("r0")
end

local function toSigned32(n)
    if n >= 0x80000000 then
        return n - 0x100000000
    end
    return n
end

local function getScore()
    local sp = memory.getregister("r13")
    local r10 = memory.getregister("r10")
    local finalScore = memory.getregister("r0")

    if prevR10 and r10 < prevR10 then
        nodeScoresStable = copyTable(nodeScores)
        nodeScores = {}
    end

    prevR10 = r10

    local candidateBase = sp + 0x60
    local nodePtr = memory.readdword(candidateBase + r10 * 4)

    if nodePtr ~= 0 then
        nodeScores[nodePtr] = finalScore
    end
end

local function getPartyCoords(baseAddr)
    if baseAddr == 0 or baseAddr == nil then return nil end

    local x = memory.readdwordsigned(baseAddr + 0) / scale
    local y = memory.readdwordsigned(baseAddr + 4) / scale
    local z = memory.readdwordsigned(baseAddr + 8) / scale

    return x, y, z
end

-- Read camera matrix (3x4)
local function readCameraMatrix()
    local m = {}
    for i = 0, 11 do
        m[i + 1] = memory.readdwordsigned(addr.camMatrix + i * 4) / scale
    end
    return m
end

-- Read projection matrix (4x4)
local function readProjMatrix()
    local m = {}
    for i = 0, 15 do
        m[i + 1] = memory.readdwordsigned(addr.projMatrix + i * 4) / scale
    end
    return m
end

-- 3x4 view transform
local function matMul3x4(x, y, z, m)
    return
        x * m[1] + y * m[4] + z * m[7]  + m[10],
        x * m[2] + y * m[5] + z * m[8]  + m[11],
        x * m[3] + y * m[6] + z * m[9]  + m[12]
end

-- 4x4 projection
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

local function drawWorldTextRaw(wx, wy, wz, text, camMatrix, projMatrix, colour)
    local rx, ry, rz = matMul3x4(wx, wy, wz, camMatrix)
    local sx, sy = project4x4(rx, ry, rz, projMatrix)

    if not sx or not sy then return end

    -- match behavior of circles/crosses
    if not isOnBottomScreen(sx, sy) then return end

    gui.text(sx - 12, sy, text, colour, "#00000040")
end

local function drawWorldTextClamped(wx, wy, wz, text, camMatrix, projMatrix, colour)
    local rx, ry, rz = matMul3x4(wx, wy, wz, camMatrix)
    local sx, sy = project4x4(rx, ry, rz, projMatrix)

    if not sx or not sy then return end

    -- text box size (approx)
    local paddingX = 12
    local paddingY = 0

    local minX = 2
    local maxX = screenW - 40   -- prevent overflow (adjust if needed)
    local minY = 2
    local maxY = screenH - 10

    -- clamp to screen
    local clampedX = math.max(minX, math.min(maxX, sx - paddingX))
    local clampedY = math.max(minY, math.min(maxY, sy + paddingY))

    gui.text(clampedX, clampedY, text, colour, "#00000040")
end

local function drawWorldCircle(wx, wy, wz, radius, camMatrix, projMatrix, colour)
    local segments = 24

    local prevSX, prevSY = nil, nil

    for i = 0, segments do
        local angle = (i / segments) * (math.pi * 2)

        local x = wx + math.cos(angle) * radius
        local z = wz + math.sin(angle) * radius
        local y = wy -- stay on ground plane

        local rx, ry, rz = matMul3x4(x, y, z, camMatrix)
        local sx, sy = project4x4(rx, ry, rz, projMatrix)

        if sx and sy then
            if prevSX and prevSY then
                if isOnBottomScreen(prevSX, prevSY) or isOnBottomScreen(sx, sy) then
                    gui.line(prevSX, prevSY, sx, sy, colour)
                end
            end
            prevSX, prevSY = sx, sy
        else
            prevSX, prevSY = nil, nil
        end
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

local function getBestNode()
    local bestPtr = nil
    local bestScore = nil

    for ptr, score in pairs(nodeScoresStable) do
        local signed = toSigned32(score)

        if signed > 0 then
            if not bestScore or signed > bestScore then
                bestScore = signed
                bestPtr = ptr
            end
        end
    end

    return bestPtr, bestScore
end

local function drawNodes(camMatrix, projMatrix, px, py, pz)
    local bestPtr, bestScore = getBestNode()
    local base = memory.readdwordsigned(addr.basePointer)
    local ending = memory.readdwordsigned(addr.endPointer)
    if not base or not ending then return end

    local nodeCount = (ending - base) / 0x10

    for i = 0, nodeCount - 1 do
        local nx = bit.lshift(memory.readwordsigned(base + i * 0x10 + 4), 0xC) / scale
        local ny = bit.lshift(memory.readwordsigned(base + i * 0x10 + 6), 0xC) / scale
        local nz = bit.lshift(memory.readwordsigned(base + i * 0x10 + 8), 0xC) / scale

        local rx, ry, rz = matMul3x4(nx, ny, nz, camMatrix)
        local sx, sy = project4x4(rx, ry, rz, projMatrix)

        if sx and sy then
            local nodePtr = base + i * 0x10

            local colour = "yellow"

            if nodePtr == bestPtr then
                colour = "green"
            end

            local score = nodeScoresStable[nodePtr]

            if score then
                local scoreSigned = toSigned32(score)
                if scoreSigned < 0 then colour = "red" end
                scoreStr = string.format("%.2f", scoreSigned / scale)
                drawWorldTextRaw(nx, ny, nz, scoreStr, camMatrix, projMatrix, colour)
            end

            --if nodePtr == entity2 or nodePtr == entity1 then
                --colour = "green"
            --end

            drawWorldCircle(nx, ny, nz, nodeRadius, camMatrix, projMatrix, colour)
            --drawWorldCross(nx, ny, nz, 0.25, camMatrix, projMatrix, colour)

            
        end
    end
end

local function drawGrid(px, py, pz, camMatrix, projMatrix)
    local gridRadius = 30
    local yLevel = py

    local startX = math.floor(px) - gridRadius
    local endX   = math.floor(px) + gridRadius
    local startZ = math.floor(pz) - gridRadius
    local endZ   = math.floor(pz) + gridRadius

    local TILE = 8
    local HALF = TILE / 2

    local function isMajor(v)
        return ((v - HALF) % TILE) == 0
    end

    -- Draw lines parallel to Z (vary X)
    for x = startX, endX do
        local prevSX, prevSY = nil, nil

        for z = startZ, endZ do
            local wx = x
            local wy = yLevel
            local wz = z

            local rx, ry, rz = matMul3x4(wx, wy, wz, camMatrix)
            local sx, sy = project4x4(rx, ry, rz, projMatrix)

            if sx and sy then
                local onScreen = true

                if prevSX and prevSY then
                    local prevOnScreen = (prevSY >= 0 and prevSY < screenH)

                    if (prevSY >= 0 and prevSY < screenH) or (sy >= 0 and sy < screenH) then
                        local cx1, cy1, cx2, cy2 = clipLineToBottomScreen(prevSX, prevSY, sx, sy)
                        if cx1 then
                            local colour = "#88888860"

                            if isMajor(x) then
                                colour = "#FFFFFFA0"
                            end

                            gui.line(cx1, cy1, cx2, cy2, colour)
                        end
                    end
                end

                if onScreen then
                    prevSX, prevSY = sx, sy
                else
                    prevSX, prevSY = nil, nil
                end
            else
                prevSX, prevSY = nil, nil
            end
        end
    end

    -- Draw lines parallel to X (vary Z)
    for z = startZ, endZ do
        local prevSX, prevSY = nil, nil

        for x = startX, endX do
            local wx = x
            local wy = yLevel
            local wz = z

            local rx, ry, rz = matMul3x4(wx, wy, wz, camMatrix)
            local sx, sy = project4x4(rx, ry, rz, projMatrix)

            if sx and sy then
                local onScreen = (sy < screenH)

                if prevSX and prevSY then
                    local prevOnScreen = (prevSY >= 0 and prevSY < screenH)

                    if (prevSY >= 0 and prevSY < screenH) or (sy >= 0 and sy < screenH) then
                        local cx1, cy1, cx2, cy2 = clipLineToBottomScreen(prevSX, prevSY, sx, sy)
                        if cx1 then
                            local colour = "#88888860"

                            if isMajor(z) then
                                colour = "#FFFFFFA0"
                            end

                            gui.line(cx1, cy1, cx2, cy2, colour)
                        end
                    end
                end

                if onScreen then
                    prevSX, prevSY = sx, sy
                else
                    prevSX, prevSY = nil, nil
                end
            else
                prevSX, prevSY = nil, nil
            end
        end
    end
end

local function main()
    local input = joypad.get(1)

    local AB = input.A and input.B
    if AB and not prevAB then
        showGrid = not showGrid
    end
    prevAB = AB

    if input.start and not prevStart then
        memory.writedword(addr.tilt, tiltCustom)
        memory.writedword(addr.zoom, zoomCustom)
    end
    prevStart = input.start

    local px = memory.readdwordsigned(addr.p1Coords + 0) / scale
    local py = memory.readdwordsigned(addr.p1Coords + 4) / scale
    local pz = memory.readdwordsigned(addr.p1Coords + 8) / scale

    local dist = r0 / scale
    local distStr = string.format("%6.2f", dist)

    local camMatrix = readCameraMatrix()
    local projMatrix = readProjMatrix()

    local inBattle = memory.readbyte(addr.battleFlag)
    if inBattle == 0 then
        if showGrid then
            drawGrid(px, py, pz, camMatrix, projMatrix)
        end
        drawNodes(camMatrix, projMatrix, px, py, pz)
        for i = 1, 1 do
            local px, py, pz = getPartyCoords(partyAddrs[i])
            if px then
                drawWorldCircle(px, py, pz, dist, camMatrix, projMatrix, "cyan")
                drawWorldCross(px, py, pz, 0.25, camMatrix, projMatrix, "cyan")
            end
        end       
        drawWorldTextClamped(px - 0.8, py, pz - dist + 0.5, distStr .. "m", camMatrix, projMatrix, "cyan")
    end
end

memory.registerexec(instr2, getScore)
memory.registerexec(instr, getRange)
gui.register(main)
