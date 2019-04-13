local GamsteronAIOVer = 0.0794
local LocalCore, Menu, CHAMPION, INTERRUPTER, ORB, TS, OB, DMG, SPELLS
do
    if _G.GamsteronAIOLoaded == true then return end
    _G.GamsteronAIOLoaded = true
    
    local SUPPORTED_CHAMPIONS =
    {
        ["Tristana"] = true,
        
    }
    
--locals
local GetTickCount = GetTickCount
local myHero = myHero
local LocalCharName = myHero.charName
local LocalVector = Vector
local LocalOsClock = os.clock
local LocalCallbackAdd = Callback.Add
local LocalCallbackDel = Callback.Del
local LocalDrawLine = Draw.Linek
local LocalDrawColor = Draw.Color
local LocalDrawCircle = Draw.Circle
local LocalDrawText = Draw.Text
local LocalControlIsKeyDown = Control.IsKeyDown
local LocalControlMouseEvent = Control.mouse_event
local LocalControlSetCursorPos = Control.SetCursorPos
local LocalControlKeyUp = Control.KeyUp
local LocalControlKeyDown = Control.KeyDown
local LocalGameCanUseSpell = Game.CanUseSpell
local LocalGameLatency = Game.Latency
local LocalGameTimer = Game.Timer
local LocalGameParticleCount = Game.ParticleCount
local LocalGameParticle = Game.Particle
local LocalGameHeroCount = Game.HeroCount
local LocalGameHero = Game.Hero
local LocalGameMinionCount = Game.MinionCount
local LocalGameMinion = Game.Minion
local LocalGameTurretCount = Game.TurretCount
local LocalGameTurret = Game.Turret
local LocalGameWardCount = Game.WardCount
local LocalGameWard = Game.Ward
local LocalGameObjectCount = Game.ObjectCount
local LocalGameObject = Game.Object
local LocalGameMissileCount = Game.MissileCount
local LocalGameMissile = Game.Missile
local LocalGameIsChatOpen = Game.IsChatOpen
local LocalGameIsOnTop = Game.IsOnTop
local STATE_UNKNOWN = STATE_UNKNOWN
local STATE_ATTACK = STATE_ATTACK
local STATE_WINDUP = STATE_WINDUP
local STATE_WINDDOWN = STATE_WINDDOWN
local ITEM_1 = ITEM_1
local ITEM_2 = ITEM_2
local ITEM_3 = ITEM_3
local ITEM_4 = ITEM_4
local ITEM_5 = ITEM_5
local ITEM_6 = ITEM_6
local ITEM_7 = ITEM_7
local _Q = _Q
local _W = _W
local _E = _E
local _R = _R
local MOUSEEVENTF_RIGHTDOWN = MOUSEEVENTF_RIGHTDOWN
local MOUSEEVENTF_RIGHTUP = MOUSEEVENTF_RIGHTUP
local Obj_AI_Barracks = Obj_AI_Barracks
local Obj_AI_Hero = Obj_AI_Hero
local Obj_AI_Minion = Obj_AI_Minion
local Obj_AI_Turret = Obj_AI_Turret
local Obj_HQ = "obj_HQ"
local pairs = pairs
local LocalMathCeil = math.ceil
local LocalMathMax = math.max
local LocalMathMin = math.min
local LocalMathSqrt = math.sqrt
local LocalMathRandom = math.random
local LocalMathHuge = math.huge
local LocalMathAbs = math.abs
local LocalStringSub = string.sub
local LocalStringLen = string.len
local EPSILON = 1E-12
local TEAM_ALLY = myHero.team
local TEAM_ENEMY = 300 - TEAM_ALLY
local TEAM_JUNGLE = 300
local ORBWALKER_MODE_NONE = -1
local ORBWALKER_MODE_COMBO = 0
local ORBWALKER_MODE_HARASS = 1
local ORBWALKER_MODE_LANECLEAR = 2
local ORBWALKER_MODE_JUNGLECLEAR = 3
local ORBWALKER_MODE_LASTHIT = 4
local ORBWALKER_MODE_FLEE = 5
local DAMAGE_TYPE_PHYSICAL = 0
local DAMAGE_TYPE_MAGICAL = 1
local DAMAGE_TYPE_TRUE = 2
local function CheckWall(from, to, distance)
    local pos1 = to + (to - from):Normalized() * 50
    local pos2 = pos1 + (to - from):Normalized() * (distance - 50)
    local point1 = Point(pos1.x, pos1.z)
    local point2 = Point(pos2.x, pos2.z)
    if MapPosition:intersectsWall(LineSegment(point1, point2)) or (MapPosition:inWall(point1) and MapPosition:inWall(point2)) then
        return true
    end
    return false
end
local function CastSpell(spell, unit, spelldata, hitchance)
    if LocalCore:IsValidTarget(unit) then
        local HitChance = hitchance or 3
        local Pred = GetGamsteronPrediction(unit, spelldata, myHero)
        if Pred.Hitchance >= HitChance then
            return LocalCore:CastSpell(spell, nil, Pred.CastPosition)
        end
    end
    return false
end
Tristana = function()
        require "MapPositionGOS"
        if Menu.eset.melee:Value() then
                    local meleeHeroes = {}
                    for i = 1, LocalGameHeroCount() do
                        local hero = LocalGameHero(i)
                        if LocalCore:IsValidTarget(hero) and hero.team == LocalCore.TEAM_ENEMY and hero.range < 400 and Menu.eset.useonmelee[hero.charName] and Menu.eset.useonmelee[hero.charName]:Value() and myHero.pos:DistanceTo(hero.pos) < hero.range + myHero.boundingRadius + hero.boundingRadius then
                            _G.table.insert(meleeHeroes, hero)
                        end
                    end
                    if #meleeHeroes > 0 then
                        _G.table.sort(meleeHeroes, function(a, b) return a.health + (a.totalDamage * 2) + (a.attackSpeed * 100) > b.health + (b.totalDamage * 2) + (b.attackSpeed * 100) end)
                        local meleeTarget = meleeHeroes[1]
                        if LocalCore:IsFacing(meleeTarget, myHero, 60) then
                            Control.CastSpell(HK_R, meleeTarget)
                            result = true
                        end
                    end
                end
 
        end)
    end
end)
