local GamsteronBlitzVer = 0.03
local LocalCore, Menu, Orbwalker, TargetSelector, ObjectManager, Damage, Spells

do
    if _G.GamsteronBlitzcrankLoaded or myHero.charName ~= "Blitzcrank" then
        return
    end

    if not FileExist(COMMON_PATH .. "GamsteronCore.lua") then
        DownloadFileAsync("https://raw.githubusercontent.com/gamsteron/GOS-External/master/Common/GamsteronCore.lua", COMMON_PATH .. "GamsteronCore.lua", function() end)
        while not FileExist(COMMON_PATH .. "GamsteronCore.lua") do end
    end

    require('GamsteronCore')
    if _G.GamsteronCoreUpdated then
        return
    end
    LocalCore = _G.GamsteronCore

    local success, version = LocalCore:AutoUpdate({
        version = GamsteronBlitzVer,
        scriptPath = SCRIPT_PATH .. "GamsteronBlitzcrank.lua",
        scriptUrl = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Champions/GamsteronBlitzcrank.lua",
        versionPath = SCRIPT_PATH .. "GamsteronBlitzcrank.version",
        versionUrl = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Champions/GamsteronBlitzcrank.version"
    })

    if success then
        print("GamsteronBlitzcrank updated to version " .. version .. ". Please Reload with 2x F6 !")
        _G.GamsteronBlitzcrankUpdated = true
        return
    end
end

local Menu, Orbwalker, TargetSelector, ObjectManager, Damage, Spells

local pairs							= _G.pairs
local myHero						= _G.myHero
local GameTimer                     = _G.Game.Timer
local GameCanUseSpell               = _G.Game.CanUseSpell
local MathMax                       = _G.math.max

local Q_AUTO_ON = true
local Q_INTERRUPTER_ON = true
local Q_AUTO_HITCHANCE = 3

local QData =
{
    Type = LocalCore.SPELLTYPE_LINE, Aoe = false, From = myHero,
    Delay = 0.25, Radius = 70, Range = 925, Speed = 1800,
    Collision = true, MaxCollision = 0, CollisionObjects = { LocalCore.COLLISION_MINION, LocalCore.COLLISION_YASUOWALL, LocalCore.COLLISION_ENEMYHERO }
}

local function LoadMenu()
    Menu = MenuElement({name = "Gamsteron Blitzcrank", id = "GamsteronBlitzcrank", type = _G.MENU })
        Menu:MenuElement({id = "interrupter", name = "Interrupter", value = true, callback = function(value) Q_INTERRUPTER_ON = value end})
        Menu:MenuElement({name = "Q Auto", id = "auto", type = _G.MENU })
            Menu.auto:MenuElement({id = "enabled", name = "Enabled", value = true, callback = function(value) Q_AUTO_ON = value end})
            Menu.auto:MenuElement({name = "Use on:", id = "useon", type = _G.MENU })
                LocalCore:OnEnemyHeroLoad(function(hero) Menu.auto.useon:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
            Menu.auto:MenuElement({id = "hitchance", name = "Hitchance", value = 3, drop = { "Collision", "Normal", "High", "Immobile" }, callback = function(value) Q_AUTO_HITCHANCE = value end })
        Menu:MenuElement({name = "Version " .. tostring(GamsteronBlitzVer), type = _G.SPACE, id = "verblitzspace"})
end

local function QLogic()
    if Q_AUTO_ON and Spells:IsReady(_Q, { q = 0.3, w = 0.3, e = 0.3, r = 0.3 } ) then
        local EnemyHeroes = ObjectManager:GetEnemyHeroes(QData.Range, false, LocalCore.HEROES_SPELL)
        local qList = {}
        for i = 1, #EnemyHeroes do
            local hero = EnemyHeroes[i]
            local isEnabled = Menu.auto.useon[hero.charName]
            if isEnabled and isEnabled:Value() then
                table.insert(qList, hero)
            end
        end
        local qTarget = TargetSelector:GetTarget(qList, LocalCore.DAMAGE_TYPE_MAGICAL)
        if qTarget then
            if LocalCore:CastSpell(HK_Q, qTarget, myHero, QData, Q_AUTO_HITCHANCE) then
                return
            end
        end
    end
end

AddLoadCallback(function()
    Orbwalker, TargetSelector, ObjectManager, Damage, Spells = _G.SDK.Orbwalker, _G.SDK.TargetSelector, _G.SDK.ObjectManager, _G.SDK.Damage, _G.SDK.Spells

    LoadMenu()

    local Interrupter = LocalCore:__Interrupter()
    Interrupter:OnInterrupt(function(enemy, activeSpell)
        if Q_INTERRUPTER_ON and Spells:IsReady(_Q, { q = 0.3, w = 0.3, e = 0.3, r = 0.3 } ) then
            LocalCore:CastSpell(HK_Q, enemy, myHero, QData, 4)
        end
    end)

    Orbwalker.CanAttackC = function()
        if not Spells:CheckSpellDelays({ q = 0.4, w = 0, e = 0.33, r = 0.33 }) then
            return false
        end
        return true
    end

    Orbwalker.CanMoveC = function()
        if not Spells:CheckSpellDelays({ q = 0.6, w = 0, e = 0.25, r = 0.25 }) then
            return false
        end
        return true
    end

    Callback.Add("Draw", function()
        if Orbwalker:IsAutoAttacking() then return end
        QLogic()
    end)
end)

_G.GamsteronBlitzcrankLoaded = true
