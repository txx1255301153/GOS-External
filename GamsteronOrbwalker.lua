local GamsteronOrbVer = 0.0771
local LocalCore, Menu, MenuItem, Cursor, Items, Spells, Damage, ObjectManager, TargetSelector, HealthPrediction, Orbwalker, HoldPositionButton
local AttackSpeedData = { windup = myHero.attackData.windUpTime, anim = myHero.attackData.animationTime, tickwindup = os.clock(), tickanim = os.clock() }

do
	if _G.GamsteronOrbwalkerLoaded == true then return end
	
	if _G.SDK and _G.SDK.Orbwalker then return end

	if not FileExist(COMMON_PATH .. "GamsteronCore.lua") then
		DownloadFileAsync("https://raw.githubusercontent.com/gamsteron/GOS-External/master/Common/GamsteronCore.lua", COMMON_PATH .. "GamsteronCore.lua", function() end)
		while not FileExist(COMMON_PATH .. "GamsteronCore.lua") do end
	end

	require('GamsteronCore')
	if _G.GamsteronCoreUpdated then return end
	LocalCore = _G.GamsteronCore

	local success, version = LocalCore:AutoUpdate({
		version = GamsteronOrbVer,
		scriptPath = SCRIPT_PATH .. "GamsteronOrbwalker.lua",
		scriptUrl = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/GamsteronOrbwalker.lua",
		versionPath = SCRIPT_PATH .. "GamsteronOrbwalker.version",
		versionUrl = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/GamsteronOrbwalker.version"
	})
	if success then
		print("GamsteronOrbwalker updated to version " .. version .. ". Please Reload with 2x F6 !")
		_G.GamsteronOrbwalkerUpdated = true
		return
	end

	math.randomseed(os.clock())
end

local HAS_LETHAL_TEMPO				= false
local LAST_LETHAL_TEMPO				= 0
local ATTACK_WINDUP					= 0
local ATTACK_ANIMATION				= 0

local GAMSTERON_MODE_DMG			= false
local CASTSPELL_TICK				= 0
local CASTSPELL_CANMOVE				= 0
local LAST_KEYPRESS					= 0
local LAST_MOUSECLICK				= 0
_G.GAMSTERON_CONTROLL				= nil

local OsClock						= _G.os.clock
local GetTickCount					= GetTickCount
local myHero						= _G.myHero
local heroName						= myHero.charName
local Vector						= Vector
local DrawLine						= Draw.Line
local DrawColor						= Draw.Color
local DrawCircle					= Draw.Circle
local DrawText						= Draw.Text
local ControlIsKeyDown				= Control.IsKeyDown
local ControlMouseEvent				= Control.mouse_event
local ControlSetCursorPos			= Control.SetCursorPos
local ControlKeyUp					= Control.KeyUp
local ControlKeyDown				= Control.KeyDown
local GameCanUseSpell				= Game.CanUseSpell
local GameLatency					= Game.Latency
local GameTimer						= Game.Timer
local GameParticleCount				= Game.ParticleCount
local GameParticle					= Game.Particle
local GameHeroCount 				= Game.HeroCount
local GameHero 						= Game.Hero
local GameMinionCount 				= Game.MinionCount
local GameMinion 					= Game.Minion
local GameTurretCount 				= Game.TurretCount
local GameTurret 					= Game.Turret
local GameWardCount 				= Game.WardCount
local GameWard 						= Game.Ward
local GameObjectCount 				= Game.ObjectCount
local GameObject					= Game.Object
local GameMissileCount 				= Game.MissileCount
local GameMissile					= Game.Missile
local GameIsChatOpen				= Game.IsChatOpen
local GameIsOnTop					= Game.IsOnTop
local pairs							= pairs
local MathCeil						= math.ceil
local MathMax						= math.max
local MathMin						= math.min
local MathSqrt						= math.sqrt
local MathRandom					= math.random
local MathHuge						= 999999999
local MathAbs						= math.abs
local TableInsert					= _G.table.insert
local TableRemove					= _G.table.remove

local function GetProjSpeed()
	local name = myHero.charName
	if LocalCore.IsMelee[name] or (LocalCore.SpecialMelees[name] ~= nil and LocalCore.SpecialMelees[name]()) then
		return MathHuge
	end
	if LocalCore.SpecialMissileSpeeds[name] ~= nil then
		local projectileSpeed = LocalCore.SpecialMissileSpeeds[name](myHero)
		if projectileSpeed then
			return projectileSpeed
		end
	end
	if myHero.attackData.projectileSpeed then
		return myHero.attackData.projectileSpeed
	end
	return MathHuge
end

local function GetWindup()
	local name = myHero.charName
	if LocalCore.SpecialWindUpTimes[name] ~= nil then
		local SpecialWindUpTime = LocalCore.SpecialWindUpTimes[name](myHero)
		if SpecialWindUpTime then
			return SpecialWindUpTime
		end
	end
	if HAS_LETHAL_TEMPO then
		return myHero.attackData.windUpTime
	elseif OsClock() < AttackSpeedData.tickwindup and myHero.attackSpeed * (1 / myHero.attackData.animationTime / myHero.attackSpeed) <= 2.5 then
		return myHero.attackData.windUpTime
	end
	return ATTACK_WINDUP
end

local function GetAnimation()
	if HAS_LETHAL_TEMPO then
		return myHero.attackData.animationTime
	elseif OsClock() < AttackSpeedData.tickanim and myHero.attackSpeed * (1 / myHero.attackData.animationTime / myHero.attackSpeed) <= 2.5 then
		return myHero.attackData.animationTime
	end
	return ATTACK_ANIMATION
end

local function IsInDistance2D(v1, v2, range)
	local dx = v1.x - v2.x
	local dy = v1.y - v2.y
	return dx * dx + dy * dy <= range * range
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

do
	local __Cursor = LocalCore:Class()

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

	function __Cursor:LastStep()
		self.WorkDone = true
		self.EndTime = 0
		self.StartTime = 0
		ControlSetCursorPos(self.CursorPos.x, self.CursorPos.y)
		if IsInDistance2D(self.CursorPos, _G.cursorPos, 120) then
			self.IsReady = true
			_G.GAMSTERON_CONTROLL = nil
		end
	end

	function __Cursor:CastKey()
		if self.CastPos == nil then return end
		local newpos
		if self.CastPos.pos then
			newpos = Vector(self.CastPos.pos.x, self.CastPos.pos.y + 50, self.CastPos.pos.z):To2D()
		elseif self.CastPos.z then
			newpos = self.CastPos:To2D()
		else
			newpos = self.CastPos
		end
		ControlSetCursorPos(newpos.x, newpos.y)
		if self.Work ~= nil then--and Utilities:GetDistance2DSquared(newpos, _G.cursorPos) <= MAXIMUM_MOUSE_DISTANCE then
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
		self.MousePos = _G.mousePos
		self.CastPos = castpos
		self.Work = work
		self.WorkDone = false
		self.EndTime = 0
		self:CastKey()
	end

	function __Cursor:WndMsg(msg, wParam)
		if not self.IsReadyGlobal and wParam == self.Key then
			self.IsReadyGlobal = true
		end
	end

	function __Cursor:Tick()
		if self.IsReady then return end
		if not self.WorkDone and (self.IsReadyGlobal or GameTimer() > self.StartTime + 0.1) then
			if not self.IsReadyGlobal then
				self.IsReadyGlobal = true
			end
			self.EndTime = GameTimer() + Menu.orb.excdelay:Value() * 0.001
			self.WorkDone = true
		end
		if self.WorkDone and GameTimer() > self.EndTime and GameTimer() - self.StartTime > 0.02 then
			ControlSetCursorPos(self.CursorPos.x, self.CursorPos.y)
			if IsInDistance2D(self.CursorPos, _G.cursorPos, 120) then
				self.IsReady = true
				_G.GAMSTERON_CONTROLL = nil
			end
			return
		end
		self:CastKey()
	end

	function __Cursor:CreateDrawMenu()
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

	Cursor = __Cursor()
end

