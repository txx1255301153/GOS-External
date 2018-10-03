--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Initialize:                                                                                                                                          
    -- Return:                                                                                                                                          
        if _G.GamsteronBlitzcrankLoaded or myHero.charName ~= "Blitzcrank" then
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
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local Interrupter = Core:Interrupter()
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    -- Load Prediction:                                                                                                                                       
        if _Update then
            if not FileExist(COMMON_PATH .. "GamsteronPrediction.lua") then
                DownloadFileAsync("https://raw.githubusercontent.com/gamsteron/GOS-External/master/Common/GamsteronPrediction.lua", COMMON_PATH .. "GamsteronPrediction.lua", function() end)
                while not FileExist(COMMON_PATH .. "GamsteronPrediction.lua") do end
            end
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        require('GamsteronPrediction')
        ------------------------------------------------------------------------------------------------------------------------------------------------
        if _G.GamsteronPredictionUpdated then
            return
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local Prediction = _G.GamsteronPrediction
	----------------------------------------------------------------------------------------------------------------------------------------------------
	-- Auto Update:                                                                                                                                     
        if _Update then
            local args =
            {
                version = 0.01,
                ----------------------------------------------------------------------------------------------------------------------------------------
                scriptPath = SCRIPT_PATH .. "GamsteronBlitzcrank.lua",
                scriptUrl = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Champions/GamsteronBlitzcrank.lua",
                ----------------------------------------------------------------------------------------------------------------------------------------
                versionPath = SCRIPT_PATH .. "GamsteronBlitzcrank.version",
                versionUrl = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Champions/GamsteronBlitzcrank.version"
            }
            --------------------------------------------------------------------------------------------------------------------------------------------
            local success, version = Core:AutoUpdate(args)
            --------------------------------------------------------------------------------------------------------------------------------------------
            if success then
                print("GamsteronBlitzcrank updated to version " .. version .. ". Please Reload with 2x F6 !")
                _G.GamsteronBlitzcrankUpdated = true
            end
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        if _G.GamsteronBlitzcrankUpdated then
            return
        end
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Locals:                                                                                                                                              
    local Menu
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    local Orbwalker, TargetSelector, ObjectManager, Damage, Spells
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    local _Q							= _G._Q
	local _W							= _G._W
	local _E							= _G._E
    local _R							= _G._R
    local pairs							= _G.pairs
    local myHero						= _G.myHero
    local GameTimer                     = _G.Game.Timer
    local GameCanUseSpell               = _G.Game.CanUseSpell
    local MathMax                       = _G.math.max
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants:                                                                                                                                           
    local SPELLTYPE_LINE            = 0
    local SPELLTYPE_CIRCLE          = 1
    local SPELLTYPE_CONE            = 2
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    local COLLISION_MINION          = 0
    local COLLISION_ALLYHERO        = 1
    local COLLISION_ENEMYHERO       = 2
    local COLLISION_YASUOWALL       = 3
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    local TEAM_ALLY						= myHero.team
	local TEAM_ENEMY					= 300 - TEAM_ALLY
    local TEAM_JUNGLE					= 300
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    local ORBWALKER_MODE_NONE           = -1
    local ORBWALKER_MODE_COMBO          = 0
    local ORBWALKER_MODE_HARASS         = 1
    local ORBWALKER_MODE_LANECLEAR      = 2
    local ORBWALKER_MODE_JUNGLECLEAR    = 3
    local ORBWALKER_MODE_LASTHIT        = 4
    local ORBWALKER_MODE_FLEE           = 5
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    local DAMAGE_TYPE_PHYSICAL			= 0
	local DAMAGE_TYPE_MAGICAL			= 1
    local DAMAGE_TYPE_TRUE				= 2
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    local HEROES_SPELL                  = 0
    local HEROES_ATTACK                 = 1
    local HEROES_IMMORTAL               = 2
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Load:                                                                                                                                                
    do
        local Q_AUTO_ON = true
        local Q_AUTO_HITCHANCE = 3
        local QData =
        {
            Type = SPELLTYPE_LINE, Aoe = false, From = myHero,
            Delay = 0.25, Radius = 70, Range = 925, Speed = 1800,
            Collision = true, MaxCollision = 0, CollisionObjects = { COLLISION_MINION, COLLISION_YASUOWALL, COLLISION_ENEMYHERO }
        }
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local function LoadMenu()
            Menu = MenuElement({name = "Gamsteron Blitzcrank", id = "GamsteronBlitzcrank", type = _G.MENU })
                Menu:MenuElement({name = "Q Auto", id = "auto", type = _G.MENU })
                    Menu.auto:MenuElement({id = "enabled", name = "Enabled", value = true, callback = function(value) Q_AUTO_ON = value end})
                    Menu.auto:MenuElement({name = "Use on:", id = "useon", type = _G.MENU })
                        Core:OnEnemyHeroLoad(function(hero) Menu.auto.useon:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
                    Menu.auto:MenuElement({id = "hitchance", name = "Hitchance", value = 3, drop = { "Collision", "Normal", "High", "Immobile" }, callback = function(value) Q_AUTO_HITCHANCE = value end })
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        Callback.Add("Load", function()
            Orbwalker, TargetSelector, ObjectManager, Damage, Spells = _G.SDK.Orbwalker, _G.SDK.TargetSelector, _G.SDK.ObjectManager, _G.SDK.Damage, _G.SDK.Spells
            --------------------------------------------------------------------------------------------------------------------------------------------
            LoadMenu()
            --------------------------------------------------------------------------------------------------------------------------------------------
            Orbwalker.CanAttackC = function()
                if not Spells:CheckSpellDelays({ q = 0.4, w = 0, e = 0.33, r = 0.33 }) then
                    return false
                end
                return true
            end
            --------------------------------------------------------------------------------------------------------------------------------------------
            Orbwalker.CanMoveC = function()
                if not Spells:CheckSpellDelays({ q = 0.6, w = 0, e = 0.25, r = 0.25 }) then
                    return false
                end
                return true
            end
        end)
        ------------------------------------------------------------------------------------------------------------------------------------------------
        Callback.Add("Draw", function()
            if Q_AUTO_ON and Spells:IsReady(_Q, { q = 0.3, w = 0.3, e = 0.3, r = 0.3 } ) then
                local EnemyHeroes = ObjectManager:GetEnemyHeroes(QData.Range, false, HEROES_SPELL)
                local qList = {}
                for i = 1, #EnemyHeroes do
                    local hero = EnemyHeroes[i]
                    local isEnabled = Menu.auto.useon[hero.charName]
                    if isEnabled and isEnabled:Value() then
                        table.insert(qList, hero)
                    end
                end
                local qTarget = TargetSelector:GetTarget(qList, DAMAGE_TYPE_MAGICAL)
                if qTarget then
                    if Prediction:CastSpell(HK_Q, qTarget, myHero, QData, Q_AUTO_HITCHANCE) then
                        return
                    end
                end
            end
        end)
    end
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    _G.GamsteronBlitzcrankLoaded = true
--------------------------------------------------------------------------------------------------------------------------------------------------------
