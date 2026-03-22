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
    direction = 0x022BBC8A
}

local scale = 4096

local screenW, screenH = 256, 192
local centerX, centerY = screenW / 2, screenH / 2

local nodeRadius = 3

local radiusInner = 0x3800
local radiusMiddle = 0x5000
local radiusOuter = 0xA000

local tiltDefault = 0x00007999
local tiltCustom  = 0x00020000
local zoomDefault = 0x0000E000
local zoomCustom  = 0x00030000
local coolupCustom = 0x0000FFFF

local showWorldCircles = true
local prevAB = false
local prevStart = false

local function internalToTiles(v)
    return (v * 2) / scale
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

    if cw == 0 then return nil end

    local nx = cx / cw
    local ny = cy / cw

    local sx = (nx * 0.5 + 0.5) * screenW
    local sy = (1 - (ny * 0.5 + 0.5)) * screenH

    return sx, sy
end

local function drawSolidCircle(cx, cy, radius)
    for dx = -radius, radius do
        for dy = -radius, radius do
            if dx*dx + dy*dy <= radius*radius then
                gui.pixel(cx + dx, cy + dy, "#FF0000b0")
            end
        end
    end
end

local function drawNodes(camMatrix, projMatrix)
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
            if sx >= 0 and sx < screenW and sy >= 0 and sy < screenH then
                drawSolidCircle(math.floor(sx), math.floor(sy), nodeRadius)
            end
        end
    end
end

local function getFacingRadians()
    local raw = memory.readwordunsigned(addr.direction)
    return (raw / 0x6488) * (math.pi * 2)
end

local function rotateY(x, z, angle)
    local cosA = math.cos(angle)
    local sinA = math.sin(angle)
    return
        x * cosA - z * sinA,
        x * sinA + z * cosA
end

local function drawWorldCircle(px, py, pz, radius, camMatrix, projMatrix, color, axis, facing)
    local segments = 128
    local prevSX, prevSY = nil, nil

    local cosF = math.cos(facing)
    local sinF = math.sin(facing)

    for i = 0, segments do
        local angle = (i / segments) * (math.pi * 2)

        local lx, ly, lz = 0, 0, 0

        if axis == "XZ" then
            lx = math.cos(angle) * radius / scale
            lz = math.sin(angle) * radius / scale

        elseif axis == "XY" then
            lx = math.cos(angle) * radius / scale
            ly = math.sin(angle) * radius / scale

        elseif axis == "YZ" then
            ly = math.cos(angle) * radius / scale
            lz = math.sin(angle) * radius / scale
        end

        local wx = lx * cosF - lz * sinF
        local wz = lx * sinF + lz * cosF
        local wy = ly

        wx = px + wx
        wy = py + wy
        wz = pz + wz

        local rx, ry, rz = matMul3x4(wx, wy, wz, camMatrix)
        local sx, sy = project4x4(rx, ry, rz, projMatrix)

        if sx and sy then
            local onScreen = (sx >= 0 and sx < screenW and sy >= 0 and sy < screenH)

            if prevSX and prevSY then
                local prevOnScreen = (prevSX >= 0 and prevSX < screenW and prevSY >= 0 and prevSY < screenH)

                if onScreen and prevOnScreen then
                    gui.line(prevSX, prevSY, sx, sy, color)
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

local function main()
-- Poke addresses
--memory.writedword(addr.coolup, coolupCustom)

    local input = joypad.get(1)

    if input.start and not prevStart then
        memory.writedword(addr.tilt, tiltCustom)
        memory.writedword(addr.zoom, zoomCustom)
    end

    prevStart = input.start

    local ABPressed = input.A and input.B

    if ABPressed and not prevAB then
        showWorldCircles = not showWorldCircles
    end

    prevAB = ABPressed

    local px = memory.readdwordsigned(addr.playerX) / scale
    local py = memory.readdwordsigned(addr.playerY) / scale
    local pz = memory.readdwordsigned(addr.playerZ) / scale

    local camMatrix = readCameraMatrix()
    local projMatrix = readProjMatrix()

    local inBattle = memory.readbyte(addr.battleFlag)
    if inBattle == 0 then
        drawNodes(camMatrix, projMatrix)
        if showWorldCircles then
            local facing = getFacingRadians()
            facing = -facing

            -- Inner
            drawWorldCircle(px, py, pz, radiusInner, camMatrix, projMatrix, "green", "XZ", facing)
            drawWorldCircle(px, py, pz, radiusInner, camMatrix, projMatrix, "blue", "XY", facing)
            drawWorldCircle(px, py, pz, radiusInner, camMatrix, projMatrix, "red", "YZ", facing)

            -- Middle
            drawWorldCircle(px, py, pz, radiusMiddle, camMatrix, projMatrix, "green", "XZ", facing)
            drawWorldCircle(px, py, pz, radiusMiddle, camMatrix, projMatrix, "blue", "XY", facing)
            drawWorldCircle(px, py, pz, radiusMiddle, camMatrix, projMatrix, "red", "YZ", facing)

            -- Outer
            drawWorldCircle(px, py, pz, radiusOuter, camMatrix, projMatrix, "green", "XZ", facing)
            drawWorldCircle(px, py, pz, radiusOuter, camMatrix, projMatrix, "blue", "XY", facing)
            drawWorldCircle(px, py, pz, radiusOuter, camMatrix, projMatrix, "red", "YZ", facing)
        end
    end
end

gui.register(main)
