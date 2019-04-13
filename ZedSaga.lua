if myHero.charName ~= 'Zed' then return end


require "MapPosition"

Latency = Game.Latency
	local ignitecast
	local igniteslot
    local Zoe = myHero
    local ping = Game.Latency()/1000
    local itsReadyBitch = Game.CanUseSpell
    local smallshits = Game.MinionCount
    local littleshit = Game.Minion
	local Q = {range = 900, speed = 900, width = 70, delay = 0.25}
	local W = {range = 650, speed = 1750, swaprange = 1300, delay = 0.25}
	local E = {range = 290}
	local R = {range = 625}
	local visionTick = GetTickCount()
	local LocalCallbackAdd = Callback.Add
	local HKITEM = { [ITEM_1] = 49, [ITEM_2] = 50, [ITEM_3] = 51, [ITEM_4] = 52, [ITEM_5] = 53, [ITEM_6] = 54 
	}
	local shadow = myHero.pos
	local shadow2 = myHero.pos
    local _EnemyHeroes
    local _OnVision = {}
    local TotalHeroes = 0
    local TEAM_ALLY = Zoe.team
    local TEAM_ENEMY = 300 - TEAM_ALLY
    local myCounter = 1
    local isEvading = ExtLibEvade and ExtLibEvade.Evading
	local	GetOrbMode,
        SagaOrb,
        Sagacombo,
        Sagaharass,
        SagalastHit,
        SagalaneClear,
        SagaSDK,
        SagaSDKCombo,
        SagaSDKHarass,
        SagaSDKJungleClear,
        SagaSDKLaneClear,
        SagaSDKLastHit,
        SagaSDKSelector,
        SagaGOScombo,
        SagaGOSharass,
        SagaGOSlastHit,
        SagaGOSlaneClear,
        SagaSDKModes,
        minionCollision,
        VectorPointProjectionOnLineSegment,
        SagaSDKMagicDamage,
		SagaSDKPhysicalDamage,
		Qdmg,
		QDmg,
		Edmg,
		Passivedmg,
		ComboAA,
		BOTRKdmg,
		Rdmg,
		GetDistance2D,
		IsImmobileTarget,
		GetPred, CastQ,
		CastQS,
		CastW,
		Combo, 
		Harass, 
		Flee,
		LaneClear,
		LastHit



    local DamageReductionTable = {
        ['Braum'] = {
            buff = 'BraumShieldRaise',
            amount = function(target)
                return 1 - ({0.3, 0.325, 0.35, 0.375, 0.4})[target:GetSpellData(_E).level]
            end
        },
        ['Urgot'] = {
            buff = 'urgotswapdef',
            amount = function(target)
                return 1 - ({0.3, 0.4, 0.5})[target:GetSpellData(_R).level]
            end
        },
        ['Alistar'] = {
            buff = 'Ferocious Howl',
            amount = function(target)
                return ({0.5, 0.4, 0.3})[target:GetSpellData(_R).level]
            end
        },
        ['Amumu'] = {
            buff = 'Tantrum',
            amount = function(target)
                return ({2, 4, 6, 8, 10})[target:GetSpellData(_E).level]
            end,
            damageType = 1
        },
        ['Galio'] = {
            buff = 'GalioIdolOfDurand',
            amount = function(target)
                return 0.5
            end
        },
        ['Garen'] = {
            buff = 'GarenW',
            amount = function(target)
                return 0.7
            end
        },
        ['Gragas'] = {
            buff = 'GragasWSelf',
            amount = function(target)
                return ({0.1, 0.12, 0.14, 0.16, 0.18})[target:GetSpellData(_W).level]
            end
        },
        ['Annie'] = {
            buff = 'MoltenShield',
            amount = function(target)
                return 1 - ({0.16, 0.22, 0.28, 0.34, 0.4})[target:GetSpellData(_E).level]
            end
        },
        ['Malzahar'] = {
            buff = 'malzaharpassiveshield',
            amount = function(target)
                return 0.1
            end
        }
    }

    local
		findEmemy,
		ClearJungle,
		HarassMode,
		ClearMode,
        validTarget,
        ValidTargetM,
		GetDistanceSqr,
        GetDistance,
        DamageReductionMod,
        OnVision,
        OnVisionF,
        CalcMagicalDamage,
        CalcPhysicalDamage,
        GetTarget,
        Priority,
		PassivePercentMod,
        GetItemSlot,
        Angle,
		Saga, Saga_Menu
	
		
		
		Qdmg = function(target)
			if Game.CanUseSpell(0) == 0 then
				if Game.CanUseSpell(1) == 0 and GetDistance(myHero.pos,target.pos) < 900 and target:GetCollision(70, 900, 0.25) == 0 then
					return CalcPhysicalDamage(myHero,target,(45 + 35 * myHero:GetSpellData(_Q).level + 0.9 * myHero.bonusDamage) * 1.75 )
				elseif Game.CanUseSpell(1) == 0 and GetDistance(myHero.pos,target.pos) < 900 and target:GetCollision(70, 900, 0.25) ~= 0 then
					return CalcPhysicalDamage(myHero,target,(45 + 35 * myHero:GetSpellData(_Q).level + 0.9 * myHero.bonusDamage) * 1.75 * 0.6 )
				elseif not Game.CanUseSpell(1) == 0 and target:GetCollision(70, 900, 0.25) == 0 then
					return CalcPhysicalDamage(myHero,target,(45 + 35 * myHero:GetSpellData(_Q).level + 0.9 * myHero.bonusDamage))
				elseif not Game.CanUseSpell(1) == 0 and target:GetCollision(70, 900, 0.25) ~= 0 then
					return CalcPhysicalDamage(myHero,target,(45 + 35 * myHero:GetSpellData(_Q).level + 0.9 * myHero.bonusDamage * 0.6))
				end
			end
			return 0
		end
		
		QDmg = function(target)
			if Game.CanUseSpell(0) == 0 then
				if target:GetCollision(70, 900, 0.25) == 0 then
					return CalcPhysicalDamage(myHero,target,(45 + 35 * myHero:GetSpellData(_Q).level + 0.9 * myHero.bonusDamage))
				elseif target:GetCollision(70, 900, 0.25) ~= 0 then
					return CalcPhysicalDamage(myHero,target,(45 + 35 * myHero:GetSpellData(_Q).level + 0.9 * myHero.bonusDamage * 0.6))
				end
			end
			return 0
		end
		
		Edmg = function(target)
			if Game.CanUseSpell(2) == 0 then
				return CalcPhysicalDamage(myHero,target,(45 + 25 * myHero:GetSpellData(_E).level + 0.8 * myHero.bonusDamage))
			end
			return 0
		end
		
		Passivedmg = function(target)
			for i = 0, target.buffCount do
				local buff = target:GetBuff(i)
				if buff.name == "zedpassivecd" then
					return 0
				end
			end
			if myHero.levelData.lvl >= 17 then
				return CalcMagicalDamage(myHero,target,(target.maxHealth * 0.1))
			elseif myHero.levelData.lvl >= 7 then
				return CalcMagicalDamage(myHero,target,(target.maxHealth * 0.08))
			else
				return CalcMagicalDamage(myHero,target,(target.maxHealth * 0.06))
			end
		end
		
		 ComboAA = function(target)
			local AAdmg = CalcPhysicalDamage(myHero,target,(myHero.totalDamage))
			if myHero.attackSpeed >= 2.5 then
				return AAdmg * 5
			elseif myHero.attackSpeed >= 2 then
				return AAdmg * 4
			elseif myHero.attackSpeed >= 1.5 then
				return AAdmg * 3
			elseif myHero.attackSpeed >= 1 then
				return AAdmg * 2
			else
				return AAdmg
			end
		end
		
			BOTRKdmg = function(target)
			local items = {}
			for slot = ITEM_1,ITEM_6 do
				local id = myHero:GetItemData(slot).itemID 
				if id > 0 then
					items[id] = slot
				end
			end
		
			local BOTRK = items[3144] or items[3153]
			if BOTRK and myHero:GetSpellData(BOTRK).currentCd == 0 then
				return CalcMagicalDamage(myHero,target,(100))
			end
			return 0
		end
		
		
		Rdmg = function(target)
			if Game.CanUseSpell(3) == 0 then
				return CalcPhysicalDamage(myHero,target,(myHero.totalDamage + (0.15 + 0.10 * myHero:GetSpellData(_R).level) * (Passivedmg(target) + Qdmg(target) * 0.5 + BOTRKdmg(target) + ComboAA(target)) ))
			end
			return 0
		end

		ComboDamage = function(target)
			local basedamage = ComboAA(target)
			local qdmgg = 0
			local rdmgg = 0
			local edmgg = 0
			local botrk = BOTRKdmg(target)
			local passive = Passivedmg(target)
			if Game.CanUseSpell(0) == 0 then 
				qdmgg = QDmg(target)
			end

			if Game.CanUseSpell(2) == 0 then 
				edmgg = Edmg(target)
			end

			if Game.CanUseSpell(3) == 0 then 
				rdmgg = Rdmg(target)
			end
			local total = qdmgg + rdmgg + botrk + passive + basedamage
			return total
		end
		
        
    
    local sqrt = math.sqrt
	GetDistanceSqr = function(p1, p2)
		p2 = p2 or Zoe
		p1 = p1.pos or p1
		p2 = p2.pos or p2
		
	
		local dx, dz = p1.x - p2.x, p1.z - p2.z 
		return dx * dx + dz * dz
	end

	GetDistance = function(p1, p2)
		
		return sqrt(GetDistanceSqr(p1, p2))
    end
    


    


    GetEnemyHeroes = function()
        _EnemyHeroes = {}
        for i = 1, Game.HeroCount() do
            local unit = Game.Hero(i)
            if unit.team == TEAM_ENEMY or unit.isEnemy then
                _EnemyHeroes[myCounter] = unit
                myCounter = myCounter + 1
            end
        end
        myCounter = 1
        return #_EnemyHeroes
    end

	GetTarget = function(range)

		if SagaOrb == 1 then
			if myHero.ap > myHero.totalDamage then
				return EOW:GetTarget(range, EOW.ap_dec, myHero.pos)
			else
				return EOW:GetTarget(range, EOW.ad_dec, myHero.pos)
			end
		elseif SagaOrb == 2 and SagaSDKSelector then
			if myHero.ap > myHero.totalDamage then
				return SagaSDKSelector:GetTarget(range, SagaSDKMagicDamage)
			else
				return SagaSDKSelector:GetTarget(range, SagaSDKPhysicalDamage)
			end
		elseif _G.GOS then
			if myHero.ap > myHero.totalDamage then
				return GOS:GetTarget(range, "AP")
			else
				return GOS:GetTarget(range, "AD")
			end
		elseif _G.gsoSDK then
			return _G.gsoSDK.TS:GetTarget()
		end
	end


    function CalcPhysicalDamage(source, target, amount)
        local ArmorPenPercent = source.armorPenPercent
        local ArmorPenFlat = (0.4 + target.levelData.lvl / 30) * source.armorPen
        local BonusArmorPen = source.bonusArmorPenPercent
      
        if source.type == Obj_AI_Minion then
          ArmorPenPercent = 1
          ArmorPenFlat = 0
          BonusArmorPen = 1
        elseif source.type == Obj_AI_Turret then
          ArmorPenFlat = 0
          BonusArmorPen = 1
          if source.charName:find("3") or source.charName:find("4") then
            ArmorPenPercent = 0.25
          else
            ArmorPenPercent = 0.7
          end
        end
      
        if source.type == Obj_AI_Turret then
          if target.type == Obj_AI_Minion then
            amount = amount * 1.25
            if string.ends(target.charName, "MinionSiege") then
              amount = amount * 0.7
            end
            return amount
          end
        end
      
        local armor = target.armor
        local bonusArmor = target.bonusArmor
        local value = 100 / (100 + (armor * ArmorPenPercent) - (bonusArmor * (1 - BonusArmorPen)) - ArmorPenFlat)
      
        if armor < 0 then
          value = 2 - 100 / (100 - armor)
        elseif (armor * ArmorPenPercent) - (bonusArmor * (1 - BonusArmorPen)) - ArmorPenFlat < 0 then
          value = 1
        end
        return math.max(0, math.floor(DamageReductionMod(source, target, PassivePercentMod(source, target, value) * amount, 1)))
      end

    CalcMagicalDamage = function(source, target, amount)
        local mr = target.magicResist
        local value = 100 / (100 + (mr * source.magicPenPercent) - source.magicPen)
      
        if mr < 0 then
          value = 2 - 100 / (100 - mr)
        elseif (mr * source.magicPenPercent) - source.magicPen < 0 then
          value = 1
        end
        return math.max(0, math.floor(DamageReductionMod(source, target, PassivePercentMod(source, target, value) * amount, 2)))
      end
    
      DamageReductionMod = function(source,target,amount,DamageType)
        if source.type == Obj_AI_Hero then
          if GotBuff(source, "Exhaust") > 0 then
            amount = amount * 0.6
          end
        end
        if target.type == Obj_AI_Hero then
          for i = 0, target.buffCount do
            if target:GetBuff(i).count > 0 then
              local buff = target:GetBuff(i)
              if buff.name == "MasteryWardenOfTheDawn" then
                amount = amount * (1 - (0.06 * buff.count))
              end
              if DamageReductionTable[target.charName] then
                if buff.name == DamageReductionTable[target.charName].buff and (not DamageReductionTable[target.charName].damagetype or DamageReductionTable[target.charName].damagetype == DamageType) then
                  amount = amount * DamageReductionTable[target.charName].amount(target)
                end
              end
              if target.charName == "Maokai" and source.type ~= Obj_AI_Turret then
                if buff.name == "MaokaiDrainDefense" then
                  amount = amount * 0.8
                end
              end
              if target.charName == "MasterYi" then
                if buff.name == "Meditate" then
                  amount = amount - amount * ({0.5, 0.55, 0.6, 0.65, 0.7})[target:GetSpellData(_W).level] / (source.type == Obj_AI_Turret and 2 or 1)
                end
              end
            end
          end
        if target.charName == "Kassadin" and DamageType == 2 then
            amount = amount * 0.85
          end
        end
        return amount
      end
    
      PassivePercentMod = function(source, target, amount, damageType)
        local SiegeMinionList = {"Red_Minion_MechCannon", "Blue_Minion_MechCannon"}
        local NormalMinionList = {"Red_Minion_Wizard", "Blue_Minion_Wizard", "Red_Minion_Basic", "Blue_Minion_Basic"}
        if source.type == Obj_AI_Turret then
          if table.contains(SiegeMinionList, target.charName) then
            amount = amount * 0.7
          elseif table.contains(NormalMinionList, target.charName) then
            amount = amount * 1.14285714285714
          end
        end
        if source.type == Obj_AI_Hero then 
          if target.type == Obj_AI_Hero then
            if (GetItemSlot(source, 3036) > 0 or GetItemSlot(source, 3034) > 0) and source.maxHealth < target.maxHealth and damageType == 1 then
              amount = amount * (1 + math.min(target.maxHealth - source.maxHealth, 500) / 50 * (GetItemSlot(source, 3036) > 0 and 0.015 or 0.01))
            end
          end
        end
        return amount
        end
        
        GetItemSlot = function(unit, id)
            for i = ITEM_1, ITEM_7 do
                if unit:GetItemData(i).itemID == id then
                    return i
                end
            end
            return 0
        end

        DisableMovement = function(bool)

            if _G.SDK then
                _G.SDK.Orbwalker:SetMovement(not bool)
            elseif _G.EOWLoaded then
                EOW:SetMovements(not bool)
            elseif _G.GOS then
                GOS.BlockMovement = bool
            end
         end
         
         DisableAttacks = function(bool)
         
            if _G.SDK then
                _G.SDK.Orbwalker:SetAttack(not bool)
            elseif _G.EOWLoaded then
                EOW:SetAttacks(not bool)
            elseif _G.GOS then
                GOS.BlockAttack = bool
            end
         end
         

        local castSpell = {state = 0, tick = GetTickCount(), casting = GetTickCount() - 1000, mouse = mousePos}
        CastSpell = function(spell,pos,range,delay)
        
            local range = range or math.huge
            local delay = delay or 250
            local ticker = GetTickCount()
        
            if castSpell.state == 0 and GetDistance(Zoe.pos, pos) < range and ticker - castSpell.casting > delay + Latency() then
                castSpell.state = 1
                castSpell.mouse = mousePos
                castSpell.tick = ticker
            end
            if castSpell.state == 1 then
                if ticker - castSpell.tick < Latency() then
                    Control.SetCursorPos(pos)
                    Control.KeyDown(spell)
                    Control.KeyUp(spell)
                    castSpell.casting = ticker + delay
                    DelayAction(function()
                        if castSpell.state == 1 then
                            Control.SetCursorPos(castSpell.mouse)
                            castSpell.state = 0
                        end
                    end,Latency()/1000)
                end
                if ticker - castSpell.casting > Latency() then
                    Control.SetCursorPos(castSpell.mouse)
                    castSpell.state = 0
                end
            end
        end



       

        findMinion = function()
            for i = 1, smallshits() do
                local minion = littleshit(i)
                if i > 1000 then return end
                if minion and minion.pos:DistanceTo() <= W.range and minion.isTargetable and minion.isEnemy and not minion.dead and minion.visible then
                    return minion, minion.pos
                end
            end
        end

		validTarget = function(unit)
			if unit and unit.isEnemy and unit.valid and unit.isTargetable and not unit.dead and not unit.isImmortal and not (GotBuff(unit, 'FioraW') == 1) and
			not (GotBuff(unit, 'XinZhaoRRangedImmunity') == 1 and unit.distance <= 450) and unit.visible then
				return true
			else 
				return false
			end
		end

        GetEnemiesinRangeCount = function(target,range)
            local inRadius =  {}
            
            for i = 1, TotalHeroes do
                local unit = _EnemyHeroes[i]
				if unit.pos ~= nil and validTarget(unit) then
                    if  GetDistance(target.pos, unit.pos) <= range then
                        
                        inRadius[myCounter] = unit
                        myCounter = myCounter + 1
                    end
                end
            end
                myCounter = 1
            return #inRadius, inRadius
		end
		
		GetEnemiesinRangeCountShadow = function(target,range)
            local inRadius =  {}
            
            for i = 1, TotalHeroes do
                local unit = _EnemyHeroes[i]
				if unit.pos ~= nil and validTarget(unit) then
					
                    if  GetDistance(target, unit.pos) <= range then
                        inRadius[myCounter] = unit
                        myCounter = myCounter + 1
                    end
                end
            end
                myCounter = 1
            return #inRadius, inRadius
        end

        


        VectorPointProjectionOnLineSegment = function(v1, v2, v)
            local cx, cy, ax, ay, bx, by = v.x, v.z, v1.x, v1.z, v2.x, v2.z
            local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) * (bx - ax) + (by - ay) * (by - ay))
            local pointLine = { x = ax + rL * (bx - ax), z = ay + rL * (by - ay) }
            local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
            local isOnSegment = rS == rL
            local pointSegment = isOnSegment and pointLine or {x = ax + rS * (bx - ax), z = ay + rS * (by - ay)}
            return pointSegment, pointLine, isOnSegment
        end 
        
        minionCollision2 = function( me, position, spell)
            local targemyCounter = 0
            for i = smallshits(), 1, -1 do 
                local minion = littleshit(i)
                if minion.isTargetable and minion.team == TEAM_ENEMY and minion.dead == false then
                    local linesegment, line, isOnSegment = VectorPointProjectionOnLineSegment(me, position, minion.pos)
                    if linesegment and isOnSegment and (GetDistanceSqr(minion.pos, linesegment) <= (minion.boundingRadius + spell.Width) * (minion.boundingRadius + spell.Width)) then
                        targemyCounter = targemyCounter + 1
                    end
                end
            end
            return targemyCounter
        end


    LocalCallbackAdd(
    'Load',
	function()
        Saga_Menu()
        TotalHeroes = GetEnemyHeroes()
        GetIgnite()
        

		if _G.EOWLoaded then
			SagaOrb = 1
		elseif _G.SDK and _G.SDK.Orbwalker then
			SagaOrb = 2
		elseif _G.GOS then
			SagaOrb = 3
		elseif _G.gsoSDK then
			SagaOrb = 4
		end
		
		if  SagaOrb == 1 then
		   local mode = EOW:Mode()
		
		   Sagacombo = mode == 1
		   Sagaharass = mode == 2
		   SagalastHit = mode == 3
		   SagalaneClear = mode == 4
		   SagajungleClear = mode == 4
		
		   Sagacanmove = EOW:CanMove()
		   Sagacanattack = EOW:CanAttack()
		elseif  SagaOrb == 2 then
			SagaSDK = SDK.Orbwalker
			SagaSDKCombo = SDK.ORBWALKER_MODE_COMBO
			SagaSDKHarass = SDK.ORBWALKER_MODE_HARASS
			SagaSDKJungleClear = SDK.ORBWALKER_MODE_JUNGLECLEAR
			SagaSDKJungleClear = SDK.ORBWALKER_MODE_JUNGLECLEAR
			SagaSDKLaneClear = SDK.ORBWALKER_MODE_LANECLEAR
			SagaSDKLastHit = SDK.ORBWALKER_MODE_LASTHIT
			SagaSDKFlee = SDK.ORBWALKER_MODE_FLEE
			SagaSDKSelector = SDK.TargetSelector
			SagaSDKMagicDamage = _G.SDK.DAMAGE_TYPE_MAGICAL
			SagaSDKPhysicalDamage = _G.SDK.DAMAGE_TYPE_PHYSICAL
		elseif  SagaOrb == 3 then
		   
		end
    end
)

