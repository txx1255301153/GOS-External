 require('GamsteronPrediction')
    if _G.GamsteronPredictionUpdated then
        return
    end
    
    require('GamsteronCore')
    if _G.GamsteronCoreUpdated then return end
    LocalCore = _G.GamsteronCore
    
    local success, version = LocalCore:AutoUpdate({
        version = GamsteronAIOVer,
        scriptPath = SCRIPT_PATH .. "GamsteronAIO.lua",
        scriptUrl = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/GamsteronAIO.lua",
        versionPath = SCRIPT_PATH .. "GamsteronAIO.version",
        versionUrl = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/GamsteronAIO.version"
    })
    if success then
        print("GamsteronAIO updated to version " .. version .. ". Please Reload with 2x F6 !")
        _G.GamsteronAIOUpdated = true
        return
    end
end
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
        Menu = MenuElement({name = "Gamsteron KogMaw", id = "Gamsteron_KogMaw", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Icons/kog.png"})
        -- Q
        Menu:MenuElement({name = "Q settings", id = "qset", type = _G.MENU})
        Menu.qset:MenuElement({id = "combo", name = "Combo", value = true})
        Menu.qset:MenuElement({id = "harass", name = "Harass", value = false})
        Menu.qset:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = {"normal", "high"}})
        -- W
        Menu:MenuElement({name = "W settings", id = "wset", type = _G.MENU})
        Menu.wset:MenuElement({id = "combo", name = "Combo", value = true})
        Menu.wset:MenuElement({id = "harass", name = "Harass", value = false})
        Menu.wset:MenuElement({id = "stopq", name = "Stop Q if has W buff", value = false})
        Menu.wset:MenuElement({id = "stope", name = "Stop E if has W buff", value = false})
        Menu.wset:MenuElement({id = "stopr", name = "Stop R if has W buff", value = false})
        -- E
        Menu:MenuElement({name = "E settings", id = "eset", type = _G.MENU})
        Menu.eset:MenuElement({id = "combo", name = "Combo", value = true})
        Menu.eset:MenuElement({id = "harass", name = "Harass", value = false})
        Menu.eset:MenuElement({id = "emana", name = "Minimum Mana %", value = 20, min = 1, max = 100, step = 1})
        Menu.eset:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = {"normal", "high"}})
        -- R
        Menu:MenuElement({name = "R settings", id = "rset", type = _G.MENU})
        Menu.rset:MenuElement({id = "combo", name = "Combo", value = true})
        Menu.rset:MenuElement({id = "harass", name = "Harass", value = false})
        Menu.rset:MenuElement({id = "onlylow", name = "Only 0-40 % HP enemies", value = true})
        Menu.rset:MenuElement({id = "stack", name = "Stop at x stacks", value = 3, min = 1, max = 9, step = 1})
        Menu.rset:MenuElement({id = "rmana", name = "Minimum Mana %", value = 20, min = 1, max = 100, step = 1})
        Menu.rset:MenuElement({name = "KS", id = "ksmenu", type = _G.MENU})
        Menu.rset.ksmenu:MenuElement({id = "ksr", name = "KS - Enabled", value = true})
        Menu.rset.ksmenu:MenuElement({id = "csksr", name = "KS -> Check R stacks", value = false})
        Menu.rset:MenuElement({name = "Semi Manual", id = "semirkog", type = _G.MENU})
        Menu.rset.semirkog:MenuElement({name = "Semi-Manual Key", id = "semir", key = string.byte("T")})
        Menu.rset.semirkog:MenuElement({name = "Check R stacks", id = "semistacks", value = false})
        Menu.rset.semirkog:MenuElement({name = "Only 0-40 % HP enemies", id = "semilow", value = false})
        Menu.rset.semirkog:MenuElement({name = "Use on:", id = "useon", type = _G.MENU})
        LocalCore:OnEnemyHeroLoad(function(hero) Menu.rset.semirkog.useon:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
        Menu.rset:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = {"normal", "high"}})
        -- Version
        Menu:MenuElement({name = "Version " .. tostring(KogMawVersion), type = _G.SPACE, id = "verspace"})
        CHAMPION = LocalCore:Class()
        function CHAMPION:__init()
            self.QData = {delay = 0.25, radius = 70, range = 1175, speed = 1650, collision = true, type = _G.SPELLTYPE_LINE}
            self.EData = {delay = 0.25, radius = 120, range = 1280, speed = 1350, collision = false, type = _G.SPELLTYPE_LINE}
            self.RData = {delay = 1.2, radius = 225, range = 0, speed = math.huge, collision = false, type = _G.SPELLTYPE_CIRCLE}
            self.HasWBuff = false
        end
        function CHAMPION:Tick()
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
            if ((ORB.Modes[ORBWALKER_MODE_COMBO] and Menu.wset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and Menu.wset.harass:Value())) and ORB:IsBeforeAttack(0.55) and SPELLS:IsReady(_W, {q = 0.33, w = 0.5, e = 0.33, r = 0.33}) then
                local enemyList = OB:GetEnemyHeroes(610 + (20 * myHero:GetSpellData(_W).level) + myHero.boundingRadius - 35, true, 1)
                if #enemyList > 0 and Control.CastSpell(HK_W) then
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
            local wMana = 40 - (myHero:GetSpellData(_W).currentCd * myHero.mpRegen)
            local meMana = myHero.mana - wMana
            if not(AATarget) and (LocalGameTimer() < SPELLS.LastW + 0.3 or LocalGameTimer() < SPELLS.LastWk + 0.3) then
                return
            end
            -- R
            local result = false
            if meMana > myHero:GetSpellData(_R).mana and SPELLS:IsReady(_R, {q = 0.33, w = 0.15, e = 0.33, r = 0.5}) then
                self.RData.range = 900 + 300 * myHero:GetSpellData(_R).level
                local enemyList = OB:GetEnemyHeroes(self.RData.range, false, 0)
                local rStacks = LocalCore:GetBuffCount(myHero, "kogmawlivingartillerycost") < Menu.rset.stack:Value()
                local checkRStacksKS = Menu.rset.ksmenu.csksr:Value()
                -- KS
                if Menu.rset.ksmenu.ksr:Value() and (not checkRStacksKS or rStacks) then
                    local rTargets = {}
                    for i = 1, #enemyList do
                        local hero = enemyList[i]
                        local baseRDmg = 60 + (40 * myHero:GetSpellData(_R).level) + (myHero.bonusDamage * 0.65) + (myHero.ap * 0.25)
                        local rMultipier = math.floor(100 - (((hero.health + (hero.hpRegen * 3)) * 100) / hero.maxHealth))
                        local rDmg
                        if rMultipier > 60 then
                            rDmg = baseRDmg * 2
                        else
                            rDmg = baseRDmg * (1 + (rMultipier * 0.00833))
                        end
                        rDmg = DMG:CalculateDamage(myHero, hero, DAMAGE_TYPE_MAGICAL, rDmg)
                        local unitKillable = rDmg > hero.health + (hero.hpRegen * 2)
                        if unitKillable then
                            rTargets[#rTargets + 1] = hero
                        end
                    end
                    result = CastSpell(HK_R, TS:GetTarget(rTargets, 1), self.RData, Menu.rset.hitchance:Value() + 1)
                end if result then return end
                -- SEMI MANUAL
                local checkRStacksSemi = Menu.rset.semirkog.semistacks:Value()
                if Menu.rset.semirkog.semir:Value() and (not checkRStacksSemi or rStacks) then
                    local onlyLowR = Menu.rset.semirkog.semilow:Value()
                    local rTargets = {}
                    if onlyLowR then
                        for i = 1, #enemyList do
                            local hero = enemyList[i]
                            if hero and ((hero.health + (hero.hpRegen * 3)) * 100) / hero.maxHealth < 40 then
                                rTargets[#rTargets + 1] = hero
                            end
                        end
                    else
                        rTargets = enemyList
                    end
                    result = CastSpell(HK_R, TS:GetTarget(rTargets, 1), self.RData, Menu.rset.hitchance:Value() + 1)
                end if result then return end
                -- Combo / Harass
                if (ORB.Modes[ORBWALKER_MODE_COMBO] and Menu.rset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and Menu.rset.harass:Value()) then
                    local stopRIfW = Menu.wset.stopr:Value() and self.HasWBuff
                    if not stopRIfW and rStacks and manaPercent > Menu.rset.rmana:Value() then
                        local onlyLowR = Menu.rset.onlylow:Value()
                        local AATarget2
                        if onlyLowR and AATarget and (AATarget.health * 100) / AATarget.maxHealth > 39 then
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
                                    if hero and ((hero.health + (hero.hpRegen * 3)) * 100) / hero.maxHealth < 40 then
                                        rTargets[#rTargets + 1] = hero
                                    end
                                end
                            else
                                rTargets = enemyList
                            end
                            t = TS:GetTarget(rTargets, 1)
                        end
                        result = CastSpell(HK_R, t, self.RData, Menu.rset.hitchance:Value() + 1)
                    end
                end if result then return end
            end
            -- Q
            local stopQIfW = Menu.wset.stopq:Value() and self.HasWBuff
            if not stopQIfW and meMana > myHero:GetSpellData(_Q).mana and SPELLS:IsReady(_Q, {q = 0.5, w = 0.15, e = 0.33, r = 0.33}) then
                -- Combo / Harass
                if (ORB.Modes[ORBWALKER_MODE_COMBO] and Menu.qset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and Menu.qset.harass:Value()) then
                    local t
                    if AATarget then
                        t = AATarget
                    else
                        t = TS:GetTarget(OB:GetEnemyHeroes(1175, false, 0), 1)
                    end
                    result = CastSpell(HK_Q, t, self.QData, Menu.qset.hitchance:Value() + 1)
                end
            end if result then return end
            -- E
            local stopEifW = Menu.wset.stope:Value() and self.HasWBuff
            if not stopEifW and manaPercent > Menu.eset.emana:Value() and meMana > myHero:GetSpellData(_E).mana and SPELLS:IsReady(_E, {q = 0.33, w = 0.15, e = 0.5, r = 0.33}) then
                if (ORB.Modes[ORBWALKER_MODE_COMBO] and Menu.eset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and Menu.eset.harass:Value()) then
                    local t
                    if AATarget then
                        t = AATarget
                    else
                        t = TS:GetTarget(OB:GetEnemyHeroes(1280, false, 0), 1)
                    end
                    result = CastSpell(HK_E, t, self.EData, Menu.eset.hitchance:Value() + 1)
                end
            end if result then return end
        end
        function CHAMPION:PreAttack(args)
            if ((ORB.Modes[ORBWALKER_MODE_COMBO] and Menu.wset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and Menu.wset.harass:Value())) and SPELLS:IsReady(_W, {q = 0.33, w = 0.5, e = 0.33, r = 0.33}) then
                local enemyList = OB:GetEnemyHeroes(610 + (20 * myHero:GetSpellData(_W).level) + myHero.boundingRadius - 35, true, 1)
                if #enemyList > 0 and Control.CastSpell(HK_W) then
                    args.Process = false
                end
            end
        end
        function CHAMPION:CanMove()
            if not SPELLS:CheckSpellDelays({q = 0.2, w = 0, e = 0.2, r = 0.2}) then
                return false
            end
            return true
        end
        function CHAMPION:CanAttack()
            if not SPELLS:CheckSpellDelays({q = 0.33, w = 0, e = 0.33, r = 0.33}) then
                return false
            end
            return true
        end
    end,
    Vayne = function()
        require "MapPositionGOS"
        local VayneVersion = "0.03 - antimelee, antidash, interrupt etc."
        Menu = MenuElement({name = "Gamsteron Vayne", id = "Gamsteron_Vayne", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Icons/vayne.png"})
        -- Q
        Menu:MenuElement({name = "Q settings", id = "qset", type = _G.MENU})
        Menu.qset:MenuElement({id = "combo", name = "Combo", value = true})
        Menu.qset:MenuElement({id = "harass", name = "Harass", value = false})
        -- E
        Menu:MenuElement({name = "E settings", id = "eset", type = _G.MENU})
        Menu.eset:MenuElement({id = "melee", name = "AntiMelee", value = true})
        Menu.eset:MenuElement({name = "Use on (AntiMelee):", id = "useonmelee", type = _G.MENU})
        LocalCore:OnEnemyHeroLoad(function(hero)
            local notMelee = {
                ["Thresh"] = true,
                ["Azir"] = true,
                ["Velkoz"] = true
            }
            if LocalCore.IsMelee[hero.charName] and not notMelee[hero.charName] then
                Menu.eset.useonmelee:MenuElement({id = hero.charName, name = hero.charName, value = true})
            end
        end)
        Menu.eset:MenuElement({id = "dash", name = "AntiDash - kha e, rangar r", value = true})
        Menu.eset:MenuElement({id = "interrupt", name = "Interrupt dangerous spells", value = true})
        Menu.eset:MenuElement({id = "combo", name = "Combo (Stun)", value = true})
        Menu.eset:MenuElement({id = "harass", name = "Harass (Stun)", value = false})
        Menu.eset:MenuElement({name = "Use on (Stun):", id = "useonstun", type = _G.MENU})
        LocalCore:OnEnemyHeroLoad(function(hero) Menu.eset.useonstun:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
        --R
        Menu:MenuElement({name = "R settings", id = "rset", type = _G.MENU})
        Menu.rset:MenuElement({id = "qready", name = "Only if Q ready or almost ready", value = true})
        Menu.rset:MenuElement({id = "combo", name = "Combo - if X enemies near vayne", value = true})
        Menu.rset:MenuElement({id = "xcount", name = "  ^^^ X enemies ^^^", value = 3, min = 1, max = 5, step = 1})
        Menu.rset:MenuElement({id = "xdistance", name = "^^^ max. distance ^^^", value = 500, min = 250, max = 750, step = 50})
        -- Version
        Menu:MenuElement({name = "Version " .. tostring(VayneVersion), type = _G.SPACE, id = "verspace"})
        CHAMPION = LocalCore:Class()
        function CHAMPION:__init()
            _G.GamsteronMenuSpell.isaa:Value(false)
            self.LastReset = 0
            self.EData = {delay = 0.5, radius = 0, range = 550 - 35, speed = 2000, collision = false, type = _G.SPELLTYPE_LINE}
        end
        function CHAMPION:Tick()
            
            -- reset attack after Q
            if LocalGameCanUseSpell(_Q) ~= 0 and LocalGameTimer() > self.LastReset + 1 and LocalCore:HasBuff(myHero, "vaynetumblebonus") then
                ORB:__OnAutoAttackReset()
                self.LastReset = LocalGameTimer()
            end
            -- reset attack after Q
            
            local result = false
            
            -- r
            if ORB.Modes[ORBWALKER_MODE_COMBO] and Menu.rset.combo:Value() and SPELLS:IsReady(_R, {q = 0.5, w = 0, e = 0.5, r = 0.5}) then
                local canR = true
                if Menu.rset.qready:Value() then
                    canR = false
                    if LocalGameCanUseSpell(_Q) == 0 then canR = true end
                    if LocalGameCanUseSpell(_Q) == 32 and myHero.mana > myHero:GetSpellData(_Q).mana and myHero:GetSpellData(_Q).currentCd < 0.75 then canR = true end
                end
                if canR then
                    local countEnemies = 0
                    for i = 1, LocalGameHeroCount() do
                        local hero = LocalGameHero(i)
                        if LocalCore:IsValidTarget(hero) and hero.team == LocalCore.TEAM_ENEMY and myHero.pos:DistanceTo(hero.pos) < Menu.rset.xdistance:Value() and not OB:IsHeroImmortal(hero, false) then
                            countEnemies = countEnemies + 1
                        end
                    end
                    if countEnemies >= Menu.rset.xcount:Value() then
                        result = Control.CastSpell(HK_R)
                    end
                end
            end
            -- r
            
            -- e
            if not result and SPELLS:IsReady(_E, {q = 0.75, w = 0, e = 0.75, r = 0}) then
                
                -- e antiMelee
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
                            Control.CastSpell(HK_E, meleeTarget)
                            result = true
                        end
                    end
                end
                -- e antiMelee
                
                -- e antiDash
                if not result and Menu.eset.dash:Value() then
                    for i = 1, LocalGameHeroCount() do
                        local hero = LocalGameHero(i)
                        if LocalCore:IsValidTarget(hero) and hero.team == LocalCore.TEAM_ENEMY then
                            local path = hero.pathing
                            if path and path.isDashing and hero.posTo and myHero.pos:DistanceTo(hero.posTo) < 500 and LocalCore:IsFacing(hero, myHero, 75) then
                                local extpos = hero.pos:Extended(hero.posTo, path.dashSpeed * (0.07 + _G.LATENCY))
                                if myHero.pos:DistanceTo(extpos) < 550 + myHero.boundingRadius + hero.boundingRadius then
                                    Control.CastSpell(HK_E, hero)
                                    result = true
                                    break
                                end
                            end
                        end
                    end
                end
                -- e antiDash
                
                -- e stun
                if not result and ((ORB.Modes[ORBWALKER_MODE_COMBO] and Menu.eset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and Menu.eset.harass:Value())) then
                    local eRange = self.EData.range + myHero.boundingRadius
                    for i = 1, LocalGameHeroCount() do
                        local hero = LocalGameHero(i)
                        if LocalCore:IsValidTarget(hero) and hero.team == LocalCore.TEAM_ENEMY and myHero.pos:DistanceTo(hero.pos) < eRange + hero.boundingRadius and not OB:IsHeroImmortal(hero, false) then
                            if Menu.eset.useonstun[hero.charName] and Menu.eset.useonstun[hero.charName]:Value() and CheckWall(myHero.pos, hero.pos, 450) and CheckWall(myHero.pos, hero:GetPrediction(self.EData.delay + 0.06 + LATENCY, self.EData.speed), 450) then
                                result = Control.CastSpell(HK_E, hero)
                                break
                            end
                        end
                    end
                end
                -- e stun
            end
            -- e
            
            -- q
            if not result and SPELLS:IsReady(_Q, {q = 0.5, w = 0, e = 0.5, r = 0}) then
                
                -- Is Attacking
                local isAttacking = false
                if ORB:IsAutoAttacking() then
                    isAttacking = true
                end
                -- Can Attack
                local AATarget = TS:GetComboTarget()
                if AATarget and not ORB.IsNone and ORB:CanAttack() then
                    isAttacking = true
                end
                --Q
                if not isAttacking and ((ORB.Modes[ORBWALKER_MODE_COMBO] and Menu.qset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and Menu.qset.harass:Value())) then
                    local mePos = myHero.pos
                    local extended = Vector(myHero.pos):Extended(Vector(_G.mousePos), 300)
                    local meRange = myHero.range + myHero.boundingRadius
                    for i = 1, LocalGameHeroCount() do
                        local hero = LocalGameHero(i)
                        if LocalCore:IsValidTarget(hero) and hero.team == LocalCore.TEAM_ENEMY and extended and Vector(extended):DistanceTo(hero.pos) < meRange + hero.boundingRadius - 35 and not OB:IsHeroImmortal(hero, true) then
                            result = Control.CastSpell(HK_Q)
                            break
                        end
                    end
                end
                
            end
            -- q
            
            return result
        end
        function CHAMPION:Interrupter()
            INTERRUPTER = LocalCore:__Interrupter()
            INTERRUPTER:OnInterrupt(function(enemy)
                if Menu.eset.interrupt:Value() and SPELLS:IsReady(_E, {q = 0.75, w = 0, e = 0.5, r = 0}) and enemy.pos:ToScreen().onScreen and myHero.pos:DistanceTo(enemy.pos) < 550 + myHero.boundingRadius + enemy.boundingRadius - 35 then
                    Control.CastSpell(HK_E, enemy)
                end
            end)
        end
        function CHAMPION:CanAttack()
            if not SPELLS:CheckSpellDelays({q = 0.3, w = 0, e = 0.5, r = 0}) then
                return false
            end
            return true
        end
        function CHAMPION:CanMove()
            if not SPELLS:CheckSpellDelays({q = 0.2, w = 0, e = 0.4, r = 0}) then
                return false
            end
            return true
        end
    end,
    Brand = function()
        local BrandVersion = "0.02 - fixed q casting, no bugs, faster combo"
        Menu = MenuElement({name = "Gamsteron Brand", id = "Gamsteron_Brand", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Icons/x1xxbrandx3xx.png"})
        -- Q
        Menu:MenuElement({name = "Q settings", id = "qset", type = _G.MENU})
        -- KS
        Menu.qset:MenuElement({name = "KS", id = "killsteal", type = _G.MENU})
        Menu.qset.killsteal:MenuElement({id = "enabled", name = "Enabled", value = true})
        Menu.qset.killsteal:MenuElement({id = "minhp", name = "minimum enemy hp", value = 200, min = 1, max = 300, step = 1})
        Menu.qset.killsteal:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = {"normal", "high"}})
        -- Auto
        Menu.qset:MenuElement({name = "Auto", id = "auto", type = _G.MENU})
        Menu.qset.auto:MenuElement({id = "stun", name = "Auto Stun", value = true})
        Menu.qset.auto:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = {"normal", "high"}})
        -- Combo / Harass
        Menu.qset:MenuElement({name = "Combo / Harass", id = "comhar", type = _G.MENU})
        Menu.qset.comhar:MenuElement({id = "combo", name = "Combo", value = true})
        Menu.qset.comhar:MenuElement({id = "harass", name = "Harass", value = false})
        Menu.qset.comhar:MenuElement({id = "stun", name = "Only if will stun", value = true})
        Menu.qset.comhar:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = {"normal", "high"}})
        -- W
        Menu:MenuElement({name = "W settings", id = "wset", type = _G.MENU})
        Menu.wset:MenuElement({id = "disaa", name = "Disable attack if ready or almostReady", value = true})
        -- KS
        Menu.wset:MenuElement({name = "KS", id = "killsteal", type = _G.MENU})
        Menu.wset.killsteal:MenuElement({id = "enabled", name = "Enabled", value = true})
        Menu.wset.killsteal:MenuElement({id = "minhp", name = "minimum enemy hp", value = 200, min = 1, max = 300, step = 1})
        Menu.wset.killsteal:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = {"normal", "high"}})
        -- Auto
        Menu.wset:MenuElement({name = "Auto", id = "auto", type = _G.MENU})
        Menu.wset.auto:MenuElement({id = "enabled", name = "Enabled", value = true})
        Menu.wset.auto:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = {"normal", "high"}})
        -- Combo / Harass
        Menu.wset:MenuElement({name = "Combo / Harass", id = "comhar", type = _G.MENU})
        Menu.wset.comhar:MenuElement({id = "combo", name = "Combo", value = true})
        Menu.wset.comhar:MenuElement({id = "harass", name = "Harass", value = false})
        Menu.wset.comhar:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = {"normal", "high"}})
        -- E
        Menu:MenuElement({name = "E settings", id = "eset", type = _G.MENU})
        Menu.eset:MenuElement({id = "disaa", name = "Disable attack if ready or almostReady", value = true})
        -- KS
        Menu.eset:MenuElement({name = "KS", id = "killsteal", type = _G.MENU})
        Menu.eset.killsteal:MenuElement({id = "enabled", name = "Enabled", value = true})
        Menu.eset.killsteal:MenuElement({id = "minhp", name = "minimum enemy hp", value = 100, min = 1, max = 300, step = 1})
        -- Auto
        Menu.eset:MenuElement({name = "Auto", id = "auto", type = _G.MENU})
        Menu.eset.auto:MenuElement({id = "stun", name = "If Q ready | no collision & W not ready $ mana for Q + E", value = true})
        Menu.eset.auto:MenuElement({id = "passive", name = "If Q not ready & W not ready $ enemy has passive buff", value = true})
        -- Combo / Harass
        Menu.eset:MenuElement({name = "Combo / Harass", id = "comhar", type = _G.MENU})
        Menu.eset.comhar:MenuElement({id = "combo", name = "Combo", value = true})
        Menu.eset.comhar:MenuElement({id = "harass", name = "Harass", value = false})
        --R
        Menu:MenuElement({name = "R settings", id = "rset", type = _G.MENU})
        -- Auto
        Menu.rset:MenuElement({name = "Auto", id = "auto", type = _G.MENU})
        Menu.rset.auto:MenuElement({id = "enabled", name = "Enabled", value = true})
        Menu.rset.auto:MenuElement({id = "xenemies", name = ">= X enemies near target", value = 2, min = 1, max = 4, step = 1})
        Menu.rset.auto:MenuElement({id = "xrange", name = "< X distance enemies to target", value = 300, min = 100, max = 600, step = 50})
        -- Combo / Harass
        Menu.rset:MenuElement({name = "Combo / Harass", id = "comhar", type = _G.MENU})
        Menu.rset.comhar:MenuElement({id = "combo", name = "Use R Combo", value = true})
        Menu.rset.comhar:MenuElement({id = "harass", name = "Use R Harass", value = false})
        Menu.rset.comhar:MenuElement({id = "xenemies", name = ">= X enemies near target", value = 1, min = 1, max = 4, step = 1})
        Menu.rset.comhar:MenuElement({id = "xrange", name = "< X distance enemies to target", value = 300, min = 100, max = 600, step = 50})
        -- Version
        Menu:MenuElement({name = "Version " .. tostring(BrandVersion), type = _G.SPACE, id = "verspace"})
        CHAMPION = LocalCore:Class()
        function CHAMPION:__init()
            self.ETarget = nil
            self.QData = {Delay = 0.25, Radius = 80, Range = 1050, Speed = 1550, Collision = true, Type = _G.SPELLTYPE_LINE}
            self.WData = {Delay = 0.625, Radius = 100, Range = 875, Speed = math.huge, Collision = false, Type = _G.SPELLTYPE_CIRCLE}
        end
        function CHAMPION:Tick()
            -- Is Attacking
            if ORB:IsAutoAttacking() then
                return
            end
            local result = false
            -- Q
            if SPELLS:IsReady(_Q, {q = 0.5, w = 0.53, e = 0.53, r = 0.33}) then
                -- KS
                if Menu.qset.killsteal.enabled:Value() then
                    local baseDmg = 50
                    local lvlDmg = 30 * myHero:GetSpellData(_Q).level
                    local apDmg = myHero.ap * 0.55
                    local qDmg = baseDmg + lvlDmg + apDmg
                    local minHP = Menu.qset.killsteal.minhp:Value()
                    if qDmg > minHP then
                        local enemyList = OB:GetEnemyHeroes(1050, false, 0)
                        for i = 1, #enemyList do
                            local qTarget = enemyList[i]
                            if qTarget.health > minHP and qTarget.health < DMG:CalculateDamage(myHero, qTarget, DAMAGE_TYPE_MAGICAL, qDmg) then
                                result = CastSpell(HK_Q, qTarget, self.QData, Menu.qset.killsteal.hitchance:Value() + 1)
                            end
                        end
                    end
                end if result then return end
                -- Combo Harass
                if (ORB.Modes[ORBWALKER_MODE_COMBO] and Menu.qset.comhar.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and Menu.qset.comhar.harass:Value()) then
                    if LocalGameTimer() < SPELLS.LastEk + 1 and LocalGameTimer() > SPELLS.LastE + 0.33 and self.ETarget and not self.ETarget.dead and self.ETarget:GetCollision(self.QData.Radius, self.QData.Speed, self.QData.Delay) == 0 then
                        result = CastSpell(HK_Q, self.ETarget, self.QData, Menu.qset.comhar.hitchance:Value() + 1)
                        if result then return end
                    end
                    local blazeList = {}
                    local enemyList = OB:GetEnemyHeroes(1050, false, 0)
                    for i = 1, #enemyList do
                        local unit = enemyList[i]
                        if LocalCore:GetBuffDuration(unit, "brandablaze") > 0.5 and unit:GetCollision(self.QData.Radius, self.QData.Speed, self.QData.Delay) == 0 then
                            blazeList[#blazeList + 1] = unit
                        end
                    end
                    result = CastSpell(HK_Q, TS:GetTarget(blazeList, 1), self.QData, Menu.qset.comhar.hitchance:Value() + 1)
                    if not result and not Menu.qset.comhar.stun:Value() and LocalGameTimer() > SPELLS.LastWk + 1.33 and LocalGameTimer() > SPELLS.LastEk + 0.77 and LocalGameTimer() > SPELLS.LastRk + 0.77 then
                        result = CastSpell(HK_Q, TS:GetTarget(OB:GetEnemyHeroes(1050, false, 0), 1), self.QData, Menu.qset.comhar.hitchance:Value() + 1)
                    end
                    -- Auto
                elseif Menu.qset.auto.stun:Value() then
                    if LocalGameTimer() < SPELLS.LastEk + 1 and LocalGameTimer() > SPELLS.LastE + 0.33 and self.ETarget and not self.ETarget.dead and self.ETarget:GetCollision(self.QData.Radius, self.QData.Speed, self.QData.Delay) == 0 then
                        result = CastSpell(HK_Q, self.ETarget, self.QData, Menu.qset.auto.hitchance:Value() + 1)
                        if result then return end
                    end
                    local blazeList = {}
                    local enemyList = OB:GetEnemyHeroes(1050, false, 0)
                    for i = 1, #enemyList do
                        local unit = enemyList[i]
                        if LocalCore:GetBuffDuration(unit, "brandablaze") > 0.5 and unit:GetCollision(self.QData.Radius, self.QData.Speed, self.QData.Delay) == 0 then
                            blazeList[#blazeList + 1] = unit
                        end
                    end
                    result = CastSpell(HK_Q, TS:GetTarget(blazeList, 1), self.QData, Menu.qset.auto.hitchance:Value() + 1)
                end
            end if result then return end
            -- E
            if SPELLS:IsReady(_E, {q = 0.33, w = 0.53, e = 0.5, r = 0.33}) then
                -- antigap
                local enemyList = OB:GetEnemyHeroes(635, false, 0)
                for i = 1, #enemyList do
                    local unit = enemyList[i]
                    if LocalCore:GetDistanceSquared(myHero.pos, unit.pos) < 300 * 300 then
                        result = Control.CastSpell(HK_E, unit)
                    end
                end if result then return end
                -- KS
                if Menu.eset.killsteal.enabled:Value() then
                    local baseDmg = 50
                    local lvlDmg = 20 * myHero:GetSpellData(_E).level
                    local apDmg = myHero.ap * 0.35
                    local eDmg = baseDmg + lvlDmg + apDmg
                    local minHP = Menu.eset.killsteal.minhp:Value()
                    if eDmg > minHP then
                        for i = 1, #enemyList do
                            local unit = enemyList[i]
                            if unit.health > minHP and unit.health < DMG:CalculateDamage(myHero, unit, DAMAGE_TYPE_MAGICAL, eDmg) then
                                result = Control.CastSpell(HK_E, unit)
                                if result then break end
                            end
                        end
                    end
                end if result then return end
                -- Combo / Harass
                if (ORB.Modes[ORBWALKER_MODE_COMBO] and Menu.eset.comhar.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and Menu.eset.comhar.harass:Value()) then
                    local blazeList = {}
                    for i = 1, #enemyList do
                        local unit = enemyList[i]
                        if LocalCore:GetBuffDuration(unit, "brandablaze") > 0.33 then
                            blazeList[#blazeList + 1] = unit
                        end
                    end
                    local eTarget = TS:GetTarget(blazeList, 1)
                    if eTarget then
                        result = Control.CastSpell(HK_E, eTarget)
                        self.ETarget = eTarget
                    end if result then return end
                    if LocalGameTimer() > SPELLS.LastQk + 0.77 and LocalGameTimer() > SPELLS.LastWk + 1.33 and LocalGameTimer() > SPELLS.LastRk + 0.77 then
                        eTarget = TS:GetTarget(enemyList, 1)
                        if eTarget then
                            result = Control.CastSpell(HK_E, eTarget)
                            self.ETarget = eTarget
                        end
                    end
                    -- Auto
                elseif myHero:GetSpellData(_Q).level > 0 and myHero:GetSpellData(_W).level > 0 then
                    -- EQ -> if Q ready | no collision & W not ready $ mana for Q + E
                    if Menu.eset.auto.stun:Value() and myHero.mana > myHero:GetSpellData(_Q).mana + myHero:GetSpellData(_E).mana then
                        if (LocalGameCanUseSpell(_Q) == 0 or myHero:GetSpellData(_Q).currentCd < 0.75) and not(LocalGameCanUseSpell(_W) == 0 or myHero:GetSpellData(_W).currentCd < 0.75) then
                            local blazeList = {}
                            local enemyList = OB:GetEnemyHeroes(635, false, 0)
                            for i = 1, #enemyList do
                                local unit = enemyList[i]
                                if LocalCore:GetBuffDuration(unit, "brandablaze") > 0.33 then
                                    blazeList[#blazeList + 1] = unit
                                end
                            end
                            local eTarget = TS:GetTarget(blazeList, 1)
                            if eTarget and eTarget:GetCollision(self.QData.Radius, self.QData.Speed, self.QData.Delay) == 0 then
                                result = Control.CastSpell(HK_E, eTarget)
                            end if result then return end
                            if LocalGameTimer() > SPELLS.LastQk + 0.77 and LocalGameTimer() > SPELLS.LastWk + 1.33 and LocalGameTimer() > SPELLS.LastRk + 0.77 then
                                eTarget = TS:GetTarget(enemyList, 1)
                                if eTarget and eTarget:GetCollision(self.QData.Radius, self.QData.Speed, self.QData.Delay) == 0 then
                                    result = Control.CastSpell(HK_E, eTarget)
                                    self.ETarget = eTarget
                                end
                            end
                        end
                    end
                    -- Passive -> If Q not ready & W not ready $ enemy has passive buff
                    if Menu.eset.auto.passive:Value() and not(LocalGameCanUseSpell(_Q) == 0 or myHero:GetSpellData(_Q).currentCd < 0.75) and not(LocalGameCanUseSpell(_W) == 0 or myHero:GetSpellData(_W).currentCd < 0.75) then
                        local blazeList = {}
                        local enemyList = OB:GetEnemyHeroes(670, false, 0)
                        for i = 1, #enemyList do
                            local unit = enemyList[i]
                            if LocalCore:GetBuffDuration(unit, "brandablaze") > 0.33 then
                                blazeList[#blazeList + 1] = unit
                            end
                        end
                        local eTarget = TS:GetTarget(blazeList, 1)
                        if eTarget then
                            result = Control.CastSpell(HK_E, eTarget)
                            self.ETarget = eTarget
                        end
                    end
                end
            end if result then return end
            -- W
            if SPELLS:IsReady(_W, {q = 0.33, w = 0.5, e = 0.33, r = 0.33}) then
                -- KS
                if Menu.wset.killsteal.enabled:Value() then
                    local baseDmg = 30
                    local lvlDmg = 45 * myHero:GetSpellData(_W).level
                    local apDmg = myHero.ap * 0.6
                    local wDmg = baseDmg + lvlDmg + apDmg
                    local minHP = Menu.wset.killsteal.minhp:Value()
                    if wDmg > minHP then
                        local enemyList = OB:GetEnemyHeroes(950, false, 0)
                        for i = 1, #enemyList do
                            local wTarget = enemyList[i]
                            if wTarget.health > minHP and wTarget.health < DMG:CalculateDamage(myHero, wTarget, DAMAGE_TYPE_MAGICAL, wDmg) then
                                result = CastSpell(HK_W, wTarget, self.WData, Menu.wset.killsteal.hitchance:Value() + 1)
                                if result then break end
                            end
                        end
                    end
                end if result then return end
                -- Combo / Harass
                if (ORB.Modes[ORBWALKER_MODE_COMBO] and Menu.wset.comhar.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and Menu.wset.comhar.harass:Value()) then
                    local blazeList = {}
                    local enemyList = OB:GetEnemyHeroes(950, false, 0)
                    for i = 1, #enemyList do
                        local unit = enemyList[i]
                        if LocalCore:GetBuffDuration(unit, "brandablaze") > 1.33 then
                            blazeList[#blazeList + 1] = unit
                        end
                    end
                    result = CastSpell(HK_W, TS:GetTarget(blazeList, 1), self.WData, Menu.wset.comhar.hitchance:Value() + 1)
                    if not result and LocalGameTimer() > SPELLS.LastQk + 0.77 and LocalGameTimer() > SPELLS.LastEk + 0.77 and LocalGameTimer() > SPELLS.LastRk + 0.77 then
                        result = CastSpell(HK_W, TS:GetTarget(enemyList, 1), self.WData, Menu.wset.comhar.hitchance:Value() + 1)
                    end
                    -- Auto
                elseif Menu.wset.auto.enabled:Value() then
                    for i = 1, 3 do
                        local blazeList = {}
                        local enemyList = OB:GetEnemyHeroes(1200 - (i * 100), false, 0)
                        for j = 1, #enemyList do
                            local unit = enemyList[j]
                            if LocalCore:GetBuffDuration(unit, "brandablaze") > 1.33 then
                                blazeList[#blazeList + 1] = unit
                            end
                        end
                        result = CastSpell(HK_W, TS:GetTarget(blazeList, 1), self.WData, Menu.wset.auto.hitchance:Value() + 1)
                        if not result and LocalGameTimer() > SPELLS.LastQk + 0.77 and LocalGameTimer() > SPELLS.LastEk + 0.77 and LocalGameTimer() > SPELLS.LastRk + 0.77 then
                            result = CastSpell(HK_W, TS:GetTarget(enemyList, 1), self.WData, Menu.wset.auto.hitchance:Value() + 1)
                        end
                    end
                end
            end if result then return end
            -- R
            if SPELLS:IsReady(_R, {q = 0.33, w = 0.33, e = 0.33, r = 0.5}) then
                -- Combo / Harass
                if (ORB.Modes[ORBWALKER_MODE_COMBO] and Menu.rset.comhar.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and Menu.rset.comhar.harass:Value()) then
                    local enemyList = OB:GetEnemyHeroes(750, false, 0)
                    local xRange = Menu.rset.comhar.xrange:Value()
                    local xEnemies = Menu.rset.comhar.xenemies:Value()
                    for i = 1, #enemyList do
                        local count = 0
                        local rTarget = enemyList[i]
                        for j = 1, #enemyList do
                            local unit = enemyList[j]
                            if rTarget ~= unit and rTarget.pos:DistanceTo(unit.pos) < xRange then
                                count = count + 1
                            end
                        end
                        if count >= xEnemies then
                            result = Control.CastSpell(HK_R, rTarget)
                            if result then break end
                        end
                    end
                    -- Auto
                elseif Menu.rset.auto.enabled:Value() then
                    local enemyList = OB:GetEnemyHeroes(750, false, 0)
                    local xRange = Menu.rset.auto.xrange:Value()
                    local xEnemies = Menu.rset.auto.xenemies:Value()
                    for i = 1, #enemyList do
                        local count = 0
                        local rTarget = enemyList[i]
                        for j = 1, #enemyList do
                            local unit = enemyList[j]
                            if rTarget ~= unit and rTarget.pos:DistanceTo(unit.pos) < xRange then
                                count = count + 1
                            end
                        end
                        if count >= xEnemies then
                            result = Control.CastSpell(HK_R, rTarget)
                            if result then break end
                        end
                    end
                end
            end
        end
        function CHAMPION:CanMove()
            if not SPELLS:CheckSpellDelays({q = 0.2, w = 0.2, e = 0.2, r = 0.2}) then
                return false
            end
            return true
        end
        function CHAMPION:CanAttack()
            if not SPELLS:CheckSpellDelays({q = 0.33, w = 0.33, e = 0.33, r = 0.33}) then
                return false
            end
            -- LastHit, LaneClear
            if not ORB.Modes[ORBWALKER_MODE_COMBO] and not ORB.Modes[ORBWALKER_MODE_HARASS] then
                return true
            end
            -- W
            if Menu.wset.disaa:Value() and myHero:GetSpellData(_W).level > 0 and myHero.mana > myHero:GetSpellData(_W).mana and (LocalGameCanUseSpell(_W) == 0 or myHero:GetSpellData(_W).currentCd < 1) then
                return false
            end
            -- E
            if Menu.eset.disaa:Value() and myHero:GetSpellData(_E).level > 0 and myHero.mana > myHero:GetSpellData(_E).mana and (LocalGameCanUseSpell(_E) == 0 or myHero:GetSpellData(_E).currentCd < 1) then
                return false
            end
            return true
        end
end,
