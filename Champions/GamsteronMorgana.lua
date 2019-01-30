local GamsteronMorganaVer = 0.08
local debugMode = false
local LocalCore, Menu, Orbwalker, TargetSelector, ObjectManager, Damage, Spells

do
    if _G.GamsteronMorganaLoaded or myHero.charName ~= "Morgana" then
        return
    end

    if not FileExist(COMMON_PATH .. "GamsteronCore.lua") then
        DownloadFileAsync("https://raw.githubusercontent.com/gamsteron/GOS-External/master/Common/GamsteronCore.lua", COMMON_PATH .. "GamsteronCore.lua", function() end)
        while not FileExist(COMMON_PATH .. "GamsteronCore.lua") do end
    end

    if not FileExist(COMMON_PATH .. "GamsteronPrediction.lua") then
        DownloadFileAsync("https://raw.githubusercontent.com/gamsteron/GOS-External/master/Common/GamsteronPrediction.lua", COMMON_PATH .. "GamsteronPrediction.lua", function() end)
        while not FileExist(COMMON_PATH .. "GamsteronPrediction.lua") do end
    end

    require('GamsteronCore')
    if _G.GamsteronCoreUpdated then
        return
    end
    require('GamsteronPrediction')
    if _G.GamsteronPredictionUpdated then
        return
    end
    LocalCore = _G.GamsteronCore

    local success, version = LocalCore:AutoUpdate({
        version = GamsteronMorganaVer,
        scriptPath = SCRIPT_PATH .. "GamsteronMorgana.lua",
        scriptUrl = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Champions/GamsteronMorgana.lua",
        versionPath = SCRIPT_PATH .. "GamsteronMorgana.version",
        versionUrl = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Champions/GamsteronMorgana.version"
    })

    if success then
        print("GamsteronMorgana updated to version " .. version .. ". Please Reload with 2x F6 !")
        _G.GamsteronMorganaUpdated = true
        return
    end
end

local pairs							= _G.pairs
local myHero						= _G.myHero
local GameTimer                     = _G.Game.Timer
local GameCanUseSpell               = _G.Game.CanUseSpell
local MathMax                       = _G.math.max

local Q_KS_ON                       = false
local Q_AUTO_ON                     = true
local Q_COMBO_ON                    = true
local Q_DISABLEAA                   = false
local Q_HARASS_ON                   = false
local Q_INTERRUPTER_ON              = true
local Q_KS_MINHP                    = 200
local Q_KS_HITCHANCE                = 3
local Q_AUTO_HITCHANCE              = 3
local Q_COMBO_HITCHANCE             = 3
local W_KS_ON                       = false
local W_KS_MINHP                    = 200
local W_AUTO_ON                     = true
local W_COMBO_ON                    = false
local W_HARASS_ON                   = false
local W_CLEAR_ON                    = false
local W_CLEAR_MINX                  = 3
local E_AUTO_ON                     = true
local E_ALLY_ON                     = true
local E_SELF_ON                     = true
local R_KS_ON                       = false
local R_KS_MINHP                    = 200
local R_AUTO_ON                     = true
local R_AUTO_ENEMIESX               = 3
local R_AUTO_RANGEX                 = 300
local R_COMBO_ON                    = false
local R_HARASS_ON                   = false
local R_COMBO_ENEMIESX              = 3
local R_COMBO_RANGEX                = 300

local QData                         =
{
    Type = _G.SPELLTYPE_LINE, Aoe = false,
    Delay = 0.25, Radius = 70, Range = 1175, Speed = 1200,
    Collision = true, MaxCollision = 0, CollisionObjects = { _G.COLLISION_MINION, _G.COLLISION_YASUOWALL }
}
local WData                         =
{
    Type = _G.SPELLTYPE_CIRCLE, Aoe = false, Collision = false,
    Delay = 0.25, Radius = 150, Range = 900, Speed = math.huge
}
local EData                         =
{
    Range = 800
}
local RData                         =
{
    Range = 625
}

