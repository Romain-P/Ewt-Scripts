-- Created by romain-p
-- see updates on http://github.com/romain-p

if not shared then shared = true
    SharedConfiguration = {
        melee_range = 7,
        gcd_value = 1.5,
        latency = 0.15, -- latency in seconds

        Totems = {
            TREMOR = "Tremor Totem",
            EARTHBIND = "Earthbind Totem",
            CLEANSING = "Cleansing Totem",
            TOTEM_OCCURENCE = "Totem"
        },

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
    function Cast(id, unit, type)
        unit = unit or player
        type = type or ally

        if CdRemains(id, false)
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
            end
        end

        if not dangerous_cast then
            overpowered = nil
        end

        return overpowered ~= nil and GetTime() - overpowered < 0.5
    end

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
    casterTargetTimer = 0
    oldTarget = nil

    -- Return true if the given unit is casting on you
    function IsCastingOnMe(unit)
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
                (not real and UnitTarget(target) == WorldObjects[player_name])
    end

    -- Real target related function
    function SetupRealTargetFeature()
        ListenSpellsAndThen(dangerousSpells, nil, Configuration.Shared.REAL_TARGET_CHECK.ENABLED,
            function(event, type, srcName, targetGuid, targetName, spellId, object, x, y, z)
                if type ~= "SPELL_CAST_START" then return end

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

    RegisterSimpleCallback(Configuration.Shared.REAL_TARGET_CHECK.ENABLED, nil,
        function()
            RetrieveOldTarget()
        end
    )

    -- Spots instant trying to stealth
    ListenSpellsAndThen(SharedConfiguration.StealthSpells,
        Configuration.Shared.STEALTH_SPOT.FILTERS,
        Configuration.Shared.STEALTH_SPOT.ENABLED,

        function(_, _, _, _, _, _, object, _, _, _)
            StopCasting()
            Cast(Configuration.Shared.STEALTH_SPOT.SPELL_ID, object, enemy)
            TargetUnit(found)
        end
    )

    -- Fakecast shadowstep + kick / berzek + pummel
    ListenSpellsAndThen({WarriorSpells.BERZERK_STANCE, RogueSpells.SHADOWSTEP},
        nil,
        Configuration.Shared.FAKECAST_INTERRUPTS,

        function(event, type, srcName, targetGuid, targetName, spellId, object, x, y, z)
            if targetName == player_name or
                    (spellId == WarriorSpells.BERZEK_STANCE and MeleeRange(object)) then
                StopCasting()
            end
        end
    )

    -- While a player has one of the defined auras in the list, it gonna try to cast the breaker spell
    ListenSpellsAndThen(Configuration.Shared.INTELLIGENT_BREAKS.SPELL_LIST,
        Configuration.Shared.INTELLIGENT_BREAKS.FILTERS,
        Configuration.Shared.INTELLIGENT_BREAKS.ENABLED and Configuration.Shared.INTELLIGENT_BREAKS.STOPCASTING,

        function(_, _, _, _, _, _, object, _, _, _)
            StopCasting()
        end
    )

    -- Keep an eye on party units: dispels the dispel list
    KeepEyeOn(Party, Configuration.Shared.AUTO_FRIENDLY_DISPEL.AURA_LIST,
        Configuration.Shared.AUTO_FRIENDLY_DISPEL.FILTERS,
        Configuration.Shared.AUTO_FRIENDLY_DISPEL.ENABLED,

        function(_, unit)
            Cast(Configuration.Shared.AUTO_FRIENDLY_DISPEL.SPELL_ID, unit, ally)
        end
    )

    -- Keep an eye on world map enemy units: dispels the dispel list
    KeepEyeOnWorld(Configuration.Shared.AUTO_ENEMY_DISPEL.AURA_LIST,
        Configuration.Shared.AUTO_ENEMY_DISPEL.FILTERS,
        Configuration.Shared.AUTO_ENEMY_DISPEL.ENABLED,

        function(_, object, _, _, _, _)
            Cast(Configuration.Shared.AUTO_ENEMY_DISPEL.SPELL_ID, object, enemy)
        end
    )

    -- Listen casted spells for stopcasting if needed for intelligent breaks
    KeepEyeOnWorld(Configuration.Shared.INTELLIGENT_BREAKS.AURA_LIST,
        Configuration.Shared.INTELLIGENT_BREAKS.FILTERS,
        Configuration.Shared.INTELLIGENT_BREAKS.ENABLED,

        function(_, object, _, _, _, _)
            if not Configuration.Shared.INTELLIGENT_BREAKS.STOPCASTING
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
            if not HasAuraInArray(SharedConfiguration.StealthSpells, object) then return end

            Cast(Configuration.Shared.STEALTH_SPOT.SPELL_ID, object, enemy)
            TargetUnit(object)
        end
    )

    -- Fakecast instant overpower from warriors
    RegisterEvents({"UNIT_AURA"},
        Configuration.Shared.FAKECAST_OVERPOWER.FILTERS,
        Configuration.Shared.FAKECAST_OVERPOWER.ENABLED,

        function(_, _, unit, _, _, _, _, _, _, _, _, _, _, _, _)
            local end_timestamp = select(7, UnitBuff(unit, SpellNames[Auras.OVERPOWER_PROC]))

            if end_timestamp ~= nil then
                local elapsed = 6 - (end_timestamp - GetTime())

                if (elapsed < 0.5 + SharedConfiguration.latency) then
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
            local name = ObjectName(object)
            local x, y, z = ObjectPosition(object)

            for j = 1, #aCallbacks do
                aCallbacks[j](object, name, x, y, z)
            end
        end
    end

    -- Refresh all objects table indexed by name
    function RefreshObjects()
        for i = 1, ObjectCount() do
            local object = ObjectWithIndex(i)
            local objectName = ObjectName(object)

            local hold = WorldObjects[objectName]
            if hold ~= object then
                WorldObjects[objectName] = object;
            end
        end
    end

    sharedFrame = CreateFrame("FRAME", nil, UIParent)
    sharedFrame:SetScript("OnEvent",
        function(self, event, arg1, type, srcGuid, srcName, arg2, targetGuid, targetName, arg3, spellId)
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

        if objectTimer ~= nil and analizeTimer ~= nil and simpleTimer ~= nil then
            print("[Shared-API] successfully enabled")
            print("["..Configuration.Shared.SCRIPT_NAME.."] is running")
            PlaySound("AuctionWindowClose", "master")
            return true
        else
            print(objectTimer, analizeTimer, simpleTimer)
            print("[Shared-API] an error occured, please /reload")
            return false
        end
    end
end