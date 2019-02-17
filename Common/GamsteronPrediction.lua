-- RETURN IF LOADED
if _G.GamsteronPredictionLoaded then return end
_G.GamsteronPredictionLoaded = true

-- REQUIRE CORE
if not _G.FileExist(COMMON_PATH .. "GamsteronCore.lua") then
    _G.DownloadFileAsync("https://raw.githubusercontent.com/gamsteron/GOS-External/master/Common/GamsteronCore.lua", _G.COMMON_PATH .. "GamsteronCore.lua", function() end)
    while not _G.FileExist(_G.COMMON_PATH .. "GamsteronCore.lua") do end
end
require('GamsteronCore')
local Local_Core = _G.GamsteronCore

-- AUTO UPDATER
local UPDATER_Version = 0.145
local UPDATER_ScriptName = "GamsteronPrediction"
local UPDATER_success, UPDATER_version = Local_Core:AutoUpdate({
    version = UPDATER_Version,
    scriptPath = _G.COMMON_PATH .. UPDATER_ScriptName .. ".lua",
    scriptUrl = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Common/" .. UPDATER_ScriptName .. ".lua",
    versionPath = _G.COMMON_PATH .. UPDATER_ScriptName .. ".version",
    versionUrl = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Common/" .. UPDATER_ScriptName .. ".version"
})
if UPDATER_success then _G.print("GamsteronPrediction updated to version " .. UPDATER_version .. ". Please Reload with 2x F6 !"); return end

-- LOCALS
local Menu, Orbwalker, TargetSelector, ObjectManager, Damage, Spells
local Local_MathSqrt = _G.math.sqrt
local Local_MathHuge = _G.math.huge
local Local_MathMax = _G.math.max
local Local_MathMin = _G.math.min
local Local_OsClock = _G.os.clock
local Local_TableInsert = _G.table.insert
local Local_TableRemove = _G.table.remove

-- VARIABLES
local DebugMode = false
local NewPosData = {}
local WaypointData = {}
local VisibleData = {}
local Yasuo = {Wall = nil, Name = nil, Level = 0, CastTime = 0, StartPos = nil}
local IsYasuo = false; Local_Core:OnEnemyHeroLoad(function(hero) if hero.charName == "Yasuo" and hero.team == Local_Core.TEAM_ENEMY then IsYasuo = true end end)

-- MENU
local MaxRangeMulipier = 1
Menu = MenuElement({name = "Gamsteron Prediction", id = UPDATER_ScriptName, type = _G.MENU})
Menu:MenuElement({id = "PredMaxRange", name = "Pred Max Range %", value = 100, min = 70, max = 100, step = 1, callback = function(value) MaxRangeMulipier = value * 0.01 end})
Menu:MenuElement({name = "Version " .. tostring(UPDATER_Version), type = _G.SPACE, id = "Version"})
MaxRangeMulipier = Menu.PredMaxRange:Value() * 0.01

-- MATH
local function GetDistance(vec1, vec2)
    if DebugMode then
        assert(vec1, "vec1 nil")
        assert(vec2, "vec2 nil")
    end
    local dx = (vec1.x - vec2.x)
    local dy = ((vec1.z or vec1.y) - (vec2.z or vec2.y))
    return Local_MathSqrt(dx * dx + dy * dy)
end

local function GetDistanceSquared(vec1, vec2)
    if DebugMode then
        assert(vec1, "vec1 nil")
        assert(vec2, "vec2 nil")
    end
    local dx = (vec1.x - vec2.x)
    local dy = ((vec1.z or vec1.y) - (vec2.z or vec2.y))
    return dx * dx + dy * dy
end

local function IsInRange(vec1, vec2, range)
    if DebugMode then
        assert(vec1, "vec1 nil")
        assert(vec2, "vec2 nil")
        assert(range, "range nil")
    end
    local dx = (vec1.x - vec2.x)
    local dy = ((vec1.z or vec1.y) - (vec2.z or vec2.y))
    return dx * dx + dy * dy <= range * range
end

local function Normalized(vec1, vec2)
    if DebugMode then
        assert(vec1, "vec1 nil")
        assert(vec2, "vec2 nil")
    end
    local vec = {x = vec1.x - vec2.x, y = (vec1.z or vec1.y) - (vec2.z or vec2.y)}
    local length = Local_MathSqrt(vec.x * vec.x + vec.y * vec.y)
    if length > 0 then
        local inv = 1.0 / length
        return {x = (vec.x * inv), y = (vec.y * inv)}
    end
    return nil
end

local function Extended(vec, dir, range)
    if DebugMode then
        assert(vec, "vec nil")
        assert(range, "range nil")
    end
    vec = {x = vec.x, y = (vec.z or vec.y)}
    if dir == nil then return vec end
    return {x = vec.x + dir.x * range, y = vec.y + dir.y * range}
end

local function Perpendicular(dir)
    if dir == nil then return nil end
    return {x = -dir.y, y = dir.x}
end

local function Intersection(s1, e1, s2, e2)
    if DebugMode then
        assert(s1, "s1 nil")
        assert(e1, "e1 nil")
        assert(s2, "s2 nil")
        assert(e2, "e2 nil")
    end
    local IntersectionResult = {Intersects = false, Point = {x = 0, y = 0}}
    local s1y, e1y, s2y, e2y = (s1.z or s1.y), (e1.z or e1.y), (s2.z or s2.y), (e2.z or e2.y)
    local deltaACy = s1y - s2y
    local deltaDCx = e2.x - s2.x
    local deltaACx = s1.x - s2.x
    local deltaDCy = e2y - s2y
    local deltaBAx = e1.x - s1.x
    local deltaBAy = e1y - s1y
    local denominator = deltaBAx * deltaDCy - deltaBAy * deltaDCx
    local numerator = deltaACy * deltaDCx - deltaACx * deltaDCy
    if denominator == 0 then
        if numerator == 0 then
            if s1.x >= s2.x and s1.x <= e2.x then
                return {Intersects = true, Point = s1}
            end
            if s2.x >= s1.x and s2.x <= e1.x then
                return {Intersects = true, Point = s2}
            end
            return IntersectionResult
        end
        return IntersectionResult
    end
    local r = numerator / denominator
    if r < 0 or r > 1 then
        return IntersectionResult
    end
    local s = (deltaACy * deltaBAx - deltaACx * deltaBAy) / denominator
    if s < 0 or s > 1 then
        return IntersectionResult
    end
    local point =
    {
        x = s1.x + r * deltaBAx,
        y = s1y + r * deltaBAy
    }
    return {Intersects = true, Point = point}