local function LoadMenu()
    Menu = MenuElement({name = "Gamsteron Morgana", id = "GamsteronMorgana", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/morganads83fd.png" })
        -- Q
        Menu:MenuElement({name = "Q settings", id = "qset", type = _G.MENU })
            -- Disable Attack
            Menu.qset:MenuElement({id = "disaa", name = "Disable attack if ready or almostReady", value = false, callback = function(value) Q_DISABLEAA = value end})
            -- Interrupt:
            Menu.qset:MenuElement({id = "interrupter", name = "Interrupter", value = true, callback = function(value) Q_INTERRUPTER_ON = value end})
            -- KS
            Menu.qset:MenuElement({name = "KS", id = "killsteal", type = _G.MENU })
                Menu.qset.killsteal:MenuElement({id = "enabled", name = "Enabled", value = false, callback = function(value) Q_KS_ON = value end})
                Menu.qset.killsteal:MenuElement({id = "minhp", name = "minimum enemy hp", value = 200, min = 1, max = 300, step = 1, callback = function(value) Q_KS_MINHP = value end})
                Menu.qset.killsteal:MenuElement({id = "hitchance", name = "Hitchance", value = 3, drop = { "Collision", "Normal", "High", "Immobile" }, callback = function(value) Q_KS_HITCHANCE = value end })
            -- Auto
            Menu.qset:MenuElement({name = "Auto", id = "auto", type = _G.MENU })
                Menu.qset.auto:MenuElement({id = "enabled", name = "Enabled", value = true, callback = function(value) Q_AUTO_ON = value end})
                Menu.qset.auto:MenuElement({name = "Use on:", id = "useon", type = _G.MENU })
                    LocalCore:OnEnemyHeroLoad(function(hero) Menu.qset.auto.useon:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
                Menu.qset.auto:MenuElement({id = "hitchance", name = "Hitchance", value = 3, drop = { "Collision", "Normal", "High", "Immobile" }, callback = function(value) Q_AUTO_HITCHANCE = value end })
            -- Combo / Harass
            Menu.qset:MenuElement({name = "Combo / Harass", id = "comhar", type = _G.MENU })
                Menu.qset.comhar:MenuElement({id = "combo", name = "Combo", value = true, callback = function(value) Q_COMBO_ON = value end})
                Menu.qset.comhar:MenuElement({id = "harass", name = "Harass", value = false, callback = function(value) Q_HARASS_ON = value end})
                Menu.qset.comhar:MenuElement({name = "Use on:", id = "useon", type = _G.MENU })
                    LocalCore:OnEnemyHeroLoad(function(hero) Menu.qset.comhar.useon:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
                Menu.qset.comhar:MenuElement({id = "hitchance", name = "Hitchance", value = 3, drop = { "Collision", "Normal", "High", "Immobile" }, callback = function(value) Q_COMBO_HITCHANCE = value end })
        -- W
        Menu:MenuElement({name = "W settings", id = "wset", type = _G.MENU })
            -- KS
            Menu.wset:MenuElement({name = "KS", id = "killsteal", type = _G.MENU })
                Menu.wset.killsteal:MenuElement({id = "enabled", name = "Enabled", value = false, callback = function(value) W_KS_ON = value end})
                Menu.wset.killsteal:MenuElement({id = "minhp", name = "minimum enemy hp", value = 200, min = 1, max = 300, step = 1, callback = function(value) W_KS_MINHP = value end})
            -- Auto
            Menu.wset:MenuElement({name = "Auto", id = "auto", type = _G.MENU })
                Menu.wset.auto:MenuElement({id = "enabled", name = "Enabled", value = true, callback = function(value) W_AUTO_ON = value end})
            -- Combo / Harass
            Menu.wset:MenuElement({name = "Combo / Harass", id = "comhar", type = _G.MENU })
                Menu.wset.comhar:MenuElement({id = "combo", name = "Use W Combo", value = false, callback = function(value) W_COMBO_ON = value end})
                Menu.wset.comhar:MenuElement({id = "harass", name = "Use W Harass", value = false, callback = function(value) W_HARASS_ON = value end})
            -- Clear
            Menu.wset:MenuElement({name = "Clear", id = "laneclear", type = _G.MENU })
                Menu.wset.laneclear:MenuElement({id = "enabled", name = "Enbaled", value = false, callback = function(value) W_CLEAR_ON = value end})
                Menu.wset.laneclear:MenuElement({id = "xminions", name = "Min minions W Clear", value = 3, min = 1, max = 5, step = 1, callback = function(value) W_CLEAR_MINX = value end})
        -- E
        Menu:MenuElement({name = "E settings", id = "eset", type = _G.MENU })
            -- Auto
            Menu.eset:MenuElement({name = "Auto", id = "auto", type = _G.MENU })
                Menu.eset.auto:MenuElement({id = "enabled", name = "Enabled", value = true, callback = function(value) E_AUTO_ON = value end})
                Menu.eset.auto:MenuElement({id = "ally", name = "Use on ally", value = true, callback = function(value) E_ALLY_ON = value end})
                Menu.eset.auto:MenuElement({id = "selfish", name = "Use on yourself", value = true, callback = function(value) E_SELF_ON = value end})
        --R
        Menu:MenuElement({name = "R settings", id = "rset", type = _G.MENU })
            -- KS
            Menu.rset:MenuElement({name = "KS", id = "killsteal", type = _G.MENU })
                Menu.rset.killsteal:MenuElement({id = "enabled", name = "Enabled", value = false, callback = function(value) R_KS_ON = value end})
                Menu.rset.killsteal:MenuElement({id = "minhp", name = "Minimum enemy hp", value = 200, min = 1, max = 300, step = 1, callback = function(value) R_KS_MINHP = value end})
            -- Auto
            Menu.rset:MenuElement({name = "Auto", id = "auto", type = _G.MENU })
                Menu.rset.auto:MenuElement({id = "enabled", name = "Enabled", value = true, callback = function(value) R_AUTO_ON = value end})
                Menu.rset.auto:MenuElement({id = "xenemies", name = ">= X enemies near morgana", value = 3, min = 1, max = 5, step = 1, callback = function(value) R_AUTO_ENEMIESX = value end})
                Menu.rset.auto:MenuElement({id = "xrange", name = "< X distance enemies to morgana", value = 300, min = 100, max = 550, step = 50, callback = function(value) R_AUTO_RANGEX = value end})
            -- Combo / Harass
            Menu.rset:MenuElement({name = "Combo / Harass", id = "comhar", type = _G.MENU })
                Menu.rset.comhar:MenuElement({id = "combo", name = "Use R Combo", value = true, callback = function(value) R_COMBO_ON = value end})
                Menu.rset.comhar:MenuElement({id = "harass", name = "Use R Harass", value = false, callback = function(value) R_HARASS_ON = value end})
                Menu.rset.comhar:MenuElement({id = "xenemies", name = ">= X enemies near morgana", value = 2, min = 1, max = 4, step = 1, callback = function(value) R_COMBO_ENEMIESX = value end})
                Menu.rset.comhar:MenuElement({id = "xrange", name = "< X distance enemies to morgana", value = 300, min = 100, max = 550, step = 50, callback = function(value) R_COMBO_RANGEX = value end})
        Menu:MenuElement({name = "Version " .. tostring(GamsteronMorganaVer), type = _G.SPACE, id = "vermorgspace"})
end
LoadMenu()

local function QLogic()
    local result = false
    if Spells:IsReady(_Q, { q = 1, w = 0.3, e = 0.3, r = 0.3 } ) then
        local EnemyHeroes = ObjectManager:GetEnemyHeroes(QData.Range, false, LocalCore.HEROES_SPELL)

        if Q_KS_ON then
            local baseDmg = 25
            local lvlDmg = 55 * myHero:GetSpellData(_Q).level
            local apDmg = myHero.ap * 0.9
            local qDmg = baseDmg + lvlDmg + apDmg
            if qDmg > Q_KS_MINHP then
                for i = 1, #EnemyHeroes do
                    local qTarget = EnemyHeroes[i]
                    if qTarget.health > Q_KS_MINHP and qTarget.health < Damage:CalculateDamage(myHero, qTarget, LocalCore.DAMAGE_TYPE_MAGICAL, qDmg) then
                        local pred = GetGamsteronPrediction(qTarget, QData, myHero.pos)
                        if pred.Hitchance >= Q_KS_HITCHANCE then
                            result = LocalCore:CastSpell(HK_Q, qTarget, pred.CastPosition)
                        end
                    end
                end
            end
        end if result then return end

        if (Orbwalker.Modes[LocalCore.ORBWALKER_MODE_COMBO] and Q_COMBO_ON) or (Orbwalker.Modes[LocalCore.ORBWALKER_MODE_HARASS] and Q_HARASS_ON) then
            local qList = {}
            for i = 1, #EnemyHeroes do
                local hero = EnemyHeroes[i]
                local heroName = hero.charName
                if Menu.qset.comhar.useon[heroName] and Menu.qset.comhar.useon[heroName]:Value() then
                    qList[#qList+1] = hero
                end
            end
            local qTarget = TargetSelector:GetTarget(qList, LocalCore.DAMAGE_TYPE_MAGICAL)
            if qTarget then
                local pred = GetGamsteronPrediction(qTarget, QData, myHero.pos)
                if pred.Hitchance >= Q_COMBO_HITCHANCE then
                    result = LocalCore:CastSpell(HK_Q, qTarget, pred.CastPosition)
                end
            end
        end if result then return end

        if Q_AUTO_ON then
            local qList = {}
            for i = 1, #EnemyHeroes do
                local hero = EnemyHeroes[i]
                local heroName = hero.charName
                if Menu.qset.auto.useon[heroName] and Menu.qset.auto.useon[heroName]:Value() then
                    qList[#qList+1] = hero
                end
            end
            local qTarget = TargetSelector:GetTarget(qList, LocalCore.DAMAGE_TYPE_MAGICAL)
            if qTarget then
                local pred = GetGamsteronPrediction(qTarget, QData, myHero.pos)
                if pred.Hitchance >= Q_AUTO_HITCHANCE then
                    LocalCore:CastSpell(HK_Q, qTarget, pred.CastPosition)
                end
            end
        end
    end
end

local function WLogic()
    local result = false
    if Spells:IsReady(_W, { q = 0.3, w = 1, e = 0.3, r = 0.3 } ) then
        local EnemyHeroes = ObjectManager:GetEnemyHeroes(WData.Range, false, 0)

        if W_KS_ON then
            local baseDmg = 10
            local lvlDmg = 14 * myHero:GetSpellData(_W).level
            local apDmg = myHero.ap * 0.22
            local wDmg = baseDmg + lvlDmg + apDmg
            if wDmg > W_KS_MINHP then
                for i = 1, #EnemyHeroes do
                    local wTarget = EnemyHeroes[i]
                    if wTarget.health > W_KS_MINHP and wTarget.health < Damage:CalculateDamage(myHero, wTarget, LocalCore.DAMAGE_TYPE_MAGICAL, wDmg) then
                        local pred = GetGamsteronPrediction(wTarget, WData, myHero.pos)
                        if pred.Hitchance >= _G.HITCHANCE_HIGH then
                            result = LocalCore:CastSpell(HK_W, wTarget, pred.CastPosition)
                        end
                    end
                end
            end
        end if result then return end

        if (Orbwalker.Modes[LocalCore.ORBWALKER_MODE_COMBO] and W_COMBO_ON) or (Orbwalker.Modes[LocalCore.ORBWALKER_MODE_HARASS] and W_HARASS_ON) then
            for i = 1, #EnemyHeroes do
                local unit = EnemyHeroes[i]
                local pred = GetGamsteronPrediction(unit, WData, myHero.pos)
                if pred.Hitchance >= _G.HITCHANCE_HIGH  then
                    result = LocalCore:CastSpell(HK_W, unit, pred.CastPosition)
                end
            end
        end if result then return end

        if (Orbwalker.Modes[LocalCore.ORBWALKER_MODE_LANECLEAR] and W_CLEAR_ON) then
            local target = nil
            local BestHit = 0
            local CurrentCount = 0
            local eMinions = ObjectManager:GetEnemyMinions(WData.Range + 200)
            for i = 1, #eMinions do
                local minion = eMinions[i]
                CurrentCount = 0
                local minionPos = minion.pos
                for j = 1, #eMinions do
                    local minion2 = eMinions[i]
                    if LocalCore:IsInRange(minionPos, minion2.pos, 250) then
                        CurrentCount = CurrentCount + 1
                    end
                end
                if CurrentCount > BestHit then
                    BestHit = CurrentCount
                    target = minion
                end
            end
            if target and BestHit >= W_CLEAR_MINX then
                result = Control.CastSpell(HK_W, target)
            end
        end if result then return end

        if W_AUTO_ON then
            for i = 1, #EnemyHeroes do
                local unit = EnemyHeroes[i]
                local ImmobileDuration, DashDuration, SlowDuration = GetImmobileDashSlowDuration(unit)
                if ImmobileDuration > 0.5 and not unit.pathing.isDashing then
                    Control.CastSpell(HK_W, unit)
                end
            end
        end
    end
end

local function ELogic()
    if E_AUTO_ON and (E_ALLY_ON or E_SELF_ON) and Spells:IsReady(_E, { q = 0.3, w = 0.3, e = 1, r = 0.3 } ) then
        local EnemyHeroes = ObjectManager:GetEnemyHeroes(2500, false, LocalCore.HEROES_IMMORTAL)
        local AllyHeroes = ObjectManager:GetAllyHeroes(EData.Range)
        for i = 1, #EnemyHeroes do
            local hero = EnemyHeroes[i]
            local heroPos = hero.pos
            local currSpell = hero.activeSpell
            if currSpell and currSpell.valid and hero.isChanneling then
                for j = 1, #AllyHeroes do
                    local ally = AllyHeroes[j]
                    if (E_SELF_ON and ally.isMe) or (E_ALLY_ON and not ally.isMe) then
                        local canUse = false
                        local allyPos = ally.pos
                        if currSpell.target == ally.handle then
                            canUse = true
                        else
                            local spellPos = currSpell.placementPos
                            local width = ally.boundingRadius + 100
                            if currSpell.width > 0 then width = width + currSpell.width end
                            local isOnSegment, pointSegment, pointLine = LocalCore:ProjectOn(allyPos, spellPos, heroPos)
                            if LocalCore:IsInRange(pointSegment, allyPos, width) then
                                canUse = true
                            end
                        end
                        if canUse then
                            Control.CastSpell(HK_E, ally)
                        end
                    end
                end
            end
        end
    end
end

local function RLogic()
    local result = false
    if Spells:IsReady(_R, { q = 0.33, w = 0.33, e = 0.33, r = 1 } ) then
        local EnemyHeroes = ObjectManager:GetEnemyHeroes(RData.Range, false, 0)

        if R_KS_ON then
            local baseDmg = 75
            local lvlDmg = 75 * myHero:GetSpellData(_R).level
            local apDmg = myHero.ap * 0.7
            local rDmg = baseDmg + lvlDmg + apDmg
            if rDmg > R_KS_MINHP then
                for i = 1, #EnemyHeroes do
                    local rTarget = EnemyHeroes[i]
                    if rTarget.health > R_KS_MINHP and rTarget.health < Damage:CalculateDamage(myHero, rTarget, LocalCore.DAMAGE_TYPE_MAGICAL, rDmg) then
                        result = LocalCore:CastSpell(HK_R)
                    end
                end
            end
        end if result then return end

        if (Orbwalker.Modes[LocalCore.ORBWALKER_MODE_COMBO] and R_COMBO_ON) or (Orbwalker.Modes[LocalCore.ORBWALKER_MODE_HARASS] and R_HARASS_ON) then
            local count = 0
            local mePos = myHero.pos
            for i = 1, #EnemyHeroes do
                local unit = EnemyHeroes[i]
                if LocalCore:IsInRange(mePos, unit.pos, R_COMBO_RANGEX) then
                    count = count + 1
                end
            end
            if count >= R_COMBO_ENEMIESX then
                result = LocalCore:CastSpell(HK_R)
            end
        end if result then return end
        
        if R_AUTO_ON then
            local count = 0
            local mePos = myHero.pos
            for i = 1, #EnemyHeroes do
                local unit = EnemyHeroes[i]
                if LocalCore:GetDistance(mePos, unit.pos) < R_AUTO_RANGEX then
                    count = count + 1
                end
            end
            if count >= R_AUTO_ENEMIESX then
                result = LocalCore:CastSpell(HK_R)
            end if result then return end
        end
    end
end

AddLoadCallback(function()
    Orbwalker, TargetSelector, ObjectManager, Damage, Spells = _G.SDK.Orbwalker, _G.SDK.TargetSelector, _G.SDK.ObjectManager, _G.SDK.Damage, _G.SDK.Spells

    local Interrupter = LocalCore:__Interrupter()
    Interrupter:OnInterrupt(function(enemy, activeSpell)
        if Q_INTERRUPTER_ON and Spells:IsReady(_Q, { q = 0.3, w = 0.3, e = 0.3, r = 0.3 } ) then
            local pred = GetGamsteronPrediction(enemy, QData, myHero.pos)
            if pred.Hitchance >= _G.HITCHANCE_MEDIUM then
                LocalCore:CastSpell(HK_Q, enemy, pred.CastPosition)
            end
        end
    end)

    Orbwalker.CanAttackC = function()
        if not Spells:CheckSpellDelays({ q = 0.33, w = 0.33, e = 0.33, r = 0.33 }) then
            return false
        end
        -- LastHit, LaneClear
        if not Orbwalker.Modes[LocalCore.ORBWALKER_MODE_COMBO] and not Orbwalker.Modes[LocalCore.ORBWALKER_MODE_HARASS] then
            return true
        end
        -- Q
        if Q_DISABLEAA and myHero:GetSpellData(_Q).level > 0 and myHero.mana > myHero:GetSpellData(_Q).mana and (GameCanUseSpell(_Q) == 0 or myHero:GetSpellData(_Q).currentCd < 1) then
            return false
        end
        return true
    end

    Orbwalker.CanMoveC = function()
        if not Spells:CheckSpellDelays({ q = 0.25, w = 0.25, e = 0.25, r = 0.25 }) then
            return false
        end
        return true
    end

    Callback.Add("Draw", function()
        if debugMode then
            local isautoaa = false
            local status, err = pcall(function () isautoaa = Orbwalker:IsAutoAttacking() end); if not status then print("2501: " .. tostring(err)) end
            if isautoaa then return end
            local status, err = pcall(function () QLogic() end); if not status then print("2501: " .. tostring(err)) end
            local status, err = pcall(function () WLogic() end); if not status then print("2501: " .. tostring(err)) end
            local status, err = pcall(function () ELogic() end); if not status then print("2501: " .. tostring(err)) end
            local status, err = pcall(function () RLogic() end); if not status then print("2501: " .. tostring(err)) end
        else
            if Orbwalker:IsAutoAttacking() then return end
            QLogic()
            WLogic()
            ELogic()
            RLogic()
        end
    end)
end)

_G.GamsteronMorganaLoaded = true