checkItems = function()
	local items = {}
	for slot = ITEM_1,ITEM_6 do
		local id = myHero:GetItemData(slot).itemID 
		if id > 0 then
			items[id] = slot
		end
	end
	return items
end

GetIgnite = function()
    if myHero:GetSpellData(SUMMONER_2).name:lower() == "summonerdot" then
        igniteslot = 5
        ignitecast = HK_SUMMONER_2

    elseif myHero:GetSpellData(SUMMONER_1).name:lower() == "summonerdot" then
        igniteslot = 4
        ignitecast = HK_SUMMONER_1
    else
        igniteslot = nil
        ignitecast = nil
    end
    
end



SIGroup = function(target)
	local items = checkItems()
	local bg = items[3144] or items[3153]
	if target then
		if bg and Saga.items.bg:Value() and myHero:GetSpellData(bg).currentCd == 0  and myHero.pos:DistanceTo(target.pos) < 550 then
			Control.CastSpell(HKITEM[bg], target.pos)
		end
		
		
		local tmt = items[3077] or items[3748] or items[3074]
		if tmt and Saga.items.tm:Value() and myHero:GetSpellData(tmt).currentCd == 0  and myHero.pos:DistanceTo(target.pos) < 400 and myHero.attackData.state == 2 then
			Control.CastSpell(HKITEM[tmt], target.pos)
		end

		local YG = items[3142]
		if YG and Saga.items.yg:Value() and myHero:GetSpellData(YG).currentCd == 0  and myHero.pos:DistanceTo(target.pos) < 1575 then
			Control.CastSpell(HKITEM[YG])
		end
		
		
		if ignitecast and igniteslot and Saga.items.ig:Value() then
			if target and Game.CanUseSpell(igniteslot) == 0 and GetDistanceSqr(myHero, target) < 450 * 450 and 25 >= (100 * target.health / target.maxHealth) then
				Control.CastSpell(ignitecast, target)
			end
		end

	end