end

local function VectorMovementCollision(startPoint1, endPoint1, v1, startPoint2, v2, delay)
    if DebugMode then
        assert(startPoint1, "startPoint1 nil")
        assert(endPoint1, "endPoint1 nil")
        assert(v1, "v1 nil")
        assert(startPoint2, "startPoint2 nil")
        assert(v2, "v2 nil")
        assert(delay, "delay nil")
    end
    local sP1x, sP1y, eP1x, eP1y, sP2x, sP2y = startPoint1.x, startPoint1.z, endPoint1.x, endPoint1.z, startPoint2.x, startPoint2.z
    local d, e = eP1x - sP1x, eP1y - sP1y
    local dist, t1, t2 = Local_MathSqrt(d * d + e * e), nil, nil
    local S, K = dist ~= 0 and v1 * d / dist or 0, dist ~= 0 and v1 * e / dist or 0
    function GetCollisionPoint(t) return t and {x = sP1x + S * t, y = sP1y + K * t} or nil end
    if delay and delay ~= 0 then sP1x, sP1y = sP1x + S * delay, sP1y + K * delay end
    local r, j = sP2x - sP1x, sP2y - sP1y
    local c = r * r + j * j
    if dist > 0 then
        if v1 == Local_MathHuge then
            local t = dist / v1
            t1 = v2 * t >= 0 and t or nil
        elseif v2 == Local_MathHuge then
            t1 = 0
        else
            local a, b = S * S + K * K - v2 * v2, -r * S - j * K
            if a == 0 then
                if b == 0 then
                    t1 = c == 0 and 0 or nil
                else
                    local t = -c / (2 * b)
                    t1 = v2 * t >= 0 and t or nil
                end
            else
                local sqr = b * b - a * c
                if sqr >= 0 then
                    local nom = Local_MathSqrt(sqr)
                    local t = (-nom - b) / a
                    t1 = v2 * t >= 0 and t or nil
                    t = (nom - b) / a
                    t2 = v2 * t >= 0 and t or nil
                end
            end
        end
    elseif dist == 0 then
        t1 = 0
    end
    return t1, GetCollisionPoint(t1), t2, GetCollisionPoint(t2), dist
end

local function ClosestPointOnLineSegment(p, p1, p2)
    if DebugMode then
        assert(p, "p nil")
        assert(p1, "p1 nil")
        assert(p2, "p2 nil")
    end
    --local px,pz,py = p.x, p.z, p.y
    --local ax,az,ay = p1.x, p1.z, p1.y
    --local bx,bz,by = p2.x, p2.z, p2.y
    local px, pz = p.x, (p.z or p.y)
    local ax, az = p1.x, (p1.z or p1.y)
    local bx, bz = p2.x, (p2.z or p2.y)
    local bxax = bx - ax
    local bzaz = bz - az
    --local byay = by - by
    --local t = ((px - ax) * bxax + (pz - az) * bzaz + (py - ay) * byay) / (bxax * bxax + bzaz * bzaz + byay * byay)
    local t = ((px - ax) * bxax + (pz - az) * bzaz) / (bxax * bxax + bzaz * bzaz)
    if t < 0 then
        return p1, false
    end
    if t > 1 then
        return p2, false
    end
    return {x = ax + t * bxax, z = az + t * bzaz}, true
    --return Vector({ x = ax + t * bxax, z = az + t * bzaz, y = ay + t * byay }), true
end

local function GetInterceptionTime(source, startP, endP, unitspeed, spellspeed)
    if DebugMode then
        assert(source, "source nil")
        assert(startP, "startP nil")
        assert(endP, "endP nil")
        assert(unitspeed, "unitspeed nil")
        assert(spellspeed, "spellspeed nil")
    end
    local sx = source.x
    local sy = (source.z or source.y)
    local ux = startP.x
    local uy = (startP.z or startP.y)
    local dx = endP.x - ux
    local dy = (endP.z or endP.y) - uy
    local magnitude = Local_MathSqrt(dx * dx + dy * dy)
    dx = (dx / magnitude) * unitspeed
    dy = (dy / magnitude) * unitspeed
    local a = (dx * dx) + (dy * dy) - (spellspeed * spellspeed)
    local b = 2 * ((ux * dx) + (uy * dy) - (sx * dx) - (sy * dy))
    local c = (ux * ux) + (uy * uy) + (sx * sx) + (sy * sy) - (2 * sx * ux) - (2 * sy * uy)
    local d = (b * b) - (4 * a * c)
    if d > 0 then
        local t1 = (-b + Local_MathSqrt(d)) / (2 * a)
        local t2 = (-b - Local_MathSqrt(d)) / (2 * a)
        return Local_MathMax(t1, t2)
    end
    if d == 0 then
        return - b / (2 * a)
    end
    return 0
end

-- YASUO
local function IsYasuoWall()
    if not IsYasuo or Yasuo.Wall == nil then return false end
    if Yasuo.Name == nil or Yasuo.Wall.name == nil or Yasuo.Name ~= Yasuo.Wall.name or Yasuo.StartPos == nil then
        Yasuo.Wall = nil
        return false
    end
    return true
end

