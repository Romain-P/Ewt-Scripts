-- Created by romain-p
-- see updates on http://github.com/romain-p

if not defined then
    defined = true
    RunScript(ReadFile("script/shared_spells.lua"))

    Configuration = {
        -- A spell that gonna be casted on stealthed targets
        SPOT_SPELL = PriestSpells.SWD,

        DISPELL_LIST = {
            Auras.HOJ,
            Auras.REPENTANCE,
            Auras.SEDUCTION,
            Auras.SEDUCTION2,
            Auras.COUNTERSPELL
        }
    }

    RunScript(ReadFile("script/shared.lua"))

    -- SWD Scatter, Hungering cold, blind, gouge, repentence
    ListenSpellsAndThen({HunterSpells.SCATTER, DkSpells.HUNGERING_COLD, RogueSpells.BLIND, RogueSpells.GOUGE, PaladinSpells.REPENTENCE},
        function(_, _, _, targetName, _, object, _, _, _)
            if targetName ~= player_name then return end
            Cast(PriestSpells.SWD, object, enemy)
        end
    )

    -- Keep an eye on party units: dispels the dispel list
    KeepEyeOn(Party, Configuration.DISPELL_LIST,
        function(_, unit)
            Cast(PriestSpells.DISPEL_MAGIC, unit, ally)
        end
    )

    -- Keep an eye on world objects: md divine shield
    KeepEyeOnWorld({Auras.DIVINE_SHIELD},
        function(_, object, _, x, y, z)
            local MD_RANGE = 30 -- naive md script, TODO: calcul position when not in los or 5 yards away

            if GetDistanceBetweenObjects(player, object) <= MD_RANGE and
               ValidUnit(object, enemy) and CdRemains(PriestSpells.MASS_DISPEL) then

                if IsAoEPending() then
                    CancelPendingSpell()
                end

                CastSpellByID(PriestSpells.MASS_DISPEL)
                ClickPosition(x, y, z)
            end
        end
    )

    -- Tracks and kills totems with wound/weapon in order: tremor, cleansing, earthind and others
    function TrackTotems()
        local priority_name, priority

        IterateObjects(
            function(object, objectName, _)
                if UnitIsEnemy(object, player) and UnitCanAttack(player, object) == 1 then
                    local tremor_totem = objectName == SharedConfiguration.Totems.TREMOR

                    if tremor_totem or
                            objectName == SharedConfiguration.Totems.EARTHBIND or
                            (objectName == SharedConfiguration.Totems.CLEANSING and priority_name ~= SharedConfiguration.Totems.EARTHBIND) or
                            string.find(objectName, SharedConfiguration.Totems.TOTEM_OCCURENCE) ~= nil and priority == nil then
                        priority = object
                        priority_name = objectName

                        return tremor_totem
                    end
                end

                return false
            end
        )

        if MeleeRange(priority) then
            RunMacroText("/startattack [@"..priority.."]")
        else
            Cast(RaceSpells.SHOOT, priority, enemy)
        end
    end

    -- Healing rotation for a given friendly unit
    function Heal(unit)
        if unit == pet then
            if UnitExists(party1pet) then
                unit = party1pet
            elseif UnitExists(party2pet) then
                unit = party2pet
            end
        end

        if CdRemains(PriestSpells.SHIELD, false)
                and not HasAura(PriestSpells.SHIELD, unit)
                and not HasAura(Auras.WEAKENED_SOUL, unit) then
            Cast(PriestSpells.SHIELD, unit, ally)

        elseif CdRemains(PriestSpells.PRAYER_OF_MENDING, false)
                and not HasAura(Auras.PRAYER_OF_MENDING, unit)
                and HealthIsUnder(unit, 80) then
            Cast(PriestSpells.PRAYER_OF_MENDING, unit, ally)

        elseif CdRemains(PriestSpells.PENANCE, false) then
            Cast(PriestSpells.PENANCE, unit, ally)

        elseif HealthIsUnder(unit, 70)
                and not HasAura(PriestSpells.RENEW, unit)
                and HasAura(PriestSpells.SHIELD, unit)
                and HasAura(Auras.GRACE, unit) then
            Cast(PriestSpells.RENEW, unit, ally)

        else
            local id = PriestSpells.FLASH_HEAL

            if HealthIsUnder(player, 80)
                    and unit ~= player then
                id = PriestSpells.BINDING_HEAL
            end

            Cast(id, unit, ally)
        end
    end
end

if not enabled then
    OnEnable()
    enabled = true
else
    OnDisable()
    enabled = false
end
