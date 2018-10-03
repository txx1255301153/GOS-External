--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Initialize:                                                                                                                                          
    -- Return:                                                                                                                                          
        if _G.GamsteronPredictionLoaded then
            return
        end
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    -- Load Core:                                                                                                                                       
        local _Update = true
        ------------------------------------------------------------------------------------------------------------------------------------------------
        if _Update then
            if not FileExist(COMMON_PATH .. "GamsteronCore.lua") then
                DownloadFileAsync("https://raw.githubusercontent.com/gamsteron/GOS-External/master/Common/GamsteronCore.lua", COMMON_PATH .. "GamsteronCore.lua", function() end)
                while not FileExist(COMMON_PATH .. "GamsteronCore.lua") do end
            end
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        require('GamsteronCore')
        ------------------------------------------------------------------------------------------------------------------------------------------------
        if _G.GamsteronCoreUpdated then
            return
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local Core = _G.GamsteronCore
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    -- Auto Update:                                                                                                                                     
        if _Update then
            local args =
            {
                version = 0.05,
                ----------------------------------------------------------------------------------------------------------------------------------------
                scriptPath = COMMON_PATH .. "GamsteronPrediction.lua",
                scriptUrl = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Common/GamsteronPrediction.lua",
                ----------------------------------------------------------------------------------------------------------------------------------------
                versionPath = COMMON_PATH .. "GamsteronPrediction.version",
                versionUrl = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Common/GamsteronPrediction.version"
            }
            --------------------------------------------------------------------------------------------------------------------------------------------
            local success, version = Core:AutoUpdate(args)
            --------------------------------------------------------------------------------------------------------------------------------------------
            if success then
                print("GamsteronPrediction updated to version " .. version .. ". Please Reload with 2x F6 !")
                _G.GamsteronPredictionUpdated = true
            end
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        if _G.GamsteronPredictionUpdated then
            return
        end
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Locals:                                                                                                                                              
    local DebugMode                 = false
    local HighAccuracy              = 0.1
    local Prediction                = Core:Class()
    local myHero                    = _G.myHero
    local MathSqrt                  = _G.math.sqrt
    local MathMax                   = _G.math.max
    local MathAbs                   = _G.math.abs
    local MathHuge                  = _G.math.huge
    local MathMin                   = _G.math.min
    local GameTimer                 = _G.Game.Timer
    local TableInsert               = _G.table.insert
    local TableRemove               = _G.table.remove
    local GameMinion                = _G.Game.Minion
    local GameMinionCount           = _G.Game.MinionCount
    local GameHeroCount 			= _G.Game.HeroCount
    local GameHero 				    = _G.Game.Hero
    local TEAM_ALLY                 = Core.TEAM_ALLY
    -- Methods:                                                                                                                                         
        local function To2D(vec)
            return { x = vec.x, y = vec.z or vec.y }
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local function GetDistance(vec1, vec2)
            local dx = vec1.x - vec2.x
            local dy = vec1.y - vec2.y
            return MathSqrt(dx * dx + dy * dy)
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local function GetDistanceSquared(vec1, vec2)
            local dx = vec1.x - vec2.x
            local dy = vec1.y - vec2.y
            return dx * dx + dy * dy
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local function IsInRange(vec1, vec2, range)
            if not vec2 then return false end
            local dx = vec1.x - vec2.x
            local dy = vec1.y - vec2.y
            return dx * dx + dy * dy <= range * range
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local function Normalized(vec1, vec2)
            local vec = { x = vec1.x - vec2.x, y = vec1.y - vec2.y }
            local length = MathSqrt(vec.x * vec.x + vec.y * vec.y)
            if length > 0 then
                local inv = 1.0 / length
                return { x = vec.x * inv, y = vec.y * inv }
            end
            return nil
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local function Extended(vec, dir, range)
            if dir == nil then return vec end
            return { x = vec.x + dir.x * range, y = vec.y + dir.y * range }
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local function IsValidTarget(target)
			if target == nil or target.networkID == nil then
				return false
			end
			if target.dead or not target.valid or (not target.visible) or (not target.isTargetable) then
				return false
			end
			return true
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local function GetEnemyMinions(from, range)
			local result = {}
			for i = 1, GameMinionCount() do
				local minion = GameMinion(i)
				local mr = bb and range + minion.boundingRadius or range
				if minion and minion.team ~= TEAM_ALLY and IsValidTarget(minion) and IsInRange(from, To2D(minion.pos), mr) then
					result[#result+1] = minion
				end
			end
			return result
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
		local function GetAllyHeroes(from, range, unitID)
            local result = {}
			for i = 1, GameHeroCount() do
				local hero = GameHero(i)
				if hero and IsValidTarget(hero) and unitID ~= hero.networkID and hero.team == TEAM_ALLY then
					if IsInRange(from, To2D(hero.pos), range) then
						TableInsert(result, hero)
					end
				end
			end
			return result
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
		local function GetEnemyHeroes(from, range, unitID)
            local result = {}
			for i = 1, GameHeroCount() do
				local hero = GameHero(i)
				if hero and IsValidTarget(hero) and unitID ~= hero.networkID and hero.team ~= TEAM_ALLY then
					if IsInRange(from, To2D(hero.pos), range) then
						TableInsert(result, hero)
					end
				end
			end
			return result
		end
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants:                                                                                                                                           
    -- Hit Chance:                                                                                                                                      
        local HITCHANCE_IMPOSSIBLE      = 0
        local HITCHANCE_COLLISION       = 1
        local HITCHANCE_NORMAL          = 2
        local HITCHANCE_HIGH            = 3
        local HITCHANCE_IMMOBILE        = 4
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    -- Spell Type:                                                                                                                                      
        local SPELLTYPE_LINE            = 0
        local SPELLTYPE_CIRCLE          = 1
        local SPELLTYPE_CONE            = 2
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Prediction Methods:                                                                                                                                  
    local function GetWaypoints(unit, unitID)
        local result = {}
        if unit.visible then
            TableInsert(result, To2D(unit.pos))
            local path = unit.pathing
            for i = path.pathIndex, path.pathCount do
                TableInsert(result, To2D(unit:GetPath(i)))
            end
        else
            local data = Core:GetHeroData(unit)
            if data and data.IsMoving and GameTimer() < data.GainVisionTimer + 0.5 then
                result = data.Path
            end
        end
        return result
    end
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    -- Prediction Output:                                                                                                                                   
        local function PredictionOutput(args)
            args = args or {}
            ------------------------------------------------------------------------------------
            local result =
            {
                CastPosition           = args.CastPosition         or nil,
                UnitPosition           = args.UnitPosition         or nil,
                Hitchance              = args.Hitchance            or HITCHANCE_IMPOSSIBLE,
                Input                  = args.Input                or nil,
                ------------------------------------------------------------------------------------
                CollisionObjects       = args.CollisionObjects     or {},
                ------------------------------------------------------------------------------------
                AoeTargetsHit          = args.AoeTargetsHit        or {},
                AoeTargetsHitCount     = args.AoeTargetsHitCount   or 0
            }
            ------------------------------------------------------------------------------------
            result.AoeTargetsHitCount = MathMax(result.AoeTargetsHitCount, #result.AoeTargetsHit)
            return result
        end
    --------------------------------------------------------------------------------------------------------------------------------------------------------
    -- Prediction Input:                                                                                                                                    
        local function PredictionInput(args)
            local result =
            {
                Aoe                = args.Aoe                  or false,
                Collision          = args.Collision            or false,
                Unit               = args.Unit                 or nil,
                From               = args.From                 or myHero,
                MaxCollision       = args.MaxCollision         or 0,
                CollisionObjects   = args.CollisionObjects     or { Core.COLLISION_MINION, Core.COLLISION_YASUOWALL },
                Delay              = args.Delay                or 0,
                Radius             = args.Radius               or 1,
                Range              = args.Range                or MathHuge,
                Speed              = args.Speed                or MathHuge,
                Type               = args.Type                 or SPELLTYPE_LINE
            }
            result.Valid = true
            ------------------------------------------------------------------------------------------------------------------------------------------------
            if args.UseBoundingRadius or result.Type == SPELLTYPE_LINE then
                result.RealRadius = result.Radius + (result.Unit.boundingRadius*0.5)
            else
                result.RealRadius = result.Radius
            end
            result.RealRadius = result.RealRadius * 0.9
            ------------------------------------------------------------------------------------------------------------------------------------------------
            result.Delay = result.Delay + 0.06 + (Core:GetLatency() * 0.5)
            ------------------------------------------------------------------------------------------------------------------------------------------------
            if result.From == nil or result.Unit == nil or not result.Unit.valid or result.Unit.dead or not result.Unit.isTargetable then
                result.Valid = false
                return result
            end
            ------------------------------------------------------------------------------------------------------------------------------------------------
            result.UnitID = result.Unit.networkID
            ------------------------------------------------------------------------------------------------------------------------------------------------
            local from = To2D(myHero.pos)
            if result.Collision then
                result.ObjectsList = {}
                for i = 1, #result.CollisionObjects do
                    local CollisionType = result.CollisionObjects[i]
                    if CollisionType == Core.COLLISION_MINION then
                        result.ObjectsList.enemyMinions = GetEnemyMinions(from, 2000)
                    elseif CollisionType ==  Core.COLLISION_ALLYHERO then
                        result.ObjectsList.allyHeroes = GetAllyHeroes(from, 2000, result.UnitID)
                    elseif CollisionType == Core.COLLISION_ENEMYHERO then
                        result.ObjectsList.enemyHeroes = GetEnemyHeroes(from, 2000, result.UnitID)
                    end
                end
            end
            ------------------------------------------------------------------------------------------------------------------------------------------------
            result.UnitData = Core:GetHeroData(result.Unit)
            ------------------------------------------------------------------------------------------------------------------------------------------------
            if GameTimer() < result.UnitData.RemainingImmortal - result.Delay + 0.1 then
                result.Valid = false
                return result
            end
            ------------------------------------------------------------------------------------------------------------------------------------------------
            result.From = To2D(result.From.pos)
            ------------------------------------------------------------------------------------------------------------------------------------------------
            if result.Range ~= MathHuge and not IsInRange(result.From, To2D(result.Unit.pos), result.Range * 1.5) then
                result.Valid = false
                return result
            end
            ------------------------------------------------------------------------------------------------------------------------------------------------
            result.RangeCheckFrom = To2D(myHero.pos)
            ------------------------------------------------------------------------------------------------------------------------------------------------
            return result
        end
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    local function GetStandardPrediction(input)
        local unit = input.Unit
        local unitID = input.UnitID
        local unitPos = To2D(unit.pos)
        local unitPath = unit.pathing
        local speed = unit.ms
        if IsInRange(unitPos, input.From, 200) then
            speed = speed / 1.5
        end
        local data = input.UnitData
        local path = GetWaypoints(unit, unitID)
        local pathCount = #path
        local Radius = input.RealRadius
        ------------------------------------------------------------------------------------------------------------------------------------------------
        if pathCount == 1 or not unitPath.hasMovePath or IsInRange(unitPos, To2D(unitPath.endPos), 25) then
            if unit.visible and GameTimer() > data.LastMoveTimer + 0.5 and pathCount == 1 and not unitPath.hasMovePath then
                if GameTimer() > data.StopMoveTimer + 3 and GameTimer() > data.LastMoveTimer + 3 then
                    return PredictionOutput({ Input = input, Hitchance = HITCHANCE_HIGH, CastPosition = unitPos, UnitPosition = unitPos })
                end
                return PredictionOutput({ Input = input, Hitchance = HITCHANCE_NORMAL, CastPosition = unitPos, UnitPosition = unitPos })
            end
            PredictionOutput()
        ------------------------------------------------------------------------------------------------------------------------------------------------
        elseif pathCount > 1 and Core:PathLength(path) > -Radius + (input.Delay * speed) then
        ------------------------------------------------------------------------------------------------------------------------------------------------
            local HitChance = (GameTimer() < data.LastMoveTimer + HighAccuracy) and HITCHANCE_HIGH or HITCHANCE_NORMAL
            --------------------------------------------------------------------------------------------------------------------------------------------
            if input.Speed == MathHuge then
                local tDistance = (input.Delay * speed) - Radius
                for i = 1, #path - 1 do
                    local a = path[i]
                    local b = path[i + 1]
                    local d = GetDistance(a, b)
                    if d >= tDistance then
                        local direction = Normalized(b, a)
                        local cp = Extended(a, direction, tDistance)
                        local p = Extended(a, direction, (i == #path - 2) and MathMin(tDistance + Radius, d) or (tDistance + Radius))
                        return PredictionOutput({ Input = input, Hitchance = HitChance, CastPosition = cp, UnitPosition = p })
                    end
                    tDistance = tDistance - d
                end
            --------------------------------------------------------------------------------------------------------------------------------------------
            else
                local d = (input.Delay * speed) - Radius
                if input.Type == SPELLTYPE_LINE or input.Type == SPELLTYPE_CONE then
                    if IsInRange(unitPos, input.From, 200) then
                        d = input.Delay * speed
                    end
                end
                path = Core:CutPath(path, d)
                local tT = 0
                for i = 1, #path - 1 do
                    local a = path[i]
                    local b = path[i + 1]
                    local tB = GetDistance(a, b) / speed
                    local direction = Normalized(b, a)
                    if tT ~= 0 then
                        a = Extended(a, direction, -(speed * tT))
                    end
                    local t, pos = Core:VectorMovementCollision(a, b, speed, input.From, input.Speed, tT)
                    if t ~= nil and t >= tT and t <= tT + tB then
                        local p = Extended(pos, direction, Radius)
                        return PredictionOutput({ Input = input, Hitchance = HitChance, CastPosition = pos, UnitPosition = p })
                    end
                    tT = tT + tB
                end
            end
        end
        return PredictionOutput({ Input = input, Hitchance = HITCHANCE_NORMAL, CastPosition = path[#path], UnitPosition = path[#path] })
    end
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    local function GetDashingPrediction(input)
        local unit = input.Unit
        local path = Core:GetWaypoints(unit, input.UnitID)
        if #path ~= 2 then
            return PredictionOutput()
        end
        local startPos = To2D(unit.pos)
        local endPos = path[2]
        if IsInRange(startPos, endPos, 25) then
            return PredictionOutput()
        end
        local speed = unit.pathing.dashSpeed
        local interceptTime = input.Delay + Core:GetInterceptionTime(input.From, startPos, endPos, speed, input.Speed) - (input.RealRadius / unit.ms)
        local remainingTime = GetDistance(startPos, endPos) / speed
        if remainingTime + 0.1 >= interceptTime then
            local direction = Normalized(endPos, startPos)
            local castPos = Extended(startPos, direction, speed * interceptTime)
            if GetDistanceSquared(startPos, castPos) > GetDistanceSquared(startPos, endPos) then
                castPos = endPos
            end
            if remainingTime >= interceptTime then
                if DebugMode then print("IMMOBILE_DASH: speed " .. tostring(speed)) end
                return PredictionOutput({ Input = input, Hitchance = HITCHANCE_IMMOBILE, CastPosition = castPos, UnitPosition = castPos })
            end
            if DebugMode then print("HIGH_DASH: speed " .. tostring(speed)) end
            return PredictionOutput({ Input = input, Hitchance = HITCHANCE_HIGH, CastPosition = castPos, UnitPosition = castPos })
        end
        return PredictionOutput()
    end
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    local function GetImmobilePrediction(input, remainingTime)
        local pos = To2D(input.Unit.pos)
        local interceptTime = input.Delay + (GetDistance(input.From, pos) / input.Speed) - (input.RealRadius / input.Unit.ms)
        if remainingTime + 0.1 >= interceptTime then
            if remainingTime >= interceptTime then
                if DebugMode then print("IMMOBILE_STUN") end
                return PredictionOutput({ Input = input, Hitchance = HITCHANCE_IMMOBILE, CastPosition = pos, UnitPosition = pos })
            end
            if DebugMode then print("HIGH_STUN") end
            return PredictionOutput({ Input = input, Hitchance = HITCHANCE_HIGH, CastPosition = pos, UnitPosition = pos })
        end
        return PredictionOutput()
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Prediction:                                                                                                                                          
    function Prediction:__init()
        self.MaxRangeMulipier           = 1
        ------------------------------------------------------------------------------------------------------------------------------------------------
        self.HITCHANCE_IMPOSSIBLE       = 0
        self.HITCHANCE_COLLISION        = 1
        self.HITCHANCE_NORMAL           = 2
        self.HITCHANCE_HIGH             = 3
        self.HITCHANCE_IMMOBILE         = 4
        ------------------------------------------------------------------------------------------------------------------------------------------------
        self.SPELLTYPE_LINE             = 0
        self.SPELLTYPE_CIRCLE           = 1
        self.SPELLTYPE_CONE             = 2
        ------------------------------------------------------------------------------------------------------------------------------------------------
        self.menu = MenuElement({name = "Gamsteron Prediction", id = "gsopred", type = _G.MENU })
            self.menu:MenuElement({id = "PredHighAccuracy", name = "High Accuracy [ last move ms ]", value = 100, min = 25, max = 100, step = 5, callback = function(value) HighAccuracy = value * 0.001 end })
            self.menu:MenuElement({id = "PredMaxRange", name = "Max Range %", value = 100, min = 70, max = 100, step = 1, callback = function(value) self.MaxRangeMulipier = value * 0.01 end })
            self.MaxRangeMulipier = self.menu.PredMaxRange:Value() * 0.01
    end
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    function Prediction:GetPrediction(unit, args, from)
        args.Unit = unit
        args.From = from
        local input = PredictionInput(args)
        if not input.Valid then return PredictionOutput() end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local unitID = input.UnitID
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local result = nil
        ------------------------------------------------------------------------------------------------------------------------------------------------
        if unit.pathing.isDashing then
            result = GetDashingPrediction(input)
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        if result == nil then
            local data = input.UnitData
            if data.RemainingDash > 0 or GameTimer() <= data.ExpireDash then
                return PredictionOutput()
            end
            local remainingTime = MathMax(data.RemainingImmobile, data.ExpireImmobile - GameTimer())
            if remainingTime > 0 then
                result = GetImmobilePrediction(input, remainingTime)
            else
                input.Range = input.Range * self.MaxRangeMulipier
            end
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        if result == nil then
            result = GetStandardPrediction(input)
            if result.Hitchance ~= HITCHANCE_IMPOSSIBLE then
                local isOK = false
                local castPos = result.CastPosition
                local path = input.UnitData.Path
                for i = 1, #path - 1 do
                    local v1, v2 = path[i], path[i+1]
                    local isOnSegment, pointSegment, pointLine = Core:ProjectOn(castPos, v1, v2)
                    if Core:IsInRange(pointSegment, castPos, 10) then
                        isOK = true
                        break
                    end
                end
                if not isOK then
                    result.Hitchance = HITCHANCE_IMPOSSIBLE
                end
            end
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        if result.Hitchance ~= HITCHANCE_IMPOSSIBLE then
            if input.Range ~= MathHuge then
                if result.Hitchance >= HITCHANCE_HIGH and not IsInRange(input.RangeCheckFrom, To2D(unit.pos), input.Range + input.RealRadius * 3 / 4) then
                    result.Hitchance = HITCHANCE_NORMAL
                end
                if not IsInRange(input.RangeCheckFrom, result.UnitPosition, input.Range + (input.Type == SPELLTYPE_CIRCLE and input.RealRadius or 0)) then
                    result.Hitchance = HITCHANCE_IMPOSSIBLE
                end
                if not IsInRange(input.RangeCheckFrom, result.CastPosition, input.Range) then
                    if result.Hitchance > HITCHANCE_IMPOSSIBLE then
                        result.CastPosition = Extended(input.RangeCheckFrom, Normalized(result.UnitPosition, input.RangeCheckFrom), input.Range)
                    else
                        result.Hitchance = HITCHANCE_IMPOSSIBLE
                    end
                end
                if not IsInRange(result.CastPosition, To2D(myHero.pos), input.Range) then
                    result.Hitchance = HITCHANCE_IMPOSSIBLE
                end
            end
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        if result.Hitchance ~= HITCHANCE_IMPOSSIBLE then
            if input.Collision then
                local isWall, objects = Core:GetCollision(input.From, result.CastPosition, input.Speed, input.Delay, input.Radius, input.CollisionObjects, input.ObjectsList)
                if isWall or #objects > input.MaxCollision then
                    result.Hitchance = HITCHANCE_COLLISION
                end
                result.CollisionObjects = objects
            end
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        return result
    end
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    function Prediction:CastSpell(spell, unit, from, spellData, hitChance)
        if unit == nil and from == nil and spellData == nil then
            if Control.CastSpell(spell) == true then
                return true
            end
        else
            if from ~= nil and spellData ~= nil then
                hitChance = hitChance or 2
                spellData.Unit = unit
                local pred = self:GetPrediction(unit, spellData, from)
                if pred.Hitchance >= hitChance then
                    local pos = pred.CastPosition
                    if Control.CastSpell(spell, Vector(pos.x, unit.pos.y, pos.y)) == true then
                        return true
                    end
                end
            elseif Control.CastSpell(spell, unit) == true then
                return true
            end
        end
        return false
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Load:                                                                                                                                                
    _G.GamsteronPrediction = Prediction()
    _G.GamsteronPredictionLoaded = true
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Debug:                                                                                                                                               
    if DebugMode then
        local DebugDraw = true
        if DebugDraw then
            local DebugWaypoint     = false
            local DebugPrediction   = true
            --------------------------------------------------------------------------------------------------------------------------------------------
            local COLOR_WHITE       = Draw.Color(150,255,255,255)
            local COLOR_TRANSPARENT = Draw.Color(0,255,255,255)
            local COLOR_GREEN       = Draw.Color(255,0,255,0)
            --------------------------------------------------------------------------------------------------------------------------------------------
            local function DrawHack()
                Draw.Circle(myHero.pos, 1, 1, COLOR_TRANSPARENT)
            end
            --------------------------------------------------------------------------------------------------------------------------------------------
            Callback.Add('Draw', function()
                if DebugWaypoint then
                    local MyHeroID = myHero.networkID
                    --local ExtendedPosition = GamsteronPrediction:GetCastPos(MyHeroID, To2D(myHero.pos), 250)
                    if ExtendedPosition then
                        DrawHack()
                        --local DirectionTimer = GamsteronPrediction.HeroDirections[MyHeroID].Tick
                        --if GameTimer() > DirectionTimer + 0.05 and GameTimer() < DirectionTimer + 0.075 then
                            Draw.Circle(Vector(myHero.pathing.endPos), 75, 3, COLOR_WHITE)
                            Draw.Circle(Vector(ExtendedPosition.x, 0, ExtendedPosition.y), 75, 3, COLOR_WHITE)
                        --end
                    end
                end
                if DebugPrediction then
                    for i = 1, Game.HeroCount() do
                        local Hero = Game.Hero(i)
                        if Hero and Hero.isEnemy and Hero.valid and Hero.alive and not Hero.dead then
                            local args = { Delay = 0.2, Radius = 70, Range = 2000, Speed = 1800, Collision = false, Type = SPELLTYPE_LINE }
                            local pred = GamsteronPrediction:GetPrediction(myHero, args, Hero)
                            if pred.Hitchance >= HITCHANCE_HIGH then
                                local pos = Vector(pred.CastPosition.x, 0, pred.CastPosition.y)
                                DrawHack()
                                Draw.Circle(pos, 75, 3, COLOR_WHITE)
                            end
                        end
                    end
                end
            end)
            local debugOnProcessSpell = false
            if debugOnProcessSpell then
                local currentPath = {}
                local predPos = nil
                Core:OnProcessWaypoint(function(unit, args, move)
                    if move and unit.isMe then
                        for i = #currentPath, 1, -1 do
                            currentPath[i] = nil
                        end
                        for i = 1, #args.path do
                            TableInsert(currentPath, Vector(args.path[i].x, 0, args.path[i].y))
                        end
                        for i = 1, #currentPath do
                            Draw.Circle(currentPath[i], 75, 3, COLOR_WHITE)
                        end
                        for i = 1, Game.HeroCount() do
                            local Hero = Game.Hero(i)
                            if Hero and Hero.isEnemy and Hero.valid and Hero.alive and not Hero.dead and IsInRange(To2D(myHero.pos), To2D(Hero.pos), 2000) then
                                local args = { Delay = 0.2, Radius = 70, Range = 2000, Speed = 1200, Collision = false, Type = SPELLTYPE_LINE }
                                local pred = GamsteronPrediction:GetPrediction(myHero, args, Hero)
                                if pred.Hitchance >= HITCHANCE_NORMAL then
                                    local pos = Vector(pred.CastPosition.x, 0, pred.CastPosition.y)
                                    DrawHack()
                                    predPos = pos
                                    Draw.Circle(pos, 75, 3, COLOR_GREEN)
                                    TickAction(function() Draw.Circle(pos, 75, 3, COLOR_GREEN) end, 0.05)
                                end
                            end
                        end
                    end
                end)
                --[[
                local function Get2D(vec)
                    return { x = vec.x, y = vec.z or vec.y }
                end
                local function Extended(vec, dir, range)
                    if dir == nil then return vec end
                    return { x = vec.x + dir.x * range, y = vec.y + dir.y * range }
                end
                Callback.Add('Draw', function()
                    local startSegment = myHero.pos:To2D()
                    local direction = Get2D(myHero.dir)
                    local extended = Extended(Get2D(myHero.pos), direction, 250)
                    local endSegment = Vector(extended.x, myHero.pos.y, extended.y):To2D()
                    Draw.Line(startSegment.x, startSegment.y, endSegment.x, endSegment.y)
                end)
                Callback.Add('Draw', function()
                    --print(myHero.dir.x)
                    for i = 1, #currentPath do
                        --Draw.Circle(currentPath[i], 75, 3, COLOR_WHITE)
                    end
                    if predPos then
                        --Draw.Circle(predPos, 75, 3, COLOR_GREEN)
                    end
                end)]]
            end
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------