local function IsYasuoWallCollision(startPos, endPos, speed, delay)
    if DebugMode then
        assert(startPos, "startPos nil")
        assert(endPos, "endPos nil")
        assert(speed, "speed nil")
        assert(delay, "delay nil")
    end
    if not IsYasuoWall() then return false end
    local Pos = Yasuo.Wall.pos
    local Width = 300 + 50 * Yasuo.Level
    local Direction = Perpendicular(Normalized(Pos, Yasuo.StartPos))
    local StartPos = Extended(Pos, Direction, Width / 2)
    local EndPos = Extended(StartPos, Direction, -Width)
    local IntersectionResult = Intersection(StartPos, EndPos, endPos, startPos)
    if IntersectionResult.Intersects then
        local t = delay + GetDistance(IntersectionResult.Point, startPos) / speed
        if _G.Game.Timer() + t < Yasuo.CastTime + 4 then
            return true
        end
    end
    return false
end

local function YasuoWallTick(unit)
    if DebugMode then
        assert(unit, "unit nil")
    end
    if _G.Game.Timer() > Yasuo.CastTime + 2 then
        local wallData = unit:GetSpellData(_W)
        if wallData.currentCd > 0 and wallData.cd - wallData.currentCd < 1.5 then
            Yasuo.Wall = nil
            Yasuo.Name = nil
            Yasuo.StartPos = nil
            Yasuo.Level = wallData.level
            Yasuo.CastTime = wallData.castTime
            for i = 1, _G.Game.ParticleCount() do
                local obj = _G.Game.Particle(i)
                if obj then
                    local name = obj.name:lower()
                    if name:find("yasuo") and name:find("_w_") and name:find("windwall") then
                        if name:find("activate") then
                            Yasuo.StartPos = obj.pos
                        else
                            Yasuo.Wall = obj
                            Yasuo.Name = obj.name
                            break
                        end
                    end
                end
            end
        end
    end
    if Yasuo.Wall ~= nil then
        if Yasuo.Name == nil or Yasuo.Wall.name == nil or Yasuo.Name ~= Yasuo.Wall.name or Yasuo.StartPos == nil then
            Yasuo.Wall = nil
        end
    end
end

-- VPREDICTION
local vpredlastick = 0
local PA = {}
local WaypointsTime = 10
local TargetsWaypoints = {}
local function VPredOnTick()
    if os.clock() > vpredlastick + 0.2 then
        vpredlastick = os.clock()
        for NID, TargetWaypoints in pairs(TargetsWaypoints) do
            local i = 1
            while i <= #TargetsWaypoints[NID] do
                if TargetsWaypoints[NID][i]["time"] + WaypointsTime < os.clock() then
                    Local_TableRemove(TargetsWaypoints[NID], i)
                else
                    i = i + 1
                end
            end
        end
    end
end
local function VPredGetWaypoints(NetworkID, from, to)
    local Result = {}
    to = to and to or os.clock()
    if TargetsWaypoints[NetworkID] then
        for i, waypoint in ipairs(TargetsWaypoints[NetworkID]) do
            if from <= waypoint.time and to >= waypoint.time then
                Local_TableInsert(Result, waypoint)
            end
        end
    end
    return Result, #Result
end
local function VPredGetCurrentWayPoints(object)
    local result = {}
    local path = object.pathing
    if path.hasMovePath then
        Local_TableInsert(result, object.pos)
        for i = path.pathIndex, path.pathCount do
            Local_TableInsert(result, object:GetPath(i))
        end
    else
        Local_TableInsert(result, object.pos)
    end
    return result
end
local function VPredCountWaypoints(NetworkID, from, to)
    local R, N = VPredGetWaypoints(NetworkID, from, to)
    return N
