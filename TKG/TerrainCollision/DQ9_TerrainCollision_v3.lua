local addr = {
    camMatrix  = 0x0210A05C,
    projMatrix = 0x0210A018,
    mc         = 0x022BBBDC,
    battleFlag = 0x022A44C6
}

local objects = {}

local triBase = 0
local triCount = 0
local objectIndex = 1
local scale = 4096
local screenW, screenH = 256, 192

local function getHex(decimal, digits)
   return string.format("%0"..digits.."X", decimal)
end

local function readMatrix(base, count)
    local m = {}
    for i = 0, count - 1 do
        m[i + 1] = memory.readdwordsigned(base + i * 4) / scale
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

local function clipLineToScreen(x1, y1, x2, y2)
    local minX, maxX = 0, screenW - 1
    local minY, maxY = 0, screenH - 1

    -- trivial reject
    if (x1 < minX and x2 < minX) or (x1 > maxX and x2 > maxX) or
       (y1 < minY and y2 < minY) or (y1 > maxY and y2 > maxY) then
        return nil
    end

    local dx = x2 - x1
    local dy = y2 - y1

    -- clip X
    if dx ~= 0 then
        if x1 < minX then
            local t = (minX - x1) / dx
            x1 = minX
            y1 = y1 + t * dy
        elseif x1 > maxX then
            local t = (maxX - x1) / dx
            x1 = maxX
            y1 = y1 + t * dy
        end

        if x2 < minX then
            local t = (minX - x2) / dx
            x2 = minX
            y2 = y2 + t * dy
        elseif x2 > maxX then
            local t = (maxX - x2) / dx
            x2 = maxX
            y2 = y2 + t * dy
        end
    end

    -- recompute deltas after X clipping
    dx = x2 - x1
    dy = y2 - y1

    -- clip Y
    if dy ~= 0 then
        if y1 < minY then
            local t = (minY - y1) / dy
            y1 = minY
            x1 = x1 + t * dx
        elseif y1 > maxY then
            local t = (maxY - y1) / dy
            y1 = maxY
            x1 = x1 + t * dx
        end

        if y2 < minY then
            local t = (minY - y2) / dy
            y2 = minY
            x2 = x2 + t * dx
        elseif y2 > maxY then
            local t = (maxY - y2) / dy
            y2 = maxY
            x2 = x2 + t * dx
        end
    end

    return x1, y1, x2, y2
end

local function drawWorldLine(x1,y1,z1, x2,y2,z2, cam, proj, colour)
    local rx1, ry1, rz1 = matMul3x4(x1,y1,z1, cam)
    local sx1, sy1 = project4x4(rx1, ry1, rz1, proj)

    local rx2, ry2, rz2 = matMul3x4(x2,y2,z2, cam)
    local sx2, sy2 = project4x4(rx2, ry2, rz2, proj)

    if not sx1 or not sx2 then return end

    local cx1, cy1, cx2, cy2 = clipLineToScreen(sx1, sy1, sx2, sy2)
    if cx1 then
        gui.line(cx1, cy1, cx2, cy2, colour)
    end
end

local function fx32(n)
    if n >= 0x80000000 then
        n = n - 0x100000000
    end
    return n / scale
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

local function drawWorldCircle(cx, cy, cz, r, cam, proj, colour)
    local segments = 16
    local step = (math.pi * 2) / segments

    local prevX, prevY, prevZ

    for i = 0, segments do
        local angle = i * step
        local x = cx + math.cos(angle) * r
        local z = cz + math.sin(angle) * r
        local y = cy

        if prevX then
            drawWorldLine(prevX, prevY, prevZ, x, y, z, cam, proj, colour)
        end

        prevX, prevY, prevZ = x, y, z
    end
end

local function drawWorldTriangle(v0x,v0y,v0z, v1x,v1y,v1z, v2x,v2y,v2z, cam, proj, colour)
    drawWorldLine(v0x,v0y,v0z, v1x,v1y,v1z, cam, proj, colour)
    drawWorldLine(v1x,v1y,v1z, v2x,v2y,v2z, cam, proj, colour)
    drawWorldLine(v2x,v2y,v2z, v0x,v0y,v0z, cam, proj, colour)
end

local function readTri(addr)
    local function rv(off)
        return fx32(memory.readdword(addr + off)),
               fx32(memory.readdword(addr + off + 4)),
               fx32(memory.readdword(addr + off + 8))
    end

    local v0x,v0y,v0z = rv(0x00)
    local v1x,v1y,v1z = rv(0x0C)
    local v2x,v2y,v2z = rv(0x18)
    local nx,ny,nz    = rv(0x24)

    return v0x,v0y,v0z, v1x,v1y,v1z, v2x,v2y,v2z, nx,ny,nz
end

memory.registerexec(0x020315b8, function()
    triBase = memory.getregister("r0")
    triCount = memory.getregister("r1")
end)

memory.registerexec(0x0203d0b0, function()
    objects = {}
    objectIndex = 1
end)

memory.registerexec(0x020404E4, function()
   local r4 = memory.getregister("r4")

   objects[objectIndex] = {}
   objects[objectIndex][1] = r4 + 0x24
   objects[objectIndex][2] = r4 + 0x28
   objects[objectIndex][3] = r4 + 0x2C
   objectIndex = objectIndex + 1
end)


local function main()
    local inBattle = memory.readbyte(addr.battleFlag)
    if inBattle == 0 then
        local cam = readMatrix(addr.camMatrix, 12)
        local proj = readMatrix(addr.projMatrix, 16)

        local px, py, pz = readVec3(addr.mc)
        local pr = readRadius(addr.mc)
        drawWorldCircle(px, py, pz, pr, cam, proj, "cyan")

        for i = 1, #objects do
            local objx = memory.readdwordsigned(objects[i][1]) / scale
            local objy = memory.readdwordsigned(objects[i][2]) / scale
            local objz = memory.readdwordsigned(objects[i][3]) / scale
            --drawWorldCircle(objx, objy, objz, 0.5, cam, proj, "cyan")
        end

        if triBase ~= 0 then
            for i = 0, triCount - 1 do
                local triAddr = triBase + i * 0x30

                local v0x,v0y,v0z,
                      v1x,v1y,v1z,
                      v2x,v2y,v2z,
                      nx,ny,nz = readTri(triAddr)

                local isWall = math.abs(ny) < 0.3
                local colour = isWall and "red" or "white"

                drawWorldTriangle(
                    v0x,v0y,v0z,
                    v1x,v1y,v1z,
                    v2x,v2y,v2z,
                    cam, proj,
                    colour
                )
            end
        end
    end
end

gui.register(main)
