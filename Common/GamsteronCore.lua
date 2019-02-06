local GamsteronCoreVer = 0.109
_G.GamsteronDebug = true
--_G.FileDebug = io.open(SCRIPT_PATH .. "000TEST.txt", "wb")

-- locals update START
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

    local Obj_HQ 						= "obj_HQ"
    local Structures =
    {
        [Obj_AI_Barracks] = true,
        [Obj_AI_Turret] = true,
        [Obj_HQ] = true
    }

    local HeroesLoaded                  = false
    local HeroesLoad                    =
    {
        Count                       = 0,
        Heroes                      = {},
        OnEnemyHeroLoadC            = {},
        OnAllyHeroLoadC             = {}
    }

    local AllyNexus                     = nil
    local EnemyNexus                    = nil
    local AllyInhibitors                = {}
    local EnemyInhibitors               = {}
    local AllyTurrets                   = {}
    local EnemyTurrets                  = {}
    local EnemyHeroes                   = {}
    local AllyHeroes                    = {}

    local OnLoadC                       = {}
    local TickActions                   = {}

    local Menu = MenuElement({name = "Gamsteron Core", id = "GamCore", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Icons/GamsteronCore.png" })
    Menu:MenuElement({id = "ping", name = "Your Ping", value = 50, min = 0, max = 150, step = 1, callback = function(value) _G.LATENCY = value * 0.001 end })
    Menu:MenuElement({name = "Version " .. tostring(GamsteronCoreVer), type = _G.SPACE, id = "vercorespace"})
    _G.LATENCY = Menu.ping:Value() * 0.001

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
-- locals update END

function __GamsteronCore:__init()
    self.HEROES_SPELL                     = 0
    self.HEROES_ATTACK                    = 1
    self.HEROES_IMMORTAL                  = 2

    self.TEAM_ALLY                        = myHero.team
    self.TEAM_ENEMY                       = 300 - self.TEAM_ALLY
    self.TEAM_JUNGLE                      = 300

    self.MINION_TYPE_OTHER_MINION		    = 1
    self.MINION_TYPE_MONSTER			    = 2
    self.MINION_TYPE_LANE_MINION		    = 3

    self.DAMAGE_TYPE_PHYSICAL			    = 0
    self.DAMAGE_TYPE_MAGICAL			    = 1
    self.DAMAGE_TYPE_TRUE				    = 2

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
        ["GravesAutoAttackRecoil"] = true,
        ["LeonaShieldOfDaybreakAttack"] = true
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
            args.RawTotal = args.RawTotal * t[_G.SDK.Damage:GetMaxLevel(args.From)] * 0.01;
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
                args.RawMagical = args.RawMagical + (1 + (args.TargetIsMinion and 1.2 or 0)) * t[_G.SDK.Damage:GetMaxLevel(args.From)];
            end
        end,
        [3091] = function(args)
            args.RawMagical = args.RawMagical + 40;
        end,
        [3094] = function(args)
            if self:GetBuffCount(args.From, "itemstatikshankcharge") == 100 then
                local t = { 50, 50, 50, 50, 50, 58, 66, 75, 83, 92, 100, 109, 117, 126, 134, 143, 151, 160 };
                args.RawMagical = args.RawMagical + t[_G.SDK.Damage:GetMaxLevel(args.From)];
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
end

function __GamsteronCore:GetBuffDuration(unit, bName)
    bName = bName:lower()
    for i = 0, unit.buffCount do
        local buff = unit:GetBuff(i)
        if buff and buff.count > 0 and buff.name:lower() == bName then
            return buff.duration
        end
    end
    return 0
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

function __GamsteronCore:ProjectOn(p, p1, p2)
    local isOnSegment, pointSegment, pointLine
    local px,pz = p.x, (p.z or p.y)
    local ax,az = p1.x, (p1.z or p1.y)
    local bx,bz = p2.x, (p2.z or p2.y)
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

function __GamsteronCore:CastSpell(spell, unit, castPos)
    if unit == nil and castPos == nil then
        if Control.CastSpell(spell) == true then
            return true
        end
    else
        if castPos ~= nil then
            if Control.CastSpell(spell, castPos) == true then
                return true
            end
        elseif Control.CastSpell(spell, unit) == true then
            return true
        end
    end
    return false
end

function __GamsteronCore:Join(t1, t2, t3, t4, t5, t6)
	local t = {}
    for i = 1, #t1 do TableInsert(t, t1[i]) end
    for i = 1, #t2 do TableInsert(t, t2[i]) end
    if t3 then for i = 1, #t3 do TableInsert(t, t3[i]) end end
    if t4 then for i = 1, #t4 do TableInsert(t, t4[i]) end end
    if t5 then for i = 1, #t5 do TableInsert(t, t5[i]) end end
    if t6 then for i = 1, #t6 do TableInsert(t, t6[i]) end end
	return t
end

function __GamsteronCore:HasBuff(unit, name)
    name = name:lower()
    for i = 0, unit.buffCount do
        local buff = unit:GetBuff(i)
        if buff and buff.count > 0 and buff.name:lower() == name then
            return true
        end
    end
    return false
end

function __GamsteronCore:To2D(vec)
    return { x = vec.x, y = vec.z or vec.y }
end

function __GamsteronCore:GetDistance(vec1, vec2)
    local dx = vec1.x - vec2.x
    local dy = (vec1.z or vec1.y) - (vec2.z or vec2.y)
    return MathSqrt(dx * dx + dy * dy)
end

function __GamsteronCore:GetDistanceSquared(vec1, vec2)
    local dx = vec1.x - vec2.x
    local dy = (vec1.z or vec1.y) - (vec2.z or vec2.y)
    return dx * dx + dy * dy
end

function __GamsteronCore:IsInRange(vec1, vec2, range)
    local dx = vec1.x - vec2.x
    local dy = (vec1.z or vec1.y) - (vec2.z or vec2.y)
    return dx * dx + dy * dy <= range * range
end

function __GamsteronCore:GetClosestEnemy(enemyList, maxDistance)
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

function __GamsteronCore:GetImmobileEnemy(enemyList, maxDistance)
    local result = nil
    local num = 0
    for i = 1, #enemyList do
        local hero = enemyList[i]
        local distance = myHero.pos:DistanceTo(hero.pos)
        local iT = self:ImmobileTime(hero)
        if distance < maxDistance and iT > num then
            num = iT
            result = hero
        end
    end
    return result
end

function __GamsteronCore:IsSlowed(unit, delay)
    for i = 0, unit.buffCount do
        local buff = unit:GetBuff(i)
        if from and buff.count > 0 and buff.type == 10 and buff.duration >= delay then
            return true
        end
    end
    return false
end

function __GamsteronCore:IsImmobile(unit, delay)
    -- http://leagueoflegends.wikia.com/wiki/Types_of_Crowd_Control
        --ok
        --STUN = 5
        --SNARE = 11
        --SUPRESS = 24
        --KNOCKUP = 29
        --good
        --FEAR = 21 -> fiddle Q, ...
        --CHARM = 22 -> ahri E, ...
        --not good
        --TAUNT = 8 -> rammus E, ... can move too fast + anyway will detect attack
        --SLOW = 10 -> can move too fast -> nasus W, zilean E are ok. Rylai item, ... not good
        --KNOCKBACK = 30 -> alistar W, lee sin R, ... - no no
    for i = 0, unit.buffCount do
        local buff = unit:GetBuff(i)
        if buff and buff.count > 0 and buff.duration > delay then
            local bType = buff.type
            if bType == 5 or bType == 11 or bType == 21 or bType == 22 or bType == 24 or bType == 29 or buff.name == "recall" then
                return true
            end
        end
    end
    return false
end

function __GamsteronCore:ImmobileTime(unit)
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

function __GamsteronCore:GetBuffCount(unit, name)
    name = name:lower()
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and buff.count > 0 and buff.name:lower() == name then
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
	if not target.alive or target.dead or (not target.visible) or (not target.isTargetable) then
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

function __GamsteronCore:IsInAutoAttackRange(from, target, extrarange)
    local range = extrarange or 0
	return self:IsInRange(from.pos, target.pos, self:GetAutoAttackRange(from, target) + range)
end

function __GamsteronCore:RadianToDegree(angle)
    return angle * (180.0 / MathPI)
end

function __GamsteronCore:Polar(v1)
    local x = v1.x
    local y = v1.z or v1.y
    if x == 0 then
        if y > 0 then
            return 90
        end
        return y < 0 and 270 or 0
    end
    local theta = self:RadianToDegree(MathAtan(y / x))
    if x < 0 then
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
    local vec = { x = vec1.x - vec2.x, y = (vec1.z or vec1.y) - (vec2.z or vec2.y) }
    local length = MathSqrt(vec.x * vec.x + vec.y * vec.y)
    if length > 0 then
        local inv = 1.0 / length
        return { x = (vec.x * inv), y = (vec.y * inv) }
    end
    return nil
end

function __GamsteronCore:Extended(vec, dir, range)
    if dir == nil then return vec end
    local vecy = vec.z or vec.y
    local diry = dir.z or dir.y
    return { x = vec.x + dir.x * range, y = vecy + diry * range }
end

function __GamsteronCore:OnEnemyHeroLoad(cb)
    TableInsert(HeroesLoad.OnEnemyHeroLoadC, cb)
end

function __GamsteronCore:OnAllyHeroLoad(cb)
    TableInsert(HeroesLoad.OnAllyHeroLoadC, cb)
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

function __GamsteronCore:IsFacing(source, target, angle)
    angle = angle or 90
    if target.pos then target = target.pos end
    local sd = self:To2D(source.dir)
    local sp = self:To2D(source.pos)
    local dir = self:To2D(Vector(target) - source.pos)
    --local ext = source.pos + source.dir * 500
    --Draw.Line(source.pos:To2D(), ext:To2D())
    if self:AngleBetween(sd, dir) < angle then
        if source.posTo then
            local normalized = self:Normalized(source.posTo, sp)
            --local ext = self:Extended(sp, normalized, 1000)
            --Draw.Circle(Vector(ext.x, 0, ext.y))
            --Draw.Line(source.pos:To2D(), Vector(ext.x, 0, ext.y):To2D())
            if normalized == nil or self:AngleBetween(normalized, dir) < angle then
                return true
            end
        end
        return true
    end
    return false
end

function __GamsteronCore:IsBothFacing(source, target, angle)
    if self:IsFacing(source, target, angle) and self:IsFacing(target, source, angle) then
        return true
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
    local function InterrupterTick()
        for i = 1, GameHeroCount() do
            local unit = GameHero(i)
            if self:IsValidTarget(unit) and myHero.pos:DistanceTo(unit.pos) < 1500 then
                local spell = unit.activeSpell
                if spell and spell.valid and spells[spell.name] and spell.castEndTime - GameTimer() > 0.33 then
                    for j = 1, #cb do
                        cb[j](unit)
                    end
                end
            end
        end
    end
    Callback.Add("Tick", function()
        if _G.GamsteronDebug then
            local status, err = pcall(function() InterrupterTick() end) if not status then print("INTERRUPTER TICK: " .. tostring(err)) end
        else
            InterrupterTick()
        end
    end)
    function c:OnInterrupt(cbb)
        TableInsert(cb, cbb)
    end
    return result
end

_G.GamsteronCore = __GamsteronCore()

_G.TickAction = function(cb, remainingTime)
    TableInsert(TickActions, { cb, GameTimer() + remainingTime })
end

function AddLoadCallback(cb)
    TableInsert(OnLoadC, cb)
end

Callback.Add("Load", function()
    for i, cb in pairs(OnLoadC) do
        cb()
    end
    --Maxxxel
    _G.drawCircleQuality = 22
    _G.clickerSleepDelay = 0
    --Maxxxel
    for i = 1, GameObjectCount() do
        local obj = GameObject(i)
        if obj then
            local t = obj.type
            if Structures[t] then
                if t == Obj_AI_Barracks then
                    if obj.isEnemy then
                        TableInsert(EnemyInhibitors, obj)
                    elseif obj.isAlly then
                        TableInsert(AllyInhibitors, obj)
                    end
                elseif t == Obj_AI_Turret then
                    if obj.isEnemy then
                        TableInsert(EnemyTurrets, obj)
                    elseif obj.isAlly then
                        TableInsert(AllyTurrets, obj)
                    end
                elseif t == Obj_AI_Nexus then
                    if obj.isEnemy then
                        EnemyNexus = obj
                    elseif obj.isAlly then
                        AllyNexus = obj
                    end
                end
            end
        end
    end
    Callback.Add("Tick", function()
        if HeroesLoad.Count >= 10 then return end
        for i = 1, GameHeroCount() do
            local obj = GameHero(i)
            if obj then
                local id = obj.networkID
                if id and id > 0 and HeroesLoad.Heroes[id] == nil then
                    HeroesLoad.Count = HeroesLoad.Count + 1
                    HeroesLoad.Heroes[id] = true
                    if obj.isAlly then
                        for i, cb in pairs(HeroesLoad.OnAllyHeroLoadC) do
                            cb(obj)
                        end
                        TableInsert(AllyHeroes, obj)
                    else
                        for i, cb in pairs(HeroesLoad.OnEnemyHeroLoadC) do
                            cb(obj)
                        end
                        TableInsert(EnemyHeroes, obj)
                    end
                end
            end
        end
    end)
    Callback.Add("Draw", function()
        if _G.GamsteronDebug then
            local status, err = pcall(function()
                for i, action in pairs(TickActions) do if GameTimer() > action[2] or action[1]() == true then TableRemove(TickActions, i) end end
            end)
            if not status then print("CallbackDraw(): " .. tostring(err)) end
        else
            for i, action in pairs(TickActions) do if GameTimer() > action[2] or action[1]() == true then TableRemove(TickActions, i) end end
        end
    end)
end)

_G.GamsteronCoreLoaded = true
