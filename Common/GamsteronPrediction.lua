local GamsteronPredictionVer = 0.09
local DebugMode = false

-- LOAD START
    local IsLoaded, StartTime = false, os.clock() + 5
    local function PreLoad()
        if os.clock() < StartTime or _G.Game.Timer() < 30 then
            return
        end
        IsLoaded = true
    end
    local LocalCore, Menu, Orbwalker, TargetSelector, ObjectManager, Damage, Spells
    do
        if _G.GamsteronPredictionLoaded then
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
            version = GamsteronPredictionVer,
            scriptPath = SCRIPT_PATH .. "GamsteronPrediction.lua",
            scriptUrl = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Common/GamsteronPrediction.lua",
            versionPath = SCRIPT_PATH .. "GamsteronPrediction.version",
            versionUrl = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Common/GamsteronPrediction.version"
        })
    
        if success then
            print("GamsteronPrediction updated to version " .. version .. ". Please Reload with 2x F6 !")
            _G.GamsteronPredictionUpdated = true
            return
        end
    end
    local HighAccuracy = 0.1
    local ExtraImmobile = 0
    local MaxRangeMulipier = 1
    local HighAccuracy2 = 5000
    Menu = MenuElement({name = "Gamsteron Prediction", id = "GamsteronPrediction", type = _G.MENU })
    Menu:MenuElement({id = "castposMode", name = "CastPos Mode", value = 1, drop = { "GOS - recommended", "Custom - not recommended" } })
    Menu:MenuElement({id = "ExtraImmobile", name = "ExtraImmobileTime - lower = better accuracy", value = 100, min = 0, max = 200, step = 10, callback = function(value) ExtraImmobile = value * 0.001 end })
    Menu:MenuElement({id = "PredNumAccuracy", name = "HitChance High - higher = better accuracy", value = 3000, min = 2000, max = 5000, step = 1000, callback = function(value) HighAccuracy2 = value end })
    Menu:MenuElement({id = "PredHighAccuracy", name = "HitChance High - lower = better accuracy", value = 80, min = 20, max = 100, step = 10, callback = function(value) HighAccuracy = value * 0.001 end })
    Menu:MenuElement({id = "PredMaxRange", name = "Pred Max Range %", value = 100, min = 70, max = 100, step = 1, callback = function(value) MaxRangeMulipier = value * 0.01 end })
    Menu:MenuElement({name = "Version " .. tostring(GamsteronPredictionVer), type = _G.SPACE, id = "vermorgspace"})
    HighAccuracy = Menu.PredHighAccuracy:Value() * 0.001
    ExtraImmobile = Menu.ExtraImmobile:Value() * 0.001
    MaxRangeMulipier = Menu.PredMaxRange:Value() * 0.01
    HighAccuracy2 = Menu.PredNumAccuracy:Value()
-- LOAD END

-- BUFF SPELL NAMES START
    local STUN_BUFFS                       =
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

    local SLOW_BUFFS                       =
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

    local DASH_BUFFS                       =
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

    local STUN_SPELLS                      =
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

    local DASH_SPELLS                      =
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
    --
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

    local NoAutoAttacks                    =
    {
        ["GravesAutoAttackRecoil"] = true
    }

    local ATTACK_SPELLS                    =
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
-- BUFF SPELL NAMES END