end
LocalCallbackAdd("Draw", function()
if Saga.Drawings.Q.Enabled:Value() then 
	Draw.Circle(myHero.pos, Q.range, 0, Saga.Drawings.Q.Color:Value())
end

if Saga.Drawings.E.Enabled:Value() then 
	Draw.Circle(myHero.pos, E.range, 0, Saga.Drawings.E.Color:Value())
end

if Saga.Drawings.W.Enabled:Value() then 
	Draw.Circle(myHero.pos, W.range, 0, Saga.Drawings.W.Color:Value())
end

if Saga.Drawings.R.Enabled:Value() then 
	Draw.Circle(myHero.pos, R.range, 0, Saga.Drawings.R.Color:Value())
end

for i= 1, TotalHeroes do
	local hero = _EnemyHeroes[i]
	local barPos = hero.hpBar
	if hero then
	if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
		local dmg = ComboDamage(hero)
		if dmg > hero.health then
			Draw.Text("KILL NOW", 30, hero.pos2D.x - 50, hero.pos2D.y + 50,Draw.Color(200, 255, 87, 51))				
		else
			Draw.Text("Harass Me", 30, hero.pos2D.x - 50, hero.pos2D.y + 50,Draw.Color(200, 255, 87, 51))
		end
		end 	
		end
	end

end)

