PingStats = Ping:NewModule("PingStats", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Ping", true)

local Ping = Ping
local Data = PingData

local GUI = {}
local units = {
    recent = {},
    display = {},
}

local PAGE_SIZE = 34
local TAB_PLAYER = 1
local VIEW_PLAYER_HISTORY = 1
local COLOR_NORMAL = {1, 1, 1}
local COLOR_SAME_FACTION = {0, 1, 0}
local COLOR_KOS = {1, 0, 0}

GUI.ListFrameLines = {
    [VIEW_PLAYER_HISTORY] = {},
}
GUI.ListFrameFields = {
    [VIEW_PLAYER_HISTORY] = {},
}

local SORT = {
    ["PingStatsPlayersNameSort"] = "name",
    ["PingStatsPlayersLevelSort"] = "level",
    ["PingStatsPlayersClassSort"] = "class",
    ["PingStatsPlayersGuildSort"] = "guild",
    ["PingStatsPlayersWinsSort"] = "wins",
    ["PingStatsPlayersLosesSort"] = "loses",	
    ["PingStatsTimeSort"] = "time",	
}

function PingStats:OnInitialize()
    -- create lookup tables for all GUI list lines and buttons
    local views = {
        [VIEW_PLAYER_HISTORY] = "PingStatsPlayerHistoryFrameListFrame",
    }

    for view, frame in pairs(views) do
        GUI.ListFrameLines[view] = {}
        setmetatable(GUI.ListFrameLines[view], {
            __index = function(t, k)
                local b = _G[views[view].."Line"..k]
                if b then
                    rawset(t, k, b)
                    return b
                end
            end,
        })

        for line = 1, PAGE_SIZE do
            GUI.ListFrameFields[view][line] = {}
            setmetatable(GUI.ListFrameFields[view][line], {
                __index = function(t, k)
                    local f = _G[views[view].."Line"..line..k]
                    if f then
                        rawset(t, k, f)
                        return f
                    end
                end,
            })
        end
    end

    -- set initial view
    self.sortBy = "time"	
    self.view = VIEW_PLAYER_HISTORY

    -- localization
    PingStatsKosCheckboxText:SetText(L["KOS"])
    PingStatsRealmCheckboxText:SetText(L["Realm"])
    PingStatsWinsLosesCheckboxText:SetText(L["Won/Lost"])
    PingStatsReasonCheckboxText:SetText(L["Reason"])
    
    table.insert(UISpecialFrames, "PingStatsFrame")
end

function PingStats:OnDisable()
    self:Hide()
end

function PingStats:Show()
    PingStatsFilterBox:SetText("")
    PingStatsKosCheckbox:SetChecked(false)
    PingStatsRealmCheckbox:SetChecked(false)
    PingStatsWinsLosesCheckbox:SetChecked(false)
    PingStatsReasonCheckbox:SetChecked(false)
	local HonorKills, _, HighestRank = GetPVPLifetimeStats("player")
	PingStatsHonorKillsText:SetText(L["HonorKills"]..":  "..HonorKills)
--	PingStatsHonorKillsText:SetText(L["HonorKills"]..":  "..GetStatistic(588))
--	PingStatsPvPDeathsText:SetText(L["PvPDeaths"]..":  "..GetStatistic(1501))
    PingStatsFrame:Show()
    self:Recalulate()
    self:ScheduleRepeatingTimer("Refresh", 1)
end

function PingStats:Hide()
    self:CancelAllTimers()
    PingStatsFrame:Hide()
    self:Cleanup()
end

function PingStats:Toggle()
    if PingStatsFrame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

function PingStats:IsShown()
    return PingStatsFrame:IsShown()
end 

function PingStats:UpdateView()
    local tab = PanelTemplates_GetSelectedTab(PingStatsTabFrame)

    if tab == TAB_PLAYER then
		self.view = VIEW_PLAYER_HISTORY

        PingStatsWinsLosesCheckbox:ClearAllPoints()	
--		PingStatsWinsLosesCheckbox:SetPoint("LEFT", PingStatsKosCheckboxText, "RIGHT", 12, -1)
        PingStatsWinsLosesCheckbox:SetPoint("LEFT", PingStatsKosCheckbox, "RIGHT", 12, -1)

        if (self.sortBy == "name") or (self.sortBy == "level") or (self.sortBy == "class") then
            self.sortBy = "time"
        end 
    end 
    self:Refresh()
end

function PingStats:OnNewEvent(unit)
    self.newevents = true
end

function PingStats:SetSortColumn(name)
    name = SORT[name]
    if name then
        self.sortBy = name
        self:Recalulate()
    end
end

function PingStats:Recalulate()
    if not self:IsShown() or not self:IsEnabled() then
		return
	end

    self.newevents = false
    PingStatsRefreshButton:UnlockHighlight()

    local tab = PanelTemplates_GetSelectedTab(PingStatsTabFrame)

    local i = 1

    if tab == TAB_PLAYER then
        for _, unit in PingData:GetPlayers(self.sortBy) do
            units.recent[i] = unit
            i = i + 1
        end
    end

    for j = i, #units.recent do
		units.recent[j] = nil
	end

    self:Filter()
end

function PingStats:Filter()
    if not self:IsShown() or not self:IsEnabled() then
		return
	end

    local tab = PanelTemplates_GetSelectedTab(PingStatsTabFrame)

    local filter = PingStatsFilterBox:GetText() or ""
    local filterkos = PingStatsKosCheckbox:GetChecked()
    local filterrealm = PingStatsRealmCheckbox:GetChecked()
    local filterpvp = PingStatsWinsLosesCheckbox:GetChecked()
    local filterreason = PingStatsReasonCheckbox:GetChecked()
	
    local i = 1
    for _, unit in ipairs(units.recent) do
        local session = PingData:GetUnitSession(unit)

        if (filter == "" or (unit.name and unit.name:sub(1, string.len(filter)):lower() == filter:lower()) or (unit.guild and unit.guild:sub(1, string.len(filter)):lower() == filter:lower())) and (not filterkos or unit.kos) and (not filterrealm or unit.name and not unit.name:find "-") and (not filterpvp or ((unit.wins and unit.wins > 0) or (unit.loses and unit.loses > 0))) and (not filterreason or unit.reason) then
			units.display[i] = unit
			i = i + 1
        end
    end

    for j = i, #units.display do
		units.display[j] = nil
	end

    self:Refresh()
end

function PingStats:Refresh()
    if self.refreshing then
		return
	end
    self.refreshing = true

    local tab = PanelTemplates_GetSelectedTab(PingStatsTabFrame)
	local view = PingStats.view

    -- set offest location to current scroll position
    local Scroll = PingStatsTabFrameTabContentFrameScrollFrame
    FauxScrollFrame_Update(Scroll, #units.display, PAGE_SIZE, 15)
    local offset = FauxScrollFrame_GetOffset(Scroll)
    Scroll:Show()

    local now = time()

    -- loop through all frame lines
    for row = 1, PAGE_SIZE do
        local line = GUI.ListFrameLines[view][row]

        -- use offset to locate where to start displaying records
        local i = row + offset

        if i <= #units.display then
            local unit = units.display[i]
            local session = PingData:GetUnitSession(unit)

            line.unit = unit

            local age = now - unit.time

            local r, g, b
            if unit.kos and (age < 60) then
                r, g, b = unpack(COLOR_KOS)
            elseif unit.faction and unit.faction == Ping.FactionName then
                r, g, b = unpack(COLOR_SAME_FACTION)
			else
                r, g, b = unpack(COLOR_NORMAL)
            end

            if tab == TAB_PLAYER then
                local name = GUI.ListFrameFields[view][row]["Name"]
                name:SetText(unit.name)
                name:SetTextColor(r, g, b)

                local level = GUI.ListFrameFields[view][row]["Level"]
                level:SetText(unit.level)
                level:SetTextColor(r, g, b)

                local class = GUI.ListFrameFields[view][row]["Class"]
				local classtext = unit.class
				if classtext then
					classtext = (L[classtext])
				else
					classtext = "?"
				end	
                class:SetText(classtext)
                class:SetTextColor(r, g, b)

                local guild = GUI.ListFrameFields[view][row]["Guild"]
                guild:SetText(unit.guild or "?")
                guild:SetTextColor(r, g, b)

                local wins = GUI.ListFrameFields[view][row]["Wins"]
                wins:SetText(unit.wins or 0)
                wins:SetTextColor(r, g, b)

                local loses = GUI.ListFrameFields[view][row]["Loses"]
                loses:SetText(unit.loses or 0)
                loses:SetTextColor(r, g, b)

				local reason = GUI.ListFrameFields[view][row]["Reason"]
				local reasonText = ""
				if unit.reason then
					for reason in pairs(unit.reason) do
						if reasonText ~= "" then
							reasonText = reasonText..", "
						end
						if reason == L["KOSReasonOther"] then
							reasonText = reasonText..unit.reason[reason]
						else
							reasonText = reasonText..reason
						end
					end
				end
                reason:SetText(reasonText or "")
                reason:SetTextColor(r, g, b)
					
				local zone = GUI.ListFrameFields[view][row]["Zone"]  
				local location = unit.zone
					if location and unit.subZone and unit.subZone ~= "" and unit.subZone ~= location then
						location = unit.subZone..", "..location
					end
				zone:SetText(location or "?")
                zone:SetTextColor(r, g, b)

				local time = GUI.ListFrameFields[view][row]["Time"]
                time:SetText((unit.time and unit.time > 0) and Ping:FormatTime(unit.time) or "?")				
                time:SetTextColor(r, g, b)

                local tList = GUI.ListFrameFields[view][row]["List"]
                local f = ""
				for key, value in pairs(PingPerCharDB.KOSData) do
					-- find units that match
					local KoSname = key
					if unit.name == KoSname then
						f = f .. "x"
					end
				end		
                tList:SetText(f)
                tList:SetTextColor(r, g, b)
            end
            line:Show()
        else
            line:Hide()
        end
    end

    self.refreshing = false
end

function PingStats:OnRefreshButtonUpdate(frame, elapsed)
    if not self.newevents then
		return
	end

    local timer = frame.timer + elapsed

    if (timer < .5) then
        frame.timer = timer
        return
    end

    while (timer >= .5) do
        timer = timer - .5
    end
    frame.timer = timer

    if (frame.state) then
        frame:UnlockHighlight()
        frame.state = nil
    else
        frame:LockHighlight()
        frame.state = true
    end    
end

-- remove all references to units
function PingStats:Cleanup()
    for _, lines in pairs(GUI.ListFrameLines) do
        for _, line in pairs(lines) do
            line.unit = nil
        end
    end

    for i in ipairs(units.recent) do units.recent[i] = nil end
    for i in ipairs(units.display) do units.display[i] = nil end
end

function Ping_CreateStatsDropdown(node)
    local info = {}
    local unit = node.unit
    local session = PingData:GetUnitSession(unit)
    if UIDROPDOWNMENU_MENU_LEVEL == 1 then
        info = UIDropDownMenu_CreateInfo()
        info.isTitle = true
        info.text = unit.name
		info.notCheckable = true
        UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

		if not unit.kos then
			info.isTitle = nil
			info.notCheckable = true
			info.hasArrow = false
			info.disabled = nil
			info.text = L["AddToKOSList"]
			info.func = function()
				Ping:ToggleKOSPlayer(true, unit.name)
			end
			info.value = nil
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			
			info.isTitle = nil
			info.notCheckable = true
			info.hasArrow = false
			info.disabled = nil
			info.text = L["RemoveFromStatsList"]
			info.func = function() 
				Ping:RemovePlayerDataFromStats(unit.name)
				PingStats:Recalulate()
			end 
			info.value = nil
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		else
			info = UIDropDownMenu_CreateInfo()
			info.notCheckable = true
			info.text = L["KOSReasonDropDownMenu"]
			info.value = unit
			info.func = function()
				Ping:SetKOSReason(unit.name, L["KOSReasonOther"], other)
			end
			info.checked = false
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			
			info.isTitle = nil
			info.notCheckable = true
			info.hasArrow = false
			info.disabled = nil
			info.text = L["RemoveFromKOSList"]
			info.func = function()
				Ping:ToggleKOSPlayer(false, unit.name)
			end
			info.value = nil
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

			info.isTitle = nil
			info.notCheckable = true
			info.hasArrow = false
			info.disabled = nil
			info.text = L["KOSReasonClear"]
			info.func = function()
				Ping:SetKOSReason(unit.name, nil)
			end
			info.value = nil
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end	

        elseif UIDROPDOWNMENU_MENU_LEVEL == 2 then
    end 
end

function Ping:ShowStatsDropDown(node, button)
    if button ~= "RightButton" then
		return
	end
    GameTooltip:Hide()
	PingStatsDropDownMenu.unit = node.unit
    local cursor = GetCursorPosition() / UIParent:GetEffectiveScale()
    local center = node:GetLeft() + (node:GetWidth() / 2)
    UIDropDownMenu_Initialize(PingStatsDropDownMenu, Ping_CreateStatsDropdown, "MENU")
    UIDropDownMenu_SetAnchor(PingStatsDropDownMenu, cursor - center, 0, "TOPRIGHT", node, "TOP")
    CloseDropDownMenus(1)
    ToggleDropDownMenu(1, nil, PingStatsDropDownMenu)    
end