-- MATH START
    local function GetDistance(vec1, vec2)
        local dx = vec1.x - vec2.x
        local dy = (vec1.z or vec1.y) - (vec2.z or vec2.y)
        return _G.math.sqrt(dx * dx + dy * dy)
    end
    local function GetDistanceSquared(vec1, vec2)
        local dx = vec1.x - vec2.x
        local dy = (vec1.z or vec1.y) - (vec2.z or vec2.y)
        return dx * dx + dy * dy
    end
    local function Normalized(vec1, vec2)
        local vec = { x = vec1.x - vec2.x, y = (vec1.z or vec1.y) - (vec2.z or vec2.y) }
        local length = _G.math.sqrt(vec.x * vec.x + vec.y * vec.y)
        if length > 0 then
            local inv = 1.0 / length
            return { x = (vec.x * inv), y = (vec.y * inv) }
        end
        return nil
    end
    local function Extended(vec, dir, range)
        vec = { x = vec.x, y = (vec.z or vec.y) }
        if dir == nil then return vec end
        return { x = vec.x + dir.x * range, y = vec.y + dir.y * range }
    end
    local function Perpendicular(dir)
        if dir == nil then return nil end
        return { x = -dir.y, y = dir.x }
    end
    local function Intersection(lineSegment1Start, lineSegment1End, lineSegment2Start, lineSegment2End)
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
    local function IsInRange(vec1, vec2, range)
        local dx = vec1.x - vec2.x
        local dy = (vec1.z or vec1.y) - (vec2.z or vec2.y)
        return dx * dx + dy * dy <= range * range
    end
    local function ProjectOn(p, p1, p2)
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
    local function GetInterceptionTime(source, startP, endP, unitspeed, spellspeed)
        local sx = source.x
        local sy = (source.z or source.y)
        local ux = startP.x
        local uy = (startP.z or startP.y)
        local dx = endP.x - ux
        local dy = (endP.z or endP.y) - uy
        local magnitude = _G.math.sqrt(dx * dx + dy * dy)
        dx = (dx / magnitude) * unitspeed
        dy = (dy / magnitude) * unitspeed
        local a = (dx * dx) + (dy * dy) - (spellspeed * spellspeed)
        local b = 2 * ((ux * dx) + (uy * dy) - (sx * dx) - (sy * dy))
        local c = (ux * ux) + (uy * uy) + (sx * sx) + (sy * sy) - (2 * sx * ux) - (2 * sy * uy)
        local d = (b * b) - (4 * a * c)
        if d > 0 then
            local t1 = (-b + _G.math.sqrt(d)) / (2 * a)
            local t2 = (-b - _G.math.sqrt(d)) / (2 * a)
            return _G.math.max(t1, t2)
        end
        if d >= 0 and d < 0.00001 then
            return -b / (2 * a)
        end
        return 0.00001
    end
-- MATH END

-- YASUO START
    local IsYasuo = false; LocalCore:OnEnemyHeroLoad(function(hero) if hero.charName == "Yasuo" and hero.team == LocalCore.TEAM_ENEMY then IsYasuo = true end end)
    local Yasuo = { Wall = nil, Name = nil, Level = 0, CastTime = 0, StartPos = nil }
    local function IsYasuoWall()
        if not IsYasuo or Yasuo.Wall == nil then return false end
        if Yasuo.Name == nil or Yasuo.Wall.name == nil or Yasuo.Name ~= Yasuo.Wall.name or Yasuo.StartPos == nil then
            Yasuo.Wall = nil
            return false
        end
        return true
    end
    local function IsYasuoWallCollision(startPos, endPos, speed, delay)
        if not IsYasuoWall() then return false end
        local Pos = Yasuo.Wall.pos
        local Width = 300 + 50 * Yasuo.Level
        local Direction = Perpendicular(Normalized(Pos, Yasuo.StartPos))
        local StartPos = Extended(Pos, Direction, Width / 2)
        local EndPos = Extended(StartPos, Direction, -Width)
        local IntersectionResult = Intersection(StartPos, EndPos, endPos, startPos)
        if IntersectionResult.Intersects then
            local t = delay + GetDistance(IntersectionResult.Point, startPos) / speed
            if _G.Game.Timer() + t < Yasuo.CastTime + 4 then
                return true
            end
        end
        return false
    end
    local function YasuoWallTick(unit)
        if _G.Game.Timer() > Yasuo.CastTime + 2 then
            local wallData = unit:GetSpellData(_W)
            if wallData.currentCd > 0 and wallData.cd - wallData.currentCd < 1.5 then
                Yasuo.Wall = nil
                Yasuo.Name = nil
                Yasuo.StartPos = nil
                Yasuo.Level = wallData.level
                Yasuo.CastTime = wallData.castTime
                for i = 1, _G.Game.ParticleCount() do
                    local obj = _G.Game.Particle(i)
                    if obj then
                        local name = obj.name:lower()
                        if name:find("yasuo") and name:find("_w_") and name:find("windwall") then
                            if name:find("activate") then
                                Yasuo.StartPos = obj.pos
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
-- YASUO END

