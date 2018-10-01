--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Initialize:                                                                                                                                          
    -- Return:                                                                                                                                          
        if _G.GamsteronAIOLoaded then
            return
        end
        local SUPPORTED_CHAMPIONS =
        {
            ["Twitch"] = true,
            ["Ezreal"] = true,
            ["KogMaw"] = true,
            ["Varus"] = true,
            ["Brand"] = true,
            ["Morgana"] = true,
            ["Karthus"] = true,
            ["Vayne"] = true
        }
        if not SUPPORTED_CHAMPIONS[myHero.charName] then
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
    -- Load Prediction:                                                                                                                                       
        if _Update then
            if not FileExist(COMMON_PATH .. "GamsteronPrediction.lua") then
                DownloadFileAsync("https://raw.githubusercontent.com/gamsteron/GOS-External/master/Common/GamsteronPrediction.lua", COMMON_PATH .. "GamsteronPrediction.lua", function() end)
                while not FileExist(COMMON_PATH .. "GamsteronPrediction.lua") do end
            end
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        if _G.GamsteronPredictionUpdated then
            return
        end
	----------------------------------------------------------------------------------------------------------------------------------------------------
	-- Auto Update:                                                                                                                                     
        if _Update then
            local args =
            {
                version = 7,
                ----------------------------------------------------------------------------------------------------------------------------------------
                scriptPath = COMMON_PATH .. "GamsteronAIO.lua",
                scriptUrl = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Common/GamsteronAIO.lua",
                ----------------------------------------------------------------------------------------------------------------------------------------
                versionPath = COMMON_PATH .. "GamsteronAIO.version",
                versionUrl = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Common/GamsteronAIO.version"
            }
            --------------------------------------------------------------------------------------------------------------------------------------------
            local success, version = Core:AutoUpdate(args)
            --------------------------------------------------------------------------------------------------------------------------------------------
            if success then
                print("GamsteronAIO updated to version " .. version .. ". Please Reload with 2x F6 !")
                _G.GamsteronAIOUpdated = true
            end
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        if _G.GamsteronAIOUpdated then
            return
        end
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Locals:                                                                                                                                              
    local META
    local MENU, CHAMPION
    local INTERRUPTER, PREDICTION, ORB, TS, DMG, OB, SPELLS
	local GetTickCount					= GetTickCount
	local myHero						= myHero
	local LocalCharName					= myHero.charName
	local LocalVector					= Vector
	local LocalOsClock					= os.clock
	local LocalCallbackAdd				= Callback.Add
	local LocalCallbackDel				= Callback.Del
	local LocalDrawLine					= Draw.Line
	local LocalDrawColor				= Draw.Color
	local LocalDrawCircle				= Draw.Circle
	local LocalDrawText					= Draw.Text
	local LocalControlIsKeyDown			= Control.IsKeyDown
	local LocalControlMouseEvent		= Control.mouse_event
	local LocalControlSetCursorPos		= Control.SetCursorPos
	local LocalControlKeyUp				= Control.KeyUp
	local LocalControlKeyDown			= Control.KeyDown
	local LocalGameCanUseSpell			= Game.CanUseSpell
	local LocalGameLatency				= Game.Latency
	local LocalGameTimer				= Game.Timer
	local LocalGameParticleCount		= Game.ParticleCount
	local LocalGameParticle				= Game.Particle
	local LocalGameHeroCount 			= Game.HeroCount
	local LocalGameHero 				= Game.Hero
	local LocalGameMinionCount 			= Game.MinionCount
	local LocalGameMinion 				= Game.Minion
	local LocalGameTurretCount 			= Game.TurretCount
	local LocalGameTurret 				= Game.Turret
	local LocalGameWardCount 			= Game.WardCount
	local LocalGameWard 				= Game.Ward
	local LocalGameObjectCount 			= Game.ObjectCount
	local LocalGameObject				= Game.Object
	local LocalGameMissileCount 		= Game.MissileCount
	local LocalGameMissile				= Game.Missile
	local LocalGameIsChatOpen			= Game.IsChatOpen
	local LocalGameIsOnTop				= Game.IsOnTop
	local STATE_UNKNOWN					= STATE_UNKNOWN
	local STATE_ATTACK					= STATE_ATTACK
	local STATE_WINDUP					= STATE_WINDUP
	local STATE_WINDDOWN				= STATE_WINDDOWN
	local ITEM_1						= ITEM_1
	local ITEM_2						= ITEM_2
	local ITEM_3						= ITEM_3
	local ITEM_4						= ITEM_4
	local ITEM_5						= ITEM_5
	local ITEM_6						= ITEM_6
	local ITEM_7						= ITEM_7
	local _Q							= _Q
	local _W							= _W
	local _E							= _E
	local _R							= _R
	local MOUSEEVENTF_RIGHTDOWN			= MOUSEEVENTF_RIGHTDOWN
	local MOUSEEVENTF_RIGHTUP			= MOUSEEVENTF_RIGHTUP
	local Obj_AI_Barracks				= Obj_AI_Barracks
	local Obj_AI_Hero					= Obj_AI_Hero
	local Obj_AI_Minion					= Obj_AI_Minion
	local Obj_AI_Turret					= Obj_AI_Turret
	local Obj_HQ 						= "obj_HQ"
	local pairs							= pairs
	local LocalMathCeil					= math.ceil
	local LocalMathMax					= math.max
	local LocalMathMin					= math.min
	local LocalMathSqrt					= math.sqrt
	local LocalMathRandom				= math.random
	local LocalMathHuge					= math.huge
	local LocalMathAbs					= math.abs
	local LocalStringSub				= string.sub
	local LocalStringLen				= string.len
	local TEAM_ALLY						= myHero.team
	local TEAM_ENEMY					= 300 - TEAM_ALLY
	local TEAM_JUNGLE					= 300
    local ORBWALKER_MODE_NONE           = -1
    local ORBWALKER_MODE_COMBO          = 0
    local ORBWALKER_MODE_HARASS         = 1
    local ORBWALKER_MODE_LANECLEAR      = 2
    local ORBWALKER_MODE_JUNGLECLEAR    = 3
    local ORBWALKER_MODE_LASTHIT        = 4
    local ORBWALKER_MODE_FLEE           = 5
    local DAMAGE_TYPE_PHYSICAL			= 0
	local DAMAGE_TYPE_MAGICAL			= 1
    local DAMAGE_TYPE_TRUE				= 2
    local StunBuffs =
    {
        ["recall"]						= true,
        -- Aatrox
        ["AatroxQ"]						= true,
        ["AatroxE"]						= true,
        -- Ahri
        ["AhriSeduce"] 					= true,
        -- Alistar
        ["Pulverize"] 					= true,
        -- Amumu
        ["BandageToss"] 				= true,
        ["CurseoftheSadMummy"] 			= true,
        -- Anivia
        ["FlashFrostSpell"] 			= true,
        -- Ashe
        ["EnchantedCrystalArrow"] 		= true,
        -- Bard
        ["BardQ"] 						= true,
        -- Blitzcrank
        ["RocketGrab"] 					= true,
        -- Braum
        ["BraumQ"] 						= true,
        ["BraumRWrapper"] 				= true,
        -- Cassiopeia
        ["CassiopeiaPetrifyingGaze"]	= true,
        -- Chogath
        ["Rupture"] 					= true,
        -- Darius
        ["DariusAxeGrabCone"] 			= true,
        -- Diana
        ["DianaVortex"] 				= true,
        -- DrMundo
        ["InfectedCleaverMissileCast"] 	= true,
        -- Draven
        ["DravenDoubleShot"] 			= true,
        -- Elise
        ["EliseHumanE"] 				= true,
        -- Evelynn
        ["EvelynnR"] 					= true,
        -- FiddleSticks
        ["Terrify"] 					= true,
        -- Fizz
        ["FizzMarinerDoom"] 			= true,
        -- Galio
        ["GalioResoluteSmite"] 			= true,
        ["GalioIdolOfDurand"] 			= true,
        -- Gnar
        ["gnarbigq"] 					= true,
        ["GnarQ"] 						= true,
        ["gnarbigw"] 					= true,
        ["GnarR"] 						= true,
        -- Gragas
        ["GragasE"] 					= true,
        ["GragasR"] 					= true,
        -- Hecarim
        ["HecarimUlt"] 					= true,
        -- Heimerdinger
        ["HeimerdingerE"] 				= true,
        -- Irelia
        ["IreliaEquilibriumStrike"] 	= true,
        -- Janna
        ["HowlingGale"] 				= true,
        ["SowTheWind"] 					= true,
        -- JarvanIV
        ["JarvanIVDragonStrike2"] 		= true,
        -- Jayce
        ["JayceToTheSkies"] 			= true,
        ["JayceThunderingBlow"] 		= true,
        -- Karma
        ["KarmaQMissileMantra"] 		= true,
        ["KarmaQ"] 						= true,
        ["KarmaW"] 						= true,
        -- Kassadin
        ["ForcePulse"] 					= true,
        -- Kayle
        ["JudicatorReckoning"] 			= true,
        -- KhaZix
        ["KhazixW"] 					= true,
        ["khazixwlong"] 				= true,
        -- KogMaw
        ["KogMawVoidOoze"] 				= true,
        -- LeBlanc
        ["LeblancSoulShackle"] 			= true,
        ["LeblancSoulShackleM"] 		= true,
        -- LeeSin
        ["BlindMonkQOne"] 				= true,
        ["BlindMonkRKick"] 				= true,
        -- Leona
        ["LeonaSolarFlare"] 			= true,
        -- Lissandra
        ["LissandraW"] 					= true,
        ["LissandraR"] 					= true,
        -- Lulu
        ["LuluQ"] 						= true,
        ["LuluW"] 						= true,
        -- Lux
        ["LuxLightBinding"] 			= true,
        -- Malphite
        ["SeismicShard"] 				= true,
        ["UFSlash"] 					= true,
        -- Malzahar
        ["AlZaharNetherGrasp"] 			= true,
        -- Maokai
        ["MaokaiTrunkLine"] 			= true,
        ["MaokaiW"] 					= true,
        -- Morgana
        ["DarkBindingMissile"] 			= true,
        ["SoulShackles"] 				= true,
        ["Stun"]						= true,
        -- Nami
        ["NamiQ"] 						= true,
        ["NamiR"] 						= true,
        -- Nasus
        ["NasusW"] 						= true,
        -- Nautilus
        ["NautilusAnchorDrag"] 			= true,
        ["NautilusR"] 					= true,
        -- Nocturne
        ["NocturneUnspeakableHorror"]	= true,
        -- Nunu
        ["IceBlast"]					= true,
        -- Olaf
        ["OlafAxeThrowCast"]			= true,
        -- Orianna
        --0
        -- Pantheon
        ["PantheonW"]					= true,
        -- Poppy
        ["PoppyHeroicCharge"]			= true,
        -- Quinn
        ["QuinnQ"]						= true,
        ["QuinnE"]						= true,
        -- Rammus
        ["PuncturingTaunt"]				= true,
        -- Rengar
        ["RengarE"]						= true,
        -- Riven
        ["RivenMartyr"]					= true,
        -- Rumble
        ["RumbleGrenade"]				= true,
        -- Ryze
        ["RyzeW"]						= true,
        -- Sejuani
        ["SejuaniArcticAssault"]		= true,
        ["SejuaniGlacialPrisonCast"]	= true,
        -- Shaco
        ["TwoShivPoison"]				= true,
        -- Shen
        ["ShenShadowDash"]				= true,
        -- Shyvana
        ["ShyvanaTransformCast"]		= true,
        -- Singed
        ["Fling"]						= true,
        -- Skarner
        ["SkarnerFracture"]				= true,
        ["SkarnerImpale"]				= true,
        -- Sona
        ["SonaR"]						= true,
        -- Swain
        ["SwainQ"]						= true,
        ["SwainShadowGrasp"]			= true,
        -- Syndra
        ["syndrawcast"]					= true,
        ["SyndraE"]						= true,
        -- TahmKench
        ["TahmKenchQ"]					= true,
        ["TahmKenchE"]					= true,
        -- Taric
        ["Dazzle"]						= true,
        -- Teemo
        ["BlindingDart"]				= true,
        -- Thresh
        ["ThreshQ"]						= true,
        ["ThreshE"]						= true,
        -- Tristana
        ["TristanaR"]					= true,
        -- Tryndamere
        ["MockingShout"] 				= true,
        -- Urgot
        ["UrgotR"]						= true,
        -- Varus
        ["VarusR"]						= true,
        -- Vayne
        ["VayneCondemn"]				= true,
        -- Veigar
        ["VeigarEventHorizon"]			= true,
        -- VelKoz
        ["VelkozQMissile"]				= true,
        ["VelkozQMissileSplit"]			= true,
        ["VelkozE"]						= true,
        -- Vi
        ["ViQMissile"]					= true,
        ["ViR"]							= true,
        -- Viktor
        ["ViktorGravitonField"]			= true,
        -- Warwick
        ["InfiniteDuress"]				= true,
        -- Xerath
        ["XerathArcaneBarrage2"]		= true,
        ["XerathMageSpear"]				= true,
        -- Yasou
        ["yasuoq3w"]					= true,
        -- Zac
        ["ZacQ"]						= true,
        ["ZacE"]						= true,
        -- Ziggs
        ["ZiggsW"]						= true,
        -- Zilean
        ["ZileanQ"]						= true,
        ["TimeWarp"]					= true,
        -- Zyra
        ["ZyraGraspingRoots"]			= true,
        ["ZyraBrambleZone"]				= true
    }
	----------------------------------------------------------------------------------------------------------------------------------------------------
	-- Methods:																																			
    local function GetDistanceSquared(a, b)
        if a.pos ~= nil then
            a = a.pos
        end
        if b.pos ~= nil then
            b = b.pos
        end
        if a.z ~= nil and b.z ~= nil then
            local x = (a.x - b.x)
            local z = (a.z - b.z)
            return x * x + z * z
        else
            local x = (a.x - b.x)
            local y = (a.y - b.y)
            return x * x + y * y
        end
    end
    local function IsInRange(from, target, range)
        if range == nil then
            return true
        end
        return GetDistanceSquared(from, target) <= range * range
    end
    local function GetInterceptionTime(source, startP, endP, unitspeed, spellspeed)
        local sx = source.x
        local sy = source.z
        local ux = startP.x
        local uy = startP.z
        local dx = endP.x - ux
        local dy = endP.z - uy
        local magnitude = math.sqrt(dx * dx + dy * dy)
        dx = (dx / magnitude) * unitspeed
        dy = (dy / magnitude) * unitspeed
        local a = (dx * dx) + (dy * dy) - (spellspeed * spellspeed)
        local b = 2 * ((ux * dx) + (uy * dy) - (sx * dx) - (sy * dy))
        local c = (ux * ux) + (uy * uy) + (sx * sx) + (sy * sy) - (2 * sx * ux) - (2 * sy * uy)
        local d = (b * b) - (4 * a * c)
        if d > 0 then
            local t1 = (-b + math.sqrt(d)) / (2 * a)
            local t2 = (-b - math.sqrt(d)) / (2 * a)
            return math.max(t1, t2)
        end
        if d >= 0 and d < 0.00001 then
            return -b / (2 * a)
        end
        return 0.00001
    end
    local function CheckWall(from, to, distance)
        local pos1 = to + (to-from):Normalized() * 50
        local pos2 = pos1 + (to-from):Normalized() * (distance - 50)
        local point1 = Point(pos1.x, pos1.z)
        local point2 = Point(pos2.x, pos2.z)
        if MapPosition:intersectsWall(LineSegment(point1, point2)) or (MapPosition:inWall(point1) and MapPosition:inWall(point2)) then
            return true
        end
        return false
    end
    local function isValidTarget(obj, range)
        range = range or math.huge
        return obj ~= nil and obj.valid and obj.visible and not obj.dead and obj.isTargetable and not obj.isImmortal and obj.distance <= range
    end
    local function CountObjectsNearPos(pos, range, radius, objects)
        local n = 0
        for i, object in pairs(objects) do
            if GetDistanceSquared(pos, object.pos) <= radius * radius then
                n = n + 1
            end
        end
        return n
    end
    local function GetBestCircularFarmPosition(range, radius, objects)
        local BestPos 
        local BestHit = 0
        for i, object in pairs(objects) do
            local hit = CountObjectsNearPos(object.pos, range, radius, objects)
            if hit > BestHit then
                BestHit = hit
                BestPos = object.pos
                if BestHit == #objects then
                    break
                end
            end
        end
        return BestPos, BestHit
    end
    local function IsBeforeAttack(multipier)
        if GameTimer() > ORB.AttackLocalStart + multipier * myHero.attackData.animationTime then
            return true
        else
            return false
        end
    end
    local function GetBuffDuration(unit, bName)
        bName = bName:lower()
        for i = 0, unit.buffCount do
            local buff = unit:GetBuff(i)
            if buff and buff.count > 0 and buff.name:lower() == bName then
                return buff.duration
            end
        end
        return 0
    end
    local function IsImmobile(unit, delay)
        for i = 0, unit.buffCount do
            local buff = unit:GetBuff(i)
            if buff and buff.count > 0 and buff.duration > delay and StunBuffs[buff.name] then
                return true
            end
        end
        return false
    end
    local function IsSlowed(unit, delay)
        for i = 0, unit.buffCount do
            local buff = unit:GetBuff(i)
            if from and buff.count > 0 and buff.type == 10 and buff.duration >= delay then
                return true
            end
        end
        return false
    end
    local function HasBuff(unit, bName)
        bName = bName:lower()
        for i = 0, unit.buffCount do
            local buff = unit:GetBuff(i)
            if buff and buff.count > 0 and buff.name:lower() == bName then
                return true
            end
        end
        return false
    end
    local function GetBuffCount(unit, bName)
        bName = bName:lower()
        for i = 0, unit.buffCount do
            local buff = unit:GetBuff(i)
            if buff and buff.count > 0 and buff.name:lower() == bName then
                return buff.count
            end
        end
        return 0
    end
    local function GetClosestEnemy(enemyList, maxDistance)
        local result = nil
        for i = 1, #enemyList do
            local hero = enemyList[i]
            local distance = myHero.pos:DistanceTo(hero.pos)
            if distance < maxDistance then
                maxDistance = distance
                result = hero
            end
        end
        return result
    end
    local function ImmobileTime(unit)
        local iT = 0
        for i = 0, unit.buffCount do
            local buff = unit:GetBuff(i)
            if buff and buff.count > 0 then
                local bType = buff.type
                if bType == 5 or bType == 11 or bType == 21 or bType == 22 or bType == 24 or bType == 29 or buff.name == "recall" then
                    local bDuration = buff.duration
                    if bDuration > iT then
                        iT = bDuration
                    end
                end
            end
        end
        return iT
    end
    local function GetImmobileEnemy(enemyList, maxDistance)
        local result = nil
        local num = 0
        for i = 1, #enemyList do
            local hero = enemyList[i]
            local distance = myHero.pos:DistanceTo(hero.pos)
            local iT = ImmobileTime(hero)
            if distance < maxDistance and iT > num then
                num = iT
                result = hero
            end
        end
        return result
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants:                                                                                                                                           
    local HITCHANCE_IMPOSSIBLE      = 0
    local HITCHANCE_COLLISION       = 1
    local HITCHANCE_NORMAL          = 2
    local HITCHANCE_HIGH            = 3
    local HITCHANCE_IMMOBILE        = 4
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    local SPELLTYPE_LINE            = 0
    local SPELLTYPE_CIRCLE          = 1
    local SPELLTYPE_CONE            = 2
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    local COLLISION_MINION          = 0
    local COLLISION_ALLYHERO        = 1
    local COLLISION_ENEMYHERO       = 2
    local COLLISION_YASUOWALL       = 3
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Champions:                                                                                                                                           
    META =
    {
        Interrupter = function()
            local c = {}
            local result =
            {
                Loaded = true,
                Callback = {},
                Spells = {
                    ["CaitlynAceintheHole"] = true,
                    ["Crowstorm"] = true,
                    ["DrainChannel"] = true,
                    ["GalioIdolOfDurand"] = true,
                    ["ReapTheWhirlwind"] = true,
                    ["KarthusFallenOne"] = true,
                    ["KatarinaR"] = true,
                    ["LucianR"] = true,
                    ["AlZaharNetherGrasp"] = true,
                    ["Meditate"] = true,
                    ["MissFortuneBulletTime"] = true,
                    ["AbsoluteZero"] = true,
                    ["PantheonRJump"] = true,
                    ["PantheonRFall"] = true,
                    ["ShenStandUnited"] = true,
                    ["Destiny"] = true,
                    ["UrgotSwap2"] = true,
                    ["VelkozR"] = true,
                    ["InfiniteDuress"] = true,
                    ["XerathLocusOfPower2"] = true
                }
            }
            -- [ init ]
                c.__index = c
                setmetatable(result, c)
            function c:Tick()
                local enemyList = OB:GetEnemyHeroes(1500, false, 0)
                for i = 1, #enemyList do
                    local enemy = enemyList[i]
                    local activeSpell = enemy.activeSpell
                    if activeSpell and activeSpell.valid and self.Spells[activeSpell.name] and activeSpell.isChanneling and activeSpell.castEndTime - LocalGameTimer() > 0.33 then
                        for j = 1, #self.Callback do
                            self.Callback[j](enemy, activeSpell)
                        end
                    end
                end
            end
            return result
        end,
        Prediction = function()
            -- [ test dashSpell ]
            --local cc= 0
            --if myHero.activeSpell and myHero.activeSpell.valid then cc = cc + 1; print('ok '..cc); print(myHero.activeSpell.name) end
            --if myHero.pathing.isDashing then print(cc.. " dash") end
            local c = {}
            local result =
            {
                DashSpell =
                {
                    ["sionr"] = true,
                    ["warwickr"] = true,
                    ["vir"] = true,
                    ["tristanaw"] = true,
                    ["shyvanatransformleap"] = true,
                    ["powerball"] = true,
                    ["leonazenithblade"] = true,
                    ["galioe"] = true,
                    ["galior"] = true,
                    ["blindmonkqone"] = true,
                    ["alphastrike"] = true,
                    ["nautilusanchordragmissile"] = true,
                    ["caitlynentrapment"] = true,
                    ["bandagetoss"] = true,
                    ["ekkoeattack"] = true,
                    ["ekkor"] = true,
                    ["evelynne"] = true,
                    ["evelynne2"] = true,
                    ["evelynnr"] = true,
                    ["ezrealarcaneshift"] = true,
                    ["crowstorm"] = true,
                    ["tahmkenchnewr"] = true,
                    ["shenr"] = true,
                    ["graveschargeshot"] = true,
                    ["jarvanivdragonstrike"] = true,
                    ["hecarimrampattack"] = true,
                    ["illaoiwattack"] = true,
                    ["riftwalk"] = true,
                    ["katarinae"] = true,
                    ["pantheonrjump"] = true
                    -- taliyahr
                    -- reksair
                    -- kled ?
                    -- rakanq, rakanr
                    -- sejuaniq ?
                    -- zace
                    -- zoe ?
                    -- kalistaq
                    -- eliseq ?
                    -- aurelionsol ?
                },
                Waypoints =
                {
                }
            }
            -- [ init ]
                c.__index = c
                setmetatable(result, c)
            function c:GetWaypoints(unit)
                local path = unit.pathing
                return { IsMoving = path.hasMovePath, Path = path.endPos, Tick = LocalGameTimer() }
            end
            function c:SaveWaypointsSingle(unit)
                local unitID = unit.networkID
                if not self.Waypoints[unitID] then
                    self.Waypoints[unitID] = self:GetWaypoints(unit)
                    return
                end
                local currentWaypoints = self:GetWaypoints(unit)
                local currentWaypointsT = self.Waypoints[unitID]
                if currentWaypoints.IsMoving ~= currentWaypointsT.IsMoving then
                    self.Waypoints[unitID] = currentWaypoints
                    return
                end
                if currentWaypoints.IsMoving then
                    local xx = currentWaypoints.Path.x
                    local zz = currentWaypoints.Path.z
                    local xxT = currentWaypointsT.Path.x
                    local zzT = currentWaypointsT.Path.z
                    if xx ~= xxT or zz ~= zzT then
                        self.Waypoints[unitID] = currentWaypoints
                    end
                end
            end
            function c:SaveWaypoints(enemyList)
                for i = 1, #enemyList do
                    local unit = enemyList[i]
                    self:SaveWaypointsSingle(unit)
                end
            end
            function c:ClosestPointOnLineSegment(p, p1, p2)
                --local px,pz,py = p.x, p.z, p.y
                --local ax,az,ay = p1.x, p1.z, p1.y
                --local bx,bz,by = p2.x, p2.z, p2.y
                local px,pz = p.x, p.z
                local ax,az = p1.x, p1.z
                local bx,bz = p2.x, p2.z
                local bxax = bx - ax
                local bzaz = bz - az
                --local byay = by - by
                --local t = ((px - ax) * bxax + (pz - az) * bzaz + (py - ay) * byay) / (bxax * bxax + bzaz * bzaz + byay * byay)
                local t = ((px - ax) * bxax + (pz - az) * bzaz) / (bxax * bxax + bzaz * bzaz)
                if t < 0 then
                    return p1, false
                elseif t > 1 then
                    return p2, false
                else
                    return { x = ax + t * bxax, z = az + t * bzaz }, true
                    --return Vector({ x = ax + t * bxax, z = az + t * bzaz, y = ay + t * byay }), true
                end
            end
            function c:IsMinionCollision(unit, spellData, prediction)
                local width = spellData.radius * 0.77
                local enemyMinions = OB:GetEnemyMinions(2000, false)
                local mePos = myHero.pos
                for i = 1, #enemyMinions do
                    local minion = enemyMinions[i]
                    if minion ~= unit then
                        local bbox = minion.boundingRadius
                        local predWidth = width + bbox + 20
                        local minionPos = minion.pos
                        local predPos
                        if prediction then
                            predPos = unit:GetPrediction(spellData.speed,spellData.delay)
                        else
                            predPos = unit.pos
                        end
                        local point,onLineSegment = self:ClosestPointOnLineSegment(minionPos, predPos, myHero.pos)
                        local x = minionPos.x - point.x
                        local z = minionPos.z - point.z
                        if onLineSegment and x * x + z * z < predWidth * predWidth then
                            return true
                        end
                        local mPathing = minion.pathing
                        if mPathing.hasMovePath then
                            local minionPosPred = minionPos:Extended(mPathing.endPos, spellData.delay + (mePos:DistanceTo(minionPos) / spellData.speed))
                            point,onLineSegment = self:ClosestPointOnLineSegment(minionPosPred, predPos, myHero.pos)
                            local xx = minionPosPred.x - point.x
                            local zz = minionPosPred.z - point.z
                            if onLineSegment and xx * xx + zz * zz < predWidth * predWidth then
                                return true
                            end
                        end
                    end
                end
                return false
            end
            function c:IsCollision(unit, spellData)
                if unit:GetCollision(spellData.radius, spellData.speed, spellData.delay) > 0 or self:IsMinionCollision(unit, spellData) or self:IsMinionCollision(unit, spellData, true) then
                    return true
                end
                return false
            end
            function c:GetPrediction(unit, from, spellData)
                local CastPos
                local hitChance = 1
                local unitPos = unit.pos
                local unitID = unit.networkID
                self:SaveWaypointsSingle(unit)
                local radius = spellData.radius
                local speed = spellData.speed
                local sType = spellData.sType
                local collision = spellData.collision
                local range = spellData.range - 35
                if sType == "line" and radius > 0 then
                    range = range - radius * 0.5
                end
                local interceptionTime
                if speed < 10000 then
                    interceptionTime = GetInterceptionTime(from, unitPos, unit.pathing.endPos, unit.ms, speed)
                else
                    interceptionTime = 0
                end
                local latency = Core:GetLatency()
                local delay = spellData.delay + interceptionTime
                local fromToUnit = from:DistanceTo(unitPos) / speed
                if collision and self:IsCollision(unit, spellData) then
                    return false
                end
                if unit.pathing.isDashing then
                    return false
                end
                local isCastingSpell = unit.activeSpell and unit.activeSpell.valid
                if isCastingSpell and self.DashSpell[unit.activeSpell.name:lower()] then
                    return false
                end
                local isImmobile = IsImmobile(unit, 0)
                if unit.pathing.hasMovePath and self.Waypoints[unitID].IsMoving and not isImmobile and not isCastingSpell then
                    local endPos = unit.pathing.endPos
                    local UnitEnd = GetDistanceSquared(unitPos, endPos)
                    if LocalGameTimer() - self.Waypoints[unitID].Tick < 0.175 or LocalGameTimer() - self.Waypoints[unitID].Tick > 1.25 or UnitEnd > 4000000 or from:AngleBetween(unitPos, endPos) < 25 or IsSlowed(unit, delay + fromToUnit) then
                        hitChance = 2
                    end
                    if radius > 0 then
                        CastPos = unit:GetPrediction(math.huge,delay):Extended(unitPos, radius * 0.5)
                    else
                        CastPos = unit:GetPrediction(math.huge,delay)
                    end
                elseif isImmobile or isCastingSpell then
                    CastPos = unit.pos
                    if IsImmobile(unit, delay + fromToUnit - 0.1) or (isCastingSpell and unit.activeSpell.castEndTime - LocalGameTimer() > 0.15) then
                        hitChance = 2
                    end
                elseif not unit.pathing.hasMovePath and not self.Waypoints[unitID].IsMoving and LocalGameTimer() - self.Waypoints[unitID].Tick > 0.77 then
                    CastPos = unit.pos
                end
                if not CastPos or not CastPos:ToScreen().onScreen then
                    return false
                end
                if GetDistanceSquared(from, CastPos) > range * range then
                    return false
                end
                return CastPos, hitChance
            end
            function c:CastSpell(spell, unit, from, spellData, hitChance)
                local result2 = false
                if unit == nil and from == nil and spellData == nil and hitChance == nil then
                    if Control.CastSpell(spell) == true then
                        result2 = true
                    end
                else
                    local CastPos, HitChance
                    if from ~= nil and spellData ~= nil and hitChance ~= nil then
                        CastPos, HitChance = PREDICTION:GetPrediction(unit, from, spellData)
                        if not CastPos then return false end
                        if HitChance >= hitChance and Control.CastSpell(spell, CastPos) == true then
                            result2 = true
                        end
                    elseif Control.CastSpell(spell, unit) == true then
                        result2 = true
                    end
                end
                if result2 then
                    if spell == HK_Q then
                        SPELLS.LastQ = LocalGameTimer()
                    elseif spell == HK_W then
                        SPELLS.LastW = LocalGameTimer()
                    elseif spell == HK_E then
                        SPELLS.LastE = LocalGameTimer()
                    elseif spell == HK_R then
                        SPELLS.LastR = LocalGameTimer()
                    end
                end
                return result2
            end
            return result
        end,
        Prediction2 = function()
            -- init
                require('GamsteronPrediction')
                local c = {}
                local result = { p = _G.GamsteronPrediction }
                c.__index = c
                setmetatable(result, c)
            function c:CastSpell(spell, unit, from, spellData, hitChance)
                local result2 = false
                if unit == nil and from == nil and spellData == nil and hitChance == nil then
                    if Control.CastSpell(spell) == true then
                        result2 = true
                    end
                else
                    if from ~= nil and spellData ~= nil and hitChance ~= nil then
                        spellData.Unit = unit
                        local pred = self.p:GetPrediction(unit, spellData)
                        if pred.Hitchance >= HITCHANCE_HIGH then
                            local pos = pred.CastPosition
                            if Control.CastSpell(spell, Vector(pos.x, unit.pos.y, pos.y)) == true then
                                result2 = true
                            end
                        end
                    elseif Control.CastSpell(spell, unit) == true then
                        result2 = true
                    end
                end
                if result2 then
                    if spell == HK_Q then
                        SPELLS.LastQ = LocalGameTimer()
                    elseif spell == HK_W then
                        SPELLS.LastW = LocalGameTimer()
                    elseif spell == HK_E then
                        SPELLS.LastE = LocalGameTimer()
                    elseif spell == HK_R then
                        SPELLS.LastR = LocalGameTimer()
                    end
                end
                return result2
            end
            function c:IsMinionCollision(unit, spellData)
                local width = spellData.Radius * 0.77
                local enemyMinions = OB:GetEnemyMinions(2000, false)
                local mePos = myHero.pos
                for i = 1, #enemyMinions do
                    local minion = enemyMinions[i]
                    if minion ~= unit then
                        local bbox = minion.boundingRadius
                        local predWidth = width + bbox + 20
                        local minionPos = minion.pos
                        local predPos = unit.pos
                        local point,onLineSegment = self:ClosestPointOnLineSegment(minionPos, predPos, myHero.pos)
                        local x = minionPos.x - point.x
                        local z = minionPos.z - point.z
                        if onLineSegment and x * x + z * z < predWidth * predWidth then
                            return true
                        end
                        local mPathing = minion.pathing
                        if mPathing.hasMovePath then
                            local minionPosPred = minionPos:Extended(mPathing.endPos, spellData.Delay + (mePos:DistanceTo(minionPos) / spellData.Speed))
                            point,onLineSegment = self:ClosestPointOnLineSegment(minionPosPred, predPos, myHero.pos)
                            local xx = minionPosPred.x - point.x
                            local zz = minionPosPred.z - point.z
                            if onLineSegment and xx * xx + zz * zz < predWidth * predWidth then
                                return true
                            end
                        end
                    end
                end
                return false
            end
            function c:ClosestPointOnLineSegment(p, p1, p2)
                --local px,pz,py = p.x, p.z, p.y
                --local ax,az,ay = p1.x, p1.z, p1.y
                --local bx,bz,by = p2.x, p2.z, p2.y
                local px,pz = p.x, p.z
                local ax,az = p1.x, p1.z
                local bx,bz = p2.x, p2.z
                local bxax = bx - ax
                local bzaz = bz - az
                --local byay = by - by
                --local t = ((px - ax) * bxax + (pz - az) * bzaz + (py - ay) * byay) / (bxax * bxax + bzaz * bzaz + byay * byay)
                local t = ((px - ax) * bxax + (pz - az) * bzaz) / (bxax * bxax + bzaz * bzaz)
                if t < 0 then
                    return p1, false
                elseif t > 1 then
                    return p2, false
                else
                    return { x = ax + t * bxax, z = az + t * bzaz }, true
                    --return Vector({ x = ax + t * bxax, z = az + t * bzaz, y = ay + t * byay }), true
                end
            end
            return result
        end,
        Twitch = function()
            local c = {}
            local result =
            {
                HasQBuff = false,
                QBuffDuration = 0,
                HasQASBuff = false,
                QASBuffDuration = 0,
                Recall = true,
                EBuffs = {},
                WData = { Delay = 0.25, Radius = 50, Range = 950, Speed = 1400, Collision = false, Type = SPELLTYPE_CIRCLE }
            }
            -- init
                c.__index = c
                setmetatable(result, c)
            function c:Menu()
                MENU = MenuElement({name = "Gamsteron Twitch", id = "gsotwitch", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/twitch.png" })
                    MENU:MenuElement({name = "Q settings", id = "qset", type = _G.MENU })
                        MENU.qset:MenuElement({id = "combo", name = "Use Q Combo", value = false})
                        MENU.qset:MenuElement({id = "harass", name = "Use Q Harass", value = false})
                        MENU.qset:MenuElement({id = "recallkey", name = "Invisible Recall Key", key = string.byte("T"), value = false, toggle = true})
                        MENU.qset.recallkey:Value(false)
                        MENU.qset:MenuElement({id = "note1", name = "Note: Key should be diffrent than recall key", type = SPACE})
                    MENU:MenuElement({name = "W settings", id = "wset", type = _G.MENU })
                        MENU.wset:MenuElement({id = "stopq", name = "Stop if Q invisible", value = true})
                        MENU.wset:MenuElement({id = "stopwult", name = "Stop if R", value = false})
                        MENU.wset:MenuElement({id = "combo", name = "Use W Combo", value = true})
                        MENU.wset:MenuElement({id = "harass", name = "Use W Harass", value = false})
                        MENU.wset:MenuElement({id = "hitchance", name = "Hitchance", value = 1, drop = { "normal", "high" } })
                    MENU:MenuElement({name = "E settings", id = "eset", type = _G.MENU })
                        MENU.eset:MenuElement({id = "combo", name = "Use E Combo", value = true})
                        MENU.eset:MenuElement({id = "harass", name = "Use E Harass", value = false})
                        MENU.eset:MenuElement({id = "killsteal", name = "Use E KS", value = true})
                        MENU.eset:MenuElement({id = "stacks", name = "X stacks", value = 6, min = 1, max = 6, step = 1 })
                        MENU.eset:MenuElement({id = "enemies", name = "X enemies", value = 1, min = 1, max = 5, step = 1 })
                    MENU:MenuElement({name = "R settings", id = "rset", type = _G.MENU })
                        MENU.rset:MenuElement({id = "combo", name = "Use R Combo", value = true})
                        MENU.rset:MenuElement({id = "harass", name = "Use R Harass", value = false})
                        MENU.rset:MenuElement({id = "xenemies", name = "x - enemies", value = 3, min = 1, max = 5, step = 1 })
                        MENU.rset:MenuElement({id = "xrange", name = "x - distance", value = 750, min = 300, max = 1500, step = 50 })
                    MENU:MenuElement({name = "Drawings", id = "draws", type = _G.MENU })
                        MENU.draws:MenuElement({id = "enabled", name = "Enabled", value = true})
                        MENU.draws:MenuElement({name = "Q Timer",  id = "qtimer", type = _G.MENU})
                            MENU.draws.qtimer:MenuElement({id = "enabled", name = "Enabled", value = true})
                            MENU.draws.qtimer:MenuElement({id = "color", name = "Color ", color = Draw.Color(200, 65, 255, 100)})
                        MENU.draws:MenuElement({name = "Q Invisible Range",  id = "qinvisible", type = _G.MENU})
                            MENU.draws.qinvisible:MenuElement({id = "enabled", name = "Enabled", value = true})
                            MENU.draws.qinvisible:MenuElement({id = "color", name = "Color ", color = Draw.Color(200, 255, 0, 0)})
                        MENU.draws:MenuElement({name = "Q Notification Range",  id = "qnotification", type = _G.MENU})
                            MENU.draws.qnotification:MenuElement({id = "enabled", name = "Enabled", value = true})
                            MENU.draws.qnotification:MenuElement({id = "color", name = "Color ", color = Draw.Color(200, 188, 77, 26)})
            end
            function c:Tick()
                --[[q buff best orbwalker dps
                if gsoGetTickCount() - gsoSpellTimers.lqk < 500 and gsoGetTickCount() > champInfo.lastASCheck + 1000 then
                champInfo.asNoQ = gsoMyHero.attackSpeed
                champInfo.windUpNoQ = gsoTimers.windUpTime
                champInfo.lastASCheck = gsoGetTickCount()
                end--]]
                --[[disable attack
                local num = 1150 - (gsoGetTickCount() - (gsoSpellTimers.lqk + (gsoExtra.maxLatency*1000)))
                if num < (gsoTimers.windUpTime*1000)+50 and num > - 50 then
                return false
                end--]]
                --qrecall
                if MENU.qset.recallkey:Value() == self.Recall then
                    LocalControlKeyDown(HK_Q)
                    LocalControlKeyUp(HK_Q)
                    LocalControlKeyDown(string.byte("B"))
                    LocalControlKeyUp(string.byte("B"))
                    self.Recall = not self.Recall
                end
                --qbuff
                local qDuration = GetBuffDuration(myHero, "globalcamouflage")--twitchhideinshadows
                self.HasQBuff = qDuration > 0
                if qDuration > 0 then
                    self.QBuffDuration = Game.Timer() + qDuration
                else
                    self.QBuffDuration = 0
                end
                --qasbuff
                local qasDuration = GetBuffDuration(myHero, "twitchhideinshadowsbuff")
                self.HasQASBuff = qasDuration > 0
                if qasDuration > 0 then
                    self.QASBuffDuration = Game.Timer() + qasDuration
                else
                    self.QASBuffDuration = 0
                end
                --handle e buffs
                local enemyList = OB:GetEnemyHeroes(1200, false, 0)
                for i = 1, #enemyList do
                    local hero  = enemyList[i]
                    local nID   = hero.networkID
                    if not self.EBuffs[nID] then
                        self.EBuffs[nID] = { count = 0, durT = 0 }
                    end
                    if not hero.dead then
                        local hasB = false
                        local cB = self.EBuffs[nID].count
                        local dB = self.EBuffs[nID].durT
                        for i = 0, hero.buffCount do
                            local buff = hero:GetBuff(i)
                            if buff and buff.count > 0 and buff.name:lower() == "twitchdeadlyvenom" then
                                hasB = true
                                if cB < 6 and buff.duration > dB then
                                    self.EBuffs[nID].count = cB + 1
                                    self.EBuffs[nID].durT = buff.duration
                                else
                                    self.EBuffs[nID].durT = buff.duration
                                end
                                break
                            end
                        end
                        if not hasB then
                            self.EBuffs[nID].count = 0
                            self.EBuffs[nID].durT = 0
                        end
                    end
                end
                -- Combo / Harass
                if ORB:IsAutoAttacking() then
                    return
                end
                --EKS
                if MENU.eset.killsteal:Value() and SPELLS:IsReady(_E, { q = 0, w = 0.25, e = 0.5, r = 0 } ) then
                    for i = 1, #enemyList do
                        local hero = enemyList[i]
                        local buffCount
                        if self.EBuffs[hero.networkID] then
                            buffCount = self.EBuffs[hero.networkID].count
                        else
                            buffCount = 0
                        end
                        if buffCount > 0 and myHero.pos:DistanceTo(hero.pos) < 1200 - 35 then
                            local elvl = myHero:GetSpellData(_E).level
                            local basedmg = 10 + ( elvl * 10 )
                            local perstack = ( 10 + (5*elvl) ) * buffCount
                            local bonusAD = myHero.bonusDamage * 0.25 * buffCount
                            local bonusAP = myHero.ap * 0.2 * buffCount
                            local edmg = basedmg + perstack + bonusAD + bonusAP
                            if DMG:CalculateDamage(myHero, hero, DAMAGE_TYPE_PHYSICAL, edmg) >= hero.health + (1.5*hero.hpRegen) and PREDICTION:CastSpell(HK_E) then
                                break
                            end
                        end
                    end
                end
                local isCombo = ORB.Modes[ORBWALKER_MODE_COMBO]
                local isHarass = ORB.Modes[ORBWALKER_MODE_HARASS]
                if isCombo or isHarass then
                    -- R
                    if ((isCombo and MENU.rset.combo:Value()) or (isHarass and MENU.rset.harass:Value())) and SPELLS:IsReady(_R, { q = 1, w = 0.33, e = 0.33, r = 0.5 } ) and #OB:GetEnemyHeroes(MENU.rset.xrange:Value(), false, 1) >= MENU.rset.xenemies:Value() and PREDICTION:CastSpell(HK_R) then
                        return
                    end
                    -- [ get combo target ]
                    local target = TS:GetComboTarget()
                    if target and ORB:CanAttack() then
                        return
                    end
                    -- Q
                    if ((isCombo and MENU.qset.combo:Value()) or (isHarass and MENU.qset.harass:Value())) and target and SPELLS:IsReady(_Q, { q = 0.5, w = 0.33, e = 0.33, r = 0.1 } ) and PREDICTION:CastSpell(HK_Q) then
                        return
                    end
                    --W
                    if ((isCombo and MENU.wset.combo:Value())or(isHarass and MENU.wset.harass:Value())) and not(MENU.wset.stopwult:Value() and Game.Timer() < lastRk + 5.45) and not(MENU.wset.stopq:Value() and self.HasQBuff) and SPELLS:IsReady(_W, { q = 0, w = 0.5, e = 0.25, r = 0 } ) then
                        if target then
                            WTarget = target
                        else
                            WTarget = TS:GetTarget(OB:GetEnemyHeroes(950, false, 0), 0)
                        end
                        if WTarget and PREDICTION:CastSpell(HK_W, WTarget, myHero.pos, self.WData, MENU.wset.hitchance:Value()) then
                            return
                        end
                    end
                    --E
                    if ((ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.eset.combo:Value())or(ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.eset.harass:Value())) and SPELLS:IsReady(_E, { q = 0, w = 0.25, e = 0.5, r = 0 } ) then
                        local countE = 0
                        local xStacks = MENU.eset.stacks:Value()
                        local enemyList = OB:GetEnemyHeroes(1200, false, 0)
                        for i = 1, #enemyList do
                            local hero = enemyList[i]
                            local buffCount
                            if self.EBuffs[hero.networkID] then
                                buffCount = self.EBuffs[hero.networkID].count
                            else
                                buffCount = 0
                            end
                            if hero and myHero.pos:DistanceTo(hero.pos) < 1200 - 35 and buffCount >= xStacks then
                                countE = countE + 1
                            end
                        end
                        if countE >= MENU.eset.enemies:Value() and PREDICTION:CastSpell(HK_E) then
                            return
                        end
                    end
                end
            end
            function c:Draw()
                local lastQ, lastQk, lastW, lastWk, lastE, lastEk, lastR, lastRk = SPELLS:GetLastSpellTimers()
                if Game.Timer() < lastQk + 16 then
                    local pos2D = myHero.pos:To2D()
                    local posX = pos2D.x - 50
                    local posY = pos2D.y
                    local num1 = 1.35-(Game.Timer()-lastQk)
                    local timerEnabled = MENU.draws.qtimer.enabled:Value()
                    local timerColor = MENU.draws.qtimer.color:Value()
                    if num1 > 0.001 then
                        if timerEnabled then
                            local str1 = tostring(math.floor(num1*1000))
                            local str2 = ""
                            for i = 1, #str1 do
                                if #str1 <=2 then
                                    str2 = 0
                                    break
                                end
                                local char1
                                if i <= #str1-2 then
                                    char1 = str1:sub(i,i)
                                else
                                    char1 = "0"
                                end
                                str2 = str2..char1
                            end
                            Draw.Text(str2, 50, posX+50, posY-15, timerColor)
                        end
                    elseif self.HasQBuff then
                        local num2 = math.floor(1000*(self.QBuffDuration-Game.Timer()))
                        if num2 > 1 then
                            if MENU.draws.qinvisible.enabled:Value() then
                                Draw.Circle(myHero.pos, 500, 1, MENU.draws.qinvisible.color:Value())
                            end
                            if MENU.draws.qnotification.enabled:Value() then
                                Draw.Circle(myHero.pos, 800, 1, MENU.draws.qnotification.color:Value())
                            end
                            if timerEnabled then
                                local str1 = tostring(num2)
                                local str2 = ""
                                for i = 1, #str1 do
                                    if #str1 <=2 then
                                        str2 = 0
                                        break
                                    end
                                    local char1
                                    if i <= #str1-2 then
                                        char1 = str1:sub(i,i)
                                    else
                                        char1 = "0"
                                    end
                                    str2 = str2..char1
                                end
                                Draw.Text(str2, 50, posX+50, posY-15, timerColor)
                            end
                        end
                    end
                end
            end
            function c:PreAttack(args)
                local isCombo = ORB.Modes[ORBWALKER_MODE_COMBO]
                local isHarass = ORB.Modes[ORBWALKER_MODE_HARASS]
                if isCombo or isHarass then
                    -- R
                    if (isCombo and MENU.rset.combo:Value()) or (isHarass and MENU.rset.harass:Value()) then
                        if SPELLS:IsReady(_R, { q = 1, w = 0.33, e = 0.33, r = 0.5 } ) and #OB:GetEnemyHeroes(MENU.rset.xrange:Value(), false, 1) >= MENU.rset.xenemies:Value() and PREDICTION:CastSpell(HK_R) then
                            return
                        end
                    end
                end
            end
            function c:CanMove()
                if not SPELLS:CheckSpellDelays({ q = 0, w = 0.2, e = 0.2, r = 0 }) then
                    return false
                end
                return true
            end
            function c:CanAttack()
                if not SPELLS:CheckSpellDelays({ q = 0, w = 0.33, e = 0.33, r = 0 }) then
                    return false
                end
                return true
            end
            return result
        end,
        Morgana = function()
            local c = {}
            local result =
            {
                QData = { Delay = 0.25, Radius = 70, Range = 1175, Speed = 1200, Collision = true, Type = SPELLTYPE_LINE },
                WData = { Range = 900, Radius = 275 },
                EData = { Range = 800 },
                RData = { Range = 625 }
            }
            -- init
                c.__index = c
                setmetatable(result, c)
            function c:Menu()
                MENU = MenuElement({name = "Gamsteron Morgana", id = "gsomorgana", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/morganads83fd.png" })
                    -- Q
                    MENU:MenuElement({name = "Q settings", id = "qset", type = _G.MENU })
                        -- Disable Attack
                        MENU.qset:MenuElement({id = "disaa", name = "Disable attack if ready or almostReady", value = false})
                        -- KS
                        MENU.qset:MenuElement({name = "KS", id = "killsteal", type = _G.MENU })
                            MENU.qset.killsteal:MenuElement({id = "enabled", name = "Enabled", value = false})
                            MENU.qset.killsteal:MenuElement({id = "minhp", name = "minimum enemy hp", value = 200, min = 1, max = 300, step = 1})
                            MENU.qset.killsteal:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "normal", "high" } })
                        -- Auto
                        MENU.qset:MenuElement({name = "Auto", id = "auto", type = _G.MENU })
                            MENU.qset.auto:MenuElement({id = "enabled", name = "Enabled", value = true})
                            MENU.qset.auto:MenuElement({name = "Use on:", id = "useon", type = _G.MENU })
                                Core:OnEnemyHeroLoad(function(hero) MENU.qset.auto.useon:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
                            MENU.qset.auto:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "normal", "high" } })
                        -- Combo / Harass
                        MENU.qset:MenuElement({name = "Combo / Harass", id = "comhar", type = _G.MENU })
                            MENU.qset.comhar:MenuElement({id = "combo", name = "Combo", value = true})
                            MENU.qset.comhar:MenuElement({id = "harass", name = "Harass", value = false})
                            MENU.qset.comhar:MenuElement({name = "Use on:", id = "useon", type = _G.MENU })
                                Core:OnEnemyHeroLoad(function(hero) MENU.qset.comhar.useon:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
                            MENU.qset.comhar:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "normal", "high" } })
                    -- W
                    MENU:MenuElement({name = "W settings", id = "wset", type = _G.MENU })
                        -- KS
                        MENU.wset:MenuElement({name = "KS", id = "killsteal", type = _G.MENU })
                            MENU.wset.killsteal:MenuElement({id = "enabled", name = "Enabled", value = false})
                            MENU.wset.killsteal:MenuElement({id = "minhp", name = "minimum enemy hp", value = 200, min = 1, max = 300, step = 1})
                        -- Auto
                        MENU.wset:MenuElement({name = "Auto", id = "auto", type = _G.MENU })
                            MENU.wset.auto:MenuElement({id = "enabled", name = "Enabled", value = true})
                            MENU.wset.auto:MenuElement({id = "slow", name = "Slow", value = false})
                            MENU.wset.auto:MenuElement({id = "immobile", name = "Immobile", value = true})
                            MENU.wset.auto:MenuElement({id = "time", name = "Minimum milliseconds", value = 500, min = 250, max = 2000, step = 50})
                        -- Combo / Harass
                        MENU.wset:MenuElement({name = "Combo / Harass", id = "comhar", type = _G.MENU })
                            MENU.wset.comhar:MenuElement({id = "combo", name = "Use W Combo", value = false})
                            MENU.wset.comhar:MenuElement({id = "harass", name = "Use W Harass", value = false})
                        -- Clear
                        MENU.wset:MenuElement({name = "Clear", id = "clear", type = _G.MENU })
                            MENU.wset.clear:MenuElement({id = "enabled", name = "Enbaled", value = true})
                            MENU.wset.clear:MenuElement({id = "xminions", name = "Min minions W Clear", value = 3, min = 1, max = 5, step = 1})
                    -- E
                    MENU:MenuElement({name = "E settings", id = "eset", type = _G.MENU })
                        -- Auto
                        MENU.eset:MenuElement({name = "Auto", id = "auto", type = _G.MENU })
                            MENU.eset.auto:MenuElement({id = "enabled", name = "Enabled", value = true})
                            MENU.eset.auto:MenuElement({id = "ally", name = "Use on ally", value = true})
                            MENU.eset.auto:MenuElement({id = "selfish", name = "Use on yourself", value = true})
                    --R
                    MENU:MenuElement({name = "R settings", id = "rset", type = _G.MENU })
                        -- KS
                        MENU.rset:MenuElement({name = "KS", id = "killsteal", type = _G.MENU })
                            MENU.rset.killsteal:MenuElement({id = "enabled", name = "Enabled", value = false})
                            MENU.rset.killsteal:MenuElement({id = "minhp", name = "Minimum enemy hp", value = 200, min = 1, max = 300, step = 1})
                        -- Auto
                        MENU.rset:MenuElement({name = "Auto", id = "auto", type = _G.MENU })
                            MENU.rset.auto:MenuElement({id = "enabled", name = "Enabled", value = true})
                            MENU.rset.auto:MenuElement({id = "xenemies", name = ">= X enemies near morgana", value = 3, min = 1, max = 5, step = 1})
                            MENU.rset.auto:MenuElement({id = "xrange", name = "< X distance enemies to morgana", value = 300, min = 100, max = 550, step = 50})
                        -- Combo / Harass
                        MENU.rset:MenuElement({name = "Combo / Harass", id = "comhar", type = _G.MENU })
                            MENU.rset.comhar:MenuElement({id = "combo", name = "Use R Combo", value = true})
                            MENU.rset.comhar:MenuElement({id = "harass", name = "Use R Harass", value = false})
                            MENU.rset.comhar:MenuElement({id = "xenemies", name = ">= X enemies near morgana", value = 2, min = 1, max = 4, step = 1})
                            MENU.rset.comhar:MenuElement({id = "xrange", name = "< X distance enemies to morgana", value = 300, min = 100, max = 550, step = 50})
            end
            function c:Tick()
                -- Is Attacking
                if ORB:IsAutoAttacking() then
                    return
                end
                -- Q
                if SPELLS:IsReady(_Q, { q = 0.5, w = 0.33, e = 0.33, r = 0.33 } ) then
                    -- KS
                    if MENU.qset.killsteal.enabled:Value() then
                        local baseDmg = 25
                        local lvlDmg = 55 * myHero:GetSpellData(_Q).level
                        local apDmg = myHero.ap * 0.9
                        local qDmg = baseDmg + lvlDmg + apDmg
                        local minHP = MENU.qset.killsteal.minhp:Value()
                        if qDmg > minHP then
                            local enemyList = OB:GetEnemyHeroes(self.QData.Range, false, 0)
                            for i = 1, #enemyList do
                                local qTarget = enemyList[i]
                                if qTarget.health > minHP and qTarget.health < DMG:CalculateDamage(myHero, qTarget, DAMAGE_TYPE_MAGICAL, qDmg) and PREDICTION:CastSpell(HK_Q, qTarget, myHero.pos, self.QData, MENU.qset.killsteal.hitchance:Value()) then
                                    return
                                end
                            end
                        end
                    end
                    -- Combo Harass
                    if (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.qset.comhar.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.qset.comhar.harass:Value()) then
                        local qList = {}
                        local enemyList = OB:GetEnemyHeroes(self.QData.Range, false, 0)
                        for i = 1, #enemyList do
                            local hero = enemyList[i]
                            local heroName = hero.charName
                            if MENU.qset.comhar.useon[heroName] and MENU.qset.comhar.useon[heroName]:Value() then
                                qList[#qList+1] = hero
                            end
                        end
                        local qTarget = TS:GetTarget(qList, 1)
                        if qTarget and PREDICTION:CastSpell(HK_Q, qTarget, myHero.pos, self.QData, MENU.qset.comhar.hitchance:Value()) then
                            return
                        end
                    -- Auto
                    elseif MENU.qset.auto.enabled:Value() then
                        local qList = {}
                        local enemyList = OB:GetEnemyHeroes(self.QData.Range, false, 0)
                        for i = 1, #enemyList do
                            local hero = enemyList[i]
                            local heroName = hero.charName
                            if MENU.qset.auto.useon[heroName] and MENU.qset.auto.useon[heroName]:Value() then
                                qList[#qList+1] = hero
                            end
                        end
                        local qTarget = TS:GetTarget(qList, 1)
                        if qTarget and PREDICTION:CastSpell(HK_Q, qTarget, myHero.pos, self.QData, MENU.qset.auto.hitchance:Value()) then
                            return
                        end
                    end
                end
                -- W
                if SPELLS:IsReady(_W, { q = 0.33, w = 0.5, e = 0.33, r = 0.33 } ) then
                    -- KS
                    if MENU.wset.killsteal.enabled:Value() then
                        local baseDmg = 10
                        local lvlDmg = 14 * myHero:GetSpellData(_W).level
                        local apDmg = myHero.ap * 0.22
                        local wDmg = baseDmg + lvlDmg + apDmg
                        local minHP = MENU.wset.killsteal.minhp:Value()
                        if wDmg > minHP then
                            local enemyList = OB:GetEnemyHeroes(self.QData.Range, false, 0)
                            for i = 1, #enemyList do
                                local wTarget = enemyList[i]
                                if wTarget.health > minHP and wTarget.health < DMG:CalculateDamage(myHero, wTarget, DAMAGE_TYPE_MAGICAL, wDmg) and PREDICTION:CastSpell(HK_W, wTarget, myHero.pos, self.QData, MENU.qset.killsteal.hitchance:Value()) then
                                    return
                                end
                            end
                        end
                    end
                    -- Combo / Harass
                    if (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.wset.comhar.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.wset.comhar.harass:Value()) then
                        local enemyList = OB:GetEnemyHeroes(self.WData.Range, false, 0)
                        for i = 1, #enemyList do
                            local unit = enemyList[i]
                            if PREDICTION:CastSpell(HK_W, unit) then
                                return
                            end
                        end
                    end
                    -- Clear
                    if (ORB.Modes[ORBWALKER_MODE_LANECLEAR] and MENU.wset.clear.enabled:Value()) then
                        local eMinions = {}
                        local mobs = {}
                        for i = 1, Game.MinionCount() do
                            local minion = Game.Minion(i)
                            if  isValidTarget(minion, self.WData.Range) then
                                if minion.team == 300 then
                                    mobs[#mobs+1] = minion
                                elseif minion.isEnemy  then
                                    eMinions[#eMinions+1] = minion
                                end
                            end
                        end
                        local BestPos, BestHit = GetBestCircularFarmPosition(self.WData.Range, self.WData.Radius, eMinions)
                        if BestHit >= MENU.wset.clear.xminions:Value() then
                            if Control.CastSpell(HK_W, BestPos) then
                                return
                            end
                        end
                    end
                    -- Auto
                    if MENU.wset.auto.enabled:Value() then
                        local mSlow = MENU.wset.auto.slow:Value()
                        local mImmobile = MENU.wset.auto.immobile:Value()
                        local mTime = MENU.wset.auto.time:Value() * 0.001
                        if mSlow or mImmobile then
                            local enemyList = OB:GetEnemyHeroes(self.WData.Range, false, 0)
                            for i = 1, #enemyList do
                                local unit = enemyList[i]
                                --print("lol")
                                if ((mImmobile and IsImmobile(unit, mTime)) or (mSlow and IsSlowed(unit, mTime))) and PREDICTION:CastSpell(HK_W, unit) then
                                    return
                                end
                            end
                        end
                    end
                end
                -- E
                if SPELLS:IsReady(_E, { q = 0.33, w = 0.33, e = 0.5, r = 0.33 } ) then
                    -- Auto
                    if MENU.eset.auto.enabled:Value() then
                        for i = 1, LocalGameHeroCount() do
                            local hero = LocalGameHero(i)
                            if hero and hero.isEnemy and hero.activeSpell.valid and hero.isChanneling then
                                local currSpell = hero.activeSpell
                                local spellPos = Vector(currSpell.placementPos.x, currSpell.placementPos.y, currSpell.placementPos.z)
                                for i = 1, Game.HeroCount() do
                                    local ally = Game.Hero(i)
                                    if ally and ((ally.isAlly and ally ~= myHero and MENU.eset.auto.ally:Value()) or (ally == myHero) and MENU.eset.auto.selfish:Value()) then
                                        if (ally.pos:DistanceTo(myHero.pos) < self.EData.Range and ally.pos:DistanceTo(spellPos) < currSpell.width + (ally.boundingRadius * 1.5)) or currSpell.target == ally.handle then
                                            --print(ally.pos:DistanceTo(spellPos))
                                            if Control.CastSpell(HK_E, ally) then
                                                return
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                -- R
                if SPELLS:IsReady(_R, { q = 0.33, w = 0.33, e = 0.33, r = 0.5 } ) then
                    -- KS
                    if MENU.rset.killsteal.enabled:Value() then
                        local baseDmg = 75
                        local lvlDmg = 75 * myHero:GetSpellData(_R).level
                        local apDmg = myHero.ap * 0.7
                        local rDmg = baseDmg + lvlDmg + apDmg
                        local minHP = MENU.rset.killsteal.minhp:Value()
                        if rDmg > minHP then
                            local enemyList = OB:GetEnemyHeroes(self.RData.Range, false, 0)
                            for i = 1, #enemyList do
                                local rTarget = enemyList[i]
                                if rTarget.health > minHP and rTarget.health < DMG:CalculateDamage(myHero, rTarget, DAMAGE_TYPE_MAGICAL, rDmg) and PREDICTION:CastSpell(HK_R) then
                                    return
                                end
                            end
                        end
                    end
                    -- Combo / Harass
                    if (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.rset.comhar.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.rset.comhar.harass:Value()) then
                        local count = 0
                        local xRange = MENU.rset.comhar.xrange:Value()
                        local enemyList = OB:GetEnemyHeroes(self.RData.Range, false, 0)
                        for i = 1, #enemyList do
                            local unit = enemyList[i]
                            if unit.pos:DistanceTo(myHero.pos) < xRange then
                                count = count + 1
                            end
                        end
                        if count >= MENU.rset.comhar.xenemies:Value() and PREDICTION:CastSpell(HK_R) then
                            return
                        end
                    end
                    -- Auto
                    if MENU.rset.auto.enabled:Value() then
                        local count = 0
                        local xRange = MENU.rset.auto.xrange:Value()
                        local enemyList = OB:GetEnemyHeroes(self.RData.Range, false, 0)
                        for i = 1, #enemyList do
                            local unit = enemyList[i]
                            if unit.pos:DistanceTo(myHero.pos) < xRange then
                                count = count + 1
                            end
                        end
                        if count >= MENU.rset.auto.xenemies:Value() and PREDICTION:CastSpell(HK_R) then
                            return
                        end
                    end
                end
            end
            function c:CanAttack()
                if not SPELLS:CheckSpellDelays({ q = 0.33, w = 0.33, e = 0.33, r = 0.33 }) then
                    return false
                end
                -- LastHit, LaneClear
                if not ORB.Modes[ORBWALKER_MODE_COMBO] and not ORB.Modes[ORBWALKER_MODE_HARASS] then
                    return true
                end
                -- Q
                if MENU.qset.disaa:Value() and myHero:GetSpellData(_Q).level > 0 and myHero.mana > myHero:GetSpellData(_Q).mana and (LocalGameCanUseSpell(_Q) == 0 or myHero:GetSpellData(_Q).currentCd < 1) then
                    return false
                end
                return true
            end
            function c:CanMove()
                if not SPELLS:CheckSpellDelays({ q = 0.2, w = 0.2, e = 0.2, r = 0.2 }) then
                    return false
                end
                return true
            end
            function c:Draw()
                if SPELLS:IsReady(_Q, { q = 0.5, w = 0.33, e = 0.33, r = 0.33 } ) then
                    if MENU.qset.auto.enabled:Value() then
                        local qList = {}
                        local enemyList = OB:GetEnemyHeroes(self.QData.Range, false, 0)
                        for i = 1, #enemyList do
                            local hero = enemyList[i]
                            local heroName = hero.charName
                            if MENU.qset.auto.useon[heroName] and MENU.qset.auto.useon[heroName]:Value() then
                                qList[#qList+1] = hero
                            end
                        end
                        local qTarget = TS:GetTarget(qList, 1)
                        if qTarget and PREDICTION:CastSpell(HK_Q, qTarget, myHero.pos, self.QData, MENU.qset.auto.hitchance:Value()) then
                            return
                        end
                    end
                end
            end
            return result
        end,
        Karthus = function()
            local c = {}
            local result =
            {
                QData = { Delay = 1.1, Radius = 200, Range = 875, Speed = math.huge, Collision = false, Type = SPELLTYPE_CIRCLE },
                WData = { Delay = 0.25, Radius = 0, Range = 1000, Speed = math.huge, Collision = false, Type = SPELLTYPE_LINE }
            }
            -- init
                c.__index = c
                setmetatable(result, c)
            function c:Menu()
                MENU = MenuElement({name = "Gamsteron Karthus", id = "gsokarthus", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/karthusw5s.png" })
                    -- Q
                    MENU:MenuElement({name = "Q settings", id = "qset", type = _G.MENU })
                        -- Disable Attack
                        MENU.qset:MenuElement({id = "disaa", name = "Disable attack", value = true})
                        -- KS
                        MENU.qset:MenuElement({name = "KS", id = "killsteal", type = _G.MENU })
                            MENU.qset.killsteal:MenuElement({id = "enabled", name = "Enabled", value = true})
                            MENU.qset.killsteal:MenuElement({id = "minhp", name = "minimum enemy hp", value = 200, min = 1, max = 300, step = 1})
                            MENU.qset.killsteal:MenuElement({id = "hitchance", name = "Hitchance", value = 1, drop = { "normal", "high" } })
                        -- Auto
                        MENU.qset:MenuElement({name = "Auto", id = "auto", type = _G.MENU })
                            MENU.qset.auto:MenuElement({id = "enabled", name = "Enabled", value = true})
                            MENU.qset.auto:MenuElement({name = "Use on:", id = "useon", type = _G.MENU })
                                Core:OnEnemyHeroLoad(function(hero) MENU.qset.auto.useon:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
                            MENU.qset.auto:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "normal", "high" } })
                        -- Combo / Harass
                        MENU.qset:MenuElement({name = "Combo / Harass", id = "comhar", type = _G.MENU })
                            MENU.qset.comhar:MenuElement({id = "combo", name = "Combo", value = true})
                            MENU.qset.comhar:MenuElement({id = "harass", name = "Harass", value = false})
                            MENU.qset.comhar:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "normal", "high" } })
                    -- W
                    MENU:MenuElement({name = "W settings", id = "wset", type = _G.MENU })
                        MENU.wset:MenuElement({id = "combo", name = "Combo", value = true})
                        MENU.wset:MenuElement({id = "harass", name = "Harass", value = false})
                        MENU.wset:MenuElement({id = "slow", name = "Auto OnSlow", value = true})
                        MENU.wset:MenuElement({id = "immobile", name = "Auto OnImmobile", value = true})
                        MENU.wset:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "normal", "high" } })
                    -- E
                    MENU:MenuElement({name = "E settings", id = "eset", type = _G.MENU })
                        MENU.eset:MenuElement({id = "auto", name = "Auto", value = true})
                        MENU.eset:MenuElement({id = "combo", name = "Combo", value = true})
                        MENU.eset:MenuElement({id = "harass", name = "Harass", value = false})
                        MENU.eset:MenuElement({id = "minmp", name = "minimum mana percent", value = 25, min = 1, max = 100, step = 1})
                    --R
                    MENU:MenuElement({name = "R settings", id = "rset", type = _G.MENU })
                        MENU.rset:MenuElement({id = "killsteal", name = "Auto KS X enemies in passive form", value = true})
                        MENU.rset:MenuElement({id = "kscount", name = "^^^ X enemies ^^^", value = 2, min = 1, max = 5, step = 1})
                    -- [ draws ]
                    MENU:MenuElement({name = "Drawings", id = "draws", type = _G.MENU })
                        MENU.draws:MenuElement({name = "Draw Kill Count", id = "ksdraw", type = _G.MENU })
                        MENU.draws.ksdraw:MenuElement({id = "enabled", name = "Enabled", value = true})
                        MENU.draws.ksdraw:MenuElement({id = "size", name = "Text Size", value = 25, min = 1, max = 64, step = 1 })
            end
            function c:Tick()
                -- Is Attacking
                if ORB:IsAutoAttacking() then
                    return
                end
                -- Has Passive Buff
                local hasPassive = HasBuff(myHero, "karthusdeathdefiedbuff")
                -- W
                if SPELLS:IsReady(_W, { q = 0.33, w = 0.5, e = 0.33, r = 3.23 } ) then
                    local mSlow = MENU.wset.slow:Value()
                    local mImmobile = MENU.wset.immobile:Value()
                    if (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.wset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.wset.harass:Value()) then
                        local enemyList = OB:GetEnemyHeroes(1000, false, 0)
                        local wTarget = TS:GetTarget(enemyList, 1)
                        if wTarget and PREDICTION:CastSpell(HK_W, wTarget, myHero.pos, self.WData, MENU.wset.hitchance:Value()) then
                            return
                        end
                    elseif mSlow or mImmobile then
                        local enemyList = OB:GetEnemyHeroes(1000, false, 0)
                        for i = 1, #enemyList do
                            local unit = enemyList[i]
                            if ((mImmobile and IsImmobile(unit, 0.5)) or (mSlow and IsSlowed(unit, 0.5))) and PREDICTION:CastSpell(HK_W, unit, myHero.pos, self.WData, MENU.wset.hitchance:Value()) then
                                return
                            end
                        end
                    end
                end
                -- E
                if SPELLS:IsReady(_E, { q = 0.33, w = 0.33, e = 0.5, r = 3.23 } ) and not hasPassive then
                    if MENU.eset.auto:Value() or (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.eset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.eset.harass:Value()) then
                        local enemyList = OB:GetEnemyHeroes(425, false, 0)
                        local eBuff = HasBuff(myHero, "karthusdefile")
                        if eBuff and #enemyList == 0 and PREDICTION:CastSpell(HK_E) then
                            return
                        end
                        local manaPercent = 100 * myHero.mana / myHero.maxMana
                        if not eBuff and #enemyList > 0 and manaPercent > MENU.eset.minmp:Value() and PREDICTION:CastSpell(HK_E) then
                            return
                        end
                    end
                end
                -- Q
                if SPELLS:IsReady(_Q, { q = 0.5, w = 0.33, e = 0.33, r = 3.23 } ) and SPELLS:CustomIsReady(_Q, 1) then
                    -- KS
                    if MENU.qset.killsteal.enabled:Value() then
                        local qDmg = self:GetQDmg()
                        local minHP = MENU.qset.killsteal.minhp:Value()
                        if qDmg > minHP then
                            local enemyList = OB:GetEnemyHeroes(875, false, 0)
                            for i = 1, #enemyList do
                                local qTarget = enemyList[i]
                                if qTarget.health > minHP and qTarget.health < DMG:CalculateDamage(myHero, qTarget, DAMAGE_TYPE_MAGICAL, self:GetQDmg()) and PREDICTION:CastSpell(HK_Q, qTarget, myHero.pos, self.QData, MENU.qset.killsteal.hitchance:Value()) then
                                    return
                                end
                            end
                        end
                    end
                    -- Combo Harass
                    if (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.qset.comhar.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.qset.comhar.harass:Value()) then
                        for i = 1, 3 do
                            local enemyList = OB:GetEnemyHeroes(1000 - (i*100), false, 0)
                            local qTarget = TS:GetTarget(enemyList, 1)
                            if qTarget and PREDICTION:CastSpell(HK_Q, qTarget, myHero.pos, self.QData, MENU.qset.comhar.hitchance:Value()) then
                                return
                            end
                        end
                    -- Auto
                    elseif MENU.qset.auto.enabled:Value() then
                        for i = 1, 3 do
                            local qList = {}
                            local enemyList = OB:GetEnemyHeroes(1000 - (i*100), false, 0)
                            for i = 1, #enemyList do
                                local hero = enemyList[i]
                                local heroName = hero.charName
                                if MENU.qset.auto.useon[heroName] and MENU.qset.auto.useon[heroName]:Value() then
                                    qList[#qList+1] = hero
                                end
                            end
                            local qTarget = TS:GetTarget(qList, 1)
                            if qTarget and PREDICTION:CastSpell(HK_Q, qTarget, myHero.pos, self.QData, MENU.qset.auto.hitchance:Value()) then
                                return
                            end
                        end
                    end
                end
                -- R
                if SPELLS:IsReady(_R, { q = 0.33, w = 0.33, e = 0.33, r = 0.5 } ) and MENU.rset.killsteal:Value() and hasPassive then
                    local rCount = 0
                    local enemyList = OB:GetEnemyHeroes(99999, false, 0)
                    for i = 1, #enemyList do
                        local rTarget = enemyList[i]
                        if rTarget.health < DMG:CalculateDamage(myHero, rTarget, DAMAGE_TYPE_MAGICAL, self:GetRDmg()) then
                            rCount = rCount + 1
                        end
                    end
                    if rCount > MENU.rset.kscount:Value() and PREDICTION:CastSpell(HK_R) then
                        return
                    end
                end
            end
            function c:Draw()
                self:Tick()
                if MENU.draws.ksdraw.enabled:Value() and LocalGameCanUseSpell(_R) == 0 then
                    local rCount = 0
                    local enemyList = OB:GetEnemyHeroes(99999, false, 0)
                    for i = 1, #enemyList do
                        local rTarget = enemyList[i]
                        if rTarget.health < DMG:CalculateDamage(myHero, rTarget, DAMAGE_TYPE_MAGICAL, self:GetRDmg()) then
                            rCount = rCount + 1
                        end
                    end
                    local mePos = myHero.pos:To2D()
                    local posX = mePos.x - 50
                    local posY = mePos.y
                    if rCount > 0 then
                        LocalDrawText("Kill Count: "..rCount, MENU.draws.ksdraw.size:Value(), posX, posY, LocalDrawColor(255, 000, 255, 000))
                    else
                        LocalDrawText("Kill Count: "..rCount, MENU.draws.ksdraw.size:Value(), posX, posY, LocalDrawColor(150, 255, 000, 000))
                    end
                end
            end
            function c:CanAttack()
                if not SPELLS:CheckSpellDelays({ q = 0.33, w = 0.33, e = 0.33, r = 3.23 }) then
                    return false
                end
                if not MENU.qset.disaa:Value() then
                    return true
                end
                if not ORB.Modes[ORBWALKER_MODE_COMBO] and not ORB.Modes[ORBWALKER_MODE_HARASS] then
                    return true
                end
                if myHero.mana > myHero:GetSpellData(_Q).mana then
                    return false
                end
                return true
            end
            function c:CanMove()
                if not SPELLS:CheckSpellDelays({ q = 0.2, w = 0.2, e = 0.2, r = 3.13 }) then
                    return false
                end
                return true
            end
            function c:GetQDmg()
                local qLvl = myHero:GetSpellData(_Q).level
                if qLvl == 0 then return 0 end
                local baseDmg = 30
                local lvlDmg = 20 * qLvl
                local apDmg = myHero.ap * 0.3
                return baseDmg + lvlDmg + apDmg
            end
            function c:GetRDmg()
                local rLvl = myHero:GetSpellData(_R).level
                if rLvl == 0 then return 0 end
                local baseDmg = 100
                local lvlDmg = 150 * rLvl
                local apDmg = myHero.ap * 0.75
                return baseDmg + lvlDmg + apDmg
            end
            return result
        end,
        KogMaw = function()
            local c = {}
            local result =
            {
                HasWBuff = false,
                QData = { Delay = 0.25, Radius = 70, Range = 1175, Speed = 1650, Collision = true, Type = SPELLTYPE_LINE },
                EData = { Delay = 0.25, Radius = 120, Range = 1280, Speed = 1350, Collision = false, Type = SPELLTYPE_LINE },
                RData = { Delay = 1.2, Radius = 225, Range = 0, Speed = math.huge, Collision = false, Type = SPELLTYPE_CIRCLE }
            }
            -- init
                c.__index = c
                setmetatable(result, c)
            function c:Menu()
                MENU = MenuElement({name = "Gamsteron KogMaw", id = "gsokogmaw", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/kog.png" })
                    MENU:MenuElement({name = "Q settings", id = "qset", type = _G.MENU })
                        MENU.qset:MenuElement({id = "combo", name = "Combo", value = true})
                        MENU.qset:MenuElement({id = "harass", name = "Harass", value = false})
                        MENU.qset:MenuElement({id = "hitchance", name = "Hitchance", value = 1, drop = { "normal", "high" } })
                    MENU:MenuElement({name = "W settings", id = "wset", type = _G.MENU })
                        MENU.wset:MenuElement({id = "combo", name = "Combo", value = true})
                        MENU.wset:MenuElement({id = "harass", name = "Harass", value = false})
                        MENU.wset:MenuElement({id = "stopq", name = "Stop Q if has W buff", value = false})
                        MENU.wset:MenuElement({id = "stope", name = "Stop E if has W buff", value = false})
                        MENU.wset:MenuElement({id = "stopr", name = "Stop R if has W buff", value = false})
                    MENU:MenuElement({name = "E settings", id = "eset", type = _G.MENU })
                        MENU.eset:MenuElement({id = "combo", name = "Combo", value = true})
                        MENU.eset:MenuElement({id = "harass", name = "Harass", value = false})
                        MENU.eset:MenuElement({id = "emana", name = "Minimum Mana %", value = 20, min = 1, max = 100, step = 1 })
                        MENU.eset:MenuElement({id = "hitchance", name = "Hitchance", value = 1, drop = { "normal", "high" } })
                    MENU:MenuElement({name = "R settings", id = "rset", type = _G.MENU })
                        MENU.rset:MenuElement({id = "combo", name = "Combo", value = true})
                        MENU.rset:MenuElement({id = "harass", name = "Harass", value = false})
                        MENU.rset:MenuElement({id = "onlylow", name = "Only 0-40 % HP enemies", value = true})
                        MENU.rset:MenuElement({id = "stack", name = "Stop at x stacks", value = 3, min = 1, max = 9, step = 1 })
                        MENU.rset:MenuElement({id = "rmana", name = "Minimum Mana %", value = 20, min = 1, max = 100, step = 1 })
                        MENU.rset:MenuElement({name = "KS", id = "ksmenu", type = _G.MENU })
                            MENU.rset.ksmenu:MenuElement({id = "ksr", name = "KS - Enabled", value = true})
                            MENU.rset.ksmenu:MenuElement({id = "csksr", name = "KS -> Check R stacks", value = false})
                        MENU.rset:MenuElement({name = "Semi Manual", id = "semirkog", type = _G.MENU })
                            MENU.rset.semirkog:MenuElement({name = "Semi-Manual Key", id = "semir", key = string.byte("T")})
                            MENU.rset.semirkog:MenuElement({name = "Check R stacks", id = "semistacks", value = false})
                            MENU.rset.semirkog:MenuElement({name = "Only 0-40 % HP enemies", id = "semilow",  value = false})
                            MENU.rset.semirkog:MenuElement({name = "Use on:", id = "useon", type = _G.MENU })
                                Core:OnEnemyHeroLoad(function(hero) MENU.rset.semirkog.useon:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
                        MENU.rset:MenuElement({id = "hitchance", name = "Hitchance", value = 1, drop = { "normal", "high" } })
            end
            function c:Tick()
                -- Is Attacking
                if ORB:IsAutoAttacking() then
                    return
                end
                -- Can Attack
                local AATarget = TS:GetComboTarget()
                if AATarget and not ORB.IsNone and ORB:CanAttack() then
                    return
                end
                -- W
                if ((ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.wset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.wset.harass:Value())) and IsBeforeAttack(0.55) and SPELLS:IsReady(_W, { q = 0.33, w = 0.5, e = 0.33, r = 0.33 } ) then
                    local enemyList = OB:GetEnemyHeroes(610 + ( 20 * myHero:GetSpellData(_W).level ) + myHero.boundingRadius - 35, true, 1)
                    if #enemyList > 0 and PREDICTION:CastSpell(HK_W) then
                        return
                    end
                end
                -- Check W Buff
                local HasWBuff = false
                for i = 0, myHero.buffCount do
                    local buff = myHero:GetBuff(i)
                    if buff and buff.count > 0 and buff.duration > 0 and buff.name == "KogMawBioArcaneBarrage" then
                        HasWBuff = true
                        break
                    end
                end
                self.HasWBuff = HasWBuff
                -- Get Mana Percent
                local manaPercent = 100 * myHero.mana / myHero.maxMana
                -- Save Mana
                local wMana = 40 - ( myHero:GetSpellData(_W).currentCd * myHero.mpRegen )
                local meMana = myHero.mana - wMana
                if not(AATarget) and (LocalGameTimer() < SPELLS.LastW + 0.3 or LocalGameTimer() < SPELLS.LastWk + 0.3) then
                    return
                end
                -- R
                if meMana > myHero:GetSpellData(_R).mana and SPELLS:IsReady(_R, { q = 0.33, w = 0.15, e = 0.33, r = 0.5 } ) then
                    self.RData.Range = 900 + 300 * myHero:GetSpellData(_R).level
                    local enemyList = OB:GetEnemyHeroes(self.RData.Range, false, 0)
                    local rStacks = GetBuffCount(myHero, "kogmawlivingartillerycost") < MENU.rset.stack:Value()
                    local checkRStacksKS = MENU.rset.ksmenu.csksr:Value()
                    -- KS
                    if MENU.rset.ksmenu.ksr:Value() and ( not checkRStacksKS or rStacks ) then
                        local rTargets = {}
                        for i = 1, #enemyList do
                            local hero = enemyList[i]
                            local baseRDmg = 60 + ( 40 * myHero:GetSpellData(_R).level ) + ( myHero.bonusDamage * 0.65 ) + ( myHero.ap * 0.25 )
                            local rMultipier = math.floor(100 - ( ( ( hero.health + ( hero.hpRegen * 3 ) ) * 100 ) / hero.maxHealth ))
                            local rDmg
                            if rMultipier > 60 then
                                rDmg = baseRDmg * 2
                            else
                                rDmg = baseRDmg * ( 1 + ( rMultipier * 0.00833 ) )
                            end
                            rDmg = DMG:CalculateDamage(myHero, hero, DAMAGE_TYPE_MAGICAL, rDmg)
                            local unitKillable = rDmg > hero.health + (hero.hpRegen * 2)
                            if unitKillable then
                                rTargets[#rTargets+1] = hero
                            end
                        end
                        local t = TS:GetTarget(rTargets, 1)
                        if t and PREDICTION:CastSpell(HK_R, t, myHero.pos, self.RData, MENU.rset.hitchance:Value()) then
                            return
                        end
                    end
                    -- SEMI MANUAL
                    local checkRStacksSemi = MENU.rset.semirkog.semistacks:Value()
                    if MENU.rset.semirkog.semir:Value() and ( not checkRStacksSemi or rStacks ) then
                        local onlyLowR = MENU.rset.semirkog.semilow:Value()
                        local rTargets = {}
                        if onlyLowR then
                            for i = 1, #enemyList do
                                local hero = enemyList[i]
                                if hero and ( ( hero.health + ( hero.hpRegen * 3 ) ) * 100 ) / hero.maxHealth < 40 then
                                    rTargets[#rTargets+1] = hero
                                end
                            end
                        else
                            rTargets = enemyList
                        end
                        local t = TS:GetTarget(rTargets, 1)
                        if t and PREDICTION:CastSpell(HK_R, t, myHero.pos, self.RData, MENU.rset.hitchance:Value()) then
                            return
                        end
                    end
                    -- Combo / Harass
                    if (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.rset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.rset.harass:Value()) then
                        local stopRIfW = MENU.wset.stopr:Value() and self.HasWBuff
                        if not stopRIfW and rStacks and manaPercent > MENU.rset.rmana:Value() then
                            local onlyLowR = MENU.rset.onlylow:Value()
                            local AATarget2
                            if onlyLowR and AATarget and ( AATarget.health * 100 ) / AATarget.maxHealth > 39 then
                                AATarget2 = nil
                            else
                                AATarget2 = AATarget
                            end
                            local t
                            if AATarget2 then
                                t = AATarget2
                            else
                                local rTargets = {}
                                if onlyLowR then
                                    for i = 1, #enemyList do
                                        local hero = enemyList[i]
                                        if hero and ( ( hero.health + ( hero.hpRegen * 3 ) ) * 100 ) / hero.maxHealth < 40 then
                                            rTargets[#rTargets+1] = hero
                                        end
                                    end
                                else
                                    rTargets = enemyList
                                end
                                t = TS:GetTarget(rTargets, 1)
                            end
                            if t and PREDICTION:CastSpell(HK_R, t, myHero.pos, self.RData, MENU.rset.hitchance:Value()) then
                                return
                            end
                        end
                    end
                end
                -- Q
                local stopQIfW = MENU.wset.stopq:Value() and self.HasWBuff
                if not stopQIfW and meMana > myHero:GetSpellData(_Q).mana and SPELLS:IsReady(_Q, { q = 0.5, w = 0.15, e = 0.33, r = 0.33 } ) then
                    -- Combo / Harass
                    if (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.qset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.qset.harass:Value()) then
                        local t
                        if AATarget then
                            t = AATarget
                        else
                            t = TS:GetTarget(OB:GetEnemyHeroes(1175, false, 0), 1)
                        end
                        if t and PREDICTION:CastSpell(HK_Q, t, myHero.pos, self.QData, MENU.qset.hitchance:Value()) then
                            return
                        end
                    end
                end
                -- E
                local stopEifW = MENU.wset.stope:Value() and self.HasWBuff
                if not stopEifW and manaPercent > MENU.eset.emana:Value() and meMana > myHero:GetSpellData(_E).mana and SPELLS:IsReady(_E, { q = 0.33, w = 0.15, e = 0.5, r = 0.33 } ) then
                    if (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.eset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.eset.harass:Value()) then
                        local t
                        if AATarget then
                            t = AATarget
                        else
                            t = TS:GetTarget(OB:GetEnemyHeroes(1280, false, 0), 1)
                        end
                        if t and PREDICTION:CastSpell(HK_E, t, myHero.pos, self.EData, MENU.eset.hitchance:Value()) then
                            return
                        end
                    end
                end
            end
            function c:PreAttack(args)
                if ((ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.wset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.wset.harass:Value())) and SPELLS:IsReady(_W, { q = 0.33, w = 0.5, e = 0.33, r = 0.33 } ) then
                    local enemyList = OB:GetEnemyHeroes(610 + ( 20 * myHero:GetSpellData(_W).level ) + myHero.boundingRadius - 35, true, 1)
                    if #enemyList > 0 and PREDICTION:CastSpell(HK_W) then
                        args.Process = false
                        return
                    end
                end
            end
            function c:CanMove()
                if not SPELLS:CheckSpellDelays({ q = 0.2, w = 0, e = 0.2, r = 0.2 }) then
                    return false
                end
                return true
            end
            function c:CanAttack()
                if not SPELLS:CheckSpellDelays({ q = 0.33, w = 0, e = 0.33, r = 0.33 }) then
                    return false
                end
                return true
            end
            return result
        end,
        Brand = function()
            local c = {}
            local result =
            {
                ETarget = nil,
                QData = { Delay = 0.25, Radius = 80, Range = 1050, Speed = 1550, Collision = true, Type = SPELLTYPE_LINE },
                WData = { Delay = 0.625, Radius = 100, Range = 875, Speed = math.huge, Collision = false, Type = SPELLTYPE_CIRCLE }
            }
            -- init
                c.__index = c
                setmetatable(result, c)
            function c:Menu()
                MENU = MenuElement({name = "Gamsteron Brand", id = "gsobrand", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/x1xxbrandx3xx.png" })
                    -- Q
                    MENU:MenuElement({name = "Q settings", id = "qset", type = _G.MENU })
                        -- KS
                        MENU.qset:MenuElement({name = "KS", id = "killsteal", type = _G.MENU })
                            MENU.qset.killsteal:MenuElement({id = "enabled", name = "Enabled", value = true})
                            MENU.qset.killsteal:MenuElement({id = "minhp", name = "minimum enemy hp", value = 200, min = 1, max = 300, step = 1})
                            MENU.qset.killsteal:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "normal", "high" } })
                        -- Auto
                        MENU.qset:MenuElement({name = "Auto", id = "auto", type = _G.MENU })
                            MENU.qset.auto:MenuElement({id = "stun", name = "Auto Stun", value = true})
                            MENU.qset.auto:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "normal", "high" } })
                        -- Combo / Harass
                        MENU.qset:MenuElement({name = "Combo / Harass", id = "comhar", type = _G.MENU })
                            MENU.qset.comhar:MenuElement({id = "combo", name = "Combo", value = true})
                            MENU.qset.comhar:MenuElement({id = "harass", name = "Harass", value = false})
                            MENU.qset.comhar:MenuElement({id = "stun", name = "Only if will stun", value = true})
                            MENU.qset.comhar:MenuElement({id = "hitchance", name = "Hitchance", value = 1, drop = { "normal", "high" } })
                    -- W
                    MENU:MenuElement({name = "W settings", id = "wset", type = _G.MENU })
                        MENU.wset:MenuElement({id = "disaa", name = "Disable attack if ready or almostReady", value = true})
                        -- KS
                        MENU.wset:MenuElement({name = "KS", id = "killsteal", type = _G.MENU })
                            MENU.wset.killsteal:MenuElement({id = "enabled", name = "Enabled", value = true})
                            MENU.wset.killsteal:MenuElement({id = "minhp", name = "minimum enemy hp", value = 200, min = 1, max = 300, step = 1})
                            MENU.wset.killsteal:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "normal", "high" } })
                        -- Auto
                        MENU.wset:MenuElement({name = "Auto", id = "auto", type = _G.MENU })
                            MENU.wset.auto:MenuElement({id = "enabled", name = "Enabled", value = true})
                            MENU.wset.auto:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "normal", "high" } })
                        -- Combo / Harass
                        MENU.wset:MenuElement({name = "Combo / Harass", id = "comhar", type = _G.MENU })
                            MENU.wset.comhar:MenuElement({id = "combo", name = "Combo", value = true})
                            MENU.wset.comhar:MenuElement({id = "harass", name = "Harass", value = false})
                            MENU.wset.comhar:MenuElement({id = "hitchance", name = "Hitchance", value = 1, drop = { "normal", "high" } })
                    -- E
                    MENU:MenuElement({name = "E settings", id = "eset", type = _G.MENU })
                        MENU.eset:MenuElement({id = "disaa", name = "Disable attack if ready or almostReady", value = true})
                        -- KS
                        MENU.eset:MenuElement({name = "KS", id = "killsteal", type = _G.MENU })
                            MENU.eset.killsteal:MenuElement({id = "enabled", name = "Enabled", value = true})
                            MENU.eset.killsteal:MenuElement({id = "minhp", name = "minimum enemy hp", value = 100, min = 1, max = 300, step = 1})
                        -- Auto
                        MENU.eset:MenuElement({name = "Auto", id = "auto", type = _G.MENU })
                            MENU.eset.auto:MenuElement({id = "stun", name = "If Q ready | no collision & W not ready $ mana for Q + E", value = true})
                            MENU.eset.auto:MenuElement({id = "passive", name = "If Q not ready & W not ready $ enemy has passive buff", value = true})
                        -- Combo / Harass
                        MENU.eset:MenuElement({name = "Combo / Harass", id = "comhar", type = _G.MENU })
                            MENU.eset.comhar:MenuElement({id = "combo", name = "Combo", value = true})
                            MENU.eset.comhar:MenuElement({id = "harass", name = "Harass", value = false})
                    --R
                    MENU:MenuElement({name = "R settings", id = "rset", type = _G.MENU })
                        -- Auto
                        MENU.rset:MenuElement({name = "Auto", id = "auto", type = _G.MENU })
                            MENU.rset.auto:MenuElement({id = "enabled", name = "Enabled", value = true})
                            MENU.rset.auto:MenuElement({id = "xenemies", name = ">= X enemies near target", value = 2, min = 1, max = 4, step = 1})
                            MENU.rset.auto:MenuElement({id = "xrange", name = "< X distance enemies to target", value = 300, min = 100, max = 600, step = 50})
                        -- Combo / Harass
                        MENU.rset:MenuElement({name = "Combo / Harass", id = "comhar", type = _G.MENU })
                            MENU.rset.comhar:MenuElement({id = "combo", name = "Use R Combo", value = true})
                            MENU.rset.comhar:MenuElement({id = "harass", name = "Use R Harass", value = false})
                            MENU.rset.comhar:MenuElement({id = "xenemies", name = ">= X enemies near target", value = 1, min = 1, max = 4, step = 1})
                            MENU.rset.comhar:MenuElement({id = "xrange", name = "< X distance enemies to target", value = 300, min = 100, max = 600, step = 50})
            end
            function c:Tick()
                -- Is Attacking
                if ORB:IsAutoAttacking() then
                    return
                end
                -- Q
                if SPELLS:IsReady(_Q, { q = 0.5, w = 0.53, e = 0.53, r = 0.33 } ) then
                    -- antigap
                    local gapList = OB:GetEnemyHeroes(300, false, 0)
                    for i = 1, #gapList do
                        if PREDICTION:CastSpell(HK_Q, gapList[i], myHero.pos, self.QData, 1) then
                            return
                        end
                    end
                    -- KS
                    if MENU.qset.killsteal.enabled:Value() then
                        local baseDmg = 50
                        local lvlDmg = 30 * myHero:GetSpellData(_Q).level
                        local apDmg = myHero.ap * 0.55
                        local qDmg = baseDmg + lvlDmg + apDmg
                        local minHP = MENU.qset.killsteal.minhp:Value()
                        if qDmg > minHP then
                            local enemyList = OB:GetEnemyHeroes(1050, false, 0)
                            for i = 1, #enemyList do
                                local qTarget = enemyList[i]
                                if qTarget.health > minHP and qTarget.health < DMG:CalculateDamage(myHero, qTarget, DAMAGE_TYPE_MAGICAL, qDmg) and PREDICTION:CastSpell(HK_Q, qTarget, myHero.pos, self.QData, MENU.qset.killsteal.hitchance:Value()) then
                                    return
                                end
                            end
                        end
                    end
                    -- Combo Harass
                    if (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.qset.comhar.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.qset.comhar.harass:Value()) then
                        if LocalGameTimer() < SPELLS.LastEk + 1 and LocalGameTimer() > SPELLS.LastE + 0.33 and self.ETarget and not self.ETarget.dead and not PREDICTION:IsCollision(self.ETarget, self.QData) and PREDICTION:CastSpell(HK_Q, self.ETarget, myHero.pos, self.QData, MENU.qset.comhar.hitchance:Value()) then
                            return
                        end
                        local blazeList = {}
                        local enemyList = OB:GetEnemyHeroes(1050, false, 0)
                        for i = 1, #enemyList do
                            local unit = enemyList[i]
                            if GetBuffDuration(unit, "brandablaze") > 0.5 and not PREDICTION:IsCollision(unit, self.QData) then
                                blazeList[#blazeList+1] = unit
                            end
                        end
                        local qTarget = TS:GetTarget(blazeList, 1)
                        if qTarget and PREDICTION:CastSpell(HK_Q, qTarget, myHero.pos, self.QData, MENU.qset.comhar.hitchance:Value()) then
                            return
                        end
                        if not MENU.qset.comhar.stun:Value() and LocalGameTimer() > SPELLS.LastWk + 1.33 and LocalGameTimer() > SPELLS.LastEk + 0.77 and LocalGameTimer() > SPELLS.LastRk + 0.77 then
                            local qTarget = TS:GetTarget(OB:GetEnemyHeroes(1050, false, 0), 1)
                            if qTarget and PREDICTION:CastSpell(HK_Q, qTarget, myHero.pos, self.QData, MENU.qset.comhar.hitchance:Value()) then
                                return
                            end
                        end
                    -- Auto
                    elseif MENU.qset.auto.stun:Value() then
                        if LocalGameTimer() < SPELLS.LastEk + 1 and LocalGameTimer() > SPELLS.LastE + 0.33 and self.ETarget and not self.ETarget.dead and not PREDICTION:IsCollision(self.ETarget, self.QData) and PREDICTION:CastSpell(HK_Q, self.ETarget, myHero.pos, self.QData, 2) then
                            return
                        end
                        local blazeList = {}
                        local enemyList = OB:GetEnemyHeroes(1050, false, 0)
                        for i = 1, #enemyList do
                            local unit = enemyList[i]
                            if GetBuffDuration(unit, "brandablaze") > 0.5 and not PREDICTION:IsCollision(unit, self.QData) then
                                blazeList[#blazeList+1] = unit
                            end
                        end
                        local qTarget = TS:GetTarget(blazeList, 1)
                        if qTarget and PREDICTION:CastSpell(HK_Q, qTarget, myHero.pos, self.QData, MENU.qset.auto.hitchance:Value()) then
                            return
                        end
                    end
                end
                -- E
                if SPELLS:IsReady(_E, { q = 0.33, w = 0.53, e = 0.5, r = 0.33 } ) then
                    -- antigap
                    local enemyList = OB:GetEnemyHeroes(635, false, 0)
                    for i = 1, #enemyList do
                        local unit = enemyList[i]
                        if GetDistanceSquared(myHero.pos, unit.pos) < 300 * 300 and PREDICTION:CastSpell(HK_E, unit) then
                            return
                        end
                    end
                    -- KS
                    if MENU.eset.killsteal.enabled:Value() then
                        local baseDmg = 50
                        local lvlDmg = 20 * myHero:GetSpellData(_E).level
                        local apDmg = myHero.ap * 0.35
                        local eDmg = baseDmg + lvlDmg + apDmg
                        local minHP = MENU.eset.killsteal.minhp:Value()
                        if eDmg > minHP then
                            for i = 1, #enemyList do
                                local unit = enemyList[i]
                                if unit.health > minHP and unit.health < DMG:CalculateDamage(myHero, unit, DAMAGE_TYPE_MAGICAL, eDmg) and PREDICTION:CastSpell(HK_E, unit) then
                                    return
                                end
                            end
                        end
                    end
                    -- Combo / Harass
                    if (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.eset.comhar.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.eset.comhar.harass:Value()) then
                        local blazeList = {}
                        for i = 1, #enemyList do
                            local unit = enemyList[i]
                            if GetBuffDuration(unit, "brandablaze") > 0.33 then
                                blazeList[#blazeList+1] = unit
                            end
                        end
                        local eTarget = TS:GetTarget(blazeList, 1)
                        if eTarget and PREDICTION:CastSpell(HK_E, eTarget) then
                            self.ETarget = eTarget
                            return
                        end
                        if LocalGameTimer() > SPELLS.LastQk + 0.77 and LocalGameTimer() > SPELLS.LastWk + 1.33 and LocalGameTimer() > SPELLS.LastRk + 0.77 then
                            eTarget = TS:GetTarget(enemyList, 1)
                            if eTarget and PREDICTION:CastSpell(HK_E, eTarget) then
                                self.ETarget = eTarget
                                return
                            end
                        end
                    -- Auto
                    elseif myHero:GetSpellData(_Q).level > 0 and myHero:GetSpellData(_W).level > 0 then
                        -- EQ -> if Q ready | no collision & W not ready $ mana for Q + E
                        if MENU.eset.auto.stun:Value() and myHero.mana > myHero:GetSpellData(_Q).mana + myHero:GetSpellData(_E).mana then
                            if (LocalGameCanUseSpell(_Q) == 0 or myHero:GetSpellData(_Q).currentCd < 0.75) and not(LocalGameCanUseSpell(_W) == 0 or myHero:GetSpellData(_W).currentCd < 0.75) then
                                local blazeList = {}
                                local enemyList = OB:GetEnemyHeroes(635, false, 0)
                                for i = 1, #enemyList do
                                    local unit = enemyList[i]
                                    if GetBuffDuration(unit, "brandablaze") > 0.33 then
                                        blazeList[#blazeList+1] = unit
                                    end
                                end
                                local eTarget = TS:GetTarget(blazeList, 1)
                                if eTarget and not PREDICTION:IsCollision(eTarget, self.QData) and PREDICTION:CastSpell(HK_E, eTarget) then
                                    return
                                end
                                if LocalGameTimer() > SPELLS.LastQk + 0.77 and LocalGameTimer() > SPELLS.LastWk + 1.33 and LocalGameTimer() > SPELLS.LastRk + 0.77 then
                                    eTarget = TS:GetTarget(enemyList, 1)
                                    if eTarget and not PREDICTION:IsCollision(eTarget, self.QData) and PREDICTION:CastSpell(HK_E, eTarget) then
                                        self.ETarget = eTarget
                                        return
                                    end
                                end
                            end
                        end
                        -- Passive -> If Q not ready & W not ready $ enemy has passive buff
                        if MENU.eset.auto.passive:Value() and not(LocalGameCanUseSpell(_Q) == 0 or myHero:GetSpellData(_Q).currentCd < 0.75) and not(LocalGameCanUseSpell(_W) == 0 or myHero:GetSpellData(_W).currentCd < 0.75) then
                            local blazeList = {}
                            local enemyList = OB:GetEnemyHeroes(670, false, 0)
                            for i = 1, #enemyList do
                                local unit = enemyList[i]
                                if GetBuffDuration(unit, "brandablaze") > 0.33 then
                                    blazeList[#blazeList+1] = unit
                                end
                            end
                            local eTarget = TS:GetTarget(blazeList, 1)
                            if eTarget and PREDICTION:CastSpell(HK_E, eTarget) then
                                self.ETarget = eTarget
                                return
                            end
                        end
                    end
                end
                -- W
                if SPELLS:IsReady(_W, { q = 0.33, w = 0.5, e = 0.33, r = 0.33 } ) then
                    -- antigap
                    local gapList = OB:GetEnemyHeroes(300, false, 0)
                    for i = 1, #gapList do
                        if PREDICTION:CastSpell(HK_W, gapList[i], myHero.pos, self.WData, 1) then
                            return
                        end
                    end
                    -- KS
                    if MENU.wset.killsteal.enabled:Value() then
                        local baseDmg = 30
                        local lvlDmg = 45 * myHero:GetSpellData(_W).level
                        local apDmg = myHero.ap * 0.6
                        local wDmg = baseDmg + lvlDmg + apDmg
                        local minHP = MENU.wset.killsteal.minhp:Value()
                        if wDmg > minHP then
                            local enemyList = OB:GetEnemyHeroes(950, false, 0)
                            for i = 1, #enemyList do
                                local wTarget = enemyList[i]
                                if wTarget.health > minHP and wTarget.health < DMG:CalculateDamage(myHero, wTarget, DAMAGE_TYPE_MAGICAL, wDmg) and PREDICTION:CastSpell(HK_W, wTarget, myHero.pos, self.WData, MENU.wset.killsteal.hitchance:Value()) then
                                    return
                                end
                            end
                        end
                    end
                    -- Combo / Harass
                    if (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.wset.comhar.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.wset.comhar.harass:Value()) then
                        local blazeList = {}
                        local enemyList = OB:GetEnemyHeroes(950, false, 0)
                        for i = 1, #enemyList do
                            local unit = enemyList[i]
                            if GetBuffDuration(unit, "brandablaze") > 1.33 then
                                blazeList[#blazeList+1] = unit
                            end
                        end
                        local wTarget = TS:GetTarget(blazeList, 1)
                        if wTarget and PREDICTION:CastSpell(HK_W, wTarget, myHero.pos, self.WData, MENU.wset.comhar.hitchance:Value()) then
                            return
                        end
                        if LocalGameTimer() > SPELLS.LastQk + 0.77 and LocalGameTimer() > SPELLS.LastEk + 0.77 and LocalGameTimer() > SPELLS.LastRk + 0.77 then
                            local enemyList = OB:GetEnemyHeroes(950, false, 0)
                            local wTarget = TS:GetTarget(enemyList, 1)
                            if wTarget and PREDICTION:CastSpell(HK_W, wTarget, myHero.pos, self.WData, MENU.wset.comhar.hitchance:Value()) then
                                return
                            end
                        end
                    -- Auto
                    elseif MENU.wset.auto.enabled:Value() then
                        for i = 1, 3 do
                            local blazeList = {}
                            local enemyList = OB:GetEnemyHeroes(1200 - (i * 100), false, 0)
                            for j = 1, #enemyList do
                                local unit = enemyList[j]
                                if GetBuffDuration(unit, "brandablaze") > 1.33 then
                                    blazeList[#blazeList+1] = unit
                                end
                            end
                            local wTarget = TS:GetTarget(blazeList, 1)
                            if wTarget and PREDICTION:CastSpell(HK_W, wTarget, myHero.pos, self.WData, MENU.wset.auto.hitchance:Value()) then
                                return
                            end
                            if LocalGameTimer() > SPELLS.LastQk + 0.77 and LocalGameTimer() > SPELLS.LastEk + 0.77 and LocalGameTimer() > SPELLS.LastRk + 0.77 then
                                local enemyList = OB:GetEnemyHeroes(1200 - (i * 100), false, 0)
                                local wTarget = TS:GetTarget(enemyList, 1)
                                if wTarget and PREDICTION:CastSpell(HK_W, wTarget, myHero.pos, self.WData, MENU.wset.auto.hitchance:Value()) then
                                    return
                                end
                            end
                        end
                    end
                end
                -- R
                if SPELLS:IsReady(_R, { q = 0.33, w = 0.33, e = 0.33, r = 0.5 } ) then
                    -- Combo / Harass
                    if (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.rset.comhar.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.rset.comhar.harass:Value()) then
                        local enemyList = OB:GetEnemyHeroes(750, false, 0)
                        local xRange = MENU.rset.comhar.xrange:Value()
                        local xEnemies = MENU.rset.comhar.xenemies:Value()
                        for i = 1, #enemyList do
                            local count = 0
                            local rTarget = enemyList[i]
                            for j = 1, #enemyList do
                                local unit = enemyList[j]
                                if rTarget ~= unit and rTarget.pos:DistanceTo(unit.pos) < xRange then
                                    count = count + 1
                                end
                            end
                            if count >= xEnemies and PREDICTION:CastSpell(HK_R, rTarget) then
                                return
                            end
                        end
                    -- Auto
                    elseif MENU.rset.auto.enabled:Value() then
                        local enemyList = OB:GetEnemyHeroes(750, false, 0)
                        local xRange = MENU.rset.auto.xrange:Value()
                        local xEnemies = MENU.rset.auto.xenemies:Value()
                        for i = 1, #enemyList do
                            local count = 0
                            local rTarget = enemyList[i]
                            for j = 1, #enemyList do
                                local unit = enemyList[j]
                                if rTarget ~= unit and rTarget.pos:DistanceTo(unit.pos) < xRange then
                                    count = count + 1
                                end
                            end
                            if count >= xEnemies and PREDICTION:CastSpell(HK_R, rTarget) then
                                return
                            end
                        end
                    end
                end
            end
            function c:CanMove()
                if not SPELLS:CheckSpellDelays({ q = 0.2, w = 0.2, e = 0.2, r = 0.2 }) then
                    return false
                end
                return true
            end
            function c:CanAttack()
                if not SPELLS:CheckSpellDelays({ q = 0.33, w = 0.33, e = 0.33, r = 0.33 }) then
                    return false
                end
                -- LastHit, LaneClear
                if not ORB.Modes[ORBWALKER_MODE_COMBO] and not ORB.Modes[ORBWALKER_MODE_HARASS] then
                    return true
                end
                -- W
                if MENU.wset.disaa:Value() and myHero:GetSpellData(_W).level > 0 and myHero.mana > myHero:GetSpellData(_W).mana and ( LocalGameCanUseSpell(_W) == 0 or myHero:GetSpellData(_W).currentCd < 1 ) then
                    return false
                end
                -- E
                if MENU.eset.disaa:Value() and myHero:GetSpellData(_E).level > 0 and myHero.mana > myHero:GetSpellData(_E).mana and ( LocalGameCanUseSpell(_E) == 0 or myHero:GetSpellData(_E).currentCd < 1 ) then
                    return false
                end
                return true
            end
            return result
        end,
        Varus = function()
            local c = {}
            local result =
            {
                HasQBuff = false,
                QData = { Delay = 0.1, Radius = 70, Range = 1650, Speed = 1900, Collision = false, Type = SPELLTYPE_LINE },
                EData = { Delay = 0.5, Radius = 235, Range = 925, Speed = 1500, Collision = false, Type = SPELLTYPE_CIRCLE },
                RData = { Delay = 0.25, Radius = 120, Range = 1075, Speed = 1950, Collision = false, Type = SPELLTYPE_LINE }
            }
            -- init
                c.__index = c
                setmetatable(result, c)
            function c:Menu()
                MENU = MenuElement({name = "Gamsteron Varus", id = "gsovarus", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/gsovarussf3f.png" })
                    MENU:MenuElement({name = "Q settings", id = "qset", type = _G.MENU })
                        MENU.qset:MenuElement({id = "combo", name = "Combo", value = true})
                        MENU.qset:MenuElement({id = "harass", name = "Harass", value = false})
                        MENU.qset:MenuElement({id = "stacks", name = "If enemy has 3 W stacks [ W passive ]", value = true})
                        MENU.qset:MenuElement({id = "active", name = "If varus has W buff [ W active ]", value = true})
                        MENU.qset:MenuElement({id = "range", name = "No enemies in AA range", value = true})
                        MENU.qset:MenuElement({id = "hitchance", name = "Hitchance", value = 1, drop = { "normal", "high" } })
                    MENU:MenuElement({name = "W settings", id = "wset", type = _G.MENU })
                        MENU.wset:MenuElement({id = "combo", name = "Combo", value = true})
                        MENU.wset:MenuElement({id = "harass", name = "Harass", value = false})
                        MENU.wset:MenuElement({id = "whp", name = "min. hp %", value = 50, min = 1, max = 100, step = 1})
                    MENU:MenuElement({name = "E settings", id = "eset", type = _G.MENU })
                        MENU.eset:MenuElement({id = "combo", name = "Combo", value = true})
                        MENU.eset:MenuElement({id = "harass", name = "Harass", value = false})
                        MENU.eset:MenuElement({id = "range", name = "No enemies in AA range", value = true})
                        MENU.eset:MenuElement({id = "stacks", name = "If enemy has 3 W stacks [ W passive ]", value = false})
                        MENU.eset:MenuElement({id = "hitchance", name = "Hitchance", value = 1, drop = { "normal", "high" } })
                    MENU:MenuElement({name = "R settings", id = "rset", type = _G.MENU })
                        MENU.rset:MenuElement({id = "combo", name = "Use R Combo", value = true})
                        MENU.rset:MenuElement({id = "harass", name = "Use R Harass", value = false})
                        MENU.rset:MenuElement({id = "rci", name = "Use R if enemy isImmobile", value = true})
                        MENU.rset:MenuElement({id = "rcd", name = "Use R if enemy distance < X", value = true})
                        MENU.rset:MenuElement({id = "rdist", name = "use R if enemy distance < X", value = 500, min = 250, max = 1000, step = 50})
                        MENU.rset:MenuElement({id = "hitchance", name = "Hitchance", value = 1, drop = { "normal", "high" } })
            end
            function c:Tick()
                -- Check Q Buff
                self.HasQBuff = HasBuff(myHero, "varusq")
                -- Is Attacking
                if not self.HasQBuff and ORB:IsAutoAttacking() then
                    return
                end
                -- Can Attack
                local AATarget = TS:GetComboTarget()
                if not self.HasQBuff and AATarget and not ORB.IsNone and ORB:CanAttack() then
                    return
                end
                -- Get Enemies
                local enemyList = OB:GetEnemyHeroes(math.huge, false, 0)
                --R
                if ((ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.rset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.rset.harass:Value())) and SPELLS:IsReady(_R, { q = 0.33, w = 0, e = 0.63, r = 0.5 } ) then
                    if MENU.rset.rcd:Value() then
                        local t = GetClosestEnemy(enemyList, MENU.rset.rdist:Value())
                        if t and PREDICTION:CastSpell(HK_R, t, myHero.pos, self.RData, MENU.rset.hitchance:Value()) then
                            return
                        end
                    end
                    if MENU.rset.rci:Value() then
                        local t = GetImmobileEnemy(enemyList, 900)
                        if t and myHero.pos:DistanceTo(t.pos) < self.RData.Range and PREDICTION:CastSpell(HK_R, t) then
                            return
                        end
                    end
                end
                --E
                if ((ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.eset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.eset.harass:Value())) and SPELLS:IsReady(_E, { q = 0.33, w = 0, e = 0.63, r = 0.33 } ) then
                    local aaRange = MENU.eset.range:Value() and not AATarget
                    local onlyStacksE = MENU.eset.stacks:Value()
                    local eTargets = {}
                    for i = 1, #enemyList do
                        local hero = enemyList[i]
                        if myHero.pos:DistanceTo(hero.pos) < 925 and (GetBuffCount(hero, "varuswdebuff") == 3 or not onlyStacksE or myHero:GetSpellData(_W).level == 0 or aaRange) then
                            eTargets[#eTargets+1] = hero
                        end
                    end
                    local t = TS:GetTarget(eTargets, 0)
                    if t and PREDICTION:CastSpell(HK_E, t, myHero.pos, self.EData, MENU.eset.hitchance:Value()) then
                        return
                    end
                end
                -- Q
                if (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.qset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.qset.harass:Value()) then
                    local aaRange = MENU.qset.range:Value() and not AATarget
                    local wActive = MENU.qset.active:Value() and LocalGameTimer() < SPELLS.LastWk + 3
                    -- Q1
                    if not self.HasQBuff and SPELLS:IsReady(_Q, { q = 0.5, w = 0.1, e = 1, r = 0.33 } ) then
                        if LocalControlIsKeyDown(HK_Q) then
                            LocalControlKeyUp(HK_Q)
                        end
                        -- W
                        if ((ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.wset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.wset.harass:Value())) and SPELLS:IsReady(_W, { q = 0.33, w = 0.5, e = 0.63, r = 0.33 } ) then
                            local whp = MENU.wset.whp:Value()
                            for i = 1, #enemyList do
                                local hero = enemyList[i]
                                local hp = 100 * ( hero.health / hero.maxHealth )
                                if hp < whp and myHero.pos:DistanceTo(hero.pos) < 1500 and PREDICTION:CastSpell(HK_W) then
                                    return
                                end
                            end
                        end
                        local onlyStacksQ = MENU.qset.stacks:Value()
                        for i = 1, #enemyList do
                            local hero = enemyList[i]
                            if myHero.pos:DistanceTo(hero.pos) < 1500 and (GetBuffCount(hero, "varuswdebuff") == 3 or not onlyStacksQ or myHero:GetSpellData(_W).level == 0 or wActive or aaRange) then
                                LocalControlKeyDown(HK_Q)
                                SPELLS.LastQ = LocalGameTimer()
                                return
                            end
                        end
                    -- Q2
                    elseif self.HasQBuff and SPELLS:IsReady(_Q, { q = 0.2, w = 0, e = 0.63, r = 0.33 } ) then
                        local qTargets = {}
                        local onlyStacksQ = MENU.qset.stacks:Value()
                        for i = 1, #enemyList do
                            local hero = enemyList[i]
                            if myHero.pos:DistanceTo(hero.pos) < 1650 and (GetBuffCount(hero, "varuswdebuff") == 3 or not onlyStacksQ or myHero:GetSpellData(_W).level == 0 or wActive or aaRange) then
                                qTargets[#qTargets+1] = hero
                            end
                        end
                        if #qTargets == 0 then
                            for i = 1, #enemyList do
                                local hero = enemyList[i]
                                if myHero.pos:DistanceTo(hero.pos) < 1650 then
                                    qTargets[#qTargets+1] = hero
                                end
                            end
                        end
                        local qkey = SPELLS.LastQk - 0.33
                        local qTimer = LocalGameTimer() - qkey
                        local qExtraRange
                        if qTimer < 2 then
                            qExtraRange = qTimer * 0.5 * 700
                        else
                            qExtraRange = 700
                        end
                        local qRange = 925 + qExtraRange
                        local t = TS:GetTarget(qTargets, 0)
                        if t and PREDICTION:CastSpell(HK_Q, t, myHero.pos, self.QData, MENU.qset.hitchance:Value()) then
                            return
                        end
                    end
                end
            end
            function c:CanAttack()
                self.HasQBuff = HasBuff(myHero, "varusq")
                if not SPELLS:CheckSpellDelays({ q = 0.33, w = 0, e = 0.33, r = 0.33 }) then
                    return false
                end
                if self.HasQBuff == true then
                    return false
                end
                return true
            end
            function c:CanMove()
                if not SPELLS:CheckSpellDelays({ q = 0.2, w = 0, e = 0.2, r = 0.2 }) then
                    return false
                end
                return true
            end
            return result
        end,
        Vayne = function()
            require "MapPositionGOS"
            local c = {}
            local result =
            {
                LastReset = 0,
                EData = { Delay = 0.5, Radius = 0, Range = 550 + myHero.boundingRadius + 35, Speed = 2000, Collision = false, Type = SPELLTYPE_LINE }
            }
            -- init
                c.__index = c
                setmetatable(result, c)
            function c:Menu()
                MENU = MenuElement({name = "Gamsteron Vayne", id = "gsovayne", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/vayne.png" })
                    -- Q
                    MENU:MenuElement({name = "Q settings", id = "qset", type = _G.MENU })
                        MENU.qset:MenuElement({id = "combo", name = "Combo", value = true})
                        MENU.qset:MenuElement({id = "harass", name = "Harass", value = false})
                    -- E
                    MENU:MenuElement({name = "E settings", id = "eset", type = _G.MENU })
                        MENU.eset:MenuElement({id = "interrupt", name = "Interrupt dangerous spells", value = true})
                        MENU.eset:MenuElement({id = "combo", name = "Combo (Stun)", value = true})
                        MENU.eset:MenuElement({id = "harass", name = "Harass (Stun)", value = false})
                        MENU.eset:MenuElement({id = "hitchance", name = "Hitchance", value = 1, drop = { "fastest", "normal", "high" } })
                        MENU.eset:MenuElement({name = "Use on (Stun):", id = "useonstun", type = _G.MENU })
                            Core:OnEnemyHeroLoad(function(hero) MENU.eset.useonstun:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
                    --R
                    MENU:MenuElement({name = "R settings", id = "rset", type = _G.MENU })
                        MENU.rset:MenuElement({id = "qready", name = "Only if Q ready or almost ready", value = true})
                        MENU.rset:MenuElement({id = "combo", name = "Combo - if X enemies near vayne", value = true})
                        MENU.rset:MenuElement({id = "xcount", name = "  ^^^ X enemies ^^^", value = 3, min = 1, max = 5, step = 1})
                        MENU.rset:MenuElement({id = "xdistance", name = "^^^ max. distance ^^^", value = 500, min = 250, max = 750, step = 50})
            end
            function c:Tick()
                -- reset attack after Q
                if LocalGameCanUseSpell(_Q) ~= 0 and LocalGameTimer() > self.LastReset + 1 and HasBuff(myHero, "vaynetumblebonus") then
                    ORB:__OnAutoAttackReset()
                    self.LastReset = LocalGameTimer()
                end
                -- Is Attacking
                if ORB:IsAutoAttacking() then
                    return
                end
                -- Can Attack
                local AATarget = TS:GetComboTarget()
                if AATarget and not ORB.IsNone and ORB:CanAttack() then
                    return
                end
                -- R
                if ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.rset.combo:Value() and SPELLS:IsReady(_R, { q = 0.5, w = 0, e = 0.5, r = 0.5 } ) then
                    local canR = true
                    if MENU.rset.qready:Value() then
                        if not((LocalGameCanUseSpell(_Q) == 0) or (LocalGameCanUseSpell(_Q) == 32 and myHero.mana > myHero:GetSpellData(_Q).mana and myHero:GetSpellData(_Q).currentCd < 0.75)) then
                            canR = false
                        end
                    end
                    if canR then
                        local enemyList = OB:GetEnemyHeroes(MENU.rset.xdistance:Value(), false, 0)
                        if #enemyList >= MENU.rset.xcount:Value() and PREDICTION:CastSpell(HK_R) then
                            return
                        end
                    end
                end
                -- E
                if (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.eset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.eset.harass:Value()) then
                    if SPELLS:IsReady(_E, { q = 0.3, w = 0, e = 0.5, r = 0 } ) then
                        local enemyList = OB:GetEnemyHeroes(550+myHero.boundingRadius, true, 0)
                        for i = 1, #enemyList do
                            local hero = enemyList[i]
                            local name = hero.charName
                            local latency = Core:GetLatency()
                            if MENU.eset.useonstun[name] and MENU.eset.useonstun[name]:Value() and CheckWall(myHero.pos, hero.pos, 475) and CheckWall(myHero.pos, hero:GetPrediction(math.huge,0.5+0.15+latency), 475) then
                                local menuHC = MENU.eset.hitchance:Value()
                                if menuHC == 1 and PREDICTION:CastSpell(HK_E, hero) then
                                    return
                                end
                                local castPos, hitChance = PREDICTION:GetPrediction(hero, myHero.pos, self.EData)
                                if castPos ~= nil and hitChance ~= nil and hitChance >= 1 then
                                    if menuHC == 2 and CheckWall(myHero.pos, castPos, 475) and PREDICTION:CastSpell(HK_E, hero) then
                                        return
                                    end
                                    if menuHC == 3 and hitChance >= 2 and CheckWall(myHero.pos, castPos, 475) and PREDICTION:CastSpell(HK_E, hero) then
                                        return
                                    end
                                end
                            end
                        end
                    end
                end
                --Q
                if (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.qset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.qset.harass:Value()) then
                    if SPELLS:IsReady(_Q, { q = 0.5, w = 0, e = 0.5, r = 0 } ) then
                        local mePos = myHero.pos
                        local meRange = myHero.range + myHero.boundingRadius
                        local enemyList = OB:GetEnemyHeroes(1000, false, 1)
                        for i = 1, #enemyList do
                            local hero = enemyList[i]
                            if mePos:DistanceTo(mousePos) > 300 and mePos:Extended(mousePos, 300):DistanceTo(hero.pos) < meRange + hero.boundingRadius - 35 and PREDICTION:CastSpell(HK_Q) then
                                return
                            end
                        end
                    end
                end
            end
            function c:Interrupter()
                INTERRUPTER = META.Interrupter()
                INTERRUPTER.Callback[#INTERRUPTER.Callback+1] = function(enemy, activeSpell)
                    if MENU.eset.interrupt:Value() and SPELLS:IsReady(_E, { q = 0.3, w = 0, e = 0.5, r = 0 } ) then
                        PREDICTION:CastSpell(HK_E, enemy)
                    end
                end
            end
            function c:CanAttack()
                if not SPELLS:CheckSpellDelays({ q = 0.3, w = 0, e = 0.5, r = 0 }) then
                    return false
                end
                return true
            end
            function c:CanMove()
                if not SPELLS:CheckSpellDelays({ q = 0.2, w = 0, e = 0.4, r = 0 }) then
                    return false
                end
                return true
            end
            return result
        end,
        Ezreal = function()
            local c = {}
            local result =
            {
                resX = Game.Resolution().x,
                resY = Game.Resolution().y,
                QData = { Delay = 0.25, Radius = 60, Range = 1150, Speed = 2000, Collision = true, Type = SPELLTYPE_LINE },
                WData = { Delay = 0.25, Radius = 80, Range = 1150, Speed = 1550, Collision = false, Type = SPELLTYPE_LINE },
                QFarm = nil
            }
            -- init
                c.__index = c
                setmetatable(result, c)
            function c:Menu()
                MENU = MenuElement({name = "Gamsteron Ezreal", id = "gsoezreal", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/ezreal.png" })
                    MENU:MenuElement({name = "Spells", id = "spells", type = _G.MENU })
                        MENU.spells:MenuElement({id = "q", name = "Q", value = false, key = string.byte("Q"), toggle = true})
                        MENU.spells:MenuElement({id = "w", name = "W", value = false, key = string.byte("W"), toggle = true})
                        MENU.spells:MenuElement({id = "e", name = "E", value = false, key = string.byte("E"), toggle = true})
                        MENU.spells:MenuElement({id = "r", name = "R", value = false, key = string.byte("R"), toggle = true})
                        MENU.spells:MenuElement({id = "d", name = "D", value = false, key = string.byte("D"), toggle = true})
                        MENU.spells:MenuElement({id = "f", name = "F", value = false, key = string.byte("F"), toggle = true})
                    MENU:MenuElement({name = "Auto Q", id = "autoq", type = _G.MENU })
                        MENU.autoq:MenuElement({id = "enable", name = "Enable", value = true, key = string.byte("T"), toggle = true})
                        MENU.autoq:MenuElement({id = "mana", name = "Q Auto min. mana percent", value = 50, min = 0, max = 100, step = 1 })
                        MENU.autoq:MenuElement({id = "hitchance", name = "Hitchance", value = 1, drop = { "normal", "high" } })
                    MENU:MenuElement({name = "Q settings", id = "qset", type = _G.MENU })
                        MENU.qset:MenuElement({id = "hitchance", name = "Hitchance", value = 1, drop = { "normal", "high" } })
                        MENU.qset:MenuElement({id = "combo", name = "Combo", value = true})
                        MENU.qset:MenuElement({id = "harass", name = "Harass", value = false})
                        MENU.qset:MenuElement({id = "clearm", name = "LaneClear/LastHit", type = _G.MENU })
                            MENU.qset.clearm:MenuElement({id = "lhenabled", name = "LastHit Enabled", value = true})
                            MENU.qset.clearm:MenuElement({id = "lhmana", name = "LastHit Min. Mana %", value = 50, min = 0, max = 100, step = 5 })
                            MENU.qset.clearm:MenuElement({id = "lcenabled", name = "LaneClear Enabled", value = false})
                            MENU.qset.clearm:MenuElement({id = "lcmana", name = "LaneClear Min. Mana %", value = 75, min = 0, max = 100, step = 5 })
                    MENU:MenuElement({name = "W settings", id = "wset", type = _G.MENU })
                        MENU.wset:MenuElement({id = "hitchance", name = "Hitchance", value = 1, drop = { "normal", "high" } })
                        MENU.wset:MenuElement({id = "combo", name = "Combo", value = true})
                        MENU.wset:MenuElement({id = "harass", name = "Harass", value = false})
                    MENU:MenuElement({name = "Drawings", id = "draws", type = _G.MENU })
                        MENU.draws:MenuElement({name = "Auto Q", id = "autoq", type = _G.MENU })
                            MENU.draws.autoq:MenuElement({id = "enabled", name = "Enabled", value = true})
                            MENU.draws.autoq:MenuElement({id = "size", name = "Text Size", value = 25, min = 1, max = 64, step = 1 })
                            MENU.draws.autoq:MenuElement({id = "custom", name = "Custom Position", value = false})
                            MENU.draws.autoq:MenuElement({id = "posX", name = "Text Position Width", value = self.resX * 0.5 - 150, min = 1, max = self.resX, step = 1 })
                            MENU.draws.autoq:MenuElement({id = "posY", name = "Text Position Height", value = self.resY * 0.5, min = 1, max = self.resY, step = 1 })
                        MENU.draws:MenuElement({name = "Q Farm", id = "qfarm", type = _G.MENU })
                            MENU.draws.qfarm:MenuElement({name = "LastHitable Minion",  id = "lasthit", type = MENU})
                                MENU.draws.qfarm.lasthit:MenuElement({name = "Enabled",  id = "enabled", value = true})
                                MENU.draws.qfarm.lasthit:MenuElement({name = "Color",  id = "color", color = LocalDrawColor(150, 255, 255, 255)})
                                MENU.draws.qfarm.lasthit:MenuElement({name = "Width",  id = "width", value = 3, min = 1, max = 10})
                                MENU.draws.qfarm.lasthit:MenuElement({name = "Radius",  id = "radius", value = 50, min = 1, max = 100})
                            MENU.draws.qfarm:MenuElement({name = "Almost LastHitable Minion",  id = "almostlasthit", type = MENU})
                                MENU.draws.qfarm.almostlasthit:MenuElement({name = "Enabled",  id = "enabled", value = true})
                                MENU.draws.qfarm.almostlasthit:MenuElement({name = "Color",  id = "color", color = LocalDrawColor(150, 239, 159, 55)})
                                MENU.draws.qfarm.almostlasthit:MenuElement({name = "Width",  id = "width", value = 3, min = 1, max = 10})
                                MENU.draws.qfarm.almostlasthit:MenuElement({name = "Radius",  id = "radius", value = 50, min = 1, max = 100})
            end
            function c:Tick()

                -- [ mana percent ]
                local manaPercent = 100 * myHero.mana / myHero.maxMana

                -- [ q farm ]
                if MENU.qset.clearm.lhenabled:Value() or MENU.qset.clearm.lcenabled:Value() then
                    if manaPercent > MENU.qset.clearm.lhmana:Value() then
                        self.QFarm:Tick()
                    end
                end
                
                -- [ e manual ]
                SPELLS:CastManualSpell(_E, { q = 0.33, w = 0.33, e = 0.5, r = 1.13 })

                -- [ is attacking ]
                if ORB:IsAutoAttacking() then
                    return
                end

                -- [ get attack target ]
                local AATarget = TS:GetComboTarget()

                -- [ can attack ]
                if AATarget and not ORB.IsNone and ORB:CanAttack() then
                    return
                end

                -- [ use q ]
                if SPELLS:IsReady(_Q, { q = 0.5, w = 0.33, e = 0.33, r = 1.13 } ) then

                    -- [ combo / harass ]
                    if (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.qset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.qset.harass:Value()) then
                        local QTarget
                        if AATarget then
                            QTarget = AATarget
                        else
                            QTarget = TS:GetTarget(OB:GetEnemyHeroes(1150, false, 0), 0)
                        end
                        if QTarget and PREDICTION:CastSpell(HK_Q, QTarget, myHero.pos, self.QData, MENU.qset.hitchance:Value()) then
                            return
                        end

                    -- [ auto ]
                    elseif MENU.autoq.enable:Value() and manaPercent > MENU.autoq.mana:Value() then
                        local enemyHeroes = OB:GetEnemyHeroes(1150, false, 0)
                        for i = 1, #enemyHeroes do
                            local unit = enemyHeroes[i]
                            if unit and PREDICTION:CastSpell(HK_Q, unit, myHero.pos, self.QData, MENU.autoq.hitchance:Value()) then
                                return
                            end
                        end
                    end

                    -- [ cast q clear ]
                    if MENU.qset.clearm.lhenabled:Value() and not ORB.IsNone and not ORB.Modes[ORBWALKER_MODE_COMBO] and manaPercent > MENU.qset.clearm.lhmana:Value() then
                        -- [ last hit ]
                        local lhtargets = self.QFarm:GetLastHitTargets()
                        for i = 1, #lhtargets do
                            local unit = lhtargets[i]
                            if not unit.dead and not unit.pathing.hasMovePath and not PREDICTION:IsMinionCollision(unit, self.QData) and PREDICTION:CastSpell(HK_Q, unit) then
                                ORB:SetAttack(false)
                                DelayAction(function() ORB:SetAttack(true) end, self.QData.Delay + (unit.pos:DistanceTo(myHero.pos) / self.QData.Speed) + 0.05)
                                return
                            end
                        end
                    end
                    if MENU.qset.clearm.lcenabled:Value() and ORB.Modes[ORBWALKER_MODE_LANECLEAR] and not self.QFarm:ShouldWait() and manaPercent > MENU.qset.clearm.lcmana:Value() then
                        -- [ enemy heroes ]
                        local enemyHeroes = OB:GetEnemyHeroes(self.Range, false, "spell")
                        for i = 1, #enemyHeroes do
                            local unit = enemyHeroes[i]
                            if unit and self:CastSpell(HK_Q, unit, myHero.pos, self.QData, MENU.qset.hitchance:Value()) then
                                return
                            end
                        end
                        -- [ lane clear ]
                        local lctargets = self.QFarm:GetLaneClearTargets()
                        for i = 1, #lctargets do
                            local unit = lctargets[i]
                            if not unit.dead and not unit.pathing.hasMovePath and not PREDICTION:IsMinionCollision(unit, self.QData) and PREDICTION:CastSpell(HK_Q, unit) then
                                return
                            end
                        end
                    end
                end

                -- [ use w ]
                if SPELLS:IsReady(_W, { q = 0.33, w = 0.5, e = 0.33, r = 1.13 } ) then
                    if (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.wset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.wset.harass:Value()) then
                        local WTarget
                        if AATarget then
                            WTarget = AATarget
                        else
                            WTarget = TS:GetTarget(OB:GetEnemyHeroes(1000, false, 0), 0)
                        end
                        if WTarget and PREDICTION:CastSpell(HK_W, WTarget, myHero.pos, self.WData, MENU.wset.hitchance:Value()) then
                            return
                        end
                    end
                end
            end
            function c:Draw()
                if MENU.draws.autoq.enabled:Value() then
                    local mePos = myHero.pos:To2D()
                    local isCustom = MENU.draws.autoq.custom:Value()
                    local posX, posY
                    if isCustom then
                        posX = MENU.draws.autoq.posX:Value()
                        posY = MENU.draws.autoq.posY:Value()
                    else
                        posX = mePos.x - 50
                        posY = mePos.y
                    end
                    if MENU.autoq.enable:Value() then
                        LocalDrawText("Auto Q Enabled", MENU.draws.autoq.size:Value(), posX, posY, LocalDrawColor(255, 000, 255, 000))
                    else
                        LocalDrawText("Auto Q Disabled", MENU.draws.autoq.size:Value(), posX, posY, LocalDrawColor(255, 255, 000, 000))
                    end
                end
                -- [ q farm ]
                local lhmenu = MENU.draws.qfarm.lasthit
                local lcmenu = MENU.draws.qfarm.almostlasthit
                if lhmenu.enabled:Value() or lcmenu.enabled:Value() then
                    local fm = self.QFarm.FarmMinions
                    for i = 1, #fm do
                        local minion = fm[i]
                        if minion.LastHitable and lhmenu.enabled:Value() then
                            LocalDrawCircle(minion.Minion.pos,lhmenu.radius:Value(),lhmenu.width:Value(),lhmenu.color:Value())
                        elseif minion.AlmostLastHitable and lcmenu.enabled:Value() then
                            LocalDrawCircle(minion.Minion.pos,lcmenu.radius:Value(),lcmenu.width:Value(),lcmenu.color:Value())
                        end
                    end
                end
            end
            function c:QClear()
                self.QFarm = SPELLS:SpellClear(_Q, self.QData, function() return ((25 * myHero:GetSpellData(_Q).level) - 10) + (1.1 * myHero.totalDamage) + (0.4 * myHero.ap) end)
            end
            function c:CanAttack()
                if not SPELLS:CheckSpellDelays({ q = 0.33, w = 0.33, e = 0.33, r = 1.13 }) then
                    return false
                end
                return true
            end
            function c:CanMove()
                if not SPELLS:CheckSpellDelays({ q = 0.2, w = 0.2, e = 0.2, r = 1 }) then
                    return false
                end
                return true
            end
            return result
        end
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Load:                                                                                                                                                
    Callback.Add("Load", function()
        AIO_LOADED = true
        PREDICTION = META.Prediction2()
        ORB = _G.SDK.Orbwalker
        SPELLS = _G.SDK.Spells
        TS = _G.SDK.TargetSelector
        DMG = _G.SDK.Damage
        OB = _G.SDK.ObjectManager
        CHAMPION = META[LocalCharName]()
        if CHAMPION.Menu then
            CHAMPION:Menu()
        end
        if CHAMPION.QClear then
            CHAMPION:QClear()
        end
        if CHAMPION.WClear then
            CHAMPION:WClear()
        end
        if CHAMPION.EClear then
            CHAMPION:EClear()
        end
        if CHAMPION.RClear then
            CHAMPION:RClear()
        end
        if CHAMPION.Interrupter then
            CHAMPION:Interrupter()
        end
        if CHAMPION.CanAttack then
            ORB.CanAttackC = function() return CHAMPION:CanAttack() end
        end
        if CHAMPION.CanMove then
            ORB.CanMoveC = function() return CHAMPION:CanMove() end
        end
        if CHAMPION.PreAttack then
            ORB:OnPreAttack(function(args) CHAMPION:PreAttack(args) end)
        end
        if CHAMPION.Tick then
            Callback.Add("Tick", function()
                --PREDICTION:SaveWaypoints(OB:GetEnemyHeroes(15000))
                CHAMPION:Tick()
                if INTERRUPTER ~= nil then
                    INTERRUPTER:Tick()
                end
            end)
        end
        if CHAMPION.Draw then
            Callback.Add('Draw', function()
                CHAMPION:Draw()
                --PREDICTION:SaveWaypoints(OB:GetEnemyHeroes(15000))
            end)
        end
        if CHAMPION.WndMsg then
            Callback.Add('WndMsg', function(msg, wParam) CHAMPION:WndMsg(msg, wParam) end)
        end
    end)
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    _G.GamsteronAIOLoaded = true
--------------------------------------------------------------------------------------------------------------------------------------------------------
