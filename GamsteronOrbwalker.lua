local GamsteronOrbVer = 0.04
local LocalCore, Menu, MenuChamp, Cursor, Spells, Damage, ObjectManager, TargetSelector, HealthPrediction, Orbwalker, HoldPositionButton

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

local MAXIMUM_MOUSE_DISTANCE		= 120 * 120
local GAMSTERON_MODE_DMG			= false
local CONTROLL						= nil
local NEXT_CONTROLL					= 0
local ME_CAITLYN					= myHero.charName == "Caitlyn"
local ME_KALISTA					= myHero.charName == "Kalista"

local GetTickCount					= GetTickCount
local myHero						= _G.myHero
local MeCharName					= myHero.charName
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
local MathHuge						= math.huge
local MathAbs						= math.abs
local TableInsert					= _G.table.insert
local TableRemove					= _G.table.remove

local function GetProjSpeed()
	if LocalCore.IsMelee[MeCharName] or (LocalCore.SpecialMelees[MeCharName] ~= nil and LocalCore.SpecialMelees[MeCharName]()) then
		return math.huge
	end
	if LocalCore.SpecialMissileSpeeds[MeCharName] ~= nil then
		local projectileSpeed = LocalCore.SpecialMissileSpeeds[MeCharName](myHero)
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
	if LocalCore.SpecialWindUpTimes[MeCharName] ~= nil then
		local SpecialWindUpTime = LocalCore.SpecialWindUpTimes[MeCharName](myHero)
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
		if self.Work ~= nil then--and LocalCore:GetDistanceSquared(newpos, _G.cursorPos) <= MAXIMUM_MOUSE_DISTANCE then
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
			if LocalCore:GetDistanceSquared(self.CursorPos, _G.cursorPos) <= MAXIMUM_MOUSE_DISTANCE then
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

	Cursor = __Cursor()
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
		if not Cursor.IsReady or CONTROLL ~= nil or currentTime <= NEXT_CONTROLL + 0.05 then
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
		local latency = LATENCY
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
			if self.IsLastHitable and not Orbwalker.IsNone and not Orbwalker.Modes[LocalCore.ORBWALKER_MODE_COMBO] then
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
			if Orbwalker.Modes[LocalCore.ORBWALKER_MODE_LANECLEAR] and self:CanLaneClear() then
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
			if team == LocalCore.TEAM_ALLY then
				return HealthPrediction.CachedTeamAlly
			elseif team == LocalCore.TEAM_ENEMY then
				return HealthPrediction.CachedTeamEnemy
			elseif team == LocalCore.TEAM_JUNGLE then
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
				local pos = LocalCore:To2D(target.pos)
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
						HealthPrediction.CachedAttackData[objname][name] = { Range = LocalCore:GetAutoAttackRange(obj, target), Damage = 0 }
					end
					local range = HealthPrediction.CachedAttackData[objname][name].Range + 100
					if LocalCore:IsInRange(LocalCore:To2D(obj.pos), pos, range) then
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
			local hp = LocalCore:TotalShieldHealth(target)
			if #attacks == 0 then return hp end
			local pos = LocalCore:To2D(target.pos)
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
						flyTime = LocalCore:GetDistance(LocalCore:To2D(attacker.pos), pos) / attacker.attackData.projectileSpeed
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
			if Orbwalker.Modes[LocalCore.ORBWALKER_MODE_COMBO] or Orbwalker.IsNone then
				return
			end
			local targets = ObjectManager:GetEnemyMinions(self.Range - 35, false)
			local projectileSpeed = self.Speed
			local winduptime = self.Delay
			local latency = LATENCY * 0.5
			local pos = LocalCore:To2D(myHero.pos)
			for i = 1, #targets do
				local target = targets[i]
				local FlyTime = LocalCore:GetDistance(pos, LocalCore:To2D(target.pos)) / projectileSpeed
				self.FarmMinions[#self.FarmMinions+1] = self:SetLastHitable(target, winduptime + FlyTime + latency, damagefunc())
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
		local mePos = LocalCore:To2D(myHero.pos)
		--selected:
		if Menu.ts.selected.enable:Value() and self.SelectedTarget ~= nil and LocalCore:IsValidTarget(self.SelectedTarget) and not ObjectManager:IsHeroImmortal(self.SelectedTarget, false) and self.SelectedTarget.pos.onScreen then
			SelectedID = self.SelectedTarget.networkID
			if Menu.ts.selected.onlysel:Value() then
				if type(a) == "number" then
					if LocalCore:IsInRange(mePos, LocalCore:To2D(self.SelectedTarget.pos), a) then
						return self.SelectedTarget
					end
				elseif type(a) == "table" then
					local x = 0
					for i = 1, #a do
						local u = a[i]
						if u then
							local dist = LocalCore:GetDistanceSquared(mePos, LocalCore:To2D(u.pos))
							if dist > x then
								x = dist
							end
						end
					end
					if LocalCore:IsInRange(mePos, LocalCore:To2D(self.SelectedTarget.pos), x) then
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
					x = LocalCore:GetDistance(LocalCore:To2D(unit.pos), mePos)
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
		local mePos = LocalCore:To2D(myHero.pos)
		for i = 1, GameHeroCount() do
			local hero = GameHero(i)
			if hero and hero.team == LocalCore.TEAM_ENEMY and LocalCore:IsValidTarget(hero) and not ObjectManager:IsHeroImmortal(hero, true) then
				local herorange = range
				if ME_CAITLYN and LocalCore:HasBuff(hero, "caitlynyordletrapinternal") then
					herorange = herorange + 600
				else
					herorange = herorange + bbox + hero.boundingRadius
				end
				if LocalCore:IsInRange(mePos, LocalCore:To2D(hero.pos), herorange) then
					targets[#targets+1] = hero
				end
			end
		end
		local t = self:GetTarget(targets, LocalCore.DAMAGE_TYPE_PHYSICAL)
		if not ME_KALISTA then
			return t
		end
		if t == nil then
			local hp = MathHuge
			for i = 1, GameHeroCount() do
				local obj = GameHero(i)
				if LocalCore:IsValidTarget(obj) and not obj.isAlly and LocalCore:IsInAutoAttackRange(myHero, obj) and obj.health < hp then
					t = obj
					hp = obj.health
				end
			end
		end
		if t == nil then
			hp = MathHuge
			for i = 1, GameMinionCount() do
				local obj = GameMinion(i)
				if LocalCore:IsValidTarget(obj) and not obj.isAlly and LocalCore:IsInAutoAttackRange(myHero, obj) and obj.health < hp then
					t = obj
					hp = obj.health
				end
			end
		end
		if t == nil then
			hp = MathHuge
			for i = 1, GameTurretCount() do
				local obj = GameTurret(i)
				if LocalCore:IsValidTarget(obj) and not obj.isAlly and LocalCore:IsInAutoAttackRange(myHero, obj) and obj.health < hp then
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
			local pos = LocalCore:To2D(_G.mousePos)
			for i = 1, #enemyList do
				local unit = enemyList[i]
				local distance = LocalCore:GetDistance(pos, LocalCore:To2D(unit.pos))
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
		if LocalCore.Priorities[charName] ~= nil then
			priority = LocalCore.Priorities[charName]
		else
			priority = 1
		end
		Menu.ts.priorities:MenuElement({ id = charName, name = charName, value = priority, min = 1, max = 5, step = 1 })
	end

	function __TargetSelector:CreateMenu()
		Menu:MenuElement({name = "Target Selector", id = "ts", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/ts.png" })
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
		local br = bb and range + 270 - 30 or range --myHero.range + 270 bbox
		local nr = bb and range + 380 - 30 or range --myHero.range + 380 bbox
		local mePos = LocalCore:To2D(myHero.pos)
		for i = 1, #turrets do
			local turret = turrets[i]
			local tr = bb and range + turret.boundingRadius * 0.75 or range
			if turret and LocalCore:IsValidTarget(turret) and LocalCore:IsInRange(mePos, LocalCore:To2D(turret.pos), tr) then
				result[#result+1] = turret
			end
		end
		for i = 1, #inhibitors do
			local barrack = inhibitors[i]
			if barrack and barrack.isTargetable and barrack.visible and LocalCore:IsInRange(mePos, LocalCore:To2D(barrack.pos), br) then
				result[#result+1] = barrack
			end
		end
		if nexus and nexus.isTargetable and nexus.visible and LocalCore:IsInRange(mePos, LocalCore:To2D(nexus.pos), nr) then
			result[#result+1] = nexus
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
		local mePos = LocalCore:To2D(myHero.pos)
		for i = 1, GameMinionCount() do
			local minion = GameMinion(i)
			if LocalCore:IsValidTarget(minion) and self:GetMinionType(minion) == LocalCore.MINION_TYPE_LANE_MINION then
				if LocalCore:IsInRange(mePos, LocalCore:To2D(minion.pos), range) then
					TableInsert(result, minion)
				end
			end
		end
		return result
	end

	function __ObjectManager:GetAllyMinions(range, bb)
		local result = {}
		local mePos = LocalCore:To2D(myHero.pos)
		for i = 1, GameMinionCount() do
			local minion = GameMinion(i)
			local mr = bb and range + minion.boundingRadius or range
			if minion and minion.team == LocalCore.TEAM_ALLY and LocalCore:IsValidTarget(minion) and self:GetMinionType(minion) == LocalCore.MINION_TYPE_LANE_MINION and LocalCore:IsInRange(mePos, LocalCore:To2D(minion.pos), mr) then
				result[#result+1] = minion
			end
		end
		return result
	end

	function __ObjectManager:GetEnemyMinions(range)
		local result = {}
		local mePos = LocalCore:To2D(myHero.pos)
		for i = 1, GameMinionCount() do
			local minion = GameMinion(i)
			local mr = bb and range + minion.boundingRadius or range
			if minion and minion.team == LocalCore.TEAM_ENEMY and LocalCore:IsValidTarget(minion) and LocalCore:IsInRange(mePos, LocalCore:To2D(minion.pos), mr) and self:GetMinionType(minion) == LocalCore.MINION_TYPE_LANE_MINION then
				result[#result+1] = minion
			end
		end
		return result
	end

	function __ObjectManager:GetEnemyMinionsInAutoAttackRange()
		local result = {}
		for i = 1, GameMinionCount() do
			local minion = GameMinion(i)
			if LocalCore:IsValidTarget(minion) and minion.isEnemy and self:GetMinionType(minion) == LocalCore.MINION_TYPE_LANE_MINION then
				if LocalCore:IsInAutoAttackRange(myHero, minion) then
					TableInsert(result, minion)
				end
			end
		end
		return result
	end

	function __ObjectManager:GetOtherMinions(range)
		local result = {}
		local mePos = LocalCore:To2D(myHero.pos)
		for i = 1, GameWardCount() do
			local minion = GameWard(i)
			if LocalCore:IsValidTarget(minion) and self:GetMinionType(minion) == LocalCore.MINION_TYPE_OTHER_MINION then
				if LocalCore:IsInRange(mePos, LocalCore:To2D(minion.pos), range) then
					TableInsert(result, minion)
				end
			end
		end
		return result
	end

	function __ObjectManager:GetOtherAllyMinions(range)
		local result = {}
		local mePos = LocalCore:To2D(myHero.pos)
		for i = 1, GameWardCount() do
			local minion = GameWard(i)
			if LocalCore:IsValidTarget(minion) and minion.isAlly and self:GetMinionType(minion) == LocalCore.MINION_TYPE_OTHER_MINION then
				if LocalCore:IsInRange(mePos, LocalCore:To2D(minion.pos), range) then
					TableInsert(result, minion)
				end
			end
		end
		return result
	end

	function __ObjectManager:GetOtherEnemyMinions(range)
		local result = {}
		local mePos = LocalCore:To2D(myHero.pos)
		for i = 1, GameWardCount() do
			local minion = GameWard(i)
			if LocalCore:IsValidTarget(minion) and minion.isEnemy and self:GetMinionType(minion) == LocalCore.MINION_TYPE_OTHER_MINION then
				if LocalCore:IsInRange(mePos, LocalCore:To2D(minion.pos), range) then
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
			if LocalCore:IsValidTarget(minion) and minion.isEnemy and self:GetMinionType(minion) == LocalCore.MINION_TYPE_OTHER_MINION then
				if LocalCore:IsInAutoAttackRange(myHero, minion) then
					TableInsert(result, minion)
				end
			end
		end
		return result
	end

	function __ObjectManager:GetMonsters(range)
		local result = {}
		local mePos = LocalCore:To2D(myHero.pos)
		for i = 1, GameMinionCount() do
			local minion = GameMinion(i)
			if LocalCore:IsValidTarget(minion) and self:GetMinionType(minion) == LocalCore.MINION_TYPE_MONSTER then
				if LocalCore:IsInRange(mePos, LocalCore:To2D(minion.pos), range) then
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
		local mePos = LocalCore:To2D(myHero.pos)
		for i = 1, GameHeroCount() do
			local hero = GameHero(i)
			if LocalCore:IsValidTarget(hero) then
				if LocalCore:IsInRange(mePos, LocalCore:To2D(hero.pos), range) then
					TableInsert(result, hero)
				end
			end
		end
		return result
	end

	function __ObjectManager:GetAllyHeroes(range)
		local result = {}
		local mePos = LocalCore:To2D(myHero.pos)
		for i = 1, GameHeroCount() do
			local hero = GameHero(i)
			if LocalCore:IsValidTarget(hero) and hero.isAlly then
				if LocalCore:IsInRange(mePos, LocalCore:To2D(hero.pos), range) then
					TableInsert(result, hero)
				end
			end
		end
		return result
	end

	function __ObjectManager:GetEnemyHeroes(range, bb, state)
		local result = {}
		state = state or 0
		bb = bb or false
		--state "spell" = 0
		--state "attack" = 1
		--state "immortal" = 2
		local mePos = LocalCore:To2D(myHero.pos)
		for i = 1, GameHeroCount() do
			local hero = GameHero(i)
			local r = bb and range + hero.boundingRadius or range
			if hero and hero.team == LocalCore.TEAM_ENEMY and LocalCore:IsValidTarget(hero) and LocalCore:IsInRange(mePos, LocalCore:To2D(hero.pos), r) then
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

	function __ObjectManager:GetEnemyHeroesInAutoAttackRange()
		local result = {}
		for i = 1, GameHeroCount() do
			local hero = GameHero(i)
			if LocalCore:IsValidTarget(hero) and hero.isEnemy then
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
		local turrets = LocalCore:GetAllyTurrets()
		local mePos = LocalCore:To2D(myHero.pos)
		for i = 1, #turrets do
			local turret = turrets[i]
			if LocalCore:IsValidTarget(turret) and LocalCore:IsInRange(mePos, LocalCore:To2D(turret.pos), range) then
				TableInsert(result, turret)
			end
		end
		return result
	end

	function __ObjectManager:GetEnemyTurrets(range)
		local result = {}
		local turrets = LocalCore:GetEnemyTurrets()
		local mePos = LocalCore:To2D(myHero.pos)
		for i = 1, #turrets do
			local turret = turrets[i]
			if LocalCore:IsValidTarget(turret) and LocalCore:IsInRange(mePos, LocalCore:To2D(turret.pos), range) then
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
			Menu.orb:MenuElement({ name = "Humanizer", id = "humanizer", type = _G.MENU })
				Menu.orb.humanizer:MenuElement({ name = "Random", id = "random", type = _G.MENU })
					Menu.orb.humanizer.random:MenuElement({name = "Enabled", id = "enabled", value = true })
					Menu.orb.humanizer.random:MenuElement({name = "From", id = "from", value = 150, min = 60, max = 300, step = 20 })
					Menu.orb.humanizer.random:MenuElement({name = "To", id = "to", value = 220, min = 60, max = 400, step = 20 })
				Menu.orb.humanizer:MenuElement({name = "Humanizer", id = "standard", value = 200, min = 60, max = 300, step = 10 })
					self.Menu.General.MovementDelay = Menu.orb.humanizer.standard
			Menu.orb:MenuElement({ name = "Extra Cursor Delay", id = "excdelay", value = 25, min = 0, max = 50, step = 5 })
			Menu.orb:MenuElement({name = "Player Attack Only Click", id = "aamoveclick", key = string.byte("U")})
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
		Cursor:SetCursor(_G.cursorPos, unit, attackKey, function()
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
		Cursor:SetCursor(_G.cursorPos, pos, MOUSEEVENTF_RIGHTDOWN, function()
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
		if LocalCore:IsChanneling(myHero) then
			return false
		end
		if LocalCore.DisableAutoAttack[MeCharName] ~= nil and LocalCore.DisableAutoAttack[MeCharName](myHero) then
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
			if GameTimer() >= self.AttackEndTime - LATENCY - 0.04 then
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
			if GameTimer() >= self.AttackCastEndTime + 0.01 - LATENCY then
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
		if ME_KALISTA then
			return true
		end
		if not myHero.pathing.hasMovePath then
			self.LastMoveLocal = 0
		end
		if LocalCore:IsChanneling(myHero) then
			if LocalCore.AllowMovement[MeCharName] == nil or (not LocalCore.AllowMovement[MeCharName](myHero)) then
				return false
			end
		end
		if self.ChampionCanMove[MeCharName] ~= nil and not self.ChampionCanMove[MeCharName]() then
			return false
		end
		if MenuChamp.lcore.enabled:Value() and MenuChamp.lcore.response:Value() and GameTimer() > self.AttackLocalStart + self.AttackWindUp + MenuChamp.lcore.extraw:Value() * 0.001 then
			return true
		end
		local mePos = LocalCore:To2D(myHero.pos)
		if LocalCore:IsInRange(mePos, LocalCore:To2D(_G.mousePos), 120) then
			return false
		end
		if self.AttackCastEndTime > self.AttackLocalStart then
			if GameTimer() >= self.AttackCastEndTime + extraDelay + 0.01 - LATENCY then
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
		if not Cursor.IsReadyGlobal then
			if wParam == Menu.orb.aamoveclick:Key() then
				self.AttackLocalStart = GameTimer()
				Cursor.IsReadyGlobal = true
				--print("attack")
			elseif wParam == Cursor.Key then
				Cursor.IsReadyGlobal = true
				--print("spell")
			elseif Cursor.Key == MOUSEEVENTF_RIGHTDOWN and wParam == 2 then
				Cursor.IsReadyGlobal = true
				--print("mouse")
			end
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
			elseif GameTimer() > HealthPrediction.ShouldWaitTime + MenuChamp.lclear.swait:Value() * 0.001 then
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
			if GameTimer() < self.LastMouseDown + 1 then
				ControlMouseEvent(MOUSEEVENTF_RIGHTDOWN)
				self.LastMouseDown = 0
			end
			return
		end
		if GameIsChatOpen() or (ExtLibEvade and ExtLibEvade.Evading) or not Cursor.IsReady or (not GameIsOnTop()) then
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
			elseif GameTimer() > HealthPrediction.ShouldWaitTime + MenuChamp.lclear.swait:Value() * 0.001 then
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
			if self.MovementEnabled and GameTimer() > self.LastMoveLocal and self:CanMoveLocal(0) then
				self:AttackMove()
			end
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
		if spell and spell.valid and not LocalCore.NoAutoAttacks[spell.name] and spell.castEndTime > self.AttackCastEndTime and (not myHero.isChanneling or LocalCore.SpecialAutoAttacks[spell.name]) then
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
		--[[
		local data = LocalCore:GetHeroData(myHero, true)
		for name, s in pairs(data.ActiveSpells) do
			if s.type == LocalCore.SPELLCAST_ATTACK and s.completed then
				local as = s.spell
				if as ~= nil and as.spellWasCast ~= nil and as.spellWasCast == false and GameTimer() > as.castEndTime and GameTimer() < as.castEndTime + 0.075 then
					self:__OnAutoAttackReset()
					print("reset attack")
				end
			end
		end]]
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
		self.AttackEndTime = 0
		self.AttackLocalStart = 0
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
			if not minion.Minion.dead and minion.LastHitable and minion.PredictedHP < min and LocalCore:IsValidTarget(minion.Minion) and LocalCore:IsInAutoAttackRange(myHero, minion.Minion) then
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
				if not target.Minion.dead and target.PredictedHP < min and LocalCore:IsValidTarget(target.Minion) and LocalCore:IsInAutoAttackRange(myHero, target.Minion) then
					min = target.PredictedHP
					result = target.Minion
				end
			end
		end
		return result
	end

	function __HealthPrediction:SetObjects(team)
		if team == LocalCore.TEAM_ALLY then
			if #self.CachedTeamAlly > 0 then
				return
			end
		elseif team == LocalCore.TEAM_ENEMY then
			if #self.CachedTeamEnemy > 0 then
				return
			end
		elseif team == LocalCore.TEAM_JUNGLE then
			if #self.CachedTeamJungle > 0 then
				return
			end
		end
		for i = 1, GameMinionCount() do
			local obj = GameMinion(i)
			if obj and obj.team ~= team and LocalCore:IsValidTarget(obj) then
				if team == LocalCore.TEAM_ALLY then
					self.CachedTeamAlly[#self.CachedTeamAlly+1] = obj
				elseif team == LocalCore.TEAM_ENEMY then
					self.CachedTeamEnemy[#self.CachedTeamEnemy+1] = obj
				else
					self.CachedTeamJungle[#self.CachedTeamJungle+1] = obj
				end
			end
		end
		for i = 1, GameHeroCount() do
			local obj = GameHero(i)
			if obj and obj.team ~= team and not obj.isMe and LocalCore:IsValidTarget(obj) then
				if team == LocalCore.TEAM_ALLY then
					self.CachedTeamAlly[#self.CachedTeamAlly+1] = obj
				elseif team == LocalCore.TEAM_ENEMY then
					self.CachedTeamEnemy[#self.CachedTeamEnemy+1] = obj
				else
					self.CachedTeamJungle[#self.CachedTeamJungle+1] = obj
				end
			end
		end
		local turrets = LocalCore:Join(LocalCore:GetEnemyTurrets(), LocalCore:GetAllyTurrets())
		for i = 1, #turrets do
			local obj = turrets[i]
			if obj and obj.team ~= team and LocalCore:IsValidTarget(obj) then
				if team == LocalCore.TEAM_ALLY then
					self.CachedTeamAlly[#self.CachedTeamAlly+1] = obj
				elseif team == LocalCore.TEAM_ENEMY then
					self.CachedTeamEnemy[#self.CachedTeamEnemy+1] = obj
				else
					self.CachedTeamJungle[#self.CachedTeamJungle+1] = obj
				end
			end
		end
	end

	function __HealthPrediction:GetObjects(team)
		if team == LocalCore.TEAM_ALLY then
			return self.CachedTeamAlly
		elseif team == LocalCore.TEAM_ENEMY then
			return self.CachedTeamEnemy
		elseif team == LocalCore.TEAM_JUNGLE then
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
			local pos = LocalCore:To2D(target.pos)
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
					self.CachedAttackData[objname][name] = { Range = LocalCore:GetAutoAttackRange(obj, target), Damage = 0 }
				end
				local range = self.CachedAttackData[objname][name].Range + 100
				if LocalCore:IsInRange(LocalCore:To2D(obj.pos), pos, range) then
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
		local hp = LocalCore:TotalShieldHealth(target)
		if #attacks == 0 then return hp end
		local pos = LocalCore:To2D(target.pos)
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
					flyTime = LocalCore:GetDistance(LocalCore:To2D(attacker.pos), pos) / attacker.attackData.projectileSpeed
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
		if Orbwalker.Modes[LocalCore.ORBWALKER_MODE_COMBO] or Orbwalker:HasMode(LocalCore.ORBWALKER_MODE_NONE) then
			self.CanCheckTurret = false
			return
		end
		local targets = ObjectManager:GetEnemyMinions(myHero.range + myHero.boundingRadius, true)
		local projectileSpeed = GetProjSpeed()
		local winduptime = GetWindup()
		local latency = LATENCY * 0.5
		local pos = LocalCore:To2D(myHero.pos)
		for i = 1, #targets do
			local target = targets[i]
			local FlyTime = LocalCore:GetDistance(pos, LocalCore:To2D(target.pos)) / projectileSpeed
			self.FarmMinions[#self.FarmMinions+1] = self:SetLastHitable(target, winduptime + FlyTime + latency, Damage:GetAutoAttackDamage(myHero, target))
		end
		self.CanCheckTurret = false
	end

	function __HealthPrediction:Draw()
		if Orbwalker.Modes[LocalCore.ORBWALKER_MODE_COMBO] then return end
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
	if CONTROLL == nil and GameTimer() > NEXT_CONTROLL + 0.05 then
		CONTROLL = function()
			if Cursor.IsReady then
				Orbwalker:Attack(target)
				NEXT_CONTROLL = GameTimer()
				Spells.CanNext = true
				return true
			end
			return false
		end
		return true
	end
	return false
end

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
				if Cursor.IsReady then
					Orbwalker:MoveToPos(position)
					return true
				end
			else
				Orbwalker:Move()
				return true
			end
			return false
		end
		return true
	end
	return false
end

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
		if position ~= nil and not Cursor.IsReady then
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
				Cursor:SetCursor(_G.cursorPos, position, key, function()
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

Menu = MenuElement({name = "gsoOrbwalker", id = "gamsteronOrb", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/rsz_gsoorbwalker.png" })
TargetSelector:CreateMenu()
Orbwalker:CreateMenu()

Menu:MenuElement({name = "Drawings", id = "gsodraw", leftIcon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/circles.png", type = _G.MENU })
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

	Callback.Add('WndMsg', function(msg, wParam)
		TargetSelector:WndMsg(msg, wParam)
		Orbwalker:WndMsg(msg, wParam)
		Spells:WndMsg(msg, wParam)
	end)

	Callback.Add('Draw', function()
		if not Menu.gsodraw.enabled:Value() then return end
		TargetSelector:Draw()
		HealthPrediction:Draw()
		Cursor:Draw()
		Orbwalker:Draw()
	end)

	Callback.Add('Draw', function()
		Orbwalker:Tick()
		Cursor:Tick()
		if CONTROLL ~= nil and CONTROLL() == true then
			CONTROLL = nil
		end
	end)
end)

_G.GamsteronOrbwalkerLoaded = true
