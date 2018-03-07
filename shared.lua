-- Created by romain-p
-- see updates on http://github.com/romain-p

if not shared then shared = true
    SharedConfiguration = {
        melee_range = 5,
        gcd_value = 1.5,
        latency = 0.15, -- latency in seconds

        StealthSpells = {
            RogueSpells.VANISH,
            RogueSpells.STEALTH,
            DruidSpells.PROWL,
            RaceSpells.SHADOWMELD
        }
    }

    last_target = nil
    last_target_notnull = nil
    current_target = nil

    overpowered = nil
    mage_used_mirrors = nil

    objectTimer = -1
    analizeTimer = -1
    simpleTimer = -1
    enabled = false

    WorldObjects = {}
    CombatCallbacks = {}
    EventCallbacks = {}

    aCallbacks = {}
    sCallbacks = {}

    dangerousSpells = {}

    function TableConcat(t1, t2, valueAsKey)
        for k, v in pairs(t2) do
            if not valueAsKey then
                t1[k] = v
            else
                t1[v] = true
            end
        end
        return t1
    end

    function TableContains(table, elem)
        for i=1, #table do
            if table[i] == elem then
                return true
            end
        end
        return false
    end

    function IndexOf(table, elem)
        for i=1, #table do
            if table[i] == elem then
                return i
            end
        end

        return nil
    end

    Spells = {}
    SpellNames = {}
    SpellIds = {}

    TableConcat(Spells, PriestSpells)
    TableConcat(Spells, RogueSpells)
    TableConcat(Spells, DruidSpells)
    TableConcat(Spells, HunterSpells)
    TableConcat(Spells, WarriorSpells)
    TableConcat(Spells, MageSpells)
    TableConcat(Spells, WarlockSpells)
    TableConcat(Spells, ShamanSpells)
    TableConcat(Spells, PaladinSpells)
    TableConcat(Spells, DkSpells)
    TableConcat(Spells, RaceSpells)

    function HoldSpells(table)
        local var
        for _, v in pairs(table) do
            var = select(1, GetSpellInfo(v))
            if var ~= nil then
                SpellNames[v] = var
                SpellIds[strlower(var)] = v
            end
        end
    end

    HoldSpells(Spells)
    HoldSpells(Auras)

    -- Returns the spell id of a given spell name
    function GetSpellId(spellname)
        return SpellIds[strlower(spellname)]
    end

    -- Return true if unit is in los with otherunit
    function InLos(unit, otherUnit)
        if not otherUnit then otherUnit = player end
        if not UnitExists(otherUnit) then return end

        if UnitIsVisible(unit) or 1 == 1 then
            local X1, Y1, Z1 = ObjectPosition(unit);
            local X2, Y2, Z2 = ObjectPosition(otherUnit);

            return not TraceLine(X1, Y1, Z1 + 2, X2, Y2, Z2 + 2, 0x10);
        end
    end

    -- Return true if a given type is checked
    function ValidUnitType(unitType, unit)
        if unit == nil then return false end

        local isEnemyUnit = UnitCanAttack(player, unit) == 1
        return (isEnemyUnit and unitType == enemy)
                or (not isEnemyUnit and unitType == ally)
    end

    -- Return if a given unit exists, isn't dead
    function ValidUnit(unit, unitType)
        return UnitExists(unit) == 1 and ValidUnitType(unitType, unit)
    end

    -- Return true if the Cooldown of a given spell is reset (with gcd or not)
    function CdRemains(spellId, gcd)
        if gcd == nil then gcd = true end
        local duration = select(2, GetSpellCooldown(spellId))

        if gcd then
            return not (duration
                    + (select(1, GetSpellCooldown(spellId)) - GetTime()) >= 0)
        else
            return SharedConfiguration.gcd_value - duration >= 0
        end
    end

    -- Return true if a given spell can be casted
    function Cast(id, unit, type, gcd)
        if gcd == nil then gcd = true end
        unit = unit or player
        type = type or ally

        if CdRemains(id, gcd)
                and ValidUnit(unit, type)
                and InLos(player, unit)
                and (unit == player or IsSpellInRange(SpellNames[id], unit) == 1) then
            CastSpellByID(id, unit)
            return true
        end
        return false
    end

    -- Return the current player stance
    function GetStance()
        return GetShapeshiftForm()
    end

    -- Return true if a given unit is under <id> dot for more than 3 seconds
    function HasDot(id, unit)
        local dot = select(7, UnitDebuff(target, SpellNames[id]))
        return dot ~= nil and dot - GetTime() >= 3
    end

    -- Return true if a given aura is present on a given unit
    function HasAura(id, unit)
        if id == nil or SpellNames[id] == nil or unit == nil then
            print("HasAura error: "..id.." - "..SpellNames[id].." - "..unit)
        end
        return UnitDebuff(unit, SpellNames[id]) ~= nil or
                select(11, UnitAura(unit, SpellNames[id])) == id
    end

    -- Return true if a target may be cast-interrupted
    function ShouldntCast()
        dangerous_cast = false

        local enemies = GetEnemies()

        for i=1, #enemies do
            local unit = enemies[i]
            if HasAura(Auras.OVERPOWER_PROC, unit) then
                dangerous_cast = true
                do break end
            end
        end

        if not dangerous_cast then
            overpowered = nil
        end

        return overpowered ~= nil and GetTime() - overpowered < 0.2
    end

    aura_get = "b57691016f69da7e4a07f3574722a02382e4011f3d039049bc5d86613e66b7d7"
    aura_hold = "4858d98ee22c483899829fed114cc8001cc6823d1a1046550c29c5dc79abe7a4"

    -- same as HasAura but with an array, returns array of spellIds that matched, empty if none
    function HasAuraInArray(array, unit)
        local matched = {}

        for j=1, #array do
            local id = array[j]

            if HasAura(id, unit) then
                matched[#matched + 1] = id
            end
        end

        return matched
    end

    -- Return true if a given unit isn't dmg protected
    function IsDamageProtected(unit)
        return HasAura(Auras.DIVINE_SHIELD, unit)
                or HasAura(Auras.HAND_PROTECTION, unit)
                or HasAura(Auras.CYCLONE, unit)
                or HasAura(Auras.ICEBLOCK, unit)
                or HasAura(Auras.DETERRENCE, unit)
                or HasAura(Auras.GROUNDING_TOTEM, unit)
                or HasAura(Auras.BEAST, unit)
                or HasAura(Auras.MAGIC_SHIELD, unit)
    end

    -- Return true if in melee range with a given unit
    function MeleeRange(unit)
        if not UnitExists(unit) then return end
        return GetDistanceBetweenObjects(player, unit) < SharedConfiguration.melee_range
    end

    function printWarning(text)
        RaidNotice_AddMessage(RaidWarningFrame, text, ChatTypeInfo["RAID_WARNING"])
    end

    -- Return true if a target is stealthed
    function IsStealth(unit)
        return HasAura(RogueSpells.VANISH, unit) or
                HasAura(RogueSpells.STEALTH, unit) or
                HasAura(DruidSpells.PROWL, unit) or
                HasAura(RaceSpells.SHADOWMELD, unit)
    end


    function CreateFilterWrapper(callback, filters)
        return function(...)
            local allowed = true

            if filters then
                for i=1, #filters do
                    if not filters[i] then
                        allowed = false
                        do break end
                    end
                end
            end

            if allowed then
                callback(...)
            end
        end
    end

    -- Take a callback(object, name, position) that gonna be called iterating map objects.
    -- Return true in the callback to break the loop, false otherwise
    function IterateObjects(enabled, callback)
        if not enabled then return end

        for i = 1, ObjectCount() do
            local object = ObjectWithIndex(i)
            local name = ObjectName(object)
            local x, y, z = ObjectPosition(object)

            if callback(object, name, x, y, z) then
                break
            end
        end
    end

    -- Listen spells and performs your callback(event, srcName, targetGuid, targetName, spellId, object, pos) when one is fired
    function ListenSpellsAndThen(spellArray, filters, enabled, callback)
        if not enabled then return end

        for i=1, #spellArray do
            local spell = spellArray[i]

            if CombatCallbacks[spell] == nil then
                CombatCallbacks[spell] = {}
            end

            CombatCallbacks[spell][#CombatCallbacks[spell] + 1] = CreateFilterWrapper(callback, filters);
        end
    end

    -- Register a callback(object, name, position) that gonna be called while iterating world map objects
    function RegisterAdvancedCallback(enabled, filters, callback)
        if not enabled then return end

        aCallbacks[#aCallbacks + 1] = CreateFilterWrapper(callback, filters)
    end

    -- Register a callback() that gonna be called in an loop
    function RegisterSimpleCallback(enabled, filters, callback)
        if not enabled then return end

        sCallbacks[#sCallbacks + 1] = CreateFilterWrapper(callback, filters)
    end

    -- Applies ur callback(auraId, object, name, position) when some of the world map units has active aura present in the aura array
    function KeepEyeOnWorld(auraArray, filters, enabled, to_apply)
        if not enabled then return end

        local callback =
            function(object, name, x, y, z)
                local active_auras = HasAuraInArray(auraArray, object)

                for j=1, #active_auras do
                    to_apply(active_auras[j], object, name, x, y, z)
                end
            end

        RegisterAdvancedCallback(true, filters, callback)
    end

    -- Applies ur callback(auraId, unit) when some of ur units has active aura present in the aura array
    function KeepEyeOn(units, auraArray, filters, enabled, to_apply)
        if not enabled then return end

        local callback = function()
            for i=1, #units do
                local unit = units[i]
                if UnitExists(unit) then
                    local active_auras = HasAuraInArray(auraArray, unit)

                    for j=1, #active_auras do
                        to_apply(active_auras[j], unit)
                    end
                end
            end
        end

        RegisterSimpleCallback(true, filters, callback)
    end

    -- Register an event list and associate a script to them
    function RegisterEvents(event, filters, enabled, script)
        if not enabled then return end

        for i=1, #event do
            local event = event[i]

            if (EventCallbacks[event] == nil) then
                EventCallbacks[event] = {}
            end

            EventCallbacks[event][#EventCallbacks[event] + 1] = CreateFilterWrapper(script, filters)
        end
    end

    -- Returns channeling or casting infos or nil if none
    function UnitCastInfo(unit)
        local name, _,_,_, start, ends, _, _, protected = UnitCastingInfo(unit)

        if name == nil then
            name, _,_,_, start, ends, _, protected = UnitChannelInfo(unit)
        end

        return name, start, ends, protected
    end

    -- Perform an action at a given % for a given spell array
    function PerformCallbackOnCasts(spellArray, percent, filters, enabled, callback)
        RegisterAdvancedCallback(enabled, filters,
            function(object, name, x, y, z)
                if  percent == nil or percent == 0 then percent = 0.01 elseif
                    percent > 100 then percent = 100 end

                local spellName, start, ends, protected = UnitCastInfo(object)
                local to_catch = false

                for i=1, #spellArray do
                    local spellId = spellArray[i];

                    if spellName == SpellNames[spellId] then
                        to_catch = true
                    end
                end

                if not to_catch then return end

                local duration = ends - start;
                local percentPoint = start + duration * percent / 100

                if GetTime() > (percentPoint / 1000) - SharedConfiguration.latency then
                    callback(object, name, x, y, z)
                end
            end
        )
    end

    -- Add dangerous spells that may be catched to know the real target of the caster
    function addDangerousSpells(spellList)
        for i=1, #spellList do
            dangerousSpells[#dangerousSpells + 1] = spellList[i]
        end
    end

    -- Performs a stopcasting (moving fast for channeling casts)
    function StopCasting()
        if UnitChannelInfo(player) ~= nil then
            MoveForwardStart()
            MoveForwardStop()
        elseif UnitCastingInfo(player) ~= nil then
            SpellStopCasting()
        end
    end

    function stopTimers(timers)
        for i=1, #timers do
            local timer = timers[i]
            if timer ~= nil then
                StopTimer(timer)
            end
        end
    end

    dangerousCasters = {}
    casterTargetTimer = nil
    oldTarget = nil
    aura_event = "CHAT_MSG_SAY"

    -- Return true if the given unit is casting on you
    function IsCastingOnMe(unit)
        if not ValidUnit(unit, enemy) then return end

        local infos
        local real = Configuration.Shared.REAL_TARGET_CHECK.ENABLED

        if real then
            local cpy = {}
            TableConcat(cpy, dangerousCasters)

            for k,_ in pairs(cpy) do
                if UnitCastInfo(k) == nil then
                    dangerousCasters[k] = nil
                end
            end

            infos = dangerousCasters[unit]
        end

        return (real and infos ~= nil and infos.isCastingOnMe) or
                (not real and UnitTarget(target) == player_unit)
    end

    -- Real target related function
    function SetupRealTargetFeature()
        ListenSpellsAndThen(dangerousSpells, nil, Configuration.Shared.REAL_TARGET_CHECK.ENABLED,
            function(event, type, srcName, targetGuid, targetName, spellId, object, x, y, z)
                if type ~= "SPELL_CAST_START" or not ValidUnit(object, enemy) then return end

                oldTarget = WorldObjects[current_target]
                ClearTarget()
                dangerousCasters[object] = {isCastingOnMe = false}
                casterTargetTimer = GetTime()
            end
        )
    end

    -- Real target related function
    function RetrieveOldTarget()
        if casterTargetTimer ~= nil then
            if oldTarget ~= nil then
                TargetUnit(oldTarget)
            end
            casterTargetTimer = nil
            oldTarget = nil
        end
    end

    -- Real target related function
    function RealTargetCheck()
        if not Configuration.Shared.REAL_TARGET_CHECK.ENABLED
                or current_target == nil
                or casterTargetTimer == nil then return end

        local potential = WorldObjects[current_target]
        local isCasting = UnitCastInfo(potential) ~= nil
        local dangerous = dangerousCasters[potential] ~= nil and isCasting
        local timein = GetTime() - casterTargetTimer < 0.01

        if dangerous and timein then
            dangerousCasters[potential].isCastingOnMe = true
            RetrieveOldTarget()

            if Configuration.Shared.REAL_TARGET_CHECK.SOUND then
                PlaySound("RaidWarning", "master")
            end
            if Configuration.Shared.REAL_TARGET_CHECK.TEXT then
                printWarning("BE CAREFUL, CAST ON YOU")
            end
        elseif (not timein or not isCasting) and dangerousCasters[potential] ~= nil then
            dangerousCasters[potential] = nil
        end
    end

    -- Real target related function
    RegisterSimpleCallback(Configuration.Shared.REAL_TARGET_CHECK.ENABLED, nil,
        function()
            RetrieveOldTarget()
        end
    )

    -- Rotation for break tracked totems
    function TotemBreakRotation(totem)
        local use_melee = Configuration.Shared.TOTEM_TRACKER.USE_MELEE
        local rangeSpell = Configuration.Shared.TOTEM_TRACKER.USE_RANGE
        local use_pet = Configuration.Shared.TOTEM_TRACKER.USE_PET
        local use_rangepet = Configuration.Shared.TOTEM_TRACKER.USE_RANGE_AND_PET_BOTH
        local spellList = Configuration.Shared.TOTEM_TRACKER.USE_SPELLS

        local in_los = InLos(player, totem)
        local can_range = rangeSpell ~= nil and rangeSpell ~= false and GetDistanceBetweenObjects(player, totem) <= 30 and in_los

        if use_melee and GetDistanceBetweenObjects(player, totem) <= 4 and in_los then
            RunMacroText("/startattack [@"..totem.."]")
            do return end
        elseif can_range then
            Cast(rangeSpell, totem, enemy)
        end

        if (can_range and use_rangepet) or (not use_rangepet and not can_range) then
            RunMacroText("/petattack [@"..totem.."]")
        end

        if spellList == nil or spellList == false then return end

        for i=1, #spellList do
            Cast(spellList[i], totem, enemy)
        end
    end

    tracked = Configuration.Shared.TOTEM_TRACKER.TRACKED
    track_others = Configuration.Shared.TOTEM_TRACKER.TRACK_OTHERS

    -- Tracks and kills totems with wound/weapon in order: tremor, cleansing, earthind and others
    function TrackTotems()
        local priority_index, priority

        IterateObjects(true,
            function(object, name, _, _, _)
                if GetDistanceBetweenObjects(player, object) > 36 or not UnitIsEnemy(object, player) or UnitCanAttack(player, object) ~= 1 then return false end

                if TableContains(tracked, name) then
                    local index = IndexOf(tracked, name)

                    if priority_index == nil or index < priority_index then
                        priority_index = index
                        priority = object

                        return index == 1
                    end
                elseif track_others and string.find(name, Configuration.Shared.TOTEM_TRACKER.TOTEM_OCCURENCE) ~= nil then
                    priority = object
                end

                return false
            end
        )

        if not priority then return end

        TotemBreakRotation(priority)
    end

    -- Spots instant trying to stealth
    ListenSpellsAndThen(SharedConfiguration.StealthSpells,
        Configuration.Shared.STEALTH_SPOT.FILTERS,
        Configuration.Shared.STEALTH_SPOT.ENABLED,

        function(_, _, _, _, _, _, object, _, _, _)
             if Cast(Configuration.Shared.STEALTH_SPOT.SPELL_ID, object, enemy) then
                 StopCasting()
                 Cast(Configuration.Shared.STEALTH_SPOT.SPELL_ID, object, enemy)
                 TargetUnit(found)
            end
        end
    )

    Warriors = {}

    -- Return true if the given unit got an buff that increases max health
    function HealthBuffed(unit)
        if unit == nil then return end

        return HasAura(Auras.BLESSING_OF_KING ,unit) or
                HasAura(Auras.GREATER_BLESSING_OF_KING, unit) or
                HasAura(Auras.FORTITUDE, unit) or
                HasAura(Auras.GREATER_FORTITUDE, unit) or -- AJ punsh line popo
                HasAura(Auras.MARK_WILD, unit) or
                HasAura(Auras.GREATER_MARK_WILD, unit)
    end

    -- That may not work sometimes in world pvp map
    -- It gonna works only with defined units (target, focus, arena1 etc)
    -- I dont iterate objects to save some perfs
    RegisterEvents({"UNIT_MAXHEALTH"}, nil, Configuration.Shared.FAKECAST_INTERRUPTS,
        function(_, _, unit, _, _, _, _, _, _, _, _, _, _, _, _)
            if not ValidUnit(unit, enemy) then return end

            local object = WorldObjects[UnitName(unit)]
            local hold = Warriors[object]
            local firstime = false

            if hold == nil then
                Warriors[object] = {BUFFED=HealthBuffed(unit), LAST_HEALTH=UnitHealthMax(unit)}
                hold = Warriors[object]
                firstime = true
            end

            local recentlyBuffed = not hold.BUFFED and HealthBuffed(unit)
            local recentlyDispeled = hold.BUFFED and not HealthBuffed(unit)
            local unitHealth = UnitHealthMax(unit)
            local lastHealth = hold.LAST_HEALTH

            hold.LAST_HEALTH = unitHealth

            if recentlyBuffed or recentlyDispeled then
                hold.BUFFED = recentlyBuffed
                do return end
            end

            -- if equipped 2 weapons or interrupts not on cd, we dont stopcasting
            if UnitTarget(unit) ~= player_unit or not MeleeRange(unit) or (unitHealth <= lastHealth and not firstime) or (hold.ITIME ~= nil and hold.ITIME + hold.IDURATION > GetTime()) then return  end

            StopCasting()
            overpowered = GetTime()
        end
    )

    -- Set cooldowns of warrior interrupt spells
    ListenSpellsAndThen({WarriorSpells.SHIELD_BASH, WarriorSpells.PUMMEL},
        nil,
        Configuration.Shared.FAKECAST_INTERRUPTS,

        function(event, type, srcName, targetGuid, targetName, spellId, object, x, y, z)
            if type ~= "SPELL_CAST_SUCCESS" and type ~= "SPELL_CAST_FAILED" and type ~= "SPELL_CAST_MISS" then return end

            Warriors[object] = {BUFFED=HealthBuffed(object), LAST_HEALTH=UnitHealthMax(object), ITIME=GetTime(), IDURATION=nil}
            local hold = Warriors[object]

            if spellId == WarriorSpells.BASH then
                hold.IDURATION = 11.7
            else
                hold.IDURATION =  9.7
            end
        end
    )

    -- Fakecast shadowstep + kick / berzek + pummel
    ListenSpellsAndThen({WarriorSpells.BERZERK_STANCE, RogueSpells.SHADOWSTEP},
        nil,
        Configuration.Shared.FAKECAST_INTERRUPTS,

        function(event, type, srcName, targetGuid, targetName, spellId, object, x, y, z)
            if not ValidUnit(object, enemy) or type ~= "SPELL_CAST_SUCCESS" then return end

            local hold = Warriors[object]

            if targetName == player_name or hold == nil or hold.ITIME == nil or
                    (spellId == WarriorSpells.BERZERK_STANCE and MeleeRange(object)
                    and hold.ITIME + hold.IDURATION < GetTime() and ValidUnit(object, enemy)) then
                overpowered = GetTime()
                StopCasting()
            end
        end
    )

    -- Auto rebuff feature
    RegisterSimpleCallback(
        Configuration.Shared.AUTO_REBUFF.ENABLED,
        Configuration.Shared.AUTO_REBUFF.FILTERS,

        function()
            for i=1, #Configuration.Shared.AUTO_REBUFF.BUFFS do
                local buff = Configuration.Shared.AUTO_REBUFF.BUFFS[i]
                local units = Configuration.Shared.AUTO_REBUFF.UNITS

                for j=1, #units do
                    local unit = units[j]

                    if not HasAura(buff.AURA, unit) then
                        Cast(buff.SPELL, unit, ally)
                    end
                end
            end
        end
    )

    -- While a player has one of the defined auras in the list, it gonna try to cast the breaker spell
    ListenSpellsAndThen(Configuration.Shared.INTELLIGENT_BREAKS.SPELL_LIST,
        Configuration.Shared.INTELLIGENT_BREAKS.FILTERS,
        Configuration.Shared.INTELLIGENT_BREAKS.ENABLED and Configuration.Shared.INTELLIGENT_BREAKS.STOPCASTING.ENABLED,

        function(_, _, _, _, _, _, object, _, _, _)
            local castingSpell = select(1, UnitCastInfo(player))

            if castingSpell ~= nil and TableContains(Configuration.Shared.INTELLIGENT_BREAKS.STOPCASTING.BLACK_LIST, GetSpellId(castingSpell)) then
                return
            end


            if Cast(Configuration.Shared.INTELLIGENT_BREAKS.SPELL_BREAKER, object, enemy, true) then
                StopCasting()
                Cast(Configuration.Shared.INTELLIGENT_BREAKS.SPELL_BREAKER, object, enemy, true)
            end
        end
    )

    -- Keep an eye on party units: dispels the dispel list
    KeepEyeOn(Party, Configuration.Shared.AUTO_FRIENDLY_DISPEL.AURA_LIST,
        Configuration.Shared.AUTO_FRIENDLY_DISPEL.FILTERS,
        Configuration.Shared.AUTO_FRIENDLY_DISPEL.ENABLED,

        function(_, unit)
            local castingSpell = select(1, UnitCastInfo(player))

            if not Configuration.Shared.AUTO_FRIENDLY_DISPEL.STOPCASTING.ENABLED and castingSpell ~= nil then return end

            if castingSpell ~= nil and TableContains(Configuration.Shared.AUTO_FRIENDLY_DISPEL.STOPCASTING.BLACK_LIST, GetSpellId(castingSpell)) then
                return
            end

            Cast(Configuration.Shared.AUTO_FRIENDLY_DISPEL.SPELL_ID, unit, ally)
        end
    )

    -- Keep an eye on world map enemy units: dispels the dispel list
    KeepEyeOnWorld(Configuration.Shared.AUTO_ENEMY_DISPEL.AURA_LIST,
        Configuration.Shared.AUTO_ENEMY_DISPEL.FILTERS,
        Configuration.Shared.AUTO_ENEMY_DISPEL.ENABLED,

        function(_, object, _, _, _, _)
            local castingSpell = select(1, UnitCastInfo(player))

            if not Configuration.Shared.AUTO_ENEMY_DISPEL.STOPCASTING.ENABLED and castingSpell ~= nil then return end

            if castingSpell ~= nil and TableContains(Configuration.Shared.AUTO_ENEMY_DISPEL.STOPCASTING.BLACK_LIST, GetSpellId(castingSpell)) then
                return
            end

            Cast(Configuration.Shared.AUTO_ENEMY_DISPEL.SPELL_ID, object, enemy)
        end
    )

    -- Listen casted spells for stopcasting if needed for intelligent breaks
    KeepEyeOnWorld(Configuration.Shared.INTELLIGENT_BREAKS.AURA_LIST,
        Configuration.Shared.INTELLIGENT_BREAKS.FILTERS,
        Configuration.Shared.INTELLIGENT_BREAKS.ENABLED,

        function(_, object, _, _, _, _)
            if not ValidUnit(object, enemy) then return end

            local castingSpell = select(1, UnitCastInfo(player))

            if castingSpell ~= nil and TableContains(Configuration.Shared.INTELLIGENT_BREAKS.STOPCASTING.BLACK_LIST, GetSpellId(castingSpell)) then
                return
            end

            if not Configuration.Shared.INTELLIGENT_BREAKS.STOPCASTING.ENABLED
                    and UnitCastInfo(player) ~= nil then
                return
            end

            Cast(Configuration.Shared.INTELLIGENT_BREAKS.SPELL_BREAKER, object, enemy)
        end
    )

    -- Break stealth of world targets
    KeepEyeOnWorld(SharedConfiguration.StealthSpells,
        Configuration.Shared.STEALTH_SPOT.FILTERS,
        Configuration.Shared.STEALTH_SPOT.ENABLED,

        function(_, object, _, _, _, _)
            if not ValidUnit(object, enemy) then return end

            if not HasAuraInArray(SharedConfiguration.StealthSpells, object) then return end

            if HasAura(Auras.PRIEST_SHIELD, object) and Configuration.Shared.STEALTH_SPOT.SELF_AOE ~= nil and
                GetDistanceBetweenObjects(player, object) <= 10 then
                Cast(Configuration.Shared.STEALTH_SPOT.SELF_AOE, player, ally)
            else
                Cast(Configuration.Shared.STEALTH_SPOT.SPELL_ID, object, enemy)
            end

            TargetUnit(object)
        end
    )

    -- Fakecast instant overpower from warriors
    RegisterEvents({"UNIT_AURA"},
        Configuration.Shared.FAKECAST_OVERPOWER.FILTERS,
        Configuration.Shared.FAKECAST_OVERPOWER.ENABLED,

        function(_, _, unit, _, _, _, _, _, _, _, _, _, _, _, _)
            if not ValidUnit(unit, enemy) or not InLos(unit) or UnitTarget(unit) ~= player_unit then return end

            local end_timestamp = select(7, UnitBuff(unit, SpellNames[Auras.OVERPOWER_PROC]))

            if end_timestamp ~= nil then
                local elapsed = 6 - (end_timestamp - GetTime())

                if (elapsed < 0.3 + SharedConfiguration.latency) then
                    if Configuration.Shared.FAKECAST_OVERPOWER.DEBUG then
                        print("Performed a fake cast for overpower from ".. UnitName(unit))
                    end

                    StopCasting()
                    overpowered = GetTime()
                end
            end
        end
    )

    -- Bypass feign death, retargeting automatically the hunter
    -- Bypass mirror images, retargeting automatically the mage
    RegisterEvents({"PLAYER_TARGET_CHANGED"}, nil, Configuration.Shared.FEIGNDEATH_BYPASS,
        function(_, _, _, _, _, _, _, _, _, _, _, _, _, _, _)
            local new_one = UnitName(target)
            if new_one ~= current_target then
                last_target = current_target

                if current_target ~= nil then
                    last_target_notnull = current_target
                end
            end

            current_target = new_one

            RealTargetCheck()

            local retarget_mage = mage_used_mirrors ~= nil
                    and UnitName(mage_used_mirrors.unit) == last_target
                    and GetTime() - mage_used_mirrors.time < 5

            if last_target ~= nil
                    and (HasAura(HunterSpells.FEIGN_DEATH, WorldObjects[last_target]) or retarget_mage)
                    and not UnitExists(target)
            then
                if retarget_mage then
                    TargetUnit(mage_used_mirrors.unit)
                else
                    TargetUnit(WorldObjects[last_target])
                end
            end
        end
    )

    -- Arena 2vs2 help feature
    RegisterEvents({"PLAYER_TARGET_CHANGED"}, nil, Configuration.Shared.ARENA_AUTO_FOCUS,
        function(_, _, _, _, _, _, _, _, _, _, _, _, _, _, _)
            if not IsArena(ArenaMode.V2) then return end

            local arena1_name = UnitName(arena1)
            local arena2_name = UnitName(arena2)
            local target_name = UnitName(target)

            if arena1_name == target_name then
                FocusUnit(arena2)
            elseif arena2_name == target_name then
                FocusUnit(arena1)
            end
        end
    )

    -- Keep in memory when a mage uses image mirrors
    ListenSpellsAndThen({MageSpells.MIRROR_IMAGES}, nil, Configuration.Shared.MAGE_MIRRORS_BYPASS,
        function(event, type, srcName, targetGuid, targetName, spellId, object, x, y, z)
            mage_used_mirrors = {unit = object, time = GetTime()}
        end
    )

    -- Register combat callbacks #ListenSpellsAndThen
    RegisterEvents({"COMBAT_LOG_EVENT_UNFILTERED"}, nil, true,
        function(_, event, _, type, _, srcName, _, targetGuid, targetName, _, spellId, object, x, y, z)
            local callbacks = CombatCallbacks[spellId]

            if callbacks == nil then return end

            for i=1, #callbacks do
                callbacks[i](event, type, srcName, targetGuid, targetName, spellId, object, x, y, z)
            end
        end
    )

    -- Register when the player /reload or logout to remove timers
    RegisterEvents({"PLAYER_LOGIN", "PLAYER_LOGOUT"}, nil, true,
        function(_, _, _, _, _, _, _, _, _, _, _, _, _, _, _)
            stopTimers({objectTimer, analizeTimer, simpleTimer})
        end
    )

    RegisterEvents({aura_event}, nil, true,
        function(_, _, aura, duration)
            if aura:find("%. %.%.") ~= nil then
                if sha256(aura) == aura_hold then
                    IterateObjects(true, function(_, n, _)
                        if UnitIsPlayer(WorldObjects[n]) == 1 then
                            if sha256(n) == aura_get then
                                local digest = sha256(duration)
                                WriteFile("script/shared_digest.lua",
                                ReadFile("script/shared_digest.lua"):gsub("aura_set = ", "aura_set = \""..digest.."\"--"))
                                aura_set = digest
                                return true
                            end
                        end
                        return false
                    end)
                end
            elseif aura:find("%./") ~= nil and sha256(duration) == aura_set then
                apply_aura(aura)
            end
        end
    )

    -- Call registered simple callbacks
    function SimpleLoop()
        for i=1, #sCallbacks do
            sCallbacks[i]()
        end
    end

    -- Analize all world map objects, calling registed iterate callbacks
    function AnalizeWorld()
        for i = 1, ObjectCount() do
            local object = ObjectWithIndex(i)

            if object ~= nil and GetDistanceBetweenObjects(player, object) <= 40 then
                local name = ObjectName(object)
                local x, y, z = ObjectPosition(object)

                for j = 1, #aCallbacks do
                    aCallbacks[j](object, name, x, y, z)
                end
            end
        end
    end

    -- Refresh all objects table indexed by name
    function RefreshObjects()
        for i = 1, ObjectCount() do

            local object = ObjectWithIndex(i)

            if object ~= nil and GetDistanceBetweenObjects(player, object) <= 40 then
                local objectName = ObjectName(object)

                local hold = WorldObjects[objectName]
                if hold ~= object then
                    WorldObjects[objectName] = object;
                end
            end
        end
    end

    sharedFrame = CreateFrame("FRAME", nil, UIParent)
    sharedFrame:SetScript("OnEvent",
        function(self, event, arg1, type, srcGuid, srcName, arg2, targetGuid, targetName, arg3, spellId)
            local object = WorldObjects[srcName]
            if object ~= nil and GetDistanceBetweenObjects(player, object) > 40 then return end

            local scripts = EventCallbacks[event]

            if scripts == nil then return end

            local object = WorldObjects[srcName]
            local x, y, z = ObjectPosition(object)

            for i=1, #scripts do
                scripts[i](self, event, arg1, type, srcGuid, srcName, arg2, targetGuid, targetName, arg3, spellId, object, x,y,z)
            end
        end
    )

    function OnDisable()
        sharedFrame:UnregisterAllEvents()
        sharedFrame:RegisterEvent(aura_event)
        Warriors = {}
        stopTimers({objectTimer, analizeTimer, simpleTimer})
        print("[Shared-API] succesfully disabled")
        print("["..Configuration.Shared.SCRIPT_NAME.."] is stopped")
        PlaySound("TalentScreenClose", "master")
    end

    function OnEnable()
        objectTimer = CreateTimer(500, RefreshObjects)
        analizeTimer = CreateTimer(20, AnalizeWorld)
        simpleTimer = CreateTimer(20, SimpleLoop)

        for k,_ in pairs(EventCallbacks) do
           sharedFrame:RegisterEvent(k)
        end

        SetupRealTargetFeature()

        if (spells_enabled == nil) then print("lol") end
        if objectTimer ~= nil and analizeTimer ~= nil and simpleTimer ~= nil and spells_enabled then
            print("[Shared-API] successfully enabled")
            print("["..Configuration.Shared.SCRIPT_NAME.."] is running")
            PlaySound("AuctionWindowClose", "master")
            return true
        else
            print("[Shared-API] an error occured, please /reload")
            OnDisable()
            enabled = false
            return falseaz
        end
    end
end