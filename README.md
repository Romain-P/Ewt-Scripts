## Ewt Scripts

All features in need are performing `LoS`, `range`, `cooldown` and `unit type` checks  
Each analysis doesnt need to have defined unit e.g `target`/`focus`/`arena123`. The script performs checks analysing all map objects  
`No fps`are taken with my scripts, I `optimized` all the code

### Installation

* Make a folder called `script` in your world of warcraft folder  
* Put all .lua files in this folder
* Example of location: `your_wow_folder/script/shared.lua`
* Then select `Advanced Lua Unlock` in the EWT UI
* Finally enable it with the ewt-command e.g `.loadfile script/priest_disc.lua`

### Documentation

#### Shared API

Shared-API holds units in variables that are frequently used, use them as well!  
The following functions I'll describe are the most scallable of the Share-API.
See more specific functions directly in the file `shared.lua`

* Apply a `callback(auraId, object, name, position)` when some of the world map units has an aura present in the aura array
````lua
    function KeepEyeOnWorld(auraArray, enabled, callback);
    
    -- Naive Example
    -- This function holds an advanced callback in a shared table 
    -- The callback is gonna cast mass dispel when a player is found with divine shield in the world map
    KeepEyeOnWorld({Auras.DIVINE_SHIELD}, true, -- true to enable the feature
        function(_, object, x, y, z)
            CastSpellByID(PriestSpells.MASS_DISPEL)
            ClickPosition(x, y, z)
         end
    )
````

* Apply a `callback(auraId, unit)` when some of ur units has active aura present in the aura array
````lua
    function KeepEyeOn(units, auraArray, enabled, to_apply);
    
    -- Naive Example
    -- This function holds a simple callback in a shared table
    -- The callback is gonna dispel party1 and party when they are under HOJ
    KeepEyeOn({party1, party2}, {Auras.HOJ}, true, -- true to enable the feature
        function(auraId, unit)
            CastSpellByID(PaladinSpells.CLEANSE, unit)
        end
    )
````

* Listen casted spells in the world map and perform a `callback(event, srcName, targetGuid, targetName, spellId, object, pos)` when one is fired
````lua
    function ListenSpellsAndThen(spellArray, enabled, callback);
    
    -- Naive Example
    -- This function holds a callback in a shared table
    -- This callback is gonna Charge a rogue when he tries to be stealth
    ListenSpellsAndThen({RogueSpells.VANISH, RogueSpells.STEALTH}, true, -- true to enable the feature
        function(event, srcName, targetGuid, targetName, spellId, object, x, y, z)
            CastSpellByID(WarriorSpells.CHARGE, object)
        end
    )
````

* Listen casting spells in the world map and perform a `callback(object, name, position)` when fired and at percent% of the cast bar
```lua
    function PerformCallbackOnCasts(spellArray, percent, enabled, callback);
    
    -- Naive Example
    -- This function holds a callback in a shared table
    -- This callback is gonna kick any mage casting sheep at 90% of castbar
    PerformCallbackOnCasts({MageSpells.SHEEP}, 90, true,
         function(object, name, x, y, z)
            CastSpellByID(RogueSpells.KICK, object)
         end
    )
```

* See also 'primitive' functions to register a custom callback
````lua
    -- Take a callback(object, name, position) that gonna be called for each map object.
    -- Return true in the callback to break the loop, false otherwise
    -- /!\ This function doesnt hold the callback, it performs only one loop
    function IterateObjects(enabled, callback)

    -- Register a callback(object, name, position) that gonna be called while iterating world map objects
    function RegisterAdvancedCallback(enabled, callback);

    -- Register a callback() that gonna be called in an loop
    function RegisterSimpleCallback(enabled, callback);
````

* Listen events and apply custom scripts `callback(self, event, arg1, type, srcGuid, srcName, arg2, targetGuid, targetName, arg3, spellId, object, x, y, z)` when they are fired
```lua
    -- Register an event list and associate a script(
    function RegisterEvents(event, enabled, script);
    
    RegisterEvents({PLAYER_TOTEM_UPDATE}, true, -- true to enable the feature
        function(_, _, _, _, _, srcName, _, _, _, _, _, player_unit, posx, posy, posz)
            print("The player "..srcName.." spawned or destroyed a totem")
        end
    )
```

#### Common Features

* `Auto Fakecast Overpower`: Fakecast instant overpowers from other warrior scripters
* `Feign Death Bypass`: Auto re-target the hunter
* `Mirror Images Bypass`: Auto re-target the mage
* `Arena Auto Focus`: Auto focus arena1/arena2 depending of your target (works on 2s only)

#### Priest Scripts

See [Priest Configuration](https://github.com/Romain-P/Ewt-Scripts/blob/master/priest_disc.lua#L8) for more details and customisation

* `Totem tracker`: checks for destroy totems with Shoot/Weapon (depending the range) in order: `Tremor, Cleansing, Earthbind and then others`
```lua
    -- Make this macro and press it to kill a totem
    /script TrackTotems()
```
* `Healing Rotation`: performs an healing rotation on the unit you want e.g `player`, `party1`, `party1pet`
```lua
    -- Make this macro and press it to heal the unit, yourself in this example
    /script Heal(player)
```
* `Dps Rotation`: performs a dps rotation on the unit you want in order, holy fire, smite and mind blast if interrupted
```lua
    -- Make this macro and press it to dps the unit, target in this example
    /script Dps(target)
```
* `Dot Rotation`: applies `Shadow Word: Pain` and `Devouring Plague` to the given unit (still looking at the duration of the dots)
```lua
    -- Make this macro and press it to dot the unit, target in this example
    /script Dot(target)
```
* `Stealth Spot`: Analyses the world map objects and spot all stealth players with the defined spellId (class depending)
* `Auto Instant Controls Break`: Swd all instant controls from any player on the map e.g gouge
* `Auto Friendly Dispel`: Dispels your party members when they got specific auras
* `Auto Mass Dispel`: Automatically cast `Mass Dispel` on players with the defined aura list. This feature has to be reviewed to calculate a new position when the paladin isnt in direct `LoS` or `15 yards away` (15 yards of radius)
* `Auto Casting Controls Break`: Swd all casting controls from any player on the map e.g sheep
