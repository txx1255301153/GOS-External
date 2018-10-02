--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Initialize:                                                                                                                                          
    -- Return:                                                                                                                                          
		if _G.GamsteronOrbwalkerLoaded then
			return
		end
		if _G.SDK and _G.SDK.Orbwalker then
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
	-- Auto Update:                                                                                                                                     
		if _Update then
			local args =
			{
				version = 0.01,
				----------------------------------------------------------------------------------------------------------------------------------------
				scriptPath = COMMON_PATH .. "GamsteronOrbwalker.lua",
				scriptUrl = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/GamsteronOrbwalker.lua",
				----------------------------------------------------------------------------------------------------------------------------------------
				versionPath = COMMON_PATH .. "GamsteronOrbwalker.version",
				versionUrl = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/GamsteronOrbwalker.version"
			}
			--------------------------------------------------------------------------------------------------------------------------------------------
			local success, version = Core:AutoUpdate(args)
			--------------------------------------------------------------------------------------------------------------------------------------------
			if success then
				print("GamsteronOrbwalker updated to version " .. version .. ". Please Reload with 2x F6 !")
				_G.GamsteronOrbwalkerUpdated = true
			end
		end
		------------------------------------------------------------------------------------------------------------------------------------------------
		if _G.GamsteronOrbwalkerUpdated then
			return
		end
	----------------------------------------------------------------------------------------------------------------------------------------------------
	-- RandomSeed:																																		
		math.randomseed(os.clock())
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Locals:																																				
	-- Variables:																																		
		local Menu, MenuChamp
		local GAMSTERON_MODE_DMG = false
		local CURSOR
		local Spells, Damage, ObjectManager, TargetSelector, HealthPrediction, Orbwalker, HoldPositionButton
		local CONTROLL						= nil
		local NEXT_CONTROLL					= 0
		local MYHERO_IS_CAITLYN				= myHero.charName == "Caitlyn"
		local ME_IS_KALISTA					= myHero.charName == "Kalista"
		local GetTickCount					= GetTickCount
		local myHero						= _G.myHero
		local MeCharName					= myHero.charName
		local Vector					= Vector
		local DrawLine					= Draw.Line
		local DrawColor				= Draw.Color
		local DrawCircle				= Draw.Circle
		local DrawText					= Draw.Text
		local ControlIsKeyDown			= Control.IsKeyDown
		local ControlMouseEvent		= Control.mouse_event
		local ControlSetCursorPos		= Control.SetCursorPos
		local ControlKeyUp				= Control.KeyUp
		local ControlKeyDown			= Control.KeyDown
		local GameCanUseSpell			= Game.CanUseSpell
		local GameLatency				= Game.Latency
		local GameTimer				= Game.Timer
		local GameParticleCount		= Game.ParticleCount
		local GameParticle				= Game.Particle
		local GameHeroCount 			= Game.HeroCount
		local GameHero 				= Game.Hero
		local GameMinionCount 			= Game.MinionCount
		local GameMinion 				= Game.Minion
		local GameTurretCount 			= Game.TurretCount
		local GameTurret 				= Game.Turret
		local GameWardCount 			= Game.WardCount
		local GameWard 				= Game.Ward
		local GameObjectCount 			= Game.ObjectCount
		local GameObject				= Game.Object
		local GameMissileCount 		= Game.MissileCount
		local GameMissile				= Game.Missile
		local GameIsChatOpen			= Game.IsChatOpen
		local GameIsOnTop				= Game.IsOnTop
		local _Q							= _Q
		local _W							= _W
		local _E							= _E
		local _R							= _R
		local MOUSEEVENTF_RIGHTDOWN			= MOUSEEVENTF_RIGHTDOWN
		local MOUSEEVENTF_RIGHTUP			= MOUSEEVENTF_RIGHTUP
		local Obj_AI_Hero					= Obj_AI_Hero
		local Obj_AI_Minion					= Obj_AI_Minion
		local Obj_AI_Turret					= Obj_AI_Turret
		local pairs							= pairs
		local MathCeil					= math.ceil
		local MathMax					= math.max
		local MathMin					= math.min
		local MathSqrt					= math.sqrt
		local MathRandom				= math.random
		local MathHuge					= math.huge
		local MathAbs					= math.abs
		local DAMAGE_TYPE_PHYSICAL			= 0
		local DAMAGE_TYPE_MAGICAL			= 1
		local DAMAGE_TYPE_TRUE				= 2
		local MINION_TYPE_OTHER_MINION		= 1
		local MINION_TYPE_MONSTER			= 2
		local MINION_TYPE_LANE_MINION		= 3
		local ORBWALKER_MODE_NONE			= -1
		local ORBWALKER_MODE_COMBO			= 0
		local ORBWALKER_MODE_HARASS			= 1
		local ORBWALKER_MODE_LANECLEAR		= 2
		local ORBWALKER_MODE_JUNGLECLEAR	= 3
		local ORBWALKER_MODE_LASTHIT		= 4
		local ORBWALKER_MODE_FLEE			= 5
		local TEAM_ALLY						= myHero.team
		local TEAM_ENEMY					= 300 - TEAM_ALLY
		local TEAM_JUNGLE					= 300
		local MAXIMUM_MOUSE_DISTANCE		= 120 * 120
		local TableInsert					= _G.table.insert
		local TableRemove					= _G.table.remove
	----------------------------------------------------------------------------------------------------------------------------------------------------
	-- Lists:																																			
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
		local BaseTurrets =
		{
			["SRUAP_Turret_Order3"] = true,
			["SRUAP_Turret_Order4"] = true,
			["SRUAP_Turret_Chaos3"] = true,
			["SRUAP_Turret_Chaos4"] = true
		}
		local Obj_AI_Bases =
		{
			[Obj_AI_Hero] = true,
			[Obj_AI_Minion] = true,
			[Obj_AI_Turret] = true
		}
		local function HasBuff(unit, name)
			for i = 0, unit.buffCount do
				local buff = unit:GetBuff(i)
				if buff and buff.count > 0 and buff.name == name then
					return true
				end
			end
			return false
		end
		local ChannelingBuffs =
		{
			["Caitlyn"] = function(unit)
				return HasBuff(unit, "CaitlynAceintheHole")
			end,
			["Fiddlesticks"] = function(unit)
				return HasBuff(unit, "Drain") or HasBuff(unit, "Crowstorm")
			end,
			["Galio"] = function(unit)
				return HasBuff(unit, "GalioIdolOfDurand")
			end,
			["Janna"] = function(unit)
				return HasBuff(unit, "ReapTheWhirlwind")
			end,
			["Kaisa"] = function(unit)
				return HasBuff(unit, "KaisaE")
			end,
			["Karthus"] = function(unit)
				return HasBuff(unit, "karthusfallenonecastsound")
			end,
			["Katarina"] = function(unit)
				return HasBuff(unit, "katarinarsound")
			end,
			["Lucian"] = function(unit)
				return HasBuff(unit, "LucianR")
			end,
			["Malzahar"] = function(unit)
				return HasBuff(unit, "alzaharnethergraspsound")
			end,
			["MasterYi"] = function(unit)
				return HasBuff(unit, "Meditate")
			end,
			["MissFortune"] = function(unit)
				return HasBuff(unit, "missfortunebulletsound")
			end,
			["Nunu"] = function(unit)
				return HasBuff(unit, "AbsoluteZero")
			end,
			["Pantheon"] = function(unit)
				return HasBuff(unit, "pantheonesound") or HasBuff(unit, "PantheonRJump")
			end,
			["Shen"] = function(unit)
				return HasBuff(unit, "shenstandunitedlock")
			end,
			["TwistedFate"] = function(unit)
				return HasBuff(unit, "Destiny")
			end,
			["Urgot"] = function(unit)
				return HasBuff(unit, "UrgotSwap2")
			end,
			["Varus"] = function(unit)
				return HasBuff(unit, "VarusQ")
			end,
			["VelKoz"] = function(unit)
				return HasBuff(unit, "VelkozR")
			end,
			["Vi"] = function(unit)
				return HasBuff(unit, "ViQ")
			end,
			["Vladimir"] = function(unit)
				return HasBuff(unit, "VladimirE")
			end,
			["Warwick"] = function(unit)
				return HasBuff(unit, "infiniteduresssound")
			end,
			["Xerath"] = function(unit)
				return HasBuff(unit, "XerathArcanopulseChargeUp") or HasBuff(unit, "XerathLocusOfPower2")
			end
		}
		local MinionsRange =
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
		local SpecialAutoAttackRanges =
		{
			["Caitlyn"] = function(target)
				if target ~= nil and HasBuff(target, "caitlynyordletrapinternal") then
					return 650
				end
				return 0
			end
		}
		local SpecialWindUpTimes =
		{
			["TwistedFate"] = function(unit, target)
				if HasBuff(unit, "BlueCardPreAttack") or HasBuff(unit, "RedCardPreAttack") or HasBuff(unit, "GoldCardPreAttack") then
					return 0.125
				end
				return nil
			end
		}
		local SpecialMissileSpeeds =
		{
			["Caitlyn"] = function(unit, target)
				if HasBuff(unit, "caitlynheadshot") then
					return 3000
				end
				return nil
			end,
			["Graves"] = function(unit, target)
				return 3800
			end,
			["Illaoi"] = function(unit, target)
				if HasBuff(unit, "IllaoiW") then
					return 1600
				end
				return nil
			end,
			["Jayce"] = function(unit, target)
				if HasBuff(unit, "jaycestancegun") then
					return 2000
				end
				return nil
			end,
			["Jhin"] = function(unit, target)
				if HasBuff(unit, "jhinpassiveattackbuff") then
					return 3000
				end
				return nil
			end,
			["Jinx"] = function(unit, target)
				if HasBuff(unit, "JinxQ") then
					return 2000
				end
				return nil
			end,
			["Poppy"] = function(unit, target)
				if HasBuff(unit, "poppypassivebuff") then
					return 1600
				end
				return nil
			end,
			["Twitch"] = function(unit, target)
				if HasBuff(unit, "TwitchFullAutomatic") then
					return 4000
				end
				return nil
			end
		}
		local TurretToMinionPercentMod =
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
		local MinionIsMelee =
		{
			["SRU_ChaosMinionMelee"] = true, ["SRU_ChaosMinionSuper"] = true,  ["SRU_OrderMinionMelee"] = true, ["SRU_OrderMinionSuper"] = true, ["HA_ChaosMinionMelee"] = true,
			["HA_ChaosMinionSuper"] = true, ["HA_OrderMinionMelee"] = true, ["HA_OrderMinionSuper"] = true
		}
		local NoAutoAttacks =
		{
			["GravesAutoAttackRecoil"] = true
		}
		local SpecialAutoAttacks =
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
		local IsMelee =
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
		local SpecialMelees =
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
		local Priorities =
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
		local PriorityMultiplier =
		{
			[1] = 1.6,
			[2] = 1.45,
			[3] = 1.3,
			[4] = 1.15,
			[5] = 1
		}
	----------------------------------------------------------------------------------------------------------------------------------------------------
	-- Methods:																																			
		local function Join(t1, t2, t3, t4, t5, t6)
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
		local function GetBuffCount(unit, name)
			for i = 0, unit.buffCount do
				local buff = unit:GetBuff(i)
				if buff and buff.count > 0 and buff.name == name then
					return buff.count
				end
			end
			return -1
		end
		local function HasItem(unit, id)
			for i = 1, #ItemSlots do
				local slot = ItemSlots[i]
				local item = unit:GetItemData(slot)
				if item then
					local itemID = item.itemID
					if itemID > 0 and itemID == id then
						return true
					end
				end
			end
		end
		local function GetDistance2DSquared(a, b)
			local x = (a.x - b.x)
			local y = (a.y - b.y)
			return x * x + y * y
		end
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
		local function TotalShieldHealth(target)
			local result = target.health + target.shieldAD + target.shieldAP
			if target.charName == "Blitzcrank" then
				if not HasBuff(target, "manabarriercooldown") and not HasBuff(target, "manabarrier") then
					result = result + target.mana * 0.5
				end
			end
			return result
		end
		local function IsChanneling(unit)
			if ChannelingBuffs[unit.charName] ~= nil then
				return ChannelingBuffs[unit.charName](unit)
			end
			return false
		end
		local function IsValidTarget(target)
			if target == nil or target.networkID == nil then
				return false
			end
			if Obj_AI_Bases[target.type] ~= nil then
				if not target.valid then
					return false
				end
			end
			if target.dead or (not target.visible) or (not target.isTargetable) then
				return false
			end
			return true
		end
		local function GetAutoAttackRange(from, target)
			local result = from.range
			if from.type == Obj_AI_Minion then
				result = MinionsRange[from.charName] ~= nil and MinionsRange[from.charName] or 0
			elseif from.type == Obj_AI_Turret then
				result = 775
			end
			result = result + from.boundingRadius + (target ~= nil and (target.boundingRadius - 20) or 35)
			if target.type == Obj_AI_Hero and SpecialAutoAttackRanges[from.charName] ~= nil then
				result = result + SpecialAutoAttackRanges[from.charName](target)
			end
			return result
		end
		local function IsInAutoAttackRange(from, target)
			return IsInRange(from, target, GetAutoAttackRange(from, target))
		end
		local function GetProjSpeed()
			if IsMelee[MeCharName] or (SpecialMelees[MeCharName] ~= nil and SpecialMelees[MeCharName]()) then
				return math.huge
			end
			if SpecialMissileSpeeds[MeCharName] ~= nil then
				local projectileSpeed = SpecialMissileSpeeds[MeCharName](myHero)
				if projectileSpeed then
					return projectileSpeed
				end
			end
			if myHero.attackData.projectileSpeed then
				return myHero.attackData.projectileSpeed
			elseif Orbwalker.AttackProjSpeed > 0 then
				return Orbwalker.AttackProjSpeed
			end
			return math.huge
		end
		local function GetWindup()
			if SpecialWindUpTimes[MeCharName] ~= nil then
				local SpecialWindUpTime = SpecialWindUpTimes[MeCharName](myHero)
				if SpecialWindUpTime then
					return SpecialWindUpTime
				end
			end
			if Orbwalker.AttackWindUp > 0 then
				return Orbwalker.AttackWindUp
			elseif myHero.attackData.windUpTime then
				return myHero.attackData.windUpTime
			end
			return 0.25
		end
		local function GetHumanizer()
			local humnum
			if Menu.orb.humanizer.random.enabled:Value() then
				local fromhum = Menu.orb.humanizer.random.from:Value()
				local tohum = Menu.orb.humanizer.random.to:Value()
				if tohum <= fromhum then
					humnum = fromhum * 0.001
				else
					humnum = MathRandom(fromhum, tohum) * 0.001
				end
			else
				humnum = Menu.orb.humanizer.standard:Value() * 0.001
			end
			return humnum
		end
		local function ResetMenu()
            MenuChamp.lcore.enabled:Value(false)
            MenuChamp.lcore.response:Value(false)
            MenuChamp.lcore.extraw:Value(100)
            MenuChamp.hold.HoldRadius:Value(120)
            MenuChamp.spell.isaa:Value(true)
			MenuChamp.spell.baa:Value(false)
			MenuChamp.lclear.laneset:Value(true)
			MenuChamp.lclear.swait:Value(500)
        end
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Cursor Class:																																		
	do
		local __Cursor = Core:Class()
		function __Cursor:__init()
			self.StartTime = 0
			self.IsReady = true
			self.IsReadyGlobal = true
			self.Key = nil
			self.CursorPos = nil
			self.CastPos = nil
			self.Work = nil
			self.WorkDone = true
			self.EndTime = 0
		end
		function __Cursor:CastKey()
			if self.CastPos == nil then return end
			local newpos
			if self.CastPos.pos then
				newpos = Vector(self.CastPos.pos.x, self.CastPos.pos.y + self.CastPos.boundingRadius, self.CastPos.pos.z):To2D()
				--newpos = Vector(self.CastPos.pos.x, self.CastPos.pos.y, self.CastPos.pos.z + self.CastPos.boundingRadius * 0.5):To2D()
			else
				newpos = self.CastPos:To2D()
			end
			ControlSetCursorPos(newpos.x, newpos.y)
			if self.Work ~= nil then--and GetDistance2DSquared(newpos, _G.cursorPos) <= MAXIMUM_MOUSE_DISTANCE then
				self.Work()
				self.Work = nil
			end
		end
		function __Cursor:SetCursor(cursorpos, castpos, key, work)
			self.StartTime = GameTimer()
			self.IsReady = false
			self.IsReadyGlobal = false
			self.Key = key
			self.CursorPos = cursorpos
			self.CastPos = castpos
			self.Work = work
			self.WorkDone = false
			self.EndTime = 0
			self:CastKey()
		end
		function __Cursor:Tick()
			if self.IsReady then return end
			if not self.WorkDone and (self.IsReadyGlobal or GameTimer() > self.StartTime + 0.1) then
				if not self.IsReadyGlobal then
					self.IsReadyGlobal = true
				end
				local extradelay = Menu.orb.excdelay:Value()
				if extradelay == 0 then
					self.EndTime = 0
				else
					self.EndTime = GameTimer() + extradelay * 0.001
				end
				self.WorkDone = true
			end
			if self.WorkDone and GameTimer() > self.EndTime then
				ControlSetCursorPos(self.CursorPos.x, self.CursorPos.y)
				if GetDistance2DSquared(self.CursorPos, _G.cursorPos) <= MAXIMUM_MOUSE_DISTANCE then
					self.IsReady = true
				end
				return
			end
			self:CastKey()
		end
		function __Cursor:CreateDrawMenu(menu)
			Menu.gsodraw:MenuElement({name = "Cursor Pos",  id = "cursor", type = _G.MENU})
				Menu.gsodraw.cursor:MenuElement({name = "Enabled",  id = "enabled", value = true})
				Menu.gsodraw.cursor:MenuElement({name = "Color",  id = "color", color = DrawColor(255, 153, 0, 76)})
				Menu.gsodraw.cursor:MenuElement({name = "Width",  id = "width", value = 3, min = 1, max = 10})
				Menu.gsodraw.cursor:MenuElement({name = "Radius",  id = "radius", value = 150, min = 1, max = 300})
		end
		function __Cursor:Draw()
			if Menu.gsodraw.cursor.enabled:Value() then
				DrawCircle(mousePos, Menu.gsodraw.cursor.radius:Value(), Menu.gsodraw.cursor.width:Value(), Menu.gsodraw.cursor.color:Value())
			end
		end
		CURSOR = __Cursor()
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- _G.SDK.Spells:																																		
	do
		local __Spells = Core:Class()
		function __Spells:__init()
			self.LastQ = 0
			self.LastW = 0
			self.LastE = 0
			self.LastR = 0
			self.LastQk = 0
			self.LastWk = 0
			self.LastEk = 0
			self.LastRk = 0
			self.Work = nil
			self.WorkEndTime = 0
			self.ObjectEndTime = 0
			self.SpellEndTime = 0
			self.CanNext = true
			self.StartTime = 0
			self.DelayedSpell = {}
			self.WindupList =
			{
				["VayneCondemn"] = 0.6,
				["UrgotE"] = 1,
				["TristanaW"] = 0.9,
				["TristanaE"] = 0.15,
				["ThreshQInternal"] = 1.25,
				["ThreshE"] = 0.75,
				["ThreshRPenta"] = 0.75
			}
			self.WorkList =
			{
				["UrgotE"] =
				{
					1.5,
					function()
						for i = 1, GameParticleCount() do
							local obj = GameParticle(i)
							if obj ~= nil and obj.name == "Urgot_Base_E_tar" then
								self.ObjectEndTime = GameTimer() + 0.75
								self.Work = nil
								break
							end
						end
					end
				},
				["ThreshQInternal"] =
				{
					3,
					function()
						for i = 1, GameParticleCount() do
							local obj = GameParticle(i)
							if obj ~= nil and obj.name == "Thresh_Base_Q_stab_tar" then
								self.ObjectEndTime = GameTimer() + 1
								self.Work = nil
								break
							end
						end
					end
				}
			}
		end
		function __Spells:DisableAutoAttack()
			local a = myHero.activeSpell
			if a and a.valid and a.startTime > self.StartTime and myHero.isChanneling and not SpecialAutoAttacks[a.name] then
				local name = a.name
				if self.Work == nil and GameTimer() > self.WorkEndTime and self.WorkList[name] ~= nil then
					self.WorkEndTime = GameTimer() + self.WorkList[name][1]
					self.Work = self.WorkList[name][2]
				end
				local twindup = self.WindupList[name]
				local windup = twindup ~= nil and twindup or a.windup
				local t = a.startTime + windup
				t = t - Core:GetLatency()
				self.SpellEndTime = t
				self.StartTime = a.startTime
				if GameTimer() < Orbwalker.AttackLocalStart + Orbwalker.AttackWindUp - 0.09 or GameTimer() < Orbwalker.AttackCastEndTime - 0.1 then
					Orbwalker:__OnAutoAttackReset()
				end
				return true
			end
			return false
		end
		function __Spells:WndMsg(msg, wParam)
			local manualNum = -1
			local currentTime = GameTimer()
			if wParam == HK_Q and currentTime > self.LastQk + 0.33 and GameCanUseSpell(_Q) == 0 then
				self.LastQk = currentTime
				manualNum = 0
			elseif wParam == HK_W and currentTime > self.LastWk + 0.33 and GameCanUseSpell(_W) == 0 then
				self.LastWk = currentTime
				manualNum = 1
			elseif wParam == HK_E and currentTime > self.LastEk + 0.33 and GameCanUseSpell(_E) == 0 then
				self.LastEk = currentTime
				manualNum = 2
			elseif wParam == HK_R and currentTime > self.LastRk + 0.33 and GameCanUseSpell(_R) == 0 then
				self.LastRk = currentTime
				manualNum = 3
			end
			if manualNum > -1 and not self.DelayedSpell[manualNum] and not _G.SDK.Orbwalker.IsNone then
				self.DelayedSpell[manualNum] =
				{
					function()
						ControlKeyDown(wParam)
						ControlKeyUp(wParam)
						ControlKeyDown(wParam)
						ControlKeyUp(wParam)
						ControlKeyDown(wParam)
						ControlKeyUp(wParam)
					end,
					currentTime
				}
			end
		end
		function __Spells:IsReady(spell, delays)
			delays = delays or { q = 0.25, w = 0.25, e = 0.25, r = 0.25 }
			local currentTime = GameTimer()
			if not CURSOR.IsReady or CONTROLL ~= nil or currentTime <= NEXT_CONTROLL + 0.05 then
				return false
			end
			if currentTime < self.LastQ + delays.q or currentTime < self.LastQk + delays.q then
				return false
			end
			if currentTime < self.LastW + delays.w or currentTime < self.LastWk + delays.w then
				return false
			end
			if currentTime < self.LastE + delays.e or currentTime < self.LastEk + delays.e then
				return false
			end
			if currentTime < self.LastR + delays.r or currentTime < self.LastRk + delays.r then
				return false
			end
			if GameCanUseSpell(spell) ~= 0 then
				return false
			end
			return true
		end
		function __Spells:CastManualSpell(spell, delays)
			if self:IsReady(spell, delays) then
				local kNum = 0
				if spell == _W then
					  kNum = 1
				elseif spell == _E then
					  kNum = 2
				elseif spell == _R then
					  kNum = 3
				end
				local currentTime = GameTimer()
				for k,v in pairs(self.DelayedSpell) do
					if currentTime - v[2] > 0.125 then
						self.DelayedSpell[k] = nil
					elseif k == kNum then
						v[1]()
						if k == 0 then
							self.LastQ = currentTime
						elseif k == 1 then
							self.LastW = currentTime
						elseif k == 2 then
							self.LastE = currentTime
						elseif k == 3 then
							self.LastR = currentTime
						end
						self.DelayedSpell[k] = nil
						break
					end
				end
			end
		end
		function __Spells:CustomIsReady(spell, cd)
			local passT
			if spell == _Q then
				passT = GameTimer() - self.LastQk
			elseif spell == _W then
				passT = GameTimer() - self.LastWk
			elseif spell == _E then
				passT = GameTimer() - self.LastEk
			elseif spell == _R then
				passT = GameTimer() - self.LastRk
			end
			local cdr = 1 - myHero.cdr
			cd = cd * cdr
			local latency = Core:GetLatency()
			if passT - latency - 0.15 > cd then
				return true
			end
			return false
		end
		function __Spells:GetLastSpellTimers()
			return self.LastQ, self.LastQk, self.LastW, self.LastWk, self.LastE, self.LastEk, self.LastR, self.LastRk
		end
		function __Spells:CheckSpellDelays(delays)
			local currentTime = GameTimer()
			if currentTime < self.LastQ + delays.q or currentTime < self.LastQk + delays.q then
				return false
			end
			if currentTime < self.LastW + delays.w or currentTime < self.LastWk + delays.w then
				return false
			end
			if currentTime < self.LastE + delays.e or currentTime < self.LastEk + delays.e then
				return false
			end
			if currentTime < self.LastR + delays.r or currentTime < self.LastRk + delays.r then
				return false
			end
			return true
		end
		function __Spells:SpellClear(spell, spelldata, damagefunc)
			local c = {}
			local result =
			{
				Delay = spelldata.Delay,
				Speed = spelldata.Speed,
				Range = spelldata.Range,
				TurretHasTarget = false,
				CanCheckTurret = true,
				ShouldWaitTime = 0,
				IsLastHitable = false,
				LastHandle = 0,
				LastLCHandle = 0,
				FarmMinions = {}
			}
			-- init
				c.__index = c
				setmetatable(result, c)
			function c:GetLastHitTargets()
				local result = {}
				if self.IsLastHitable and not Orbwalker.IsNone and not Orbwalker.Modes[ORBWALKER_MODE_COMBO] then
					for i, minion in pairs(self.FarmMinions) do
						if minion.LastHitable then
							local unit = minion.Minion
							if unit.handle ~= HealthPrediction.LastHandle and not unit.dead then
								result[#result+1] = unit
							end
						end
					end
				end
				return result
			end
			function c:GetLaneClearTargets()
				local result = {}
				if Orbwalker.Modes[ORBWALKER_MODE_LANECLEAR] and self:CanLaneClear() then
					for i, minion in pairs(self.FarmMinions) do
						local unit = minion.Minion
						if unit.handle ~= HealthPrediction.LastLCHandle and not unit.dead then
							result[#result+1] = unit
						end
					end
				end
				return result
			end
			function c:GetObjects(team)
				if team == TEAM_ALLY then
					return HealthPrediction.CachedTeamAlly
				elseif team == TEAM_ENEMY then
					return HealthPrediction.CachedTeamEnemy
				elseif team == TEAM_JUNGLE then
					return HealthPrediction.CachedTeamJungle
				end
			end
			function c:SetAttacks(target)
				-- target handle
				local handle = target.handle
				-- Cached Attacks
				if HealthPrediction.CachedAttacks[handle] == nil then
					HealthPrediction.CachedAttacks[handle] = {}
					-- target team
					local team = target.team
					-- charName
					local name = target.charName
					-- set attacks
					local pos = target.pos
					-- cached objects
					HealthPrediction:SetObjects(team)
					local attackers = self:GetObjects(team)
					for i = 1, #attackers do
						local obj = attackers[i]
						local objname = obj.charName
						if HealthPrediction.CachedAttackData[objname] == nil then
							HealthPrediction.CachedAttackData[objname] = {}
						end
						if HealthPrediction.CachedAttackData[objname][name] == nil then
							HealthPrediction.CachedAttackData[objname][name] = { Range = GetAutoAttackRange(obj, target), Damage = 0 }
						end
						local range = HealthPrediction.CachedAttackData[objname][name].Range + 100
						if GetDistanceSquared(obj.pos, pos) < range * range then
							if HealthPrediction.CachedAttackData[objname][name].Damage == 0 then
								HealthPrediction.CachedAttackData[objname][name].Damage = Damage:GetAutoAttackDamage(obj, target)
							end
							HealthPrediction.CachedAttacks[handle][#HealthPrediction.CachedAttacks[handle]+1] = {
								Attacker = obj,
								Damage = HealthPrediction.CachedAttackData[objname][name].Damage,
								Type = obj.type
							}
						end
					end
				end
				return HealthPrediction.CachedAttacks[handle]
			end
			function c:GetPossibleDmg(target)
				local result = 0
				local handle = target.handle
				local attacks = HealthPrediction.CachedAttacks[handle]
				if #attacks == 0 then return 0 end
				local pos = target.pos
				for i = 1, #attacks do
					local attack = attacks[i]
					local attacker = attack.Attacker
					if (not self.TurretHasTarget and attack.Type == Obj_AI_Turret) or (attack.Type == Obj_AI_Minion and attacker.pathing.hasMovePath) then
						result = result + attack.Damage
					end
				end
				return result
			end
			function c:GetPrediction(target, time)
				self:SetAttacks(target)
				local handle = target.handle
				local attacks = HealthPrediction.CachedAttacks[handle]
				local hp = TotalShieldHealth(target)
				if #attacks == 0 then return hp end
				local pos = target.pos
				for i = 1, #attacks do
					local attack = attacks[i]
					local attacker = attack.Attacker
					local dmg = attack.Damage
					local objtype = attack.Type
					local isTurret = objtype == Obj_AI_Turret
					local time2 = time
					if isTurret then
						time2 = time2 - 0.1
					end
					local ismoving = false
					if not isTurret then ismoving = attacker.pathing.hasMovePath end
					if attacker.attackData.target == handle and not ismoving then
						if isTurret and self.CanCheckTurret then
							self.TurretHasTarget = true
						end
						local flyTime
						if attacker.attackData.projectileSpeed and attacker.attackData.projectileSpeed > 0 then
							flyTime = attacker.pos:DistanceTo(pos) / attacker.attackData.projectileSpeed
						else
							flyTime = 0
						end
						local endTime = (attacker.attackData.endTime - attacker.attackData.animationTime) + flyTime + attacker.attackData.windUpTime
						if endTime <= GameTimer() then
							endTime = endTime + attacker.attackData.animationTime + flyTime
						end
						while endTime - GameTimer() < time2 do
							hp = hp - dmg
							endTime = endTime + attacker.attackData.animationTime + flyTime
						end
					end
				end
				return hp
			end
			function c:ShouldWait()
				return GameTimer() <= self.ShouldWaitTime + MenuChamp.lclear.swait:Value() * 0.001
			end
			function c:SetLastHitable(target, time, damage)
				local hpPred = self:GetPrediction(target, time)
				local lastHitable = hpPred - damage < 0
				if lastHitable then self.IsLastHitable = true end
				local almostLastHitable = false
				if not lastHitable then
					local dmg = self:GetPrediction(target, myHero:GetSpellData(spell).cd + (time * 3)) - self:GetPossibleDmg(target)
					almostLastHitable = dmg - damage < 0
				end
				if almostLastHitable then
					self.ShouldWaitTime = GameTimer()
				end
				return { LastHitable =  lastHitable, Unkillable = hpPred < 0, Time = time, AlmostLastHitable = almostLastHitable, PredictedHP = hpPred, Minion = target }
			end
			function c:Tick()
				self.FarmMinions = {}
				self.TurretHasTarget = false
				self.CanCheckTurret = true
				self.IsLastHitable = false
				if myHero:GetSpellData(spell).level == 0 then
					return
				end
				if myHero.mana < myHero:GetSpellData(spell).mana then
					return
				end
				if GameCanUseSpell(spell) ~= 0 and myHero:GetSpellData(spell).currentCd > 0.5 then
					return
				end
				if Orbwalker.Modes[ORBWALKER_MODE_COMBO] or Orbwalker.IsNone then
					return
				end
				local targets = ObjectManager:GetEnemyMinions(self.Range - 35, false)
				local projectileSpeed = self.Speed
				local winduptime = self.Delay
				local latency = Core:GetLatency() * 0.5
				local pos = myHero.pos
				for i = 1, #targets do
					local target = targets[i]
					local FlyTime = pos:DistanceTo(target.pos) / projectileSpeed
					self.FarmMinions[#self.FarmMinions+1] = self:SetLastHitable(target, winduptime + FlyTime + latency, damagefunc())
				end
				self.CanCheckTurret = false
			end
			return result
		end
		Spells = __Spells()
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- _G.SDK.TargetSelector:																																
	do
		local __TargetSelector = Core:Class()
		function __TargetSelector:__init()
			self.SelectedTarget = nil
			self.LastSelTick = 0
		end
		function __TargetSelector:GetTarget(a, dmgType, bb, validmode)
			local SelectedID = -1
			--selected:
			if Menu.ts.selected.enable:Value() and self.SelectedTarget ~= nil and IsValidTarget(self.SelectedTarget) and not ObjectManager:IsHeroImmortal(self.SelectedTarget, false) and self.SelectedTarget.pos.onScreen then
				SelectedID = self.SelectedTarget.networkID
				if Menu.ts.selected.onlysel:Value() then
					if type(a) == "number" then
						if GetDistanceSquared(myHero.pos, self.SelectedTarget.pos) <= a * a then
							return self.SelectedTarget
						end
					elseif type(a) == "table" then
						local x = 0
						for i = 1, #a do
							local u = a[i]
							if u then
								local dist = GetDistanceSquared(myHero.pos, u.pos)
								if dist > x then
									x = dist
								end
							end
						end
						if GetDistanceSquared(myHero.pos, self.SelectedTarget.pos) <= x * x then
							return self.SelectedTarget
						end
					end
					return nil
				end
			end
			--others:
			if dmdType == nil or dmgType < 0 or dmgType > 2 then
				dmgType = 1
			end
			local result = nil
			if type(a) == "table" then
				if #a == 1 then return a[1] end
				local num = 10000000
				local mode = Menu.ts.Mode:Value()
				for i = 1, #a do
					local x
					local unit = a[i]
					if SelectedID ~= -1 and SelectedID == unit.networkID then
						return self.SelectedTarget
					elseif mode == 1 then
						local unitName = unit.charName
						local priority
						if Menu.ts.priorities[unitName] then
							priority = Menu.ts.priorities[unitName]:Value()
						else
							priority = 1
						end
						local multiplier = PriorityMultiplier[priority]
						local def
						if dmgType == DAMAGE_TYPE_MAGICAL then
							def = multiplier * (unit.magicResist - myHero.magicPen)
						elseif dmgType == DAMAGE_TYPE_PHYSICAL then
							def = multiplier * (unit.armor - myHero.armorPen)
						else
							def = 0
						end
						if def and def > 0 then
							if dmgType == DAMAGE_TYPE_MAGICAL then
								def = myHero.magicPenPercent * def
							elseif dmgType == DAMAGE_TYPE_PHYSICAL then
								def = myHero.bonusArmorPenPercent * def
							else
								def = 0
							end
						end
						x = ( ( unit.health * multiplier * ( ( 100 + def ) / 100 ) ) - ( unit.totalDamage * unit.attackSpeed * 2 ) ) - unit.ap
					elseif mode == 2 then
						x = unit.pos:DistanceTo(myHero.pos)
					elseif mode == 3 then
						x = unit.health
					elseif mode == 4 then
						local unitName = unit.charName
						if Menu.ts.priorities[unitName] then
							x = Menu.ts.priorities[unitName]:Value()
						else
							x = 1
						end
					end
					if x < num then
						num = x
						result = unit
					end
				end
			else
				local bbox = false
				if bb ~= nil and bb == true then bbox = true end
				local vmode = validmode or 0
				if a == nil or a <= 0 then
					a = 20000
				end
				return self:GetTarget(ObjectManager:GetEnemyHeroes(a, bbox, vmode), dmgType)
			end
			return result
		end
		function __TargetSelector:GetComboTarget()
			local targets = {}
			local range = myHero.range - 20
			local bbox = myHero.boundingRadius
			for i = 1, GameHeroCount() do
				local hero = GameHero(i)
				if hero and hero.team == TEAM_ENEMY and IsValidTarget(hero) and not ObjectManager:IsHeroImmortal(hero, true) then
					local herorange = range
					if MYHERO_IS_CAITLYN and HasBuff(hero, "caitlynyordletrapinternal") then
						herorange = herorange + 600
					else
						herorange = herorange + bbox + hero.boundingRadius
					end
					if GetDistanceSquared(myHero.pos, hero.pos) <= herorange * herorange then
						targets[#targets+1] = hero
					end
				end
			end
			local t = self:GetTarget(targets, DAMAGE_TYPE_PHYSICAL)
			if not ME_IS_KALISTA then
				return t
			end
			if t == nil then
				local hp = MathHuge
				for i = 1, GameHeroCount() do
					local obj = GameHero(i)
					if IsValidTarget(obj) and not obj.isAlly and IsInAutoAttackRange(myHero, obj) and obj.health < hp then
						t = obj
						hp = obj.health
					end
				end
			end
			if t == nil then
				hp = MathHuge
				for i = 1, GameMinionCount() do
					local obj = GameMinion(i)
					if IsValidTarget(obj) and not obj.isAlly and IsInAutoAttackRange(myHero, obj) and obj.health < hp then
						t = obj
						hp = obj.health
					end
				end
			end
			if t == nil then
				hp = MathHuge
				for i = 1, GameTurretCount() do
					local obj = GameTurret(i)
					if IsValidTarget(obj) and not obj.isAlly and IsInAutoAttackRange(myHero, obj) and obj.health < hp then
						t = obj
						hp = obj.health
					end
				end
			end
			return t
		end
		function __TargetSelector:WndMsg(msg, wParam)
			if msg == WM_LBUTTONDOWN and Menu.ts.selected.enable:Value() and GetTickCount() > self.LastSelTick + 100 then
				self.SelectedTarget = nil
				local num = 10000000
				local enemyList = ObjectManager:GetEnemyHeroes(99999999, false, 2)
				for i = 1, #enemyList do
					local unit = enemyList[i]
					local distance = mousePos:DistanceTo(unit.pos)
					if distance < 150 and distance < num then
						self.SelectedTarget = unit
						num = distance
					end
				end
				self.LastSelTick = GetTickCount()
			end
		end
		function __TargetSelector:Draw()
			if Menu.gsodraw.selected.enabled:Value() then
				if self.SelectedTarget and not self.SelectedTarget.dead and self.SelectedTarget.isTargetable and self.SelectedTarget.visible and self.SelectedTarget.valid then
					DrawCircle(self.SelectedTarget.pos, Menu.gsodraw.selected.radius:Value(), Menu.gsodraw.selected.width:Value(), Menu.gsodraw.selected.color:Value())
				end
			end
		end
		function __TargetSelector:CreatePriorityMenu(charName)
			local priority
			if Priorities[charName] ~= nil then
				priority = Priorities[charName]
			else
				priority = 1
			end
			Menu.ts.priorities:MenuElement({ id = charName, name = charName, value = priority, min = 1, max = 5, step = 1 })
		end
		function __TargetSelector:CreateMenu()
			Menu:MenuElement({name = "Target Selector", id = "ts", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/ts.png" })
				Menu.ts:MenuElement({ id = "Mode", name = "Mode", value = 1, drop = { "Auto", "Closest", "Least Health", "Highest Priority" } })
				Menu.ts:MenuElement({ id = "priorities", name = "Priorities", type = _G.MENU })
					Core:OnEnemyHeroLoad(function(hero) self:CreatePriorityMenu(hero.charName) end)
				Menu.ts:MenuElement({ id = "selected", name = "Selected Target", type = _G.MENU })
					Menu.ts.selected:MenuElement({ id = "enable", name = "Enabled", value = true })
					Menu.ts.selected:MenuElement({ id = "onlysel", name = "Only Selected", value = false })
		end
		function __TargetSelector:CreateDrawMenu()
			Menu.gsodraw:MenuElement({name = "Selected Target",  id = "selected", type = _G.MENU})
				Menu.gsodraw.selected:MenuElement({name = "Enabled",  id = "enabled", value = true})
				Menu.gsodraw.selected:MenuElement({name = "Color",  id = "color", color = DrawColor(255, 204, 0, 0)})
				Menu.gsodraw.selected:MenuElement({name = "Width",  id = "width", value = 3, min = 1, max = 10})
				Menu.gsodraw.selected:MenuElement({name = "Radius",  id = "radius", value = 150, min = 1, max = 300})
		end
		function __TargetSelector:GetPriority(target)
			local x = Priorities[target.charName]
			if x ~= nil then
				return x
			end
			return 1
		end
		TargetSelector = __TargetSelector()
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- _G.SDK.ObjectManager:																																
	do
		local __ObjectManager = Core:Class()
		------------------------------------------------------------------------------------------------------------------------------------------------
		function __ObjectManager:__init()
			self.UndyingBuffs = { ["zhonyasringshield"] = true }
		end
		------------------------------------------------------------------------------------------------------------------------------------------------
		function __ObjectManager:IsHeroImmortal(unit, jaxE)
			local hp = 100 * ( unit.health / unit.maxHealth )
			if self.UndyingBuffs["JaxCounterStrike"] ~= nil then self.UndyingBuffs["JaxCounterStrike"] = jaxE end
			if self.UndyingBuffs["kindredrnodeathbuff"] ~= nil then self.UndyingBuffs["kindredrnodeathbuff"] = hp < 10 end
			if self.UndyingBuffs["UndyingRage"] ~= nil then self.UndyingBuffs["UndyingRage"] = hp < 15 end
			if self.UndyingBuffs["ChronoShift"] ~= nil then self.UndyingBuffs["ChronoShift"] = hp < 15; self.UndyingBuffs["chronorevive"] = hp < 15 end
			for i = 0, unit.buffCount do
				local buff = unit:GetBuff(i)
				if buff and buff.count > 0 and self.UndyingBuffs[buff.name] then
					return true
				end
			end
			return false
		end
		------------------------------------------------------------------------------------------------------------------------------------------------
		function __ObjectManager:GetEnemyBuildings(range, bb)
			local result = {}
			local turrets = Core:GetEnemyTurrets()
			local inhibitors = Core:GetEnemyInhibitors()
			local nexus = Core:GetEnemyNexus()
			local br = bb and range + 270 - 30 or range --myHero.range + 270 bbox
			local nr = bb and range + 380 - 30 or range --myHero.range + 380 bbox
			for i = 1, #turrets do
				local turret = turrets[i]
				local tr = bb and range + turret.boundingRadius * 0.75 or range
				if turret and IsValidTarget(turret) and GetDistanceSquared(myHero.pos, turret.pos) < tr * tr then
					result[#result+1] = turret
				end
			end
			for i = 1, #inhibitors do
				local barrack = inhibitors[i]
				if barrack and barrack.isTargetable and barrack.visible and GetDistanceSquared(myHero.pos, barrack.pos) < br * br then
					result[#result+1] = barrack
				end
			end
			if nexus and nexus.isTargetable and nexus.visible and GetDistanceSquared(myHero.pos, nexus.pos) < nr * nr then
				result[#result+1] = nexus
			end
			return result
		end
		------------------------------------------------------------------------------------------------------------------------------------------------
		function __ObjectManager:GetMinionType(minion)
			if minion.team == TEAM_JUNGLE then
				return MINION_TYPE_MONSTER
			elseif minion.maxHealth <= 6 then
				return MINION_TYPE_OTHER_MINION
			else
				return MINION_TYPE_LANE_MINION
			end
		end
		------------------------------------------------------------------------------------------------------------------------------------------------
		function __ObjectManager:GetMinions(range)
			local result = {}
			for i = 1, GameMinionCount() do
				local minion = GameMinion(i)
				if IsValidTarget(minion) and self:GetMinionType(minion) == MINION_TYPE_LANE_MINION then
					if IsInRange(myHero, minion, range) then
						TableInsert(result, minion)
					end
				end
			end
			return result
		end
		------------------------------------------------------------------------------------------------------------------------------------------------
		function __ObjectManager:GetAllyMinions(range, bb)
			local result = {}
			for i = 1, GameMinionCount() do
				local minion = GameMinion(i)
				local mr = bb and range + minion.boundingRadius or range
				if minion and minion.team == TEAM_ALLY and IsValidTarget(minion) and self:GetMinionType(minion) == MINION_TYPE_LANE_MINION and IsInRange(myHero, minion, mr) then
					result[#result+1] = minion
				end
			end
			return result
		end
		------------------------------------------------------------------------------------------------------------------------------------------------
		function __ObjectManager:GetEnemyMinions(range)
			local result = {}
			for i = 1, GameMinionCount() do
				local minion = GameMinion(i)
				local mr = bb and range + minion.boundingRadius or range
				if minion and minion.team == TEAM_ENEMY and IsValidTarget(minion) and IsInRange(myHero, minion, mr) and self:GetMinionType(minion) == MINION_TYPE_LANE_MINION then
					result[#result+1] = minion
				end
			end
			return result
		end
		------------------------------------------------------------------------------------------------------------------------------------------------
		function __ObjectManager:GetEnemyMinionsInAutoAttackRange()
			local result = {}
			for i = 1, GameMinionCount() do
				local minion = GameMinion(i)
				if IsValidTarget(minion) and minion.isEnemy and self:GetMinionType(minion) == MINION_TYPE_LANE_MINION then
					if IsInAutoAttackRange(myHero, minion) then
						TableInsert(result, minion)
					end
				end
			end
			return result
		end
		------------------------------------------------------------------------------------------------------------------------------------------------
		function __ObjectManager:GetOtherMinions(range)
			local result = {}
			for i = 1, GameWardCount() do
				local minion = GameWard(i)
				if IsValidTarget(minion) and self:GetMinionType(minion) == MINION_TYPE_OTHER_MINION then
					if IsInRange(myHero, minion, range) then
						TableInsert(result, minion)
					end
				end
			end
			return result
		end
		------------------------------------------------------------------------------------------------------------------------------------------------
		function __ObjectManager:GetOtherAllyMinions(range)
			local result = {}
			for i = 1, GameWardCount() do
				local minion = GameWard(i)
				if IsValidTarget(minion) and minion.isAlly and self:GetMinionType(minion) == MINION_TYPE_OTHER_MINION then
					if IsInRange(myHero, minion, range) then
						TableInsert(result, minion)
					end
				end
			end
			return result
		end
		------------------------------------------------------------------------------------------------------------------------------------------------
		function __ObjectManager:GetOtherEnemyMinions(range)
			local result = {}
			for i = 1, GameWardCount() do
				local minion = GameWard(i)
				if IsValidTarget(minion) and minion.isEnemy and self:GetMinionType(minion) == MINION_TYPE_OTHER_MINION then
					if IsInRange(myHero, minion, range) then
						TableInsert(result, minion)
					end
				end
			end
			return result
		end
		------------------------------------------------------------------------------------------------------------------------------------------------
		function __ObjectManager:GetOtherEnemyMinionsInAutoAttackRange()
			local result = {}
			for i = 1, GameWardCount() do
				local minion = GameWard(i)
				if IsValidTarget(minion) and minion.isEnemy and self:GetMinionType(minion) == MINION_TYPE_OTHER_MINION then
					if IsInAutoAttackRange(myHero, minion) then
						TableInsert(result, minion)
					end
				end
			end
			return result
		end
		------------------------------------------------------------------------------------------------------------------------------------------------
		function __ObjectManager:GetMonsters(range)
			local result = {}
			for i = 1, GameMinionCount() do
				local minion = GameMinion(i)
				if IsValidTarget(minion) and self:GetMinionType(minion) == MINION_TYPE_MONSTER then
					if IsInRange(myHero, minion, range) then
						TableInsert(result, minion)
					end
				end
			end
			return result
		end
		------------------------------------------------------------------------------------------------------------------------------------------------
		function __ObjectManager:GetMonstersInAutoAttackRange()
			local result = {}
			for i = 1, GameMinionCount() do
				local minion = GameMinion(i)
				if IsValidTarget(minion) and self:GetMinionType(minion) == MINION_TYPE_MONSTER then
					if IsInAutoAttackRange(myHero, minion) then
						TableInsert(result, minion)
					end
				end
			end
			return result
		end
		------------------------------------------------------------------------------------------------------------------------------------------------
		function __ObjectManager:GetHeroes(range)
			local result = {}
			for i = 1, GameHeroCount() do
				local hero = GameHero(i)
				if IsValidTarget(hero) then
					if IsInRange(myHero, hero, range) then
						TableInsert(result, hero)
					end
				end
			end
			return result
		end
		------------------------------------------------------------------------------------------------------------------------------------------------
		function __ObjectManager:GetAllyHeroes(range)
			local result = {}
			for i = 1, GameHeroCount() do
				local hero = GameHero(i)
				if IsValidTarget(hero) and hero.isAlly then
					if IsInRange(myHero, hero, range) then
						TableInsert(result, hero)
					end
				end
			end
			return result
		end
		------------------------------------------------------------------------------------------------------------------------------------------------
		function __ObjectManager:GetEnemyHeroes(range, bb, state)
			local result = {}
			state = state or 0
			bb = bb or false
			--state "spell" = 0
			--state "attack" = 1
			--state "immortal" = 2
			for i = 1, GameHeroCount() do
				local hero = GameHero(i)
				local r = bb and range + hero.boundingRadius or range
				if hero and hero.team == TEAM_ENEMY and IsValidTarget(hero) and IsInRange(myHero, hero, r) then
					local immortal = false
					if state == 0 then
						immortal = self:IsHeroImmortal(hero, false)
					elseif state == 1 then
						immortal = self:IsHeroImmortal(hero, true)
					end
					if not immortal then
						result[#result+1] = hero
					end
				end
			end
			return result
		end
		------------------------------------------------------------------------------------------------------------------------------------------------
		function __ObjectManager:GetEnemyHeroesInAutoAttackRange()
			local result = {}
			for i = 1, GameHeroCount() do
				local hero = GameHero(i)
				if IsValidTarget(hero) and hero.isEnemy then
					if IsInAutoAttackRange(myHero, hero) then
						TableInsert(result, hero)
					end
				end
			end
			return result
		end
		------------------------------------------------------------------------------------------------------------------------------------------------
		function __ObjectManager:GetTurrets(range)
			return Join(self:GetAllyTurrets(range), self:GetEnemyTurrets(range))
		end
		------------------------------------------------------------------------------------------------------------------------------------------------
		function __ObjectManager:GetAllyTurrets(range)
			local result = {}
			local turrets = Core:GetAllyTurrets()
			for i = 1, #turrets do
				local turret = turrets[i]
				if IsValidTarget(turret) and IsInRange(myHero, turret, range) then
					TableInsert(result, turret)
				end
			end
			return result
		end
		------------------------------------------------------------------------------------------------------------------------------------------------
		function __ObjectManager:GetEnemyTurrets(range)
			local result = {}
			local turrets = Core:GetEnemyTurrets()
			for i = 1, #turrets do
				local turret = turrets[i]
				if IsValidTarget(turret) and IsInRange(myHero, turret, range) then
					TableInsert(result, turret)
				end
			end
			return result
		end
		------------------------------------------------------------------------------------------------------------------------------------------------
		ObjectManager = __ObjectManager()
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- _G.SDK.Orbwalker:																																	
	do
		local __Orbwalker = Core:Class()
		function __Orbwalker:__init()
			--[[Core:OnCancelAttack(function(unit, args)
				if unit.isMe then
					print("attack was canceled")
					self:__OnAutoAttackReset()
				end
			end)]]
			-- SDK:																																		
				self.Menu =
				{
					General =
					{
						HoldRadius = nil,
						MovementDelay = nil
					}
				}
				self.LastHoldPosition = 0
				self.HoldPosition = nil
				self.AutoAttackResetted = false
				self.IsNone = true
				self.ForceMovement = nil
				self.ForceTarget = nil
				self.MenuKeys =
				{
					[ORBWALKER_MODE_COMBO] = {},
					[ORBWALKER_MODE_HARASS] = {},
					[ORBWALKER_MODE_LANECLEAR] = {},
					[ORBWALKER_MODE_JUNGLECLEAR] = {},
					[ORBWALKER_MODE_LASTHIT] = {},
					[ORBWALKER_MODE_FLEE] = {}
				}
				self.Modes =
				{
					[ORBWALKER_MODE_COMBO] = false,
					[ORBWALKER_MODE_HARASS] = false,
					[ORBWALKER_MODE_LANECLEAR] = false,
					[ORBWALKER_MODE_JUNGLECLEAR] = false,
					[ORBWALKER_MODE_LASTHIT] = false,
					[ORBWALKER_MODE_FLEE] = false
				}
				self.AllowMovement =
				{
					["Kaisa"] = function(unit)
						return HasBuff(unit, "KaisaE")
					end,
					["Lucian"] = function(unit)
						return HasBuff(unit, "LucianR")
					end,
					["Varus"] = function(unit)
						return HasBuff(unit, "VarusQ")
					end,
					["Vi"] = function(unit)
						return HasBuff(unit, "ViQ")
					end,
					["Vladimir"] = function(unit)
						return HasBuff(unit, "VladimirE")
					end,
					["Xerath"] = function(unit)
						return HasBuff(unit, "XerathArcanopulseChargeUp")
					end
				}
				self.DisableAutoAttack =
				{
					["Urgot"] = function(unit)
						return HasBuff(unit, "UrgotW")
					end,
					["Darius"] = function(unit)
						return HasBuff(unit, "dariusqcast")
					end,
					["Graves"] = function(unit)
						if unit.hudAmmo == 0 then
							return true
						end
						return false
					end,
					["Jhin"] = function(unit)
						if HasBuff(unit, "JhinPassiveReload") then
							return true
						end
						if unit.hudAmmo == 0 then
							return true
						end
						return false
					end
				}
			--------------------------------------------------------------------------------------------------------------------------------------------
			self.ChampionCanMove =
			{
				["Thresh"] = function()
					if myHero.pathing.isDashing then
						self.ThreshLastDash = GameTimer()
					end
					local currentTime = GameTimer()
					local lastDash = currentTime - self.ThreshLastDash
					if lastDash < 0.25 then
						return false
					end
					return true
				end
			}
			-- Thresh
			self.ThreshLastDash = 0
			-- Attack
			self.ResetAttack = false
			self.AttackStartTime = 0
			self.AttackEndTime = 0
			self.AttackCastEndTime = 1
			self.AttackLocalStart = 0
			self.AttackSpeed = 0
			self.AttackWindUp = 0
			self.AttackAnim = 0
			self.AttackProjSpeed = -1
			self.AutoAttackResets =
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
			-- Move
			self.LastMoveLocal = 0
			self.LastMoveTime = 0
			self.LastMovePos = myHero.pos
			self.LastPostAttack = 0
			-- Mouse
			self.LastMouseDown = 0
			-- Callbacks
			self.OnPreAttackC = {}
			self.OnPostAttackC = {}
			self.OnPostAttackTickC = {}
			self.OnAttackC = {}
			self.OnPreMoveC = {}
			-- Debug
			self.TestCount = 0
			self.TestStartTime = 0
			-- Other
			self.PostAttackBool = false
			self.AttackEnabled = true
			self.MovementEnabled = true
			self.IsTeemo = false
			self.IsBlindedByTeemo = false
			self.CanAttackC = function() return true end
			self.CanMoveC = function() return true end
		end
		function __Orbwalker:CreateMenu()
			Menu:MenuElement({name = "Orbwalker", id = "orb", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/orb.png" })
				MenuChamp = Menu.orb:MenuElement({name = MeCharName, id = MeCharName, type = _G.MENU})
					MenuChamp:MenuElement({ name = "Spell Manager", id = "spell", type = _G.MENU })
						MenuChamp.spell:MenuElement({name = "Block if is attacking", id = "isaa", value = true })
						MenuChamp.spell:MenuElement({name = "Spells between attacks", id = "baa", value = false })
					MenuChamp:MenuElement({ name = "Orbwalker Core", id = "lcore", type = _G.MENU })
						MenuChamp.lcore:MenuElement({name = "Use at own risk ! There can be attack cancels !", id = "space", type = SPACE})
						MenuChamp.lcore:MenuElement({name = "ON - Local, OFF - Server", id = "enabled", value = false })
						MenuChamp.lcore:MenuElement({name = "Only Local (if Local ON)", id = "response", value = false })
						MenuChamp.lcore:MenuElement({ name = "Local Extra Windup", id = "extraw", value = 100, min = 0, max = 100, step = 10 })
					MenuChamp:MenuElement({ name = "LaneClear", id = "lclear", type = _G.MENU })
						MenuChamp.lclear:MenuElement({name = "Attack Heroes", id = "laneset", value = true })
						MenuChamp.lclear:MenuElement({name = "Should Wait Time", id = "swait", value = 500, min = 0, max = 1000, step = 100 })
					MenuChamp:MenuElement({ name = "Hold Radius", id = "hold", type = _G.MENU })
						MenuChamp.hold:MenuElement({ id = "HoldRadius", name = "Hold Radius", value = 120, min = 100, max = 250, step = 10 })
							self.Menu.General.HoldRadius = MenuChamp.hold.HoldRadius
						MenuChamp.hold:MenuElement({ id = "HoldPosButton", name = "Hold position button", key = string.byte("H"), tooltip = "Should be same in game keybinds", onKeyChange = function(kb) HoldPositionButton = kb; end });
							HoldPositionButton = MenuChamp.hold.HoldPosButton:Key()
					MenuChamp:MenuElement({ name = "Default Settings Key", id = "dkey", type = _G.MENU })
						MenuChamp.dkey:MenuElement({name = "Hold together !", id = "space", type = SPACE})
						MenuChamp.dkey:MenuElement({name = "1", id = "def1", key = string.byte("U"), callback = function() if MenuChamp.dkey.def2:Value() then ResetMenu() end end})
						MenuChamp.dkey:MenuElement({name = "2", id = "def2", key = string.byte("Y"), callback = function() if MenuChamp.dkey.def1:Value() then ResetMenu() end end})
				Menu.orb:MenuElement({name = "Keys", id = "keys", type = _G.MENU})
					Menu.orb.keys:MenuElement({name = "Combo Key", id = "combo", key = string.byte(" ")})
						self:RegisterMenuKey(ORBWALKER_MODE_COMBO, Menu.orb.keys.combo)
					Menu.orb.keys:MenuElement({name = "Harass Key", id = "harass", key = string.byte("C")})
						self:RegisterMenuKey(ORBWALKER_MODE_HARASS, Menu.orb.keys.harass)
					Menu.orb.keys:MenuElement({name = "LastHit Key", id = "lasthit", key = string.byte("X")})
						self:RegisterMenuKey(ORBWALKER_MODE_LASTHIT, Menu.orb.keys.lasthit)
					Menu.orb.keys:MenuElement({name = "LaneClear Key", id = "laneclear", key = string.byte("V")})
						self:RegisterMenuKey(ORBWALKER_MODE_LANECLEAR, Menu.orb.keys.laneclear)
					Menu.orb.keys:MenuElement({name = "Jungle Key", id = "jungle", key = string.byte("V")})
						self:RegisterMenuKey(ORBWALKER_MODE_JUNGLECLEAR, Menu.orb.keys.jungle)
					Menu.orb.keys:MenuElement({name = "Flee Key", id = "flee", key = string.byte("A")})
						self:RegisterMenuKey(ORBWALKER_MODE_FLEE, Menu.orb.keys.flee)
				Menu.orb:MenuElement({ name = "Humanizer", id = "humanizer", type = _G.MENU })
					Menu.orb.humanizer:MenuElement({ name = "Random", id = "random", type = _G.MENU })
						Menu.orb.humanizer.random:MenuElement({name = "Enabled", id = "enabled", value = true })
						Menu.orb.humanizer.random:MenuElement({name = "From", id = "from", value = 150, min = 60, max = 300, step = 20 })
						Menu.orb.humanizer.random:MenuElement({name = "To", id = "to", value = 220, min = 60, max = 400, step = 20 })
					Menu.orb.humanizer:MenuElement({name = "Humanizer", id = "standard", value = 200, min = 60, max = 300, step = 10 })
						self.Menu.General.MovementDelay = Menu.orb.humanizer.standard
				Menu.orb:MenuElement({ name = "Extra Cursor Delay", id = "excdelay", value = 25, min = 0, max = 50, step = 5 })
				Menu.orb:MenuElement({name = "Player Attack Move Click", id = "aamoveclick", key = string.byte("P")})
		end
		function __Orbwalker:CreateDrawMenu(menu)
			Menu.gsodraw:MenuElement({name = "MyHero Attack Range", id = "me", type = _G.MENU})
				Menu.gsodraw.me:MenuElement({name = "Enabled",  id = "enabled", value = true})
				Menu.gsodraw.me:MenuElement({name = "Color",  id = "color", color = DrawColor(150, 49, 210, 0)})
				Menu.gsodraw.me:MenuElement({name = "Width",  id = "width", value = 1, min = 1, max = 10})
			Menu.gsodraw:MenuElement({name = "Enemy Attack Range", id = "he", type = _G.MENU})
				Menu.gsodraw.he:MenuElement({name = "Enabled",  id = "enabled", value = true})
				Menu.gsodraw.he:MenuElement({name = "Color",  id = "color", color = DrawColor(150, 255, 0, 0)})
				Menu.gsodraw.he:MenuElement({name = "Width",  id = "width", value = 1, min = 1, max = 10})
		end
		function __Orbwalker:OnPreAttack(func)
			self.OnPreAttackC[#self.OnPreAttackC+1] = func
		end
		function __Orbwalker:OnPostAttack(func)
			self.OnPostAttackC[#self.OnPostAttackC+1] = func
		end
		function __Orbwalker:OnPostAttackTick(func)
			self.OnPostAttackTickC[#self.OnPostAttackTickC+1] = func
		end
		function __Orbwalker:OnAttack(func)
			self.OnAttackC[#self.OnAttackC+1] = func
		end
		function __Orbwalker:OnPreMovement(func)
			self.OnPreMoveC[#self.OnPreMoveC+1] = func
		end
		function __Orbwalker:Draw()
			if Menu.gsodraw.me.enabled:Value() and myHero.pos:ToScreen().onScreen then
				DrawCircle(myHero.pos, myHero.range + myHero.boundingRadius + 35, Menu.gsodraw.me.width:Value(), Menu.gsodraw.me.color:Value())
			end
			if Menu.gsodraw.he.enabled:Value() then
				local enemyHeroes = ObjectManager:GetEnemyHeroes(99999999, false, 2)
				for i = 1, #enemyHeroes do
					local enemy = enemyHeroes[i]
					if enemy.pos:ToScreen().onScreen then
						DrawCircle(enemy.pos, enemy.range + enemy.boundingRadius + 35, Menu.gsodraw.he.width:Value(), Menu.gsodraw.he.color:Value())
					end
				end
			end
		end
		function __Orbwalker:CanAttackEvent(func)
			self.CanAttackC = func
		end
		function __Orbwalker:CanMoveEvent(func)
			self.CanMoveC = func
		end
		function __Orbwalker:Attack(unit)
			self.ResetAttack = false
			local attackKey = Menu.orb.aamoveclick:Key()
			CURSOR:SetCursor(_G.cursorPos, unit, attackKey, function()
				ControlKeyDown(attackKey)
				ControlKeyUp(attackKey)
			end)
			self.LastMoveLocal = 0
			self.AttackLocalStart = GameTimer()
		end
		function __Orbwalker:Move()
			if ControlIsKeyDown(2) then self.LastMouseDown = GameTimer() end
			self.LastMovePos = _G.mousePos
			ControlMouseEvent(MOUSEEVENTF_RIGHTDOWN)
			ControlMouseEvent(MOUSEEVENTF_RIGHTUP)
			self.LastMoveLocal = GameTimer() + GetHumanizer()
			self.LastMoveTime = GameTimer()
		end
		function __Orbwalker:MoveToPos(pos)
			if ControlIsKeyDown(2) then self.LastMouseDown = GameTimer() end
			CURSOR:SetCursor(_G.cursorPos, pos, MOUSEEVENTF_RIGHTDOWN, function()
				ControlMouseEvent(MOUSEEVENTF_RIGHTDOWN)
				ControlMouseEvent(MOUSEEVENTF_RIGHTUP)
			end)
			self.LastMoveLocal = GameTimer() + GetHumanizer()
			self.LastMoveTime = GameTimer()
		end
		function __Orbwalker:CanAttackLocal()
			if not self.CanAttackC() then return false end
			if self.IsBlindedByTeemo then
				return false
			end
			if ExtLibEvade and ExtLibEvade.Evading then
				return false
			end
			if IsChanneling(myHero) then
				return false
			end
			if self.DisableAutoAttack[MeCharName] ~= nil and self.DisableAutoAttack[MeCharName](myHero) then
				return false
			end
			if Spells:DisableAutoAttack() then
				return false
			end
			if GameTimer() < Spells.SpellEndTime then
				return false
			end
			if GameTimer() < Spells.ObjectEndTime then
				return false
			end
			if MenuChamp.lcore.enabled:Value() and MenuChamp.lcore.response:Value() and GameTimer() < self.AttackLocalStart + self.AttackWindUp + 0.2 then
				return false
			end
			if self.AttackCastEndTime > self.AttackLocalStart then
				if GameTimer() >= self.AttackEndTime - Core:GetLatency() - 0.04 then
					return true
				end
				return false
			end
			if GameTimer() < self.AttackLocalStart + 0.2 then
				return false
			end
			return true
		end
		function __Orbwalker:CanMoveSpell()
			if MenuChamp.lcore.enabled:Value() and MenuChamp.lcore.response:Value() and GameTimer() > self.AttackLocalStart + self.AttackWindUp + MenuChamp.lcore.extraw:Value() * 0.001 then
				return true
			end
			if self.AttackCastEndTime > self.AttackLocalStart then
				if GameTimer() >= self.AttackCastEndTime + 0.01 - Core:GetLatency() then
					return true
				end
				if MenuChamp.lcore.enabled:Value() and GameTimer() > self.AttackLocalStart + self.AttackWindUp + MenuChamp.lcore.extraw:Value() * 0.001 then
					return true
				end
				return false
			end
			if GameTimer() < self.AttackLocalStart + 0.2 then
				return false
			end
			return true
		end
		function __Orbwalker:CanMoveLocal(extraDelay)
			local onlyMove = extraDelay == 0
			if onlyMove and not self.CanMoveC() then return false end
			if ExtLibEvade and ExtLibEvade.Evading then
				return false
			end
			if MeCharName == "Kalista" then
				return true
			end
			if not myHero.pathing.hasMovePath then
				self.LastMoveLocal = 0
			end
			if IsChanneling(myHero) then
				if self.AllowMovement[MeCharName] == nil or (not self.AllowMovement[MeCharName](myHero)) then
					return false
				end
			end
			if self.ChampionCanMove[MeCharName] ~= nil and not self.ChampionCanMove[MeCharName]() then
				return false
			end
			if MenuChamp.lcore.enabled:Value() and MenuChamp.lcore.response:Value() and GameTimer() > self.AttackLocalStart + self.AttackWindUp + MenuChamp.lcore.extraw:Value() * 0.001 then
				return true
			end
			if GetDistanceSquared(myHero.pos, _G.mousePos) < 15000 then
				return false
			end
			if self.AttackCastEndTime > self.AttackLocalStart then
				if GameTimer() >= self.AttackCastEndTime + extraDelay + 0.01 - Core:GetLatency() then
					return true
				end
				if MenuChamp.lcore.enabled:Value() and GameTimer() > self.AttackLocalStart + self.AttackWindUp + MenuChamp.lcore.extraw:Value() * 0.001 then
					return true
				end
				return false
			end
			if GameTimer() < self.AttackLocalStart + 0.2 then
				return false
			end
			return true
		end
		function __Orbwalker:AttackMove(unit, isLH, isLC)
			if self.AttackEnabled and unit and unit.pos:ToScreen().onScreen and self:CanAttackLocal() then
				local args = { Target = unit, Process = true }
				for i = 1, #self.OnPreAttackC do
					self.OnPreAttackC[i](args)
				end
				if args.Process and args.Target then
					if _G.Control.Attack(args.Target) then
						self.PostAttackBool = true
						if isLH then
							HealthPrediction.LastHandle = unit.handle
						elseif isLC and unit.type == Obj_AI_Minion then
							HealthPrediction.LastLCHandle = unit.handle
						end
					end
				end
			elseif self.MovementEnabled and self:CanMoveLocal(0) then
				if self.PostAttackBool then
					for i = 1, #self.OnPostAttackC do
						self.OnPostAttackC[i]()
					end
					self.LastPostAttack = GameTimer()
					self.PostAttackBool = false
				end
				if GameTimer() < self.LastPostAttack + 0.15 then
					for i = 1, #self.OnPostAttackTickC do
						self.OnPostAttackTickC[i]()
					end
				end
				if GameTimer() > self.LastMoveLocal then
					local args = { Target = self.ForceMovement, Process = true }
					for i = 1, #self.OnPreMoveC do
						self.OnPreMoveC[i](args)
					end
					if args.Process then
						local toMouse = false
						local position
						if not args.Target then
							toMouse = true
							position = _G.mousePos
						elseif args.Target.x then
							position = Vector(args.Target)
						elseif args.Target.pos then
							position = args.Target.pos
						end
						if toMouse then position = nil end
						_G.Control.Move(position)
					end
				end
			end
		end
		function __Orbwalker:WndMsg(msg, wParam)
			if not CURSOR.IsReadyGlobal then
				if wParam == Menu.orb.aamoveclick:Key() then
					self.AttackLocalStart = GameTimer()
					CURSOR.IsReadyGlobal = true
					--print("attack")
				elseif wParam == CURSOR.Key then
					CURSOR.IsReadyGlobal = true
					--print("spell")
				elseif CURSOR.Key == MOUSEEVENTF_RIGHTDOWN and wParam == 2 then
					CURSOR.IsReadyGlobal = true
					--print("mouse")
				end
			end
		end
		function __Orbwalker:GetTarget()
			local result = nil
			if IsValidTarget(self.ForceTarget) then
				result = self.ForceTarget
			elseif self.Modes[ORBWALKER_MODE_COMBO] then
				result = TargetSelector:GetComboTarget()
			elseif self.Modes[ORBWALKER_MODE_HARASS] then
				if HealthPrediction.IsLastHitable then
					result = HealthPrediction:GetLastHitTarget()
				else
					result = TargetSelector:GetComboTarget()
				end
			elseif self.Modes[ORBWALKER_MODE_LASTHIT] then
				result = HealthPrediction:GetLastHitTarget()
			elseif self.Modes[ORBWALKER_MODE_LANECLEAR] then
				if HealthPrediction.IsLastHitable then
					result = HealthPrediction:GetLastHitTarget()
				elseif GameTimer() > HealthPrediction.ShouldWaitTime + MenuChamp.lclear.swait:Value() * 0.001 then
					result = HealthPrediction:GetLaneClearTarget()
				end
			elseif self.Modes[ORBWALKER_MODE_FLEE] then
				result = nil
			elseif self.Modes[ORBWALKER_MODE_JUNGLECLEAR] then
				result = HealthPrediction:GetJungleTarget()
			end
			return result
		end
		function __Orbwalker:Orbwalk()
			self.IsNone = self:HasMode(ORBWALKER_MODE_NONE)
			self.Modes = self:GetModes()
			if self.IsNone then
				if GameTimer() < self.LastMouseDown + 1 then
					ControlMouseEvent(MOUSEEVENTF_RIGHTDOWN)
					self.LastMouseDown = 0
				end
				return
			end
			if GameIsChatOpen() or (ExtLibEvade and ExtLibEvade.Evading) or not CURSOR.IsReady or (not GameIsOnTop()) then
				return
			end
			if IsValidTarget(self.ForceTarget) then
				self:AttackMove(self.ForceTarget)
			elseif self.Modes[ORBWALKER_MODE_COMBO] then
				self:AttackMove(TargetSelector:GetComboTarget())
			elseif self.Modes[ORBWALKER_MODE_HARASS] then
				if HealthPrediction.IsLastHitable then
					self:AttackMove(HealthPrediction:GetLastHitTarget(), true)
				else
					self:AttackMove(TargetSelector:GetComboTarget())
				end
			elseif self.Modes[ORBWALKER_MODE_LASTHIT] then
				self:AttackMove(HealthPrediction:GetLastHitTarget())
			elseif self.Modes[ORBWALKER_MODE_LANECLEAR] then
				if HealthPrediction.IsLastHitable then
					self:AttackMove(HealthPrediction:GetLastHitTarget(), true)
				elseif GameTimer() > HealthPrediction.ShouldWaitTime + MenuChamp.lclear.swait:Value() * 0.001 then
					self:AttackMove(HealthPrediction:GetLaneClearTarget(), false, true)
				else
					self:AttackMove()
				end
			elseif self.Modes[ORBWALKER_MODE_FLEE] then
				if self.MovementEnabled and GameTimer() > self.LastMoveLocal and self:CanMoveLocal(0) then
					self:AttackMove()
				end
			elseif self.Modes[ORBWALKER_MODE_JUNGLECLEAR] then
				self:AttackMove(HealthPrediction:GetJungleTarget())
			end
		end
		function __Orbwalker:Tick()
			-- COMMENTED FOR FUTURE USAGE ! Calculate Animation & WindUp AttackTime
				--local baseAnimationTime = myHero.attackSpeed * (1 / myHero.attackData.animationTime / myHero.attackSpeed)
				--local baseWindUpTime = myHero.attackData.windUpTime / myHero.attackData.animationTime
				--local animationTime = 1 / baseAnimationTime
				--local windUpTime = animationTime * baseWindUpTime
				--print(tostring(animationTime) .. " " .. tostring(myHero.attackData.animationTime))
				--print(tostring(windUpTime) .. " " .. tostring(myHero.attackData.windUpTime))
			-- Get AttackData from myHero.attackData
				if self.AttackSpeed == 0 and myHero.attackSpeed then self.AttackSpeed = myHero.attackSpeed end
				if self.AttackWindUp == 0 and myHero.attackData.windUpTime then self.AttackWindUp = myHero.attackData.windUpTime end
				if self.AttackAnim == 0 and myHero.attackData.animationTime then self.AttackAnim = myHero.attackData.animationTime end
				if self.AttackProjSpeed == -1 and myHero.attackData.projectileSpeed then self.AttackProjSpeed = myHero.attackData.projectileSpeed end
			-- Get AttackData from myHero.activeSpell
				local spell = myHero.activeSpell
				if spell and spell.valid and not NoAutoAttacks[spell.name] and spell.castEndTime > self.AttackCastEndTime and (not myHero.isChanneling or SpecialAutoAttacks[spell.name]) then
					for i = 1, #self.OnAttackC do
						self.OnAttackC[i]()
					end
					self.AttackCastEndTime = spell.castEndTime
					self.AttackSpeed = myHero.attackSpeed
					self.AttackWindUp = spell.windup
					self.AttackAnim = spell.animation
					self.AttackStartTime = spell.startTime
					self.AttackEndTime = spell.endTime
					self.AttackProjSpeed = spell.speed
					if GAMSTERON_MODE_DMG then
						if self.TestCount == 0 then
							self.TestStartTime = GameTimer()
						end
						self.TestCount = self.TestCount + 1
						if self.TestCount == 5 then
							print("5 attacks in time: " .. tostring(GameTimer() - self.TestStartTime) .. "[sec]")
							self.TestCount = 0
							self.TestStartTime = 0
						end
					end
				end
				self.AttackWindUp = GetWindup()
			self:Orbwalk()
		end
		------------------------------------------------------------------------------------------------------------------------------------------------
		function __Orbwalker:RegisterMenuKey(mode, key)
			TableInsert(self.MenuKeys[mode], key);
		end
		function __Orbwalker:HasMode(mode)
			if mode == ORBWALKER_MODE_NONE then
				for _, value in pairs(self:GetModes()) do
					if value then
						return false;
					end
				end
				return true;
			end
			for i = 1, #self.MenuKeys[mode] do
				local key = self.MenuKeys[mode][i];
				if key:Value() then
					return true;
				end
			end
			return false;
		end
		function __Orbwalker:GetModes()
			return {
				[ORBWALKER_MODE_COMBO] 			= self:HasMode(ORBWALKER_MODE_COMBO),
				[ORBWALKER_MODE_HARASS] 		= self:HasMode(ORBWALKER_MODE_HARASS),
				[ORBWALKER_MODE_LANECLEAR] 		= self:HasMode(ORBWALKER_MODE_LANECLEAR),
				[ORBWALKER_MODE_JUNGLECLEAR] 	= self:HasMode(ORBWALKER_MODE_JUNGLECLEAR),
				[ORBWALKER_MODE_LASTHIT] 		= self:HasMode(ORBWALKER_MODE_LASTHIT),
				[ORBWALKER_MODE_FLEE] 			= self:HasMode(ORBWALKER_MODE_FLEE)
			}
		end
		function __Orbwalker:OnUnkillableMinion(cb)
			HealthPrediction.OnUnkillableC[#HealthPrediction.OnUnkillableC+1] = cb
		end
		function __Orbwalker:SetMovement(boolean)
			self.MovementEnabled = boolean
		end
		function __Orbwalker:SetAttack(boolean)
			self.AttackEnabled = boolean
		end
		function __Orbwalker:ShouldWait()
			return GameTimer() <= HealthPrediction.ShouldWaitTime + MenuChamp.lclear.swait:Value() * 0.001
		end
		function __Orbwalker:IsEnabled()
			return true
		end
		function __Orbwalker:IsAutoAttacking(unit)
			local me = unit or myHero
			if me.isMe then
				return not self:CanMoveSpell()
			end
			return GameTimer() < unit.attackData.endTime - unit.attackData.windDownTime
		end
		function __Orbwalker:CanMove(unit)
			local result = true
			unit = unit or myHero
			if self:IsAutoAttacking(unit) then
				result = false
			end
			if result and IsChanneling(unit) then
				if self.AllowMovement[unit.charName] == nil or (not self.AllowMovement[unit.charName](unit)) then
					result = false
				end
			end
			return result
		end
		function __Orbwalker:CanAttack(unit)
			local result = true
			unit = unit or myHero
			if unit.isMe then
				return self:CanAttackLocal()
			end
			if result and IsChanneling(unit) then
				result = false
			end
			if result and self.DisableAutoAttack[unit.charName] ~= nil and self.DisableAutoAttack[unit.charName](unit) then
				result = false
			end
			return result
		end
		function __Orbwalker:__OnAutoAttackReset()
			self.ResetAttack = true
			self.AttackEndTime = 0
			self.AttackLocalStart = 0
		end
		Orbwalker = __Orbwalker()
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- _G.SDK.HealthPrediction:																																
	do
		local __HealthPrediction = Core:Class()
		function __HealthPrediction:__init()
			self.OnUnkillableC = {}
			self.CachedTeamEnemy = {}
			self.CachedTeamAlly = {}
			self.CachedTeamJungle = {}
			self.CachedAttackData = {}
			self.CachedAttacks = {}
			self.TurretHasTarget = false
			self.CanCheckTurret = true
			self.ShouldWaitTime = 0
			self.IsLastHitable = false
			self.LastHandle = 0
			self.LastLCHandle = 0
			self.FarmMinions = {}
		end
		function __HealthPrediction:CreateDrawMenu()
			Menu.gsodraw:MenuElement({name = "LastHitable Minion",  id = "lasthit", type = _G.MENU})
				Menu.gsodraw.lasthit:MenuElement({name = "Enabled",  id = "enabled", value = true})
				Menu.gsodraw.lasthit:MenuElement({name = "Color",  id = "color", color = DrawColor(150, 255, 255, 255)})
				Menu.gsodraw.lasthit:MenuElement({name = "Width",  id = "width", value = 3, min = 1, max = 10})
				Menu.gsodraw.lasthit:MenuElement({name = "Radius",  id = "radius", value = 50, min = 1, max = 100})
			Menu.gsodraw:MenuElement({name = "Almost LastHitable Minion",  id = "almostlasthit", type = _G.MENU})
				Menu.gsodraw.almostlasthit:MenuElement({name = "Enabled",  id = "enabled", value = true})
				Menu.gsodraw.almostlasthit:MenuElement({name = "Color",  id = "color", color = DrawColor(150, 239, 159, 55)})
				Menu.gsodraw.almostlasthit:MenuElement({name = "Width",  id = "width", value = 3, min = 1, max = 10})
				Menu.gsodraw.almostlasthit:MenuElement({name = "Radius",  id = "radius", value = 50, min = 1, max = 100})
		end
		function __HealthPrediction:GetJungleTarget()
			local result = nil
			local health = 200000
			local targets = Join(ObjectManager:GetMonstersInAutoAttackRange(), ObjectManager:GetOtherEnemyMinionsInAutoAttackRange())
			for i = 1, #targets do
				local obj = targets[i]
				if obj and obj.health < health then
					health = obj.health
					result = obj
				end
			end
			return result
		end
		function __HealthPrediction:GetLastHitTarget()
			local min = 10000000
			local result = nil
			for i = 1, #self.FarmMinions do
				local minion = self.FarmMinions[i]
				if not minion.Minion.dead and minion.LastHitable and minion.PredictedHP < min and IsValidTarget(minion.Minion) and IsInAutoAttackRange(myHero, minion.Minion) then
					min = minion.PredictedHP
					result = minion.Minion
				end
			end
			return result
		end
		function __HealthPrediction:GetLaneClearTarget()
			local enemyTurrets = ObjectManager:GetEnemyBuildings(myHero.range+myHero.boundingRadius - 35, true)
			if #enemyTurrets >= 1 then return enemyTurrets[1] end
			if MenuChamp.lclear.laneset:Value() then
				local result = TargetSelector:GetComboTarget()
				if result then return result end
			end
			local result = nil
			if GameTimer() > self.ShouldWaitTime + MenuChamp.lclear.swait:Value() * 0.001 then
				local min = 10000000
				for i = 1, #self.FarmMinions do
					local target = self.FarmMinions[i]
					if not target.Minion.dead and target.PredictedHP < min and IsValidTarget(target.Minion) and IsInAutoAttackRange(myHero, target.Minion) then
						min = target.PredictedHP
						result = target.Minion
					end
				end
			end
			return result
		end
		function __HealthPrediction:SetObjects(team)
			if team == TEAM_ALLY then
				if #self.CachedTeamAlly > 0 then
					return
				end
			elseif team == TEAM_ENEMY then
				if #self.CachedTeamEnemy > 0 then
					return
				end
			elseif team == TEAM_JUNGLE then
				if #self.CachedTeamJungle > 0 then
					return
				end
			end
			for i = 1, GameMinionCount() do
				local obj = GameMinion(i)
				if obj and obj.team ~= team and IsValidTarget(obj) then
					if team == TEAM_ALLY then
						self.CachedTeamAlly[#self.CachedTeamAlly+1] = obj
					elseif team == TEAM_ENEMY then
						self.CachedTeamEnemy[#self.CachedTeamEnemy+1] = obj
					else
						self.CachedTeamJungle[#self.CachedTeamJungle+1] = obj
					end
				end
			end
			for i = 1, GameHeroCount() do
				local obj = GameHero(i)
				if obj and obj.team ~= team and not obj.isMe and IsValidTarget(obj) then
					if team == TEAM_ALLY then
						self.CachedTeamAlly[#self.CachedTeamAlly+1] = obj
					elseif team == TEAM_ENEMY then
						self.CachedTeamEnemy[#self.CachedTeamEnemy+1] = obj
					else
						self.CachedTeamJungle[#self.CachedTeamJungle+1] = obj
					end
				end
			end
			local turrets = Join(Core:GetEnemyTurrets(), Core:GetAllyTurrets())
			for i = 1, #turrets do
				local obj = turrets[i]
				if obj and obj.team ~= team and IsValidTarget(obj) then
					if team == TEAM_ALLY then
						self.CachedTeamAlly[#self.CachedTeamAlly+1] = obj
					elseif team == TEAM_ENEMY then
						self.CachedTeamEnemy[#self.CachedTeamEnemy+1] = obj
					else
						self.CachedTeamJungle[#self.CachedTeamJungle+1] = obj
					end
				end
			end
		end
		function __HealthPrediction:GetObjects(team)
			if team == TEAM_ALLY then
				return self.CachedTeamAlly
			elseif team == TEAM_ENEMY then
				return self.CachedTeamEnemy
			elseif team == TEAM_JUNGLE then
				return self.CachedTeamJungle
			end
		end
		function __HealthPrediction:SetAttacks(target)
			-- target handle
			local handle = target.handle
			-- Cached Attacks
			if self.CachedAttacks[handle] == nil then
				self.CachedAttacks[handle] = {}
				-- target team
				local team = target.team
				-- charName
				local name = target.charName
				-- set attacks
				local pos = target.pos
				-- cached objects
				self:SetObjects(team)
				local attackers = self:GetObjects(team)
				for i = 1, #attackers do
					local obj = attackers[i]
					local objname = obj.charName
					if self.CachedAttackData[objname] == nil then
						self.CachedAttackData[objname] = {}
					end
					if self.CachedAttackData[objname][name] == nil then
						self.CachedAttackData[objname][name] = { Range = GetAutoAttackRange(obj, target), Damage = 0 }
					end
					local range = self.CachedAttackData[objname][name].Range + 100
					if GetDistanceSquared(obj.pos, pos) < range * range then
						if self.CachedAttackData[objname][name].Damage == 0 then
							self.CachedAttackData[objname][name].Damage = Damage:GetAutoAttackDamage(obj, target)
						end
						self.CachedAttacks[handle][#self.CachedAttacks[handle]+1] = {
							Attacker = obj,
							Damage = self.CachedAttackData[objname][name].Damage,
							Type = obj.type
						}
					end
				end
			end
			return self.CachedAttacks[handle]
		end
		function __HealthPrediction:GetPossibleDmg(target)
			local result = 0
			local handle = target.handle
			local attacks = self.CachedAttacks[handle]
			if #attacks == 0 then return 0 end
			local pos = target.pos
			for i = 1, #attacks do
				local attack = attacks[i]
				local attacker = attack.Attacker
				if (not self.TurretHasTarget and attack.Type == Obj_AI_Turret) or (attack.Type == Obj_AI_Minion and attacker.pathing.hasMovePath) then
					result = result + attack.Damage
				end
			end
			return result
		end
		function __HealthPrediction:GetPrediction(target, time)
			self:SetAttacks(target)
			local handle = target.handle
			local attacks = self.CachedAttacks[handle]
			local hp = TotalShieldHealth(target)
			if #attacks == 0 then return hp end
			local pos = target.pos
			for i = 1, #attacks do
				local attack = attacks[i]
				local attacker = attack.Attacker
				local dmg = attack.Damage
				local objtype = attack.Type
				local isTurret = objtype == Obj_AI_Turret
				local time2 = time
				if isTurret then
					time2 = time2 - 0.1
				end
				local ismoving = false
				if not isTurret then ismoving = attacker.pathing.hasMovePath end
				if attacker.attackData.target == handle and not ismoving then
					if isTurret and self.CanCheckTurret then
						self.TurretHasTarget = true
					end
					local flyTime
					if attacker.attackData.projectileSpeed and attacker.attackData.projectileSpeed > 0 then
						flyTime = attacker.pos:DistanceTo(pos) / attacker.attackData.projectileSpeed
					else
						flyTime = 0
					end
					local endTime = (attacker.attackData.endTime - attacker.attackData.animationTime) + flyTime + attacker.attackData.windUpTime
					if endTime <= GameTimer() then
						endTime = endTime + attacker.attackData.animationTime + flyTime
					end
					while endTime - GameTimer() < time2 do
						hp = hp - dmg
						endTime = endTime + attacker.attackData.animationTime + flyTime
					end
				end
			end
			return hp
		end
		function __HealthPrediction:SetLastHitable(target, time, damage)
			local hpPred = self:GetPrediction(target, time)
			if hpPred < 0 then
				for i = 1, #self.OnUnkillableC do
					self.OnUnkillableC[i](target)
				end
			end
			local lastHitable = hpPred - damage < 0
			if lastHitable then self.IsLastHitable = true end
			local almostLastHitable = false
			if not lastHitable then
				local dmg = self:GetPrediction(target, (myHero.attackData.animationTime * 1.5) + (time * 3)) - self:GetPossibleDmg(target)
				almostLastHitable = dmg - damage < 0
			end
			if almostLastHitable then
				self.ShouldWaitTime = GameTimer()
			end
			return { LastHitable =  lastHitable, Unkillable = hpPred < 0, AlmostLastHitable = almostLastHitable, PredictedHP = hpPred, Minion = target }
		end
		function __HealthPrediction:Tick()
			self.CachedAttackData = {}
			self.CachedAttacks = {}
			self.FarmMinions = {}
			self.CachedTeamEnemy = {}
			self.CachedTeamAlly = {}
			self.CachedTeamJungle = {}
			self.TurretHasTarget = false
			self.CanCheckTurret = true
			self.IsLastHitable = false
			if Orbwalker.Modes[ORBWALKER_MODE_COMBO] then
				self.CanCheckTurret = false
				return
			end
			local targets = ObjectManager:GetEnemyMinions(myHero.range + myHero.boundingRadius, true)
			local projectileSpeed = GetProjSpeed()
			local winduptime = GetWindup()
			local latency = Core:GetLatency() * 0.5
			local pos = myHero.pos
			for i = 1, #targets do
				local target = targets[i]
				local FlyTime = pos:DistanceTo(target.pos) / projectileSpeed
				self.FarmMinions[#self.FarmMinions+1] = self:SetLastHitable(target, winduptime + FlyTime + latency, Damage:GetAutoAttackDamage(myHero, target))
			end
			self.CanCheckTurret = false
		end
		function __HealthPrediction:Draw()
			if Orbwalker.Modes[ORBWALKER_MODE_COMBO] then return end
			if Menu.gsodraw.lasthit.enabled:Value() or Menu.gsodraw.almostlasthit.enabled:Value() then
				local tm = self.FarmMinions
				for i = 1, #tm do
					local minion = tm[i]
					if minion.LastHitable and Menu.gsodraw.lasthit.enabled:Value() then
						DrawCircle(minion.Minion.pos,Menu.gsodraw.lasthit.radius:Value(),Menu.gsodraw.lasthit.width:Value(),Menu.gsodraw.lasthit.color:Value())
					elseif minion.AlmostLastHitable and Menu.gsodraw.almostlasthit.enabled:Value() then
						DrawCircle(minion.Minion.pos,Menu.gsodraw.almostlasthit.radius:Value(),Menu.gsodraw.almostlasthit.width:Value(),Menu.gsodraw.almostlasthit.color:Value())
					end
				end
			end
		end
		HealthPrediction = __HealthPrediction()
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- _G.SDK.Damage:																																		
	do
		local __Damage = Core:Class()
		function __Damage:__init()
			self.StaticChampionDamageDatabase =
			{
				["Caitlyn"] = function(args)
					if HasBuff(args.From, "caitlynheadshot") then
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
					if GetBuffCount(args.From, "dianapassivemarker") == 2 then
						local level = args.From.levelData.lvl
						args.RawMagical = args.RawMagical + MathMax(15 + 5 * level, -10 + 10 * level, -60 + 15 * level, -125 + 20 * level, -200 + 25 * level) + 0.8 * args.From.ap;
					end
				end,
				["Draven"] = function(args)
					if HasBuff(args.From, "DravenSpinningAttack") then
						local level = args.From:GetSpellData(_Q).level
						args.RawPhysical = args.RawPhysical + 25 + 5 * level + (0.55 + 0.1 * level) * args.From.bonusDamage; 
					end
					
				end,
				["Graves"] = function(args)
					local t = { 70, 71, 72, 74, 75, 76, 78, 80, 81, 83, 85, 87, 89, 91, 95, 96, 97, 100 };
					args.RawTotal = args.RawTotal * t[Damage:GetMaxLevel(args.From)] * 0.01;
				end,
				["Jinx"] = function(args)
					if HasBuff(args.From, "JinxQ") then
						args.RawPhysical = args.RawPhysical + args.From.totalDamage * 0.1;
					end
				end,
				["Kalista"] = function(args)
					args.RawPhysical = args.RawPhysical - args.From.totalDamage * 0.1;
				end,
				["Kayle"] = function(args)
					local level = args.From:GetSpellData(_E).level
					if level > 0 then
						if HasBuff(args.From, "JudicatorRighteousFury") then
							args.RawMagical = args.RawMagical + 10+ 10* level + 0.3 * args.From.ap;
						else
							args.RawMagical = args.RawMagical + 5+ 5* level + 0.15 * args.From.ap;
						end
					end
				end,
				["Nasus"] = function(args)
					if HasBuff(args.From, "NasusQ") then
						args.RawPhysical = args.RawPhysical + MathMax(GetBuffCount(args.From, "NasusQStacks"), 0) + 10 + 20 * args.From:GetSpellData(_Q).level
					end
				end,
				["Thresh"] = function(args)
					local level = args.From:GetSpellData(_E).level
					if level > 0 then
						local damage = MathMax(GetBuffCount(args.From, "threshpassivesouls"), 0) + (0.5 + 0.3 * level) * args.From.totalDamage;
						if HasBuff(args.From, "threshqpassive4") then
							damage = damage * 1;
						elseif HasBuff(args.From, "threshqpassive3") then
							damage = damage * 0.5;
						elseif HasBuff(args.From, "threshqpassive2") then
							damage = damage * 1/3;
						else
							damage = damage * 0.25;
						end
						args.RawMagical = args.RawMagical + damage;
					end
				end,
				["TwistedFate"] = function(args)
					if HasBuff(args.From, "cardmasterstackparticle") then
						args.RawMagical = args.RawMagical + 30 + 25 * args.From:GetSpellData(_E).level + 0.5 * args.From.ap;
					end
					if HasBuff(args.From, "BlueCardPreAttack") then
						args.DamageType = DAMAGE_TYPE_MAGICAL;
						args.RawMagical = args.RawMagical + 20 + 20 * args.From:GetSpellData(_W).level + 0.5 * args.From.ap;
					elseif HasBuff(args.From, "RedCardPreAttack") then
						args.DamageType = DAMAGE_TYPE_MAGICAL;
						args.RawMagical = args.RawMagical + 15 + 15 * args.From:GetSpellData(_W).level + 0.5 * args.From.ap;
					elseif HasBuff(args.From, "GoldCardPreAttack") then
						args.DamageType = DAMAGE_TYPE_MAGICAL;
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
					if HasBuff(args.From, "ViktorPowerTransferReturn") then
						args.DamageType = DAMAGE_TYPE_MAGICAL;
						args.RawMagical = args.RawMagical + 20 * args.From:GetSpellData(_Q).level + 0.5 * args.From.ap;
					end
				end,
				["Vayne"] = function(args)
					if HasBuff(args.From, "vaynetumblebonus") then
						args.RawPhysical = args.RawPhysical + (0.25 + 0.05 * args.From:GetSpellData(_Q).level) * args.From.totalDamage;
					end
				end
			}
			self.VariableChampionDamageDatabase =
			{
				["Jhin"] = function(args)
					if HasBuff(args.From, "jhinpassiveattackbuff") then
						args.CriticalStrike = true;
						args.RawPhysical = args.RawPhysical + MathMin(0.25, 0.1 + 0.05 * MathCeil(args.From.levelData.lvl / 5)) * (args.Target.maxHealth - args.Target.health);
					end
				end,
				["Lux"] = function(args)
					if HasBuff(args.Target, "LuxIlluminatingFraulein") then
						args.RawMagical = 20 + args.From.levelData.lvl * 10 + args.From.ap * 0.2;
					end
				end,
				["Orianna"] = function(args)
					local level = MathCeil(args.From.levelData.lvl / 3);
					args.RawMagical = args.RawMagical + 2 + 8 * level + 0.15 * args.From.ap;
					if args.Target.handle == args.From.attackData.target then
						args.RawMagical = args.RawMagical + MathMax(GetBuffCount(args.From, "orianapowerdaggerdisplay"), 0) * (0.4 + 1.6 * level + 0.03 * args.From.ap);
					end
				end,
				["Quinn"] = function(args)
					if HasBuff(args.Target, "QuinnW") then
						local level = args.From.levelData.lvl
						args.RawPhysical = args.RawPhysical + 10 + level * 5 + (0.14 + 0.02 * level) * args.From.totalDamage;
					end
				end,
				["Vayne"] = function(args)
					if GetBuffCount(args.Target, "VayneSilveredDebuff") == 2 then
						local level = args.From:GetSpellData(_W).level
						args.CalculatedTrue = args.CalculatedTrue + MathMax((0.045 + 0.015 * level) * args.Target.maxHealth, 20 + 20 * level);
					end
				end,
				["Zed"] = function(args)
					if 100 * args.Target.health / args.Target.maxHealth <= 50 and not HasBuff(args.From, "zedpassivecd") then
						args.RawMagical = args.RawMagical + args.Target.maxHealth * (4 + 2 * MathCeil(args.From.levelData.lvl / 6)) * 0.01;
					end
				end
			}
			self.StaticItemDamageDatabase =
			{
				[1043] = function(args)
					args.RawPhysical = args.RawPhysical + 15;
				end,
				[2015] = function(args)
					if GetBuffCount(args.From, "itemstatikshankcharge") == 100 then
						args.RawMagical = args.RawMagical + 40;
					end
				end,
				[3057] = function(args)
					if HasBuff(args.From, "sheen") then
						args.RawPhysical = args.RawPhysical + 1 * args.From.baseDamage;
					end
				end,
				[3078] = function(args)
					if HasBuff(args.From, "sheen") then
						args.RawPhysical = args.RawPhysical + 2 * args.From.baseDamage;
					end
				end,
				[3085] = function(args)
					args.RawPhysical = args.RawPhysical + 15;
				end,
				[3087] = function(args)
					if GetBuffCount(args.From, "itemstatikshankcharge") == 100 then
						local t = { 50, 50, 50, 50, 50, 56, 61, 67, 72, 77, 83, 88, 94, 99, 104, 110, 115, 120 };
						args.RawMagical = args.RawMagical + (1 + (args.TargetIsMinion and 1.2 or 0)) * t[Damage:GetMaxLevel(args.From)];
					end
				end,
				[3091] = function(args)
					args.RawMagical = args.RawMagical + 40;
				end,
				[3094] = function(args)
					if GetBuffCount(args.From, "itemstatikshankcharge") == 100 then
						local t = { 50, 50, 50, 50, 50, 58, 66, 75, 83, 92, 100, 109, 117, 126, 134, 143, 151, 160 };
						args.RawMagical = args.RawMagical + t[Damage:GetMaxLevel(args.From)];
					end
				end,
				[3100] = function(args)
					if HasBuff(args.From, "lichbane") then
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
			self.VariableItemDamageDatabase =
			{
				[1041] = function(args)
					if args.Target.team == TEAM_JUNGLE then
						args.CalculatedPhysical = args.CalculatedPhysical + 25;
					end
				end
			}
		end
		function __Damage:GetMaxLevel(hero)
			return MathMax(MathMin(hero.levelData.lvl, 18), 1);
		end
		function __Damage:CalculateDamage(from, target, damageType, rawDamage, isAbility, isAutoAttackOrTargetted)
			if from == nil or target == nil then
				return 0;
			end
			if isAbility == nil then
				isAbility = true;
			end
			if isAutoAttackOrTargetted == nil then
				isAutoAttackOrTargetted = false;
			end
			local fromIsMinion = from.type == Obj_AI_Minion;
			local targetIsMinion = target.type == Obj_AI_Minion;
			local baseResistance = 0;
			local bonusResistance = 0;
			local penetrationFlat = 0;
			local penetrationPercent = 0;
			local bonusPenetrationPercent = 0;
			if damageType == DAMAGE_TYPE_PHYSICAL then
				baseResistance = MathMax(target.armor - target.bonusArmor, 0);
				bonusResistance = target.bonusArmor;
				penetrationFlat = from.armorPen;
				penetrationPercent = from.armorPenPercent;
				bonusPenetrationPercent = from.bonusArmorPenPercent;
				-- Minions return wrong percent values.
				if fromIsMinion then
					penetrationFlat = 0;
					penetrationPercent = 0;
					bonusPenetrationPercent = 0;
				elseif from.type == Obj_AI_Turret then
					penetrationPercent = (BaseTurrets[from.charName] == nil) and 0.3 or 0.75;
					penetrationFlat = 0;
					bonusPenetrationPercent = 0;
				end
			elseif damageType == DAMAGE_TYPE_MAGICAL then
				baseResistance = MathMax(target.magicResist - target.bonusMagicResist, 0);
				bonusResistance = target.bonusMagicResist;
				penetrationFlat = from.magicPen;
				penetrationPercent = from.magicPenPercent;
				bonusPenetrationPercent = 0;
			elseif damageType == DAMAGE_TYPE_TRUE then
				return rawDamage;
			end
			local resistance = baseResistance + bonusResistance;
			if resistance > 0 then
				if penetrationPercent > 0 then
					baseResistance = baseResistance * penetrationPercent;
					bonusResistance = bonusResistance * penetrationPercent;
				end
				if bonusPenetrationPercent > 0 then
					bonusResistance = bonusResistance * bonusPenetrationPercent;
				end
				resistance = baseResistance + bonusResistance;
				resistance = resistance - penetrationFlat;
			end
			local percentMod = 1;
			-- Penetration cant reduce resistance below 0.
			if resistance >= 0 then
				percentMod = percentMod * (100 / (100 + resistance));
			else
				percentMod = percentMod * (2 - 100 / (100 - resistance));
			end
			local flatPassive = 0;
			local percentPassive = 1;
			if fromIsMinion and targetIsMinion then
				percentPassive = percentPassive * (1 + from.bonusDamagePercent);
			end
			local flatReceived = 0;
			if not isAbility and targetIsMinion then
				flatReceived = flatReceived - target.flatDamageReduction;
			end
			return MathMax(percentPassive * percentMod * (rawDamage + flatPassive) + flatReceived, 0);
		end
		function __Damage:GetStaticAutoAttackDamage(from, targetIsMinion)
			local args = {
				From = from,
				RawTotal = from.totalDamage,
				RawPhysical = 0,
				RawMagical = 0,
				CalculatedTrue = 0,
				CalculatedPhysical = 0,
				CalculatedMagical = 0,
				DamageType = DAMAGE_TYPE_PHYSICAL,
				TargetIsMinion = targetIsMinion
			}
			if self.StaticChampionDamageDatabase[args.From.charName] ~= nil then
				self.StaticChampionDamageDatabase[args.From.charName](args)
			end
			local HashSet = {}
			for i = 1, #ItemSlots do
				local slot = ItemSlots[i]
				local item = args.From:GetItemData(slot)
				if item ~= nil and item.itemID > 0 then
					if HashSet[item.itemID] == nil then
						if self.StaticItemDamageDatabase[item.itemID] ~= nil then
							self.StaticItemDamageDatabase[item.itemID](args)
						end
						HashSet[item.itemID] = true
					end
				end
			end
			return args
		end
		function __Damage:GetHeroAutoAttackDamage(from, target, static)
			local args = {
				From = from,
				Target = target,
				RawTotal = static.RawTotal,
				RawPhysical = static.RawPhysical,
				RawMagical = static.RawMagical,
				CalculatedTrue = static.CalculatedTrue,
				CalculatedPhysical = static.CalculatedPhysical,
				CalculatedMagical = static.CalculatedMagical,
				DamageType = static.DamageType,
				TargetIsMinion = target.type == Obj_AI_Minion,
				CriticalStrike = false,
			};
			if args.TargetIsMinion and args.Target.maxHealth <= 6 then
				return 1;
			end
			if self.VariableChampionDamageDatabase[args.From.charName] ~= nil then
				self.VariableChampionDamageDatabase[args.From.charName](args);
			end
			if args.DamageType == DAMAGE_TYPE_PHYSICAL then
				args.RawPhysical = args.RawPhysical + args.RawTotal;
			elseif args.DamageType == DAMAGE_TYPE_MAGICAL then
				args.RawMagical = args.RawMagical + args.RawTotal;
			elseif args.DamageType == DAMAGE_TYPE_TRUE then
				args.CalculatedTrue = args.CalculatedTrue + args.RawTotal;
			end
			if args.RawPhysical > 0 then
				args.CalculatedPhysical = args.CalculatedPhysical + self:CalculateDamage(from, target, DAMAGE_TYPE_PHYSICAL, args.RawPhysical, false, args.DamageType == DAMAGE_TYPE_PHYSICAL);
			end
			if args.RawMagical > 0 then
				args.CalculatedMagical = args.CalculatedMagical + self:CalculateDamage(from, target, DAMAGE_TYPE_MAGICAL, args.RawMagical, false, args.DamageType == DAMAGE_TYPE_MAGICAL);
			end
			local percentMod = 1;
			if args.From.critChance - 1 == 0 or args.CriticalStrike then
				percentMod = percentMod * self:GetCriticalStrikePercent(args.From);
			end
			return percentMod * args.CalculatedPhysical + args.CalculatedMagical + args.CalculatedTrue;
		end
		function __Damage:GetAutoAttackDamage(from, target, respectPassives)
			if respectPassives == nil then
				respectPassives = true;
			end
			if from == nil or target == nil then
				return 0;
			end
			local targetIsMinion = target.type == Obj_AI_Minion;
			if respectPassives and from.type == Obj_AI_Hero then
				return self:GetHeroAutoAttackDamage(from, target, self:GetStaticAutoAttackDamage(from, targetIsMinion));
			end
			if targetIsMinion then
				if target.maxHealth <= 6 then
					return 1;
				end
				if from.type == Obj_AI_Turret and BaseTurrets[from.charName] == nil then
					local percentMod = TurretToMinionPercentMod[target.charName]
					if percentMod ~= nil then
						return target.maxHealth * percentMod;
					end
				end
			end
			return self:CalculateDamage(from, target, DAMAGE_TYPE_PHYSICAL, from.totalDamage, false, true);
		end
		function __Damage:GetCriticalStrikePercent(from)
			local baseCriticalDamage = 2 + (HasItem(from, 3031) and 0.5 or 0)
			local percentMod = 1;
			local fixedMod = 0;
			if from.charName == "Jhin" then
				percentMod = 0.75;
			elseif from.charName == "XinZhao" then
				baseCriticalDamage = baseCriticalDamage - (0.875 - 0.125 * from:GetSpellData(_W).level)
			elseif from.charName == "Yasuo" then
				percentMod = 0.9;
			end
			return baseCriticalDamage * percentMod;
		end
		Damage = __Damage()
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- _G.Control .Attack .Move .CastSpell:																													
	_G.Control.Attack = function(target)
		if CONTROLL == nil and GameTimer() > NEXT_CONTROLL + 0.05 then
			CONTROLL = function()
				if CURSOR.IsReady then
					Orbwalker:Attack(target)
					NEXT_CONTROLL = GameTimer()
					return true
				end
				return false
			end
			return true
		end
		return false
	end
	----------------------------------------------------------------------------------------------------------------------------------------------------
	_G.Control.Move = function(a, b, c)
		if CONTROLL == nil and GameTimer() > NEXT_CONTROLL + 0.05 then
			local position
			if a and b and c then
				position = Vector(a, b, c)
			elseif a and b then
				position = Vector({ x = a, y = b})
			elseif a then
				if a.pos then
					position = a.pos
				else
					position = a
				end
			end
			CONTROLL = function()
				if position then
					if CURSOR.IsReady then
                        Orbwalker:MoveToPos(position)
						Spells.CanNext = true
						return true
					end
				else
                    Orbwalker:Move()
					Spells.CanNext = true
					return true
				end
				return false
			end
			return true
		end
		return false
	end
	----------------------------------------------------------------------------------------------------------------------------------------------------
	_G.Control.CastSpell = function(key, a, b, c)
		if CONTROLL == nil and GameTimer() > NEXT_CONTROLL + 0.05 then
			local position
			if a and b and c then
				position = Vector(a, b, c)
			elseif a and b then
				position = Vector({ x = a, y = b})
			elseif a then
				if a.pos then
					position = a.pos
				else
					position = a
				end
			end
			local spell
			if key == HK_Q then
				spell = _Q
			elseif key == HK_W then
				spell = _W
			elseif key == HK_E then
				spell = _E
			elseif key == HK_R then
				spell = _R
            end
            if spell ~= nil and GameCanUseSpell(spell) ~= 0 then
                return false
			end
			if spell ~= nil and not Spells.CanNext then
				return false
			end
            if position ~= nil and not CURSOR.IsReady then
                return false
			end
			if position ~= nil and MenuChamp.spell.isaa:Value() and Orbwalker:IsAutoAttacking(myHero) then
				return false
			end
			if spell == _Q then
				if GameTimer() < Spells.LastQ + 0.25 then
					return false
				else
					Spells.LastQ = GameTimer()
				end
			elseif spell == _W then
				if GameTimer() < Spells.LastW + 0.25 then
					return false
				else
					Spells.LastW = GameTimer()
				end
			elseif spell == _E then
				if GameTimer() < Spells.LastE + 0.25 then
					return false
				else
					Spells.LastE = GameTimer()
				end
			elseif spell == _R then
				if GameTimer() < Spells.LastR + 0.25 then
					return false
				else
					Spells.LastR = GameTimer()
				end
			end
			NEXT_CONTROLL = GameTimer()
			CONTROLL = function()
				if position then
                    if spell ~= nil and MenuChamp.spell.baa:Value() then
                        Spells.CanNext = false
					end
					CURSOR:SetCursor(_G.cursorPos, position, key, function()
						ControlKeyDown(key)
						ControlKeyUp(key)
                    end)
					Orbwalker.LastMoveLocal = 0
                    return true
				else
					ControlKeyDown(key)
					ControlKeyUp(key)
					return true
				end
			end
		end
		return false
	end
	----------------------------------------------------------------------------------------------------------------------------------------------------
	Callback.Add('Draw', function()
		Orbwalker:Tick()
		CURSOR:Tick()
		if CONTROLL ~= nil and CONTROLL() == true then
			CONTROLL = nil
		end
	end)
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Load:																																				
	_G.SDK =
	{
		DAMAGE_TYPE_PHYSICAL = 0,
		DAMAGE_TYPE_MAGICAL = 1,
		DAMAGE_TYPE_TRUE = 2,
		ORBWALKER_MODE_NONE = -1,
		ORBWALKER_MODE_COMBO = 0,
		ORBWALKER_MODE_HARASS = 1,
		ORBWALKER_MODE_LANECLEAR = 2,
		ORBWALKER_MODE_JUNGLECLEAR = 3,
		ORBWALKER_MODE_LASTHIT = 4,
		ORBWALKER_MODE_FLEE = 5
	}
	_G.SDK.Spells = Spells
	_G.SDK.ObjectManager = ObjectManager
	_G.SDK.Damage = Damage
	_G.SDK.TargetSelector = TargetSelector
	_G.SDK.HealthPrediction = HealthPrediction
	_G.SDK.Orbwalker = Orbwalker
	----------------------------------------------------------------------------------------------------------------------------------------------------
	Menu = MenuElement({name = "gsoOrbwalker", id = "gamsteronOrb", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/rsz_gsoorbwalker.png" })
	TargetSelector:CreateMenu()
	Orbwalker:CreateMenu()
	----------------------------------------------------------------------------------------------------------------------------------------------------
	Menu:MenuElement({name = "Drawings", id = "gsodraw", leftIcon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/circles.png", type = _G.MENU })
	Menu.gsodraw:MenuElement({name = "Enabled",  id = "enabled", value = true})
	TargetSelector:CreateDrawMenu()
	HealthPrediction:CreateDrawMenu()
	CURSOR:CreateDrawMenu()
	Orbwalker:CreateDrawMenu()
	----------------------------------------------------------------------------------------------------------------------------------------------------
	Core:OnEnemyHeroLoad(function(hero)
		local name = hero.charName
		if name == "Teemo" then
			Orbwalker.IsTeemo = true
		end
		if name == "Kayle" then ObjectManager.UndyingBuffs["JudicatorIntervention"] = true
		elseif name == "Taric" then ObjectManager.UndyingBuffs["TaricR"] = true
		elseif name == "Kindred" then ObjectManager.UndyingBuffs["kindredrnodeathbuff"] = true
		elseif name == "Zilean" then ObjectManager.UndyingBuffs["ChronoShift"] = true; ObjectManager.UndyingBuffs["chronorevive"] = true
		elseif name == "Tryndamere" then ObjectManager.UndyingBuffs["UndyingRage"] = true
		elseif name == "Jax" then ObjectManager.UndyingBuffs["JaxCounterStrike"] = true
		elseif name == "Fiora" then ObjectManager.UndyingBuffs["FioraW"] = true
		elseif name == "Aatrox" then ObjectManager.UndyingBuffs["aatroxpassivedeath"] = true
		elseif name == "Vladimir" then ObjectManager.UndyingBuffs["VladimirSanguinePool"] = true
		elseif name == "KogMaw" then ObjectManager.UndyingBuffs["KogMawIcathianSurprise"] = true
		elseif name == "Karthus" then ObjectManager.UndyingBuffs["KarthusDeathDefiedBuff"] = true
		end
	end)
	----------------------------------------------------------------------------------------------------------------------------------------------------
	Callback.Add('Tick', function()
		if _G.Orbwalker.Enabled:Value() then _G.Orbwalker.Enabled:Value(false) end
		if Orbwalker.IsTeemo then
			local hasTeemoBlind = false
			for i = 0, myHero.buffCount do
				local buff = myHero:GetBuff(i)
				if buff and buff.count > 0 and buff.name:lower() == "blindingdart" then
					hasTeemoBlind = true
					break
				end
			end
			Orbwalker.IsBlindedByTeemo = hasTeemoBlind
		end
		HealthPrediction:Tick()
		Spells:DisableAutoAttack()
		if Spells.Work ~= nil then
			if GameTimer() < Spells.WorkEndTime then
				Spells.Work()
				return
			end
			Spells.Work = nil
		end
	end)
	----------------------------------------------------------------------------------------------------------------------------------------------------
	Callback.Add('WndMsg', function(msg, wParam)
		TargetSelector:WndMsg(msg, wParam)
		Orbwalker:WndMsg(msg, wParam)
		Spells:WndMsg(msg, wParam)
	end)
	----------------------------------------------------------------------------------------------------------------------------------------------------
	Callback.Add('Draw', function()
		if not Menu.gsodraw.enabled:Value() then return end
		TargetSelector:Draw()
		HealthPrediction:Draw()
		CURSOR:Draw()
		Orbwalker:Draw()
	end)
	----------------------------------------------------------------------------------------------------------------------------------------------------
	_G.GamsteronOrbwalkerLoaded = true
--------------------------------------------------------------------------------------------------------------------------------------------------------
