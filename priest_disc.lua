-- Created by romain-p
-- see updates on http://github.com/romain-p

if not defined then
    defined = true
    RunScript(ReadFile("script/shared_init.lua"))

    Configuration = {
        SCRIPT_NAME = "Priest Discipline",

        -- 2vs2 feature: When target=arena1, automatically focus=arena2 and vice-versa
        ARENA_AUTO_FOCUS = true,

        -- Bypass feign death, auto re-targeting
        FEIGNDEATH_BYPASS = true,
        -- Bypass image mirrors, auto re-targeting
        MAGE_MIRRORS_BYPASS = true,

        -- Fakecast rogue shadow step + kick / Warrior swap stance + pummel
        -- TODO: shield equiped
        FAKECAST_INTERRUPTS = true,

        -- Enable fakecast for overpower
        FAKECAST_OVERPOWER = {
            ENABLED = true,
            DEBUG = true
        },

        -- Automatically breaks grounding totem, reflect
        INTELLIGENT_BREAKS = {
            ENABLED = true,
            FILTERS = {filter_party_health},
            STOPCASTING = true,
            SPELL_BREAKER = PriestSpells.MIND_SMOOTHE,
            SPELL_LIST = {
                WarriorSpells.REFLECT,
                ShamanSpells.GROUNDING_TOTEM
            },
            AURA_LIST = {
                Auras.GROUNDING_TOTEM,
                Auras.REFLECT,
                Auras.PROT_REFLECT
            }
        },

        -- A spell that gonna be casted on stealthed targets
        STEALTH_SPOT = {
            ENABLED = true,
            SPELL_ID = PriestSpells.SWD
        },

        -- Auras on enemy to mass dispel
        MASS_DISPEL = {
            ENABLED = true,
            FILTERS = {filter_party_health},
            AURA_LIST = {
                Auras.DIVINE_SHIELD,
                Auras.ICEBLOCK
            }
        },

        -- Dispel list on party
        AUTO_DISPEL = {
            ENABLED = true,
            FILTERS = {filter_party_health},
            AURA_LIST = {
                Auras.HOJ,
                Auras.REPENTANCE,
                Auras.SEDUCTION,
                Auras.SEDUCTION2,
                Auras.COUNTERSPELL,

            }
        },

        -- Spell list to swd when casted on you
        SWD_INSTANT_CONTROL = {
            ENABLED = true,
            SPELL_LIST = {
                HunterSpells.SCATTER,
                DkSpells.HUNGERING_COLD,
                RogueSpells.BLIND,
                RogueSpells.GOUGE,
                PaladinSpells.REPENTENCE
            }
        },

        -- Spell list to swd when casted on yu
        SWD_CASTING_CONTROL = {
            ENABLED = true,
            PERCENT = 90, -- swd at 90% of the castbar
            SPELL_LIST = {
                MageSpells.Polymorph_sheep,
                MageSpells.Polymorph_cat,
                MageSpells.Polymorph_pig,
                MageSpells.Polymorph_rabbit,
                MageSpells.Polymorph_turtle
            }
        }
    }

    RunScript(ReadFile("script/shared.lua"))

    -- SWD Scatter, Hungering cold, blind, gouge, repentence
    ListenSpellsAndThen(Configuration.SWD_INSTANT_CONTROL.SPELL_LIST,
        Configuration.SWD_INSTANT_CONTROL.FILTERS,
        Configuration.SWD_INSTANT_CONTROL.ENABLED,

        function(_, _, _, _, targetName, _, object, _, _, _)
            if targetName ~= player_name then return end
            Cast(PriestSpells.SWD, object, enemy)
        end
    )

    -- Keep an eye on party units: dispels the dispel list
    KeepEyeOn(Party, Configuration.AUTO_DISPEL.AURA_LIST,
        Configuration.AUTO_DISPEL.FILTERS,
        Configuration.AUTO_DISPEL.ENABLED,

        function(_, unit)
            Cast(PriestSpells.DISPEL_MAGIC, unit, ally)
        end
    )

    -- Keep an eye on world objects: md divine shield
    KeepEyeOnWorld(Configuration.MASS_DISPEL.AURA_LIST,
        Configuration.MASS_DISPEL.FILTERS,
        Configuration.MASS_DISPEL.ENABLED,

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

    -- SWD casting controls defined in configuration
    PerformCallbackOnCasts(
        Configuration.SWD_CASTING_CONTROL.SPELL_LIST,
        Configuration.SWD_CASTING_CONTROL.PERCENT,
        Configuration.SWD_CASTING_CONTROL.FILTERS,
        Configuration.SWD_CASTING_CONTROL.ENABLED,
            function(object, _, _, _, _)
                if not Cast(PriestSpells.SWD, object, enemy) then
                    -- if the mage isnt in range, lf a closer target
                    local found

                    local search = function(potential, pName, px, py, pz)
                        if Cast(PriestSpells.SWD, potential, enemy) then
                            found = potential
                            return true
                        end
                    end

                    IterateObjects(true, search)
                    if found ~= nil then
                        Cast(PriestSpells.SWD, found, enemy)
                    end
                end
            end
    )

    -- Tracks and kills totems with wound/weapon in order: tremor, cleansing, earthind and others
    function TrackTotems()
        local priority_name, priority

        IterateObjects(true,
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

        if not priority then return end

        if MeleeRange(priority) then
            RunMacroText("/startattack [@"..priority.."]")
        else
            Cast(RaceSpells.SHOOT, priority, enemy)
        end
    end

    -- Dps rotation for a given enemy unit
    function Dps(unit)
        -- in order, holy, smite, mind blast (if interrupted in holy school)
        Cast(PriestSpells.HOLY_FIRE, unit, enemy)
        Cast(PriestSpells.SMITE, unit, enemy)
        Cast(PriestSpells.MIND_BLAST, unit, enemy)
    end

    -- Dot a given unit with shadow word: pain + devouring plague
    function Dot(unit)
        if not HasDot(Auras.DOT_PAIN, unit) then
            Cast(PriestSpells.SHADOWORD_PAIN, unit, enemy)
        elseif not HasDot(Auras.DOT_PLAGUE, unit) then
            Cast(PriestSpells.DEVOURING_PLAGUE, unit, enemy)
        end
    end

    -- Healing rotation for a given friendly unit
    -- TODO: CALL HEAL AGAIN WHEN FAKECASTED, BUT CALL ONLY INSTANT SPELLS
    function Heal(unit)
        if ShouldntCast() then return end

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
else
    OnDisable()
end

enabled = not enabled