LocalCallbackAdd(
    'Tick',
	function()
		
        if Game.Timer() > Saga.Rate.champion:Value() and #_EnemyHeroes == 0 then
            TotalHeroes = GetEnemyHeroes()
        end
		if #_EnemyHeroes == 0 then return end
		if myHero.dead or Game.IsChatOpen() == true  or isEvading then return end
		OnVisionF()
		if GetOrbMode() == 'Combo' then
			Combo()
			
		end
	
		if GetOrbMode() == 'Harass' then
			Harass()
		end
	
		if GetOrbMode() == 'Clear' then
			LaneClear()
		end

		if GetOrbMode() == 'Lasthit' then
			LastHit()
		end
	
		if GetOrbMode() == 'Flee' then
			Flee()
		end
		end)
		GetOrbMode = function()
			if SagaOrb == 1 then
				if Sagacombo == 1 then
					return 'Combo'
				elseif Sagaharass == 2 then
					return 'Harass'
				elseif SagalastHit == 3 then
					return 'Lasthit'
				elseif SagalaneClear == 4 then
					return 'Clear'
				end
			elseif SagaOrb == 2 then
				SagaSDKModes = SDK.Orbwalker.Modes
				if SagaSDKModes[SagaSDKCombo] then
					return 'Combo'
				elseif SagaSDKModes[SagaSDKHarass] then
					return 'Harass'
				elseif SagaSDKModes[SagaSDKLaneClear] or SagaSDKModes[SagaSDKJungleClear] then
					return 'Clear'
				elseif SagaSDKModes[SagaSDKLastHit] then
					return 'Lasthit'
				elseif SagaSDKModes[SagaSDKFlee] then
					return 'Flee'
				end
			elseif SagaOrb == 3 then
				return GOS:GetMode()
			elseif SagaOrb == 4 then
				 return _G.gsoSDK.Orbwalker:GetMode()
			end
		 end
		
