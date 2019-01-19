local GamsteronCoreVer = 0.09

local function DownloadFile(url, path)
    DownloadFileAsync(url, path, function() end)
    while not FileExist(path) do end
end

local function Trim(s)
    local from = s:match"^%s*()"
    return from > #s and "" or s:match(".*%S", from)
end

local function ReadFile(path)
    local result = {}
    local file = io.open(path, "r")
    if file then
        for line in file:lines() do
            local str = Trim(line)
            if #str > 0 then
                table.insert(result, str)
            end
        end
        file:close()
    end
    return result
end

local function AutoUpdate(args)
    DownloadFile(args.versionUrl, args.versionPath)
    local fileResult = ReadFile(args.versionPath)
    local newVersion = tonumber(fileResult[1])
    if newVersion > args.version then
        DownloadFile(args.scriptUrl, args.scriptPath)
        return true, newVersion
    end
    return false, args.version
end

do
    if _G.GamsteronCoreLoaded == true then return end

    local success, version = AutoUpdate({
        version = GamsteronCoreVer,
        scriptPath = COMMON_PATH .. "GamsteronCore.lua",
        scriptUrl = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Common/GamsteronCore.lua",
        versionPath = COMMON_PATH .. "GamsteronCore.version",
        versionUrl = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Common/GamsteronCore.version"
    })
    
    if success then
        print("GamsteronCore updated to version " .. version .. ". Please Reload with 2x F6 !")
        _G.GamsteronCoreUpdated = true
        return
    end
end

local MathSqrt                      = _G.math.sqrt
local MathMax                       = _G.math.max
local MathAbs                       = _G.math.abs
local MathHuge                      = 99999999
local MathPI                        = _G.math.pi
local MathAtan                      = _G.math.atan
local MathMin                       = _G.math.min
local MathSin                       = _G.math.sin
local MathCos                       = _G.math.cos
local MathCeil                      = _G.math.ceil
local TableInsert                   = _G.table.insert
local TableRemove                   = _G.table.remove

local myHero                        = _G.myHero
local GetTickCount                  = _G.GetTickCount
local GameTimer                     = _G.Game.Timer
local GameParticleCount             = _G.Game.ParticleCount
local GameParticle                  = _G.Game.Particle
local GameHeroCount                 = _G.Game.HeroCount
local GameHero                      = _G.Game.Hero
local GameMinionCount               = _G.Game.MinionCount
local GameMinion                    = _G.Game.Minion
local GameTurretCount               = _G.Game.TurretCount
local GameTurret                    = _G.Game.Turret
local GameWardCount                 = _G.Game.WardCount
local GameWard                      = _G.Game.Ward
local GameObjectCount               = _G.Game.ObjectCount
local GameObject                    = _G.Game.Object
local GameMissileCount              = _G.Game.MissileCount
local GameMissile                   = _G.Game.Missile

local GeneralLoaded                 = false
local GeneralLoadTimers             = { EndTime = 0, Active = false, PreActive = false }

local BuildingsLoaded               = false
local BuildingsLoad                 =
{
    Performance                 = 0,
    EndTime                     = 0,
    Turrets                     = {},
    Nexuses                     = {},
    Inhibitors                  = {},
    OnAllyNexusLoadC            = {},
    OnAllyInhibitorLoadC        = {},
    OnAllyTurretLoadC           = {},
    OnEnemyNexusLoadC           = {},
    OnEnemyInhibitorLoadC       = {},
    OnEnemyTurretLoadC          = {}
}

local HeroesLoaded                  = false
local HeroesLoad                    =
{
    Performance                 = 0,
    EndTime                     = 120,
    Count                       = 0,
    Heroes                      = {},
    OnEnemyHeroLoadC            = {},
    OnAllyHeroLoadC             = {}
}

local OnLoadC                       = {}
local OnProcessRecallC              = {}
local OnProcessSpellCastC           = {}
local OnProcessSpellCompleteC       = {}
local OnProcessWaypointC            = {}
local OnCancelAttackC               = {}
local OnUpdateBuffC                 = {}
local OnCreateBuffC                 = {}
local OnRemoveBuffC                 = {}
local OnGainVisionC                 = {}
local OnLoseVisionC                 = {}
local OnIssueOrderC                 = {}
local OnSpellCastC                  = {}

local DebugMode                     = false
local HighAccuracy                  = 0.1
local MaxRangeMulipier              = 1

