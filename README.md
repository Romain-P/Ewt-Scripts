## Ewt Scripts

### Installation

* Make a folder called `script` in your world of warcraft folder  
* Put all .lua files in this folder
* Example of location: `your_wow_folder/script/shared.lua`

### Documentation

#### Shared API

Shared-API holds units in variables that are frequently used, use them as well!  
The following functions I'll describe are the most scallable of the Share-API.
See more specific functions directly in the file `shared.lua`

* Apply a `callback(auraId, object, name, position)` when some of the world map units has an aura present in the aura array
````lua
    function KeepEyeOnWorld(auraArray, callback);
    
    -- Naive Example
    -- This function holds an advanced callback in a shared table 
    -- The callback is gonna cast mass dispel when a player is found with divine shield in the world map
    KeepEyeOnWorld({Auras.DIVINE_SHIELD},
        function(_, object, x, y, z)
            CastSpellByID(PriestSpells.MASS_DISPEL)
            ClickPosition(x, y, z)
         end
    )
````

* Apply a `callback(auraId, unit)` when some of ur units has active aura present in the aura array
````lua
    function KeepEyeOn(units, auraArray, to_apply);
    
    -- Naive Example
    -- This function holds a simple callback in a shared table
    -- The callback is gonna dispel party1 and party when they are under HOJ
    KeepEyeOn({party1, party2}, {Auras.HOJ},
        function(auraId, unit)
            CastSpellByID(PaladinSpells.CLEANSE, unit)
        end
    )
````

* Listen casted spells in the world map and perform a `callback(event, srcName, targetGuid, targetName, spellId, object, pos)` when one is fired
````lua
    function ListenSpellsAndThen(auraArray, callback);
    
    -- Naive Example
    -- This function holds a callback in a shared table
    -- This callback is gonna Charge a rogue when he tries to be stealth
    ListenSpellsAndThen({RogueSpells.VANISH, RogueSpells.STEALTH}, 
        function(event, srcName, targetGuid, targetName, spellId, object, x, y, z)
            CastSpellByID(WarriorSpells.CHARGE, object)
        end
    )
````

* See also 'primitive' functions to register a custom callback
````lua
    -- Register a callback(object, name, position) that gonna be called while iterating world map objects
    function RegisterAdvancedCallback(callback)
        aCallbacks[#aCallbacks + 1] = callback
    end

    -- Register a callback() that gonna be called in an loop
    function RegisterSimpleCallback(callback)
        sCallbacks[#sCallbacks + 1] = callback
    end
````
