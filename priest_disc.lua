-- Created by romain-p
-- see updates on http://github.com/romain-p

if not defined then
    defined = true

    Configuration = {
        -- A spell that gonna be casted on stealthed targets
        SPOT_SPELL = 48158
    }

    RunScript(ReadFile("script/shared.lua"))

    function Heal(unit)

    end

    -- Tracks and kills totems with wound/weapon in order: tremor, cleansing, earthind and others
    function TrackTotems()
        local priority_name, priority

        for i = 1, ObjectCount() do
            local object = ObjectWithIndex(i)
            local objectName = ObjectName(object)

            if UnitIsEnemy(object, player) and UnitCanAttack(player, object) == 1 then
                if objectName == SharedConfiguration.Totems.TREMOR then
                    priority = object
                    priority_name = objectName
                    do break end
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
        end

        local melee = GetDistanceBetweenObjects(player, priority) < 7

        if melee then
            RunMacroText("/startattack [@"..priority.."]")
        else
            CastSpellByID(5019, priority)
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