GetDistance2D = function(p1,p2)
    return sqrt((p2.x - p1.x)*(p2.x - p1.x) + (p2.y - p1.y)*(p2.y - p1.y))
end

local _OnWaypoint = {}
function OnWaypoint(unit)
	if _OnWaypoint[unit.networkID] == nil then _OnWaypoint[unit.networkID] = {pos = unit.posTo , speed = unit.ms, time = Game.Timer()} end
	if _OnWaypoint[unit.networkID].pos ~= unit.posTo then 
		-- print("OnWayPoint:"..unit.charName.." | "..math.floor(Game.Timer()))
		_OnWaypoint[unit.networkID] = {startPos = unit.pos, pos = unit.posTo , speed = unit.ms, time = Game.Timer()}
			DelayAction(function()
				local time = (Game.Timer() - _OnWaypoint[unit.networkID].time)
				local speed = GetDistance2D(_OnWaypoint[unit.networkID].startPos,unit.pos)/(Game.Timer() - _OnWaypoint[unit.networkID].time)
				if speed > 1250 and time > 0 and unit.posTo == _OnWaypoint[unit.networkID].pos and GetDistance(unit.pos,_OnWaypoint[unit.networkID].pos) > 200 then
					_OnWaypoint[unit.networkID].speed = GetDistance2D(_OnWaypoint[unit.networkID].startPos,unit.pos)/(Game.Timer() - _OnWaypoint[unit.networkID].time)
					-- print("OnDash: "..unit.charName)
				end
			end,0.05)
	end
	return _OnWaypoint[unit.networkID]