-- VISIBLE START
    local VisibleData = {}
    local function GetVisibleData(unit)

        local id = unit.networkID

        -- create id table
        if VisibleData[id] == nil then VisibleData[id] = { IsVisible = true, IsDashing = false, InVisibleTimer = 0, VisibleTimer = 0, LastPath = {}, MoveSpeed = 0 } end

        -- unit is visible
        if unit.visible then

            -- on visible
            if not VisibleData[id].IsVisible then
                VisibleData[id].IsVisible = true
                VisibleData[id].VisibleTimer = os.clock()
            end

            -- remove old path
            local count = #VisibleData[id].LastPath
            for i = count, 1, -1 do
                table.remove(VisibleData[id].LastPath, i)
            end

            -- create new path if unit is moving
            local path = unit.pathing
            if path and path.hasMovePath then

                -- is dashing
                if path.isDashing then
                    VisibleData[id].IsDashing = true
                    VisibleData[id].MoveSpeed = path.dashSpeed
                    --print(path.dashSpeed)
                else
                    VisibleData[id].IsDashing = false
                    VisibleData[id].MoveSpeed = unit.ms
                end
                table.insert(VisibleData[id].LastPath, unit.pos)
                for i = path.pathIndex, path.pathCount do
                    table.insert(VisibleData[id].LastPath, unit:GetPath(i))
                end
            end
        -- on invisible
        elseif VisibleData[id].IsVisible then
            VisibleData[id].IsVisible = false
            VisibleData[id].InVisibleTimer = os.clock()
        end
    end
-- VISIBLE END

-- WAYPOINTS START
    local function GetPathDistance(unit, path)

        -- (toUnit) distance from start point to unit.pos
        local toUnit = 0
        if path.pathIndex > 0 then
            for i = 0, path.pathIndex do
                if i == path.pathIndex - 1 then toUnit = toUnit + unit.pos:DistanceTo(unit:GetPath(i)) break end
                toUnit = toUnit + unit:GetPath(i):DistanceTo(unit:GetPath(i+1))
            end
        end

        -- (toEnd) distance from start point to end point
        local toEnd = 0
        for i = 0, path.pathCount - 1 do
            toEnd = toEnd + unit:GetPath(i):DistanceTo(unit:GetPath(i+1))
        end

        -- (fromUnit) distance from unit.pos to end point
        local fromUnit = toEnd - toUnit

        -- return
        return toUnit, fromUnit, toEnd

    end
    local function GetPredictedPos(unit, path, predDistance)

        -- point on current segment
        local pointFrom, pointTo = unit.pos, unit:GetPath(path.pathIndex)
        local currentDistance = pointFrom:DistanceTo(pointTo)
        if currentDistance >= predDistance then
            return pointFrom:Extended(pointTo, predDistance)
        end
        predDistance = predDistance - currentDistance

        -- point is end pos
        if path.pathIndex == path.pathCount then
            return pointTo
        end

        -- search point on other path segments
        for i = path.pathIndex, path.pathCount - 1 do
            pointFrom, pointTo = unit:GetPath(i), unit:GetPath(i+1)
            currentDistance = pointFrom:DistanceTo(pointTo)
            if currentDistance >= predDistance then
                return pointFrom:Extended(pointTo, predDistance)
            end
            predDistance = predDistance - currentDistance
        end

        -- point is end pos
        return pointTo

    end
-- WAYPOINTS END

