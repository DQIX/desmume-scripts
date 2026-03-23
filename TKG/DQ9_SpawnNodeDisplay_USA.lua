-- TKG

local addr = {
    playerX = 0x022BBC20,
    playerY = 0x022BBC24,
    playerZ = 0x022BBC28,
    tilt = 0x027E38B0,
    zoom = 0x027E38B4,
    coolup = 0x020FDD4C,
    camMatrix = 0x0210A05C,
    projMatrix = 0x0210A018,
    basePointer = 0x020FDD60,
    endPointer  = 0x020FDD64,
    battleFlag = 0x022A44C6,
}

local scale = 4096

local screenW, screenH = 256, 192
local centerX, centerY = screenW / 2, screenH / 2

local nodeRadius = 3

local tiltCustom  = 0x00020000
local zoomCustom  = 0x00030000
local coolupCustom = 0x0000FFFF

local prevStart = false
local showGrid = false
local prevAB = false

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

    if cw == 0 then return nil end

    local nx = cx / cw
    local ny = cy / cw

    local sx = (nx * 0.5 + 0.5) * screenW
    local sy = (1 - (ny * 0.5 + 0.5)) * screenH

    return sx, sy
end

local function drawSolidCircle(cx, cy, radius, colour)
    for dx = -radius, radius do
        for dy = -radius, radius do
            if dx*dx + dy*dy <= radius*radius then
                gui.pixel(cx + dx, cy + dy, colour)
            end
        end
    end
end

local function drawNodes(camMatrix, projMatrix, px, py, pz)
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
            if sx >= 0 and sx < screenW and sy >= nodeRadius and sy < screenH then
                drawSolidCircle(math.floor(sx), math.floor(sy), nodeRadius, "#CC0000")
            end
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
                local onScreen = (sx >= 0 and sx < screenW and sy >= 0 and sy < screenH)

                if prevSX and prevSY then
                    local prevOnScreen = (prevSX >= 0 and prevSX < screenW and prevSY >= 0 and prevSY < screenH)

                    if onScreen and prevOnScreen then
                        local colour = "#88888860"

                        if isMajor(x) then
                            colour = "#FFFFFFA0"
                        end

                        gui.line(prevSX, prevSY, sx, sy, colour)
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
                local onScreen = (sx >= 0 and sx < screenW and sy >= 0 and sy < screenH)

                if prevSX and prevSY then
                    local prevOnScreen = (prevSX >= 0 and prevSX < screenW and prevSY >= 0 and prevSY < screenH)

                    if onScreen and prevOnScreen then
                        local colour = "#88888860"

                        if isMajor(z) then
                            colour = "#FFFFFFA0"
                        end

                        gui.line(prevSX, prevSY, sx, sy, colour)
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
-- Poke addresses
--memory.writedword(addr.coolup, coolupCustom)

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

    local px = memory.readdwordsigned(addr.playerX) / scale
    local py = memory.readdwordsigned(addr.playerY) / scale
    local pz = memory.readdwordsigned(addr.playerZ) / scale

    local camMatrix = readCameraMatrix()
    local projMatrix = readProjMatrix()

    local inBattle = memory.readbyte(addr.battleFlag)
    if inBattle == 0 then
        if showGrid then
            drawGrid(px, py, pz, camMatrix, projMatrix)
        end
        drawNodes(camMatrix, projMatrix, px, py, pz)
    end
end

gui.register(main)
