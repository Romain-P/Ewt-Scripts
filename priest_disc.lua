-- Created by romain-p
-- see updates on http://github.com/romain-p

if not defined then
    defined = true

    Configuration = {
        -- A spell that gonna be casted on stealthed targets
        SPOT_SPELL = 48158
    }

    RunScript(ReadFile("script/shared.lua"))

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

    -- Tracks and kills totems with wound/weapon in order: tremor, cleansing, earthind and others
    function TrackTotems()
        local priority_name, priority

        IterateObjects(function(object, objectName, _)
            if UnitIsEnemy(object, player) and UnitCanAttack(player, object) == 1 then
                if objectName == SharedConfiguration.Totems.TREMOR then
                    priority = object
                    priority_name = objectName
                    return true
                elseif objectName == SharedConfiguration.Totems.EARTHBIND then
                    priority = object
                    priority_name = objectName
                elseif objectName == SharedConfiguration.Totems.CLEANSING and priority_name ~= SharedConfiguration.Totems.EARTHBIND then
                    priority = object
                    priority_name = objectName
                elseif string.find(objectName, SharedConfiguration.Totems.TOTEM_OCCURENCE) ~= nil and priority == nil then
                    priority = object
                    priority_name = objectName
                end
            end

            return false
        end)

        if MeleeRange(priority) then
            RunMacroText("/startattack [@"..priority.."]")
        else
            Cast(RaceSpells.SHOOT, priority, enemy)
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