-- COLLISION START
    _G.COLLISION_MINION = 0
    _G.COLLISION_ALLYHERO = 1
    _G.COLLISION_ENEMYHERO = 2
    _G.COLLISION_YASUOWALL = 3
    local function GetEnemyMinions(from, range)
        local result = {}
        for i = 1, Game.MinionCount() do
            local minion = Game.Minion(i)
            if minion and minion.team ~= LocalCore.TEAM_ALLY and LocalCore:IsValidTarget(minion) and IsInRange(from, minion.pos, range) then
                _G.table.insert(result, minion)
            end
        end
        return result
    end
    local function GetAllyHeroes(from, range, unitID)
        local result = {}
        for i = 1, Game.HeroCount() do
            local hero = Game.Hero(i)
            if hero and unitID ~= hero.networkID and hero.team == LocalCore.TEAM_ALLY and LocalCore:IsValidTarget(hero) then
                if IsInRange(from, hero.pos, range) then
                    _G.table.insert(result, hero)
                end
            end
        end
        return result
    end
    local function GetEnemyHeroes(from, range, unitID)
        local result = {}
        for i = 1, Game.HeroCount() do
            local hero = Game.Hero(i)
            if hero and unitID ~= hero.networkID and hero.team ~= LocalCore.TEAM_ALLY and LocalCore:IsValidTarget(hero) then
                if IsInRange(from, hero.pos, range) then
                    _G.table.insert(result, hero)
                end
            end
        end
        return result
    end
    local function GetCollisionWaypoints(unit, path)
        local result = {}
        _G.table.insert(result, unit.pos)
        for i = path.pathIndex, path.pathCount do
            _G.table.insert(result, unit:GetPath(i))
        end
        return result
    end
    local function GetCollisionPrediction(unit, from, spellspeed, spelldelay)
        local HasMovePath, CastPos = false, nil
        local path = unit.pathing
        if not path or not path.hasMovePath then
            CastPos = unit.pos
        else
            local cwp = GetCollisionWaypoints(unit, path)
            if #cwp == 1 then
                CastPos = cwp[1]
            else
                HasMovePath, CastPos = true, unit:GetPrediction(spellspeed, spelldelay)
            end
        end
        return HasMovePath, CastPos
    end
    local function GetCollision(from, to, speed, delay, radius, collisionObjects, objectsList, skipID)
        local result = {}
        local direction = Normalized(to, from)
        to = Extended(to, direction, 35)
        from = Extended(from, direction, -35)
        local fromPos = myHero.pos
        for i = 1, #collisionObjects do
            local objectType = collisionObjects[i]
            if objectType == _G.COLLISION_MINION then
                local objects = GetEnemyMinions(fromPos, 2000)
                for k = 1, #objects do
                    local object = objects[k]
                    local HasMovePath, CastPos = GetCollisionPrediction(object, from, speed, delay)
                    local isOnSegment, pointSegment, pointLine = ProjectOn(CastPos, from, to)
                    local IsCollisionable = false
                    if isOnSegment and IsInRange(CastPos, pointSegment, radius + 35 + object.boundingRadius) then
                        _G.table.insert(result, object)
                        IsCollisionable = true
                    end
                    if HasMovePath and not IsCollisionable then
                        local objectPos = object.pos
                        isOnSegment, pointSegment, pointLine = ProjectOn(objectPos, from, to)
                        if isOnSegment and IsInRange(objectPos, pointSegment, radius + 35 + object.boundingRadius) then
                            _G.table.insert(result, object)
                        end
                    end
                end
            elseif objectType == _G.COLLISION_ENEMYHERO then
                local objects = GetEnemyHeroes(fromPos, 2000, skipID)
                for k = 1, #objects do
                    local object = objects[k]
                    local HasMovePath, CastPos = GetCollisionPrediction(object, from, speed, delay)
                    local isOnSegment, pointSegment, pointLine = ProjectOn(CastPos, from, to)
                    local IsCollisionable = false
                    if isOnSegment and IsInRange(CastPos, pointSegment, radius + 35 + object.boundingRadius) then
                        _G.table.insert(result, object)
                        IsCollisionable = true
                    end
                    if HasMovePath and not IsCollisionable then
                        local objectPos = object.pos
                        isOnSegment, pointSegment, pointLine = ProjectOn(objectPos, from, to)
                        if isOnSegment and IsInRange(objectPos, pointSegment, radius + 35 + object.boundingRadius) then
                            _G.table.insert(result, object)
                        end
                    end
                end
            elseif objectType == _G.COLLISION_ALLYHERO then
                local objects = GetAllyHeroes(fromPos, 2000, skipID)
                for k = 1, #objects do
                    local object = objects[k]
                    local HasMovePath, CastPos = GetCollisionPrediction(object, from, speed, delay)
                    local isOnSegment, pointSegment, pointLine = ProjectOn(CastPos, from, to)
                    local IsCollisionable = false
                    if isOnSegment and IsInRange(CastPos, pointSegment, radius + 35 + object.boundingRadius) then
                        _G.table.insert(result, object)
                        IsCollisionable = true
                    end
                    if HasMovePath and not IsCollisionable then
                        local objectPos = object.pos
                        isOnSegment, pointSegment, pointLine = ProjectOn(objectPos, from, to)
                        if isOnSegment and IsInRange(objectPos, pointSegment, radius + 35 + object.boundingRadius) then
                            _G.table.insert(result, object)
                        end
                    end
                end
            --elseif objectType == CollisionableObjects.Walls then
            elseif IsYasuo and objectType == _G.COLLISION_YASUOWALL and IsYasuoWall() then
                local Pos = Yasuo.Wall.pos
                local Width = 300 + 50 * Yasuo.Level
                local Direction = Perpendicular(Normalized(Pos, Yasuo.StartPos))
                local StartPos = Extended(Pos, Direction, Width / 2)
                local EndPos = Extended(StartPos, Direction, -Width)
                local IntersectionResult = Intersection(StartPos, EndPos, to, from)
                if IntersectionResult.Intersects then
                    local t = _G.Game.Timer() + (GetDistance(IntersectionResult.Point, from) / speed + delay)
                    if t < Yasuo.CastTime + 4 then
                        return true, { Yasuo.Wall }
                    end
                end
            end
        end
        return false, result
    end
