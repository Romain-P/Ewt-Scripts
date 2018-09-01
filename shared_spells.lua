-- Created by romain-p
-- see updates on http://github.com/romain-p

if not shared_spells then
    shared_spells = true

    RaceSpells = {
        SHADOWMELD = 58984,
        SHOOT = 5019,
        THROW = 2764,
        HUMAN_TRINKET = 59752,
        YOUR_SPELL = 10212121
    }

    HunterSpells = {
        SCATTER = 19503,
        FEIGN_DEATH = 5384
    }

    WarriorSpells = {
        REFLECT = 23920,
        BERZERK_STANCE = 2458,
        SHIELD_BASH = 72,
        PUMMEL = 6552
    }

    MageSpells = {
        FIRE_BALL = 42833,
        Polymorph_sheep = 12826,
        Polymorph_rabbit = 61721,
        Polymorph_turtle = 28271,
        Polymorph_pig = 28272,
        Polymorph_cat = 61305,
        Polymorph_subrank1 = 12824,
        Polymorph_subrank2 = 12825,
        Polymorph_turkey = 61780,

        MIRROR_IMAGES = 55342
    }

    WarlockSpells = {}

    ShamanSpells = {
        GROUNDING_TOTEM = 8177
    }

    PaladinSpells = {
        REPENTENCE = 20066,
        HAND_OF_RECKONING = 62124,
        JUDGEMENT_OF_WISDOM = 53408,
        JUDGEMENT_OF_JUSTICE = 53407,
        JUDGEMENT_OF_LIGHT = 20271,
        DIVINE_STORM = 53385,
        DIVINE_SHIELD = 642,
        SAC = 64205,
        RET_SAC = 6940,
        CRUSADER_STRIKE = 35395,
        EXORCISM = 48801,
        HAMMER_OF_WRATH = 48806,
        HOJ = 10308,
        REPENTANCE = 20066,
        CLEANSE = 4987,
        SACRED_SHIELD = 53601,
        RIGHTEOUS_FURY = 25780,
        BLESSING_OF_KINGS = 20217,
        SEAL_OF_RIGHTEOUSNESS = 21084,
        SEAL_OF_VENGENCE = 31801,
        SEAL_OF_COMMAND = 20375,
        SEAL_OF_JUSTICE = 20164,
        FLASH_OF_LIGHT = 48785,
        FREEDOM = 1044,
        DIVINE_PLEA = 54428
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
        GOUGE = 1776,
        SHADOWSTEP = 36554
    }

    PriestSpells = {
        DEVOURING_PLAGUE = 48300,
        SHADOWORD_PAIN = 48125,
        PENANCE = 53007,
        DISPEL_MAGIC = 988,
        FLASH_HEAL = 48071,
        PRAYER_OF_MENDING = 48113,
        RENEW = 48068,
        SHIELD = 48066,
        BINDING_HEAL = 48120,
        SWD = 48158,
        MASS_DISPEL = 32375,
        HOLY_FIRE = 48135,
        SMITE = 48123,
        MIND_BLAST = 48127,
        MIND_CONTROL = 605,
        HYMN_OF_HOPE = 64901,
        DIVINE_HYMN = 64843,
        MIND_SMOOTHE = 453,
        INNER_FIRE = 48168,
        FORTITUDE = 48161,
        ABOLISH_DISEASE = 552,
        HOLY_NOVA = 48078
    }

    Auras = {
        GNAW = 47481,
        BASH = 8983,
        KIDNEY_SHOT = 8643,
        VIPER_STING = 3034,
        TOTEM_SHIELD = 55277,
        ICE_BARRIER = 43039,
        VAMPIRIC_TOUCH = 48160,
        BLOOD_PLAGUE = 55078,
        FROST_EVER = 55095,
        EBON_PLAGUE = 51735,
        ICY_CLUTCH = 50436,
        INFECTED_WOUNDS = 58181,
        UNSTABLE_AFFLICTION = 47843,
        ICE_CHAINS = 45524,
        UNHOLY_BLIGHT = 50536,
        ABOLISH_DISEASE = 552,
        SILENCE = 15487,
        SHADOWFURY = 47847,
        Seduction_1 = 31865,
        Seduction_2 = 30850,
        Seduction_3 = 29490,
        Seduction_4 = 20407,
        Seduction_5 = 6359,
        ENTANGLING_ROOT = 53308,
        STRANGULATE = 47476,
        FREEZING_TRAP = 14309,
        FREEZING_ARROW = 60210,
        SILENCING_SHOT = 34490,
        TURN_EVIL = 10326,
        HUNGERING_COLD = 49203,
        HUNTER_MARK = 53338,
        TRAP_SNAKE = 64803,
        CRAB_SNARE = 53547,
        ROOT_TOTEM = 64695,
        CS_LOCKPET = 24259,
        FEAR_AOE_LOCK = 17928,
        ROOT_DRUID = 53308,
        ROOT_DRUID2 = 53313,
        FEARIE_FIRE = 770,
        Polymorph_sheep = 12826,
        Polymorph_rabbit = 61721,
        Polymorph_turtle = 28271,
        Polymorph_pig = 28272,
        Polymorph_cat = 61305,
        Polymorph_subrank1 = 12824,
        Polymorph_subrank2 = 12825,
        Polymorph_turkey = 61780,
        INNER_FIRE = 48168,
        BLESSING_OF_KING = 20217,
        GREATER_BLESSING_OF_KING = 25898,
        FORTITUDE = 48161,
        GREATER_FORTITUDE = 48162,
        MARK_WILD = 48469,
        GREATER_MARK_WILD = 48470,
        DOT_PAIN = 48125,
        DOT_PLAGUE = 48300,
        FEIGN_DEATH = 5384,
        GRACE = 47930,
        COUNTERSPELL = 55021,
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
        MAGIC_SHIELD = 48707,
        PRIEST_SHIELD = 48066,
        REFLECT = 23920,
        PROT_REFLECT = 59725,
        THE_ART_OF_WAR = 59578
    }
end