--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Initialize:                                                                                                                                          
    -- Return if loaded:                                                                                                                                
        if _G.GamsteronCoreLoaded then
            return
        end
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    -- Auto Updater:                                                                                                                                    
        local function DownloadFile(url, path)
            DownloadFileAsync(url, path, function() end)
            while not FileExist(path) do end
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local function Trim(s)
            local from = s:match"^%s*()"
            return from > #s and "" or s:match(".*%S", from)
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local function ReadFile(path)
            local file = io.open(path, "r")
            local result = {}
            local i = 0
            if file then
                for line in file:lines() do
                    if #Trim(line) > 0 then
                        i = i + 1
                        result[i] = line
                    end
                end
                file:close()
            end
            return result
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local function AutoUpdate(args)
            DownloadFile(args.versionUrl, args.versionPath)
            local fileResult = ReadFile(args.versionPath)
            local newVersion = tonumber(fileResult[1])
            ------------------------------------------------------------------------------------------------------------------------------------------------
            if newVersion > args.version then
                DownloadFile(args.scriptUrl, args.scriptPath)
                return true, newVersion
            end
            return false, args.version
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local _Update = false
        ------------------------------------------------------------------------------------------------------------------------------------------------
        if _Update then
            local args =
            {
                version = 0.01,
                ----------------------------------------------------------------------------------------------------------------------------------------
                scriptPath = COMMON_PATH .. "GamsteronCore.lua",
                scriptUrl = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Common/GamsteronCore.lua",
                ----------------------------------------------------------------------------------------------------------------------------------------
                versionPath = COMMON_PATH .. "GamsteronCore.version",
                versionUrl = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Common/GamsteronCore.version"
            }
            --------------------------------------------------------------------------------------------------------------------------------------------
            local success, version = AutoUpdate(args)
            --------------------------------------------------------------------------------------------------------------------------------------------
            if success then
                print("GamsteronCore updated to version " .. version .. ". Please Reload with 2x F6 !")
                _G.GamsteronCoreUpdated = true
            end
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        if _G.GamsteronCoreUpdated then
            return
        end
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Locals:                                                                                                                                              
    -- Lua Globals:                                                                                                                                     
        local MathSqrt                  = _G.math.sqrt
        local MathMax                   = _G.math.max
        local MathAbs                   = _G.math.abs
        local MathHuge                  = _G.math.huge
        local MathPI                    = _G.math.pi
        local MathAtan                  = _G.math.atan
        local MathMin                   = _G.math.min
        local MathSin                   = _G.math.sin
        local MathCos                   = _G.math.cos
        local TableInsert               = _G.table.insert
        local TableRemove               = _G.table.remove
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    -- Gos Globals:                                                                                                                                     
        local myHero                    = _G.myHero
        local GetTickCount              = _G.GetTickCount
        local GameTimer                 = _G.Game.Timer
        local GameParticleCount         = _G.Game.ParticleCount
        local GameParticle              = _G.Game.Particle
        local GameHeroCount             = _G.Game.HeroCount
        local GameHero                  = _G.Game.Hero
        local GameMinionCount           = _G.Game.MinionCount
        local GameMinion                = _G.Game.Minion
        local GameTurretCount           = _G.Game.TurretCount
        local GameTurret                = _G.Game.Turret
        local GameWardCount             = _G.Game.WardCount
        local GameWard                  = _G.Game.Ward
        local GameObjectCount           = _G.Game.ObjectCount
        local GameObject                = _G.Game.Object
        local GameMissileCount          = _G.Game.MissileCount
        local GameMissile               = _G.Game.Missile
        local CallbackAdd               = _G.Callback.Add
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    -- Champions:                                                                                                                                       
        -- Yasuo:                                                                                                                                       
            local IsYasuo                   = false
            local Yasuo                     = { Wall = nil, Name = nil, Level = 0, CastTime = 0, StartPos = nil }
        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- Hero Data:                                                                                                                                   
            local HeroData                  = {}
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    -- Objects:                                                                                                                                         
        local AllyNexus                 = nil
        local EnemyNexus                = nil
        local AllyInhibitors            = {}
        local EnemyInhibitors           = {}
        local AllyTurrets               = {}
        local EnemyTurrets              = {}
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    -- Actions:                                                                                                                                         
        local DelayedActions = {}
        local TickActions = {}
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    -- Callbacks:                                                                                                                                       
        -- General:                                                                                                                                     
            local GeneralLoaded             = false
            local GeneralLoadTimers         = { EndTime = 0, Active = false }
            local AddedCallbacks            = {}
            local DeletedCallbacks          = {}
            local OnLoadC                   = {}
            local OnUnLoadC                 = {}
            local OnGameEndC                = {}
            local OnTickC                   = {}
            local OnDrawC                   = {}
            local OnWndMsgC                 = {}
            local OnRecallC                 = {}
        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- Buildings Load:                                                                                                                              
            local BuildingsLoaded           = false
            local BuildingsLoad             =
            {
                Performance                 = 0,
                StartTime                   = 0,
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
        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- Heroes Load:                                                                                                                                 
            local HeroesLoaded              = false
            local HeroesLoad                =
            {
                Performance                 = 0,
                StartTime                   = 0,
                EndTime                     = 0,
                Count                       = 0,
                Heroes                      = {},
                OnEnemyHeroLoadC            = {},
                OnAllyHeroLoadC             = {}
            }
        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- Heroes Data:                                                                                                                                 
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
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants:                                                                                                                                           
    -- Spell Cast Type:                                                                                                                                 
        local SPELLCAST_ATTACK          = 0
        local SPELLCAST_DASH            = 1
        local SPELLCAST_IMMOBILE        = 2
        local SPELLCAST_OTHER           = 3
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    -- Unit Team:                                                                                                                                       
        local TEAM_ALLY                 = myHero.team
        local TEAM_ENEMY                = 300 - TEAM_ALLY
        local TEAM_JUNGLE               = 300
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    -- Latency:                                                                                                                                         
        local LATENCY                   = 0
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    -- Static Data:                                                                                                                                     
        local ItemSlots =
        {
			ITEM_1,
			ITEM_2,
			ITEM_3,
			ITEM_4,
			ITEM_5,
			ITEM_6,
			ITEM_7
		}
        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- Buffs:                                                                                                                                       
            local UNDYING_BUFFS             =                                                                                                                   
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
            local STUN_BUFFS                =                                                                                                                   
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
            local SLOW_BUFFS                =                                                                                                                   
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
            local DASH_BUFFS                =                                                                                                                   
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
        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- Spells:                                                                                                                                      
            local STUN_SPELLS               =                                                                                                                   
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
            local DASH_SPELLS               =                                                                                                                   
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
            local ATTACK_SPELLS             =                                                                                                                   
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
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Menu:                                                                                                                                                
    local Menu = MenuElement({name = "Gamsteron Core", id = "gsocore", type = _G.MENU })
        Menu:MenuElement({id = "ping", name = "Your Ping", value = 50, min = 0, max = 150, step = 5, callback = function(value) LATENCY = value * 0.001 end })
        LATENCY = Menu.ping:Value() * 0.001
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- _G.GamsteronCore:                                                                                                                                    
    -- Local Methods:                                                                                                                                   
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
        local function IsInRange(vec1, vec2, range)
            local dx = vec1.x - vec2.x
            local dy = vec1.y - vec2.y
            return dx * dx + dy * dy <= range * range
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
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
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local function GetWaypoints(unit, unitID)
            local result = {}
            if unit.visible then
                TableInsert(result, To2D(unit.pos))
                local path = unit.pathing
                for i = path.pathIndex, path.pathCount do
                    TableInsert(result, To2D(unit:GetPath(i)))
                end
            else
                local data = HeroData[unitID]
                if data and data.IsMoving and GameTimer() < data.GainVisionTimer + 0.5 then
                    result = data.Path
                end
            end
            return result
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local function Detector(unit, unitID)
            -- active:                                                                                                                                  
                if not HeroData[unitID] then
                    HeroData[unitID] =
                    {
                        ActiveItems = {},
                        ActiveBuffs = {},
                        ActiveSpells = {},
                        IsMoving = false,
                        IsVisible = false,
                        EndPos = To2D(unit.pathing.endPos),
                        Path = GetWaypoints(unit, unitID),
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
            --------------------------------------------------------------------------------------------------------------------------------------------
            -- pathing:                                                                                                                                 
                if unit.visible then
                    local path = unit.pathing
                    local startpos = To2D(unit.pos)
                    local endpos = To2D(path.endPos)
                    if not IsInRange(startpos, endpos, 50) and not IsInRange(data.EndPos, endpos, 10) then
                        HeroData[unitID].LastMoveTimer = GameTimer()
                        HeroData[unitID].EndPos = endpos
                        local currentPath = GetWaypoints(unit, unitID)
                        for i, p in pairs(data.Path) do
                            TableRemove(HeroData[unitID].Path, i)
                        end
                        HeroData[unitID].Path = currentPath
                        --------------------------------------------------------------------------------------------------------------------------------
                        -- On Process Waypoint:
                            for i, cb in pairs(OnProcessWaypointC) do
                                cb(unit, { path = currentPath, endPos = endpos }, true)
                            end
                        --------------------------------------------------------------------------------------------------------------------------------
                    end
                    if path.hasMovePath ~= data.IsMoving then
                        HeroData[unitID].IsMoving = path.hasMovePath
                        if not path.hasMovePath then
                            HeroData[unitID].StopMoveTimer = GameTimer()
                            ----------------------------------------------------------------------------------------------------------------------------
                            -- On Process Waypoint:
                                for i, cb in pairs(OnProcessWaypointC) do
                                    cb(unit, { path = { startpos }, endPos = startpos }, false)
                                end
                            ----------------------------------------------------------------------------------------------------------------------------
                        end
                    end
                    HeroData[unitID].GainVisionTimer = GameTimer()
                    ------------------------------------------------------------------------------------------------------------------------------------
                    -- On Gain Vision:
                        if not data.IsVisible then
                            for i, cb in pairs(OnGainVisionC) do
                                cb(unit)
                            end
                            HeroData[unitID].IsVisible = true
                        end
                    ------------------------------------------------------------------------------------------------------------------------------------
                else
                    HeroData[unitID].LostVisionTimer = GameTimer()
                    ------------------------------------------------------------------------------------------------------------------------------------
                    -- On Lose Vision:
                        if data.IsVisible then
                            for i, cb in pairs(OnLoseVisionC) do
                                cb(unit)
                            end
                            HeroData[unitID].IsVisible = false
                        end
                    ------------------------------------------------------------------------------------------------------------------------------------
                end
            --------------------------------------------------------------------------------------------------------------------------------------------
            -- buffs:                                                                                                                                   
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
                            ----------------------------------------------------------------------------------------------------------------------------
                            -- On Update Buff:                                                                                                          
                                for i, cb in pairs(OnUpdateBuffC) do
                                    cb(unit, buff)
                                end
                            ----------------------------------------------------------------------------------------------------------------------------
                            if DASH_BUFFS[name] then
                                if duration > HeroData[unitID].RemainingDash then HeroData[unitID].RemainingDash = duration end
                            ----------------------------------------------------------------------------------------------------------------------------
                            elseif STUN_BUFFS[name] then
                                ------------------------------------------------------------------------------------------------------------------------
                                -- On Process Recall:                                                                                                   
                                    if name == "recall" then
                                        for i, cb in pairs(OnProcessRecallC) do
                                            cb(unit, buff)
                                        end
                                    end
                                ------------------------------------------------------------------------------------------------------------------------
                                if duration > HeroData[unitID].RemainingImmobile then HeroData[unitID].RemainingImmobile = duration end
                            ----------------------------------------------------------------------------------------------------------------------------
                            elseif SLOW_BUFFS[name] then
                                if duration > HeroData[unitID].RemainingSlow then HeroData[unitID].RemainingSlow = duration end
                            ----------------------------------------------------------------------------------------------------------------------------
                            else
                                local immortal = UNDYING_BUFFS[name]
                                if immortal and (immortal == 100 or immortal >= 100 * unit.health / unit.maxHealth) then
                                    if duration > HeroData[unitID].RemainingImmortal then HeroData[unitID].RemainingImmortal = duration end
                                end
                            end
                        end
                    end
                end
                local OldBuffs = data.ActiveBuffs
                ----------------------------------------------------------------------------------------------------------------------------------------
                -- On Create Buff:
                    for i, newBuff in pairs(ActiveBuffs) do
                        local buffCreated = true
                        --------------------------------------------------------------------------------------------------------------------------------
                        for j, oldBuff in pairs(OldBuffs) do
                            if newBuff.name == oldBuff then
                                buffCreated = false
                                break
                            end
                        end
                        --------------------------------------------------------------------------------------------------------------------------------
                        if buffCreated then
                            for k, cb in pairs(OnCreateBuffC) do
                                cb(unit, newBuff.buff)
                            end
                        end
                    end
                ----------------------------------------------------------------------------------------------------------------------------------------
                -- On Remove Buff:
                    for i, oldBuffName in pairs(OldBuffs) do
                        local buffRemoved = true
                        --------------------------------------------------------------------------------------------------------------------------------
                        for j, newBuff in pairs(ActiveBuffs) do
                            if newBuff.name == oldBuffName then
                                buffRemoved = false
                                break
                            end
                        end
                        --------------------------------------------------------------------------------------------------------------------------------
                        if buffRemoved then
                            for k, cb in pairs(OnRemoveBuffC) do
                                cb(unit, oldBuffName)
                            end
                        end
                    end
                ----------------------------------------------------------------------------------------------------------------------------------------
                for i, oldBuff in pairs(OldBuffs) do TableRemove(HeroData[unitID].ActiveBuffs, i) end
                ----------------------------------------------------------------------------------------------------------------------------------------
                for i, activeBuff in pairs(ActiveBuffs) do TableInsert(HeroData[unitID].ActiveBuffs, activeBuff) end
            --------------------------------------------------------------------------------------------------------------------------------------------
            -- spells:                                                                                                                                  
                local spell = unit.activeSpell
                if spell and spell.valid then
                    local name = spell.name
                    if name and #name > 0 then
                        local startTime = spell.startTime
                        local activeSpells = data.ActiveSpells
                        if not activeSpells[name] or startTime > activeSpells[name].startTime then
                            local endTime, spellCastType
                            if not unit.isChanneling or ATTACK_SPELLS[name] then
                                endTime = spell.castEndTime
                                if endTime > GameTimer() and endTime > data.ExpireImmobile then
                                    HeroData[unitID].ExpireImmobile = endTime
                                end
                                spellCastType = SPELLCAST_ATTACK
                            elseif DASH_SPELLS[name] then
                                local delay = DASH_SPELLS[name]
                                endTime = delay == -1 and (spell.castEndTime) or (startTime + delay)
                                if endTime > GameTimer() and endTime > data.ExpireDash then
                                    HeroData[unitID].ExpireDash = endTime
                                end
                                spellCastType = SPELLCAST_DASH
                            elseif STUN_SPELLS[name] then
                                local delay = STUN_SPELLS[name]
                                endTime = delay == -1 and (spell.castEndTime) or (startTime + delay)
                                if endTime > GameTimer() and endTime > data.ExpireImmobile then
                                    HeroData[unitID].ExpireImmobile = endTime
                                end
                                spellCastType = SPELLCAST_IMMOBILE
                            else
                                endTime = spell.castEndTime
                                spellCastType = SPELLCAST_OTHER
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
                                if not activeSpells[name].completed and activeSpells[name].type == SPELLCAST_ATTACK and GameTimer() < activeSpells[name].castEndTime then
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
                                if not args.completed and args.type == SPELLCAST_ATTACK and GameTimer() < args.castEndTime and name ~= name2 then
                                    HeroData[unitID].ActiveSpells[name2].completed = true
                                    HeroData[unitID].ActiveSpells[name2].endTime = GameTimer()
                                    for j = 1, #OnCancelAttackC do
                                        OnCancelAttackC[j](unit, args)
                                    end
                                end
                            end
                            ----------------------------------------------------------------------------------------------------------------------------
                            -- On Process Spell Cast:                                                                                                   
                                for i, cb in pairs(OnProcessSpellCastC) do
                                    cb(unit, spell, spellCastType)
                                end
                            ----------------------------------------------------------------------------------------------------------------------------
                        end
                    end
                end
                ----------------------------------------------------------------------------------------------------------------------------------------
                -- On Process Spell Complete:
                    local activeSpells = data.ActiveSpells
                    for name, args in pairs(activeSpells) do
                        if not args.completed then
                            local currentTimer = GameTimer()
                            if args.type == SPELLCAST_ATTACK and unit.pathing.hasMovePath and currentTimer < args.castEndTime then
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
            --------------------------------------------------------------------------------------------------------------------------------------------
            -- Items:                                                                                                                                   
                for i = #data.ActiveItems, 1, -1 do
                    TableRemove(data.ActiveItems, i)
                end
                for i = 1, #ItemSlots do
                    local slot = ItemSlots[i]
                    local item = unit:GetItemData(slot)
                    if item ~= nil then
                        TableInsert(HeroData[unitID].ActiveItems, { item = item, slot = slot })
                    end
                end
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local function YasuoWallTick(unit)
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
                                    Yasuo.StartPos = To2D(obj.pos)
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
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local function IsYasuoWall()
            if not IsYasuo or Yasuo.Wall == nil then return false end
            --------------------------------------------------------------------------------------------------------------------------------------------
            if Yasuo.Name == nil or Yasuo.Wall.name == nil or Yasuo.Name ~= Yasuo.Wall.name or Yasuo.StartPos == nil then
                Yasuo.Wall = nil
                return false
            end
            --------------------------------------------------------------------------------------------------------------------------------------------
            return true
        end
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    -- Initialize:                                                                                                                                      
        local Core = Class()
        function Core:__init()
            self.COLLISION_MINION           = 0
            self.COLLISION_ALLYHERO         = 1
            self.COLLISION_ENEMYHERO        = 2
            self.COLLISION_YASUOWALL        = 3
            --------------------------------------------------------------------------------------------------------------------------------------------
            self.SPELLCAST_ATTACK           = 0
            self.SPELLCAST_DASH             = 1
            self.SPELLCAST_IMMOBILE         = 2
            self.SPELLCAST_OTHER            = 3                                                                                                                            
            --------------------------------------------------------------------------------------------------------------------------------------------
            self.TEAM_ALLY                  = myHero.team
            self.TEAM_ENEMY                 = 300 - TEAM_ALLY
            self.TEAM_JUNGLE                = 300
        end
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    -- Get Latency:                                                                                                                                     
        function Core:GetLatency()
            return LATENCY
        end
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    -- Callbacks:                                                                                                                                       
        -- Buildings Load:                                                                                                                              
            function Core:OnAllyNexusLoad(cb)
                TableInsert(BuildingsLoad.OnAllyNexusLoadC, cb)
            end
            --------------------------------------------------------------------------------------------------------------------------------------------
            function Core:OnAllyInhibitorLoad(cb)
                TableInsert(BuildingsLoad.OnAllyInhibitorLoadC, cb)
            end
            --------------------------------------------------------------------------------------------------------------------------------------------
            function Core:OnAllyTurretLoad(cb)
                TableInsert(BuildingsLoad.OnAllyTurretLoadC, cb)
            end
            --------------------------------------------------------------------------------------------------------------------------------------------
            function Core:OnEnemyNexusLoad(cb)
                TableInsert(BuildingsLoad.OnEnemyNexusLoadC, cb)
            end
            --------------------------------------------------------------------------------------------------------------------------------------------
            function Core:OnEnemyInhibitorLoad(cb)
                TableInsert(BuildingsLoad.OnEnemyInhibitorLoadC, cb)
            end
            --------------------------------------------------------------------------------------------------------------------------------------------
            function Core:OnEnemyTurretLoad(cb)
                TableInsert(BuildingsLoad.OnEnemyTurretLoadC, cb)
            end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- Heroes Load:                                                                                                                                 
            function Core:OnEnemyHeroLoad(cb)
                TableInsert(HeroesLoad.OnEnemyHeroLoadC, cb)
            end
            --------------------------------------------------------------------------------------------------------------------------------------------
            function Core:OnAllyHeroLoad(cb)
                TableInsert(HeroesLoad.OnAllyHeroLoadC, cb)
            end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- Heroes Data:                                                                                                                                 
            function Core:OnProcessRecall(cb)
                TableInsert(OnProcessRecallC, cb)
            end
            --------------------------------------------------------------------------------------------------------------------------------------------
            function Core:OnProcessSpellCast(cb)
                TableInsert(OnProcessSpellCastC, cb)
            end
            --------------------------------------------------------------------------------------------------------------------------------------------
            function Core:OnProcessSpellComplete(cb)
                TableInsert(OnProcessSpellCompleteC, cb)
            end
            --------------------------------------------------------------------------------------------------------------------------------------------
            function Core:OnProcessWaypoint(cb)
                TableInsert(OnProcessWaypointC, cb)
            end
            --------------------------------------------------------------------------------------------------------------------------------------------
            function Core:OnCancelAttack(cb)
                TableInsert(OnCancelAttackC, cb)
            end
            --------------------------------------------------------------------------------------------------------------------------------------------
            function Core:OnUpdateBuff(cb)
                TableInsert(OnUpdateBuffC, cb)
            end
            --------------------------------------------------------------------------------------------------------------------------------------------
            function Core:OnCreateBuff(cb)
                TableInsert(OnCreateBuffC, cb)
            end
            --------------------------------------------------------------------------------------------------------------------------------------------
            function Core:OnRemoveBuff(cb)
                TableInsert(OnRemoveBuffC, cb)
            end
            --------------------------------------------------------------------------------------------------------------------------------------------
            function Core:OnGainVision(cb)
                TableInsert(OnGainVisionC, cb)
            end
            --------------------------------------------------------------------------------------------------------------------------------------------
            function Core:OnLoseVision(cb)
                TableInsert(OnLoseVisionC, cb)
            end
            --------------------------------------------------------------------------------------------------------------------------------------------
            function Core:OnIssueOrder(cb)
                TableInsert(OnIssueOrderC, cb)
            end
            --------------------------------------------------------------------------------------------------------------------------------------------
            function Core:OnSpellCast(cb)
                TableInsert(OnSpellCastC, cb)
            end
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    -- Objects:                                                                                                                                         
        function Core:GetAllyNexus()
            return AllyNexus
        end
        function Core:GetEnemyNexus()
            return EnemyNexus
        end
        function Core:GetAllyInhibitors()
            return AllyInhibitors
        end
        function Core:GetEnemyInhibitors()
            return EnemyInhibitors
        end
        function Core:GetAllyTurrets()
            return AllyTurrets
        end
        function Core:GetEnemyTurrets()
            return EnemyTurrets
        end
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    -- Get Hero Data:                                                                                                                                   
        function Core:GetHeroData(unit)
            unit = unit or myHero
            --------------------------------------------------------------------------------------------------------------------------------------------
            local unitID = unit.networkID
            --------------------------------------------------------------------------------------------------------------------------------------------
            Detector(unit, unitID)
            --------------------------------------------------------------------------------------------------------------------------------------------
            return HeroData[unitID]
        end
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    -- Is Yasuo Wall Collision:                                                                                                                         
        function Core:IsYasuoWallCollision(startPos, endPos, speed, delay)
            if not IsYasuo or not IsYasuoWall() then return false end
            --------------------------------------------------------------------------------------------------------------------------------------------
            local Pos = To2D(Yasuo.Wall.pos)
            local Width = 300 + 50 * Yasuo.Level
            local Direction = self:Perpendicular(self:Normalized(Pos, Yasuo.StartPos))
            local StartPos = self:Extended(Pos, Direction, Width / 2)
            local EndPos = self:Extended(StartPos, Direction, -Width)
            local IntersectionResult = self:Intersection(StartPos, EndPos, endPos, startPos)
            if IntersectionResult.Intersects then
                local t = delay + GetDistance(IntersectionResult.Point, startPos) / speed
                if GameTimer() + t < Yasuo.CastTime + 4 then
                    return true
                end
            end
            --------------------------------------------------------------------------------------------------------------------------------------------
            return false
        end
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    -- Class:                                                                                                                                           
        function Core:Class()
            return Class()
        end
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    -- Vector2D:                                                                                                                                        
        function Core:To2D(vec)
            return { x = vec.x, y = vec.z or vec.y }
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        function Core:GetDistance(vec1, vec2)
            local dx = vec1.x - vec2.x
            local dy = vec1.y - vec2.y
            return MathSqrt(dx * dx + dy * dy)
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        function Core:GetDistanceSquared(vec1, vec2)
            local dx = vec1.x - vec2.x
            local dy = vec1.y - vec2.y
            return dx * dx + dy * dy
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        function Core:IsInRange(vec1, vec2, range)
            local dx = vec1.x - vec2.x
            local dy = vec1.y - vec2.y
            return dx * dx + dy * dy <= range * range
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- AngleBetween:                                                                                                                                
            function Core:Close(a, b, eps)
                if eps == 0 then
                    eps = 1E-9
                end
                return MathAbs(a - b) <= eps
            end
            --------------------------------------------------------------------------------------------------------------------------------------------
            function Core:RadianToDegree(angle)
                return angle * (180.0 / MathPI)
            end
            --------------------------------------------------------------------------------------------------------------------------------------------
            function Core:Polar(v1)
                if self:Close(v1.x, 0, 0) then
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
            --------------------------------------------------------------------------------------------------------------------------------------------
            function Core:AngleBetween(vec1, vec2)
                local theta = self:Polar(vec1) - self:Polar(vec2)
                if theta < 0 then
                    theta = theta + 360
                end
                if theta > 180 then
                    theta = 360 - theta
                end
                return theta
            end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        function Core:EqualVector(vec1, vec2)
            local diffX = vec1.x - vec2.x
            local diffY = vec1.y - vec2.y
            return diffX >= -10 and diffX <= 10 and diffY >= -10 and diffY <= 10
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        function Core:EqualDirection(vec1, vec2)
            return self:AngleBetween(vec1, vec2) <= 5
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        function Core:Normalized(vec1, vec2)
            local vec = { x = vec1.x - vec2.x, y = vec1.y - vec2.y }
            local length = MathSqrt(vec.x * vec.x + vec.y * vec.y)
            if length > 0 then
                local inv = 1.0 / length
                return { x = vec.x * inv, y = vec.y * inv }
            end
            return nil
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        function Core:Extended(vec, dir, range)
            if dir == nil then return vec end
            return { x = vec.x + dir.x * range, y = vec.y + dir.y * range }
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        function Core:Perpendicular(dir)
            if dir == nil then return nil end
            return { x = -dir.y, y = dir.x }
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        function Core:ProjectOn(p, p1, p2)
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
        ------------------------------------------------------------------------------------------------------------------------------------------------
        function Core:AddVectors(vec1, vec2, mulitplier)
            mulitplier = mulitplier or 1
            local x = vec1.x + vec2.x
            local y = vec1.y + vec2.y
            return {
                x = x * mulitplier,
                y = y * mulitplier
            }
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        function Core:SubVectors(vec1, vec2, mulitplier)
            mulitplier = mulitplier or 1
            local x = vec1.x - vec2.x
            local y = vec1.y - vec2.y
            return {
                x = x * mulitplier,
                y = y * mulitplier
            }
        end
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    -- Collision:                                                                                                                                       
        function Core:PathLength(path)
            local result = 0
            for i = 1, #path - 1 do
                result = result + GetDistance(path[i], path[i + 1])
            end
            return result
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        function Core:CutPath(path, distance)
            local result = {}
            local Distance = distance
            if distance < 0 then
                path[1] = self:Extended(path[1], self:Normalized(path[2], path[1]), distance)
                return path
            end
            for i = 1, #path - 1 do
                local dist = GetDistance(path[i], path[i + 1])
                if dist > Distance then
                    TableInsert(result, self:Extended(path[i], self:Normalized(path[i+1], path[i]), Distance))
                    for j = i + 1, #path do
                        TableInsert(result, path[j])
                    end
                    break
                end
                Distance = Distance - dist
            end
            return #result > 0 and result or path[#path]
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        function Core:GetWaypoints(unit, unitID)
            local result = {}
            if unit.visible then
                TableInsert(result, To2D(unit.pos))
                local path = unit.pathing
                for i = path.pathIndex, path.pathCount do
                    TableInsert(result, To2D(unit:GetPath(i)))
                end
            else
                local data = HeroData[unitID]
                if data and data.IsMoving and GameTimer() < data.GainVisionTimer + 0.5 then
                    result = data.Path
                end
            end
            return result
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        function Core:GetCollisionWaypoints(unit)
            local result = {}
            TableInsert(result, To2D(unit.pos))
            local path = unit.pathing
            for i = path.pathIndex, path.pathCount do
                TableInsert(result, To2D(unit:GetPath(i)))
            end
            return result
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        function Core:VectorMovementCollision(startPoint1, endPoint1, v1, startPoint2, v2, delay)
            local sP1x = startPoint1.x
            local sP1y = startPoint1.y
            local eP1x = endPoint1.x
            local eP1y = endPoint1.y
            local sP2x = startPoint2.x
            local sP2y = startPoint2.y
            local d = eP1x - sP1x
            local e = eP1y - sP1y
            local dist = MathSqrt(d * d + e * e)
            local t1 = nil
            local S, K
            if dist > 0 then
                S = v1 * d / dist
                K = v1 * e / dist
            else
                S = 0
                K = 0
            end
            local r = sP2x - sP1x
            local j = sP2y - sP1y
            local c = r * r + j * j
            if dist > 0 then
                if v1 == MathHuge then
                    local t = dist / v1
                    if v2 * t >= 0 then
                        t1 = t
                    end
                elseif v2 == MathHuge then
                    t1 = 0
                else
                    local a = S * S + K * K - v2 * v2
                    local b = -r * S - j * K
                    if a == 0 then
                        if b == 0 then
                            if c == 0 then
                                t1 = 0
                            end
                        else
                            local t = -c / (2 * b)
                            if v2 * t >= 0 then
                                t1 = t
                            end
                        end
                    else
                        local sqr = b * b - a * c
                        if sqr >= 0 then
                            local nom = MathSqrt(sqr)
                            local t = (-nom - b) / a
                            if v2 * t >= 0 then
                                t1 = t
                            end
                            t = (nom - b) / a
                            local t2 = nil
                            if v2 * t >= 0 then
                                t2 = t
                            end
                            if t1 ~= nil and t2 ~= nil then
                                if t1 >= delay and t2 >= delay then
                                    t1 = MathMin(t1, t2)
                                elseif t2 >= delay then
                                    t1 = t2
                                end
                            end
                        end
                    end
                end
            elseif dist == 0 then
                t1 = 0
            end
            local interceptPos = nil
            if t1 ~= nil then
                interceptPos =
                {
                    x = sP1x + S * t1,
                    y = sP1y + K * t1
                }
            end
            return t1, interceptPos
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        function Core:GetInterceptionTime(source, startP, endP, unitspeed, spellspeed)
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
        ------------------------------------------------------------------------------------------------------------------------------------------------
        function Core:Intersection(lineSegment1Start, lineSegment1End, lineSegment2Start, lineSegment2End)
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
        ------------------------------------------------------------------------------------------------------------------------------------------------
        function Core:GetCollisionPrediction(unit, from, spellspeed, spelldelay)
            -----------------------------------------------------------------------------------------------------------------------------
            local path = self:GetCollisionWaypoints(unit)
            local pathCount = #path
            -----------------------------------------------------------------------------------------------------------------------------
            if pathCount == 1 or not unit.pathing.hasMovePath then
                return false, To2D(unit.pos)
            end
            -----------------------------------------------------------------------------------------------------------------------------
            local speed = unit.ms
            if pathCount > 1 and self:PathLength(path) > spelldelay * speed then
                if spellspeed == MathHuge then
                    local tDistance = (spelldelay * speed)
                    for i = 1, #path - 1 do
                        local a = path[i]
                        local b = path[i + 1]
                        local d = GetDistance(a, b)
                        if d >= tDistance then
                            local direction = self:Normalized(b, a)
                            local cp = self:Extended(a, direction, tDistance)
                            return true, cp
                        end
                        tDistance = tDistance - d
                    end
                else
                    local d = (spelldelay * speed)
                    path = self:CutPath(path, d)
                    local tT = 0
                    for i = 1, #path - 1 do
                        local a = path[i]
                        local b = path[i + 1]
                        local tB = GetDistance(a, b) / speed
                        local direction = self:Normalized(b, a)
                        if tT ~= 0 then
                            a = self:Extended(a, direction, -(speed * tT))
                        end
                        local t, pos = self:VectorMovementCollision(a, b, speed, from, spellspeed, tT)
                        if t ~= nil and t >= tT and t <= tT + tB then
                            return true, pos
                        end
                        tT = tT + tB
                    end
                end
            end
            return true, path[#path]
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        function Core:GetCollision(from, to, speed, delay, radius, collisionObjects, objectsList)
            local result = {}
            for i = 1, #collisionObjects do
                local objectType = collisionObjects[i]
                ----------------------------------------------------------------------------------------------------------------------------------------
                if objectType == self.COLLISION_MINION then
                    local objects = objectsList.enemyMinions
                    for k = 1, #objects do
                        local object = objects[k]
                        local HasMovePath, CastPos = self:GetCollisionPrediction(object, from, speed, delay)
                        local isOnSegment, pointSegment, pointLine = self:ProjectOn(CastPos, from, to)
                        local IsCollisionable = false
                        if IsInRange(CastPos, pointSegment, radius + 30 + object.boundingRadius) then
                            TableInsert(result, object)
                            IsCollisionable = true
                        end
                        if HasMovePath and not IsCollisionable then
                            local objectPos = To2D(object.pos)
                            isOnSegment, pointSegment, pointLine = self:ProjectOn(objectPos, from, to)
                            if IsInRange(objectPos, pointSegment, radius + 30 + object.boundingRadius) then
                                TableInsert(result, object)
                            end
                        end
                    end
                ----------------------------------------------------------------------------------------------------------------------------------------
                elseif objectType == self.COLLISION_ENEMYHERO then
                    local objects = objectsList.enemyHeroes
                    for k = 1, #objects do
                        local object = objects[k]
                        local HasMovePath, CastPos = self:GetCollisionPrediction(object, from, speed, delay)
                        local isOnSegment, pointSegment, pointLine = self:ProjectOn(CastPos, from, to)
                        local IsCollisionable = false
                        if IsInRange(CastPos, pointSegment, radius + 30 + object.boundingRadius) then
                            TableInsert(result, object)
                            IsCollisionable = true
                        end
                        if HasMovePath and not IsCollisionable then
                            local objectPos = To2D(object.pos)
                            isOnSegment, pointSegment, pointLine = self:ProjectOn(objectPos, from, to)
                            if IsInRange(objectPos, pointSegment, radius + 30 + object.boundingRadius) then
                                TableInsert(result, object)
                            end
                        end
                    end
                ----------------------------------------------------------------------------------------------------------------------------------------
                elseif objectType == self.COLLISION_ALLYHERO then
                    local objects = objectsList.allyHeroes
                    for k = 1, #objects do
                        local object = objects[k]
                        local HasMovePath, CastPos = self:GetCollisionPrediction(object, from, speed, delay)
                        local isOnSegment, pointSegment, pointLine = self:ProjectOn(CastPos, from, to)
                        local IsCollisionable = false
                        if IsInRange(CastPos, pointSegment, radius + 30 + object.boundingRadius) then
                            TableInsert(result, object)
                            IsCollisionable = true
                        end
                        if HasMovePath and not IsCollisionable then
                            local objectPos = To2D(object.pos)
                            isOnSegment, pointSegment, pointLine = self:ProjectOn(objectPos, from, to)
                            if IsInRange(objectPos, pointSegment, radius + 30 + object.boundingRadius) then
                                TableInsert(result, object)
                            end
                        end
                    end
                ----------------------------------------------------------------------------------------------------------------------------------------
                --elseif objectType == CollisionableObjects.Walls then
                ----------------------------------------------------------------------------------------------------------------------------------------
                elseif IsYasuo and objectType == self.COLLISION_YASUOWALL and IsYasuoWall() then
                    local Pos = To2D(Yasuo.Wall.pos)
                    local Width = 300 + 50 * Yasuo.Level
                    local Direction = self:Perpendicular(self:Normalized(Pos, Yasuo.StartPos))
                    local StartPos = self:Extended(Pos, Direction, Width / 2)
                    local EndPos = self:Extended(StartPos, Direction, -Width)
                    local IntersectionResult = self:Intersection(StartPos, EndPos, to, from)
                    if IntersectionResult.Intersects then
                        local t = GameTimer() + (GetDistance(IntersectionResult.Point, from) / speed + delay)
                        if t < Yasuo.CastTime + 4 then
                            return true, { Yasuo.Wall }
                        end
                    end
                end
                ----------------------------------------------------------------------------------------------------------------------------------------
            end
            return false, result
        end
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    -- Updater:                                                                                                                                         
        function Core:AutoUpdate(args)
            local success, version = AutoUpdate(args)
            return success, version
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        function Core:DownloadFile(url, path)
            DownloadFile(url, path)
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        function Core:ReadFile(path)
            return ReadFile(path)
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        function Core:Trim(s)
            return Trim(s)
        end
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    -- Is Facing:                                                                                                                                       
        function Core:IsFacing(source, target)
            local sourceDir = To2D(source.dir)
            local targetPos = To2D(target.pos)
            local sourcePos = To2D(source.pos)
            local targetDir = self:Normalized(targetPos, sourcePos)
            if self:AngleBetween(sourceDir, targetDir) < 90 then
                local sourceEndPos = To2D(source.pathing.endPos)
                local sourceExtended = self:Extended(sourcePos, self:Normalized(sourceEndPos - sourcePos), 0.5 * source.ms)
                if not self:EqualVector(sourceExtended, sourcePos) then
                    sourceDir = self:Normalized(sourceExtended, sourcePos)
                end
                local targetEndPos = To2D(target.pathing.endPos)
                local targetExtended = self:Extended(targetPos, self:Normalized(targetEndPos - targetPos), 0.5 * target.ms)
                if self:AngleBetween(sourceDir, self:Normalized(targetExtended, sourceExtended)) < 90 then
                    return true
                end
            end
            return false
        end
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- _G.Callback .Add .Del:                                                                                                                               
    _G.Callback.Add = function(callbackType, callback)
        if callbackType == "Load" or callbackType == "UnLoad" or callbackType == "GameEnd" or callbackType == "Tick" or callbackType == "Draw" or callbackType == "WndMsg" or callbackType == "ProcessRecall" then
            local callbackID = tostring(callback)
            --------------------------------------------------------------------------------------------------------------------------------------------
            AddedCallbacks[callbackID] = callbackType
            --------------------------------------------------------------------------------------------------------------------------------------------
            if callbackType == "Load" then
                TableInsert(OnLoadC, callback)
            --------------------------------------------------------------------------------------------------------------------------------------------
            elseif callbackType == "UnLoad" then
                TableInsert(OnUnLoadC, callback)
            --------------------------------------------------------------------------------------------------------------------------------------------
            elseif callbackType == "GameEnd" then
                TableInsert(OnGameEndC, callback)
            --------------------------------------------------------------------------------------------------------------------------------------------
            elseif callbackType == "Tick" then
                TableInsert(OnTickC, callback)
            --------------------------------------------------------------------------------------------------------------------------------------------
            elseif callbackType == "Draw" then
                TableInsert(OnDrawC, callback)
            --------------------------------------------------------------------------------------------------------------------------------------------
            elseif callbackType == "WndMsg" then
                TableInsert(OnWndMsgC, callback)
            --------------------------------------------------------------------------------------------------------------------------------------------
            elseif callbackType == "ProcessRecall" then
                TableInsert(OnRecallC, callback)
            end
            --------------------------------------------------------------------------------------------------------------------------------------------
            --print(callbackType .. " added")
            return callbackID
        end
        assert(false, "Callback.Add: Wrong iType !")
    end
    _G.Callback.Del = function(callbackType, id)
        if callbackType == "Load" or callbackType == "UnLoad" or callbackType == "GameEnd" or callbackType == "Tick" or callbackType == "Draw" or callbackType == "WndMsg" or callbackType == "ProcessRecall" then
            for activeID, activeType in pairs(AddedCallbacks) do
                if activeID == id then
                    local foundItem = false
                    ------------------------------------------------------------------------------------------------------------------------------------
                    if callbackType == "Load" then
                        for i = #OnLoadC, 1, -1 do
                            if tostring(OnLoadC[i]) == activeID then
                                TableInsert(DeletedCallbacks, function() TableRemove(OnLoadC, i) end)
                                foundItem = true
                                break
                            end
                        end
                    ------------------------------------------------------------------------------------------------------------------------------------
                    elseif callbackType == "UnLoad" then
                        for i = #OnUnLoadC, 1, -1 do
                            if tostring(OnUnLoadC[i]) == activeID then
                                TableInsert(DeletedCallbacks, function() TableRemove(OnUnLoadC, i) end)
                                foundItem = true
                                break
                            end
                        end
                    ------------------------------------------------------------------------------------------------------------------------------------
                    elseif callbackType == "GameEnd" then
                        for i = #OnGameEndC, 1, -1 do
                            if tostring(OnGameEndC[i]) == activeID then
                                TableInsert(DeletedCallbacks, function() TableRemove(OnGameEndC, i) end)
                                foundItem = true
                                break
                            end
                        end
                    ------------------------------------------------------------------------------------------------------------------------------------
                    elseif callbackType == "Tick" then
                        for i = #OnTickC, 1, -1 do
                            if tostring(OnTickC[i]) == activeID then
                                TableInsert(DeletedCallbacks, function() TableRemove(OnTickC, i) end)
                                foundItem = true
                                break
                            end
                        end
                    ------------------------------------------------------------------------------------------------------------------------------------
                    elseif callbackType == "Draw" then
                        for i = #OnDrawC, 1, -1 do
                            if tostring(OnDrawC[i]) == activeID then
                                TableInsert(DeletedCallbacks, function() TableRemove(OnDrawC, i) end)
                                foundItem = true
                                break
                            end
                        end
                    ------------------------------------------------------------------------------------------------------------------------------------
                    elseif callbackType == "WndMsg" then
                        for i = #OnWndMsgC, 1, -1 do
                            if tostring(OnWndMsgC[i]) == activeID then
                                TableInsert(DeletedCallbacks, function() TableRemove(OnWndMsgC, i) end)
                                foundItem = true
                                break
                            end
                        end
                    ------------------------------------------------------------------------------------------------------------------------------------
                    elseif callbackType == "ProcessRecall" then
                        for i = #OnRecallC, 1, -1 do
                            if tostring(OnRecallC[i]) == activeID then
                                TableInsert(DeletedCallbacks, function() TableRemove(OnRecallC, i) end)
                                foundItem = true
                                break
                            end
                        end
                    end
                    ------------------------------------------------------------------------------------------------------------------------------------
                    assert(foundItem, "Callback.Del: CallbackID Not Found !")
                    ------------------------------------------------------------------------------------------------------------------------------------
                    AddedCallbacks[activeID] = nil
                    --print(callbackType .. " removed")
                    break
                end
            end
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- _G.DelayAction:                                                                                                                                      
    _G.DelayAction = function(callback, delay)
        TableInsert(DelayedActions, { callback, GameTimer() + delay })
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- _G.TickAction:                                                                                                                                       
    _G.TickAction = function(callback, remainingTime)
        TableInsert(TickActions, { callback, GameTimer() + remainingTime })
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Load:                                                                                                                                                
    TableInsert(HeroesLoad.OnEnemyHeroLoadC, function(hero)
        if charName == "Yasuo" then
            IsYasuo = true
        end
    end)
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    CallbackAdd("Load", function()
        for i, cb in pairs(OnLoadC) do
            cb()
        end
    end)
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    CallbackAdd("UnLoad", function()
        -- Return:
            if not GeneralLoaded then
                if GameTimer() > 15 then
                    if not GeneralLoadTimers.Active then
                        GeneralLoadTimers.Active = true
                        GeneralLoadTimers.EndTime = GameTimer() + 5
                        BuildingsLoad.StartTime = GameTimer() + 6
                        BuildingsLoad.EndTime = GameTimer() + 9
                        HeroesLoad.StartTime = GameTimer() + 6
                        HeroesLoad.EndTime = GameTimer() + 120
                    elseif GameTimer() > GeneralLoadTimers.EndTime then
                        GeneralLoaded = true
                    end
                end
                return
            end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        for i, cb in pairs(OnUnLoadC) do
            cb()
        end
    end)
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    CallbackAdd("GameEnd", function()
        -- Return:                                                                                                                                      
            if not GeneralLoaded then
                if GameTimer() > 15 then
                    if not GeneralLoadTimers.Active then
                        GeneralLoadTimers.Active = true
                        GeneralLoadTimers.EndTime = GameTimer() + 5
                        BuildingsLoad.StartTime = GameTimer() + 6
                        BuildingsLoad.EndTime = GameTimer() + 9
                        HeroesLoad.StartTime = GameTimer() + 6
                        HeroesLoad.EndTime = GameTimer() + 120
                    elseif GameTimer() > GeneralLoadTimers.EndTime then
                        GeneralLoaded = true
                    end
                end
                return
            end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        for i, cb in pairs(OnGameEndC) do
            cb()
        end
    end)
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    CallbackAdd("Tick", function()
        -- Return:                                                                                                                                      
            if not GeneralLoaded then
                if GameTimer() > 15 then
                    if not GeneralLoadTimers.Active then
                        GeneralLoadTimers.Active = true
                        GeneralLoadTimers.EndTime = GameTimer() + 5
                        BuildingsLoad.StartTime = GameTimer() + 6
                        BuildingsLoad.EndTime = GameTimer() + 9
                        HeroesLoad.StartTime = GameTimer() + 6
                        HeroesLoad.EndTime = GameTimer() + 120
                    elseif GameTimer() > GeneralLoadTimers.EndTime then
                        GeneralLoaded = true
                    end
                end
                return
            end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- Load Buildings:                                                                                                                              
            if not BuildingsLoaded then
                if GameTimer() > BuildingsLoad.StartTime and GameTimer() > BuildingsLoad.Performance then
                    for i = 1, GameObjectCount() do
                        local obj = GameObject(i)
                        if obj then
                            local type = obj.type
                            if type and (type == Obj_AI_Barracks or type == Obj_AI_Turret or type == Obj_AI_Nexus) then
                                local team = obj.team
                                local name = obj.name
                                if team and name and #name > 0 then
                                    local isnew = true
                                    local isally = obj.team == TEAM_ALLY
                                    ------------------------------------------------------------------------------------------------------------------------
                                    if type == Obj_AI_Barracks then
                                        for j, id in pairs(BuildingsLoad.Inhibitors) do
                                            if name == id then
                                                isnew = false
                                                break
                                            end
                                        end
                                        if isnew then
                                            if team == TEAM_ALLY then
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
                                    ------------------------------------------------------------------------------------------------------------------------
                                    elseif type == Obj_AI_Turret then
                                        if name ~= "Turret_OrderTurretShrine_A" and name ~= "Turret_ChaosTurretShrine_A" then
                                            for j, id in pairs(BuildingsLoad.Turrets) do
                                                if name == id then
                                                    isnew = false
                                                    break
                                                end
                                            end
                                            if isnew then
                                                if team == TEAM_ALLY then
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
                                    ------------------------------------------------------------------------------------------------------------------------
                                    elseif type == Obj_AI_Nexus then
                                        for j, id in pairs(BuildingsLoad.Nexuses) do
                                            if name == id then
                                                isnew = false
                                                break
                                            end
                                        end
                                        if isnew then
                                            if team == TEAM_ALLY then
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
        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- Load Heroes:                                                                                                                                 
            if not HeroesLoaded then
                if GameTimer() > HeroesLoad.StartTime and GameTimer() > HeroesLoad.Performance then
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
                                    if obj.team == TEAM_ALLY then
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
        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- Refresh Heroes Data:                                                                                                                         
            local YasuoChecked = false
            for i = 1, GameHeroCount() do
                local unit = GameHero(i)
                if unit and unit.valid then
                    Detector(unit, unit.networkID)
                    if IsYasuo and not YasuoChecked and unit.charName == "Yasuo" then
                        YasuoWallTick(unit)
                        YasuoChecked = true
                    end
                end
            end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        for i, cb in pairs(OnTickC) do
            cb()
        end
        for i, cb in pairs(DeletedCallbacks) do
            cb()
            TableRemove(DeletedCallbacks, i)
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- Delayed Actions:                                                                                                                             
            for i, action in pairs(DelayedActions) do
                if GameTimer() > action[2] then
                    TableRemove(DelayedActions, i)
                else
                    action[1]()
                end
            end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- Tick Actions:                                                                                                                                
            for i, action in pairs(TickActions) do
                if GameTimer() > action[2] or action[1]() == true then
                    TableRemove(TickActions, i)
                end
            end
    end)
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    CallbackAdd("Draw", function()
        -- Return:                                                                                                                                      
            if not GeneralLoaded then
                if GameTimer() > 15 then
                    if not GeneralLoadTimers.Active then
                        GeneralLoadTimers.Active = true
                        GeneralLoadTimers.EndTime = GameTimer() + 5
                        BuildingsLoad.StartTime = GameTimer() + 6
                        BuildingsLoad.EndTime = GameTimer() + 9
                        HeroesLoad.StartTime = GameTimer() + 6
                        HeroesLoad.EndTime = GameTimer() + 120
                    elseif GameTimer() > GeneralLoadTimers.EndTime then
                        GeneralLoaded = true
                    end
                end
                return
            end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- Refresh Heroes Data:                                                                                                                         
            local YasuoChecked = false
            for i = 1, GameHeroCount() do
                local unit = GameHero(i)
                if unit and unit.valid then
                    Detector(unit, unit.networkID)
                    if IsYasuo and not YasuoChecked and unit.charName == "Yasuo" then
                        YasuoWallTick(unit)
                        YasuoChecked = true
                    end
                end
            end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        for i, cb in pairs(OnDrawC) do
            cb()
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- Delayed Actions:                                                                                                                             
            for i, action in pairs(DelayedActions) do
                if GameTimer() > action[2] then
                    TableRemove(DelayedActions, i)
                else
                    action[1]()
                end
            end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- Tick Actions:                                                                                                                                
            for i, action in pairs(TickActions) do
                if GameTimer() > action[2] or action[1]() == true then
                    TableRemove(TickActions, i)
                end
            end
    end)
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    CallbackAdd("WndMsg", function(msg, wParam)
        -- Return:                                                                                                                                      
            if not GeneralLoaded then
                if GameTimer() > 15 then
                    if not GeneralLoadTimers.Active then
                        GeneralLoadTimers.Active = true
                        GeneralLoadTimers.EndTime = GameTimer() + 5
                        BuildingsLoad.StartTime = GameTimer() + 6
                        BuildingsLoad.EndTime = GameTimer() + 9
                        HeroesLoad.StartTime = GameTimer() + 6
                        HeroesLoad.EndTime = GameTimer() + 120
                    elseif GameTimer() > GeneralLoadTimers.EndTime then
                        GeneralLoaded = true
                    end
                end
                return
            end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        for i, cb in pairs(OnWndMsgC) do
            cb(msg, wParam)
        end
    end)
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    CallbackAdd("ProcessRecall", function(unit, proc)
        -- Return:                                                                                                                                      
            if not GeneralLoaded then
                if GameTimer() > 15 then
                    if not GeneralLoadTimers.Active then
                        GeneralLoadTimers.Active = true
                        GeneralLoadTimers.EndTime = GameTimer() + 5
                        BuildingsLoad.StartTime = GameTimer() + 6
                        BuildingsLoad.EndTime = GameTimer() + 9
                        HeroesLoad.StartTime = GameTimer() + 6
                        HeroesLoad.EndTime = GameTimer() + 120
                    elseif GameTimer() > GeneralLoadTimers.EndTime then
                        GeneralLoaded = true
                    end
                end
                return
            end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        for i, cb in pairs(OnRecallC) do
            cb(unit, proc)
        end
    end)
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    _G.GamsteronCore = Core()
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    _G.GamsteronCoreLoaded = true
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Debug:                                                                                                                                               
    if false then
        local file = io.open(COMMON_PATH .. "GamsteronCoreDebug.txt", "w")
        local fileTimers = { Active = false, EndTime = 0 }
        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- Ally Objects Load:
            GamsteronCore:OnAllyHeroLoad(function(hero)
                if file == nil then return end
                local text = "ally hero \"" .. hero.charName .. "\" loaded" .. "\n"
                file:write(text)
            end)
            --------------------------------------------------------------------------------------------------------------------------------------------
            GamsteronCore:OnAllyNexusLoad(function(nexus)
                if file == nil then return end
                local text = "ally nexus: \"" .. nexus.name .. "\" loaded" .. "\n"
                file:write(text)
            end)
            --------------------------------------------------------------------------------------------------------------------------------------------
            GamsteronCore:OnAllyInhibitorLoad(function(inhibitor)
                if file == nil then return end
                local text = "ally inhibitor: \"" .. inhibitor.name .. "\" loaded" .. "\n"
                file:write(text)
            end)
            --------------------------------------------------------------------------------------------------------------------------------------------
            GamsteronCore:OnAllyTurretLoad(function(turret)
                if file == nil then return end
                local text = "ally turret: \"" .. turret.name .. "\" loaded" .. "\n"
                file:write(text)
            end)
        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- Enemy Objects Load:
            GamsteronCore:OnEnemyHeroLoad(function(hero)
                if file == nil then return end
                local text = "enemy hero \"" .. hero.charName .. "\" loaded" .. "\n"
                file:write(text)
            end)
            --------------------------------------------------------------------------------------------------------------------------------------------
            GamsteronCore:OnEnemyNexusLoad(function(nexus)
                if file == nil then return end
                local text = "enemy nexus: \"" .. nexus.name .. "\" loaded" .. "\n"
                file:write(text)
            end)
            --------------------------------------------------------------------------------------------------------------------------------------------
            GamsteronCore:OnEnemyInhibitorLoad(function(inhibitor)
                if file == nil then return end
                local text = "enemy inhibitor: \"" .. inhibitor.name .. "\" loaded" .. "\n"
                file:write(text)
            end)
            --------------------------------------------------------------------------------------------------------------------------------------------
            GamsteronCore:OnEnemyTurretLoad(function(turret)
                if file == nil then return end
                local text = "enemy turret: \"" .. turret.name .. "\" loaded" .. "\n"
                file:write(text)
            end)
        ------------------------------------------------------------------------------------------------------------------------------------------------
        GamsteronCore:OnProcessRecall(function(hero, buff)
            --print(hero.charName .. " OnProcessRecall")
        end)
        ------------------------------------------------------------------------------------------------------------------------------------------------
        GamsteronCore:OnProcessSpellCast(function(hero, activeSpell, spellCastType)
            if spellCastType == SPELLCAST_ATTACK then
                --print(hero.charName .. " OnProcessSpell: \"" .. activeSpell.name .. "\", AttackSpell")
            elseif spellCastType == SPELLCAST_DASH then
                --print(hero.charName .. " OnProcessSpell: \"" .. activeSpell.name .. "\", DashSpell")
            elseif spellCastType == SPELLCAST_IMMOBILE then
                --print(hero.charName .. " OnProcessSpell: \"" .. activeSpell.name .. "\", ImmobileSpell")
            elseif spellCastType == SPELLCAST_OTHER then
                --print(hero.charName .. " OnProcessSpell: \"" .. activeSpell.name .. "\", OtherSpell")
            end
        end)
        ------------------------------------------------------------------------------------------------------------------------------------------------
        GamsteronCore:OnProcessSpellComplete(function(hero, args)
            --print(hero.charName .. " OnProcessSpellComplete: \"" .. args.name .. "\"")
        end)
        ------------------------------------------------------------------------------------------------------------------------------------------------
        GamsteronCore:OnProcessWaypoint(function(hero, path, isMoving)
            if isMoving then
                print(hero.charName .. " OnProcessWaypoint: IsMoving")
            else
                print(hero.charName .. " OnProcessWaypoint: not IsMoving")
            end
        end)
        ------------------------------------------------------------------------------------------------------------------------------------------------
        GamsteronCore:OnCancelAttack(function(hero, attack)
            --print(hero.charName .. " OnCancelAttack: \"" .. attack.name .. "\"")
        end)
        ------------------------------------------------------------------------------------------------------------------------------------------------
        GamsteronCore:OnUpdateBuff(function(hero, buff)
            --print(hero.charName .. " OnUpdateBuff: \"" .. buff.name .. "\"")
        end)
        ------------------------------------------------------------------------------------------------------------------------------------------------
        GamsteronCore:OnCreateBuff(function(hero, buff)
            --print(hero.charName .. " OnCreateBuff: \"" .. buff.name .. "\"")
        end)
        ------------------------------------------------------------------------------------------------------------------------------------------------
        GamsteronCore:OnRemoveBuff(function(hero, buffName)
            --print(hero.charName .. " OnRemoveBuff: \"" .. buffName .. "\"")
        end)
        ------------------------------------------------------------------------------------------------------------------------------------------------
        GamsteronCore:OnGainVision(function(hero)
            --print(hero.charName .. " OnGainVision")
        end)
        ------------------------------------------------------------------------------------------------------------------------------------------------
        GamsteronCore:OnLoseVision(function(hero)
            --print(hero.charName .. " OnLoseVision")
        end)
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local cbtickid1
        cbtickid1 = Callback.Add("Tick", function()
            if not fileTimers.Active then
                fileTimers.Active = true
                fileTimers.EndTime = GeneralLoadTimers.EndTime + 3
            elseif file ~= nil and GameTimer() > fileTimers.EndTime then
                file:close()
                file = nil
                print("file closed")
                Callback.Del("Tick", cbtickid1)
            end
        end)
        local loaded = false
        local fullloaded = false
        local endtime = 0
        Callback.Add("Tick", function()
            if not loaded then
                endtime = GameTimer() + 5
                loaded = true
            elseif not fullloaded and GameTimer() > endtime then
                local o = os.clock()
                DelayAction(function() print(os.clock() - o) end, 0.1)
                DelayAction(function() print(os.clock() - o) end, 0.2)
                DelayAction(function() print(os.clock() - o) end, 0.3)
                DelayAction(function() print(os.clock() - o) end, 0.4)
                DelayAction(function() print(os.clock() - o) end, 0.5)
                print("created")
                fullloaded = true
            end
        end)
        local loaded2 = false
        local fullloaded2 = false
        local endtime2 = 0
        Callback.Add("Tick", function()
            if not loaded2 then
                endtime2 = GameTimer() + 5
                loaded2 = true
            elseif not fullloaded2 and GameTimer() > endtime2 then
                local o = os.clock()
                TickAction(function() print(os.clock() - o) end, 0.1)
                fullloaded2 = true
            end
        end)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------