do
	local __Items = LocalCore:Class()

	function __Items:__init()
		self.CachedItems = {}
		self.ItemSlots = { ITEM_1, ITEM_2, ITEM_3, ITEM_4, ITEM_5, ITEM_6, ITEM_7 }
		self.ItemKeys = { HK_ITEM_1, HK_ITEM_2, HK_ITEM_3, HK_ITEM_4, HK_ITEM_5, HK_ITEM_6, HK_ITEM_7 }
		-- maxxxel
		self.ItemHydra = {
			["tia"] = {name = "Tiamat", id = 3077, range = 300, icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/e/e3/Tiamat_item.png"},
			["hyd"] = {name = "Ravenous Hydra", id = 3074, range = 300, icon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/e/e8/Ravenous_Hydra_item.png"},
			["tit"] = {name = "Titanic Hydra", id = 3748, range = 300, icon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/2/22/Titanic_Hydra_item.png"}
		}
		self.ItemSkillshot = {
			["pro"] = {name = "Hextech Protobelt-01", id = 3152, range = 800, icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/8/8d/Hextech_Protobelt-01_item.png"},
			["glp"] = {name = "Hextech GLP-800", id = 3030, range = 800, icon = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/c/c9/Hextech_GLP-800_item.png"}
		}
		self.ItemBotrk = {
			["bot"] = {name = "Botrk & Ornn Botrk & Cutlass", onlyOrbTS = true, dmgType = 1, id = { 3153, 3144, 3389 }, range = 550, icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/2/2f/Blade_of_the_Ruined_King_item.png"},
			["gun"] = {name = "Hextech Gunblade", onlyOrbTS = false, dmgType = 2, id = { 3146 }, range = 700, icon = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/6/64/Hextech_Gunblade_item.png"}
		}
		self.ItemQss = {
			["qss"] = {name = "QSS & Mercurial Scimittar", id = {3139, 3140}, icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/f/f9/Quicksilver_Sash_item.png"}
		}
		-- maxxxel
		Callback.Add("Tick", function()
			local result = false
			local result = self:UseQss()
			if not result and Orbwalker.Modes[LocalCore.ORBWALKER_MODE_COMBO] then
				self:UseBotrk()
			end
			self.CachedItems = {}
		end)
	end

	function __Items:UseBotrk()
		local result = false
		if OsClock() < LAST_KEYPRESS then return false end
		for i, item in pairs(self.ItemBotrk) do
			local menu = MenuItem[i]
			if menu.enabled:Value() then
				local isGun = false; if i == "gun" then isGun = true end
				for j, id in pairs(item.id) do
					local Item = self:IsReady(myHero, id)
					if Item.IsReady then
						local target, range
						if menu.onlyorb:Value() then
							target = TargetSelector:GetComboTarget()
						elseif isGun then
							target = TargetSelector:GetTarget(item.range-35, menu.dmgType:Value() - 1)
						else
							target = TargetSelector:GetTarget(item.range+myHero.boundingRadius-35, menu.dmgType:Value() - 1, true)
						end
						if target ~= nil then
							if isGun then
								range = item.range-35
							else
								range = item.range+myHero.boundingRadius+target.boundingRadius-35
							end
							local distance = target.pos:DistanceTo(myHero.pos)
							if distance <= range then
								if isGun and distance < menu.xrange:Value() then
									Control.CastSpell(Item.Key, target)
									result = true
								else

									-- myHero.health < x
									local meHealth = 100 * ( myHero.health / myHero.maxHealth )
									if meHealth <= menu.xhealtha:Value() then
										Control.CastSpell(Item.Key, target)
										result = true
										break
									end
									-- myHero.health < x

									-- melee
									if menu.melee:Value() then
										local meleeHeroes = {}
										for i = 1, GameHeroCount() do
											local hero = GameHero(i)
											if LocalCore:IsValidTarget(hero) and hero.team == LocalCore.TEAM_ENEMY and hero.range < 400 and myHero.pos:DistanceTo(hero.pos) < hero.range + myHero.boundingRadius + hero.boundingRadius then
												TableInsert(meleeHeroes, hero)
											end
										end
										if #meleeHeroes > 0 then
											_G.table.sort(meleeHeroes, function(a,b) return a.health + (a.totalDamage*2) + (a.attackSpeed*100) > b.health + (b.totalDamage*2) + (b.attackSpeed*100) end)
											local meleeTarget = meleeHeroes[1]
											if LocalCore:IsFacing(meleeTarget, myHero, 60) then
												Control.CastSpell(Item.Key, meleeHeroes[1])
												result = true
												break
											end
										end
									end
									-- melee
									
									-- fleeing
									if distance >= menu.flee.range:Value() and 100 * ( target.health / target.maxHealth ) <= menu.flee.health:Value() and LocalCore:IsFacing(myHero, target, 60) and not LocalCore:IsFacing(target, myHero, 60) then
										Control.CastSpell(Item.Key, target)
										result = true
										break
									end
									-- fleeing
								end
							end
						end
					end
				end
				if result then break end
			end
		end
		return result
	end

	function __Items:UseQss()
		local result = false
		if OsClock() < LAST_KEYPRESS then return false end
		for i, item in pairs(self.ItemQss) do
			local menu = MenuItem[i]
			if menu.enabled:Value() then
				for j, id in pairs(item.id) do
					local Item = self:IsReady(myHero, id)
					if Item.IsReady then
						local enemiesCount = 0
						local menuDistance = menu.types.distance:Value()
						for i = 1, GameHeroCount() do
							local hero = GameHero(i)
							if hero and hero.valid and hero.alive and hero.team == LocalCore.TEAM_ENEMY and myHero.pos:DistanceTo(hero.pos) <= menuDistance then
								enemiesCount = enemiesCount + 1
							end
						end
						if enemiesCount >= menu.types.count:Value() then
							local menuDuration = menu.types.duration:Value() * 0.001
							local menuBuffs = {
								[5] = menu.types.stun:Value(),
								[11] = menu.types.snare:Value(),
								[24] = menu.types.supress:Value(),
								[29] = menu.types.knockup:Value(),
								[21] = menu.types.fear:Value(),
								[22] = menu.types.charm:Value(),
								[8] = menu.types.taunt:Value(),
								[30] = menu.types.knockback:Value(),
								[25] = menu.types.blind:Value(),
								[31] = menu.types.disarm:Value()
							}
							for k = 0, myHero.buffCount do
								local buff = myHero:GetBuff(k)
								if buff and buff.count > 0 then
									local buffType = buff.type
									local buffDuration = buff.duration
									if menuBuffs[buffType] then
										if buffDuration >= menuDuration then
											result = true
											LAST_KEYPRESS = OsClock() + 0.07
											ControlKeyDown(Item.Key)
											ControlKeyUp(Item.Key)
											break
										end
									elseif buffType == 10 and menu.types.slowm.slow:Value() and buffDuration >= menu.types.slowm.duration:Value() * 0.001 and myHero.ms <= menu.types.slowm.speed:Value() then
										result = true
										LAST_KEYPRESS = OsClock() + 0.07
										ControlKeyDown(Item.Key)
										ControlKeyUp(Item.Key)
										break
									end
								end
							end
							if result then break end
						end
					end
				end
				if result then break end
			end
		end
		return result
	end

	function __Items:CreateMenu()
		MenuItem = MenuElement({name = "Gamsteron Items", id = "gamsteronitems", type = _G.MENU, leftIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/a/aa/Ace_in_the_Hole.png" })
		for i, k in pairs(self.ItemBotrk) do
			MenuItem:MenuElement({name = k.name, id = i, type = _G.MENU, leftIcon = k.icon })
			MenuItem[i]:MenuElement({ id = "enabled", name = "Enabled", value = true })
			if i == "gun" then MenuItem[i]:MenuElement({ id = "xrange", name = "Enemy in distance < X (700 = always ON)", value = 0, min = 0, max = 700, step = 10 }) end
			MenuItem[i]:MenuElement({ id = "melee", name = "AntiMelee - isfacing and distance < enemy melee range", value = true })
			MenuItem[i]:MenuElement({ id = "onlyorb", name = "Only Orb[attack] Target", value = k.onlyOrbTS })
			MenuItem[i]:MenuElement({ id = "dmgType", name = "TargetSelector DamageType", value = k.dmgType, drop = { "AD", "AP" } })
			MenuItem[i]:MenuElement({ id = "xhealtha", name = myHero.charName .. " %HP < X", value = 15, min = 0, max = 100, step = 1 })
			MenuItem[i]:MenuElement({ id = "flee", name = "On Fleeing Target", type = _G.MENU })
				MenuItem[i].flee:MenuElement({ id = "range", name = "Enemy in distance > X", value = 550, min = 300, max = 600, step = 10 })
				MenuItem[i].flee:MenuElement({ id = "health", name = "Enemy %HP < X", value = 50, min = 0, max = 100, step = 1 })
		end
		for i, k in pairs(self.ItemQss) do
			--[[
				STUN = 5
				SNARE = 11
				SUPRESS = 24
				KNOCKUP = 29
				FEAR = 21 -> fiddle Q, ...
				CHARM = 22 -> ahri E, ...
				TAUNT = 8 -> rammus E, ...
				SLOW = 10 -> nasus W, zilean E
				KNOCKBACK = 30 -> alistar W, lee sin R, ...
				BLIND = 25 -> teemo Q
				DISARM = 31 -> Lulu W
			]]
			MenuItem:MenuElement({ id = i, name = k.name, type = _G.MENU, leftIcon = k.icon })
			MenuItem[i]:MenuElement({ id = "enabled", name = "Enabled", value = true })
			MenuItem[i]:MenuElement({ id = "types", name = "Buff Types", type = _G.MENU })
			MenuItem[i].types:MenuElement({ id = "stun", name = "Stun - sona r", value = true })
			MenuItem[i].types:MenuElement({ id = "snare", name = "Snare - xayah e", value = true })
			MenuItem[i].types:MenuElement({ id = "supress", name = "Supress - warwick r", value = true })
			MenuItem[i].types:MenuElement({ id = "knockup", name = "Knockup - yasuo q3", value = true })
			MenuItem[i].types:MenuElement({ id = "fear", name = "Fear - fiddle q", value = true })
			MenuItem[i].types:MenuElement({ id = "charm", name = "Charm - ahri e", value = true })
			MenuItem[i].types:MenuElement({ id = "taunt", name = "Taunt - rammus e", value = true })
			MenuItem[i].types:MenuElement({ id = "knockback", name = "Knockback - alistar w", value = true })
			MenuItem[i].types:MenuElement({ id = "blind", name = "Blind - teemo q", value = true })
			MenuItem[i].types:MenuElement({ id = "disarm", name = "Disarm - lulu w", value = true })
			MenuItem[i].types:MenuElement({ id = "duration", name = "Minimum duration - in ms", value = 500, min = 0, max = 1000, step = 50 })
			MenuItem[i].types:MenuElement({ id = "count", name = "Enemies Around - Count", value = 1, min = 0, max = 5, step = 1 })
			MenuItem[i].types:MenuElement({ id = "distance", name = "Enemies Around - Distance", value = 1200, min = 0, max = 1500, step = 50 })
			MenuItem[i].types:MenuElement({ id = "slowm", name = "Slow Settings", type = _G.MENU })
			MenuItem[i].types.slowm:MenuElement({ id = "slow", name = "Slow", value = true })
			MenuItem[i].types.slowm:MenuElement({ id = "speed", name = "Maximum " .. myHero.charName .. " Move Speed", value = 200, min = 0, max = 250, step = 10 })
			MenuItem[i].types.slowm:MenuElement({ id = "duration", name = "Minimum duration - in ms", value = 1500, min = 1000, max = 3000, step = 50 })
		end
		--[[
		for i, k in pairs(self.ItemSkillshot) do
			MenuItem:MenuElement({name = k.name, id = i, type = MENU, leftIcon = k.icon })
			MenuItem[i]:MenuElement({ id = "enable", name = "Enabled", value = true })
		end
		for i, k in pairs(self.ItemHydra) do
			MenuItem:MenuElement({name = k.name, id = i, type = MENU, leftIcon = k.icon })
			MenuItem[i]:MenuElement({ id = "enable", name = "Enabled", value = true })
		end
		--]]
	end

	function __Items:IsReady(unit, id)
		local item = self:GetItemByID(unit, id)
		if item == nil then return { IsReady = false, Key = 0 } end
		if myHero:GetSpellData(self.ItemSlots[item]).currentCd == 0 then
			return { IsReady = true, Key = self.ItemKeys[item] }
		end
		return { IsReady = false, Key = 0 }
	end

	function __Items:GetItemByID(unit, id)
		local networkID = unit.networkID
		if self.CachedItems[networkID] == nil then
			local t = {}
			for i = 1, #self.ItemSlots do
				local slot = self.ItemSlots[i]
				local item = unit:GetItemData(slot)
				if item ~= nil and item.itemID > 0 then
					t[item.itemID] = i
				end
			end
			self.CachedItems[networkID] = t
		end
		return self.CachedItems[networkID][id]
	end

	Items = __Items()
end

do
	local __Spells = LocalCore:Class()

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
		self.StartTime = 0
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
		if a and a.valid and a.startTime > self.StartTime and myHero.isChanneling and not LocalCore.SpecialAutoAttacks[a.name] then
			local name = a.name
			if self.Work == nil and GameTimer() > self.WorkEndTime and self.WorkList[name] ~= nil then
				self.WorkEndTime = GameTimer() + self.WorkList[name][1]
				self.Work = self.WorkList[name][2]
			end
			local twindup = self.WindupList[name]
			local windup = twindup ~= nil and twindup or a.windup
			local t = a.startTime + windup
			t = t - LATENCY
			self.SpellEndTime = t
			self.StartTime = a.startTime
			if GameTimer() < Orbwalker.AttackLocalStart + GetWindup() - 0.09 or GameTimer() < Orbwalker.AttackCastEndTime - 0.1 then
				Orbwalker:__OnAutoAttackReset()
			end
			return true
		end
		return false
	end

	function __Spells:WndMsg(msg, wParam)
		local currentTime = GameTimer()
		if wParam == HK_Q and currentTime > self.LastQk + 0.33 and GameCanUseSpell(_Q) == 0 then
			self.LastQk = currentTime
		elseif wParam == HK_W and currentTime > self.LastWk + 0.33 and GameCanUseSpell(_W) == 0 then
			self.LastWk = currentTime
		elseif wParam == HK_E and currentTime > self.LastEk + 0.33 and GameCanUseSpell(_E) == 0 then
			self.LastEk = currentTime
		elseif wParam == HK_R and currentTime > self.LastRk + 0.33 and GameCanUseSpell(_R) == 0 then
			self.LastRk = currentTime
		end
	end

	function __Spells:IsReady(spell, delays)
		delays = delays or { q = 0, w = 0, e = 0, r = 0 }
		local currentTime = GameTimer()
		if not Cursor.IsReady or _G.GAMSTERON_CONTROLL ~= nil or OsClock() <= CASTSPELL_TICK then
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
			if self.IsLastHitable and not Orbwalker.IsNone and not Orbwalker.Modes[LocalCore.ORBWALKER_MODE_COMBO] then
				for i, minion in pairs(self.FarmMinions) do
					if minion.LastHitable then
						local unit = minion.Minion
						if LocalCore:IsValidTarget(unit) and unit.handle ~= HealthPrediction.LastHandle then
							TableInsert(result, unit)
						end
					end
				end
			end
			return result
		end
		function c:GetLaneClearTargets()
			local result = {}
			if Orbwalker.Modes[LocalCore.ORBWALKER_MODE_LANECLEAR] then
				for i, minion in pairs(self.FarmMinions) do
					local unit = minion.Minion
					if LocalCore:IsValidTarget(unit) and unit.handle ~= HealthPrediction.LastLCHandle then
						TableInsert(result, unit)
					end
				end
			end
			return result
		end
		function c:ShouldWait()
			return GameTimer() <= self.ShouldWaitTime + Menu.orb.lclear.swait:Value() * 0.001
		end
		function c:SetLastHitable(target, time, damage)
			local hpPred = HealthPrediction:GetPrediction(target, time)
			local lastHitable = hpPred - damage < 0
			if lastHitable then self.IsLastHitable = true end
			local almostLastHitable = false
			if not lastHitable then
				local dmg = HealthPrediction:GetPrediction(target, myHero:GetSpellData(spell).cd + (time * 3))
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
			if Orbwalker.Modes[LocalCore.ORBWALKER_MODE_COMBO] or Orbwalker.IsNone then
				return
			end
			local targets = ObjectManager:GetEnemyMinions(self.Range - 35, false)
			local projectileSpeed = self.Speed
			local winduptime = self.Delay
			local latency = LATENCY * 0.5
			local pos = myHero.pos
			for i = 1, #targets do
				local target = targets[i]
				local FlyTime = LocalCore:GetDistance(pos, target.pos) / projectileSpeed
				TableInsert(self.FarmMinions, self:SetLastHitable(target, winduptime + FlyTime + latency, damagefunc()))
			end
			self.CanCheckTurret = false
		end
		return result
	end

	Spells = __Spells()
end

do
	local __TargetSelector = LocalCore:Class()

	function __TargetSelector:__init()
		self.SelectedTarget = nil
		self.LastSelTick = 0
	end

	function __TargetSelector:GetTarget(a, dmgType, bb, validmode)
		local SelectedID = -1
		local mePos = myHero.pos
		--selected:
		if Menu.ts.selected.enable:Value() and self.SelectedTarget ~= nil and LocalCore:IsValidTarget(self.SelectedTarget) and not ObjectManager:IsHeroImmortal(self.SelectedTarget, false) and self.SelectedTarget.pos.onScreen then
			SelectedID = self.SelectedTarget.networkID
			if Menu.ts.selected.onlysel:Value() then
				if type(a) == "number" then
					if LocalCore:IsInRange(mePos, self.SelectedTarget.pos, a) then
						return self.SelectedTarget
					end
				elseif type(a) == "table" then
					local x = 0
					for i = 1, #a do
						local u = a[i]
						if u then
							local dist = LocalCore:GetDistanceSquared(mePos, u.pos)
							if dist > x then
								x = dist
							end
						end
					end
					if LocalCore:IsInRange(mePos, self.SelectedTarget.pos, x) then
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
					local multiplier = LocalCore.PriorityMultiplier[priority]
					local def
					if dmgType == LocalCore.DAMAGE_TYPE_MAGICAL then
						def = multiplier * (unit.magicResist - myHero.magicPen)
					elseif dmgType == LocalCore.DAMAGE_TYPE_PHYSICAL then
						def = multiplier * (unit.armor - myHero.armorPen)
					else
						def = 0
					end
					if def and def > 0 then
						if dmgType == LocalCore.DAMAGE_TYPE_MAGICAL then
							def = myHero.magicPenPercent * def
						elseif dmgType == LocalCore.DAMAGE_TYPE_PHYSICAL then
							def = myHero.bonusArmorPenPercent * def
						else
							def = 0
						end
					end
					x = ( ( unit.health * multiplier * ( ( 100 + def ) / 100 ) ) - ( unit.totalDamage * unit.attackSpeed * 2 ) ) - unit.ap
				elseif mode == 2 then
					x = LocalCore:GetDistance(unit.pos, mePos)
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
		local mePos = myHero.pos
		for i = 1, GameHeroCount() do
			local hero = GameHero(i)
			if hero and hero.team == LocalCore.TEAM_ENEMY and LocalCore:IsValidTarget(hero) and not ObjectManager:IsHeroImmortal(hero, true) then
				local herorange = range
				if myHero.charName == "Caitlyn" and LocalCore:HasBuff(hero, "caitlynyordletrapinternal") then
					herorange = herorange + 600
				else
					herorange = herorange + bbox + hero.boundingRadius
				end
				if LocalCore:IsInRange(mePos, hero.pos, herorange) then
					TableInsert(targets, hero)
				end
			end
		end
		local t = self:GetTarget(targets, LocalCore.DAMAGE_TYPE_PHYSICAL)
		if myHero.charName ~= "Kalista" then
			return t
		end
		if t == nil then
			local hp = MathHuge
			for i = 1, GameHeroCount() do
				local obj = GameHero(i)
				if LocalCore:IsValidTarget(obj) and obj.team ~= LocalCore.TEAM_ALLY and LocalCore:IsInAutoAttackRange(myHero, obj) and obj.health < hp then
					t = obj
					hp = obj.health
				end
			end
		end
		if t == nil then
			hp = MathHuge
			for i = 1, GameMinionCount() do
				local obj = GameMinion(i)
				if LocalCore:IsValidTarget(obj) and obj.team ~= LocalCore.TEAM_ALLY and LocalCore:IsInAutoAttackRange(myHero, obj) and obj.health < hp then
					t = obj
					hp = obj.health
				end
			end
		end
		if t == nil then
			hp = MathHuge
			for i = 1, GameTurretCount() do
				local obj = GameTurret(i)
				if LocalCore:IsValidTarget(obj) and obj.team ~= LocalCore.TEAM_ALLY and LocalCore:IsInAutoAttackRange(myHero, obj) and obj.health < hp then
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
			local pos = _G.mousePos
			for i = 1, #enemyList do
				local unit = enemyList[i]
				local distance = LocalCore:GetDistance(pos, unit.pos)
				if distance < 150 and distance < num then
					self.SelectedTarget = unit
					num = distance
				end
			end
			self.LastSelTick = GetTickCount()
		end
	end

	function __TargetSelector:Draw()
		if Menu.gsodraw.selected.enabled:Value() and LocalCore:IsValidTarget(self.SelectedTarget) then
			DrawCircle(self.SelectedTarget.pos, Menu.gsodraw.selected.radius:Value(), Menu.gsodraw.selected.width:Value(), Menu.gsodraw.selected.color:Value())
		end
	end

	function __TargetSelector:CreatePriorityMenu(charName)
		local priority
		if LocalCore.Priorities[charName] ~= nil then
			priority = LocalCore.Priorities[charName]
		else
			priority = 1
		end
		Menu.ts.priorities:MenuElement({ id = charName, name = charName, value = priority, min = 1, max = 5, step = 1 })
	end

	function __TargetSelector:CreateMenu()
		Menu:MenuElement({name = "Target Selector", id = "ts", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Icons/ts.png" })
			Menu.ts:MenuElement({ id = "Mode", name = "Mode", value = 1, drop = { "Auto", "Closest", "Least Health", "Highest Priority" } })
			Menu.ts:MenuElement({ id = "priorities", name = "Priorities", type = _G.MENU })
				LocalCore:OnEnemyHeroLoad(function(hero) self:CreatePriorityMenu(hero.charName) end)
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
		local x = LocalCore.Priorities[target.charName]
		if x ~= nil then
			return x
		end
		return 1
	end

	TargetSelector = __TargetSelector()
end

do
	local __ObjectManager = LocalCore:Class()

	function __ObjectManager:__init()
		self.UndyingBuffs = { ["zhonyasringshield"] = true }
	end

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

	function __ObjectManager:GetEnemyBuildings(range, bb)
		local result = {}
		local turrets = LocalCore:GetEnemyTurrets()
		local inhibitors = LocalCore:GetEnemyInhibitors()
		local nexus = LocalCore:GetEnemyNexus()
		local br = range; if bb then br = br + 270 - 30; end --myHero.range + 270 bbox
		local nr = range; if bb then nr = nr + 380 - 30; end --myHero.range + 380 bbox
		local mePos = myHero.pos
		for i = 1, #turrets do
			local turret = turrets[i]
			local tr = range; if bb then tr = tr + turret.boundingRadius * 0.75; end
			if turret and LocalCore:IsValidTarget(turret) and LocalCore:IsInRange(mePos, turret.pos, tr) then
				TableInsert(result, turret)
			end
		end
		for i = 1, #inhibitors do
			local barrack = inhibitors[i]
			if barrack and barrack.isTargetable and barrack.visible and LocalCore:IsInRange(mePos, barrack.pos, br) then
				TableInsert(result, barrack)
			end
		end
		if nexus and nexus.isTargetable and nexus.visible and LocalCore:IsInRange(mePos, nexus.pos, nr) then
			TableInsert(result, nexus)
		end
		return result
	end

	function __ObjectManager:GetMinionType(minion)
		if minion.team == LocalCore.TEAM_JUNGLE then
			return LocalCore.MINION_TYPE_MONSTER
		elseif minion.maxHealth <= 6 then
			return LocalCore.MINION_TYPE_OTHER_MINION
		else
			return LocalCore.MINION_TYPE_LANE_MINION
		end
	end

	function __ObjectManager:GetMinions(range)
		local result = {}
		range = range or MathHuge;
		local mePos = myHero.pos
		for i = 1, GameMinionCount() do
			local minion = GameMinion(i)
			if LocalCore:IsValidTarget(minion) and self:GetMinionType(minion) == LocalCore.MINION_TYPE_LANE_MINION then
				if LocalCore:IsInRange(mePos, minion.pos, range) then
					TableInsert(result, minion)
				end
			end
		end
		return result
	end

	function __ObjectManager:GetAllyMinions(range, bb)
		local result = {}
		range = range or MathHuge;
		local mePos = myHero.pos
		for i = 1, GameMinionCount() do
			local minion = GameMinion(i)
			local mr = range; if bb then mr = mr + minion.boundingRadius; end
			if minion and minion.team == LocalCore.TEAM_ALLY and LocalCore:IsValidTarget(minion) and self:GetMinionType(minion) == LocalCore.MINION_TYPE_LANE_MINION and LocalCore:IsInRange(mePos, minion.pos, mr) then
				TableInsert(result, minion)
			end
		end
		return result
	end

	function __ObjectManager:GetEnemyMinions(range)
		local result = {}
		range = range or MathHuge;
		local mePos = myHero.pos
		for i = 1, GameMinionCount() do
			local minion = GameMinion(i)
			local mr = range; if bb then mr = mr + minion.boundingRadius; end
			if minion and minion.team == LocalCore.TEAM_ENEMY and LocalCore:IsValidTarget(minion) and LocalCore:IsInRange(mePos, minion.pos, mr) and self:GetMinionType(minion) == LocalCore.MINION_TYPE_LANE_MINION then
				TableInsert(result, minion)
			end
		end
		return result
	end

	function __ObjectManager:GetEnemyMinionsInAutoAttackRange()
		local result = {}
		for i = 1, GameMinionCount() do
			local minion = GameMinion(i)
			if LocalCore:IsValidTarget(minion) and minion.team == LocalCore.TEAM_ENEMY and self:GetMinionType(minion) == LocalCore.MINION_TYPE_LANE_MINION then
				if LocalCore:IsInAutoAttackRange(myHero, minion) then
					TableInsert(result, minion)
				end
			end
		end
		return result
	end

	function __ObjectManager:GetOtherMinions(range)
		local result = {}
		range = range or MathHuge;
		local mePos = myHero.pos
		for i = 1, GameWardCount() do
			local minion = GameWard(i)
			if LocalCore:IsValidTarget(minion) and self:GetMinionType(minion) == LocalCore.MINION_TYPE_OTHER_MINION then
				if LocalCore:IsInRange(mePos, minion.pos, range) then
					TableInsert(result, minion)
				end
			end
		end
		return result
	end

	function __ObjectManager:GetOtherAllyMinions(range)
		local result = {}
		range = range or MathHuge;
		local mePos = myHero.pos
		for i = 1, GameWardCount() do
			local minion = GameWard(i)
			if LocalCore:IsValidTarget(minion) and minion.team == LocalCore.TEAM_ALLY and self:GetMinionType(minion) == LocalCore.MINION_TYPE_OTHER_MINION then
				if LocalCore:IsInRange(mePos, minion.pos, range) then
					TableInsert(result, minion)
				end
			end
		end
		return result
	end

	function __ObjectManager:GetOtherEnemyMinions(range)
		local result = {}
		range = range or MathHuge;
		local mePos = myHero.pos
		for i = 1, GameWardCount() do
			local minion = GameWard(i)
			if LocalCore:IsValidTarget(minion) and minion.team == LocalCore.TEAM_ENEMY and self:GetMinionType(minion) == LocalCore.MINION_TYPE_OTHER_MINION then
				if LocalCore:IsInRange(mePos, minion.pos, range) then
					TableInsert(result, minion)
				end
			end
		end
		return result
	end

	function __ObjectManager:GetOtherEnemyMinionsInAutoAttackRange()
		local result = {}
		for i = 1, GameWardCount() do
			local minion = GameWard(i)
			if LocalCore:IsValidTarget(minion) and minion.team == LocalCore.TEAM_ENEMY and self:GetMinionType(minion) == LocalCore.MINION_TYPE_OTHER_MINION then
				if LocalCore:IsInAutoAttackRange(myHero, minion) then
					TableInsert(result, minion)
				end
			end
		end
		return result
	end

	function __ObjectManager:GetMonsters(range)
		local result = {}
		range = range or MathHuge;
		local mePos = myHero.pos
		for i = 1, GameMinionCount() do
			local minion = GameMinion(i)
			if LocalCore:IsValidTarget(minion) and self:GetMinionType(minion) == LocalCore.MINION_TYPE_MONSTER then
				if LocalCore:IsInRange(mePos, minion.pos, range) then
					TableInsert(result, minion)
				end
			end
		end
		return result
	end

	function __ObjectManager:GetMonstersInAutoAttackRange()
		local result = {}
		for i = 1, GameMinionCount() do
			local minion = GameMinion(i)
			if LocalCore:IsValidTarget(minion) and self:GetMinionType(minion) == LocalCore.MINION_TYPE_MONSTER then
				if LocalCore:IsInAutoAttackRange(myHero, minion) then
					TableInsert(result, minion)
				end
			end
		end
		return result
	end

	function __ObjectManager:GetHeroes(range)
		local result = {}
		range = range or MathHuge;
		local mePos = myHero.pos
		for i = 1, GameHeroCount() do
			local hero = GameHero(i)
			if LocalCore:IsValidTarget(hero) then
				if LocalCore:IsInRange(mePos, hero.pos, range) then
					TableInsert(result, hero)
				end
			end
		end
		return result
	end

	function __ObjectManager:GetAllyHeroes(range)
		local result = {}
		range = range or MathHuge;
		local mePos = myHero.pos
		for i = 1, GameHeroCount() do
			local hero = GameHero(i)
			if LocalCore:IsValidTarget(hero) and hero.team == LocalCore.TEAM_ALLY and LocalCore:IsInRange(mePos, hero.pos, range) then
				TableInsert(result, hero)
			end
		end
		return result
	end

	function __ObjectManager:GetEnemyHeroes(range, bb, state)
		local result = {}
		state = state or 0
		range = range or MathHuge;
		--state "spell" = 0
		--state "attack" = 1
		--state "immortal" = 2
		local mePos = myHero.pos
		for i = 1, GameHeroCount() do
			local hero = GameHero(i)
			local r = range; if bb then r = r + hero.boundingRadius; end
			if hero and hero.team == LocalCore.TEAM_ENEMY and LocalCore:IsValidTarget(hero) and LocalCore:IsInRange(mePos, hero.pos, r) then
				local immortal = false
				if state == 0 then
					immortal = self:IsHeroImmortal(hero, false)
				elseif state == 1 then
					immortal = self:IsHeroImmortal(hero, true)
				end
				if not immortal then
					TableInsert(result, hero)
				end
			end
		end
		return result
	end

	function __ObjectManager:GetEnemyHeroesInAutoAttackRange()
		local result = {}
		for i = 1, GameHeroCount() do
			local hero = GameHero(i)
			if LocalCore:IsValidTarget(hero) and hero.team == LocalCore.TEAM_ENEMY then
				if LocalCore:IsInAutoAttackRange(myHero, hero) then
					TableInsert(result, hero)
				end
			end
		end
		return result
	end

	function __ObjectManager:GetTurrets(range)
		return LocalCore:Join(self:GetAllyTurrets(range), self:GetEnemyTurrets(range))
	end

	function __ObjectManager:GetAllyTurrets(range)
		local result = {}
		range = range or MathHuge;
		local turrets = LocalCore:GetAllyTurrets()
		local mePos = myHero.pos
		for i = 1, #turrets do
			local turret = turrets[i]
			if LocalCore:IsValidTarget(turret) and LocalCore:IsInRange(mePos, turret.pos, range) then
				TableInsert(result, turret)
			end
		end
		return result
	end

	function __ObjectManager:GetEnemyTurrets(range)
		local result = {}
		range = range or MathHuge;
		local turrets = LocalCore:GetEnemyTurrets()
		local mePos = myHero.pos
		for i = 1, #turrets do
			local turret = turrets[i]
			if LocalCore:IsValidTarget(turret) and LocalCore:IsInRange(mePos, turret.pos, range) then
				TableInsert(result, turret)
			end
		end
		return result
	end

	ObjectManager = __ObjectManager()
end

do
	local __Orbwalker = LocalCore:Class()

	function __Orbwalker:__init()																																	
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
			[LocalCore.ORBWALKER_MODE_COMBO] = {},
			[LocalCore.ORBWALKER_MODE_HARASS] = {},
			[LocalCore.ORBWALKER_MODE_LANECLEAR] = {},
			[LocalCore.ORBWALKER_MODE_JUNGLECLEAR] = {},
			[LocalCore.ORBWALKER_MODE_LASTHIT] = {},
			[LocalCore.ORBWALKER_MODE_FLEE] = {}
		}
		self.Modes =
		{
			[LocalCore.ORBWALKER_MODE_COMBO] = false,
			[LocalCore.ORBWALKER_MODE_HARASS] = false,
			[LocalCore.ORBWALKER_MODE_LANECLEAR] = false,
			[LocalCore.ORBWALKER_MODE_JUNGLECLEAR] = false,
			[LocalCore.ORBWALKER_MODE_LASTHIT] = false,
			[LocalCore.ORBWALKER_MODE_FLEE] = false
		}
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
		-- IsCastingSpell
		self.IsCastingSpell = false
		-- Thresh
		self.ThreshLastDash = 0
		-- Attack
		self.ResetAttack = false
		self.AttackServerStart = 0
		self.AttackCastEndTime = 1
		self.AttackLocalStart = 0
		self.LastPostAttack = 0
		-- Move
		self.LastMoveLocal = 0
		self.LastMoveTime = 0
		self.LastMovePos = myHero.pos
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
		Menu:MenuElement({name = "Orbwalker", id = "orb", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Icons/orb.png" })
			Menu.orb:MenuElement({name = "Keys", id = "keys", type = _G.MENU})
				Menu.orb.keys:MenuElement({name = "Combo Key", id = "combo", key = string.byte(" ")})
					self:RegisterMenuKey(LocalCore.ORBWALKER_MODE_COMBO, Menu.orb.keys.combo)
				Menu.orb.keys:MenuElement({name = "Harass Key", id = "harass", key = string.byte("C")})
					self:RegisterMenuKey(LocalCore.ORBWALKER_MODE_HARASS, Menu.orb.keys.harass)
				Menu.orb.keys:MenuElement({name = "LastHit Key", id = "lasthit", key = string.byte("X")})
					self:RegisterMenuKey(LocalCore.ORBWALKER_MODE_LASTHIT, Menu.orb.keys.lasthit)
				Menu.orb.keys:MenuElement({name = "LaneClear Key", id = "laneclear", key = string.byte("V")})
					self:RegisterMenuKey(LocalCore.ORBWALKER_MODE_LANECLEAR, Menu.orb.keys.laneclear)
				Menu.orb.keys:MenuElement({name = "Jungle Key", id = "jungle", key = string.byte("V")})
					self:RegisterMenuKey(LocalCore.ORBWALKER_MODE_JUNGLECLEAR, Menu.orb.keys.jungle)
				Menu.orb.keys:MenuElement({name = "Flee Key", id = "flee", key = string.byte("A")})
					self:RegisterMenuKey(LocalCore.ORBWALKER_MODE_FLEE, Menu.orb.keys.flee)
			Menu.orb:MenuElement({ name = "LaneClear", id = "lclear", type = _G.MENU })
				Menu.orb.lclear:MenuElement({name = "Attack Heroes", id = "laneset", value = true })
				Menu.orb.lclear:MenuElement({name = "Extra Farm Delay", id = "farmdelay", value = 50, min = 0, max = 100, step = 1 })
				Menu.orb.lclear:MenuElement({name = "Should Wait Time", id = "swait", value = 500, min = 0, max = 1000, step = 100 })
			Menu.orb:MenuElement({ name = "Humanizer", id = "humanizer", type = _G.MENU })
				Menu.orb.humanizer:MenuElement({ name = "Random", id = "random", type = _G.MENU })
					Menu.orb.humanizer.random:MenuElement({name = "Enabled", id = "enabled", value = true })
					Menu.orb.humanizer.random:MenuElement({name = "From", id = "from", value = 150, min = 60, max = 300, step = 20 })
					Menu.orb.humanizer.random:MenuElement({name = "To", id = "to", value = 220, min = 60, max = 400, step = 20 })
				Menu.orb.humanizer:MenuElement({name = "Humanizer", id = "standard", value = 200, min = 60, max = 300, step = 10 })
					self.Menu.General.MovementDelay = Menu.orb.humanizer.standard
			Menu.orb:MenuElement({ name = "Extra Windup", id = "extrawindup", value = 0, min = 0, max = 30, step = 1 })
			Menu.orb:MenuElement({ name = "Extra Cursor Delay", id = "excdelay", value = 25, min = 0, max = 75, step = 1 })
			if Menu.orb.excdelay:Value() > 75 then Menu.orb.excdelay:Value(25) end
			Menu.orb:MenuElement({name = "Player Attack Only Click", id = "aamoveclick", key = string.byte("U")})
			Menu.orb:MenuElement({ name = "Hold Radius", id = "hold", type = _G.MENU })
				Menu.orb.hold:MenuElement({ id = "HoldRadius", name = "Hold Radius", value = 120, min = 100, max = 250, step = 10 })
					self.Menu.General.HoldRadius = Menu.orb.hold.HoldRadius
				Menu.orb.hold:MenuElement({ id = "HoldPosButton", name = "Hold position button", key = string.byte("H"), tooltip = "Should be same in game keybinds", onKeyChange = function(kb) HoldPositionButton = kb; end });
					HoldPositionButton = Menu.orb.hold.HoldPosButton:Key()
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
		TableInsert(self.OnPreAttackC, func)
	end

	function __Orbwalker:OnPostAttack(func)
		TableInsert(self.OnPostAttackC, func)
	end

	function __Orbwalker:OnPostAttackTick(func)
		TableInsert(self.OnPostAttackTickC, func)
	end

	function __Orbwalker:OnAttack(func)
		TableInsert(self.OnAttackC, func)
	end

	function __Orbwalker:OnPreMovement(func)
		TableInsert(self.OnPreMoveC, func)
	end

	function __Orbwalker:IsBeforeAttack(multipier)
		if GameTimer() > self.AttackLocalStart + multipier * myHero.attackData.animationTime then
			return true
		else
			return false
		end
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
		Cursor:SetCursor(_G.cursorPos, unit, attackKey, function()
			ControlKeyDown(attackKey)
			ControlKeyUp(attackKey)
		end)
		self.LastMoveLocal = 0
		self.AttackLocalStart = GameTimer()
		LAST_KEYPRESS = OsClock() + 0.07
	end

	function __Orbwalker:Move()
		if ControlIsKeyDown(2) then self.LastMouseDown = GameTimer() end
		self.LastMovePos = _G.mousePos
		ControlMouseEvent(MOUSEEVENTF_RIGHTDOWN)
		ControlMouseEvent(MOUSEEVENTF_RIGHTUP)
		LAST_MOUSECLICK = OsClock() + 0.05
		self.LastMoveLocal = GameTimer() + GetHumanizer()
		self.LastMoveTime = GameTimer()
	end

	function __Orbwalker:MoveToPos(pos)
		if ControlIsKeyDown(2) then self.LastMouseDown = GameTimer() end
		Cursor:SetCursor(_G.cursorPos, pos, MOUSEEVENTF_RIGHTDOWN, function()
			ControlMouseEvent(MOUSEEVENTF_RIGHTDOWN)
			ControlMouseEvent(MOUSEEVENTF_RIGHTUP)
		end)
		LAST_MOUSECLICK = OsClock() + 0.05
		self.LastMoveLocal = GameTimer() + GetHumanizer()
		self.LastMoveTime = GameTimer()
	end

	function __Orbwalker:CanAttackLocal()
		if not self.CanAttackC() then return false end
		if self.IsBlindedByTeemo then
			return false
		end
		--if self.IsCastingSpell then return false end
		if ExtLibEvade and ExtLibEvade.Evading then
			return false
		end
		if _G.JustEvade then
			return false
		end
		if LocalCore:IsChanneling(myHero) then
			return false
		end
		if LocalCore.DisableAutoAttack[myHero.charName] ~= nil and LocalCore.DisableAutoAttack[myHero.charName](myHero) then
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
		if self.AttackCastEndTime > self.AttackLocalStart then
			if self.ResetAttack or GameTimer() >= self.AttackServerStart + GetAnimation() - 0.05 - LATENCY then
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
		if self.AttackCastEndTime > self.AttackLocalStart then
			local extraWindUp = Menu.orb.extrawindup:Value() * 0.001; extraWindUp = extraWindUp - LATENCY
			if GameTimer() >= self.AttackServerStart + GetWindup() + extraWindUp + 0.025 then
				return true
			end
			return false
		end
		if GameTimer() < self.AttackLocalStart + 0.2 then
			return false
		end
		return true
	end

	function __Orbwalker:CanMoveLocal()
		if not self.CanMoveC() then return false end
		if ExtLibEvade and ExtLibEvade.Evading then
			return false
		end
		if _G.JustEvade then
			return false
		end
		if myHero.charName == "Kalista" then
			return true
		end
		if not myHero.pathing.hasMovePath then
			self.LastMoveLocal = 0
		end
		if LocalCore:IsChanneling(myHero) then
			if LocalCore.AllowMovement[myHero.charName] == nil or (not LocalCore.AllowMovement[myHero.charName](myHero)) then
				return false
			end
		end
		if self.ChampionCanMove[myHero.charName] ~= nil and not self.ChampionCanMove[myHero.charName]() then
			return false
		end
		if self.AttackCastEndTime > self.AttackLocalStart then
			local extraWindUp = Menu.orb.extrawindup:Value() * 0.001; extraWindUp = extraWindUp - LATENCY
			if GameTimer() >= self.AttackServerStart + GetWindup() + extraWindUp + 0.015 then
				return true
			end
			return false
		end
		if GameTimer() < self.AttackLocalStart + 0.2 or GameTimer() < CASTSPELL_CANMOVE + 0.2 then
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
		elseif self.MovementEnabled and self:CanMoveLocal() then
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
		if wParam == Menu.orb.aamoveclick:Key() then
			self.AttackLocalStart = GameTimer()
		end
	end

	function __Orbwalker:GetTarget()
		local result = nil
		if LocalCore:IsValidTarget(self.ForceTarget) then
			result = self.ForceTarget
		elseif self.Modes[LocalCore.ORBWALKER_MODE_COMBO] then
			result = TargetSelector:GetComboTarget()
		elseif self.Modes[LocalCore.ORBWALKER_MODE_HARASS] then
			if HealthPrediction.IsLastHitable then
				result = HealthPrediction:GetLastHitTarget()
			else
				result = TargetSelector:GetComboTarget()
			end
		elseif self.Modes[LocalCore.ORBWALKER_MODE_LASTHIT] then
			result = HealthPrediction:GetLastHitTarget()
		elseif self.Modes[LocalCore.ORBWALKER_MODE_LANECLEAR] then
			if HealthPrediction.IsLastHitable then
				result = HealthPrediction:GetLastHitTarget()
			elseif GameTimer() > HealthPrediction.ShouldWaitTime + Menu.orb.lclear.swait:Value() * 0.001 then
				result = HealthPrediction:GetLaneClearTarget()
			end
			if result == nil and self.Modes[LocalCore.ORBWALKER_MODE_JUNGLECLEAR] then
				result = HealthPrediction:GetJungleTarget()
			end
		elseif self.Modes[LocalCore.ORBWALKER_MODE_JUNGLECLEAR] then
			result = HealthPrediction:GetJungleTarget()
		elseif self.Modes[LocalCore.ORBWALKER_MODE_FLEE] then
			result = nil
		end
		return result
	end

	function __Orbwalker:Orbwalk()
		self.IsNone = self:HasMode(LocalCore.ORBWALKER_MODE_NONE)
		self.Modes = self:GetModes()
		if self.IsNone then
			if GameTimer() < self.LastMouseDown + 1 and OsClock() > LAST_MOUSECLICK then
				ControlMouseEvent(MOUSEEVENTF_RIGHTDOWN)
				LAST_MOUSECLICK = OsClock() + 0.05
				self.LastMouseDown = 0
			end
			return
		end
		if GameIsChatOpen() or (ExtLibEvade and ExtLibEvade.Evading) or _G.JustEvade or not Cursor.IsReady or (not GameIsOnTop()) then
			return
		end
		if LocalCore:IsValidTarget(self.ForceTarget) then
			self:AttackMove(self.ForceTarget)
		elseif self.Modes[LocalCore.ORBWALKER_MODE_COMBO] then
			self:AttackMove(TargetSelector:GetComboTarget())
		elseif self.Modes[LocalCore.ORBWALKER_MODE_HARASS] then
			if HealthPrediction.IsLastHitable then
				self:AttackMove(HealthPrediction:GetLastHitTarget(), true)
			else
				self:AttackMove(TargetSelector:GetComboTarget())
			end
		elseif self.Modes[LocalCore.ORBWALKER_MODE_LASTHIT] then
			self:AttackMove(HealthPrediction:GetLastHitTarget())
		elseif self.Modes[LocalCore.ORBWALKER_MODE_LANECLEAR] then
			if HealthPrediction.IsLastHitable then
				local result = HealthPrediction:GetLastHitTarget()
				if result ~= nil then
					self:AttackMove(result, true)
				elseif self.Modes[LocalCore.ORBWALKER_MODE_JUNGLECLEAR] then
					self:AttackMove(HealthPrediction:GetJungleTarget())
				end
			elseif GameTimer() > HealthPrediction.ShouldWaitTime + Menu.orb.lclear.swait:Value() * 0.001 then
				local result = HealthPrediction:GetLaneClearTarget()
				if result ~= nil then
					self:AttackMove(result, false, true)
				elseif self.Modes[LocalCore.ORBWALKER_MODE_JUNGLECLEAR] then
					self:AttackMove(HealthPrediction:GetJungleTarget())
				end
			elseif self.Modes[LocalCore.ORBWALKER_MODE_JUNGLECLEAR] then
				self:AttackMove(HealthPrediction:GetJungleTarget())
			else
				self:AttackMove()
			end
		elseif self.Modes[LocalCore.ORBWALKER_MODE_JUNGLECLEAR] then
			self:AttackMove(HealthPrediction:GetJungleTarget())
		elseif self.Modes[LocalCore.ORBWALKER_MODE_FLEE] then
			if self.MovementEnabled and GameTimer() > self.LastMoveLocal and self:CanMoveLocal() then
				self:AttackMove()
			end
		end
	end

	function __Orbwalker:Tick()
		if AttackSpeedData.windup ~= myHero.attackData.windUpTime then
			AttackSpeedData.tickwindup = OsClock() + 1
			AttackSpeedData.windup = myHero.attackData.windUpTime
		end
		if AttackSpeedData.anim ~= myHero.attackData.animationTime then
			AttackSpeedData.tickanim = OsClock() + 1
			AttackSpeedData.anim = myHero.attackData.animationTime
		end
		local spellCastEndTime = 0
		local spell = myHero.activeSpell
		if spell and spell.valid then
			if not LocalCore.NoAutoAttacks[spell.name] and (not myHero.isChanneling or LocalCore.SpecialAutoAttacks[spell.name]) then
				if spell.castEndTime > self.AttackCastEndTime then
					for i = 1, #self.OnAttackC do
						self.OnAttackC[i]()
					end
					self.AttackCastEndTime = spell.castEndTime
					self.AttackServerStart = spell.startTime
					ATTACK_WINDUP = spell.windup
					ATTACK_ANIMATION = spell.animation
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
			else
				spellCastEndTime = spell.castEndTime - _G.LATENCY - 0.04
			end
		end
		if GameTimer() <= spellCastEndTime then
			self.IsCastingSpell = true
		else
			self.IsCastingSpell = false
		end
		self:Orbwalk()
	end

	function __Orbwalker:RegisterMenuKey(mode, key)
		TableInsert(self.MenuKeys[mode], key);
	end

	function __Orbwalker:HasMode(mode)
		if mode == LocalCore.ORBWALKER_MODE_NONE then
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
			[LocalCore.ORBWALKER_MODE_COMBO] 			= self:HasMode(LocalCore.ORBWALKER_MODE_COMBO),
			[LocalCore.ORBWALKER_MODE_HARASS] 		= self:HasMode(LocalCore.ORBWALKER_MODE_HARASS),
			[LocalCore.ORBWALKER_MODE_LANECLEAR] 		= self:HasMode(LocalCore.ORBWALKER_MODE_LANECLEAR),
			[LocalCore.ORBWALKER_MODE_JUNGLECLEAR] 	= self:HasMode(LocalCore.ORBWALKER_MODE_JUNGLECLEAR),
			[LocalCore.ORBWALKER_MODE_LASTHIT] 		= self:HasMode(LocalCore.ORBWALKER_MODE_LASTHIT),
			[LocalCore.ORBWALKER_MODE_FLEE] 			= self:HasMode(LocalCore.ORBWALKER_MODE_FLEE)
		}
	end

	function __Orbwalker:OnUnkillableMinion(cb)
		TableInsert(HealthPrediction.OnUnkillableC, cb)
	end

	function __Orbwalker:SetMovement(boolean)
		self.MovementEnabled = boolean
	end

	function __Orbwalker:SetAttack(boolean)
		self.AttackEnabled = boolean
	end

	function __Orbwalker:ShouldWait()
		return GameTimer() <= HealthPrediction.ShouldWaitTime + Menu.orb.lclear.swait:Value() * 0.001
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
		if result and LocalCore:IsChanneling(unit) then
			if LocalCore.AllowMovement[unit.charName] == nil or (not LocalCore.AllowMovement[unit.charName](unit)) then
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
		if result and LocalCore:IsChanneling(unit) then
			result = false
		end
		if result and LocalCore.DisableAutoAttack[unit.charName] ~= nil and LocalCore.DisableAutoAttack[unit.charName](unit) then
			result = false
		end
		return result
	end

	function __Orbwalker:__OnAutoAttackReset()
		self.ResetAttack = true
	end

	Orbwalker = __Orbwalker()
end

do
	local __HealthPrediction = LocalCore:Class()

	function __HealthPrediction:__init()
		self.OnUnkillableC = {}
		self.CachedTeamEnemy = {}
		self.CachedTeamAlly = {}
		self.CachedTeamJungle = {}
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
		local targets = LocalCore:Join(ObjectManager:GetMonstersInAutoAttackRange(), ObjectManager:GetOtherEnemyMinionsInAutoAttackRange())
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
			if LocalCore:IsValidTarget(minion.Minion) and minion.LastHitable and minion.PredictedHP < min and LocalCore:IsValidTarget(minion.Minion) and LocalCore:IsInAutoAttackRange(myHero, minion.Minion) then
				min = minion.PredictedHP
				result = minion.Minion
			end
		end
		return result
	end

	function __HealthPrediction:GetLaneClearTarget()
		local enemyTurrets = ObjectManager:GetEnemyBuildings(myHero.range+myHero.boundingRadius - 35, true)
		if #enemyTurrets >= 1 then return enemyTurrets[1] end
		if Menu.orb.lclear.laneset:Value() then
			local result = TargetSelector:GetComboTarget()
			if result then return result end
		end
		local result = nil
		if GameTimer() > self.ShouldWaitTime + Menu.orb.lclear.swait:Value() * 0.001 then
			local min = 10000000
			for i = 1, #self.FarmMinions do
				local target = self.FarmMinions[i]
				if LocalCore:IsValidTarget(target.Minion) and target.PredictedHP < min and LocalCore:IsInAutoAttackRange(myHero, target.Minion) then
					min = target.PredictedHP
					result = target.Minion
				end
			end
		end
		return result
	end

	function __HealthPrediction:SetObjects()
		for i = 1, GameMinionCount() do
			local obj = GameMinion(i)
			if obj and LocalCore:IsInRange(myHero.pos, obj.pos, 2000) and LocalCore:IsValidTarget(obj) then
				local team = obj.team
				if team == LocalCore.TEAM_ALLY then
					TableInsert(self.CachedTeamAlly, obj)
				elseif team == LocalCore.TEAM_ENEMY then
					TableInsert(self.CachedTeamEnemy, obj)
				elseif team == LocalCore.TEAM_JUNGLE then
					TableInsert(self.CachedTeamJungle, obj)
				end
			end
		end
		for i = 1, GameHeroCount() do
			local obj = GameHero(i)
			if obj and not obj.isMe and LocalCore:IsInRange(myHero.pos, obj.pos, 2000) and LocalCore:IsValidTarget(obj) then
				local team = obj.team
				if team == LocalCore.TEAM_ALLY then
					TableInsert(self.CachedTeamAlly, obj)
				elseif team == LocalCore.TEAM_ENEMY then
					TableInsert(self.CachedTeamEnemy, obj)
				elseif team == LocalCore.TEAM_JUNGLE then
					TableInsert(self.CachedTeamJungle, obj)
				end
			end
		end
		local turrets = LocalCore:Join(LocalCore:GetEnemyTurrets(), LocalCore:GetAllyTurrets())
		for i = 1, #turrets do
			local obj = turrets[i]
			if obj and LocalCore:IsInRange(myHero.pos, obj.pos, 2000) and LocalCore:IsValidTarget(obj) then
				local team = obj.team
				if team == LocalCore.TEAM_ALLY then
					TableInsert(self.CachedTeamAlly, obj)
				elseif team == LocalCore.TEAM_ENEMY then
					TableInsert(self.CachedTeamEnemy, obj)
				elseif team == LocalCore.TEAM_JUNGLE then
					TableInsert(self.CachedTeamJungle, obj)
				end
			end
		end
	end

	function __HealthPrediction:GetObjects(team)
		if team == LocalCore.TEAM_ALLY then
			return LocalCore:Join(self.CachedTeamEnemy, self.CachedTeamJungle)
		elseif team == LocalCore.TEAM_ENEMY then
			return LocalCore:Join(self.CachedTeamAlly, self.CachedTeamJungle)
		elseif team == LocalCore.TEAM_JUNGLE then
			return LocalCore:Join(self.CachedTeamEnemy, self.CachedTeamAlly)
		end
	end

	function __HealthPrediction:GetPrediction(target, time)
		local pos = target.pos
		local handle = target.handle
		local attackers = self:GetObjects(target.team)
		local hp = LocalCore:TotalShieldHealth(target)
		for i = 1, #attackers do
			local attacker = attackers[i]
			if LocalCore:IsValidTarget(attacker) and attacker.attackData.target == handle and LocalCore:IsInAutoAttackRange(attacker, target, 100) then
				local isTurret = attacker.type == Obj_AI_Turret
				if isTurret and self.CanCheckTurret then self.TurretHasTarget = true end
				local flyTime
				local projSpeed = attacker.attackData.projectileSpeed
				if isTurret then projSpeed = 700 end
				if projSpeed and projSpeed > 0 then
					flyTime = LocalCore:GetDistance(attacker.pos, pos) / projSpeed
				else
					flyTime = 0
				end
				local endTime = (attacker.attackData.endTime - attacker.attackData.animationTime) + flyTime + attacker.attackData.windUpTime
				if endTime <= GameTimer() then
					endTime = endTime + attacker.attackData.animationTime + flyTime
				end
				local dmg = Damage:GetAutoAttackDamage(attacker, target)
				while endTime - GameTimer() < time do
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
			almostLastHitable = self:GetPrediction(target, GetAnimation() * 2 + time * 2) - damage < 0
		end
		if almostLastHitable then
			self.ShouldWaitTime = GameTimer()
		end
		return { LastHitable =  lastHitable, Unkillable = hpPred < 0, AlmostLastHitable = almostLastHitable, PredictedHP = hpPred, Minion = target }
	end

	function __HealthPrediction:Tick()
		self.FarmMinions = {}
		self.CachedTeamEnemy = {}
		self.CachedTeamAlly = {}
		self.CachedTeamJungle = {}
		self.TurretHasTarget = false
		self.CanCheckTurret = true
		self.IsLastHitable = false
		if Orbwalker.Modes[LocalCore.ORBWALKER_MODE_COMBO] or Orbwalker:HasMode(LocalCore.ORBWALKER_MODE_NONE) then
			self.CanCheckTurret = false
			return
		end
		-- cached objects
		self:SetObjects()
		local targets = ObjectManager:GetEnemyMinions(myHero.range + myHero.boundingRadius, true)
		local projectileSpeed = GetProjSpeed()
		local winduptime = GetWindup()
		local extraFarmDelay = Menu.orb.lclear.farmdelay:Value() * 0.001
		local time = winduptime - LATENCY - extraFarmDelay
		local pos = myHero.pos
		for i = 1, #targets do
			local target = targets[i]
			local FlyTime = LocalCore:GetDistance(pos, target.pos) / projectileSpeed
			TableInsert(self.FarmMinions, self:SetLastHitable(target, time + FlyTime, Damage:GetAutoAttackDamage(myHero, target)))
		end
		self.CanCheckTurret = false
	end

	function __HealthPrediction:Draw()
		if Orbwalker.Modes[LocalCore.ORBWALKER_MODE_COMBO] then return end
		if Menu.gsodraw.lasthit.enabled:Value() or Menu.gsodraw.almostlasthit.enabled:Value() then
			local tm = self.FarmMinions
			for i = 1, #tm do
				local minion = tm[i]
				if LocalCore:IsValidTarget(minion.Minion) then
					if minion.LastHitable and Menu.gsodraw.lasthit.enabled:Value() then
						DrawCircle(minion.Minion.pos,Menu.gsodraw.lasthit.radius:Value(),Menu.gsodraw.lasthit.width:Value(),Menu.gsodraw.lasthit.color:Value())
					elseif minion.AlmostLastHitable and Menu.gsodraw.almostlasthit.enabled:Value() then
						DrawCircle(minion.Minion.pos,Menu.gsodraw.almostlasthit.radius:Value(),Menu.gsodraw.almostlasthit.width:Value(),Menu.gsodraw.almostlasthit.color:Value())
					end
				end
			end
		end
	end

	HealthPrediction = __HealthPrediction()
end

do
	local __Damage = LocalCore:Class()

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
		if damageType == LocalCore.DAMAGE_TYPE_PHYSICAL then
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
				penetrationPercent = (LocalCore.BaseTurrets[from.charName] == nil) and 0.3 or 0.75;
				penetrationFlat = 0;
				bonusPenetrationPercent = 0;
			end
		elseif damageType == LocalCore.DAMAGE_TYPE_MAGICAL then
			baseResistance = MathMax(target.magicResist - target.bonusMagicResist, 0);
			bonusResistance = target.bonusMagicResist;
			penetrationFlat = from.magicPen;
			penetrationPercent = from.magicPenPercent;
			bonusPenetrationPercent = 0;
		elseif damageType == LocalCore.DAMAGE_TYPE_TRUE then
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
			DamageType = LocalCore.DAMAGE_TYPE_PHYSICAL,
			TargetIsMinion = targetIsMinion
		}
		if LocalCore.StaticChampionDamageDatabase[args.From.charName] ~= nil then
			LocalCore.StaticChampionDamageDatabase[args.From.charName](args)
		end
		local HashSet = {}
		for i = 1, #LocalCore.ItemSlots do
			local slot = LocalCore.ItemSlots[i]
			local item = args.From:GetItemData(slot)
			if item ~= nil and item.itemID > 0 then
				if HashSet[item.itemID] == nil then
					if LocalCore.StaticItemDamageDatabase[item.itemID] ~= nil then
						LocalCore.StaticItemDamageDatabase[item.itemID](args)
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
		if LocalCore.VariableChampionDamageDatabase[args.From.charName] ~= nil then
			LocalCore.VariableChampionDamageDatabase[args.From.charName](args);
		end
		if args.DamageType == LocalCore.DAMAGE_TYPE_PHYSICAL then
			args.RawPhysical = args.RawPhysical + args.RawTotal;
		elseif args.DamageType == LocalCore.DAMAGE_TYPE_MAGICAL then
			args.RawMagical = args.RawMagical + args.RawTotal;
		elseif args.DamageType == LocalCore.DAMAGE_TYPE_TRUE then
			args.CalculatedTrue = args.CalculatedTrue + args.RawTotal;
		end
		if args.RawPhysical > 0 then
			args.CalculatedPhysical = args.CalculatedPhysical + self:CalculateDamage(from, target, LocalCore.DAMAGE_TYPE_PHYSICAL, args.RawPhysical, false, args.DamageType == LocalCore.DAMAGE_TYPE_PHYSICAL);
		end
		if args.RawMagical > 0 then
			args.CalculatedMagical = args.CalculatedMagical + self:CalculateDamage(from, target, LocalCore.DAMAGE_TYPE_MAGICAL, args.RawMagical, false, args.DamageType == LocalCore.DAMAGE_TYPE_MAGICAL);
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
			if from.type == Obj_AI_Turret and LocalCore.BaseTurrets[from.charName] == nil then
				local percentMod = LocalCore.TurretToMinionPercentMod[target.charName]
				if percentMod ~= nil then
					return target.maxHealth * percentMod;
				end
			end
		end
		return self:CalculateDamage(from, target, LocalCore.DAMAGE_TYPE_PHYSICAL, from.totalDamage, false, true);
	end

	function __Damage:GetCriticalStrikePercent(from)
		local baseCriticalDamage = 2
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

_G.Control.Attack = function(target)
	if Cursor.IsReady and _G.GAMSTERON_CONTROLL == nil and OsClock() > CASTSPELL_TICK and OsClock() > LAST_KEYPRESS then
		_G.GAMSTERON_CONTROLL = true
		Orbwalker:Attack(target)
		return true
	end
	return false
end

_G.Control.Move = function(a, b, c)
	if _G.GAMSTERON_CONTROLL == nil and OsClock() > LAST_KEYPRESS and OsClock() > LAST_MOUSECLICK then
		local position
		if a and b and c then
			position = Vector(a, b, c)
		elseif a and b then
			position = Vector({ x = a, y = b})
		elseif a then
			if a.pos then
				position = a.pos
			else
				position = Vector(a)
			end
		end
		_G.GAMSTERON_CONTROLL = true
		if position then
			if Cursor.IsReady then
				Orbwalker:MoveToPos(position)
			else
				_G.GAMSTERON_CONTROLL = nil
				return false
			end
		else
			Orbwalker:Move()
			_G.GAMSTERON_CONTROLL = nil
		end
		return true
	end
	return false
end

_G.Control.CastSpell = function(key, a, b, c)
	if a and GameTimer() < Orbwalker.AttackLocalStart + 0.2 and myHero.attackSpeed < 2 and Orbwalker.AttackCastEndTime < GameTimer() then
		self.AttackEnabled = false
		DelayAction(function() self.AttackEnabled = true end, 0.1)
		Orbwalker.AttackLocalStart = 0
		Cursor:LastStep()
	end
	if _G.GAMSTERON_CONTROLL == nil and OsClock() > CASTSPELL_TICK and OsClock() > LAST_KEYPRESS then
		local position
		local isTarget = false
		if a and b and c then
			position = Vector(a, b, c)
		elseif a and b then
			position = { x = a, y = b}
		elseif a then
			if a.pos then
				isTarget = true
				position = a
			else
				position = Vector(a)
			end
		end
		if key == HK_Q then
			if GameTimer() < Spells.LastQ + 0.15 then return false end
			Spells.LastQ = GameTimer()
		elseif key == HK_W then
			if GameTimer() < Spells.LastW + 0.15 then return false end
			Spells.LastW = GameTimer()
		elseif key == HK_E then
			if GameTimer() < Spells.LastE + 0.15 then return false end
			Spells.LastE = GameTimer()
		elseif key == HK_R then
			if GameTimer() < Spells.LastR + 0.15 then return false end
			Spells.LastR = GameTimer()
		end
		CASTSPELL_TICK = OsClock() + _G.LATENCY + 0.08
		_G.GAMSTERON_CONTROLL = true
		if position then
			if Cursor.IsReady then
				Cursor:SetCursor(_G.cursorPos, position, key, function()
					ControlKeyDown(key)
					ControlKeyUp(key)
				end)
				LAST_KEYPRESS = OsClock() + 0.07
				Orbwalker.LastMoveLocal = 0
			else
				_G.GAMSTERON_CONTROLL = nil
				return false
			end
		else
			ControlKeyDown(key)
			ControlKeyUp(key)
			LAST_KEYPRESS = OsClock() + 0.07
			_G.GAMSTERON_CONTROLL = nil
		end
		return true
	end
	return false
end

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
_G.SDK.Items = Items

Menu = MenuElement({name = "Gamsteron Orbwalker", id = "gamsteronOrb", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Icons/rsz_gsoorbwalker.png" })
TargetSelector:CreateMenu()
Orbwalker:CreateMenu()
Items:CreateMenu()

Menu:MenuElement({name = "Drawings", id = "gsodraw", leftIcon = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Icons/circles.png", type = _G.MENU })
Menu.gsodraw:MenuElement({name = "Enabled",  id = "enabled", value = true})
TargetSelector:CreateDrawMenu()
HealthPrediction:CreateDrawMenu()
Cursor:CreateDrawMenu()
Orbwalker:CreateDrawMenu()

Menu:MenuElement({name = "Version " .. tostring(GamsteronOrbVer), type = _G.SPACE, id = "verspace"})

LocalCore:OnEnemyHeroLoad(function(hero)
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

AddLoadCallback(function()
	Callback.Add('Draw', function()
		local hasTeemoBlind = false
		local hasLethal = false
		for i = 0, myHero.buffCount do
			local buff = myHero:GetBuff(i)
			if buff and buff.count > 0 then
				local name = buff.name:lower()
				if name == "blindingdart" then
					hasTeemoBlind = true
				elseif name:find("lethaltempoemp") then
					hasLethal = true
					LAST_LETHAL_TEMPO = GameTimer()
				end
			end
		end
		if hasLethal then
			HAS_LETHAL_TEMPO = true
		elseif GameTimer() > LAST_LETHAL_TEMPO + 1 then
			HAS_LETHAL_TEMPO = false
		end
		Orbwalker.IsBlindedByTeemo = hasTeemoBlind
	end)
	Callback.Add('Tick', function()
		if _G.Orbwalker.Enabled:Value() then _G.Orbwalker.Enabled:Value(false) end
		if _G.GamsteronDebug then
			local status, err = pcall(function () HealthPrediction:Tick() end); if not status then print("HealthPrediction:Tick: " .. tostring(err)) end
			status, err = pcall(function () Spells:DisableAutoAttack() end); if not status then print("Spells:DisableAutoAttack: " .. tostring(err)) end
			status, err = pcall(function () 
				if Spells.Work ~= nil then
					if GameTimer() < Spells.WorkEndTime then
						Spells.Work()
						return
					end
					Spells.Work = nil
				end
			end); if not status then print("Spells.Work: " .. tostring(err)) end
		else
			HealthPrediction:Tick()
			Spells:DisableAutoAttack()
			if Spells.Work ~= nil then
				if GameTimer() < Spells.WorkEndTime then
					Spells.Work()
					return
				end
				Spells.Work = nil
			end
		end
	end)

	Callback.Add('WndMsg', function(msg, wParam)
		if _G.GamsteronDebug then
			local status, err = pcall(function () TargetSelector:WndMsg(msg, wParam) end); if not status then print("TargetSelector:WndMsg: " .. tostring(err)) end
			--status, err = pcall(function () Orbwalker:WndMsg(msg, wParam) end); if not status then print("Orbwalker:WndMsg: " .. tostring(err)) end
			status, err = pcall(function () Spells:WndMsg(msg, wParam) end); if not status then print("Spells:WndMsg: " .. tostring(err)) end
			status, err = pcall(function () Cursor:WndMsg(msg, wParam) end); if not status then print("Cursor:WndMsg: " .. tostring(err)) end
		else
			TargetSelector:WndMsg(msg, wParam)
			--Orbwalker:WndMsg(msg, wParam)
			Spells:WndMsg(msg, wParam)
			Cursor:WndMsg(msg, wParam)
		end
	end)

	Callback.Add('Draw', function()
		if not Menu.gsodraw.enabled:Value() then return end
		if _G.GamsteronDebug then
			local status, err = pcall(function () TargetSelector:Draw() end); if not status then print("TargetSelector:Draw: " .. tostring(err)) end
			status, err = pcall(function () HealthPrediction:Draw() end); if not status then print("HealthPrediction:Draw " .. tostring(err)) end
			status, err = pcall(function () Cursor:Draw() end); if not status then print("Cursor:Draw " .. tostring(err)) end
			status, err = pcall(function () Orbwalker:Draw() end); if not status then print("Orbwalker:Draw " .. tostring(err)) end
		else
			TargetSelector:Draw()
			HealthPrediction:Draw()
			Cursor:Draw()
			Orbwalker:Draw()
		end
	end)

	Callback.Add('Draw', function()
		if _G.GamsteronDebug then
			local status, err = pcall(function () Orbwalker:Tick() end); if not status then print("Orbwalker:Tick " .. tostring(err)) end
			status, err = pcall(function () Cursor:Tick() end); if not status then print("Cursor:Tick: " .. tostring(err)) end
		else
			Orbwalker:Tick()
			Cursor:Tick()
		end
	end)
end)

_G.GamsteronOrbwalkerLoaded = true