end

IsImmobileTarget = function(unit)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.name == "recall") and buff.count > 0 then
			return true
		end
	end
	return false	
end

GetMinionsinRangeCount = function(target,range)
	local inRadius =  {}
	
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if minion then
		if minion.team == 300 - myHero.team and minion.isTargetable and minion.visible and not minion.dead then
			if  GetDistance(target, minion) <= range then
				inRadius[myCounter] = minion
				myCounter = myCounter + 1
			end
		end
	end
	end
		myCounter = 1
	return #inRadius, inRadius
end

GetMinionsinRangeCountShadow = function(target,range)
	local inRadius =  {}
	
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if minion then
		if minion.team == 300 - myHero.team and minion.isTargetable and minion.visible and not minion.dead then
			if  GetDistance(target, minion) <= range then
				inRadius[myCounter] = minion
				myCounter = myCounter + 1
			end
		end
	end
	end
		myCounter = 1
	return #inRadius, inRadius
end

OnVision = function(unit)
    _OnVision[unit.networkID] = _OnVision[unit.networkID] == nil and {state = unit.visible, tick = GetTickCount(), pos = unit.pos} or _OnVision[unit.networkID]
    if _OnVision[unit.networkID].state == true and not unit.visible then
        _OnVision[unit.networkID].state = false
        _OnVision[unit.networkID].tick = GetTickCount()
    end
    if _OnVision[unit.networkID].state == false and unit.visible then
        _OnVision[unit.networkID].state = true
        _OnVision[unit.networkID].tick = GetTickCount()
    end
    return _OnVision[unit.networkID]
end

OnVisionF = function()
    if GetTickCount() - visionTick > 100 then
        for i = 1, TotalHeroes do
            OnVision(_EnemyHeroes[i])
        end
        visionTick = GetTickCount()
    end
end

GetPred = function(unit,speed,delay,sourcePosA)
	local speed = speed or math.huge
	local delay = delay or 0.25
	local sourcePos = sourcePosA or myHero.pos
	local unitSpeed = unit.ms
	if OnWaypoint(unit).speed > unitSpeed then unitSpeed = OnWaypoint(unit).speed end
	if OnVision(unit).state == false then
		local unitPos = unit.pos + Vector(unit.pos,unit.posTo):Normalized() * ((GetTickCount() - OnVision(unit).tick)/1000 * unitSpeed)
		local predPos = unitPos + Vector(unit.pos,unit.posTo):Normalized() * (unitSpeed * (delay + (GetDistance(sourcePos,unitPos)/speed)))
		if GetDistance(unit.pos,predPos) > GetDistance(unit.pos,unit.posTo) then predPos = unit.posTo end
		return predPos
	else
		if unitSpeed > unit.ms then
			local predPos = unit.pos + Vector(OnWaypoint(unit).startPos,unit.posTo):Normalized() * (unitSpeed * (delay + (GetDistance(sourcePos,unit.pos)/speed)))
			if GetDistance(unit.pos,predPos) > GetDistance(unit.pos,unit.posTo) then predPos = unit.posTo end
			return predPos
		elseif IsImmobileTarget(unit) then
			return unit.pos
		else
			return unit:GetPrediction(speed,delay)
		end
	end
end

CastQ = function(target)
	if Game.CanUseSpell(0) == 0 and castSpell.state == 0 then
        if target.pos:DistanceTo() < Q.range and (Game.Timer() - OnWaypoint(target).time < 0.15 or Game.Timer() - OnWaypoint(target).time > 1.0) then
            local qPred = GetPred(target,Q.speed,Q.delay + Game.Latency()/1000)
            CastSpell(HK_Q,qPred,Q.range + 200,250)
        end
	end
end

CastQS = function(target, shadowt)
	if Game.CanUseSpell(0) == 0 and castSpell.state == 0 then
        if target.pos:DistanceTo(shadowt) < Q.range and (Game.Timer() - OnWaypoint(target).time < 0.15 or Game.Timer() - OnWaypoint(target).time > 1.0) then
            local qPred = GetPred(target,Q.speed,Q.delay + Game.Latency()/1000, shadowt)
            CastSpell(HK_Q,qPred,Q.range + 200,250)
        end
	end
