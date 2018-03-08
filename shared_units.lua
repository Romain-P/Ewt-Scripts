-- Created by romain-p
-- see updates on http://github.com/romain-p

if not shared_units then
    shared_units = true

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
    arena1 = "arena1"
    arena2 = "arena2"
    arena3 = "arena3"
    arenapet1 = "arenapet1"
    arenapet2 = "arenapet2"
    arenapet3 = "arenapet3"
    player_name = UnitName(player)
    player_unit = GetObjectWithGUID(UnitGUID(player))
    player_class = select(2, UnitClass(player))

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

    ArenaMode = {
        V3 = 1,
        V2 = 2,
        V1 = 3
    }

    -- Return true if the player is playing in Arena
    -- Define the mode if needed (ArenaMode.V1/V2/V3)
    function IsArena(mode)
        local inArena = select(1, IsActiveBattlefieldArena()) == 1

        return inArena and (not mode
                or (mode == ArenaMode.V1 and UnitExists(arena1)) == 1
                or (mode == ArenaMode.V2 and UnitExists(arena1) and UnitExists(arena2))
                or (mode == ArenaMode.V3 and UnitExists(arena1) and UnitExists(arena2) and UnitExists(arena3)) == 1)
    end

    -- Return an enemy array depending on the current area of the player
    function GetEnemies()
        if IsArena() then
            return ArenaEnemies
        else
            return WorldEnemies
        end
    end
end