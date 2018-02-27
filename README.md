## Ewt Scripts

All features in need are performing `LoS`, `range`, `cooldown` and `unit type` checks  
Each analysis doesnt need to have defined unit e.g `target`/`focus`/`arena123`. The script performs checks analysing all map objects  
`No fps`are taken with my scripts, I `optimized` all the code

* If you like my project, you can star it or even give me a donation ;)  
[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=SHFWRJ56GGZDE)

### Installation

* Make a folder called `script` in your world of warcraft folder  
* Put all .lua files in this folder
* Example of location: `your_wow_folder/script/shared.lua`
* Then select `Advanced Lua Unlock` in the EWT UI
* Finally enable it with the ewt-command e.g `.loadfile script/priest_disc.lua`

### Documentation: Shared-API

Shared-API holds units in variables that are frequently used, use them as well!  
See more specific functions directly in the Wiki

* [Click Here](https://github.com/Romain-P/Ewt-Scripts/wiki)


#### Common Features

* `Auto Fakecast Overpower`: Fakecast instant overpowers from other warrior scripters
* `Feign Death Bypass`: Auto re-target the hunter
* `Mirror Images Bypass`: Auto re-target the mage
* `Stealth Spot`: Analyses the world map objects and spot all stealth players with the defined spellId (class depending)
* `Arena Auto Focus`: Auto focus arena1/arena2 depending of your target (works on 2s only)
* `Auto Intelligent Break`: stopcasting and cast a defined spell on reflect/grounding totem
* `Fakecast pummel/kick`: fakecast kick when shadowstep is used, same for pummel when berzek stance used
* `Auto Friendly Dispel`: Dispels your party members when they got specific auras
* `Auto Enemy Dispel`: Dispels the given lists when found on the world map enemies
* `Caster's Real Target`: can detect if someone is casting on you (if you are the focus for example)

```lua
    -- First setup the list of spells you want to enable the feature
    -- You can add any spell you want, you can call AddDangerousSpells as much as you want
    AddDangerousSpells({MageSpells.SHEEP, WarlockSpells.SEDUCTION});
    AddDangerousSpells(Configuration.SOME_LIST);
    
    -- Then call this function to know if a world unit is casting one of these spells on you ;)
    IsCastingOnMe(object);
    
    -- See configuration for more details (sound + alert can be enabled/disabled)
```

* `Advanced Totem Tracker`: Tracks and kills totem, see `TOTEM_TRACKER` configuration for more customization
```lua
    -- Make this macro and press it to kill a totem
    /script TrackTotems()
```

#### Priest Scripts

See [Priest Configuration](https://github.com/Romain-P/Ewt-Scripts/blob/master/priest_disc.lua#L8) for more details and customisation

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
* `Auto Instant Controls Break`: Swd all instant controls from any player on the map e.g gouge
* `Auto Mass Dispel`: Automatically cast `Mass Dispel` on players with the defined aura list. This feature has to be reviewed to calculate a new position when the paladin isnt in direct `LoS` or `15 yards away` (15 yards of radius)
* `Auto Casting Controls Break`: Swd all casting controls from any player on the map e.g sheep