end

 CastW = function(target)
	if Game.CanUseSpell(1) == 0 and castSpell.state == 0 then
        if (Game.Timer() - OnWaypoint(target).time < 0.15 or Game.Timer() - OnWaypoint(target).time > 1.0) then
            local wPred = GetPred(target,W.speed,W.delay + Game.Latency()/1000)
			CastSpell(HK_W,wPred,W.range + 200,250)
			shadow = wPred
        end
	end
end

Combo = function()
    local target = GetTarget(Q.range + W.range)
    if target then
	SIGroup(target)
    if Saga.Combo.UseR:Value() and target.pos:DistanceTo() < R.range and Game.CanUseSpell(3) == 0  and ComboDamage(target) > target.health and myHero:GetSpellData(_R).toggleState == 0 then
		Control.CastSpell(HK_R,target)
		shadow2 = myHero.pos
	end

	
	if Saga.Combo.UseW:Value() and Game.CanUseSpell(0) == 0 and myHero:GetSpellData(_W).toggleState == 0 then
		if Game.CanUseSpell(0) ~= 0 and Game.CanUseSpell(2) ~= 0 then return end
		CastW(target)
	end
	
	if Saga.Combo.UseE:Value() and Game.CanUseSpell(2) == 0 then
		if (GetEnemiesinRangeCountShadow(shadow, 290) >= 1 and myHero:GetSpellData(_W).toggleState == 2)
		or GetEnemiesinRangeCount(myHero, 290) >= 1 then
			Control.CastSpell(HK_E)
		end
	end
	
	if Saga.Misc.gcw:Value() and Game.CanUseSpell(1) == 0 and myHero:GetSpellData(_W).toggleState == 2 and GetDistance(shadow,target.pos) < GetDistance(myHero.pos,target.pos) then
		if myHero:GetSpellData(_R).toggleState == 2 and GetDistance(shadow2,target.pos) < GetDistance(shadow,target.pos) then return end
		shadow = myHero.pos
		Control.CastSpell(HK_W)
	end

	if Game.CanUseSpell(0) == 0 and Saga.Combo.UseQ:Value() then
		if Game.CanUseSpell(1) == 0 and myHero:GetSpellData(_W).toggleState == 0 then return end
		
		if GetDistance(target.pos,shadow) >= GetDistance(target.pos,myHero.pos) then
			if GetDistance(target.pos,myHero.pos) <= Q.range then
				CastQ(target)
			end
		else
			if GetDistance(target.pos,shadow) <= Q.range then
				CastQS(target, shadow)
			end
		end
	end

	if Saga.Misc.gcr:Value() and Game.CanUseSpell(1) ~= 0 and Game.CanUseSpell(3) == 0 and myHero:GetSpellData(_R).toggleState == 2 and GetDistance(shadow2,target.pos) < GetDistance(myHero.pos,target.pos) then
		if myHero:GetSpellData(_W).toggleState == 2 and GetDistance(shadow,target.pos) < GetDistance(shadow2,target.pos) then return end
			shadow2 = myHero.pos
		Control.CastSpell(HK_R)
	end

	if Saga.Combo.UseQ:Value() and Game.CanUseSpell(0) == 0  and myHero:GetSpellData(_R).toggleState == 2 then
		if Game.CanUseSpell(3) == 0 and myHero:GetSpellData(_W).toggleState == 2 then return end
		
		if GetDistance(target.pos,shadow2) >= GetDistance(target.pos,myHero.pos) then
			if GetDistance(target.pos,myHero.pos) <= Q.range then
				CastQ(target)
			end
		else
			if GetDistance(target.pos,shadow2) <= Q.range then
				CastQS(target, shadow)
			end
		end
	end
	
	end
end

Harass = function()

	local target = GetTarget(Q.range + W.range)
	if target then
	if myHero.mana < Saga.Clear.mana:Value() * 2 then return end

	if  Saga.Harass.UseW:Value() and Game.CanUseSpell(1) == 0 and myHero:GetSpellData(_W).toggleState == 0 then
		if Game.CanUseSpell(0) ~= 0 and Game.CanUseSpell(2) == 0 then return end
		CastW(target)
	end
	if Saga.Harass.UseE:Value() and Game.CanUseSpell(2) == 0 then
		if (GetEnemiesinRangeCountShadow(shadow, 290) >= 1 and myHero:GetSpellData(_W).toggleState == 2)
		or GetEnemiesinRangeCount(myHero, 290) >= 1 then
			Control.CastSpell(HK_E)
		end
	end

	if Saga.Harass.UseQ:Value() and Game.CanUseSpell(0) == 0 then
		if Game.CanUseSpell(1) == 0 and myHero:GetSpellData(_W).toggleState == 0 then return end
		if GetDistance(target.pos,shadow) >= GetDistance(target.pos,myHero.pos) then
			if GetDistance(target.pos,myHero.pos) <= Q.range then
				CastQ(target)
			end
		else
			if GetDistance(target.pos,shadow) <= Q.range then
				CastQS(target, shadow)
			end
		end
	end
end
end

Flee = function()
	if Game.CanUseSpell(1) == 0 then
		local vec = Vector(myHero.pos):Extended(Vector(mousePos), W.range)
		Control.CastSpell(HK_W,vec)
	end
end

