-- Created by romain-p
-- see updates on http://github.com/romain-p

-- init all vars

if not launcher then
    launcher = true

    function loadscript(named)
        RunScript(ReadFile("script/" .. named .. ".lua"))
    end

    loadscript("shared_spells")
    loadscript("shared_units")
    loadscript("shared_filters")
    loadscript("shared_digest")

    all_scripts = {
        ["PRIEST"] = "priest_disc",
        ["WARRIOR"] = nil,
        ["ROGUE"] = nil,
        ["MAGE"] = nil,
        ["SHAMAN"] = nil,
        ["WARLOCK"] = nil,
        ["DRUID"] = nil,
        ["HUNTER"] = nil,
        ["PALADIN"] = nil,
        ["DEATHKNIGHT"] = nil
    }

    session = all_scripts[player_class]
end

if session == nil then
    print("Launcher: no script found for " .. player_class)
else
    loadscript(session)
end