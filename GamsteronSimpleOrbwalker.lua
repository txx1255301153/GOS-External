local START_TIME = _G.Game.Timer() + 5

-- MENU --------------------------------------------------------------------------------------------------------------------------------------------------------
local MENU_MAIN = _G.MenuElement({name = "Gamsteron " .. _G.myHero.charName, id = "gamsteron" .. _G.myHero.charName, type = _G.MENU })
local MENU_CURSOR = MENU_MAIN:MenuElement({name = "Cursor Pos",  id = "cursor", type = _G.MENU})
MENU_CURSOR:MenuElement({name = "Enabled",  id = "enabled", value = true})
MENU_CURSOR:MenuElement({name = "Color",  id = "color", color = _G.Draw.Color(255, 153, 0, 76)})
MENU_CURSOR:MenuElement({name = "Width",  id = "width", value = 3, min = 1, max = 10})
MENU_CURSOR:MenuElement({name = "Radius",  id = "radius", value = 150, min = 1, max = 300})
local MENU_ORBWALKER = MENU_MAIN:MenuElement({name = "Orbwalker", id = "orb", type = _G.MENU })
MENU_ORBWALKER:MenuElement({name = "Latency", id = "latency", value = 50, min = 1, max = 120})
MENU_ORBWALKER:MenuElement({name = "Player Attack Only Click", id = "aamoveclick", key = string.byte("U")})
MENU_ORBWALKER:MenuElement({name = "Keys", id = "keys", type = _G.MENU})
MENU_ORBWALKER.keys:MenuElement({name = "Combo Key", id = "combo", key = string.byte(" ")})
MENU_ORBWALKER.keys:MenuElement({name = "LastHit Key", id = "lasthit", key = string.byte("X")})
MENU_ORBWALKER.keys:MenuElement({name = "Clear Key", id = "clear", key = string.byte("V")})
MENU_ORBWALKER:MenuElement({name = "MyHero Attack Range", id = "me", type = _G.MENU})
MENU_ORBWALKER.me:MenuElement({name = "Enabled",  id = "enabled", value = true})
MENU_ORBWALKER.me:MenuElement({name = "Color",  id = "color", color = _G.Draw.Color(150, 49, 210, 0)})
MENU_ORBWALKER.me:MenuElement({name = "Width",  id = "width", value = 1, min = 1, max = 10})
MENU_ORBWALKER:MenuElement({name = "Enemy Attack Range", id = "he", type = _G.MENU})
MENU_ORBWALKER.he:MenuElement({name = "Enabled",  id = "enabled", value = true})
MENU_ORBWALKER.he:MenuElement({name = "Color",  id = "color", color = _G.Draw.Color(150, 255, 0, 0)})
MENU_ORBWALKER.he:MenuElement({name = "Width",  id = "width", value = 1, min = 1, max = 10})
local MENU_CHAMPION
if _G.myHero.charName == "KogMaw" then
    MENU_CHAMPION = MENU_MAIN:MenuElement({name = _G.myHero.charName, id = "champion", type = _G.MENU })
    MENU_CHAMPION:MenuElement({name = "W settings", id = "wset", type = _G.MENU })
    MENU_CHAMPION.wset:MenuElement({id = "combo", name = "Combo", value = true})
end

-- UTILS -------------------------------------------------------------------------------------------------------------------------------------------------------
local IMMORTAL_BUFFS = {
    ["zhonyasringshield"] = true,
    ["JudicatorIntervention"] = true,
    ["TaricR"] = true,
    ["kindredrnodeathbuff"] = true,
    ["ChronoShift"] = true,
    ["chronorevive"] = true,
    ["UndyingRage"] = true,
    ["JaxCounterStrike"] = true,
    ["FioraW"] = true,
    ["aatroxpassivedeath"] = true,
    ["VladimirSanguinePool"] = true,
    ["KogMawIcathianSurprise"] = true,
    ["KarthusDeathDefiedBuff"] = true
}
local function IsImmortal(unit, jaxE)
    local hp = 100*(unit.health/unit.maxHealth)
    IMMORTAL_BUFFS["JaxCounterStrike"] = jaxE
    IMMORTAL_BUFFS["kindredrnodeathbuff"] = hp < 10
    IMMORTAL_BUFFS["UndyingRage"] = hp < 15
    IMMORTAL_BUFFS["ChronoShift"] = hp < 15
    IMMORTAL_BUFFS["chronorevive"] = hp < 15
    for i = 0, unit.buffCount do
        local buff = unit:GetBuff(i)
        if buff and buff.count > 0 and IMMORTAL_BUFFS[buff.name] then
            return true
        end
    end
    return false