LaneClear = function()
	if myHero.mana < Saga.Clear.mana:Value() * 2 then return end
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if minion then
			if minion.team == 300 - myHero.team and minion.isTargetable and minion.visible and not minion.dead then
				if  Saga.Clear.UseW:Value() and Game.CanUseSpell(1) == 0 and GetMinionsinRangeCount(minion, 290) >= 3 and myHero:GetSpellData(_W).toggleState == 0 then
					CastW(minion)
				end
				if Saga.Clear.UseE:Value() and Game.CanUseSpell(2) == 0 then
					if (GetMinionsinRangeCountShadow(shadow, 290) >= 3 and myHero:GetSpellData(_W).toggleState == 2)
					or GetMinionsinRangeCount(myHero, 290) >= 3 then
						Control.CastSpell(HK_E)
					end
				end
				if  Saga.Clear.UseQ:Value() and Game.CanUseSpell(0) == 0 then
					if GetDistance(minion,shadow) >= GetDistance(minion.pos,myHero.pos) then
						if GetDistance(minion.pos,myHero.pos) <= Q.range then
							CastQS(minion,shadow)
						end
					else
						if GetDistance(minion.pos,shadow) <= Q.range then
							CastQ(minion)
						end
					end
				end
			end
			if minion.team == 300 then
				if  Saga.Clear.UseW:Value() and Game.CanUseSpell(1) == 0 and GetMinionsinRangeCount(minion.pos, 290) >= 1 and myHero:GetSpellData(_W).toggleState == 0 then
					CastW(minion)
				end
				if Saga.Clear.UseE:Value() and Game.CanUseSpell(2) == 0 then
					if GetMinionsinRangeCount(shadow, 290) >= 1 
					or GetMinionsinRangeCount(myHero, 290) >= 1 then
						Control.CastSpell(HK_E)
					end
				end
				if Saga.Clear.UseQ:Value() and Game.CanUseSpell(0) == 0 then
					if GetDistance(minion.pos,shadow) >= GetDistance(minion.pos,myHero.pos) then
						if GetDistance(minion.pos,myHero.pos) <= Q.range then
							CastQS(minion,shadow)
						end
					else
						if GetDistance(minion.pos,shadow) <= Q.range then
							CastQ(minion,myHero.pos)
						end
					end
				end
			end
		end
	end
end

LastHit = function()

	if myHero.mana < Saga.Clear.mana:Value() * 2 then return end
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if minion then
			if minion.isEnemy and minion.isTargetable and minion.visible and not minion.dead then
				if  Saga.Lasthit.UseQ:Value() and Game.CanUseSpell(0) == 0 and QDmg(minion) > minion.health then 
					CastSpell(HK_Q, minion, Q.Range, 250)
				end
			end
		end
	end
end

Saga_Menu = 
function()
	Saga = MenuElement({type = MENU, id = "Zed", name = "Saga's Zed: The Unseen Blade"})
	MenuElement({ id = "blank", type = SPACE ,name = "Version BETA 1.0.5"})
	--Combo
    Saga:MenuElement({id = "Combo", name = "Combo", type = MENU})
    Saga.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	Saga.Combo:MenuElement({id = "UseW", name = "W", value = true})
    Saga.Combo:MenuElement({id = "UseE", name = "E", value = true})
    Saga.Combo:MenuElement({id = "UseR", name = "R", value = true})
	Saga.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})

    Saga:MenuElement({id = "Harass", name = "Harass", type = MENU})
	Saga.Harass:MenuElement({id = "UseQ", name = "Q", value = true})
	Saga.Harass:MenuElement({id = "UseW", name = "W", value = true})
	Saga.Harass:MenuElement({id = "UseE", name = "E", value = true})
	
	Saga:MenuElement({id = "Clear", name = "Clear", type = MENU})
	Saga.Clear:MenuElement({id = "UseQ", name = "Q", value = true})
	Saga.Clear:MenuElement({id = "UseW", name = "W", value = true})
	Saga.Clear:MenuElement({id = "UseE", name = "W", value = true})
	

    Saga:MenuElement({id = "Lasthit", name = "Lasthit", type = MENU})
	Saga.Lasthit:MenuElement({id = "UseQ", name = "Q", value = true})

	Saga:MenuElement({id = "items", name = "UseItems", type = MENU})
	Saga.items:MenuElement({id = "bg", name = "Use Cutlass/Botrk", value = true})
	Saga.items:MenuElement({id = "tm", name = "Tiamat/Titcan/Ravenous", value = true})
	Saga.items:MenuElement({id = "yg", name = "Yoomus GhostBlade", value = true})
	Saga.items:MenuElement({id = "ig", name = "Ignite", value = true})


    Saga:MenuElement({id = "Misc", name = "R Settings", type = MENU})
	Saga.Misc:MenuElement({id = "gcw", name = "Use W2 Gap Close", value = true})
	Saga.Misc:MenuElement({id = "gcr", name = "Use R2 Gap Close", value = true})
	Saga.Clear:MenuElement({id = "mana", name = "Min: energy", value = 35, min = 0, max = 100})


    Saga:MenuElement({id = "Rate", name = "Recache Rate", type = MENU})
	Saga.Rate:MenuElement({id = "champion", name = "Value", value = 30, min = 1, max = 120, step = 1})

    Saga:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
    Saga.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    Saga.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    Saga.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    Saga.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})

    Saga.Drawings:MenuElement({id = "E", name = "Draw  E range", type = MENU})
    Saga.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    Saga.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    Saga.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})

    Saga.Drawings:MenuElement({id = "W", name = "Draw W range", type = MENU})
    Saga.Drawings.W:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    Saga.Drawings.W:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    Saga.Drawings.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
    
    Saga.Drawings:MenuElement({id = "R", name = "Draw R range", type = MENU})
    Saga.Drawings.R:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    Saga.Drawings.R:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    Saga.Drawings.R:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
end