-- COLLISION END

-- PREDICTION START
    _G.HITCHANCE_IMPOSSIBLE             = 0
    _G.HITCHANCE_COLLISION              = 1
    _G.HITCHANCE_NORMAL                 = 2
    _G.HITCHANCE_HIGH                   = 3
    _G.HITCHANCE_IMMOBILE               = 4
    _G.SPELLTYPE_LINE                   = 0
    _G.SPELLTYPE_CIRCLE                 = 1
    _G.SPELLTYPE_CONE                   = 2
    local function PredictionOutput(args)
        args = args or {}
        local result =
        {
            CastPosition           = args.CastPosition         or nil,
            UnitPosition           = args.UnitPosition         or nil,
            Hitchance              = args.Hitchance            or _G.HITCHANCE_IMPOSSIBLE,
            Input                  = args.Input                or nil,
            CollisionObjects       = args.CollisionObjects     or {},
            AoeTargetsHit          = args.AoeTargetsHit        or {},
            AoeTargetsHitCount     = args.AoeTargetsHitCount   or 0
        }
        result.AoeTargetsHitCount = _G.math.max(result.AoeTargetsHitCount, #result.AoeTargetsHit)
        return result
    end
    local function PredictionInput(unit, args, from)
        GetVisibleData(unit)
        local result =
        {
            Aoe                = args.Aoe                  or false,
            Collision          = args.Collision            or false,
            MaxCollision       = args.MaxCollision         or 0,
            CollisionObjects   = args.CollisionObjects     or { _G.COLLISION_MINION, _G.COLLISION_YASUOWALL },
            Delay              = args.Delay                or 0,
            Radius             = args.Radius               or 1,
            Range              = args.Range                or _G.math.huge,
            Speed              = args.Speed                or _G.math.huge,
            Type               = args.Type                 or _G.SPELLTYPE_LINE
        }
        result.From = from
        result.RangeCheckFrom = myHero.pos
        result.Unit = unit
        result.Delay = result.Delay + 0.06 + LATENCY
        result.UnitID = result.Unit.networkID
        if args.UseBoundingRadius or result.Type == _G.SPELLTYPE_LINE then result.RealRadius = result.Radius + result.Unit.boundingRadius else result.RealRadius = result.Radius end
        return result
    end
    local function GetHitChance(unit, path, moveSpeed, slowDuration, delay, spellType, radius, spellDelay)
        local hitChance = _G.HITCHANCE_NORMAL
        local toUnit, fromUnit, toEnd = GetPathDistance(unit, path)
        if toUnit <= 1 or fromUnit <= 1 or toEnd <= 1 then
            return _G.HITCHANCE_IMPOSSIBLE
        end
        local lastMoveTime = toUnit / moveSpeed
        if lastMoveTime > 0 then
            if lastMoveTime < HighAccuracy or lastMoveTime < fromUnit / HighAccuracy2 then
                hitChance = _G.HITCHANCE_HIGH
            end
        elseif slowDuration > 0 and moveSpeed < 250 and slowDuration + 0.1 >= delay then
            hitChance = _G.HITCHANCE_HIGH
        end
        if spellType == _G.SPELLTYPE_LINE then
            if fromUnit < 150 then
                hitChance = _G.HITCHANCE_NORMAL
            end
            if fromUnit < 75 then
                hitChance = _G.HITCHANCE_IMPOSSIBLE
            end
        end
        if fromUnit < spellDelay * moveSpeed - radius then
            hitChance = _G.HITCHANCE_NORMAL
        end
        return hitChance
    end
    local function GetStandardPrediction(input, slowDuration, moveSpeed)
        local path = input.Unit.pathing
        local Radius = input.RealRadius * 0.9
        local delay = input.Delay + (GetDistance(input.From, input.Unit.pos) / input.Speed)
        local delay2 = delay - (Radius / moveSpeed)
        local delayNoSpeed = input.Delay + (Radius / moveSpeed)
        local hitChance = GetHitChance(input.Unit, path, moveSpeed, slowDuration, delay2, input.Type, Radius, input.Delay)
        if input.Speed == _G.math.huge then
            if Menu.castposMode:Value() == 1 then
                return PredictionOutput({
                    Input = input,
                    Hitchance = hitChance,
                    CastPosition = input.Unit:GetPrediction(_G.math.huge,input.Delay):Extended(input.Unit.pos, Radius),
                    UnitPosition = input.Unit:GetPrediction(_G.math.huge,input.Delay)
                })
            else
                return PredictionOutput({
                    Input = input,
                    Hitchance = hitChance,
                    CastPosition = GetPredictedPos(input.Unit, path, moveSpeed * delayNoSpeed),
                    UnitPosition = GetPredictedPos(input.Unit, path, moveSpeed * input.Delay)
                })
            end
        end
        local endPos = GetPredictedPos(input.Unit, path, moveSpeed * delay)
        local interceptTime = input.Delay + GetInterceptionTime(input.From, input.Unit.pos, endPos, moveSpeed, input.Speed)
        local interceptTime2 = interceptTime - (Radius / moveSpeed)
        if Menu.castposMode:Value() == 1 then
            return PredictionOutput({
                Input = input,
                Hitchance = hitChance,
                CastPosition = input.Unit:GetPrediction(input.Speed,input.Delay):Extended(input.Unit.pos, Radius),
                UnitPosition = input.Unit:GetPrediction(input.Speed,input.Delay)
            })
        else
            return PredictionOutput({
                Input = input,
                Hitchance = hitChance,
                CastPosition = GetPredictedPos(input.Unit, path, moveSpeed * interceptTime2),
                UnitPosition = GetPredictedPos(input.Unit, path, moveSpeed * interceptTime)
            })
        end
    end
    local function GetDashingPrediction(input, dashDuration, moveSpeed)
        --[[local unit = input.Unit
        local path = GetWaypoints(unit, input.UnitID)
        if #path ~= 2 then
            return PredictionOutput()
        end
        local startPos = unit.pos
        local endPos = path[2]
        if IsInRange(startPos, endPos, 25) then
            return PredictionOutput()
        end
        local speed = unit.pathing.dashSpeed
        local interceptTime = input.Delay + GetInterceptionTime(input.From, startPos, endPos, speed, input.Speed) - (input.RealRadius / unit.ms)
        local remainingTime = GetDistance(startPos, endPos) / speed
        if remainingTime + 0.1 >= interceptTime then
            local direction = Normalized(endPos, startPos)
            local castPos = Extended(startPos, direction, speed * interceptTime)
            if GetDistanceSquared(startPos, castPos) > GetDistanceSquared(startPos, endPos) then
                castPos = endPos
            end
            if remainingTime >= interceptTime then
                if DebugMode then print("IMMOBILE_DASH: speed " .. tostring(speed)) end
                return PredictionOutput({ Input = input, Hitchance = _G.HITCHANCE_IMMOBILE, CastPosition = castPos, UnitPosition = castPos })
            end
            if DebugMode then print("HIGH_DASH: speed " .. tostring(speed)) end
            return PredictionOutput({ Input = input, Hitchance = _G.HITCHANCE_HIGH, CastPosition = castPos, UnitPosition = castPos })
        end--]]
        return PredictionOutput({ Input = input })
    end
    local function GetImmobilePrediction(input, ImmobileDuration)
        local pos = input.Unit.pos
        local interceptTime = input.Delay + (GetDistance(input.From, pos) / input.Speed) - (input.RealRadius / input.Unit.ms)
        if ImmobileDuration + ExtraImmobile >= interceptTime then
            return PredictionOutput({ Input = input, Hitchance = _G.HITCHANCE_IMMOBILE, CastPosition = pos, UnitPosition = pos })
        end
        return PredictionOutput({ Input = input })
    end
    function GetImmobileDashSlowDuration(unit)

        local ImmobileDuration, DashDuration, SlowDuration = 0, 0, 0

        for i = 0, unit.buffCount do
            local buff = unit:GetBuff(i)
            if buff and buff.count > 0 then
                local duration = buff.duration
                local name = buff.name
                if duration and name and #name < 30 then
                    if DASH_BUFFS[name] then
                        DashDuration = duration
                    elseif STUN_BUFFS[name] then
                        ImmobileDuration = duration
                    elseif SLOW_BUFFS[name] then
                        SlowDuration = duration
                    end
                end
            end
        end

        local spell = unit.activeSpell
        if spell and spell.valid then
            local name = spell.name
            if name then
                if not NoAutoAttacks[name] and (not unit.isChanneling or ATTACK_SPELLS[name]) then
                    local duration = spell.castEndTime - _G.Game.Timer()
                    if duration > ImmobileDuration then ImmobileDuration = duration end
                elseif DASH_SPELLS[name] then
                    local delay = DASH_SPELLS[name]; local endTime = delay == -1 and (spell.castEndTime) or (spell.startTime + delay)
                    local duration = endTime - _G.Game.Timer()
                    if duration > DashDuration then DashDuration = duration end
                elseif STUN_SPELLS[name] then
                    local delay = STUN_SPELLS[name]; endTime = delay == -1 and (spell.castEndTime) or (spell.startTime + delay)
                    local duration = endTime - _G.Game.Timer()
                    if duration > ImmobileDuration then ImmobileDuration = duration end
                end
            end
        end

        return ImmobileDuration, DashDuration, SlowDuration

    end
    local function GetPredictionOutput(unit, args, from)

        local input = PredictionInput(unit, args, from)

        local data = VisibleData[input.UnitID]

        local ImmobileDuration, DashDuration, SlowDuration = GetImmobileDashSlowDuration(unit)

        -- visible
        if unit.visible then
            local path = unit.pathing
            if not path or os.clock() - data.VisibleTimer < 0.2 then
                return PredictionOutput({ Input = input })
            end
            if not path.hasMovePath or ImmobileDuration > 0 then
                return GetImmobilePrediction(input, ImmobileDuration)
            end
            if path.isDashing or DashDuration > 0 then
                if DashDuration > 0 then
                    --return GetDashingPrediction(input, DashDuration, path.dashSpeed)
                end
                return PredictionOutput({ Input = input })
            end
            if path.hasMovePath then
                input.Range = input.Range * MaxRangeMulipier
                return GetStandardPrediction(input, SlowDuration, unit.ms)
            end
        end

         -- invisible
        local invisiblePath = data.LastPath
        if #invisiblePath == 0 then
            return GetImmobilePrediction(input, ImmobileDuration)
        end
        if data.IsDashing or DashDuration > 0 then
            if DashDuration > 0 and #invisiblePath == 2 then
                --return GetDashingPrediction(input, DashDuration, data.MoveSpeed)
            end
            return PredictionOutput({ Input = input })
        end
        local dist = 0
        for i = 1, #invisiblePath - 1 do
            dist = dist + invisiblePath[i]:DistanceTo(invisiblePath[i+1])
        end
        if os.clock() - data.InVisibleTimer < dist / data.MoveSpeed then
            input.Range = input.Range * MaxRangeMulipier
            return GetStandardPrediction(input, SlowDuration, data.MoveSpeed)
        end
        return PredictionOutput({ Input = input })
    end
    function GetGamsteronPrediction(unit, args, from)
        local output = GetPredictionOutput(unit, args, from)
        local input = output.Input
        if output.Hitchance ~= _G.HITCHANCE_IMPOSSIBLE then
            if input.Range ~= _G.math.huge then
                if output.Hitchance >= _G.HITCHANCE_HIGH and not IsInRange(input.RangeCheckFrom, unit.pos, input.Range + input.RealRadius * 3 / 4) then
                    output.Hitchance = _G.HITCHANCE_NORMAL
                end
                if not IsInRange(input.RangeCheckFrom, output.UnitPosition, input.Range + (input.Type == _G.SPELLTYPE_CIRCLE and input.RealRadius or 0)) then
                    output.Hitchance = _G.HITCHANCE_IMPOSSIBLE
                end
                if not IsInRange(output.CastPosition, myHero.pos, input.Range) then
                    output.Hitchance = _G.HITCHANCE_IMPOSSIBLE
                end
            end
        end
        if input.Collision and output.Hitchance ~= _G.HITCHANCE_IMPOSSIBLE then
            local isWall, objects = GetCollision(input.From, output.CastPosition, input.Speed, input.Delay, input.Radius, input.CollisionObjects, input.UnitID)
            if isWall or #objects > input.MaxCollision then
                output.Hitchance = _G.HITCHANCE_COLLISION
            end
            output.CollisionObjects = objects
        end
        if output.CastPosition ~= nil then
            if Menu.castposMode:Value() == 2 then
                output.CastPosition = Vector({x = output.CastPosition.x, y = unit:GetPrediction(input.Speed,input.Delay).y, z = output.CastPosition.z})
            end
            if not output.CastPosition:ToScreen().onScreen then
                if input.Type == _G.SPELLTYPE_LINE then
                    output.CastPosition = input.From:Extended(output.CastPosition, 600)
                else
                    output.Hitchance = _G.HITCHANCE_IMPOSSIBLE
                end
            end
        else
            output.Hitchance = _G.HITCHANCE_IMPOSSIBLE
        end
        return output
    end
-- PREDICTION END

-- GOS CALLBACKS START
    _G.Callback.Add("Load", function()
        Callback.Add("Draw", function()

            -- pre load
            if not IsLoaded then PreLoad(); return end

            -- prediction on tick
            local YasuoChecked = false
            for i = 1, _G.Game.HeroCount() do
                local unit = _G.Game.Hero(i)
                if unit and unit.valid and unit.alive then
                    GetVisibleData(unit)
                    if IsYasuo and not YasuoChecked and unit.charName == "Yasuo" then
                        YasuoWallTick(unit)
                        YasuoChecked = true
                    end
                end
            end
        end)
    end)
-- GOS CALLBACKS END

_G.GamsteronPredictionLoaded = true