end
local function IsInRange(v1, v2, range)
    local dx = v1.x - v2.x
    local dy = (v1.z or v1.y) - (v2.z or v2.y)
    return dx * dx + dy * dy <= range * range
end

-- CURSOR ------------------------------------------------------------------------------------------------------------------------------------------------------
local CURSOR_READY = true
local CURSOR_POS = _G.cursorPos
local CURSOR_WORK = nil
local CURSOR_SETTIME = 0
local function SetCursor(work)
    CURSOR_READY = false -- champion can't use spells if ready == false, if it's true cursor logic works
    CURSOR_POS = _G.cursorPos -- work is not done yet so we save correct cursor pos (not on cast pos)
    CURSOR_WORK = work -- setcursor to cast pos + cast spell or attack
    CURSOR_SETTIME = _G.Game.Timer() + 0.07 -- set cursor pos delay for work done
    -- STEP 1
    CURSOR_WORK() -- do work 1x
end
_G.Callback.Add("Draw", function()
    if _G.Game.Timer() < 30 or _G.Game.Timer() < START_TIME then return end
    if not CURSOR_READY then
        if CURSOR_WORK ~= nil then
            -- STEP 2
            CURSOR_WORK() -- do work 2x
            CURSOR_WORK = nil
        -- STEP 3
        elseif _G.Game.Timer() > CURSOR_SETTIME then
            _G.Control.SetCursorPos(CURSOR_POS.x, CURSOR_POS.y)
            if IsInRange(CURSOR_POS, _G.cursorPos, 120) then
                CURSOR_READY = true
            end
        end
    end
    if MENU_CURSOR.enabled:Value() then
        _G.Draw.Circle(_G.mousePos, MENU_CURSOR.radius:Value(), MENU_CURSOR.width:Value(), MENU_CURSOR.color:Value())
    end
end)

-- ORBWALKER ---------------------------------------------------------------------------------------------------------------------------------------------------
local MOVE_TIMER = 0
local ATTACK_TIMER = 0
local ATTACK_ENDTIME = 0
local ATTACK_SERVER_START = 0
local ATTACK_IS_BLINDED = false

local function IsBeforeAttack(multipier)
    return _G.Game.Timer() > ATTACK_TIMER + multipier * _G.myHero.attackData.animationTime
end

local function PreAttack()
    return
end

local function Attack(unit)
    local attackKey = MENU_ORBWALKER.aamoveclick:Key()
    local unitPos = Vector(unit.pos.x, unit.pos.y + 50, unit.pos.z):To2D()
    PreAttack()
    SetCursor(function()
        _G.Control.SetCursorPos(unitPos.x, unitPos.y)
        _G.Control.KeyDown(attackKey)
        _G.Control.KeyUp(attackKey)
    end)
    MOVE_TIMER = 0 -- reset move timer
    ATTACK_TIMER = _G.Game.Timer() -- attack is sent with delay (+-0.025)
end

local function Move()
    _G.Control.mouse_event(MOUSEEVENTF_RIGHTDOWN)
    _G.Control.mouse_event(MOUSEEVENTF_RIGHTUP)
    MOVE_TIMER = _G.Game.Timer() + 0.125
end

local function CanAttack()
    if ATTACK_IS_BLINDED then return false end
    if ATTACK_ENDTIME > ATTACK_TIMER then
        if _G.Game.Timer() >= ATTACK_SERVER_START + _G.myHero.attackData.animationTime - 0.05 - (MENU_ORBWALKER.latency:Value() * 0.001) then return true end
        return false
    end
    if _G.Game.Timer() < ATTACK_TIMER + 0.2 then
        return false
    end
    return true
end

local function CanMove()
    if _G.myHero.pos:DistanceTo(_G.mousePos) < 120 then
        return false
    end
    if ATTACK_ENDTIME > ATTACK_TIMER then
        if _G.Game.Timer() >= ATTACK_SERVER_START + _G.myHero.attackData.windUpTime - (MENU_ORBWALKER.latency:Value() * 0.0005) then return true end
        return false
    end
    if _G.Game.Timer() < ATTACK_TIMER + 0.2 then
        return false
    end
    return true
end