local Menu                          = MenuElement({name = "Gamsteron Core", id = "GamCore", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Icons/GamsteronCore.png" })
    Menu:MenuElement({id = "ping", name = "Your Ping", value = 50, min = 0, max = 150, step = 5, callback = function(value) _G.LATENCY = value * 0.001 end })
    Menu:MenuElement({id = "PredHighAccuracy", name = "Pred High Accuracy [ last move ms ]", value = 100, min = 25, max = 100, step = 5, callback = function(value) HighAccuracy = value * 0.001 end })
    Menu:MenuElement({id = "PredMaxRange", name = "Pred Max Range %", value = 100, min = 70, max = 100, step = 1, callback = function(value) MaxRangeMulipier = value * 0.01 end })
    Menu:MenuElement({name = "Version " .. tostring(GamsteronCoreVer), type = _G.SPACE, id = "vercorespace"})
    _G.LATENCY = Menu.ping:Value() * 0.001
    HighAccuracy = Menu.PredHighAccuracy:Value() * 0.001
    MaxRangeMulipier = Menu.PredMaxRange:Value() * 0.01

local HeroData                      = {}

local IsYasuo                       = false
local Yasuo                         = { Wall = nil, Name = nil, Level = 0, CastTime = 0, StartPos = nil }

local AllyNexus                     = nil
local EnemyNexus                    = nil
local AllyInhibitors                = {}
local EnemyInhibitors               = {}
local AllyTurrets                   = {}
local EnemyTurrets                  = {}

local TickActions                   = {}

local function Class()
    local cls = {}
    cls.__index = cls
    return setmetatable(cls, {__call = function (c, ...)
        local instance = setmetatable({}, cls)
        if cls.__init then
            cls.__init(instance, ...)
        end
        return instance
    end})
end

local __GamsteronCore = Class()

function __GamsteronCore:__init()
    self.HEROES_SPELL                     = 0
    self.HEROES_ATTACK                    = 1
    self.HEROES_IMMORTAL                  = 2

    self.SPELLCAST_ATTACK                 = 0
    self.SPELLCAST_DASH                   = 1
    self.SPELLCAST_IMMOBILE               = 2
    self.SPELLCAST_OTHER                  = 3

    self.TEAM_ALLY                        = myHero.team
    self.TEAM_ENEMY                       = 300 - self.TEAM_ALLY
    self.TEAM_JUNGLE                      = 300

    self.COLLISION_MINION                 = 0
    self.COLLISION_ALLYHERO               = 1
    self.COLLISION_ENEMYHERO              = 2
    self.COLLISION_YASUOWALL              = 3

    self.HITCHANCE_IMPOSSIBLE             = 0
    self.HITCHANCE_COLLISION              = 1
    self.HITCHANCE_NORMAL                 = 2
    self.HITCHANCE_HIGH                   = 3
    self.HITCHANCE_IMMOBILE               = 4

    self.SPELLTYPE_LINE                   = 0
    self.SPELLTYPE_CIRCLE                 = 1
    self.SPELLTYPE_CONE                   = 2

    self.DAMAGE_TYPE_PHYSICAL			    = 0
    self.DAMAGE_TYPE_MAGICAL			    = 1
    self.DAMAGE_TYPE_TRUE				    = 2

    self.MINION_TYPE_OTHER_MINION		    = 1
    self.MINION_TYPE_MONSTER			    = 2
    self.MINION_TYPE_LANE_MINION		    = 3

    self.ORBWALKER_MODE_NONE			    = -1
    self.ORBWALKER_MODE_COMBO			    = 0
    self.ORBWALKER_MODE_HARASS			= 1
    self.ORBWALKER_MODE_LANECLEAR		    = 2
    self.ORBWALKER_MODE_JUNGLECLEAR	    = 3
    self.ORBWALKER_MODE_LASTHIT		    = 4
    self.ORBWALKER_MODE_FLEE			    = 5

    self.BaseTurrets                      =
    {
        ["SRUAP_Turret_Order3"] = true,
        ["SRUAP_Turret_Order4"] = true,
        ["SRUAP_Turret_Chaos3"] = true,
        ["SRUAP_Turret_Chaos4"] = true
    }

    self.Obj_AI_Bases                     =
    {
        [Obj_AI_Hero] = true,
        [Obj_AI_Minion] = true,
        [Obj_AI_Turret] = true
    }

    self.ChannelingBuffs                  =
    {
        ["Caitlyn"] = function(unit)
            return self:HasBuff(unit, "CaitlynAceintheHole")
        end,
        ["Fiddlesticks"] = function(unit)
            return self:HasBuff(unit, "Drain") or self:HasBuff(unit, "Crowstorm")
        end,
        ["Galio"] = function(unit)
            return self:HasBuff(unit, "GalioIdolOfDurand")
        end,
        ["Janna"] = function(unit)
            return self:HasBuff(unit, "ReapTheWhirlwind")
        end,
        ["Kaisa"] = function(unit)
            return self:HasBuff(unit, "KaisaE")
        end,
        ["Karthus"] = function(unit)
            return self:HasBuff(unit, "karthusfallenonecastsound")
        end,
        ["Katarina"] = function(unit)
            return self:HasBuff(unit, "katarinarsound")
        end,
        ["Lucian"] = function(unit)
            return self:HasBuff(unit, "LucianR")
        end,
        ["Malzahar"] = function(unit)
            return self:HasBuff(unit, "alzaharnethergraspsound")
        end,
        ["MasterYi"] = function(unit)
            return self:HasBuff(unit, "Meditate")
        end,
        ["MissFortune"] = function(unit)
            return self:HasBuff(unit, "missfortunebulletsound")
        end,
        ["Nunu"] = function(unit)
            return self:HasBuff(unit, "AbsoluteZero")
        end,
        ["Pantheon"] = function(unit)
            return self:HasBuff(unit, "pantheonesound") or self:HasBuff(unit, "PantheonRJump")
        end,
        ["Shen"] = function(unit)
            return self:HasBuff(unit, "shenstandunitedlock")
        end,
        ["TwistedFate"] = function(unit)
            return self:HasBuff(unit, "Destiny")
        end,
        ["Urgot"] = function(unit)
            return self:HasBuff(unit, "UrgotSwap2")
        end,
        ["Varus"] = function(unit)
            return self:HasBuff(unit, "VarusQ")
        end,
        ["VelKoz"] = function(unit)
            return self:HasBuff(unit, "VelkozR")
        end,
        ["Vi"] = function(unit)
            return self:HasBuff(unit, "ViQ")
        end,
        ["Vladimir"] = function(unit)
            return self:HasBuff(unit, "VladimirE")
        end,
        ["Warwick"] = function(unit)
            return self:HasBuff(unit, "infiniteduresssound")
        end,
        ["Xerath"] = function(unit)
            return self:HasBuff(unit, "XerathArcanopulseChargeUp") or self:HasBuff(unit, "XerathLocusOfPower2")
        end
    }

    self.MinionsRange                     =
    {
        ["SRU_ChaosMinionMelee"] = 110,
        ["SRU_ChaosMinionRanged"] = 550,
        ["SRU_ChaosMinionSiege"] = 300,
        ["SRU_ChaosMinionSuper"] = 170,
        ["SRU_OrderMinionMelee"] = 110,
        ["SRU_OrderMinionRanged"] = 550,
        ["SRU_OrderMinionSiege"] = 300,
        ["SRU_OrderMinionSuper"] = 170,
        ["HA_ChaosMinionMelee"] = 110,
        ["HA_ChaosMinionRanged"] = 550,
        ["HA_ChaosMinionSiege"] = 300,
        ["HA_ChaosMinionSuper"] = 170,
        ["HA_OrderMinionMelee"] = 110,
        ["HA_OrderMinionRanged"] = 550,
        ["HA_OrderMinionSiege"] = 300,
        ["HA_OrderMinionSuper"] = 170
    }

    self.SpecialAutoAttackRanges          =
    {
        ["Caitlyn"] = function(target)
            if target ~= nil and self:HasBuff(target, "caitlynyordletrapinternal") then
                return 650
            end
            return 0
        end
    }

    self.SpecialWindUpTimes               =
    {
        ["TwistedFate"] = function(unit, target)
            if self:HasBuff(unit, "BlueCardPreAttack") or self:HasBuff(unit, "RedCardPreAttack") or self:HasBuff(unit, "GoldCardPreAttack") then
                return 0.125
            end
            return nil
        end
    }

    self.SpecialMissileSpeeds             =
    {
        ["Caitlyn"] = function(unit, target)
            if self:HasBuff(unit, "caitlynheadshot") then
                return 3000
            end
            return nil
        end,
        ["Graves"] = function(unit, target)
            return 3800
        end,
        ["Illaoi"] = function(unit, target)
            if self:HasBuff(unit, "IllaoiW") then
                return 1600
            end
            return nil
        end,
        ["Jayce"] = function(unit, target)
            if self:HasBuff(unit, "jaycestancegun") then
                return 2000
            end
            return nil
        end,
        ["Jhin"] = function(unit, target)
            if self:HasBuff(unit, "jhinpassiveattackbuff") then
                return 3000
            end
            return nil
        end,
        ["Jinx"] = function(unit, target)
            if self:HasBuff(unit, "JinxQ") then
                return 2000
            end
            return nil
        end,
        ["Poppy"] = function(unit, target)
            if self:HasBuff(unit, "poppypassivebuff") then
                return 1600
            end
            return nil
        end,
        ["Twitch"] = function(unit, target)
            if self:HasBuff(unit, "TwitchFullAutomatic") then
                return 4000
            end
            return nil
        end
    }

    self.TurretToMinionPercentMod         =
    {
        ["SRU_ChaosMinionMelee"] = 0.43,
        ["SRU_ChaosMinionRanged"] = 0.68,
        ["SRU_ChaosMinionSiege"] = 0.14,
        ["SRU_ChaosMinionSuper"] = 0.05,
        ["SRU_OrderMinionMelee"] = 0.43,
        ["SRU_OrderMinionRanged"] = 0.68,
        ["SRU_OrderMinionSiege"] = 0.14,
        ["SRU_OrderMinionSuper"] = 0.05,
        ["HA_ChaosMinionMelee"] = 0.43,
        ["HA_ChaosMinionRanged"] = 0.68,
        ["HA_ChaosMinionSiege"] = 0.14,
        ["HA_ChaosMinionSuper"] = 0.05,
        ["HA_OrderMinionMelee"] = 0.43,
        ["HA_OrderMinionRanged"] = 0.68,
        ["HA_OrderMinionSiege"] = 0.14,
        ["HA_OrderMinionSuper"] = 0.05
    }

    self.MinionIsMelee                    =
    {
        ["SRU_ChaosMinionMelee"] = true, ["SRU_ChaosMinionSuper"] = true,  ["SRU_OrderMinionMelee"] = true, ["SRU_OrderMinionSuper"] = true, ["HA_ChaosMinionMelee"] = true,
        ["HA_ChaosMinionSuper"] = true, ["HA_OrderMinionMelee"] = true, ["HA_OrderMinionSuper"] = true
    }

    self.NoAutoAttacks                    =
    {
        ["GravesAutoAttackRecoil"] = true
    }

    self.SpecialAutoAttacks               =
    {
        ["CaitlynHeadshotMissile"] = true,
        ["GarenQAttack"] = true,
        ["KennenMegaProc"] = true,
        ["MordekaiserQAttack"] = true,
        ["MordekaiserQAttack1"] = true,
        ["MordekaiserQAttack2"] = true,
        ["QuinnWEnhanced"] = true,
        ["BlueCardPreAttack"] = true,
        ["RedCardPreAttack"] = true,
        ["GoldCardPreAttack"] = true,
        ["XenZhaoThrust"] = true,
        ["XenZhaoThrust2"] = true,
        ["XenZhaoThrust3"] = true
    }

    self.IsMelee                          =
    {
        ["Aatrox"] = true,
        ["Ahri"] = false,
        ["Akali"] = true,
        ["Alistar"] = true,
        ["Amumu"] = true,
        ["Anivia"] = false,
        ["Annie"] = false,
        ["Ashe"] = false,
        ["AurelionSol"] = false,
        ["Azir"] = true,
        ["Bard"] = false,
        ["Blitzcrank"] = true,
        ["Brand"] = false,
        ["Braum"] = true,
        ["Caitlyn"] = false,
        ["Camille"] = true,
        ["Cassiopeia"] = false,
        ["Chogath"] = true,
        ["Corki"] = false,
        ["Darius"] = true,
        ["Diana"] = true,
        ["DrMundo"] = true,
        ["Draven"] = false,
        ["Ekko"] = true,
        ["Elise"] = false,
        ["Evelynn"] = true,
        ["Ezreal"] = false,
        ["Fiddlesticks"] = false,
        ["Fiora"] = true,
        ["Fizz"] = true,
        ["Galio"] = true,
        ["Gangplank"] = true,
        ["Garen"] = true,
        ["Gnar"] = false,
        ["Gragas"] = true,
        ["Graves"] = false,
        ["Hecarim"] = true,
        ["Heimerdinger"] = false,
        ["Illaoi"] = true,
        ["Irelia"] = true,
        ["Ivern"] = true,
        ["Janna"] = false,
        ["JarvanIV"] = true,
        ["Jax"] = true,
        ["Jayce"] = false,
        ["Jhin"] = false,
        ["Jinx"] = false,
        ["Kaisa"] = false,
        ["Kalista"] = false,
        ["Karma"] = false,
        ["Karthus"] = false,
        ["Kassadin"] = true,
        ["Katarina"] = true,
        ["Kayle"] = false,
        ["Kayn"] = true,
        ["Kennen"] = false,
        ["Khazix"] = true,
        ["Kindred"] = false,
        ["Kled"] = true,
        ["KogMaw"] = false,
        ["Leblanc"] = false,
        ["LeeSin"] = true,
        ["Leona"] = true,
        ["Lissandra"] = false,
        ["Lucian"] = false,
        ["Lulu"] = false,
        ["Lux"] = false,
        ["Malphite"] = true,
        ["Malzahar"] = false,
        ["Maokai"] = true,
        ["MasterYi"] = true,
        ["MissFortune"] = false,
        ["MonkeyKing"] = true,
        ["Mordekaiser"] = true,
        ["Morgana"] = false,
        ["Nami"] = false,
        ["Nasus"] = true,
        ["Nautilus"] = true,
        ["Nidalee"] = false,
        ["Nocturne"] = true,
        ["Nunu"] = true,
        ["Olaf"] = true,
        ["Orianna"] = false,
        ["Ornn"] = true,
        ["Pantheon"] = true,
        ["Poppy"] = true,
        ["Pyke"] = true,
        ["Quinn"] = false,
        ["Rakan"] = true,
        ["Rammus"] = true,
        ["RekSai"] = true,
        ["Renekton"] = true,
        ["Rengar"] = true,
        ["Riven"] = true,
        ["Rumble"] = true,
        ["Ryze"] = false,
        ["Sejuani"] = true,
        ["Shaco"] = true,
        ["Shen"] = true,
        ["Shyvana"] = true,
        ["Singed"] = true,
        ["Sion"] = true,
        ["Sivir"] = false,
        ["Skarner"] = true,
        ["Sona"] = false,
        ["Soraka"] = false,
        ["Swain"] = false,
        ["Syndra"] = false,
        ["TahmKench"] = true,
        ["Taliyah"] = false,
        ["Talon"] = true,
        ["Taric"] = true,
        ["Teemo"] = false,
        ["Thresh"] = true,
        ["Tristana"] = false,
        ["Trundle"] = true,
        ["Tryndamere"] = true,
        ["TwistedFate"] = false,
        ["Twitch"] = false,
        ["Udyr"] = true,
        ["Urgot"] = true,
        ["Varus"] = false,
        ["Vayne"] = false,
        ["Veigar"] = false,
        ["Velkoz"] = false,
        ["Vi"] = true,
        ["Viktor"] = false,
        ["Vladimir"] = false,
        ["Volibear"] = true,
        ["Warwick"] = true,
        ["Xayah"] = false,
        ["Xerath"] = false,
        ["XinZhao"] = true,
        ["Yasuo"] = true,
        ["Yorick"] = true,
        ["Zac"] = true,
        ["Zed"] = true,
        ["Ziggs"] = false,
        ["Zilean"] = false,
        ["Zoe"] = false,
        ["Zyra"] = false
    }

    self.SpecialMelees                    =
    {
        ["Elise"] = function()
            return myHero.range < 200
        end,
        ["Gnar"] = function()
            return myHero.range < 200
        end,
        ["Jayce"] = function()
            return myHero.range < 200
        end,
        ["Kayle"] = function()
            return myHero.range < 200
        end,
        ["Nidalee"] = function()
            return myHero.range < 200
        end
    }

    self.Priorities                       =
    {
        ["Aatrox"] = 3,
        ["Ahri"] = 4,
        ["Akali"] = 4,
        ["Alistar"] = 1,
        ["Amumu"] = 1,
        ["Anivia"] = 4,
        ["Annie"] = 4,
        ["Ashe"] = 5,
        ["AurelionSol"] = 4,
        ["Azir"] = 4,
        ["Bard"] = 3,
        ["Blitzcrank"] = 1,
        ["Brand"] = 4,
        ["Braum"] = 1,
        ["Caitlyn"] = 5,
        ["Camille"] = 3,
        ["Cassiopeia"] = 4,
        ["Chogath"] = 1,
        ["Corki"] = 5,
        ["Darius"] = 2,
        ["Diana"] = 4,
        ["DrMundo"] = 1,
        ["Draven"] = 5,
        ["Ekko"] = 4,
        ["Elise"] = 3,
        ["Evelynn"] = 4,
        ["Ezreal"] = 5,
        ["Fiddlesticks"] = 3,
        ["Fiora"] = 3,
        ["Fizz"] = 4,
        ["Galio"] = 1,
        ["Gangplank"] = 4,
        ["Garen"] = 1,
        ["Gnar"] = 1,
        ["Gragas"] = 2,
        ["Graves"] = 4,
        ["Hecarim"] = 2,
        ["Heimerdinger"] = 3,
        ["Illaoi"] = 3,
        ["Irelia"] = 3,
        ["Ivern"] = 1,
        ["Janna"] = 2,
        ["JarvanIV"] = 3,
        ["Jax"] = 3,
        ["Jayce"] = 4,
        ["Jhin"] = 5,
        ["Jinx"] = 5,
        ["Kaisa"] = 5,
        ["Kalista"] = 5,
        ["Karma"] = 4,
        ["Karthus"] = 4,
        ["Kassadin"] = 4,
        ["Katarina"] = 4,
        ["Kayle"] = 4,
        ["Kayn"] = 4,
        ["Kennen"] = 4,
        ["Khazix"] = 4,
        ["Kindred"] = 4,
        ["Kled"] = 2,
        ["KogMaw"] = 5,
        ["Leblanc"] = 4,
        ["LeeSin"] = 3,
        ["Leona"] = 1,
        ["Lissandra"] = 4,
        ["Lucian"] = 5,
        ["Lulu"] = 3,
        ["Lux"] = 4,
        ["Malphite"] = 1,
        ["Malzahar"] = 3,
        ["Maokai"] = 2,
        ["MasterYi"] = 5,
        ["MissFortune"] = 5,
        ["MonkeyKing"] = 3,
        ["Mordekaiser"] = 4,
        ["Morgana"] = 3,
        ["Nami"] = 3,
        ["Nasus"] = 2,
        ["Nautilus"] = 1,
        ["Nidalee"] = 4,
        ["Nocturne"] = 4,
        ["Nunu"] = 2,
        ["Olaf"] = 2,
        ["Orianna"] = 4,
        ["Ornn"] = 2,
        ["Pantheon"] = 3,
        ["Poppy"] = 2,
        ["Pyke"] = 4,
        ["Quinn"] = 5,
        ["Rakan"] = 3,
        ["Rammus"] = 1,
        ["RekSai"] = 2,
        ["Renekton"] = 2,
        ["Rengar"] = 4,
        ["Riven"] = 4,
        ["Rumble"] = 4,
        ["Ryze"] = 4,
        ["Sejuani"] = 2,
        ["Shaco"] = 4,
        ["Shen"] = 1,
        ["Shyvana"] = 2,
        ["Singed"] = 1,
        ["Sion"] = 1,
        ["Sivir"] = 5,
        ["Skarner"] = 2,
        ["Sona"] = 3,
        ["Soraka"] = 3,
        ["Swain"] = 3,
        ["Syndra"] = 4,
        ["TahmKench"] = 1,
        ["Taliyah"] = 4,
        ["Talon"] = 4,
        ["Taric"] = 1,
        ["Teemo"] = 4,
        ["Thresh"] = 1,
        ["Tristana"] = 5,
        ["Trundle"] = 2,
        ["Tryndamere"] = 4,
        ["TwistedFate"] = 4,
        ["Twitch"] = 5,
        ["Udyr"] = 2,
        ["Urgot"] = 2,
        ["Varus"] = 5,
        ["Vayne"] = 5,
        ["Veigar"] = 4,
        ["Velkoz"] = 4,
        ["Vi"] = 2,
        ["Viktor"] = 4,
        ["Vladimir"] = 3,
        ["Volibear"] = 2,
        ["Warwick"] = 2,
        ["Xayah"] = 5,
        ["Xerath"] = 4,
        ["XinZhao"] = 3,
        ["Yasuo"] = 4,
        ["Yorick"] = 2,
        ["Zac"] = 1,
        ["Zed"] = 4,
        ["Ziggs"] = 4,
        ["Zilean"] = 3,
        ["Zoe"] = 4,
        ["Zyra"] = 2
    }

    self.PriorityMultiplier               =
    {
        [1] = 1.6,
        [2] = 1.45,
        [3] = 1.3,
        [4] = 1.15,
        [5] = 1
    }

    self.StaticChampionDamageDatabase     =
    {
        ["Caitlyn"] = function(args)
            if self:HasBuff(args.From, "caitlynheadshot") then
                if args.TargetIsMinion then
                    args.RawPhysical = args.RawPhysical + args.From.totalDamage * 1.5;
                else
                    --TODO
                end
            end
        end,
        ["Corki"] = function(args)
            args.RawTotal = args.RawTotal * 0.5;
            args.RawMagical = args.RawTotal;
        end,
        ["Diana"] = function(args)
            if self:GetBuffCount(args.From, "dianapassivemarker") == 2 then
                local level = args.From.levelData.lvl
                args.RawMagical = args.RawMagical + MathMax(15 + 5 * level, -10 + 10 * level, -60 + 15 * level, -125 + 20 * level, -200 + 25 * level) + 0.8 * args.From.ap;
            end
        end,
        ["Draven"] = function(args)
            if self:HasBuff(args.From, "DravenSpinningAttack") then
                local level = args.From:GetSpellData(_Q).level
                args.RawPhysical = args.RawPhysical + 25 + 5 * level + (0.55 + 0.1 * level) * args.From.bonusDamage; 
            end
            
        end,
        ["Graves"] = function(args)
            local t = { 70, 71, 72, 74, 75, 76, 78, 80, 81, 83, 85, 87, 89, 91, 95, 96, 97, 100 };
            args.RawTotal = args.RawTotal * t[Damage:GetMaxLevel(args.From)] * 0.01;
        end,
        ["Jinx"] = function(args)
            if self:HasBuff(args.From, "JinxQ") then
                args.RawPhysical = args.RawPhysical + args.From.totalDamage * 0.1;
            end
        end,
        ["Kalista"] = function(args)
            args.RawPhysical = args.RawPhysical - args.From.totalDamage * 0.1;
        end,
        ["Kayle"] = function(args)
            local level = args.From:GetSpellData(_E).level
            if level > 0 then
                if self:HasBuff(args.From, "JudicatorRighteousFury") then
                    args.RawMagical = args.RawMagical + 10+ 10* level + 0.3 * args.From.ap;
                else
                    args.RawMagical = args.RawMagical + 5+ 5* level + 0.15 * args.From.ap;
                end
            end
        end,
        ["Nasus"] = function(args)
            if self:HasBuff(args.From, "NasusQ") then
                args.RawPhysical = args.RawPhysical + MathMax(self:GetBuffCount(args.From, "NasusQStacks"), 0) + 10 + 20 * args.From:GetSpellData(_Q).level
            end
        end,
        ["Thresh"] = function(args)
            local level = args.From:GetSpellData(_E).level
            if level > 0 then
                local damage = MathMax(self:GetBuffCount(args.From, "threshpassivesouls"), 0) + (0.5 + 0.3 * level) * args.From.totalDamage;
                if self:HasBuff(args.From, "threshqpassive4") then
                    damage = damage * 1;
                elseif self:HasBuff(args.From, "threshqpassive3") then
                    damage = damage * 0.5;
                elseif self:HasBuff(args.From, "threshqpassive2") then
                    damage = damage * 1/3;
                else
                    damage = damage * 0.25;
                end
                args.RawMagical = args.RawMagical + damage;
            end
        end,
        ["TwistedFate"] = function(args)
            if self:HasBuff(args.From, "cardmasterstackparticle") then
                args.RawMagical = args.RawMagical + 30 + 25 * args.From:GetSpellData(_E).level + 0.5 * args.From.ap;
            end
            if self:HasBuff(args.From, "BlueCardPreAttack") then
                args.DamageType = self.DAMAGE_TYPE_MAGICAL;
                args.RawMagical = args.RawMagical + 20 + 20 * args.From:GetSpellData(_W).level + 0.5 * args.From.ap;
            elseif self:HasBuff(args.From, "RedCardPreAttack") then
                args.DamageType = self.DAMAGE_TYPE_MAGICAL;
                args.RawMagical = args.RawMagical + 15 + 15 * args.From:GetSpellData(_W).level + 0.5 * args.From.ap;
            elseif self:HasBuff(args.From, "GoldCardPreAttack") then
                args.DamageType = self.DAMAGE_TYPE_MAGICAL;
                args.RawMagical = args.RawMagical + 7.5 + 7.5 * args.From:GetSpellData(_W).level + 0.5 * args.From.ap;
            end
        end,
        ["Varus"] = function(args)
            local level = args.From:GetSpellData(_W).level
            if level > 0 then
                args.RawMagical = args.RawMagical + 6 + 4 * level + 0.25 * args.From.ap;
            end
        end,
        ["Viktor"] = function(args)
            if self:HasBuff(args.From, "ViktorPowerTransferReturn") then
                args.DamageType = self.DAMAGE_TYPE_MAGICAL;
                args.RawMagical = args.RawMagical + 20 * args.From:GetSpellData(_Q).level + 0.5 * args.From.ap;
            end
        end,
        ["Vayne"] = function(args)
            if self:HasBuff(args.From, "vaynetumblebonus") then
                args.RawPhysical = args.RawPhysical + (0.25 + 0.05 * args.From:GetSpellData(_Q).level) * args.From.totalDamage;
            end
        end
    }

    self.VariableChampionDamageDatabase   =
    {
        ["Jhin"] = function(args)
            if self:HasBuff(args.From, "jhinpassiveattackbuff") then
                args.CriticalStrike = true;
                args.RawPhysical = args.RawPhysical + MathMin(0.25, 0.1 + 0.05 * MathCeil(args.From.levelData.lvl / 5)) * (args.Target.maxHealth - args.Target.health);
            end
        end,
        ["Lux"] = function(args)
            if self:HasBuff(args.Target, "LuxIlluminatingFraulein") then
                args.RawMagical = 20 + args.From.levelData.lvl * 10 + args.From.ap * 0.2;
            end
        end,
        ["Orianna"] = function(args)
            local level = MathCeil(args.From.levelData.lvl / 3);
            args.RawMagical = args.RawMagical + 2 + 8 * level + 0.15 * args.From.ap;
            if args.Target.handle == args.From.attackData.target then
                args.RawMagical = args.RawMagical + MathMax(self:GetBuffCount(args.From, "orianapowerdaggerdisplay"), 0) * (0.4 + 1.6 * level + 0.03 * args.From.ap);
            end
        end,
        ["Quinn"] = function(args)
            if self:HasBuff(args.Target, "QuinnW") then
                local level = args.From.levelData.lvl
                args.RawPhysical = args.RawPhysical + 10 + level * 5 + (0.14 + 0.02 * level) * args.From.totalDamage;
            end
        end,
        ["Vayne"] = function(args)
            if self:GetBuffCount(args.Target, "VayneSilveredDebuff") == 2 then
                local level = args.From:GetSpellData(_W).level
                args.CalculatedTrue = args.CalculatedTrue + MathMax((0.045 + 0.015 * level) * args.Target.maxHealth, 20 + 20 * level);
            end
        end,
        ["Zed"] = function(args)
            if 100 * args.Target.health / args.Target.maxHealth <= 50 and not self:HasBuff(args.From, "zedpassivecd") then
                args.RawMagical = args.RawMagical + args.Target.maxHealth * (4 + 2 * MathCeil(args.From.levelData.lvl / 6)) * 0.01;
            end
        end
    }

    self.StaticItemDamageDatabase         =
    {
        [1043] = function(args)
            args.RawPhysical = args.RawPhysical + 15;
        end,
        [2015] = function(args)
            if self:GetBuffCount(args.From, "itemstatikshankcharge") == 100 then
                args.RawMagical = args.RawMagical + 40;
            end
        end,
        [3057] = function(args)
            if self:HasBuff(args.From, "sheen") then
                args.RawPhysical = args.RawPhysical + 1 * args.From.baseDamage;
            end
        end,
        [3078] = function(args)
            if self:HasBuff(args.From, "sheen") then
                args.RawPhysical = args.RawPhysical + 2 * args.From.baseDamage;
            end
        end,
        [3085] = function(args)
            args.RawPhysical = args.RawPhysical + 15;
        end,
        [3087] = function(args)
            if self:GetBuffCount(args.From, "itemstatikshankcharge") == 100 then
                local t = { 50, 50, 50, 50, 50, 56, 61, 67, 72, 77, 83, 88, 94, 99, 104, 110, 115, 120 };
                args.RawMagical = args.RawMagical + (1 + (args.TargetIsMinion and 1.2 or 0)) * t[Damage:GetMaxLevel(args.From)];
            end
        end,
        [3091] = function(args)
            args.RawMagical = args.RawMagical + 40;
        end,
        [3094] = function(args)
            if self:GetBuffCount(args.From, "itemstatikshankcharge") == 100 then
                local t = { 50, 50, 50, 50, 50, 58, 66, 75, 83, 92, 100, 109, 117, 126, 134, 143, 151, 160 };
                args.RawMagical = args.RawMagical + t[Damage:GetMaxLevel(args.From)];
            end
        end,
        [3100] = function(args)
            if self:HasBuff(args.From, "lichbane") then
                args.RawMagical = args.RawMagical + 0.75 * args.From.baseDamage + 0.5 * args.From.ap;
            end
        end,
        [3115] = function(args)
            args.RawMagical = args.RawMagical + 15 + 0.15 * args.From.ap;
        end,
        [3124] = function(args)
            args.CalculatedMagical = args.CalculatedMagical + 15;
        end
    }

    self.VariableItemDamageDatabase       =
    {
        [1041] = function(args)
            if args.Target.team == self.TEAM_JUNGLE then
                args.CalculatedPhysical = args.CalculatedPhysical + 25;
            end
        end
    }

    self.AllowMovement                    =
    {
        ["Kaisa"] = function(unit)
            return self:HasBuff(unit, "KaisaE")
        end,
        ["Lucian"] = function(unit)
            return self:HasBuff(unit, "LucianR")
        end,
        ["Varus"] = function(unit)
            return self:HasBuff(unit, "VarusQ")
        end,
        ["Vi"] = function(unit)
            return self:HasBuff(unit, "ViQ")
        end,
        ["Vladimir"] = function(unit)
            return self:HasBuff(unit, "VladimirE")
        end,
        ["Xerath"] = function(unit)
            return self:HasBuff(unit, "XerathArcanopulseChargeUp")
        end
    }

    self.DisableAutoAttack                =
    {
        ["Urgot"] = function(unit)
            return self:HasBuff(unit, "UrgotW")
        end,
        ["Darius"] = function(unit)
            return self:HasBuff(unit, "dariusqcast")
        end,
        ["Graves"] = function(unit)
            if unit.hudAmmo == 0 then
                return true
            end
            return false
        end,
        ["Jhin"] = function(unit)
            if self:HasBuff(unit, "JhinPassiveReload") then
                return true
            end
            if unit.hudAmmo == 0 then
                return true
            end
            return false
        end
    }

    self.ItemSlots                        =
    {
        ITEM_1,
        ITEM_2,
        ITEM_3,
        ITEM_4,
        ITEM_5,
        ITEM_6,
        ITEM_7
    }

    self.AutoAttackResets                 =
    {
        ["Blitzcrank"] = { Slot = _E, toggle = true },
        ["Camille"] = { Slot = _Q },
        ["Chogath"] = { Slot = _E, toggle = true },
        ["Darius"] = { Slot = _W, toggle = true },
        ["DrMundo"] = { Slot = _E },
        ["Elise"] = { Slot = _W, Name = "EliseSpiderW"},
        ["Fiora"] = { Slot = _E },
        ["Garen"] = { Slot = _Q , toggle = true },
        ["Graves"] = { Slot = _E },
        ["Kassadin"] = { Slot = _W, toggle = true },
        ["Illaoi"] = { Slot = _W },
        ["Jax"] = { Slot = _W, toggle = true },
        ["Jayce"] = { Slot = _W, Name = "JayceHyperCharge"},
        ["Katarina"] = { Slot = _E },
        ["Kindred"] = { Slot = _Q },
        ["Leona"] = { Slot = _Q, toggle = true },
        ["Lucian"] = { Slot = _E },
        ["MasterYi"] = { Slot = _W },
        ["Mordekaiser"] = { Slot = _Q, toggle = true },
        ["Nautilus"] = { Slot = _W },
        ["Nidalee"] = { Slot = _Q, Name = "Takedown", toggle = true },
        ["Nasus"] = { Slot = _Q, toggle = true },
        ["RekSai"] = { Slot = _Q, Name = "RekSaiQ" },
        ["Renekton"] = { Slot = _W, toggle = true },
        ["Rengar"] = { Slot = _Q },
        ["Riven"] = { Slot = _Q },
        ["Sejuani"] = { Slot = _W },
        ["Sivir"] = { Slot = _W },
        ["Trundle"] = { Slot = _Q, toggle = true },
        ["Vayne"] = { Slot = _Q, toggle = true },
        ["Vi"] = { Slot = _E, toggle = true },
        ["Volibear"] = { Slot = _Q, toggle = true },
        ["MonkeyKing"] = { Slot = _Q, toggle = true },
        ["XinZhao"] = { Slot = _Q, toggle = true },
        ["Yorick"] = { Slot = _Q, toggle = true }
    }

    self.UNDYING_BUFFS                    =
    {
        ["zhonyasringshield"]           = 100,
        ["JudicatorIntervention"]       = 100,
        ["TaricR"]                      = 100,
        ["kindredrnodeathbuff"]         = 15,
        ["ChronoShift"]                 = 15,
        ["chronorevive"]                = 15,
        ["UndyingRage"]                 = 15,
        ["FioraW"]                      = 100,
        ["aatroxpassivedeath"]          = 100,
        ["VladimirSanguinePool"]        = 100,
        ["KogMawIcathianSurprise"]      = 100,
        ["KarthusDeathDefiedBuff"]      = 100
    }

    self.STUN_BUFFS                       =
    {
        -- General
            --["Disarm"] (Lulu W)                      = true, -- no attack and move (good for orb): AmumuR
            --["Flee"] (noc e, fiddle q -> target is moving, if has high ms then very fast + can be without slow)
            ["Charm"]                       = true, --AhriE, EvelynnE
            ["Stun"]                        = true, --AlistarE, AmumuQ, MorganaR, AniviaQ, AnnieP, AsheR, BrandP
            ["SummonerTeleport"]            = true,
            ["Taunt"]                       = true, --RammusE, ShenE
            ["recall"]                      = true,
        -- Aatrox
            ["aatroxqknockback"]            = true,
        -- Ahri
            ["AhriSeduce"]                  = true, --E
        -- Alistar
            ["Pulverize"]                   = true, --Q
        -- Amumu
            ["CurseoftheSadMummy"]          = true, --R
        -- Annie
            ["anniepassivestun"]            = true, --P
        -- Aurelion Sol
            ["aurelionsolqstun"]            = true, --Q
        -- Bard
            ["BardQShackleDebuff"]          = true, --Q
        -- Braum
            ["braumstundebuff"]             = true, --P
            ["braumpulselineknockup"]       = true, --R
        -- Blitzcrank
            ["powerfistslow"]               = true, --E
        -- Caitlyn
            ["caitlynyordletrapdebuff"]     = true, --W
        -- Cassiopeia
            ["CassiopeiaRStun"]             = true, --R
        -- Cho'Gath
            ["rupturelaunch"]               = true, --Q
        -- Ekko
            ["ekkowstun"]                   = true, --W
        -- Fiddlesticks
            ["fearmonger_marker"]           = true, --W
        -- Fiora
            ["fiorawstun"]                  = true, --W
        -- Gnar
            ["gnarstun"]                    = true, --R
        -- Irelia
            ["ireliawdefense"]              = true, --W
        -- Janna
            ["HowlingGaleSpell"]            = true, --Q
            ["ReapTheWhirlwind"]            = true, --R
        -- JarvanIV
            ["jarvanivdragonstrikeph2"]     = true, --QE
        -- Jinx
            ["JinxEMineSnare"]              = true, --E
        -- Karma
            ["karmaspiritbindroot"]         = true, --W
        -- Katarina
            ["katarinarsound"]              = true, --R
        -- Leblanc
            ["leblanceroot"]                = true, --E
            ["leblancreroot"]               = true, --RE
        -- Leona
            ["leonazenithbladeroot"]        = true, --E
        -- Lux
            ["LuxLightBindingMis"]          = true, --Q
        -- Malphite
            ["UnstoppableForceStun"]        = true, --R
        -- Malzahar
            ["MalzaharR"]                   = true, --R
        -- Master Yi
            ["Meditate"]                    = true, --W
        -- Miss Fortune
            ["missfortunebulletsound"]      = true, --R
        -- Morgana
            ["DarkBindingMissile"]          = true, --Q
        -- Ornn
            ["ornnrknockup"]                = true, --R
        -- Pantheon
            ["pantheonesound"]              = true, --E
            ["PantheonRJump"]               = true, --R
        -- Pyke
            ["PykeEMissile"]                = true, --E
        -- Rengar
            ["RengarEEmp"]                  = true, --RE
        -- Ryze
            ["RyzeW"]                       = true, --W
        -- Shen
            ["shenrchannelbuffbar"]         = true, --R
        -- Sion
            ["SionQ"]                       = true, --Q
            ["sionqknockup"]                = true, --Q
            ["sionrsoundexplosion"]         = true, --R
        -- Skarner
            ["skarnerpassivestun"]          = true, --PE
        -- Swain
            ["swaineroot"]                  = true, --E
        -- Tahm Kench
            ["tahmkenchqstun"]              = true, --Q
            ["TahmKenchNewR"]               = true, --R
            ["tahmkenchrcasting"]           = true, --R
        -- Taric
            ["taricestun"]                  = true, --E
        -- Twisted Fate
            ["Gate"]                        = true, --R
        -- Varus
            ["varusrroot"]                  = true, --R
        -- Veigar
            ["veigareventhorizonstun"]      = true, --E
        -- Viktor
            ["viktorgravitonfieldstun"]     = true, --W
            ["viktorwaugstun"]              = true, --W
        -- Warwick
            ["warwickrsound"]               = true, --R
            ["suppression"]                 = true, --R
        -- XinZhao
            ["XinZhaoQKnockup"]             = true, --Q
        -- Yasuo
            ["yasuorknockup"]               = true, --R
        -- Zilean
            ["ZileanStunAnim"]              = true, --Q

    }

    self.SLOW_BUFFS                       =
    {-- ??? shacoboxslow, fleeslow, nocturefleeslow
        -- General
            ["chilled"]                     = true, --AniviaQ, AniviaR
            ["slow"]                        = true, --Brand?, CaitlynE, itemomenranduin, itemslusznachwala
            ["grounded"]                    = true, --CassiopeiaW, SingedW
            ["itemslow"]                    = true, --itemrylai, itemlodowymlot, itemlodowarekawica, itemkonwzeke
            ["summonerexhaustslow"]         = true, --exhaust
            ["fleeslow"]                    = true, --FiddlesticksQ, WarwickE
        -- Items
            ["rylaivisualslow"]             = true, --rylai
            ["HextechGunbladeDebuff"]       = true, --hextechgunblade
            ["ItemSwordOfFeastAndFamine"]   = true, --botrk
            ["bilgewatercutlassdebuff"]     = true, --smallbotrk
            ["itemwillboltspellmissileslow"]= true, --glp800
            ["itemwraithcollarslow"]        = true, --blizniaczecienie
        -- Aatrox
            ["aatroxwslow"]                 = true, --W
        -- Anivia
            ["aniviaiced"]                  = true, --Q, R
        -- Ashe
            ["ashepassiveslow"]             = true, --P
        -- Aurelion Sol
            ["aurelionsolrslow"]            = true, --R
        -- Azir
            ["azirqslow"]                   = true, --Q
        -- Braum
            ["braumqslow"]                  = true, --Q
            ["braumpulselineslow"]          = true, --R
        -- Caitlyn
            ["CaitlynEntrapmentMissile"]    = true, --E
        -- Cassiopeia
            ["CassiopeiaWSlow"]             = true, --W
        -- Cho'Gath
            ["rupturetarget"]               = true, --Q
            ["vorpalspikesdebuff"]          = true, --E
        -- Darius
            ["DariusNoxianTacticsSlow"]     = true, --W
            ["dariuseslow"]                 = true, --E
        -- Diana
            ["dianaarcslow"]                = true, --E
        -- Dr'Mundo
            ["InfectedCleaverMissile"]      = true, --Q
        -- Ekko
            ["ekkoslow"]                    = true, --Q
        -- Evelynn
            ["evelynnwcharmslow"]           = true, --E
        -- Fiora
            ["fiorawslow"]                  = true, --W
        -- Fizz
            ["fizzeslow"]                   = true, --E
            ["fizzrslow"]                   = true, --R
        -- Galio
            ["GalioW"]                      = true, --W
            ["galiowslow"]                  = true, --W
        -- Gangplank
            ["gangplankeslow"]              = true, --E
            ["gangplankrslow"]              = true, --R
        -- Gnar
            ["gnarqslow"]                   = true, --Q
        -- Graves
            ["gravessmokegrenadeboomslow"]  = true, --W
        -- Heimerdinger
            ["heimerdingerultturretslow"]   = true, --RQ
            ["HeimerdingerESpell"]          = true, --E
            ["HeimerdingerESpell_ult"]      = true, --RE
        -- Ilioi
            ["illaoitentacleslow"]          = true, --E
        -- Irelia
            ["ireliarslow"]                 = true, --R
        -- Jayce
            ["jayceslow"]                   = true, --Q2
        -- Jinx
            ["jinxwsight"]                  = true, --W
        -- Karma
            ["KarmaQMissileSlow"]           = true, --Q
            ["KarmaQMissileMantraSlow"]     = true, --RQ
        -- Kayle
            ["JudicatorReckoning"]          = true, --Q
        -- Kha'Zix
            ["khazixpslow"]                 = true, --P
            ["khazixwisolatedslow"]         = true, --W
        -- Leona
            ["leonasolarflareslow"]         = true, --R
        -- Lulu
            ["luluqslow"]                   = true, --Q
            ["LuluWTwo"]                    = true, --W
            ["lulurslow"]                   = true, --R
        -- Malphite
            ["seismicshardbuff"]            = true, --Q
        -- Miss Fortune
            ["missfortunescattershotslow"]  = true, --E
        -- Nasus
            ["NasusW"]                      = true, --W
        -- Nocturne
            ["nocturefleeslow"]             = true, --E
        -- Nunu
            ["nunurslow"]                   = true, --R
        -- Olaf
            ["olafslow"]                    = true, --Q
        -- Orianna
            ["orianaslow"]                  = true, --W
        -- Poppy
            ["poppyqslow"]                  = true, --Q
        -- Pyke
            ["PykeQ"]                       = true, --Q
        -- Rammus
            ["powerballslow"]               = true, --Q
            ["DefensiveBallCurl"]           = true, --W
            ["tremorsslow"]                 = true, --R
        -- Rengar
            ["RengarE"]                     = true, --E
        -- Rumble
            ["rumblegrenadeslow"]           = true, --E
            ["rumblecarpetbombslow"]        = true, --R
        -- Shaco
            ["shacoboxslow"]                = true, --W
        -- Shen
            ["shenqslow"]                   = true, --Q
        -- Sion
            ["sionqslow"]                   = true, --Q
            ["sioneslow"]                   = true, --E
            ["sionrslow"]                   = true, --R
        -- Skarner
            ["skarnerfractureslow"]         = true, --E
        -- Soraka
            ["SorakaQ"]                     = true, --Q
        -- Tahm Kench
            ["tahmkenchqslow"]              = true, --Q
        -- Talon
            ["talonwslow"]                  = true, --W
        -- Teemo
            ["bantamtrapslow"]              = true, --R
        -- Trundle
            ["trundleqslow"]                = true, --Q
            ["trundlecircleslow"]           = true, --E
        -- Tryndamere
            ["tryndamerewslow"]             = true, --W
        -- Twisted Fate
            ["cardmasterslow"]              = true, --W
        -- Twitch
            ["TwitchVenomCaskDebuff"]       = true, --W
        -- Urgot
            ["UrgotW"]                      = true, --W
            ["urgotrslow"]                  = true, --R
        -- Varus
            ["VarusQLaunch"]                = true, --Q
            ["varuseslow"]                  = true, --E
        -- Viktor
            ["viktorgravitonfielddebuffslow"] = true, --W
        -- Vladimir
            ["vladimirsanguinepoolslow"]    = true, --W
            ["vladimireslow"]               = true, --E
        -- Zilean
            ["timewarpslow"]                = true, --E
    }

    self.DASH_BUFFS                       =
    {
        -- Aatrox
            ["aatroxwbump"]                 = true, --W
        -- Alistar
            ["headbutttarget"]              = true, --W
        -- Aurelion Sol
            ["aurelionsolrknockback"]       = true, --R
        -- Azir
            ["azirrbump"]                   = true, --R
        -- Bard
            ["bardedoormovement"]           = true, --EDash
        -- Blitzcrank
            ["rocketgrab2"]                 = true, --Q
        -- Braum
            ["braumwdash"]                  = true, --W
        -- Corki
            ["corkibombmoveaway"]           = true, --PW
        -- Darius
            ["DariusAxeGrabCone"]           = true, --E
        -- Diana
            ["dianavortexstun"]             = true, --E
        -- Ekko
            ["ekkorinvuln"]                 = true, --R
        -- Fiora
            ["FioraQ"]                      = true, --Q
            ["FioraW"]                      = true, --W
        -- Fizz
            ["fizzeicon"]                   = true, --E
            ["fizzrknockup"]                = true, --R
        -- Galio
            ["galioemove"]                  = true, --E
            ["galioknockup"]                = true, --E, R
        -- Gnar
            -- not working correctly in gos ext ["GnarE"]                       = true, --E
            ["GnarBigE"]                    = true, --RE
            ["gnarrknockback"]              = true, --R
        -- Gragas
            ["gragasestun"]                 = true, --E
            ["gragasrmoveaway"]             = true, --R
        -- Hecarim
            ["hecarimrampstuncheck"]        = true, --E
            ["hecarimrampattackknockback"]  = true, --E
            ["HecarimUltMissileGrab"]       = true, --R
        -- Janna
            ["jannamoveaway"]               = true, --R
        -- Jayce
            ["jayceknockedbuff"]            = true, --E2
        -- LeeSin
            ["blindmonkrroot"]              = true, --R
            ["BlindMonkRKick"]              = true, --R
        -- Lulu
            ["lulurboom"]                   = true, --R
        -- Nocturne
            ["nocturneparanoiadash"]        = true, --R
        -- Nunu
            ["nunuwstun"]                   = true, --W
        -- Orianna
            ["orianastun"]                  = true, --R
        -- Ornn
            ["globalwallpush"]              = true, --Q
            ["ornneknockup"]                = true, --E
        -- Poppy
            ["poppyepushenemy"]             = true, --E
            ["poppyrknockup"]               = true, --R
        -- Pyke
            ["PykeQRange"]                  = true, --Q
            ["PykeW"]                       = true, --W
        -- Rammus
            ["powerballstun"]               = true, --Q
        -- Riven
            ["rivenknockback"]              = true, --Q
        -- Shen
            ["shenedash"]                   = true, --E
        -- Shyvana
            ["ShyvanaTransformLeap"]        = true, --R
        -- Singed
            ["Fling"]                       = true, --E
        -- Sion
            ["sionrtarget"]                 = true, --R
        -- Sivir
            ["SivirE"]                      = true, --E
        -- Skarner
            ["skarnerimpaleflashlock"]      = true, --R
            ["SkarnerImpale"]               = true, --R
        -- Tahm Kench
            ["tahmkenchwpredevour"]         = true, --W
            ["tahmkenchwdevoured"]          = true, --W
        -- Talon
            ["TalonEHop"]                   = true, --E
        -- Tristana
            ["TristanaR"]                   = true, --R
        -- Trundle
            ["trundlewallbounce"]           = true, --E
        -- Urgot
            ["urgotetoss"]                  = true, --E
        -- Vayne
            ["VayneCondemnMissile"]         = true, --E
        -- Warwick
            ["WarwickQ"]                    = true, --Q
        -- Wukong
            ["MonkeyKingNimbusKick"]        = true, --E
            ["monkeykingspinknockup"]       = true, --R
        -- XinZhao
            ["xinzhaorknockback"]           = true, --R
        -- Yasuo
            ["YasuoQ3Mis"]                  = true, --Q
        -- Yorick
            ["globalwallpush"]              = true, --W
    }

    self.STUN_SPELLS                      =
    {-- -1 = activeSpell.windup
        -- Items
            ["ItemWillBoltSpellBase"]       = 0.25, --glp800
            ["ItemTiamatCleave"]            = 0.25, --Hydra, Tiamat
        -- Aatrox
            ["AatroxQWrapperCast"]          = 0.6, --Q
        -- Ahri
            ["AhriOrbofDeception"]          = 0.25, --Q
            ["AhriSeduce"]                  = 0.25, --E
        -- Akali
            ["AkaliQ"]                      = 0.25, --Q
        -- Alistar
            ["Pulverize"]                   = 0.25, --Q
            ["FeroCiousHowl"]               = 0.25, --R
        -- Amumu
            ["Tantrum"]                     = 0.25, --E
            ["CurseoftheSadMummy"]          = 0.25, --R
        -- Anivia
            ["FlashFrostSpell"]             = 0.25, --Q
            ["Crystallize"]                 = 0.25, --W
            ["Frostbite"]                   = 0.25, --E
        -- Annie
            ["AnnieQ"]                      = 0.25, --Q
            ["AnnieW"]                      = 0.25, --W
            ["AnnieR"]                      = 0.25, --R
        -- Ashe
            ["Volley"]                      = 0.25, --W
            ["AsheSpiritOfTheHawk"]         = 0.25, --E
            ["EnchantedCrystalArrow"]       = 0.25, --R
        -- Aurelion Sol
            ["AurelionSolR"]                = 0.35, --R
        -- Azir
            ["AzirQ"]                       = 0.25, --Q
            ["AzirWSpawnSoldier"]           = 0.25, --W
            ["AzirR"]                       = 0.5, --R
        -- Bard
            ["BardQ"]                       = 0.25, --Q
            ["BardWHealthPack"]             = 0.25, --W
            ["BardE"]                       = 0.25, --E
            ["BardR"]                       = 0.5, --R
        -- Blitzcrank
            ["RocketGrab"]                  = 0.25, --Q
            ["PowerFistAttack"]             = -1, --E
            ["StaticField"]                 = 0.25, --R
        -- Brand
            ["BrandQ"]                      = 0.25, --Q
            ["BrandW"]                      = 0.25, --W
            ["BrandE"]                      = 0.25, --E
            ["BrandR"]                      = 0.25, --R
        -- Braum
            ["BraumQ"]                      = 0.25, --Q
            ["BraumRWrapper"]               = 0.5, --R
        -- Caitlyn
            ["CaitlynPiltoverPeacemaker"]   = 0.625, --Q
            ["CaitlynYordleTrap"]           = 0.25, --W
            ["CaitlynAceintheHole"]         = 1.375, --R
        -- Cassiopeia
            ["CassiopeiaQ"]                 = 0.25, --Q
            ["CassiopeiaW"]                 = 0.25, --W
            ["CassiopeiaE"]                 = 0.125, --E
            ["CassiopeiaR"]                 = 0.5, --R
        -- Cho'Gath
            ["Rupture"]                     = 0.5, --Q
            ["FeralScream"]                 = 0.5, --W
            ["Feast"]                       = 0.25, --R
        -- Corki
            ["PhosphorusBomb"]              = 0.25, --Q
            ["MissileBarrageMissile"]       = 0.175, --R
        -- Darius
            ["DariusAxeGrabCone"]           = 0.25, --E
        -- Diana
            ["DianaArc"]                    = 0.25, --Q
            ["DianaVortex"]                 = 0.25, --E
        -- Dr'Mundo
            ["InfectedCleaverMissile"]      = 0.25, --Q
        -- Ekko
            ["EkkoQ"]                       = 0.25, --Q
            ["EkkoW"]                       = 0.25, --W
        -- Evelynn
            ["EvelynnQ"]                    = 0.25, --Q
            ["EvelynnW"]                    = 0.15, --W
            ["EvelynnE"]                    = 0.15, --E
        -- Ezreal
            ["EzrealMysticShot"]            = 0.25, --Q
            ["EzrealEssenceFlux"]           = 0.25, --W
            ["EzrealTrueshotBarrage"]       = 1, --R
        -- FiddleSicks
            ["Terrify"]                     = 0.25, --Q
            ["DrainChannel"]                = 0.25, --W
            ["FiddlesticksDarkWind"]        = 0.25, --E
            ["Crowstorm"]                   = 1.5, --R
        -- Fizz
            ["FizzR"]                       = 0.25, --R
        -- Galio
            ["GalioQ"]                      = 0.25, --Q
            ["GalioR"]                      = 1, --R
        -- Gangplank
            ["GangplankQProceed"]           = 0.25, --Q
            ["GangplankW"]                  = 0.25, --W
            ["GangplankE"]                  = 0.25, --E
            ["GangplankR"]                  = 0.25, --R
        -- Garen
            ["GarenR"]                      = 0.45, --R
        -- Gnar
            ["GnarQMissile"]                = 0.25, --Q
            ["GnarBigQMissile"]             = 0.5, --RQ
            ["GnarBigW"]                    = 0.6, --RW
            ["GnarR"]                       = 0.25, --R
        -- Gragas
            ["GragasQ"]                     = 0.25, --Q
            ["GragasR"]                     = 0.25, --R
        -- Graves
            ["GravesQLineSpell"]            = 0.25, --Q
            ["GravesSmokeGrenade"]          = 0.25, --W
        -- Heimerdinger
            ["HeimerdingerQ"]               = 0.25, --Q
            ["HeimerdingerW"]               = 0.25, --W
            ["HeimerdingerE"]               = 0.25, --E
            ["HeimerdingerEUlt"]            = 0.25, --RE
        -- Ilioi
            ["IllaoiQ"]                     = 0.75, --Q
            ["IllaoiE"]                     = 0.25, --E
            ["IllaoiR"]                     = 0.5, --R
        -- Irelia
            ["IreliaR"]                     = 0.4, --R
        -- Janna
            ["SowTheWind"]                  = 0.25, --W
        -- Jayce
            ["JayceShockBlast"]             = 0.2, --Q1
            ["JayceThunderingBlow"]         = 0.25, --Q2
        -- Jinx
            ["JinxWMissile"]                = 0.6, --W
            ["JinxR"]                       = 0.6, --R
        -- Kaisa
            ["KaisaW"]                      = 0.4, --W
        -- Karma
            ["KarmaQ"]                      = 0.25, --Q
            ["KarmaSpiritBind"]             = 0.25, --W
        -- Karthus
            ["KarthusLayWasteA1"]           = 0.25, --Q
            ["KarthusWallOfPain"]           = 0.25, --W
            ["KarthusFallenOne"]            = 3, --R
        -- Kassadin
            ["NullLance"]                   = 0.25, --Q
            ["ForcePulse"]                  = 0.25, --E
        -- Katarina
            ["KatarinaQ"]                   = 0.25, --Q
            ["KatarinaR"]                   = 0.5, --R
        -- Kayle
            ["JudicatorReckoning"]          = 0.25, --Q
        -- Kennen
            ["KennenShurikenHurlMissile1"]  = 0.175, --Q
            ["KennenBringTheLight"]         = 0.25, --W
            ["KennenShurikenStorm"]         = 0.25, --R
        -- Kha'Zix
            ["KhazixQ"]                     = 0.25, --Q
            ["KhazixQLong"]                 = 0.25, --RQ
            ["KhazixW"]                     = 0.25, --W
            ["KhazixWLong"]                 = 0.25, --RW
        -- Leblanc
            ["LeblancQ"]                    = 0,25, --Q
            ["LeblancRQ"]                   = 0.25, --RQ
            ["LeblancE"]                    = 0.25, --E
            ["LeblancRE"]                   = 0.25, --RE
        -- LeeSin
            ["BlindMonkQOne"]               = 0.25, --Q
            ["BlindMonkEOne"]               = 0.25, --E
            ["BlindMonkRKick"]              = 0.25, --R
        -- Leona
            ["LeonaSolarFlare"]             = 0.25, --R
        -- Lucian
            ["LucianQ"]                     = 0.35, --Q
            ["LucianW"]                     = 0.25, --W
        -- Lulu
            ["LuluQ"]                       = 0.25, --Q
            ["LuluWTwo"]                    = 0.25, --W
        -- Lux
            ["LuxLightBinding"]             = 0.25, --Q
            ["LuxPrismaticWave"]            = 0.25, --W
            ["LuxLightStrikeKugel"]         = 0.25, --E
            ["LuxMaliceCannonMis"]          = 1, --R
        -- Malphite
            ["SeismicShard"]                = 0.25, --Q
            ["Landslide"]                   = 0.25, --E
        -- Malzahar
            ["MalzaharQ"]                   = 0.25, --Q
            ["MalzaharE"]                   = 0.25, --E
        -- Miss Fortune
            ["MissFortuneRicochetShot"]     = 0.25, --Q
            ["MissFortuneScattershot"]      = 0.25, --E
        -- Mordekaiser
            ["MordekaiserSyphonOfDestruction"]  = 0.25, --E
            ["MordekaiserChildrenOfTheGrave"]   = 0.25, --R
        -- Morgana
            ["DarkBindingMissile"]              = 0.25, --Q
            ["TormentedSoil"]                   = 0.25, --W
            ["SoulShackles"]                    = 0.35, --R
        -- Nasus
            ["NasusW"]                          = 0.25, --W
            ["NasusE"]                          = 0.25, --E
            ["NasusR"]                          = 0.25, --R
        -- Nidalee
            ["JavelinToss"]                     = 0.25, --Q
            ["Bushwhack"]                       = 0.25, --W
            ["PrimalSurge"]                     = 0.25, --E
            ["Swipe"]                           = 0.25, --RE
        -- Nocturne
            ["NocturneDuskbringer"]             = 0.25, --E
        -- Nunu
            ["NunuQ"]                           = 0.3, --Q
            ["NunuR"]                           = 1.5, --R
        -- Olaf
            ["OlafAxeThrowCast"]                = 0.25, --Q
            ["OlafRecklessStrike"]              = 0.25, --E
        -- Orianna
            ["OrianaDetonateCommand"]           = 0.5, --R
        -- Ornn
            ["OrnnQ"]                           = 0.3, --Q
            ["OrnnR"]                           = 0.5, --R
        -- Pantheon
            ["PantheonQ"]                       = 0.25, --Q
            ["PantheonE"]                       = 0.35, --E
        -- Poppy
            ["PoppyQSpell"]                     = 0.35, --Q
            ["PoppyRSpell"]                     = 0.35, --R
        -- Pyke
            ["PykeQMelee"]                      = 0.25, --Q
        -- Rammus
            ["PuncturingTaunt"]                 = 0.25, --E
        -- Renekton
            ["RenektonExecute"]                 = 0.35, --W
            ["RenektonReignOfTheTyrant"]        = 0.25, --R
        -- Rengar
            ["RengarE"]                         = 0.25, --E
            ["RengarEEmp"]                      = 0.25, --RE
        -- Riven
            ["RivenMartyr"]                     = 0.3, --W
            ["RivenFengShuiEngine"]             = 0.25, --R
            ["RivenIzunaBlade"]                 = 0.25, --R
        -- Rumble
            ["RumbleGrenade"]                   = 0.25, --E
            ["RumbleCarpetBombDummy"]           = 0.55, --R
        -- Ryze
            ["RyzeQ"]                           = 0.25, --Q
            ["RyzeW"]                           = 0.25, --W
            ["RyzeE"]                           = 0.25, --E
        -- Shaco
            ["JackInTheBox"]                    = 0.25, --W
            ["TwoShivPoison"]                   = 0.25, --E
        -- Shen
            ["ShenR"]                           = 0.25, --R
        -- Shyvana
            ["ShyvanaFireball"]                 = 0.25, --E
            ["ShyvanaFireballDragon2"]          = 0.35, --RE
        -- Singed
            ["MegaAdhesive"]                    = 0.25, --W
            ["Fling"]                           = 0.25, --E
        -- Sion
            ["SionE"]                           = 0.25, --E
        -- Sivir
            ["SivirQ"]                          = 0.25, --Q
        -- Skarner
            ["SkarnerFractureMissile"]          = 0.25, --E
            ["SkarnerImpale"]                   = 0.25, --R
        -- Soraka
            ["SorakaQ"]                         = 0.25, --Q
            ["SorakaW"]                         = 0.25, --W
            ["SorakaE"]                         = 0.25, --E
            ["SorakaR"]                         = 0.25, --R
        -- Swain
            ["SwainQ"]                          = 0.25, --Q
            ["SwainW"]                          = 0.25, --W
            ["SwainE"]                          = 0.25, --E
        -- Tahm Kench
            ["TahmKenchQ"]                      = 0.25, --Q
            ["TahmKenchW"]                      = 0.35, --W
            ["TahmKenchWCastTimeAndAnimation"]  = 0.25, --W
            ["TahmKenchE"]                      = 0.25, --E
            ["TahmKenchNewR"]                   = 0.25, --R
        -- Talon
            ["TalonQAttack"]                    = 0.25, --Q
            ["TalonW"]                          = 0.25, --W
        -- Taric 
            ["TaricQ"]                          = 0.25, --Q
            ["TaricW"]                          = 0.25, --W
            ["TaricR"]                          = 0.25, --R
        -- Teemo
            ["BlindingDart"]                    = 0.25, --Q
            ["TeemoRCast"]                      = 0.25, --R
        -- Tristana
            ["TristanaE"]                       = -1, --E
            ["TristanaR"]                       = 0.25, --R
        -- Trundle
            ["TrundleQ"]                        = -1, --Q
            ["TrundleCircle"]                   = 0.25, --E
            ["TrundlePain"]                     = 0.25, --R
        -- Tryndamere
            ["TryndamereW"]                     = 0.25, --W
        -- Twisted Fate
            ["WildCards"]                       = 0.25, --Q
            ["GoldCardPreAttack"]               = 0.125, --W
            ["RedCardPreAttack"]                = 0.125, --W
            ["BlueCardPreAttack"]               = 0.125, --W
        -- Twitch
            ["TwitchVenomCask"]                 = 0.25, --W
            ["TwitchExpunge"]                   = 0.25, --E
        -- Urgot
            ["UrgotQ"]                          = 0.25, --Q
            ["UrgotE"]                          = 0.45, --E
            ["UrgotR"]                          = 0.4, --R
        -- Varus
            ["VarusE"]                          = 0.25, --E
            ["VarusR"]                          = 0.25, --R
        -- Vayne
            ["VayneCondemn"]                    = 0.25, --E
        -- Veigar
            ["VeigarBalefulStrike"]             = 0.25, --Q
            ["VeigarDarkMatterCastLockout"]     = 0.25, --W
            ["VeigarEventHorizon"]              = 0.25, --E
            ["VeigarR"]                         = 0.25, --R
        -- Viktor
            ["ViktorPowerTransfer"]             = 0.25, --Q
            ["ViktorGravitonField"]             = 0.25, --W
            ["ViktorChaosStorm"]                = 0.25, --R
        -- Vladimir
            ["VladimirQ"]                       = 0.25, --Q
        -- Warwick
            ["WarwickW"]                        = 0.5, --W
        -- XinZhao
            ["XinZhaoW"]                        = 0.5, --W
            ["XinZhaoR"]                        = 0.3, --R
        -- Yasuo
            ["YasuoQ1"]                         = 0.3, --Q
            ["YasuoQ2"]                         = 0.3, --Q
            ["YasuoQ3"]                         = 0.3, --Q
        -- Yorick
            ["YorickE"]                         = 0.33, --E
            ["YorickR"]                         = 0.5, --R
        -- Zilean
            ["ZileanQ"]                         = 0.25, --Q
    }

    self.DASH_SPELLS                      =
    {
        -- Aatrox
            ["AatroxR"]                     = 0.5, --R
        -- Ekko
            ["EkkoR"]                       = 0.5, --R
        -- Evelynn
            ["EvelynnE2"]                   = 0.15, --E
            ["EvelynnR"]                    = 0.5, --R
        -- Ezreal
            ["EzrealArcaneShift"]           = 0.3, --E
        -- Galio
            ["GalioE"]                      = 0.5, --E
        -- Gragas
            ["GragasE"]                     = 0.5, --E
        -- Graves
            ["GravesChargeShot"]            = 0.5, --R
        -- Ilioi
            ["IllaoiWAttack"]               = 0.35, --W
        -- JarvanIV
            ["JarvanIVDragonStrike"]        = 0.4, --Q
        -- Kassadin
            ["RiftWalk"]                    = 0.35, --R
        -- Katarina
            ["KatarinaE"]                   = 0.25, --E
        -- Leona
            ["LeonaZenithBlade"]            = 0.5, --E
        -- Master Yi
            ["AlphaStrike"]                 = 0.2, --Q
        -- Ornn
            ["OrnnE"]                       = 0.35, --E
        -- Pyke
            ["PykeE"]                       = 0.35, --E
            ["PykeR"]                       = 0.5, --R
        -- Shaco
            ["HallucinateFull"]             = 0.25, --R
        -- Shyvana
            ["ShyvanaTransformLeap"]        = 0.5, --R
        -- Tristana
            ["TristanaW"]                   = 0.5, --W
        -- Warwick
            ["WarwickR"]                    = 0.2, --R
    }

    self.ATTACK_SPELLS                    =
    {
        ["CaitlynHeadshotMissile"] = true,
        ["GarenQAttack"] = true,
        ["KennenMegaProc"] = true,
        ["MordekaiserQAttack"] = true,
        ["MordekaiserQAttack1"] = true,
        ["MordekaiserQAttack2"] = true,
        ["QuinnWEnhanced"] = true,
        ["BlueCardPreAttack"] = true,
        ["RedCardPreAttack"] = true,
        ["GoldCardPreAttack"] = true,
        ["XenZhaoThrust"] = true,
        ["XenZhaoThrust2"] = true,
        ["XenZhaoThrust3"] = true
    }
        -- 1. Camille (before Cassiopeia)
        -- 2. Draven (before Ekko)
        -- 3. Elise (before Evelynn)
        -- 4. Ivern (before Janna)
        -- 5. Jhin (before Jinx)
        -- 6. Kalista (before Karma)
    -- 17. Kayn (before Kennen)
        -- 18. Kindred (before Kled)
        -- 19. Kled (before Kog'Maw)
    -- 20. Kog'Maw (before Leblanc)
    -- 21. Lissandra (before Lucian)
    -- 22. Maokai (before Master Yi)
    -- 23. Nami (before Nasus)
    -- 24. Nautilus (before Nidalee)
    -- 25. Quinn (before Rakan)
    -- 26. Rakan (before Rammmus)
    -- 27. Rek'Sai (before Renekton)
    -- 28. Sejuani (before Shaco)
    -- 29. Sona (before Soraka)
    -- 30. Syndra (before Tahm Kench)
    -- 31. Taliyah (before Talon)
    -- 32. Thresh (before Tristana)
    -- 33. Vel'Koz (before Vi)
    -- 34. Vi (before Viktor)
    -- 35. Volibear (before Warwick)
        -- 36. Xayah (before Xerath)
    -- 37. Xerath (before Xin Zhao)
    -- 38. Zac (before Zed)
        -- 39. Zed (before Ziggs)
    -- 40. Ziggs (before Zilean)
    -- 41. Zoe (before Zyra)
    -- 42. Zyra
end

function __GamsteronCore:DownloadFile(url, path)
    DownloadFileAsync(url, path, function() end)
    while not FileExist(path) do end
end

function __GamsteronCore:Trim(s)
    local from = s:match"^%s*()"
    return from > #s and "" or s:match(".*%S", from)
end

function __GamsteronCore:ReadFile(path)
    local result = {}
    local file = io.open(path, "r")
    if file then
        for line in file:lines() do
            local str = Trim(line)
            if #str > 0 then
                table.insert(result, str)
            end
        end
        file:close()
    end
    return result
end

function __GamsteronCore:AutoUpdate(args)
    DownloadFile(args.versionUrl, args.versionPath)
    local fileResult = ReadFile(args.versionPath)
    local newVersion = tonumber(fileResult[1])
    if newVersion > args.version then
        DownloadFile(args.scriptUrl, args.scriptPath)
        return true, newVersion
    end
    return false, args.version
end

function __GamsteronCore:Class()
    local cls = {}
    cls.__index = cls
    return setmetatable(cls, {__call = function (c, ...)
        local instance = setmetatable({}, cls)
        if cls.__init then
            cls.__init(instance, ...)
        end
        return instance
    end})
end

function __GamsteronCore:GetPrediction(unit, args, from)
    args.Unit = unit
    args.From = from
    local input = self:PredictionInput(args)
    if not input.Valid then return self:PredictionOutput() end
    local unitID = input.UnitID
    local result = nil
    if unit.pathing.isDashing then
        result = self:GetDashingPrediction(input)
    end
    if result == nil then
        local data = input.UnitData
        if data.RemainingDash > 0 or GameTimer() <= data.ExpireDash then
            return self:PredictionOutput()
        end
        local remainingTime = MathMax(data.RemainingImmobile, data.ExpireImmobile - GameTimer())
        if remainingTime > 0 then
            result = self:GetImmobilePrediction(input, remainingTime)
        else
            input.Range = input.Range * MaxRangeMulipier
        end
    end
    if result == nil then
        result = self:GetStandardPrediction(input)
        if result.Hitchance ~= self.HITCHANCE_IMPOSSIBLE then
            local isOK = false
            local castPos = result.CastPosition
            local path = input.UnitData.Path
            for i = 1, #path - 1 do
                local v1, v2 = path[i], path[i+1]
                local isOnSegment, pointSegment, pointLine = self:ProjectOn(castPos, v1, v2)
                if self:IsInRange(pointSegment, castPos, 10) then
                    isOK = true
                    break
                end
            end
            if not isOK then
                result.Hitchance = self.HITCHANCE_IMPOSSIBLE
            end
        end
    end
    if result.Hitchance ~= self.HITCHANCE_IMPOSSIBLE then
        if input.Range ~= MathHuge then
            if result.Hitchance >= self.HITCHANCE_HIGH and not self:IsInRange(input.RangeCheckFrom, self:To2D(unit.pos), input.Range + input.RealRadius * 3 / 4) then
                result.Hitchance = self.HITCHANCE_NORMAL
            end
            if not self:IsInRange(input.RangeCheckFrom, result.UnitPosition, input.Range + (input.Type == self.SPELLTYPE_CIRCLE and input.RealRadius or 0)) then
                result.Hitchance = self.HITCHANCE_IMPOSSIBLE
            end
            if not self:IsInRange(input.RangeCheckFrom, result.CastPosition, input.Range) then
                if result.Hitchance > self.HITCHANCE_IMPOSSIBLE then
                    result.CastPosition = self:Extended(input.RangeCheckFrom, self:Normalized(result.UnitPosition, input.RangeCheckFrom), input.Range)
                else
                    result.Hitchance = self.HITCHANCE_IMPOSSIBLE
                end
            end
            
            if not self:IsInRange(result.CastPosition, self:To2D(myHero.pos), input.Range) then
                result.Hitchance = self.HITCHANCE_IMPOSSIBLE
            end
        end
    end
    if result.Hitchance ~= self.HITCHANCE_IMPOSSIBLE then
        if input.Collision then
            local isWall, objects = self:GetCollision(input.From, result.CastPosition, input.Speed, input.Delay, input.Radius, input.CollisionObjects, input.ObjectsList)
            if isWall or #objects > input.MaxCollision then
                result.Hitchance = self.HITCHANCE_COLLISION
            end
            result.CollisionObjects = objects
        end
    end
    return result
end

function __GamsteronCore:PredictionOutput(args)
    args = args or {}
    local result =
    {
        CastPosition           = args.CastPosition         or nil,
        UnitPosition           = args.UnitPosition         or nil,
        Hitchance              = args.Hitchance            or self.HITCHANCE_IMPOSSIBLE,
        Input                  = args.Input                or nil,
        CollisionObjects       = args.CollisionObjects     or {},
        AoeTargetsHit          = args.AoeTargetsHit        or {},
        AoeTargetsHitCount     = args.AoeTargetsHitCount   or 0
    }
    result.AoeTargetsHitCount = MathMax(result.AoeTargetsHitCount, #result.AoeTargetsHit)
    return result
end

function __GamsteronCore:PredictionInput(args)
    local result =
    {
        Aoe                = args.Aoe                  or false,
        Collision          = args.Collision            or false,
        Unit               = args.Unit                 or nil,
        From               = args.From                 or myHero,
        MaxCollision       = args.MaxCollision         or 0,
        CollisionObjects   = args.CollisionObjects     or { self.COLLISION_MINION, self.COLLISION_YASUOWALL },
        Delay              = args.Delay                or 0,
        Radius             = args.Radius               or 1,
        Range              = args.Range                or MathHuge,
        Speed              = args.Speed                or MathHuge,
        Type               = args.Type                 or self.SPELLTYPE_LINE
    }
    result.Valid = true
    if args.UseBoundingRadius or result.Type == self.SPELLTYPE_LINE then
        result.RealRadius = result.Radius + result.Unit.boundingRadius
    else
        result.RealRadius = result.Radius
    end
    result.RealRadius = result.RealRadius
    result.Delay = result.Delay + 0.06 + (LATENCY * 0.5)
    if result.From == nil or result.Unit == nil or not result.Unit.valid or result.Unit.dead or not result.Unit.isTargetable then
        result.Valid = false
        return result
    end
    result.UnitID = result.Unit.networkID
    if result.Collision then
        result.ObjectsList = {}
        for i = 1, #result.CollisionObjects do
            local CollisionType = result.CollisionObjects[i]
            if CollisionType == self.COLLISION_MINION then
                result.ObjectsList.enemyMinions = self:GetEnemyMinions(myHero, 2000)
            elseif CollisionType ==  self.COLLISION_ALLYHERO then
                result.ObjectsList.allyHeroes = self:GetAllyHeroes(myHero, 2000, result.UnitID)
            elseif CollisionType == self.COLLISION_ENEMYHERO then
                result.ObjectsList.enemyHeroes = self:GetEnemyHeroes(myHero, 2000, result.UnitID)
            end
        end
    end
    result.UnitData = self:GetHeroData(result.Unit)
    if GameTimer() < result.UnitData.RemainingImmortal - result.Delay + 0.1 then
        result.Valid = false
        return result
    end
    result.From = self:To2D(result.From.pos)
    if result.Range ~= MathHuge and not self:IsInRange(result.From, self:To2D(result.Unit.pos), result.Range * 1.5) then
        result.Valid = false
        return result
    end
    result.RangeCheckFrom = self:To2D(myHero.pos)
    return result
end

function __GamsteronCore:GetStandardPrediction(input)
    local unit = input.Unit
    local unitID = input.UnitID
    local unitPos = self:To2D(unit.pos)
    local unitPath = unit.pathing
    local speed = unit.ms
    if self:IsInRange(unitPos, input.From, 200) then
        speed = speed / 1.5
    end
    local data = input.UnitData
    local path = self:GetWaypoints(unit, unitID)
    local pathCount = #path
    local Radius = input.RealRadius
    if pathCount == 1 or not unitPath.hasMovePath or self:IsInRange(unitPos, self:To2D(unitPath.endPos), 25) then
        if unit.visible and GameTimer() > data.LastMoveTimer + 0.5 and pathCount == 1 and not unitPath.hasMovePath and self:IsInRange(unitPos, self:To2D(unitPath.endPos), 25) then
            if GameTimer() > data.StopMoveTimer + 3 and GameTimer() > data.LastMoveTimer + 3 then
                return self:PredictionOutput({ Input = input, Hitchance = self.HITCHANCE_HIGH, CastPosition = unitPos, UnitPosition = unitPos })
            end
            return self:PredictionOutput({ Input = input, Hitchance = self.HITCHANCE_NORMAL, CastPosition = unitPos, UnitPosition = unitPos })
        end
    elseif pathCount > 1 then
        local HitChance = self.HITCHANCE_NORMAL
        if GameTimer() < data.LastMoveTimer + HighAccuracy then HitChance = self.HITCHANCE_HIGH end
        if self:PathLength(path) < 200 then HitChance = self.HITCHANCE_NORMAL end
        if input.Speed == MathHuge then
            return self:PredictionOutput({
                Input = input,
                Hitchance = HitChance,
                CastPosition = self:CutPath(path, (input.Delay * speed) - Radius)[1],
                UnitPosition = self:CutPath(path, input.Delay * speed)[1]
            })
        end
        local a = path[1]
        local b = path[2]
        local delay = input.Delay + self:GetInterceptionTime(input.From, a, b, speed, input.Speed)
        local predDistance = speed * delay
        if self:GetDistance(a,b) >= predDistance - Radius then
            return self:PredictionOutput({
                Input = input,
                Hitchance = HitChance,
                CastPosition = self:CutPath(path, predDistance - Radius)[1],
                UnitPosition = self:CutPath(path, predDistance)[1]
            })
        end
    end
    return self:PredictionOutput()
end

function __GamsteronCore:GetDashingPrediction(input)
    local unit = input.Unit
    local path = self:GetWaypoints(unit, input.UnitID)
    if #path ~= 2 then
        return self:PredictionOutput()
    end
    local startPos = self:To2D(unit.pos)
    local endPos = path[2]
    if self:IsInRange(startPos, endPos, 25) then
        return self:PredictionOutput()
    end
    local speed = unit.pathing.dashSpeed
    local interceptTime = input.Delay + self:GetInterceptionTime(input.From, startPos, endPos, speed, input.Speed) - (input.RealRadius / unit.ms)
    local remainingTime = self:GetDistance(startPos, endPos) / speed
    if remainingTime + 0.1 >= interceptTime then
        local direction = self:Normalized(endPos, startPos)
        local castPos = self:Extended(startPos, direction, speed * interceptTime)
        if self:GetDistanceSquared(startPos, castPos) > self:GetDistanceSquared(startPos, endPos) then
            castPos = endPos
        end
        if remainingTime >= interceptTime then
            if DebugMode then print("IMMOBILE_DASH: speed " .. tostring(speed)) end
            return self:PredictionOutput({ Input = input, Hitchance = self.HITCHANCE_IMMOBILE, CastPosition = castPos, UnitPosition = castPos })
        end
        if DebugMode then print("HIGH_DASH: speed " .. tostring(speed)) end
        return self:PredictionOutput({ Input = input, Hitchance = self.HITCHANCE_HIGH, CastPosition = castPos, UnitPosition = castPos })
    end
    return self:PredictionOutput()
end

function __GamsteronCore:GetImmobilePrediction(input, remainingTime)
    local pos = self:To2D(input.Unit.pos)
    local interceptTime = input.Delay + (self:GetDistance(input.From, pos) / input.Speed) - (input.RealRadius / input.Unit.ms)
    if remainingTime + 0.1 >= interceptTime then
        if remainingTime >= interceptTime then
            if DebugMode then print("IMMOBILE_STUN") end
            return self:PredictionOutput({ Input = input, Hitchance = self.HITCHANCE_IMMOBILE, CastPosition = pos, UnitPosition = pos })
        end
        if DebugMode then print("HIGH_STUN") end
        return self:PredictionOutput({ Input = input, Hitchance = self.HITCHANCE_HIGH, CastPosition = pos, UnitPosition = pos })
    end
    return self:PredictionOutput()
end

function __GamsteronCore:CastSpell(spell, unit, from, spellData, hitChance)
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

function __GamsteronCore:Join(t1, t2, t3, t4, t5, t6)
	local t = {}
	local c = 1
	for i = 1, #t1 do
		t[c] = t1[i]
		c = c + 1
	end
	for i = 1, #t2 do
		t[c] = t2[i]
		c = c + 1
	end
	if t3 then
		for i = 1, #t3 do
			t[c] = t3[i]
			c = c + 1
		end
	end
	if t4 then
		for i = 1, #t4 do
			t[c] = t4[i]
			c = c + 1
		end
	end
	if t5 then
		for i = 1, #t5 do
			t[c] = t5[i]
			c = c + 1
		end
	end
	if t6 then
		for i = 1, #t6 do
			t[c] = t6[i]
			c = c + 1
		end
	end
	return t
end

function __GamsteronCore:HasBuff(unit, name)
    for i = 0, unit.buffCount do
        local buff = unit:GetBuff(i)
        if buff and buff.count > 0 and buff.name == name then
            return true
        end
    end
    return false
end

function __GamsteronCore:GetWaypoints(unit, unitID)
    local result = {}
    if unit.visible then
        TableInsert(result, self:To2D(unit.pos))
        local path = unit.pathing
        for i = path.pathIndex, path.pathCount do
            TableInsert(result, self:To2D(unit:GetPath(i)))
        end
    else
        local data = HeroData[unitID]
        if data and data.IsMoving and GameTimer() < data.GainVisionTimer + 0.5 then
            result = data.Path
        end
    end
    return result
end

function __GamsteronCore:Detector(unit, unitID)
    if not HeroData[unitID] then
        HeroData[unitID] =
        {
            ActiveItems = {},
            ActiveBuffs = {},
            ActiveSpells = {},
            IsMoving = false,
            IsVisible = false,
            EndPos = self:To2D(unit.pathing.endPos),
            Path = self:GetWaypoints(unit, unitID),
            LastMoveTimer = 0,
            StopMoveTimer = 0,
            GainVisionTimer = 0,
            LostVisionTimer = 0,
            ExpireImmobile = 0,
            ExpireDash = 0,
            RemainingDash = 0,
            RemainingImmobile = 0,
            RemainingSlow = 0,
            RemainingImmortal = 0
        }
    end
    local data = HeroData[unitID]
    if unit.visible then
        local path = unit.pathing
        local startpos = self:To2D(unit.pos)
        local endpos = self:To2D(path.endPos)
        if not self:IsInRange(startpos, endpos, 50) and not self:IsInRange(data.EndPos, endpos, 10) then
            HeroData[unitID].LastMoveTimer = GameTimer()
            HeroData[unitID].EndPos = endpos
            local currentPath = self:GetWaypoints(unit, unitID)
            for i, p in pairs(data.Path) do
                TableRemove(HeroData[unitID].Path, i)
            end
            HeroData[unitID].Path = currentPath
            for i, cb in pairs(OnProcessWaypointC) do
                cb(unit, { path = currentPath, endPos = endpos }, true)
            end
        end
        if path.hasMovePath ~= data.IsMoving then
            HeroData[unitID].IsMoving = path.hasMovePath
            if not path.hasMovePath then
                HeroData[unitID].StopMoveTimer = GameTimer()
                for i, cb in pairs(OnProcessWaypointC) do
                    cb(unit, { path = { startpos }, endPos = startpos }, false)
                end
            end
        end
        HeroData[unitID].GainVisionTimer = GameTimer()
        if not data.IsVisible then
            for i, cb in pairs(OnGainVisionC) do
                cb(unit)
            end
            HeroData[unitID].IsVisible = true
        end
    else
        HeroData[unitID].LostVisionTimer = GameTimer()
        if data.IsVisible then
            for i, cb in pairs(OnLoseVisionC) do
                cb(unit)
            end
            HeroData[unitID].IsVisible = false
        end
    end
    HeroData[unitID].RemainingDash = 0
    HeroData[unitID].RemainingImmobile = 0
    HeroData[unitID].RemainingSlow = 0
    HeroData[unitID].RemainingImmortal = 0
    local ActiveBuffs = {}
    for i = 0, unit.buffCount do
        local buff = unit:GetBuff(i)
        if buff and buff.count > 0 then
            local duration = buff.duration
            local name = buff.name
            if duration and name and #name > 0 and #name < 30 then
                TableInsert(ActiveBuffs, { buff = buff, name = name })
                for k, cb in pairs(OnUpdateBuffC) do
                    cb(unit, buff)
                end
                if self.DASH_BUFFS[name] then
                    if duration > HeroData[unitID].RemainingDash then HeroData[unitID].RemainingDash = duration end
                elseif self.STUN_BUFFS[name] then
                    if name == "recall" then
                        for k, cb in pairs(OnProcessRecallC) do
                            cb(unit, buff)
                        end
                    end
                    if duration > HeroData[unitID].RemainingImmobile then HeroData[unitID].RemainingImmobile = duration end
                elseif self.SLOW_BUFFS[name] then
                    if duration > HeroData[unitID].RemainingSlow then HeroData[unitID].RemainingSlow = duration end
                else
                    local immortal = self.UNDYING_BUFFS[name]
                    if immortal and (immortal == 100 or immortal >= 100 * unit.health / unit.maxHealth) then
                        if duration > HeroData[unitID].RemainingImmortal then HeroData[unitID].RemainingImmortal = duration end
                    end
                end
            end
        end
    end
    local OldBuffs = data.ActiveBuffs
    for i, newBuff in pairs(ActiveBuffs) do
        local buffCreated = true
        for j, oldBuff in pairs(OldBuffs) do
            if newBuff.name == oldBuff then
                buffCreated = false
                break
            end
        end
        if buffCreated then
            for k, cb in pairs(OnCreateBuffC) do
                cb(unit, newBuff.buff)
            end
        end
    end
    for i, oldBuffName in pairs(OldBuffs) do
        local buffRemoved = true
        for j, newBuff in pairs(ActiveBuffs) do
            if newBuff.name == oldBuffName then
                buffRemoved = false
                break
            end
        end
        if buffRemoved then
            for k, cb in pairs(OnRemoveBuffC) do
                cb(unit, oldBuffName)
            end
        end
    end
    for i, oldBuff in pairs(OldBuffs) do TableRemove(HeroData[unitID].ActiveBuffs, i) end
    for i, activeBuff in pairs(ActiveBuffs) do TableInsert(HeroData[unitID].ActiveBuffs, activeBuff) end
    local spell = unit.activeSpell
    if spell and spell.valid then
        local name = spell.name
        if name and #name > 0 then
            local startTime = spell.startTime
            local activeSpells = data.ActiveSpells
            if not activeSpells[name] or startTime > activeSpells[name].startTime then
                local endTime, spellCastType
                if not self.NoAutoAttacks[name] and (not unit.isChanneling or self.ATTACK_SPELLS[name]) then
                    endTime = spell.castEndTime
                    if endTime > GameTimer() and endTime > data.ExpireImmobile then
                        HeroData[unitID].ExpireImmobile = endTime
                    end
                    spellCastType = self.SPELLCAST_ATTACK
                elseif self.DASH_SPELLS[name] then
                    local delay = self.DASH_SPELLS[name]
                    endTime = delay == -1 and (spell.castEndTime) or (startTime + delay)
                    if endTime > GameTimer() and endTime > data.ExpireDash then
                        HeroData[unitID].ExpireDash = endTime
                    end
                    spellCastType = self.SPELLCAST_DASH
                elseif self.STUN_SPELLS[name] then
                    local delay = self.STUN_SPELLS[name]
                    endTime = delay == -1 and (spell.castEndTime) or (startTime + delay)
                    if endTime > GameTimer() and endTime > data.ExpireImmobile then
                        HeroData[unitID].ExpireImmobile = endTime
                    end
                    spellCastType = self.SPELLCAST_IMMOBILE
                else
                    endTime = spell.castEndTime
                    spellCastType = self.SPELLCAST_OTHER
                end
                if not activeSpells[name] then
                    HeroData[unitID].ActiveSpells[name] =
                    {
                        startTime = startTime,
                        endTime = endTime + 0.025 - LATENCY,
                        completed = false,
                        type = spellCastType,
                        spell = spell,
                        name = name,
                        castEndTime = spell.castEndTime
                    }
                else
                    if not activeSpells[name].completed and activeSpells[name].type == self.SPELLCAST_ATTACK and GameTimer() < activeSpells[name].castEndTime then
                        for j = 1, #OnCancelAttackC do
                            OnCancelAttackC[j](unit, activeSpells[name])
                        end
                    end
                    HeroData[unitID].ActiveSpells[name].startTime = startTime
                    HeroData[unitID].ActiveSpells[name].endTime = endTime + 0.025 - LATENCY
                    HeroData[unitID].ActiveSpells[name].completed = false
                    HeroData[unitID].ActiveSpells[name].type = spellCastType
                    HeroData[unitID].ActiveSpells[name].spell = spell
                    HeroData[unitID].ActiveSpells[name].name = name
                    HeroData[unitID].ActiveSpells[name].castEndTime = spell.castEndTime
                end
                activeSpells = HeroData[unitID].ActiveSpells
                for name2, args in pairs(activeSpells) do
                    if not args.completed and args.type == self.SPELLCAST_ATTACK and GameTimer() < args.castEndTime and name ~= name2 then
                        HeroData[unitID].ActiveSpells[name2].completed = true
                        HeroData[unitID].ActiveSpells[name2].endTime = GameTimer()
                        for j = 1, #OnCancelAttackC do
                            OnCancelAttackC[j](unit, args)
                        end
                    end
                end
                for i, cb in pairs(OnProcessSpellCastC) do
                    cb(unit, spell, spellCastType)
                end
            end
        end
    end
    local activeSpells = data.ActiveSpells
    for name, args in pairs(activeSpells) do
        if not args.completed then
            local currentTimer = GameTimer()
            if args.type == self.SPELLCAST_ATTACK and unit.pathing.hasMovePath and currentTimer < args.castEndTime then
                HeroData[unitID].ActiveSpells[name].completed = true
                HeroData[unitID].ActiveSpells[name].endTime = GameTimer()
                for j = 1, #OnCancelAttackC do
                    OnCancelAttackC[j](unit, args)
                end
            elseif currentTimer >= args.endTime then
                HeroData[unitID].ActiveSpells[name].completed = true
                for j = 1, #OnProcessSpellCompleteC do
                    OnProcessSpellCompleteC[j](unit, args)
                end
            end
        end
    end
    for i = #data.ActiveItems, 1, -1 do
        TableRemove(data.ActiveItems, i)
    end
    for i = 1, #self.ItemSlots do
        local slot = self.ItemSlots[i]
        local item = unit:GetItemData(slot)
        if item ~= nil then
            TableInsert(HeroData[unitID].ActiveItems, { item = item, slot = slot })
        end
    end
end

function __GamsteronCore:YasuoWallTick(unit)
    if GameTimer() > Yasuo.CastTime + 2 then
        local wallData = unit:GetSpellData(_W)
        if wallData.currentCd > 0 and wallData.cd - wallData.currentCd < 1.5 then
            Yasuo.Wall = nil
            Yasuo.Name = nil
            Yasuo.StartPos = nil
            Yasuo.Level = wallData.level
            Yasuo.CastTime = wallData.castTime
            for i = 1, GameParticleCount() do
                local obj = GameParticle(i)
                if obj then
                    local name = obj.name:lower()
                    if name:find("yasuo") and name:find("_w_") and name:find("windwall") then
                        if name:find("activate") then
                            Yasuo.StartPos = self:To2D(obj.pos)
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

function __GamsteronCore:IsYasuoWall()
    if not IsYasuo or Yasuo.Wall == nil then return false end
    if Yasuo.Name == nil or Yasuo.Wall.name == nil or Yasuo.Name ~= Yasuo.Wall.name or Yasuo.StartPos == nil then
        Yasuo.Wall = nil
        return false
    end
    return true
end

function __GamsteronCore:To2D(vec)
    return { x = vec.x, y = vec.z or vec.y }
end

function __GamsteronCore:GetDistance(vec1, vec2)
    local dx = vec1.x - vec2.x
    local dy = vec1.y - vec2.y
    return MathSqrt(dx * dx + dy * dy)
end

function __GamsteronCore:GetDistanceSquared(vec1, vec2)
    local dx = vec1.x - vec2.x
    local dy = vec1.y - vec2.y
    return dx * dx + dy * dy
end

function __GamsteronCore:IsInRange(vec1, vec2, range)
    local dx = vec1.x - vec2.x
    local dy = vec1.y - vec2.y
    return dx * dx + dy * dy <= range * range
end

function __GamsteronCore:GetBuffCount(unit, name)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and buff.count > 0 and buff.name == name then
			return buff.count
		end
	end
	return -1
end

function __GamsteronCore:HasItem(unit, id)
	for i = 1, #self.ItemSlots do
		local slot = self.ItemSlots[i]
		local item = unit:GetItemData(slot)
		if item then
			local itemID = item.itemID
			if itemID > 0 and itemID == id then
				return true
			end
		end
	end
end

function __GamsteronCore:TotalShieldHealth(target)
	local result = target.health + target.shieldAD + target.shieldAP
	if target.charName == "Blitzcrank" then
		if not self:HasBuff(target, "manabarriercooldown") and not self:HasBuff(target, "manabarrier") then
			result = result + target.mana * 0.5
		end
	end
	return result
end

function __GamsteronCore:IsChanneling(unit)
	if self.ChannelingBuffs[unit.charName] ~= nil then
		return self.ChannelingBuffs[unit.charName](unit)
	end
	return false
end

function __GamsteronCore:IsValidTarget(target)
	if target == nil or target.networkID == nil then
		return false
	end
	if self.Obj_AI_Bases[target.type] ~= nil then
		if not target.valid then
			return false
		end
	end
	if target.dead or (not target.visible) or (not target.isTargetable) then
		return false
	end
	return true
end

function __GamsteronCore:GetAutoAttackRange(from, target)
    local result = from.range
    local name = from.charName
	if from.type == Obj_AI_Minion then
		result = self.MinionsRange[name] ~= nil and self.MinionsRange[name] or 0
	elseif from.type == Obj_AI_Turret then
		result = 775
	end
	result = result + from.boundingRadius + (target ~= nil and (target.boundingRadius - 20) or 35)
	if target.type == Obj_AI_Hero and self.SpecialAutoAttackRanges[name] ~= nil then
		result = result + self.SpecialAutoAttackRanges[name](target)
	end
	return result
end

function __GamsteronCore:IsInAutoAttackRange(from, target)
	return self:IsInRange(self:To2D(from.pos), self:To2D(target.pos), self:GetAutoAttackRange(from, target))
end

function __GamsteronCore:RadianToDegree(angle)
    return angle * (180.0 / MathPI)
end

function __GamsteronCore:Polar(v1)
    if v1.x == 0 then
        if v1.y > 0 then
            return 90
        end
        return v1.y < 0 and 270 or 0
    end
    local theta = self:RadianToDegree(MathAtan(v1.y / v1.x))
    if v1.x < 0 then
        theta = theta + 180
    end
    if theta < 0 then
        theta = theta + 360
    end
    return theta
end

function __GamsteronCore:AngleBetween(vec1, vec2)
    local theta = self:Polar(vec1) - self:Polar(vec2)
    if theta < 0 then
        theta = theta + 360
    end
    if theta > 180 then
        theta = 360 - theta
    end
    return theta
end

function __GamsteronCore:EqualVector(vec1, vec2)
    local diffX = vec1.x - vec2.x
    local diffY = vec1.y - vec2.y
    return diffX >= -10 and diffX <= 10 and diffY >= -10 and diffY <= 10
end

function __GamsteronCore:EqualDirection(vec1, vec2)
    return self:AngleBetween(vec1, vec2) <= 5
end

function __GamsteronCore:Normalized(vec1, vec2)
    local vec = { x = vec1.x - vec2.x, y = vec1.y - vec2.y }
    local length = MathSqrt(vec.x * vec.x + vec.y * vec.y)
    if length > 0 then
        local inv = 1.0 / length
        return { x = (vec.x * inv), y = (vec.y * inv) }
    end
    return nil
end

function __GamsteronCore:Extended(vec, dir, range)
    if dir == nil then return vec end
    return { x = vec.x + dir.x * range, y = vec.y + dir.y * range }
end

function __GamsteronCore:Perpendicular(dir)
    if dir == nil then return nil end
    return { x = -dir.y, y = dir.x }
end

function __GamsteronCore:ProjectOn(p, p1, p2)
    local isOnSegment, pointSegment, pointLine
    local px,pz = p.x, p.y
    local ax,az = p1.x, p1.y
    local bx,bz = p2.x, p2.y
    local bxax = bx - ax
    local bzaz = bz - az
    local t = ((px - ax) * bxax + (pz - az) * bzaz) / (bxax * bxax + bzaz * bzaz)
    local pointLine = { x = ax + t * bxax, y = az + t * bzaz }
    if t < 0 then
        isOnSegment = false
        pointSegment = p1
    elseif t > 1 then
        isOnSegment = false
        pointSegment = p2
    else
        isOnSegment = true
        pointSegment = pointLine
    end
    return isOnSegment, pointSegment, pointLine
end

function __GamsteronCore:AddVectors(vec1, vec2, mulitplier)
    mulitplier = mulitplier or 1
    local x = vec1.x + vec2.x
    local y = vec1.y + vec2.y
    return {
        x = x * mulitplier,
        y = y * mulitplier
    }
end

function __GamsteronCore:SubVectors(vec1, vec2, mulitplier)
    mulitplier = mulitplier or 1
    local x = vec1.x - vec2.x
    local y = vec1.y - vec2.y
    return {
        x = x * mulitplier,
        y = y * mulitplier
    }
end

function __GamsteronCore:OnAllyNexusLoad(cb)
    TableInsert(BuildingsLoad.OnAllyNexusLoadC, cb)
end

function __GamsteronCore:OnAllyInhibitorLoad(cb)
    TableInsert(BuildingsLoad.OnAllyInhibitorLoadC, cb)
end

function __GamsteronCore:OnAllyTurretLoad(cb)
    TableInsert(BuildingsLoad.OnAllyTurretLoadC, cb)
end

function __GamsteronCore:OnEnemyNexusLoad(cb)
    TableInsert(BuildingsLoad.OnEnemyNexusLoadC, cb)
end

function __GamsteronCore:OnEnemyInhibitorLoad(cb)
    TableInsert(BuildingsLoad.OnEnemyInhibitorLoadC, cb)
end

function __GamsteronCore:OnEnemyTurretLoad(cb)
    TableInsert(BuildingsLoad.OnEnemyTurretLoadC, cb)
end

function __GamsteronCore:OnEnemyHeroLoad(cb)
    TableInsert(HeroesLoad.OnEnemyHeroLoadC, cb)
end

function __GamsteronCore:OnAllyHeroLoad(cb)
    TableInsert(HeroesLoad.OnAllyHeroLoadC, cb)
end

function __GamsteronCore:OnProcessRecall(cb)
    TableInsert(OnProcessRecallC, cb)
end

function __GamsteronCore:OnProcessSpellCast(cb)
    TableInsert(OnProcessSpellCastC, cb)
end

function __GamsteronCore:OnProcessSpellComplete(cb)
    TableInsert(OnProcessSpellCompleteC, cb)
end

function __GamsteronCore:OnProcessWaypoint(cb)
    TableInsert(OnProcessWaypointC, cb)
end

function __GamsteronCore:OnCancelAttack(cb)
    TableInsert(OnCancelAttackC, cb)
end

function __GamsteronCore:OnUpdateBuff(cb)
    TableInsert(OnUpdateBuffC, cb)
end

function __GamsteronCore:OnCreateBuff(cb)
    TableInsert(OnCreateBuffC, cb)
end

function __GamsteronCore:OnRemoveBuff(cb)
    TableInsert(OnRemoveBuffC, cb)
end

function __GamsteronCore:OnGainVision(cb)
    TableInsert(OnGainVisionC, cb)
end

function __GamsteronCore:OnLoseVision(cb)
    TableInsert(OnLoseVisionC, cb)
end

function __GamsteronCore:OnIssueOrder(cb)
    TableInsert(OnIssueOrderC, cb)
end

function __GamsteronCore:OnSpellCast(cb)
    TableInsert(OnSpellCastC, cb)
end

function __GamsteronCore:GetAllyNexus()
    return AllyNexus
end

function __GamsteronCore:GetEnemyNexus()
    return EnemyNexus
end

function __GamsteronCore:GetAllyInhibitors()
    return AllyInhibitors
end

function __GamsteronCore:GetEnemyInhibitors()
    return EnemyInhibitors
end

function __GamsteronCore:GetAllyTurrets()
    return AllyTurrets
end

function __GamsteronCore:GetEnemyTurrets()
    return EnemyTurrets
end

function __GamsteronCore:GetHeroData(unit, skip)
    unit = unit or myHero
    local unitID = unit.networkID
    if not skip then self:Detector(unit, unitID) end
    return HeroData[unitID]
end

function __GamsteronCore:IsYasuoWallCollision(startPos, endPos, speed, delay)
    if not IsYasuo or not self:IsYasuoWall() then return false end
    local Pos = self:To2D(Yasuo.Wall.pos)
    local Width = 300 + 50 * Yasuo.Level
    local Direction = self:Perpendicular(self:Normalized(Pos, Yasuo.StartPos))
    local StartPos = self:Extended(Pos, Direction, Width / 2)
    local EndPos = self:Extended(StartPos, Direction, -Width)
    local IntersectionResult = self:Intersection(StartPos, EndPos, endPos, startPos)
    if IntersectionResult.Intersects then
        local t = delay + self:GetDistance(IntersectionResult.Point, startPos) / speed
        if GameTimer() + t < Yasuo.CastTime + 4 then
            return true
        end
    end
    return false
end

function __GamsteronCore:PathLength(path)
    local result = 0
    for i = 1, #path - 1 do
        result = result + self:GetDistance(path[i], path[i + 1])
    end
    return result
end

function __GamsteronCore:CutPath(path, distance)
    local result = {}
    local Distance = distance
    if Distance < 0 then Distance = 0 end
    for i = 1, #path - 1 do
        local dist = self:GetDistance(path[i], path[i + 1])
        if dist > Distance then
            if Distance < 0 then Distance = 0 end
            TableInsert(result, self:Extended(path[i], self:Normalized(path[i+1], path[i]), Distance))
            for j = i + 1, #path do
                TableInsert(result, path[j])
            end
            break
        end
        Distance = Distance - dist
    end
    if #result > 0 then return result end
    return { path[#path] }
end

function __GamsteronCore:GetCollisionWaypoints(unit)
    local result = {}
    TableInsert(result, self:To2D(unit.pos))
    local path = unit.pathing
    for i = path.pathIndex, path.pathCount do
        TableInsert(result, self:To2D(unit:GetPath(i)))
    end
    return result
end

function __GamsteronCore:GetInterceptionTime(source, startP, endP, unitspeed, spellspeed)
    local sx = source.x
    local sy = source.y
    local ux = startP.x
    local uy = startP.y
    local dx = endP.x - ux
    local dy = endP.y - uy
    local magnitude = MathSqrt(dx * dx + dy * dy)
    dx = (dx / magnitude) * unitspeed
    dy = (dy / magnitude) * unitspeed
    local a = (dx * dx) + (dy * dy) - (spellspeed * spellspeed)
    local b = 2 * ((ux * dx) + (uy * dy) - (sx * dx) - (sy * dy))
    local c = (ux * ux) + (uy * uy) + (sx * sx) + (sy * sy) - (2 * sx * ux) - (2 * sy * uy)
    local d = (b * b) - (4 * a * c)
    if d > 0 then
        local t1 = (-b + MathSqrt(d)) / (2 * a)
        local t2 = (-b - MathSqrt(d)) / (2 * a)
        return MathMax(t1, t2)
    end
    if d >= 0 and d < 0.00001 then
        return -b / (2 * a)
    end
    return 0.00001
end

function __GamsteronCore:Intersection(lineSegment1Start, lineSegment1End, lineSegment2Start, lineSegment2End)
    local IntersectionResult = { Intersects = false, Point = { x = 0, y = 0 } }
    local deltaACy = lineSegment1Start.y - lineSegment2Start.y
    local deltaDCx = lineSegment2End.x - lineSegment2Start.x
    local deltaACx = lineSegment1Start.x - lineSegment2Start.x
    local deltaDCy = lineSegment2End.y - lineSegment2Start.y
    local deltaBAx = lineSegment1End.x - lineSegment1Start.x
    local deltaBAy = lineSegment1End.y - lineSegment1Start.y
    local denominator = deltaBAx * deltaDCy - deltaBAy * deltaDCx
    local numerator = deltaACy * deltaDCx - deltaACx * deltaDCy
    if denominator == 0 then
        if numerator == 0 then
            if lineSegment1Start.x >= lineSegment2Start.x and lineSegment1Start.x <= lineSegment2End.x then
                return { Intersects = true, Point = lineSegment1Start }
            end
            if lineSegment2Start.x >= lineSegment1Start.x and lineSegment2Start.x <= lineSegment1End.x then
                return { Intersects = true, Point = lineSegment2Start }
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
        x = lineSegment1Start.x + r * deltaBAx,
        y = lineSegment1Start.y + r * deltaBAy
    }
    return { Intersects = true, Point = point }
end

function __GamsteronCore:GetCollisionPrediction(unit, from, spellspeed, spelldelay)
    local path = self:GetCollisionWaypoints(unit)
    local pathCount = #path
    if pathCount <= 1 or not unit.pathing.hasMovePath then
        return false, self:To2D(unit.pos)
    else
        return true, self:To2D(unit:GetPrediction(spellspeed, spelldelay))
    end
end

function __GamsteronCore:GetCollision(from, to, speed, delay, radius, collisionObjects, objectsList)
    local result = {}
    local direction = self:Normalized(to, from)
    to = self:Extended(to, direction, 35)
    from = self:Extended(from, direction, -35)
    for i = 1, #collisionObjects do
        local objectType = collisionObjects[i]
        if objectType == self.COLLISION_MINION then
            local objects = objectsList.enemyMinions
            for k = 1, #objects do
                local object = objects[k]
                local HasMovePath, CastPos = self:GetCollisionPrediction(object, from, speed, delay)
                local isOnSegment, pointSegment, pointLine = self:ProjectOn(CastPos, from, to)
                local IsCollisionable = false
                if isOnSegment and self:IsInRange(CastPos, pointSegment, radius + 30 + object.boundingRadius) then
                    TableInsert(result, object)
                    IsCollisionable = true
                end
                if HasMovePath and not IsCollisionable then
                    local objectPos = self:To2D(object.pos)
                    isOnSegment, pointSegment, pointLine = self:ProjectOn(objectPos, from, to)
                    if isOnSegment and self:IsInRange(objectPos, pointSegment, radius + 30 + object.boundingRadius) then
                        TableInsert(result, object)
                    end
                end
            end
        elseif objectType == self.COLLISION_ENEMYHERO then
            local objects = objectsList.enemyHeroes
            for k = 1, #objects do
                local object = objects[k]
                local HasMovePath, CastPos = self:GetCollisionPrediction(object, from, speed, delay)
                local isOnSegment, pointSegment, pointLine = self:ProjectOn(CastPos, from, to)
                local IsCollisionable = false
                if isOnSegment and self:IsInRange(CastPos, pointSegment, radius + 30 + object.boundingRadius) then
                    TableInsert(result, object)
                    IsCollisionable = true
                end
                if HasMovePath and not IsCollisionable then
                    local objectPos = self:To2D(object.pos)
                    isOnSegment, pointSegment, pointLine = self:ProjectOn(objectPos, from, to)
                    if isOnSegment and self:IsInRange(objectPos, pointSegment, radius + 30 + object.boundingRadius) then
                        TableInsert(result, object)
                    end
                end
            end
        elseif objectType == self.COLLISION_ALLYHERO then
            local objects = objectsList.allyHeroes
            for k = 1, #objects do
                local object = objects[k]
                local HasMovePath, CastPos = self:GetCollisionPrediction(object, from, speed, delay)
                local isOnSegment, pointSegment, pointLine = self:ProjectOn(CastPos, from, to)
                local IsCollisionable = false
                if isOnSegment and self:IsInRange(CastPos, pointSegment, radius + 30 + object.boundingRadius) then
                    TableInsert(result, object)
                    IsCollisionable = true
                end
                if HasMovePath and not IsCollisionable then
                    local objectPos = self:To2D(object.pos)
                    isOnSegment, pointSegment, pointLine = self:ProjectOn(objectPos, from, to)
                    if isOnSegment and self:IsInRange(objectPos, pointSegment, radius + 30 + object.boundingRadius) then
                        TableInsert(result, object)
                    end
                end
            end
        --elseif objectType == CollisionableObjects.Walls then
        elseif IsYasuo and objectType == self.COLLISION_YASUOWALL and self:IsYasuoWall() then
            local Pos = self:To2D(Yasuo.Wall.pos)
            local Width = 300 + 50 * Yasuo.Level
            local Direction = self:Perpendicular(self:Normalized(Pos, Yasuo.StartPos))
            local StartPos = self:Extended(Pos, Direction, Width / 2)
            local EndPos = self:Extended(StartPos, Direction, -Width)
            local IntersectionResult = self:Intersection(StartPos, EndPos, to, from)
            if IntersectionResult.Intersects then
                local t = GameTimer() + (self:GetDistance(IntersectionResult.Point, from) / speed + delay)
                if t < Yasuo.CastTime + 4 then
                    return true, { Yasuo.Wall }
                end
            end
        end
    end
    return false, result
end

function __GamsteronCore:IsFacing(source, target)
    local sourceDir = self:To2D(source.dir)
    local targetPos = self:To2D(target.pos)
    local sourcePos = self:To2D(source.pos)
    local targetDir = self:Normalized(targetPos, sourcePos)
    if self:AngleBetween(sourceDir, targetDir) < 90 then
        local sourceEndPos = self:To2D(source.pathing.endPos)
        local sourceExtended = self:Extended(sourcePos, self:Normalized(sourceEndPos - sourcePos), 0.5 * source.ms)
        if not self:EqualVector(sourceExtended, sourcePos) then
            sourceDir = self:Normalized(sourceExtended, sourcePos)
        end
        local targetEndPos = self:To2D(target.pathing.endPos)
        local targetExtended = self:Extended(targetPos, self:Normalized(targetEndPos - targetPos), 0.5 * target.ms)
        if self:AngleBetween(sourceDir, self:Normalized(targetExtended, sourceExtended)) < 90 then
            return true
        end
    end
    return false
end

function __GamsteronCore:__Interrupter()
    local c = {}
    local result = {}
    c.__index = c
    setmetatable(result, c)
    local cb = {}
    local spells =
    {
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
    Callback.Add("Draw", function()
        local mePos = self:To2D(myHero.pos)
        for i = 1, GameHeroCount() do
            local o = GameHero(i)
            if o and o.valid and not o.dead and o.isTargetable and o.visible and self:IsInRange(mePos, self:To2D(o.pos), 1500) then
                local a = o.activeSpell
                if a and a.valid and a.isChanneling and spells[a.name] and a.castEndTime - GameTimer() > 0.33 then
                    for j = 1, #cb do
                        cb[j](o, a)
                    end
                end
            end
        end
    end)
    function c:OnInterrupt(cbb)
        TableInsert(cb, cbb)
    end
    return result
end

function __GamsteronCore:GetEnemyMinions(from, range)
    local result = {}
    from = self:To2D(from.pos)
    for i = 1, GameMinionCount() do
        local minion = GameMinion(i)
        if minion and minion.team ~= self.TEAM_ALLY and self:IsValidTarget(minion) and self:IsInRange(from, self:To2D(minion.pos), range) then
            TableInsert(result, minion)
        end
    end
    return result
end

function __GamsteronCore:GetAllyHeroes(from, range, unitID)
    local result = {}
    from = self:To2D(from.pos)
    for i = 1, GameHeroCount() do
        local hero = GameHero(i)
        if hero and self:IsValidTarget(hero) and unitID ~= hero.networkID and hero.team == self.TEAM_ALLY then
            if self:IsInRange(from, self:To2D(hero.pos), range) then
                TableInsert(result, hero)
            end
        end
    end
    return result
end

function __GamsteronCore:GetEnemyHeroes(from, range, unitID)
    local result = {}
    from = self:To2D(from.pos)
    for i = 1, GameHeroCount() do
        local hero = GameHero(i)
        if hero and self:IsValidTarget(hero) and unitID ~= hero.networkID and hero.team ~= self.TEAM_ALLY then
            if self:IsInRange(from, self:To2D(hero.pos), range) then
                TableInsert(result, hero)
            end
        end
    end
    return result
end

_G.GamsteronCore = __GamsteronCore()

_G.TickAction = function(cb, remainingTime)
    TableInsert(TickActions, { cb, GameTimer() + remainingTime })
end

TableInsert(HeroesLoad.OnEnemyHeroLoadC, function(hero)
    if hero.charName == "Yasuo" then
        IsYasuo = true
    end
end)

local function PreLoad()
    if GameTimer() > 15 then
        if not GeneralLoadTimers.Active then
            GeneralLoadTimers.Active = true
            GeneralLoadTimers.EndTime = GameTimer() + 5
            BuildingsLoad.EndTime = GameTimer() + 5
            HeroesLoad.EndTime = GameTimer() + 120
            return
        end
        if GeneralLoadTimers.Active and GameTimer() > GeneralLoadTimers.EndTime then
            GeneralLoaded = true
            for i, cb in pairs(OnLoadC) do
                cb()
            end
        end
    end
end

function AddLoadCallback(cb)
    TableInsert(OnLoadC, cb)
end

Callback.Add("Tick", function()
    if not GeneralLoaded then
        PreLoad()
        return
    end
    if not BuildingsLoaded then
        if GameTimer() > BuildingsLoad.Performance then
            for i = 1, GameObjectCount() do
                local obj = GameObject(i)
                if obj then
                    local type = obj.type
                    if type and (type == Obj_AI_Barracks or type == Obj_AI_Turret or type == Obj_AI_Nexus) then
                        local team = obj.team
                        local name = obj.name
                        if team and name and #name > 0 then
                            local isnew = true
                            local isally = obj.team == myHero.team
                            if type == Obj_AI_Barracks then
                                for j, id in pairs(BuildingsLoad.Inhibitors) do
                                    if name == id then
                                        isnew = false
                                        break
                                    end
                                end
                                if isnew then
                                    if team == myHero.team then
                                        TableInsert(AllyInhibitors, obj)
                                        for k, cb in pairs(BuildingsLoad.OnAllyInhibitorLoadC) do
                                            cb(obj)
                                        end
                                    else
                                        TableInsert(EnemyInhibitors, obj)
                                        for k, cb in pairs(BuildingsLoad.OnEnemyInhibitorLoadC) do
                                            cb(obj)
                                        end
                                    end
                                    TableInsert(BuildingsLoad.Inhibitors, name)
                                end
                            elseif type == Obj_AI_Turret then
                                if name ~= "Turret_OrderTurretShrine_A" and name ~= "Turret_ChaosTurretShrine_A" then
                                    for j, id in pairs(BuildingsLoad.Turrets) do
                                        if name == id then
                                            isnew = false
                                            break
                                        end
                                    end
                                    if isnew then
                                        if team == myHero.team then
                                            TableInsert(AllyTurrets, obj)
                                            for k, cb in pairs(BuildingsLoad.OnAllyTurretLoadC) do
                                                cb(obj)
                                            end
                                        else
                                            TableInsert(EnemyTurrets, obj)
                                            for k, cb in pairs(BuildingsLoad.OnEnemyTurretLoadC) do
                                                cb(obj)
                                            end
                                        end
                                        TableInsert(BuildingsLoad.Turrets, name)
                                    end
                                end
                            elseif type == Obj_AI_Nexus then
                                for j, id in pairs(BuildingsLoad.Nexuses) do
                                    if name == id then
                                        isnew = false
                                        break
                                    end
                                end
                                if isnew then
                                    if team == myHero.team then
                                        AllyNexus = obj
                                        for k, cb in pairs(BuildingsLoad.OnAllyNexusLoadC) do
                                            cb(obj)
                                        end
                                    else
                                        EnemyNexus = obj
                                        for k, cb in pairs(BuildingsLoad.OnEnemyNexusLoadC) do
                                            cb(obj)
                                        end
                                    end
                                    TableInsert(BuildingsLoad.Nexuses, name)
                                end
                            end
                        end
                    end
                end
            end
            if GameTimer() > BuildingsLoad.EndTime then
                BuildingsLoaded = true
            else
                BuildingsLoad.Performance = GameTimer() + 0.5
            end
        end
    end
    if not HeroesLoaded then
        if GameTimer() > HeroesLoad.Performance then
            for i = 1, GameHeroCount() do
                local obj = GameHero(i)
                if obj then
                    local name = obj.charName
                    if name and #name > 0 then
                        local objID = obj.networkID
                        local isnew = true
                        for i, id in pairs(HeroesLoad.Heroes) do
                            if objID == id then
                                isnew = false
                                break
                            end
                        end
                        if isnew then
                            HeroesLoad.Count = HeroesLoad.Count + 1
                            if obj.team == myHero.team then
                                for i, cb in pairs(HeroesLoad.OnAllyHeroLoadC) do
                                    cb(obj)
                                end
                            else
                                for i, cb in pairs(HeroesLoad.OnEnemyHeroLoadC) do
                                    cb(obj)
                                end
                            end
                            TableInsert(HeroesLoad.Heroes, objID)
                        end
                    end
                end
            end
            if HeroesLoad.Count >= 10 or GameTimer() > HeroesLoad.EndTime then
                HeroesLoaded = true
            else
                HeroesLoad.Performance = GameTimer() + 0.5
            end
        end
    end
end)

Callback.Add("Draw", function()
    if not GeneralLoaded then
        PreLoad()
        return
    end
    for i, action in pairs(TickActions) do
        if GameTimer() > action[2] or action[1]() == true then
            TableRemove(TickActions, i)
        end
    end
    local YasuoChecked = false
    for i = 1, GameHeroCount() do
        local unit = GameHero(i)
        if unit and unit.valid then
            GamsteronCore:Detector(unit, unit.networkID)
            if IsYasuo and not YasuoChecked and unit.charName == "Yasuo" then
                GamsteronCore:YasuoWallTick(unit)
                YasuoChecked = true
            end
        end
    end
end)

_G.GamsteronCoreLoaded = true
