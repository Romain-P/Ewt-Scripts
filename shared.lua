-- Created by romain-p
-- see updates on http://github.com/romain-p

if not shared then shared = true
    SharedConfiguration = {
        melee_range = 7,
        gcd_value = 1.5,
        Totems = {
            TREMOR = "Tremor Totem",
            EARTHBIND = "Earthbind Totem",
            CLEANSING = "Cleansing Totem",
            TOTEM_OCCURENCE = "Totem"
        }
    }

    enemy = "enemy"
    ally = "ally"
    target = "target"
    party1 = "party1"
    party1pet = "party1pet"
    party2 = "party2"
    party2pet = "party2pet"
    party3 = "party3"
    party3pet = "party3pet"
    player = "player"
    pet = "pet"
    player_name = UnitName(player)
    objectTimer = -1
    analizeTimer = -1
    callbacks = {}
    enabled = false

    WorldObjects = {}
    FrameCallbacks = {}

    Party = {
        "party1",
        "party2",
        "party3",
        "party1pet",
        "party2pet",
        "party3pet"
    }

    ArenaEnemies = {
        "arenapet1",
        "arenapet2",
        "arenapet3",
        "arena1",
        "arena2",
        "arena1pet",
        "arena2pet",
        "arena3pet",
        "target",
        "mouseover",
        "focus",
    }

    WorldEnemies = {
        "target",
        "targettarget",
        "focustarget",
        "focus",
        "mouseover"
    }

    RaceSpells = {
        SHADOWMELD = 58984,
        SHOOT = 5019
    }

    HunterSpells = {
        SCATTER = 19503
    }

    WarriorSpells = {}
    MageSpells = {}
    WarlockSpells = {}
    ShamanSpells = {}

    PaladinSpells = {
        REPENTENCE = 20066
    }

    DkSpells = {
        HUNGERING_COLD = 49203
    }

    DruidSpells = {
        PROWL = 5215
    }

    RogueSpells = {
        VANISH = 26889,
        STEALTH = 1784,
        BLIND = 2084,
        GOUGE = 1776
    }

    PriestSpells = {
        PENANCE = 53007,
        FLASH_HEAL = 48071,
        PRAYER_OF_MENDING = 48113,
        RENEW = 48068,
        SHIELD = 48066,
        BINDING_HEAL = 48120,
        SWD = 48158
    }

    Auras = {
        GRACE = 47930,
        WEAKENED_SOUL = 6788,
        PRAYER_OF_MENDING = 48111,
        DIVINE_SHIELD = 642,
        AURA_MASTERY = 31821,
        RENEW = 48068,
        HAND_PROTECTION = 10278,
        BURNING_DETERMINATION = 54748,
        OVERPOWER_PROC = 60503,
        FAKE_DEATH = 5384,
        SCATTER = 19503,
        REPENTANCE = 20066,
        BLIND = 2094,
        HOJ = 10308,
        SEDUCTION = 6358,
        SEDUCTION2 = 6359,
        STEALTH = 1784,
        VANISH = 26889,
        SHADOWMELD = 58984,
        PROWL = 5215,
        BLADESTORM = 46924,
        SHADOW_DANCE = 51713,
        AVENGING_WRATH = 31884,
        HUNT_DISARM = 53359,
        WAR_DISARM = 676,
        ROGUE_DISARM = 51722,
        SP_DISARM = 64058,
        FEAR = 6215,
        PSYCHIC_SCREAM = 10890,
        HOWL_OF_TERROR = 17928,
        GOUGE = 1776,
        ENRAGED_REGENERATION = 55694,
        SHAMAN_NATURE_SWIFTNESS = 16188,
        DRUID_NATURE_SWIFTNESS = 17116,
        ELEMENTAL_MASTERY = 16166,
        PRESENCE_OF_MIND = 12043,
        CYCLONE = 33786,
        DETERRENCE = 19263,
        PIERCING_HOWL = 12323,
        HAND_FREEDOM = 1044,
        MASTER_CALL = 54216,
        DEEP = 44572,
        ICEBLOCK = 45438,
        HOT_STREAK = 48108,
        COILE = 47860,
        BLOODRAGE = 29131,
        BERSERKER_RAGE = 18499,
        ENRAGE = 57522,
        GROUNDING_TOTEM = 8178,
        BEAST = 34471,
        LICHBORN = 49039,
        MAGIC_SHIELD = 48707
    }

    function TableConcat(t1, t2)
        for k, v in pairs(t2) do
            t1[k] = v
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

    -- Return true if the player is playing in Arena
    function IsArena()
        return select(1, IsActiveBattlefieldArena()) == 1
    end

    -- Return an enemy array depending on the current area of the player
    function GetEnemies()
        if IsArena() then
            return ArenaEnemies
        else
            return WorldEnemies
        end
    end

    function RegisterCallback(callback)
        callbacks[#callbacks + 1] = callback
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
        local dot = select(7, UnitDebuff("target", GetSpellInfo(id)))
        return dot ~= nil and dot - GetTime() >= 3
    end

    -- Return true if a given aura is present on a given unit
    function HasAura(id, unit)
        return UnitDebuff(unit, SpellNames[id]) ~= nil or
                select(11, UnitAura(unit, SpellNames[id])) == id
    end

    -- Return true if a given unit health is under a given percent
    function HealthIsUnder(unit, percent)
        return (((100 * UnitHealth(unit) / UnitHealthMax(unit))) < percent)
    end

    -- Return true if the whole party has health > x
    function HealthTeamNotUnder(percent)
        for _, unit in ipairs(Friends) do
            if UnitExists(unit) and HealthIsUnder(unit, percent) then
                return false
            end
        end
        return true
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

    -- Return true if a target is stealthed
    function IsStealth(unit)
        return HasAura(RogueSpells.VANISH, unit) or
                HasAura(RogueSpells.STEALTH, unit) or
                HasAura(DruidSpells.PROWL, unit) or
                HasAura(RaceSpells.SHADOWMELD, unit)
    end

    -- Take a callback(object, name, position) that gonna be called iterating map objects.
    -- Return true in the callback to break the loop, false otherwise
    function IterateObjects(callback)
        for i = 1, ObjectCount() do
            local object = ObjectWithIndex(i)
            local name = ObjectName(object)
            local position = ObjectPosition(object)

            if callback(object, name, position) then
                break
            end
        end
    end

    -- Listen spells and performs your callback(event, srcName, targetGuid, targetName, spellId) when one is fired
    function ListenSpellsAndThen(spellList, callback)
        for i=1, #spellList do
            FrameCallbacks[spellList[i]] = callback;
        end
    end

    sharedFrame = CreateFrame("FRAME", nil, UIParent)
    sharedFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    sharedFrame:RegisterEvent("PLAYER_LOGIN")
    sharedFrame:SetScript("OnEvent",
        function(self, event, _, type, srcGuid, srcName, _, targetGuid, targetName, _, spellId)

            if type == "PLAYER_LOGIN" then
                StopTimer(objectTimer)
                do return end
            end

            local object = WorldObjects[srcName]

            if spellId == RogueSpells.VANISH or
                    spellId == RogueSpells.STEALTH or
                    spellId == DruidSpells.PROWL or
                    spellId == RaceSpells.SHADOWMELD then
                SpellStopCasting()
                Cast(Configuration.SPOT_SPELL, object, enemy)
                TargetUnit(found)
            end

            for k,v in pairs(FrameCallbacks) do
                if k == spellId then
                    v(event, srcName, targetGuid, targetName, spellId, object)
                end
            end
        end)

    -- Break stealth of world targets
    function BreakStealth(unit)
        if IsStealth(unit) then
            Cast(Configuration.SPOT_SPELL, unit, enemy)
            TargetUnit(unit)
            return true
        end

        return false
    end

    -- Analize all world map objects
    function AnalizeWorld()
        for i = 1, ObjectCount() do
            local object = ObjectWithIndex(i)
            local name = ObjectName(object)
            local position = ObjectPosition(object)

            BreakStealth(object)

            for j = 1, #callbacks do
                callbacks[j](object, name, position)
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

    function OnDisable()
        sharedFrame:SetScript("OnEvent", nil)
        StopTimer(objectTimer)
        StopTimer(analizeTimer)
        print("[Shared-API] succesfully disabled")
        PlaySound("TalentScreenClose", "master")
    end

    function OnEnable()
        objectTimer = CreateTimer(500, RefreshObjects)
        analizeTimer = CreateTimer(20, AnalizeWorld)

        if objectTimer ~= nil then
            print("[Shared-API] successfully enabled")
            PlaySound("AuctionWindowClose", "master")
            return true
        else
            print("[Shared-API] an error occured, please /reload")
            return false
        end
    end
end