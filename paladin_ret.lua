-- Created by romain-p
-- see updates on http://github.com/romain-p

if not defined then
    defined = true

    Configuration = {
        -- Common features between classes
        Shared = {
            SCRIPT_NAME = "Paladin ret",

            -- 2vs2 feature: When target=arena1, automatically focus=arena2 and vice-versa
            ARENA_AUTO_FOCUS = true,

            -- Bypass feign death, auto re-targeting
            FEIGNDEATH_BYPASS = true,
            -- Bypass image mirrors, auto re-targeting
            MAGE_MIRRORS_BYPASS = true,

            -- Fakecast rogue shadow step + kick / Warrior swap stance + pummel / shield equiped (bash)
            FAKECAST_INTERRUPTS = true,

            -- Check if a caster is really casting on you
            REAL_TARGET_CHECK = {
                ENABLED = true,
                SOUND = true, -- sound alert
                TEXT = true -- screen alert
            },

            -- Enable fakecast for overpower
            FAKECAST_OVERPOWER = {
                ENABLED = true,
                DEBUG = false
            },

            -- Configure your totem tracker, then use TrackTotems()
            TOTEM_TRACKER = {
                USE_MELEE = false,
                USE_RANGE = false,
                USE_PET = false,
                USE_RANGE_AND_PET_BOTH = false,
                USE_SPELLS = {
                    PaladinSpells.HAND_OF_RECKONING
                },

                AUTO_FACE_DIRECTION = false,

                -- put your totem in order to break
                TRACKED = {
                    "Grounding Totem",
                    "Tremor Totem",
                    "Earthbind Totem",
                    "Cleansing Totem"
                },

                -- When you tracked list is broken, put true to kill other totems
                -- e.g Flamstrong Totem etc
                TRACK_OTHERS = false,
                TOTEM_OCCURENCE = "Totem"
            },

            AUTO_REBUFF = {
                ENABLED = false,
                FILTERS = {filter_party_health},
                -- Define which units to rebuff
                UNITS = {player},
                -- Define your buffs, sometimes auraId != spellId, be careful
                BUFFS = {}
            },

            -- Automatically breaks grounding totem, reflect
            INTELLIGENT_BREAKS = {
                ENABLED = false,
                FILTERS = {filter_party_health},
                STOPCASTING = {
                    ENABLED = false,

                    --It won't stopcasting if you're casting a spell in the list below
                    BLACK_LIST = {}
                },
                SPELL_BREAKER = nil,
                SPELL_LIST = {},
                AURA_LIST = {}
            },

            -- A spell that gonna be casted on stealthed targets
            STEALTH_SPOT = {
                ENABLED = true,
                SPELL_ID = PaladinSpells.JUDGEMENT_OF_JUSTICE,
                -- used when a stealth rogue near you
                SELF_AOE = PaladinSpells.DIVINE_STORM
            },

            -- Dispel list on party
            AUTO_FRIENDLY_DISPEL = {
                ENABLED = true,
                FILTERS = {filter_party_health_60},
                SPELL_ID = PaladinSpells.CLEANSE,
                STOPCASTING = {
                    ENABLED = true,

                    --It won't stopcasting if you're casting a spell in the list below
                    BLACK_LIST = {}
                },
                AURA_LIST = {
                    Auras.HOJ,
                    Auras.REPENTANCE,
                    Auras.SEDUCTION,
                    Auras.SEDUCTION2,
                    Auras.COUNTERSPELL,
                    Auras.PSYCHIC_SCREAM,
                    Auras.FEAR,
                    Auras.COILE,
                    Auras.SILENCE,
                    Auras.SHADOWFURY,
                    Auras.Seduction_1,
                    Auras.Seduction_2,
                    Auras.Seduction_3,
                    Auras.Seduction_4,
                    Auras.Seduction_5,
                    Auras.ENTANGLING_ROOT,
                    Auras.STRANGULATE,
                    Auras.FREEZING_TRAP,
                    Auras.FREEZING_ARROW,
                    Auras.SILENCING_SHOT,
                    Auras.TURN_EVIL,
                    Auras.HUNGERING_COLD,
                    Auras.HUNTER_MARK,
                    Auras.TRAP_SNAKE,
                    Auras.CRAB_SNARE,
                    Auras.ROOT_TOTEM,
                    Auras.CS_LOCKPET,
                    Auras.FEAR_AOE_LOCK,
                    Auras.ROOT_DRUID,
                    Auras.ROOT_DRUID2,
                    Auras.FEARIE_FIRE,
                    Auras.Polymorph_sheep,
                    Auras.Polymorph_rabbit,
                    Auras.Polymorph_turtle,
                    Auras.Polymorph_pig,
                    Auras.Polymorph_cat,
                    Auras.Polymorph_subrank1,
                    Auras.Polymorph_subrank2,
                    Auras.Polymorph_turkey
                }
            },

            -- Dispel list on world map enemies
            AUTO_ENEMY_DISPEL = {
                ENABLED = false,
                FILTERS = {filter_party_health},
                SPELL_ID = nil,
                STOPCASTING = {
                    ENABLED = false,

                    --It won't stopcasting if you're casting a spell in the list below
                    BLACK_LIST = {}
                },
                AURA_LIST = {}
            },
        },

        -- Spell list to swd when casted on you
        SAC_INSTANT_CONTROL = {
            ENABLED = true,
            SPELL_LIST = {
                HunterSpells.SCATTER,
                DkSpells.HUNGERING_COLD,
                RogueSpells.BLIND,
                RogueSpells.GOUGE,
                PaladinSpells.REPENTENCE
            }
        },

        AUTO_KILL_GROUNDING = true,

        -- warnings when someone cast on you
        WARNING_SPELL_LIST = {
            Auras.Seduction_1,
            Auras.Seduction_2,
            Auras.Seduction_3,
            Auras.Seduction_4,
            Auras.Seduction_5,
            Auras.Polymorph_sheep,
            Auras.Polymorph_rabbit,
            Auras.Polymorph_turtle,
            Auras.Polymorph_pig,
            Auras.Polymorph_cat,
            Auras.Polymorph_subrank1,
            Auras.Polymorph_subrank2,
            Auras.Polymorph_turkey,
            Auras.SEDUCTION,
            Auras.SEDUCTION2
        }
    }

    RunScript(ReadFile("script/shared.lua"))

    -- Hold spells that will be catched to get the real target of a caster
    addDangerousSpells(Configuration.WARNING_SPELL_LIST)

    -- SWD Scatter, Hungering cold, blind, gouge, repentence
    ListenSpellsAndThen(Configuration.SAC_INSTANT_CONTROL.SPELL_LIST,
        Configuration.SAC_INSTANT_CONTROL.FILTERS,
        Configuration.SAC_INSTANT_CONTROL.ENABLED,

        function(_, _, _, _, targetName, _, object, _, _, _)
            if targetName ~= player_name then return end
            for i=1, #Party do
                local party = Party[i]
                Cast(PaladinSpells.RED_SAC, party, ally)
                if GetDistanceBetweenObjects(player, party) <= 40 then
                    Cast(PaladinSpells.SAC, party, ally)
                end
            end
        end
    )

    -- Dps rotation for a given enemy unit
    function Dps(unit)
        if IsDamageProtected(unit) then
            print("[Protected] "..UnitName(unit).." can't be attacked")
            return
        end

        if not HasAura(Auras.PRIEST_SHIELD, unit) and
                not HasAura(Auras.ICE_BARRIER, unit) and
                not HasAura(Auras.TOTEM_SHIELD, unit) then
            Cast(PaladinSpells.JUDGEMENT_OF_LIGHT, unit, enemy)
        end
        Cast(PaladinSpells.DIVINE_STORM, player, ally)
        Cast(PaladinSpells.CRUSADER_STRIKE, unit, enemy)
        Cast(PaladinSpells.EXORCISM, unit, enemy)
        Cast(PaladinSpells.HAMMER_OF_WRATH, unit, enemy)
    end

    function SafeCast(spell, unit)
        if IsDamageProtected(unit) or
                HasAura(Auras.GROUNDING_TOTEM, unit) or
                HasAura(Auras.REFLECT, unit) or
                HasAura(Auras.PROT_REFLECT, unit) then
            print("[Protected] "..UnitName(unit).." can't be attacked")
            do return end
        end
        Cast(spell, unit, enemy)
    end

    RegisterAdvancedCallback(Configuration.AUTO_KILL_GROUNDING, nil,
        function(object, name, x, y, z)
            if ValidUnit(object, enemy) and name == "Grounding Totem" then
                TrackTotems()
            end
        end
    )
end

if not enabled then
    OnEnable()
else
    OnDisable()
end

enabled = not enabled