end
local function VPredOnNewPath(unit)
    local NetworkID = unit.networkID
    if PA[NetworkID] == nil then
        PA[NetworkID] = {}
    end
    if TargetsWaypoints[NetworkID] == nil then
        TargetsWaypoints[NetworkID] = {}
    end
    if PA[NetworkID][#PA[NetworkID] - 1] then
        local p1 = PA[NetworkID][#PA[NetworkID] - 1].p
        local p2 = PA[NetworkID][#PA[NetworkID]].p
        local angle = unit.pos:AngleBetween(p2, p1)
        if angle > 20 then
            local submit = {t = os.clock(), p = unit.posTo}
            Local_TableInsert(PA[NetworkID], submit)
        end
    else
        local submit = {t = os.clock(), p = unit.posTo}
        Local_TableInsert(PA[NetworkID], submit)
    end
    local WaypointsToAdd = VPredGetCurrentWayPoints(unit)
    if WaypointsToAdd and #WaypointsToAdd >= 1 then
        Local_TableInsert(TargetsWaypoints[NetworkID], {unitpos = unit.pos, waypoint = WaypointsToAdd[#WaypointsToAdd], time = os.clock(), n = #WaypointsToAdd})
    end
end
local function VPredOnTickEnemy(enemy)
    VPredOnNewPath(enemy)
    for i, tbl in pairs(PA[enemy.networkID]) do
        if os.clock() - 1.5 > tbl.t then
            Local_TableRemove(PA[enemy.networkID], i)
        end
    end
end
local function VPredMaxAngle(unit, currentwaypoint, from)
    local WPtable, n = VPredGetWaypoints(unit.networkID, from)
    local Max = 0
    local CV = (currentwaypoint - unit.pos)
    for i, waypoint in ipairs(WPtable) do
        local angle = Vector(0, 0, 0):AngleBetween(CV, waypoint.waypoint - waypoint.unitpos)
        if angle > Max then
            Max = angle
        end
    end
    return Max
end
local function VPredWayPointAnalysis(unit, delay, radius, speed, from, Position, CastPosition)
    local HitChance
    local SavedWayPoints = TargetsWaypoints[unit.networkID] and TargetsWaypoints[unit.networkID] or {}
    local CurrentWayPoints = VPredGetCurrentWayPoints(unit)
    
    if VPredCountWaypoints(unit.networkID, os.clock() - 0.1) >= 1 then
        HitChance = _G.HITCHANCE_HIGH
    end
    
    local N = 2
    local t1 = 0.75
    if VPredCountWaypoints(unit.networkID, os.clock() - 0.75) >= N then
        local angle = VPredMaxAngle(unit, CurrentWayPoints[#CurrentWayPoints], os.clock() - t1)
        if angle > 90 then
            HitChance = _G.HITCHANCE_NORMAL
        elseif angle < 30 and VPredCountWaypoints(unit.networkID, os.clock() - 0.1) >= 1 then
            HitChance = _G.HITCHANCE_HIGH
        end
    end
    
    if Position and CastPosition and ((radius / unit.ms >= delay + GetDistance(from, CastPosition) / speed) or (radius / unit.ms >= delay + GetDistance(from, Position) / speed)) then
        HitChance = _G.HITCHANCE_HIGH
    end
    
    if from:AngleBetween(unit.pos, CastPosition) > 60 then
        HitChance = _G.HITCHANCE_NORMAL
    end
    
    if #SavedWayPoints == 0 then
        HitChance = _G.HITCHANCE_HIGH
    end
    
    return HitChance
end

-- WAYPOINTS
local function GetPath(unit)
    if DebugMode then
        assert(unit, "unit nil")
    end
    local result = {unit.pos}
    local path = unit.pathing
    if path.isDashing then
        Local_TableInsert(result, unit.posTo)
    elseif path.hasMovePath then
        for i = path.pathIndex, path.pathCount do
            local pos = unit:GetPath(i)
            Local_TableInsert(result, pos)
        end
    end
    return result
end

local function GetPathLenght(path)
    if DebugMode then
        assert(path, "path nil")
    end
    local result = 0
    for i = 1, #path - 1 do
        result = result + GetDistance(path[i], path[i + 1])
    end
    return result
end

local function OnVisible(unit)
    if DebugMode then
        assert(unit, "unit nil")
    end
    local id = unit.networkID
    if VisibleData[id] == nil then VisibleData[id] = {IsVisible = true, IsDashing = false, InVisibleTimer = 0, VisibleTimer = 0, LastPath = {}, MoveSpeed = 0} end
    if unit.visible then
        -- on visible
        if not VisibleData[id].IsVisible then
            VisibleData[id].IsVisible = true
            VisibleData[id].VisibleTimer = Local_OsClock()
        end
        -- remove old path
        local count = #VisibleData[id].LastPath
        for i = count, 1, -1 do
            Local_TableRemove(VisibleData[id].LastPath, i)
        end
        -- create new path if unit is moving
        local path = unit.pathing
        if path and path.hasMovePath then
            -- is dashing
            if path.isDashing then
                VisibleData[id].IsDashing = true
                VisibleData[id].MoveSpeed = path.dashSpeed
            else
                VisibleData[id].IsDashing = false
                VisibleData[id].MoveSpeed = unit.ms
            end
            VisibleData[id].LastPath = GetPath(unit)
        end
        return
    end
    -- on invisible
    if VisibleData[id].IsVisible then
        VisibleData[id].IsVisible = false
        VisibleData[id].InVisibleTimer = Local_OsClock()
    end
end

local function OnWaypoint(unit)
    if DebugMode then
        assert(unit, "unit nil")
    end
    local id = unit.networkID
    if not unit.visible or Local_OsClock() < VisibleData[id].VisibleTimer + 0.15 then return end
    local path = unit.pathing
    if NewPosData[id] == nil then
        NewPosData[id] = {Pos = unit.pos, Tick = os.clock()}
    elseif not IsInRange(unit.pos, NewPosData[id].Pos, 3) then
        NewPosData[id] = {Pos = unit.pos, Tick = os.clock(), Dir = Normalized(unit.pos, NewPosData[id].Pos)}
    end
    if WaypointData[id] == nil or path.hasMovePath ~= WaypointData[id].IsMoving or WaypointData[id].Path ~= unit.posTo then
        WaypointData[id] = {IsMoving = path.hasMovePath, Path = unit.posTo, Tick = Local_OsClock()}
        if DebugMode then
            --print("on waypoint "..unit.charName)
        end
    end
end

local function CutPath(path, distance)
    local result = {}
    local Distance = distance
    if distance < 0 then
        path[1] = path[1] + distance * (path[2] - path[1]):Normalized()
        return path
    end
    for i = 1, #path - 1 do
        local dist = path[i]:DistanceTo(path[i + 1])
        if dist > Distance then
            Local_TableInsert(result, path[i] + Distance * (path[i + 1] - path[i]):Normalized())
            for j = i + 1, #path do
                Local_TableInsert(result, path[j])
            end
            break
        end
        Distance = Distance - dist
    end
    
    if #result > 0 then
        return result
    end
    
    return {path[#path]}
end

local function GetInvisiblePath(unit, path)
    if DebugMode then
        assert(unit, "unit nil")
        assert(path, "path nil")
    end
    local data = VisibleData[unit.networkID]
    local movedist = data.MoveSpeed * (Local_OsClock() - data.InVisibleTimer)
    path[#path] = path[#path] + (path[#path] - path[#path - 1]):Normalized() * movedist
    path = CutPath(path, movedist)
    return path
end

local function GetPredictedPos(unit, path, predDistance)
    if DebugMode then
        assert(unit, "unit nil")
        assert(path, "path nil")
        assert(predDistance, "predDistance nil")
    end
    if not unit.visible then
        path = GetInvisiblePath(unit, path)
    end
    path = CutPath(path, predDistance)
    return path[1]
end

-- COLLISION
_G.COLLISION_MINION = 0
_G.COLLISION_ALLYHERO = 1
_G.COLLISION_ENEMYHERO = 2
_G.COLLISION_YASUOWALL = 3

local function GetCollision(from, to, speed, delay, radius, collisionTypes, skipID)
    if DebugMode then
        assert(from, "from nil")
        assert(toPositions, "toPositions nil")
        assert(speed, "speed nil")
        assert(delay, "delay nil")
        assert(radius, "radius nil")
        assert(collisionTypes, "collisionTypes nil")
        assert(skipID, "skipID nil")
    end
    from = from + (from - to):Normalized() * 35
    local toradius = radius + 35
    to = to + (to - from):Normalized() * toradius
    local isWall, collisionObjects, collisionCount = false, {}, 0
    local checkYasuoWall = false
    local objects = {}
    for i, colType in pairs(collisionTypes) do
        if colType == _G.COLLISION_ALLYHERO or colType == _G.COLLISION_ENEMYHERO then
            for k = 1, Game.HeroCount() do
                local hero = Game.Hero(k)
                if hero then
                    if colType == _G.COLLISION_ALLYHERO then
                        if hero.isAlly and not hero.isMe and skipID ~= hero.networkID and IsInRange(from, hero.pos, 2000) and Local_Core:IsValidTarget(hero) then
                            Local_TableInsert(objects, hero)
                        end
                    elseif hero.isEnemy and skipID ~= hero.networkID and IsInRange(from, hero.pos, 2000) and Local_Core:IsValidTarget(hero) then
                        Local_TableInsert(objects, hero)
                    end
                end
            end
        elseif colType == _G.COLLISION_MINION then
            for k = 1, Game.MinionCount() do
                local minion = Game.Minion(k)
                if minion and minion.team ~= Local_Core.TEAM_ALLY and IsInRange(from, minion.pos, 2000) and minion.maxHealth > 100 and Local_Core:IsValidTarget(minion) then
                    Local_TableInsert(objects, minion)
                end
            end
        elseif colType == _G.COLLISION_YASUOWALL then
            checkYasuoWall = true
        end
    end
    for k, object in pairs(objects) do
        local NetworkID = object.networkID
        if not collisionObjects[NetworkID] then
            local objectPos = object.pos
            local pointLine, isOnSegment = ClosestPointOnLineSegment(objectPos, from, to)
            if isOnSegment and IsInRange(objectPos, pointLine, radius + 15 + object.boundingRadius) then
                collisionObjects[NetworkID] = object
                collisionCount = collisionCount + 1
            elseif object.pathing.hasMovePath then
                objectPos = object:GetPrediction(speed, delay)
                pointLine, isOnSegment = ClosestPointOnLineSegment(objectPos, from, to)
                if isOnSegment and IsInRange(objectPos, pointLine, radius + 15 + object.boundingRadius) then
                    collisionObjects[NetworkID] = object
                    collisionCount = collisionCount + 1
                end
            end
        end
    end
    if checkYasuoWall and IsYasuoWall() then
        local Pos = Yasuo.Wall.pos
        local ExtraWidth = 70
        local Width = ExtraWidth + 300 + 50 * Yasuo.Level
        local Direction = Perpendicular(Normalized(Pos, Yasuo.StartPos))
        local StartPos = Extended(Pos, Direction, Width / 2)
        local EndPos = Extended(StartPos, Direction, -Width)
        local IntersectionResult = Intersection(StartPos, EndPos, to, from)
        if IntersectionResult.Intersects then
            local t = _G.Game.Timer() + (GetDistance(IntersectionResult.Point, from) / speed + delay)
            if t < Yasuo.CastTime + 4 then
                isWall = true
                collisionCount = collisionCount + 1
                collisionObjects[Yasuo.Wall.networkID] = Yasuo.Wall
            end
        end
    end
    return isWall, collisionObjects, collisionCount
end

-- BUFFS / SPELLS
local BUFFTYPE_INTERNAL = 0
local BUFFTYPE_AURA = 1
local BUFFTYPE_ENHANCER = 2
local BUFFTYPE_DEHANCER = 3
local BUFFTYPE_SPELLSHIELD = 4
local BUFFTYPE_STUN = 5
local BUFFTYPE_INVIS = 6
local BUFFTYPE_SILENCE = 7
local BUFFTYPE_TAUNT = 8
local BUFFTYPE_POLYMORPH = 9
local BUFFTYPE_SLOW = 10
local BUFFTYPE_SNARE = 11
local BUFFTYPE_DMG = 12
local BUFFTYPE_HEAL = 13
local BUFFTYPE_HASTE = 14
local BUFFTYPE_SPELLIMM = 15
local BUFFTYPE_PHYSIMM = 16
local BUFFTYPE_INVULNERABLE = 17
local BUFFTYPE_SLEEP = 18
local BUFFTYPE_NEARSIGHT = 19
local BUFFTYPE_FRENZY = 20
local BUFFTYPE_FEAR = 21
local BUFFTYPE_CHARM = 22
local BUFFTYPE_POISON = 23
local BUFFTYPE_SUPRESS = 24
local BUFFTYPE_BLIND = 25
local BUFFTYPE_COUNTER = 26
local BUFFTYPE_SHRED = 27
local BUFFTYPE_FLEE = 28
local BUFFTYPE_KNOCKUP = 29
local BUFFTYPE_KNOCKBACK = 30
local BUFFTYPE_DISARM = 31
local IMMOBILE_TYPES =
{
    [BUFFTYPE_STUN] = true,
    [BUFFTYPE_TAUNT] = true,
    [BUFFTYPE_SNARE] = true,
    [BUFFTYPE_CHARM] = true,
    [BUFFTYPE_SUPRESS] = true
}

function GetImmobileSlowDuration(unit)
    if DebugMode then
        assert(unit, "unit nil")
    end
    local ImmobileDuration, SlowDuration = 0, 0
    for i = 0, unit.buffCount do
        local buff = unit:GetBuff(i)
        if buff and buff.count > 0 then
            local duration = buff.duration
            if buff.duration > 0 then
                local t = buff.type
                if IMMOBILE_TYPES[t] and duration > ImmobileDuration then
                    ImmobileDuration = duration
                end
                if t == BUFFTYPE_SLOW and duration > SlowDuration then
                    SlowDuration = duration
                end
            end
        end
    end
    
    local spell = unit.activeSpell
    if spell and spell.valid then
        local spellDuration = spell.castEndTime - Game.Timer()
        if spellDuration > 0 and spellDuration > ImmobileDuration then
            ImmobileDuration = spellDuration
        end
    end
    
    return ImmobileDuration, SlowDuration
end

-- PREDICTION
_G.HITCHANCE_IMPOSSIBLE = 0
_G.HITCHANCE_COLLISION = 1
_G.HITCHANCE_NORMAL = 2
_G.HITCHANCE_HIGH = 3
_G.HITCHANCE_IMMOBILE = 4
_G.SPELLTYPE_LINE = 0
_G.SPELLTYPE_CIRCLE = 1
_G.SPELLTYPE_CONE = 2

local function PredictionOutput(args)
    if DebugMode then
        assert(args, "args nil")
        assert(args.Input, "args.Input nil")
    end
    args = args or {}
    local result =
    {
        CastPosition = args.CastPosition or nil,
        UnitPosition = args.UnitPosition or nil,
        Hitchance = args.Hitchance or _G.HITCHANCE_IMPOSSIBLE,
        Input = args.Input or nil
    }
    return result
end

local function PredictionInput(unit, args, from)
    if DebugMode then
        assert(unit, "unit nil")
        assert(args, "args nil")
        assert(args.Radius, "args.Radius nil")
        assert(args.Speed, "args.Speed nil")
        assert(args.Range, "args.Range nil")
        assert(args.Type, "args.Type nil")
        assert(args.Delay, "args.Delay nil")
    end
    args = args or {}
    local result =
    {
        Collision = args.Collision or false,
        MaxCollision = args.MaxCollision or 0,
        CollisionTypes = args.CollisionTypes or {_G.COLLISION_MINION, _G.COLLISION_YASUOWALL},
        Delay = args.Delay or Local_MathHuge,
        Radius = args.Radius or Local_MathHuge,
        Range = args.Range or Local_MathHuge,
        Speed = args.Speed or Local_MathHuge,
        Type = args.Type or _G.SPELLTYPE_LINE
    }
    result.From = from
    result.RangeCheckFrom = myHero
    result.Unit = unit
    if DebugMode then
        assert(result.From, "result.From nil")
        assert(result.RangeCheckFrom, "result.RangeCheckFrom nil")
        assert(result.Unit, "result.Unit nil")
        assert(result.Speed, "result.Speed nil")
        assert(result.Range, "result.Range nil")
        assert(result.Type, "result.Type nil")
        assert(result.Delay, "result.Delay nil")
        assert(result.Radius, "result.Radius nil")
        assert(result.Speed == args.Speed, "result.Speed ~= args.Speed")
        assert(result.Range == args.Range, "result.Range ~= args.Range nil")
        assert(result.Type == args.Type, "result.Type ~= args.Type")
        assert(result.Delay == args.Delay, "result.Delay ~= args.Delay")
        assert(result.Radius == args.Radius, "result.Radius ~= args.Radius")
    end
    result.Delay = result.Delay + 0.06 + _G.LATENCY
    result.RealRadius = result.Radius
    if args.UseBoundingRadius or result.Type == _G.SPELLTYPE_LINE then result.RealRadius = result.Radius + unit.boundingRadius end
    return result
end

local function GetHitChance(unit, moveSpeed, slowDuration, delay)
    if DebugMode then
        assert(unit, "unit nil")
        assert(moveSpeed, "moveSpeed nil")
        assert(slowDuration, "slowDuration nil")
        assert(delay, "delay nil")
    end
    local hitChance = _G.HITCHANCE_NORMAL
    local lastMoveTime = Local_OsClock() - WaypointData[unit.networkID].Tick
    if lastMoveTime < 0.175 or lastMoveTime > 1 then
        hitChance = _G.HITCHANCE_HIGH
    end
    if slowDuration > 0 and moveSpeed < 250 and slowDuration >= delay then
        hitChance = _G.HITCHANCE_HIGH
    end
    return hitChance
end

local function GetImmobilePrediction(input, ImmobileDuration)
    if DebugMode then
        assert(input, "input nil")
        assert(ImmobileDuration, "ImmobileDuration nil")
    end
    local unit = input.Unit
    local pos = unit.pos
    local id = unit.networkID
    if unit.pathing.hasMovePath or WaypointData[id].IsMoving then
        return PredictionOutput({Input = input})
    end
    if ImmobileDuration >= input.Delay + (GetDistance(input.From.pos, pos) / input.Speed) - (input.RealRadius / unit.ms) then
        return PredictionOutput({Input = input, Hitchance = _G.HITCHANCE_IMMOBILE, CastPosition = pos, UnitPosition = pos})
    end
    -- ONLY AFK !!!
    if Local_OsClock() - VisibleData[id].VisibleTimer > 2.5 and Local_OsClock() - WaypointData[id].Tick > 2.5 then
        return PredictionOutput({Input = input, Hitchance = _G.HITCHANCE_HIGH, CastPosition = pos, UnitPosition = pos})
    end
    if Local_OsClock() - VisibleData[id].VisibleTimer > 0.75 and Local_OsClock() - WaypointData[id].Tick > 0.75 then
        return PredictionOutput({Input = input, Hitchance = _G.HITCHANCE_NORMAL, CastPosition = pos, UnitPosition = pos})
    end
    return PredictionOutput({Input = input})
end

local function GetDashingPrediction(input, endPos, dashSpeed)
    if DebugMode then
        assert(input, "input nil")
        assert(endPos, "endPos nil")
        assert(dashSpeed, "dashSpeed nil")
    end
    local unit, delay, radius, speed, from = input.Unit, input.Delay, input.Radius, input.Speed, input.From.pos
    local startPos
    if unit.visible then
        startPos = unit.pos
    else
        local data = VisibleData[unit.networkID]
        local dist = data.MoveSpeed * (Local_OsClock() - data.InVisibleTimer)
        if dist > GetDistance(data.LastPath[1], data.LastPath[2]) then
            return PredictionOutput({Input = input})
        end
        startPos = unit.pos:Extended(endPos, dist)
    end
    local startT = Local_OsClock()
    local dashDist = GetDistance(startPos, endPos)
    if dashDist < 50 then
        return PredictionOutput({Input = input})
    end
    local endT = startT + (dashDist / dashSpeed)
    if endT >= startT and startPos and endPos then
        local Pos = nil
        local t1, p1, t2, p2, dist = VectorMovementCollision(startPos, endPos, dashSpeed, from, speed, delay)
        t1, t2 = (t1 and 0 <= t1 and t1 <= (endT - startT - delay)) and t1 or nil, (t2 and 0 <= t2 and t2 <= (endT - startT - delay)) and t2 or nil
        local t = t1 and t2 and Local_MathMin(t1, t2) or t1 or t2
        if t then
            Pos = t == t1 and Vector(p1.x, 0, p1.y) or Vector(p2.x, 0, p2.y)
            return PredictionOutput({Input = input, Hitchance = _G.HITCHANCE_HIGH, CastPosition = Pos, UnitPosition = Pos})
        end
        Pos = Vector(endPos.x, 0, endPos.z)
        if (unit.ms * (delay + GetDistance(from, Pos) / speed - (endT - startT))) < radius then
            return PredictionOutput({Input = input, Hitchance = _G.HITCHANCE_HIGH, CastPosition = Pos, UnitPosition = Pos})
        end
    end
    return PredictionOutput({Input = input})
end

local function GetStandardPrediction(input, slowDuration, moveSpeed, unitpath)
    if DebugMode then
        assert(input, "input nil")
        assert(slowDuration, "slowDuration nil")
        assert(moveSpeed, "moveSpeed nil")
        assert(unitpath, "unitpath nil")
    end
    local Radius = input.RealRadius * 0.6 -- Draven W, Garen Q = no hit that why * 0.6
    local extradelay = 0; if input.Speed ~= Local_MathHuge then extradelay = (GetDistance(input.From.pos, input.Unit.pos) / input.Speed) end
    local delay = input.Delay + extradelay
    local pLenght = GetPathLenght(unitpath)
    if pLenght < 50 then
        return PredictionOutput({Input = input})
    end
    local cpos, upos
    if input.Speed == Local_MathHuge then
        cpos = GetPredictedPos(input.Unit, unitpath, moveSpeed * math.max(0, input.Delay - (Radius / moveSpeed)))
        upos = GetPredictedPos(input.Unit, unitpath, moveSpeed * input.Delay)
    else
        local endPos = GetPredictedPos(input.Unit, unitpath, moveSpeed * delay)
        local interceptTime = input.Delay + GetInterceptionTime(input.From.pos, input.Unit.pos, endPos, moveSpeed, input.Speed)
        local interceptTime2 = interceptTime - (Radius / moveSpeed)
        cpos = GetPredictedPos(input.Unit, unitpath, moveSpeed * interceptTime2)
        upos = GetPredictedPos(input.Unit, unitpath, moveSpeed * interceptTime)
    end
    local posData = NewPosData[input.Unit.networkID]
    local angle = Local_Core:AngleBetween(Normalized(upos, input.Unit.pos), posData.Dir)
    if posData.Dir == nil or angle > 45 then
        return PredictionOutput({Input = input})
    end
    local hitChance = GetHitChance(input.Unit, moveSpeed, slowDuration, delay - (input.RealRadius / moveSpeed))
    if hitChance == _G.HITCHANCE_NORMAL then
        hitChance = VPredWayPointAnalysis(input.Unit, input.Delay, input.RealRadius, input.Speed, input.From.pos, upos, cpos)
    end
    return PredictionOutput({Input = input, Hitchance = hitChance, CastPosition = cpos, UnitPosition = upos})
end

local function GetPredictionOutput(input)
    if DebugMode then
        assert(input, "input nil")
    end
    local unit = input.Unit
    local data = VisibleData[unit.networkID]
    local ImmobileDuration, SlowDuration = GetImmobileSlowDuration(unit)
    local path = unit.pathing
    local visible = unit.visible
    if not path then
        return PredictionOutput({Input = input})
    end
    if not visible and (Local_OsClock() > data.InVisibleTimer + 1 or #data.LastPath <= 1) then
        return PredictionOutput({Input = input})
    end
    if visible and Local_OsClock() < data.VisibleTimer + 0.2 then
        return PredictionOutput({Input = input})
    end
    if visible and (not path.hasMovePath or ImmobileDuration > 0) then
        return GetImmobilePrediction(input, ImmobileDuration)
    end
    if (not visible and data.IsDashing) or path.isDashing then
        local dashSpeed; if not visible then dashSpeed = data.MoveSpeed else dashSpeed = path.dashSpeed end
        local dashEndPos; if not visible then dashEndPos = data.LastPath[#data.LastPath] else dashEndPos = unit.posTo end
        return GetDashingPrediction(input, dashEndPos, dashSpeed)
    end
    if not visible or path.hasMovePath then
        input.Range = input.Range * MaxRangeMulipier
        local unitspeed; if not visible then unitspeed = data.MoveSpeed else unitspeed = unit.ms end
        local unitpath; if not visible then unitpath = data.LastPath else unitpath = GetPath(unit) end
        return GetStandardPrediction(input, SlowDuration, unitspeed, unitpath)
    end
    return PredictionOutput({Input = input})
end

function GetGamsteronPrediction(unit, args, from)
    --[[local delay, radius, range, speed, collision, spelltype = 0, 1, 1, math.huge, false, "line"
    if args.Delay then delay = args.Delay end
    if args.Radius then radius = args.Radius end
    if args.Range then range = args.Range end
    if args.Speed then speed = args.Speed end
    if args.Collision then collision = true end
    if args.Type and args.Type == _G.SPELLTYPE_CIRCLE then spelltype = "circular" end
    local castpos, HitChance, pos = TrusPrediction:GetBestCastPosition(unit, delay, radius, range, speed, from.pos, collision, spelltype, 0.3)
    if not unit.pathing.isDashing then
        return PredictionOutput({Hitchance = _G.HITCHANCE_IMPOSSIBLE, CastPosition = unit.pos, UnitPosition = unit.pos})
    end
    if HitChance >= 2 then
        return PredictionOutput({Hitchance = _G.HITCHANCE_HIGH, CastPosition = castpos, UnitPosition = pos})
    end
    if HitChance == 1 then
        return PredictionOutput({Hitchance = _G.HITCHANCE_NORMAL, CastPosition = castpos, UnitPosition = pos})
    end
    return PredictionOutput({Hitchance = _G.HITCHANCE_IMPOSSIBLE, CastPosition = unit.pos, UnitPosition = unit.pos})
    --]]
    if DebugMode then
        assert(unit, "unit nil")
        assert(args, "args nil")
        assert(from, "from nil")
    end
    local posTo = unit.posTo
    local visible = unit.visible
    local movePath = unit.pathing.hasMovePath
    local isdashing = unit.pathing.isDashing
    OnVisible(unit)
    OnWaypoint(unit)
    local input = PredictionInput(unit, args, from)
    local output = GetPredictionOutput(input)
    if output.Hitchance ~= _G.HITCHANCE_IMPOSSIBLE then
        if DebugMode then
            assert(output.UnitPosition, "output.UnitPosition nil")
            assert(output.CastPosition, "output.CastPosition nil")
            assert(output.Hitchance, "output.Hitchance nil")
            Draw.Circle(output.CastPosition)
            Draw.Text(tostring(output.Hitchance), 30, output.CastPosition:To2D())
        end
        if input.Range ~= Local_MathHuge then
            if output.Hitchance >= _G.HITCHANCE_HIGH and not IsInRange(input.RangeCheckFrom.pos, unit.pos, input.Range + input.RealRadius * 3 / 4) then
                output.Hitchance = _G.HITCHANCE_NORMAL
            end
            if not IsInRange(input.RangeCheckFrom.pos, output.UnitPosition, input.Range + (input.Type == _G.SPELLTYPE_CIRCLE and input.RealRadius or 0)) then
                output.Hitchance = _G.HITCHANCE_IMPOSSIBLE
            end
            if not IsInRange(output.CastPosition, myHero.pos, input.Range) then
                output.Hitchance = _G.HITCHANCE_IMPOSSIBLE
            end
        end
    end
    if input.Collision and output.Hitchance ~= _G.HITCHANCE_IMPOSSIBLE then
        local isWall, collisionObjects, collisionCount = GetCollision(input.From.pos, output.CastPosition, input.Speed, input.Delay, input.Radius, input.CollisionTypes, unit.networkID)
        if isWall or collisionCount > input.MaxCollision then
            output.Hitchance = _G.HITCHANCE_COLLISION
            output.CollisionObjects = {}
            for id, object in pairs(collisionObjects) do
                Local_TableInsert(output.CollisionObjects, object)
            end
        end
    end
    if output.Hitchance >= _G.HITCHANCE_COLLISION then
        --output.CastPosition = Vector({x = output.CastPosition.x, y = unit.pos.y, z = output.CastPosition.z})
        output.CastPosition = Vector(output.CastPosition.x, 0, output.CastPosition.z)
        if not output.CastPosition:ToScreen().onScreen then
            if input.Type == _G.SPELLTYPE_LINE then
                output.CastPosition = input.From.pos:Extended(output.CastPosition, 600)
            end
        end
    end
    if output.Hitchance >= _G.HITCHANCE_COLLISION then
        if posTo ~= unit.posTo or movePath ~= unit.pathing.hasMovePath or isdashing ~= unit.pathing.isDashing or visible ~= unit.visible then
            output.Hitchance = _G.HITCHANCE_IMPOSSIBLE
        end
    end
    return output
end

-- CALLBACKS
_G.Callback.Add("Load", function()
    Callback.Add("Tick", function()
        local YasuoChecked = false
        for i = 1, _G.Game.HeroCount() do
            local unit = _G.Game.Hero(i)
            if unit and unit.valid and unit.alive then
                VPredOnTickEnemy(unit)
                OnVisible(unit)
                OnWaypoint(unit)
                if IsYasuo and not YasuoChecked and unit.charName == "Yasuo" then
                    YasuoWallTick(unit)
                    YasuoChecked = true
                end
            end
        end
        VPredOnTick()
        if DebugMode then
            --Draw.Circle(GetPredictedPos(myHero, GetPath(myHero), myHero.ms * 0.5))
            local path = GetPath(myHero)
            for i = 1, #path do
                --Draw.Circle(path[i], 30, Draw.Color(255, 0, 255, 0))
            end
            local movedist = 150
            if #path > 1 then
                path[#path] = path[#path] + (path[#path] - path[#path - 1]):Normalized() * movedist
                path = CutPath(path, movedist)
                for i = 1, #path do
                    --Draw.Circle(path[i], 30, Draw.Color(255, 255, 0, 0))
                end
            end
            local NewPos = NewPosData[myHero.networkID]
            if NewPos.Dir then
                --Draw.Circle(myHero.pos + Vector(NewPos.Dir.x, 0, NewPos.Dir.y) * 100)
                --print(Local_Core:AngleBetween(Normalized(myHero.posTo, myHero.pos), NewPos.Dir))
            end
        end
    end)
end)