local function GetComboTarget()
    local enemylist = {}
    for i = 1, _G.Game.HeroCount() do
        local enemy = _G.Game.Hero(i)
        if enemy and enemy.team ~= _G.myHero.team and enemy.valid and (not enemy.dead) and enemy.visible and enemy.isTargetable and (not IsImmortal(enemy,true)) and enemy.pos:DistanceTo(_G.myHero.pos) < _G.myHero.range + _G.myHero.boundingRadius + enemy.boundingRadius - 35 then
            _G.table.insert(enemylist, enemy)
        end
    end
    if #enemylist == 0 then return nil end
    _G.table.sort(enemylist, function(a, b) return a.health-(a.totalDamage*3)-(a.attackSpeed*200)-(a.ap*2) < b.health-(b.totalDamage*3)-(b.attackSpeed*200)-(b.ap*2) end)
    return enemylist[1]
end

_G.Callback.Add("Tick", function()
    if _G.Game.Timer() < 30 or _G.Game.Timer() < START_TIME then return end
    -- myHero buffs
    local isblinded = false
    for i = 0, _G.myHero.buffCount do
        local buff = _G.myHero:GetBuff(i)
        if buff and buff.count > 0 and buff.name:lower() == "blindingdart" then
            isblinded = true
            break
        end
    end
    ATTACK_IS_BLINDED = isblinded
end)

_G.Callback.Add("Draw", function()
    if _G.Game.Timer() < 30 or _G.Game.Timer() < START_TIME then return end
    local spell = myHero.activeSpell
    if spell and spell.valid and (spell.castEndTime > ATTACK_ENDTIME) and (not myHero.isChanneling) then
        ATTACK_ENDTIME = spell.castEndTime
        ATTACK_SERVER_START = spell.startTime
    end
    if _G.Game.IsChatOpen() or (_G.ExtLibEvade and _G.ExtLibEvade.Evading) or _G.JustEvade or (not CURSOR_READY) or (not _G.Game.IsOnTop()) then
        return
    end
    if MENU_ORBWALKER.keys.combo:Value() then
        local target = GetComboTarget()
        if CanAttack() and target and target.pos:ToScreen().onScreen then
            Attack(target)
        elseif CanMove() and _G.Game.Timer() > MOVE_TIMER then
            Move()
        end
    end
end)

_G.Callback.Add("Draw", function()
    if _G.Game.Timer() < 30 or _G.Game.Timer() < START_TIME then return end
    if MENU_ORBWALKER.me.enabled:Value() and _G.myHero.pos:ToScreen().onScreen then
        _G.Draw.Circle(_G.myHero.pos, _G.myHero.range + _G.myHero.boundingRadius + 35, MENU_ORBWALKER.me.width:Value(), MENU_ORBWALKER.me.color:Value())
    end
    if MENU_ORBWALKER.he.enabled:Value() then
        for i = 1, _G.Game.HeroCount() do
            local enemy = _G.Game.Hero(i)
            if enemy and enemy.visible and enemy.team ~= _G.myHero.team and enemy.valid and (not enemy.dead) then
                _G.Draw.Circle(enemy.pos, enemy.range + enemy.boundingRadius + _G.myHero.boundingRadius, MENU_ORBWALKER.he.width:Value(), MENU_ORBWALKER.he.color:Value())
            end
        end
    end
end)

-- KOGMAW ------------------------------------------------------------------------------------------------------------------------------------------------------
if _G.myHero.charName == "KogMaw" then
    local function CastW()
        if MENU_ORBWALKER.keys.combo:Value() and MENU_CHAMPION.wset.combo:Value() and _G.Game.CanUseSpell(_W) == 0 then
            local isTarget = false
            for i = 1, _G.Game.HeroCount() do
                local enemy = _G.Game.Hero(i)
                if enemy and enemy.team ~= _G.myHero.team and enemy.valid and (not enemy.dead) and enemy.visible and enemy.isTargetable and (not IsImmortal(enemy,true)) and enemy.pos:DistanceTo(_G.myHero.pos) < 610 + (20 * _G.myHero:GetSpellData(_W).level) + myHero.boundingRadius + enemy.boundingRadius - 35 then
                    isTarget = true
                    break
                end
            end
            if isTarget then
                _G.Control.CastSpell(HK_W)
            end
        end
    end
    PreAttack = function() CastW() end
    _G.Callback.Add("Tick", function()
        if _G.Game.Timer() < 30 or _G.Game.Timer() < START_TIME then return end
        if CanMove() and IsBeforeAttack(0.55) then CastW() end
    end)
end
