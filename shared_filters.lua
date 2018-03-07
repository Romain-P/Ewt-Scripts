-- Created by romain-p
-- see updates on http://github.com/romain-p

if not shared_filters then
    shared_filters = true

    -- Return true if a given unit health is under a given percent
    function HealthIsUnder(unit, percent)
        return (((100 * UnitHealth(unit) / UnitHealthMax(unit))) < percent)
    end

    -- Return true if the whole units have health > x
    function HealthNotUnder(units, percent)
        for _, unit in ipairs(units) do
            if UnitExists(unit) and HealthIsUnder(unit, percent) then
                return false
            end
        end
        return true
    end

    -- Check if the whole party members have their life upper 40%
    filter_party_health = function() HealthNotUnder(Party, 40) end
end