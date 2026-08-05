local SM = LibStub:GetLibrary("LibSharedMedia-3.0")
local HBDP = LibStub("HereBeDragons-Pins-2.0")
local Events = LibStub("AceEvent-3.0")
local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:GetLocale("Ping")
local _

local FULL_ARTWORK_STYLES = {
	obsidian=true, arcane=true, warcamp=true, minimal=true,
	clean=true, unitframe=true, villain=true,
}

local function usesFullArtwork()
	return Ping.db and Ping.db.profile and FULL_ARTWORK_STYLES[Ping.db.profile.ArtworkStyle] == true
end

--++ Local FrameFlash functions derived from Blizzard code ++--
local PingFrameFlashManager = CreateFrame("FRAME");
local SPYFADEFRAMES = {};
local SPYFLASHFRAMES = {};
local PingFrameFlashTimers = {};
local PingFrameFlashTimerRefCount = {};

-- Fucntion to see if a frame is fading
function PingFrameIsFading(frame)
	for index, value in pairs(SPYFADEFRAMES) do
		if ( value == frame ) then
			return 1;
		end
	end
	return nil;
end

-- Function to stop flashing --
local function PingFrameFlashStop(frame)
    tDeleteItem(SPYFLASHFRAMES, frame);
    frame:SetAlpha(1.0);
    frame.flashTimer = nil;
    if (frame.syncId) then
        PingFrameFlashTimerRefCount[frame.syncId] = PingFrameFlashTimerRefCount[frame.syncId]-1;
        if (PingFrameFlashTimerRefCount[frame.syncId] == 0) then
            PingFrameFlashTimers[frame.syncId] = nil;
            PingFrameFlashTimerRefCount[frame.syncId] = nil;
        end
        frame.syncId = nil;
    end
    if ( frame.showWhenDone ) then
        frame:Show();
    else
        frame:Hide();
    end
end

-- Call every frame to update flashing frames  --
local function PingFrameFlash_OnUpdate(self, elapsed)
    local frame;
    local index = #SPYFLASHFRAMES;
     
    -- Update timers for all synced frames
    for syncId, timer in pairs(PingFrameFlashTimers) do
        PingFrameFlashTimers[syncId] = timer + elapsed;
    end
     
    while SPYFLASHFRAMES[index] do
        frame = SPYFLASHFRAMES[index];
        frame.flashTimer = frame.flashTimer + elapsed;
        if ( (frame.flashTimer > frame.flashDuration) and frame.flashDuration ~= -1 ) then
            PingFrameFlashStop(frame);
        else
            local flashTime = frame.flashTimer;
            local alpha;
            if (frame.syncId) then
                flashTime = PingFrameFlashTimers[frame.syncId];
            end
            flashTime = flashTime%(frame.fadeInTime+frame.fadeOutTime+(frame.flashInHoldTime or 0)+(frame.flashOutHoldTime or 0));
            if (flashTime < frame.fadeInTime) then
                alpha = flashTime/frame.fadeInTime;
            elseif (flashTime < frame.fadeInTime+(frame.flashInHoldTime or 0)) then
                alpha = 1;
            elseif (flashTime < frame.fadeInTime+(frame.flashInHoldTime or 0)+frame.fadeOutTime) then
                alpha = 1 - ((flashTime - frame.fadeInTime - (frame.flashInHoldTime or 0))/frame.fadeOutTime);
            else
                alpha = 0;
            end
            frame:SetAlpha(alpha);
            frame:Show();
        end
        -- Loop in reverse so that removing frames is safe
        index = index - 1;
    end
    if ( #SPYFLASHFRAMES == 0 ) then
        self:SetScript("OnUpdate", nil);
    end
end

-- Function to start a frame flashing
local function PingFrameFlash(frame, fadeInTime, fadeOutTime, flashDuration, showWhenDone, flashInHoldTime, flashOutHoldTime, syncId)
    if ( frame ) then
        local index = 1;
        -- If frame is already set to flash then return
        while SPYFLASHFRAMES[index] do		
            if ( SPYFLASHFRAMES[index] == frame ) then
                return;
            end
            index = index + 1;
        end
        if (syncId) then
            frame.syncId = syncId;
            if (PingFrameFlashTimers[syncId] == nil) then
                PingFrameFlashTimers[syncId] = 0;
                PingFrameFlashTimerRefCount[syncId] = 0;
            end
            PingFrameFlashTimerRefCount[syncId] = PingFrameFlashTimerRefCount[syncId]+1;
        else
            frame.syncId = nil;
        end
        -- Time it takes to fade in a flashing frame
        frame.fadeInTime = fadeInTime;
        -- Time it takes to fade out a flashing frame
        frame.fadeOutTime = fadeOutTime;
        -- How long to keep the frame flashing
        frame.flashDuration = flashDuration;
        -- Show the flashing frame when the fadeOutTime has passed
        frame.showWhenDone = showWhenDone;
        -- Internal timer
        frame.flashTimer = 0;
        -- How long to hold the faded in state
        frame.flashInHoldTime = flashInHoldTime;
        -- How long to hold the faded out state
        frame.flashOutHoldTime = flashOutHoldTime;
         
        tinsert(SPYFLASHFRAMES, frame);		
         
       PingFrameFlashManager:SetScript("OnUpdate", PingFrameFlash_OnUpdate);
    end
end

function Ping:SetFontSize(string, size)
	local Font, Height, Flags = string:GetFont()
	string:SetFont(Font, size, Flags)
end

function Ping:CreateMapNote(num)
	local notemin = 1
	if num < notemin or Ping.MapNoteList[num] then
		return
	end

	local worldIcon = CreateFrame("Button", "Ping_MapNoteList_world"..num, WorldMapFrame)
	worldIcon:SetFrameStrata(WorldMapFrame:GetFrameStrata())
	worldIcon:SetParent(WorldMapFrame)
	worldIcon:SetFrameLevel(WorldMapFrame:GetFrameLevel() + 5)	
	worldIcon:SetScript("OnEnter", function(self)
		Ping:ShowMapTooltip(self, true)
	end)
	worldIcon:SetScript("OnLeave", function(self)
		Ping:ShowMapTooltip(self, false)
	end)
	worldIcon:SetWidth(18)
	worldIcon:SetHeight(18)
	worldIcon.id = num

	local worldTexture = worldIcon:CreateTexture(nil, "OVERLAY")
	worldTexture:SetTexture("Interface\\WorldStateFrame\\"..Ping.EnemyFactionName.."Icon.blp")
	worldTexture:SetAllPoints(worldIcon)
	worldIcon.texture = worldTexture

	local miniIcon = CreateFrame("Button", "Ping_MapNoteList_mini"..num, Minimap)
	miniIcon:SetFrameStrata(Minimap:GetFrameStrata())
	miniIcon:SetParent(Minimap)
	miniIcon:SetFrameLevel(Minimap:GetFrameLevel() + 5)
	miniIcon:SetScript("OnEnter", function(self)
		Ping:ShowMapTooltip(self, true)
	end)
	miniIcon:SetScript("OnLeave", function(self)
		Ping:ShowMapTooltip(self, false)
	end)
	miniIcon:SetWidth(14)
	miniIcon:SetHeight(14)
	miniIcon.id = num

	local miniTexture = miniIcon:CreateTexture(nil, "OVERLAY")
	miniTexture:SetTexture("Interface\\WorldStateFrame\\"..Ping.EnemyFactionName.."Icon.blp")
	miniTexture:SetAllPoints(miniIcon)
	miniIcon.texture = worldTexture

	Ping.MapNoteList[num] = {}
	Ping.MapNoteList[num].displayed = false
	Ping.MapNoteList[num].continentID = 0
	Ping.MapNoteList[num].MapID = 0
	Ping.MapNoteList[num].mapX = 0
	Ping.MapNoteList[num].mapY = 0
	Ping.MapNoteList[num].worldIcon = worldIcon
	Ping.MapNoteList[num].worldIcon:Hide()
	Ping.MapNoteList[num].miniIcon = miniIcon
	Ping.MapNoteList[num].miniIcon:Hide()
end

function Ping:CreateRow(num)
	local rowmin = 1
	if num < rowmin or Ping.MainWindow.Rows[num] then
		return
	end

	local row = CreateFrame("Button", "Ping_MainWindow_Bar"..num, Ping.MainWindow, "PingSecureActionButtonTemplate")
	row:SetPoint("TOPLEFT", Ping.MainWindow, "TOPLEFT", 2, -34 - (Ping.db.profile.MainWindow.RowHeight + Ping.db.profile.MainWindow.RowSpacing) * (num - 1))
	row:SetHeight(Ping.db.profile.MainWindow.RowHeight)
	row:SetWidth(Ping.MainWindow:GetWidth() - 4)

	Ping:SetupBar(row)
	Ping.MainWindow.Rows[num] = row
	Ping.MainWindow.Rows[num]:Hide()
	row.id = num
end

function Ping:SetupBar(row)
	row.StatusBar = CreateFrame("StatusBar", nil, row)
	row.StatusBar:SetAllPoints(row)

	local BarTexture
	if not BarTexture then
		BarTexture = Ping.db.profile.BarTexture
	end

	if not BarTexture then
		BarTexture = SM:Fetch("statusbar", "flat")
	else
		BarTexture = SM:Fetch("statusbar", BarTexture)
	end
	row.StatusBar:SetStatusBarTexture(BarTexture)
	row.StatusBar:SetStatusBarColor(.5, .5, .5, 0.8)
	row.StatusBar:SetMinMaxValues(0, 100)
	row.StatusBar:SetValue(100)
	row.StatusBar:Show()

	row.LeftText = row.StatusBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.LeftText:SetPoint("LEFT", row.StatusBar, "LEFT", 2, 0)
	row.LeftText:SetJustifyH("LEFT")
	row.LeftText:SetHeight(Ping.db.profile.MainWindow.TextHeight)
	row.LeftText:SetTextColor(1, 1, 1, 1)
	Ping:SetFontSize(row.LeftText, math.max(Ping.db.profile.MainWindow.RowHeight * 0.75, Ping.db.profile.MainWindow.RowHeight - 3))
	Ping:AddFontString(row.LeftText)

	row.RightText = row.StatusBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.RightText:SetPoint("RIGHT", row.StatusBar, "RIGHT", -2, 0)	
	row.RightText:SetJustifyH("RIGHT")
	row.RightText:SetTextColor(1, 1, 1, 1)
	Ping:SetFontSize(row.RightText, math.max(Ping.db.profile.MainWindow.RowHeight * 0.65, Ping.db.profile.MainWindow.RowHeight - 12))		
	Ping:AddFontString(row.RightText)

	Ping.Colors:RegisterFont("Bar", "Bar Text", row.LeftText)
	Ping.Colors:RegisterFont("Bar", "Bar Text", row.RightText)

	-- Healer marker: a small independent glyph whose color is driven by
	-- Ping:ApplyRowText (not the Bar Text color), so it can stay green.
	row.HealerMarker = row.StatusBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.HealerMarker:SetHeight(Ping.db.profile.MainWindow.TextHeight)
	Ping:SetFontSize(row.HealerMarker, math.max(Ping.db.profile.MainWindow.RowHeight * 0.9, Ping.db.profile.MainWindow.RowHeight - 2))
	Ping:AddFontString(row.HealerMarker)
	row.HealerMarker:Hide()

	-- Thin left-edge accent (green for healers, red for KoS).
	row.RowEdge = row.StatusBar:CreateTexture(nil, "OVERLAY")
	row.RowEdge:SetTexture("Interface\\Buttons\\WHITE8X8")
	row.RowEdge:SetPoint("TOPLEFT", row.StatusBar, "TOPLEFT", 0, 0)
	row.RowEdge:SetPoint("BOTTOMLEFT", row.StatusBar, "BOTTOMLEFT", 0, 0)
	row.RowEdge:SetWidth(3)
	row.RowEdge:Hide()
end

function Ping:UpdateBarTextures()
	for k, v in pairs(Ping.MainWindow.Rows) do
		v.StatusBar:SetStatusBarTexture(SM:Fetch(SM.MediaType.STATUSBAR, Ping.db.profile.BarTexture))
	end
	if Ping.db.profile.Font then
		Ping:SetFont(Ping.db.profile.Font)
	end
	Ping:ApplyThemeFonts()
end

function Ping:SetBarTextures(handle)
	local Texture = SM:Fetch(SM.MediaType.STATUSBAR,handle)
	Ping.db.profile.BarTexture=handle
	for k, v in pairs(Ping.MainWindow.Rows) do
		v.StatusBar:SetStatusBarTexture(Texture)
	end
end

local info = {}
function Ping_CreateBarDropdown(self, level)
	if not level then return end
	for k in pairs(info) do info[k] = nil end
	if self and self.relativeTo.LeftText then
		local player = self.relativeTo.LeftText:GetText()
		if level == 1 then
			info.isTitle = 1
			info.text = player
			info.notCheckable = true
			UIDropDownMenu_AddButton(info, level)

			info = UIDropDownMenu_CreateInfo()

			if Ping.db.profile.CurrentList == 1 or Ping.db.profile.CurrentList == 2 then
				info.isTitle = nil
				info.notCheckable = true
				info.hasArrow = true
				info.disabled = nil
				info.text = L["AnnounceDropDownMenu"]
				info.value = { ["Key"] = L["AnnounceDropDownMenu"] }
				info.arg1 = self.relativeTo.name
				UIDropDownMenu_AddButton(info, level)
			end

			if Ping.db.profile.TomTomOnAltClick then
				info.isTitle = nil
				info.notCheckable = true
				info.hasArrow = false
				info.disabled = not Ping:HasTomTom()
				info.text = L["TomTomWaypoint"]
				info.func = function() Ping:SetTomTomWaypoint(player) end
				info.value = nil
				info.arg1 = self.relativeTo.name
				UIDropDownMenu_AddButton(info, level)
			end

			if not PingPerCharDB.KOSData[player] then
				info.isTitle = nil
				info.notCheckable = true
				info.hasArrow = false
				info.disabled = nil
				info.text = L["AddToKOSList"]
				info.func = function() Ping:ToggleKOSPlayer(true, player) end
				info.value = nil
				info.arg1 = self.relativeTo.name
				UIDropDownMenu_AddButton(info, level)
			else
				info.isTitle = nil
				info.notCheckable = true
				info.hasArrow = true
				info.disabled = nil
				info.text = L["KOSReasonDropDownMenu"]
				info.value = { ["Key"] = L["KOSReasonDropDownMenu"] }
				info.arg1 = self.relativeTo.name
				UIDropDownMenu_AddButton(info, level)

				info.isTitle = nil
				info.notCheckable = true
				info.hasArrow = false
				info.disabled = nil
				info.text = L["RemoveFromKOSList"]
				info.func = function() Ping:ToggleKOSPlayer(false, player) end
				info.value = nil
				info.arg1 = self.relativeTo.name
				UIDropDownMenu_AddButton(info, level)
			end
			if not PingPerCharDB.IgnoreData[player] then
				info.isTitle = nil
				info.notCheckable = true
				info.hasArrow = false
				info.disabled = nil
				info.text = L["AddToIgnoreList"]
				info.func = function() Ping:ToggleIgnorePlayer(true, player) end
				info.value = nil
				info.arg1 = self.relativeTo.name
				UIDropDownMenu_AddButton(info, level)
			else
				info.isTitle = nil
				info.notCheckable = true
				info.hasArrow = false
				info.disabled = nil
				info.text = L["RemoveFromIgnoreList"]
				info.func = function() Ping:ToggleIgnorePlayer(false, player) end
				info.value = nil
				info.arg1 = self.relativeTo.name
				UIDropDownMenu_AddButton(info, level)
			end

			if Ping.db.profile.CurrentList == 1 then
				info.isTitle = nil
				info.notCheckable = true
				info.disabled = nil
				info.text = L["Clear"]
				info.func = function() Ping:RemovePlayerFromList(player) end
				info.value = nil
				info.arg1 = self.relativeTo.name
				UIDropDownMenu_AddButton(info, level)
			end
		elseif level == 2 then
			local key = UIDROPDOWNMENU_MENU_VALUE["Key"]
			info = UIDropDownMenu_CreateInfo()

			if key == L["AnnounceDropDownMenu"] and (Ping.db.profile.CurrentList == 1 or Ping.db.profile.CurrentList == 2) then
				info.isTitle = nil
				info.notCheckable = true
				info.hasArrow = false
				info.disabled = nil
				info.text = L["PartyDropDownMenu"]
				info.func = function() Ping:AnnouncePlayer(player, "PARTY") end
				info.value = { ["Key"] = key; ["Subkey"] = 1; }
				info.arg1 = self.relativeTo.name
				UIDropDownMenu_AddButton(info, level)

				info.isTitle = nil
				info.notCheckable = true
				info.hasArrow = false
				info.disabled = nil
				info.text = L["RaidDropDownMenu"]
				info.func = function() Ping:AnnouncePlayer(player, "RAID") end
				info.value = { ["Key"] = key; ["Subkey"] = 2; }
				info.arg1 = self.relativeTo.name
				UIDropDownMenu_AddButton(info, level)

				info.isTitle = nil
				info.notCheckable = true
				info.hasArrow = false
				info.disabled = nil
				info.text = L["GuildDropDownMenu"]
				info.func = function() Ping:AnnouncePlayer(player, "GUILD") end
				info.value = { ["Key"] = key; ["Subkey"] = 3; }
				info.arg1 = self.relativeTo.name
				UIDropDownMenu_AddButton(info, level)

				info.isTitle = nil
				info.notCheckable = true
				info.hasArrow = false
				info.disabled = nil
				info.text = L["LocalDefenseDropDownMenu"]
				info.func = function() Ping:AnnouncePlayer(player, "LOCAL") end
				info.value = { ["Key"] = key; ["Subkey"] = 4; }
				info.arg1 = self.relativeTo.name
				UIDropDownMenu_AddButton(info, level)
			end

			if key == L["KOSReasonDropDownMenu"] then
				for i = 1, Ping_KOSReasonListLength do
					local reason = Ping_KOSReasonList[i]
					info.isTitle = nil
					info.notCheckable = true
					info.hasArrow = true
					info.disabled = nil
					info.text = reason.title
					info.value = { ["Key"] = key; ["Subkey"] = reason.title; ["Index"] = i; }
					info.arg1 = self.relativeTo.name
					UIDropDownMenu_AddButton(info, level)
				end

				info.isTitle = nil
				info.notCheckable = true
				info.hasArrow = false
				info.disabled = nil
				info.text = L["KOSReasonClear"]
				info.func = function()
					Ping:SetKOSReason(player, nil)
					CloseDropDownMenus(1)
				end
				info.value = nil
				info.arg1 = self.relativeTo.name
				UIDropDownMenu_AddButton(info, level)
			end
		elseif level == 3 then
			local key = UIDROPDOWNMENU_MENU_VALUE["Key"]
			local subkey = UIDROPDOWNMENU_MENU_VALUE["Subkey"]
			local index = UIDROPDOWNMENU_MENU_VALUE["Index"]
			local playerData = PingPerCharDB.PlayerData[player]
			if key == L["KOSReasonDropDownMenu"] then
				for v, reason in pairs(Ping_KOSReasonList[index].content) do
					info.isTitle = nil
					info.notCheckable = false
					info.hasArrow = false
					info.disabled = nil
					info.text = reason
					info.func = function()
						Ping:SetKOSReason(player, reason)
						CloseDropDownMenus(1)
					end
					info.checked = nil
					if playerData and playerData.reason and playerData.reason[reason] == true then
						info.checked = true
					end
					info.value = { ["Key"] = subkey; ["Subkey"] = index; }
					info.arg1 = self.relativeTo.name
					UIDropDownMenu_AddButton(info, level)
				end
			end
		end
	end
end

function Ping:BarDropDownOpen(myframe)
	Ping_BarDropDownMenu = CreateFrame("Frame", "Ping_BarDropDownMenu", myframe)
	Ping_BarDropDownMenu.displayMode = "MENU"
	Ping_BarDropDownMenu.initialize	= Ping_CreateBarDropdown

	local leftPos = myframe:GetLeft()
	local rightPos = myframe:GetRight()
	local side
	local oside
	if not rightPos then
		rightPos = 0
	end
	if not leftPos then
		leftPos = 0
	end

	local rightDist = GetScreenWidth() - rightPos

	if leftPos and rightDist < leftPos then
		side = "TOPLEFT"
		oside = "TOPRIGHT"
	else
		side = "TOPRIGHT"
		oside = "TOPLEFT"
	end
	UIDropDownMenu_SetAnchor(Ping_BarDropDownMenu, 0, 0, oside, myframe, side)
end

function Ping:SetupMainWindowButtons()
	for k, v in pairs(Ping.db.profile.MainWindow.Buttons) do
		if v then
			Ping.MainWindow[k]:Show()
			Ping.MainWindow[k]:SetWidth(16)
		else
			Ping.MainWindow[k]:SetWidth(1)
			Ping.MainWindow[k]:Hide()
		end
	end
end

function Ping:CreateMainWindow()
	if not Ping.MainWindow then
		Ping.MainWindow = Ping:CreateFrame("Ping_MainWindow", L["Nearby"], 34, 200,
		function()
			Ping.db.profile.MainWindowVis = true
		end,
		function()
			Ping.db.profile.MainWindowVis = false
		end)

		Ping:UpdateMainWindow()
	
		local theFrame = Ping.MainWindow
		theFrame:SetResizable(true)
--		theFrame:SetMinResize(90, 34)
--		theFrame:SetMaxResize(300, 264)
		theFrame:SetResizeBounds(90, 34, 300, 264)
		theFrame:SetScript("OnSizeChanged",
		function(self)
			if (self.isResizing) then
				Ping:ResizeMainWindow()
			end
		end)
		theFrame:SetMovable(true)
        theFrame:EnableMouseWheel(true)	
		theFrame:SetScript("OnMouseWheel", function(self, delta)
			Ping:MainWindowScroll(delta)
		end)
		theFrame.TitleClick = CreateFrame("FRAME", nil, theFrame)
		theFrame.TitleClick:SetAllPoints(theFrame.Title)
		theFrame.TitleClick:EnableMouse(true)
		theFrame.TitleClick:SetScript("OnMouseDown", function(self, button) 
			local parent = self:GetParent()
			if not InCombatLockdown() and (((not parent.isLocked) or (parent.isLocked == 0)) and (button == "LeftButton")) then
				Ping:SetWindowTop(parent)
				parent:StartMoving();
				parent.isMoving = true;
			end
		end)
		theFrame.TitleClick:SetScript("OnMouseUp", function(self) 
			local parent = self:GetParent()
			if (parent.isMoving) then
				parent:StopMovingOrSizing();
				parent.isMoving = false;
				Ping:SaveMainWindowPosition()
			end
		end)
        theFrame.TitleClick:EnableMouseWheel(true)		
		theFrame.TitleClick:SetScript("OnMouseWheel", function(self, delta)
			if not IsAltKeyDown() then
				return
			end
			if delta > 0 then
				Ping:MainWindowPrevMode()
			else
				Ping:MainWindowNextMode()
			end
		end)

		if not Ping.db.profile.InvertPing then
			theFrame.DragBottomRight = CreateFrame("Button", "PingResizeGripRight", theFrame)
			theFrame.DragBottomRight:Show()
			theFrame.DragBottomRight:SetFrameLevel(theFrame:GetFrameLevel() + 10)
			theFrame.DragBottomRight:SetNormalTexture("Interface\\AddOns\\Ping\\Textures\\resize-bottomright.tga")
			theFrame.DragBottomRight:SetHighlightTexture("Interface\\AddOns\\Ping\\Textures\\resize-bottomright.tga")
			theFrame.DragBottomRight:SetWidth(16)
			theFrame.DragBottomRight:SetHeight(16)
			theFrame.DragBottomRight:SetAlpha(0)
			theFrame.DragBottomRight:SetPoint("BOTTOMRIGHT", theFrame, "BOTTOMRIGHT", 0, 0)
			theFrame.DragBottomRight:EnableMouse(true)
			theFrame.DragBottomRight:SetScript("OnEnter", function(self)
				theFrame.DragBottomRight:SetAlpha(1)
			end)
			theFrame.DragBottomRight:SetScript("OnMouseDown", function(self, button)
				if not InCombatLockdown() and (((not self:GetParent().isLocked) or (self:GetParent().isLocked == 0)) and (button == "LeftButton")) then 
					self:GetParent().isResizing = true;
					self:GetParent():StartSizing("BOTTOMRIGHT") 
				end
			end)
			theFrame.DragBottomRight:SetScript("OnMouseUp", function(self, button)
				if self:GetParent().isResizing == true then
					self:GetParent():StopMovingOrSizing();
					Ping:SaveMainWindowPosition();
					Ping:RefreshCurrentList();
					self:GetParent().isResizing = false;
				end
			end)
			theFrame.DragBottomRight:SetScript("OnLeave", function(self)
				theFrame.DragBottomRight:SetAlpha(0)
			end)
		
			theFrame.DragBottomLeft = CreateFrame("Button", "PingResizeGripLeft", theFrame)
			theFrame.DragBottomLeft:Show()
			theFrame.DragBottomLeft:SetFrameLevel(theFrame:GetFrameLevel() + 10)
			theFrame.DragBottomLeft:SetNormalTexture("Interface\\AddOns\\Ping\\Textures\\resize-bottomleft.tga")
			theFrame.DragBottomLeft:SetHighlightTexture("Interface\\AddOns\\Ping\\Textures\\resize-bottomleft.tga")
			theFrame.DragBottomLeft:SetWidth(16)
			theFrame.DragBottomLeft:SetHeight(16)
			theFrame.DragBottomLeft:SetAlpha(0)		
			theFrame.DragBottomLeft:SetPoint("BOTTOMLEFT", theFrame, "BOTTOMLEFT", 0, 0)
			theFrame.DragBottomLeft:EnableMouse(true)
			theFrame.DragBottomLeft:SetScript("OnEnter", function(self)
				theFrame.DragBottomLeft:SetAlpha(1)
			end)
			theFrame.DragBottomLeft:SetScript("OnMouseDown", function(self, button)
				if not InCombatLockdown() and (((not self:GetParent().isLocked) or (self:GetParent().isLocked == 0)) and (button == "LeftButton")) then
					self:GetParent().isResizing = true;
					self:GetParent():StartSizing("BOTTOMLEFT")
				end
			end)
			theFrame.DragBottomLeft:SetScript("OnMouseUp", function(self, button)
				if self:GetParent().isResizing == true then
					self:GetParent():StopMovingOrSizing();
					Ping:SaveMainWindowPosition();
					Ping:RefreshCurrentList();
					self:GetParent().isResizing = false;
				end
			end)
			theFrame.DragBottomLeft:SetScript("OnLeave", function(self)
				theFrame.DragBottomLeft:SetAlpha(0)
			end)
		else
			theFrame.DragTopRight = CreateFrame("Button", "PingResizeGripRight", theFrame)
			theFrame.DragTopRight:Show()
			theFrame.DragTopRight:SetFrameLevel(theFrame:GetFrameLevel() + 10)
			theFrame.DragTopRight:SetNormalTexture("Interface\\AddOns\\Ping\\Textures\\resize-topright.tga")
			theFrame.DragTopRight:SetHighlightTexture("Interface\\AddOns\\Ping\\Textures\\resize-topright.tga")
			theFrame.DragTopRight:SetWidth(16)
			theFrame.DragTopRight:SetHeight(16)
			theFrame.DragTopRight:SetAlpha(0)
			theFrame.DragTopRight:SetPoint("TOPRIGHT", theFrame, "TOPRIGHT", 0, -32)
			theFrame.DragTopRight:EnableMouse(true)
			theFrame.DragTopRight:SetScript("OnEnter", function(self)
				theFrame.DragTopRight:SetAlpha(1)
			end)
			theFrame.DragTopRight:SetScript("OnMouseDown", function(self, button)
				if not InCombatLockdown() and (((not self:GetParent().isLocked) or (self:GetParent().isLocked == 0)) and (button == "LeftButton")) then
					self:GetParent().isResizing = true;
					self:GetParent():StartSizing("TOPRIGHT")
				end
			end)
			theFrame.DragTopRight:SetScript("OnMouseUp", function(self, button)
				if self:GetParent().isResizing == true then
					self:GetParent():StopMovingOrSizing();
					Ping:SaveMainWindowPosition();
					Ping:RefreshCurrentList();
					self:GetParent().isResizing = false;
				end
			end)
			theFrame.DragTopRight:SetScript("OnLeave", function(self)
				theFrame.DragTopRight:SetAlpha(0)
			end)
		
			theFrame.DragTopLeft = CreateFrame("Button", "PingResizeGripLeft", theFrame)
			theFrame.DragTopLeft:Show()
			theFrame.DragTopLeft:SetFrameLevel(theFrame:GetFrameLevel() + 10)
			theFrame.DragTopLeft:SetNormalTexture("Interface\\AddOns\\Ping\\Textures\\resize-topleft.tga")
			theFrame.DragTopLeft:SetHighlightTexture("Interface\\AddOns\\Ping\\Textures\\resize-topleft.tga")
			theFrame.DragTopLeft:SetWidth(16)
			theFrame.DragTopLeft:SetHeight(16)
			theFrame.DragTopLeft:SetAlpha(0)		
			theFrame.DragTopLeft:SetPoint("TOPLEFT", theFrame, "TOPLEFT", 0, -32)
			theFrame.DragTopLeft:EnableMouse(true)
			theFrame.DragTopLeft:SetScript("OnEnter", function(self)
				theFrame.DragTopLeft:SetAlpha(1)
			end)		
			theFrame.DragTopLeft:SetScript("OnMouseDown", function(self, button)
				if not InCombatLockdown() and (((not self:GetParent().isLocked) or (self:GetParent().isLocked == 0)) and (button == "LeftButton")) then
					self:GetParent().isResizing = true;
					self:GetParent():StartSizing("TOPLEFT")
				end
			end)
			theFrame.DragTopLeft:SetScript("OnMouseUp", function(self, button)
				if self:GetParent().isResizing == true then
					self:GetParent():StopMovingOrSizing();
					Ping:SaveMainWindowPosition();
					Ping:RefreshCurrentList();
					self:GetParent().isResizing = false;
				end
			end)
			theFrame.DragTopLeft:SetScript("OnLeave", function(self)
				theFrame.DragTopLeft:SetAlpha(0)
			end)
		end

		theFrame.RightButton = CreateFrame("Button", nil, theFrame)
		theFrame.RightButton:SetNormalTexture("Interface\\AddOns\\Ping\\Textures\\button-right.tga")
		theFrame.RightButton:SetPushedTexture("Interface\\AddOns\\Ping\\Textures\\button-right.tga")
		theFrame.RightButton:SetHighlightTexture("Interface\\AddOns\\Ping\\Textures\\button-highlight.tga")
		theFrame.RightButton:SetWidth(16)
		theFrame.RightButton:SetHeight(16)
		if not Ping.db.profile.InvertPing then 		
			theFrame.RightButton:SetPoint("TOPRIGHT", theFrame, "TOPRIGHT", -23, -14.5)
		else
			theFrame.RightButton:SetPoint("BOTTOMRIGHT", theFrame, "BOTTOMRIGHT", -23, -16.5)
		end		
		theFrame.RightButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:AddLine(L["Left/Right"], 1, 0.82, 0, 1)
			GameTooltip:AddLine(L["Left/RightDescription"],0,0,0,1)
			GameTooltip:Show()
		end)
		theFrame.RightButton:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
		theFrame.RightButton:SetScript("OnClick", function()
			Ping:MainWindowNextMode()
		end)
		theFrame.RightButton:SetFrameLevel(theFrame.RightButton:GetFrameLevel() + 1)

		theFrame.LeftButton = CreateFrame("Button", nil, theFrame)
		theFrame.LeftButton:SetNormalTexture("Interface\\AddOns\\Ping\\Textures\\button-left.tga")
		theFrame.LeftButton:SetPushedTexture("Interface\\AddOns\\Ping\\Textures\\button-left.tga")
		theFrame.LeftButton:SetHighlightTexture("Interface\\AddOns\\Ping\\Textures\\button-highlight.tga")
		theFrame.LeftButton:SetWidth(16)
		theFrame.LeftButton:SetHeight(16)
		theFrame.LeftButton:SetPoint("RIGHT", theFrame.RightButton, "LEFT", 0, 0)
		theFrame.LeftButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:AddLine(L["Left/Right"], 1, 0.82, 0, 1)
			GameTooltip:AddLine(L["Left/RightDescription"],0,0,0,1)
			GameTooltip:Show()
		end)
		theFrame.LeftButton:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
		theFrame.LeftButton:SetScript("OnClick", function()
			Ping:MainWindowPrevMode()
		end)
		theFrame.LeftButton:SetFrameLevel(theFrame.LeftButton:GetFrameLevel() + 1)

		theFrame.ClearButton = CreateFrame("Button", nil, theFrame)
		theFrame.ClearButton:SetNormalTexture("Interface\\AddOns\\Ping\\Textures\\button-clear.tga")
		theFrame.ClearButton:SetPushedTexture("Interface\\AddOns\\Ping\\Textures\\button-clear.tga")
		theFrame.ClearButton:SetHighlightTexture("Interface\\AddOns\\Ping\\Textures\\button-highlight.tga")
		theFrame.ClearButton:SetWidth(16)
		theFrame.ClearButton:SetHeight(16)
		theFrame.ClearButton:SetPoint("RIGHT", theFrame.LeftButton,"LEFT", 0, 0)
		theFrame.ClearButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:AddLine(L["Clear"], 1, 0.82, 0, 1)
			GameTooltip:AddLine(L["ClearDescription"],0,0,0,1)
			GameTooltip:Show()
		end)
		theFrame.ClearButton:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
		theFrame.ClearButton:SetScript("OnClick", function()
			Ping:ClearList()
		end)
		theFrame.ClearButton:SetFrameLevel(theFrame.ClearButton:GetFrameLevel() + 1)
		
		theFrame.StatsButton = CreateFrame("Button", nil, theFrame)
		theFrame.StatsButton:SetNormalTexture("Interface\\AddOns\\Ping\\Textures\\button-file.tga")
		theFrame.StatsButton:SetPushedTexture("Interface\\AddOns\\Ping\\Textures\\button-file.tga")
		theFrame.StatsButton:SetHighlightTexture("Interface\\AddOns\\Ping\\Textures\\button-highlight.tga")
		theFrame.StatsButton:SetWidth(12)
		theFrame.StatsButton:SetHeight(12)
		theFrame.StatsButton:SetPoint("RIGHT", theFrame.ClearButton,"LEFT", -4, 0)
		theFrame.StatsButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:AddLine(L["Statistics"], 1, 0.82, 0, 1)
			GameTooltip:AddLine(L["StatsDescription"],0,0,0,1)
			GameTooltip:Show()
		end)
		theFrame.StatsButton:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
		theFrame.StatsButton:SetScript("OnClick", function()
			PingStats:Toggle()
		end)
		theFrame.StatsButton:SetFrameLevel(theFrame.StatsButton:GetFrameLevel() + 1)
		
		-- Global frame names are shared across every addon, so a generic one like
		-- "CountFrame" would collide with the original Spy the moment both are
		-- loaded. Prefixed for the same reason every other frame here is.
		theFrame.CountFrame = CreateFrame("Frame", "PingCountFrame", theFrame)
		theFrame.CountFrame:SetPoint("RIGHT", theFrame.StatsButton,"LEFT", -4, 0)
		theFrame.CountFrame:SetHeight(Ping.db.profile.MainWindow.RowHeight)
		theFrame.CountFrame.Text = theFrame.CountFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		theFrame.CountFrame.Text:SetPoint("RIGHT", theFrame.StatsButton,"LEFT", -4, 0)
		theFrame.CountFrame.Text:SetFont(select(1, GameFontNormal:GetFont()) or STANDARD_TEXT_FONT or "Fonts\\FRIZQT.TTF", Ping.db.profile.MainWindow.RowHeight * 0.85, "OUTLINE")
		theFrame.CountFrame.Text:SetJustifyH("RIGHT")
		theFrame.CountFrame.Text:SetJustifyV("MIDDLE")
		theFrame.CountFrame.Text:SetTextColor(1, 1, 1, 1)
		theFrame.CountFrame.Text:SetText("|cFF0070DE0|r")
		theFrame.CountFrame.Text:SetScale(1)
	
		theFrame.CountButton = CreateFrame("Button", nil, theFrame)
		theFrame.CountButton:SetNormalTexture("Interface\\AddOns\\Ping\\Textures\\button-crosshairs.tga")
		theFrame.CountButton:SetPushedTexture("Interface\\AddOns\\Ping\\Textures\\button-crosshairs.tga")
		theFrame.CountButton:SetHighlightTexture("Interface\\AddOns\\Ping\\Textures\\button-highlight.tga")
		theFrame.CountButton:SetWidth(12)
		theFrame.CountButton:SetHeight(12)
		theFrame.CountButton:SetAlpha(.0)		
		theFrame.CountButton:SetPoint("RIGHT", theFrame.StatsButton,"LEFT", -4, 0)
		theFrame.CountButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:AddLine(L["NearbyCount"], 1, 0.82, 0, 1)
			GameTooltip:AddLine(L["NearbyCountDescription"],0,0,0,1)
			GameTooltip:Show()
		end)
		theFrame.CountButton:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
		theFrame.CountButton:SetFrameLevel(theFrame.CountButton:GetFrameLevel() + 1)
		
		Ping.MainWindow.Rows = {}
		Ping.MainWindow.CurRows = 0

		for i = 1, Ping.db.profile.ResizePingLimit do
			Ping:CreateRow(i)
		end

		Ping:RestoreMainWindowPosition(Ping.db.profile.MainWindow.Position.x, Ping.db.profile.MainWindow.Position.y, Ping.db.profile.MainWindow.Position.w, 34)
		Ping:SetupMainWindowButtons()
		Ping:ResizeMainWindow()
		Ping:InitOrder()

		Ping:ApplyWindowLocks()
		Ping:ApplyWindowStyle()
		Ping:ApplyThemeChrome()
	end

	if not Ping.AlertWindow then
		Ping.AlertWindow = CreateFrame("Frame", "Ping_AlertWindow", UIParent, "BackdropTemplate")
		Ping.AlertWindow:ClearAllPoints()
--		Ping.AlertWindow:SetPoint("TOP", UIParent, "TOP", 0, -140)
		Ping.AlertWindow:SetClampedToScreen(true)
		Ping:UpdateAlertWindow()
		Ping.AlertWindow:SetHeight(42)
		Ping.AlertWindow:SetBackdrop({
--			bgFile = "Interface\\AddOns\\Ping\\Textures\\alert-background.tga", tile = true, tileSize = 8,
--			edgeFile = "Interface\\AddOns\\Ping\\Textures\\alert-industrial.tga", edgeSize = 8,
--			insets = { left = 8, right = 8, top = 8, bottom = 8 },
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 8,edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 8,
			insets = { left = 2, right = 2, top = 2, bottom = 2 },
		})
		Ping.Colors:RegisterBackground("Alert", "Background", Ping.AlertWindow)

		Ping.AlertWindow.Icon = CreateFrame("Frame", nil, Ping.AlertWindow, "BackdropTemplate")
		Ping.AlertWindow.Icon:ClearAllPoints()
		Ping.AlertWindow.Icon:SetPoint("TOPLEFT", Ping.AlertWindow, "TOPLEFT", 6, -5)
		Ping.AlertWindow.Icon:SetWidth(32)
		Ping.AlertWindow.Icon:SetHeight(32)

		Ping.AlertWindow.Title = Ping.AlertWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		Ping.AlertWindow.Title:SetPoint("TOPLEFT", Ping.AlertWindow, "TOPLEFT", 42, -3)
--		Ping.AlertWindow.Title:SetJustifyH("LEFT")
		Ping.AlertWindow.Title:SetHeight(Ping.db.profile.MainWindow.TextHeight)
		Ping:AddFontString(Ping.AlertWindow.Title)

		Ping.AlertWindow.Name = Ping.AlertWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		Ping.AlertWindow.Name:SetPoint("TOPLEFT", Ping.AlertWindow, "TOPLEFT", 42, -15)
--		Ping.AlertWindow.Name:SetJustifyH("LEFT")
		Ping.AlertWindow.Name:SetHeight(Ping.db.profile.MainWindow.TextHeight)
		Ping:AddFontString(Ping.AlertWindow.Name)
		Ping:SetFontSize(Ping.AlertWindow.Name, Ping.db.profile.AlertWindow.NameSize)

		Ping.AlertWindow.Location = Ping.AlertWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		Ping.AlertWindow.Location:SetPoint("TOPLEFT", Ping.AlertWindow, "TOPLEFT", 42, -26)
--		Ping.AlertWindow.Location:SetJustifyH("LEFT")
		Ping.AlertWindow.Location:SetHeight(Ping.db.profile.MainWindow.TextHeight)
		Ping:AddFontString(Ping.AlertWindow.Location)
		Ping:SetFontSize(Ping.AlertWindow.Location, Ping.db.profile.AlertWindow.LocationSize)

		Ping.AlertWindow:Hide()
	end

	if not Ping.MapNoteList then
		Ping.MapNoteList = {}
		for i = 1, Ping.MapNoteLimit do
			Ping:CreateMapNote(i)
		end
	end

	if not Ping.MapTooltip then
		Ping.MapTooltip = CreateFrame("GameTooltip", "Ping_GameTooltip", nil, "GameTooltipTemplate")
	end

	Ping:SetCurrentList(1)
	if not Ping.db.profile.Enabled or not Ping.db.profile.MainWindowVis then
		Ping.MainWindow:Hide()
	end
end

function Ping:SetBar(num, name, desc, value, colorgroup, colorclass, tooltipData, opacity)
	local rowmin = 1

	if num < rowmin or not Ping.MainWindow.Rows[num] then
		return
	end

	local Row = Ping.MainWindow.Rows[num]
	Row.StatusBar:SetValue(value)
	Row.Name = name
	Row.BaseDesc = desc
	Row.Opacity = opacity or 1
	Row.TooltipData = tooltipData

	if colorgroup and colorclass and type(colorclass) == "string" then
		Ping.Colors:UnregisterItem(Row.StatusBar)
		-- BarOpacity lets a look preset hide the class-colored fill entirely
		-- (flat preset) while keeping the name/level text.
		local barOpacity = Ping.db.profile.BarOpacity
		if barOpacity == nil then barOpacity = 1 end
		local Multi = { r = 1, b = 1, g = 1, a = (opacity or 1) * barOpacity }
		Ping.Colors:RegisterTexture(colorgroup, colorclass, Row.StatusBar, Multi)
	end

	Ping:ApplyRowText(Row)
end

-- Renders a row's text, name color, healer marker, left-edge accent and
-- non-healer dimming from the stored Row.Name / Row.BaseDesc. Called on every
-- SetBar so all target-picker styling stays live with the profile settings.
function Ping:ApplyRowText(Row)
	local name = Row.Name or ""
	local desc = Row.BaseDesc or ""
	local opacity = Row.Opacity or 1
	local playerData = PingPerCharDB.PlayerData[name]
	local isHealer = Ping:IsHealer(playerData)
	local isKoS = PingPerCharDB.KOSData[name] ~= nil

	-- Decide the left-edge accent up front (green for healers, red for KoS) so
	-- the name and any left marker can be inset to clear the 3px stripe.
	local edgeColor
	if isHealer and Ping.db.profile.MarkHealers and Ping.db.profile.HealerGreenEdge then
		edgeColor = Ping.Colors:GetColor("Ping", "Healer Edge")
	elseif isKoS and Ping.db.profile.PrioritiseKoS then
		edgeColor = Ping.Colors:GetColor("Ping", "KoS Edge")
	end
	local leftInset = edgeColor and 7 or 2

	-- Enemy defensive cooldown countdown, appended to the right-hand text so it
	-- sits just right of the level/class without touching the nameplate.
	local cdLeft, cdShort = Ping:GetCooldownRemaining(playerData)
	if cdLeft and Ping.db.profile.TrackCooldowns then
		local mins = math.floor(cdLeft / 60)
		local secs = math.floor(cdLeft % 60)
		local clock = (mins > 0) and format("%d:%02d", mins, secs) or format("%ds", secs)
		local cc = Ping.Colors:GetColor("Ping", "Cooldown")
		local hex = cc and format("%02x%02x%02x", cc.r * 255, cc.g * 255, cc.b * 255) or "ffd200"
		desc = desc .. format("  |cff%s%s %s|r", hex, cdShort or "CD", clock)
	end

	Row.LeftText:SetText(name)
	Row.RightText:SetText(desc)

	-- Name color: class-colored (flat/compact look) or the Bar Text color.
	local barText = Ping.db.profile.Colors.Bar["Bar Text"]
	if Ping.db.profile.ClassColoredNames then
		local class = playerData and playerData.class
		local cc = class and Ping.Colors:GetColor("Class", class)
		if cc then
			Row.LeftText:SetTextColor(cc.r, cc.g, cc.b, opacity)
		else
			-- Unknown class: class color would be near-black and unreadable,
			-- so keep the normal bar text color.
			Row.LeftText:SetTextColor(barText.r, barText.g, barText.b, opacity)
		end
	else
		Row.LeftText:SetTextColor(barText.r, barText.g, barText.b, opacity)
	end
	Row.RightText:SetTextColor(barText.r, barText.g, barText.b, opacity)

	-- The healer marker glyph was removed: the green left-edge accent already
	-- says "healer", and two indicators for one fact is noise. The FontString is
	-- kept created but permanently hidden so row layout code below stays honest.
	if Row.HealerMarker then Row.HealerMarker:Hide() end

	Row.RightText:ClearAllPoints()
	Row.RightText:SetPoint("RIGHT", Row.StatusBar, "RIGHT", -2, 0)

	-- Re-anchor the name (inset past the edge stripe) and size it to whatever
	-- width is left.
	Row.LeftText:ClearAllPoints()
	Row.LeftText:SetPoint("LEFT", Row.StatusBar, "LEFT", leftInset, 0)
	Row.LeftText:SetWidth(Row:GetWidth() - Row.RightText:GetStringWidth() - leftInset - 4)

	-- Apply the left-edge accent decided above.
	if Row.RowEdge then
		Row.RowEdge:ClearAllPoints()
		if usesFullArtwork() then
			Row.RowEdge:SetPoint("TOPLEFT", Row.StatusBar, "TOPLEFT", 2, -1)
			Row.RowEdge:SetPoint("BOTTOMLEFT", Row.StatusBar, "BOTTOMLEFT", 2, 1)
			Row.RowEdge:SetWidth(2)
		else
			Row.RowEdge:SetPoint("TOPLEFT", Row.StatusBar, "TOPLEFT", 0, 0)
			Row.RowEdge:SetPoint("BOTTOMLEFT", Row.StatusBar, "BOTTOMLEFT", 0, 0)
			Row.RowEdge:SetWidth(3)
		end
		if edgeColor then
			Row.RowEdge:SetVertexColor(edgeColor.r, edgeColor.g, edgeColor.b, edgeColor.a or 1)
			Row.RowEdge:Show()
		else
			Row.RowEdge:Hide()
		end
	end

	-- Dim non-healers so the healers you want to focus stand out. Never dims
	-- KoS rows. Applied to the whole StatusBar (its children inherit alpha).
	local rowAlpha = 1
	if Ping.db.profile.DimNonHealers and Ping.db.profile.MarkHealers and not isHealer and not isKoS then
		rowAlpha = 0.35
	end
	Row.StatusBar:SetAlpha(rowAlpha)
end

-- Applies a look preset by setting the handful of underlying knobs it drives,
-- then restyling live. classbars = stock class-colored bars; flat = no fill,
-- class-colored names; compact = denser rows.
function Ping:ApplyLookPreset(preset)
	Ping.db.profile.LookPreset = preset
	if preset == "flat" then
		Ping.db.profile.ClassColoredNames = true
		Ping.db.profile.BarOpacity = 0
		Ping.db.profile.MainWindow.RowHeight = 14
	elseif preset == "compact" then
		Ping.db.profile.ClassColoredNames = false
		Ping.db.profile.BarOpacity = 1
		Ping.db.profile.MainWindow.RowHeight = 10
	else -- "classbars"
		Ping.db.profile.ClassColoredNames = false
		Ping.db.profile.BarOpacity = 1
		Ping.db.profile.MainWindow.RowHeight = 14
	end
	if Ping.MainWindow and Ping.MainWindow.Rows then
		Ping:BarsChanged()
	end
	Ping:RefreshCurrentList()
end

-- ============================================================
-- Look themes: one-click color bundles, distinct from LookPreset above.
-- LookPreset changes ROW LAYOUT (bar opacity, row height, class colors);
-- a theme changes the WINDOW'S palette without touching layout.
--
-- Two things went wrong in the first version and both are fixed here:
--
--  1. Every theme set the title bar to a shade of near-black (all six were
--     between rgb 6 and 22), so switching themes was invisible. Themes now set
--     the window BACKGROUND and a genuinely contrasting title bar - the two
--     largest areas of the window - so the change is unmistakable.
--
--  2. Colors were written straight into the profile table. That works for
--     values re-read on every draw, but Window/Background and Window/Title are
--     REGISTERED widgets (see Colors:RegisterBackground / RegisterBorder) which
--     are painted once and only repaint when pushed through Colors:SetColor.
--     Every slot now goes through SetColor, so registered widgets update live.
--
-- KoS Edge is deliberately not themed: red-for-danger is a signal the eye
-- should never have to relearn, so it stays constant and is only ever changed
-- from its own color picker.
-- ============================================================
local function rgb(hex, a)
	return {
		r = tonumber(hex:sub(1, 2), 16) / 255,
		g = tonumber(hex:sub(3, 4), 16) / 255,
		b = tonumber(hex:sub(5, 6), 16) / 255,
		a = a or 1,
	}
end

-- Each entry is { branch, slot, color }. Branch matters: "Window" holds the
-- backdrop and frame the eye actually reads, "Ping" holds the accents.
Ping.LookThemes = {
	classic = {
		name = "Classic Gold",
		classTint = { toward = rgb("c8a04a"), mix = 0.18 },
		chrome = { Icon=rgb("e8c46a"), Navigation=rgb("7ab8ff"), Count=rgb("4aa3ff"), Close=rgb("ff4a4a") },
		colors = {
			{ "Window", "Background",   rgb("2b2113") },
			{ "Window", "Title",        rgb("c8a04a") },
			{ "Window", "Title Text",   rgb("ffd100") },
			{ "Ping",    "Title Bar",    rgb("2e2412") },
			{ "Ping",    "Window Border",rgb("c8a04a") },
			{ "Ping",    "Healer Marker",rgb("4fe27a") },
			{ "Ping",    "Healer Edge",  rgb("4fe27a") },
			{ "Ping",    "Cooldown",     rgb("ffd100") },
		},
	},
	midnight = {
		name = "Midnight",
		classTint = { toward = rgb("66d9ff"), mix = 0.2, value = 0.95 },
		chrome = { Icon=rgb("c0d8ff"), Navigation=rgb("6ba7ff"), Count=rgb("7cc7ff"), Close=rgb("ff6b7a") },
		colors = {
			{ "Window", "Background",   rgb("111b33") },
			{ "Window", "Title",        rgb("4f7fd6") },
			{ "Window", "Title Text",   rgb("aaccff") },
			{ "Ping",    "Title Bar",    rgb("1a2440") },
			{ "Ping",    "Window Border",rgb("4f7fd6") },
			{ "Ping",    "Healer Marker",rgb("66d9ff") },
			{ "Ping",    "Healer Edge",  rgb("66d9ff") },
			{ "Ping",    "Cooldown",     rgb("a6c0ff") },
		},
	},
	horde = {
		name = "Horde",
		classTint = { toward = rgb("8c1c1c"), mix = 0.22 },
		chrome = { Icon=rgb("f2b0a0"), Navigation=rgb("ff7b63"), Count=rgb("ff9b70"), Close=rgb("ff4040") },
		colors = {
			{ "Window", "Background",   rgb("2b1010") },
			{ "Window", "Title",        rgb("c8231e") },
			{ "Window", "Title Text",   rgb("ff8a6a") },
			{ "Ping",    "Title Bar",    rgb("4a1010") },
			{ "Ping",    "Window Border",rgb("c8231e") },
			{ "Ping",    "Healer Marker",rgb("8ce65a") },
			{ "Ping",    "Healer Edge",  rgb("8ce65a") },
			{ "Ping",    "Cooldown",     rgb("ff8c1a") },
		},
	},
	alliance = {
		name = "Alliance",
		classTint = { toward = rgb("1c3f8c"), mix = 0.22 },
		chrome = { Icon=rgb("ead078"), Navigation=rgb("79baff"), Count=rgb("59c8ff"), Close=rgb("ff5757") },
		colors = {
			{ "Window", "Background",   rgb("101c38") },
			{ "Window", "Title",        rgb("d4af37") },
			{ "Window", "Title Text",   rgb("9fd0ff") },
			{ "Ping",    "Title Bar",    rgb("12224a") },
			{ "Ping",    "Window Border",rgb("d4af37") },
			{ "Ping",    "Healer Marker",rgb("8cd9ff") },
			{ "Ping",    "Healer Edge",  rgb("8cd9ff") },
			{ "Ping",    "Cooldown",     rgb("d4af37") },
		},
	},
	emerald = {
		name = "Emerald",
		classTint = { toward = rgb("2f8f5b"), mix = 0.2 },
		chrome = { Icon=rgb("c8ffe0"), Navigation=rgb("55d98a"), Count=rgb("55e6a0"), Close=rgb("ff5e5e") },
		colors = {
			{ "Window", "Background",   rgb("0f2b1a") },
			{ "Window", "Title",        rgb("3fd67f") },
			{ "Window", "Title Text",   rgb("8cffbf") },
			{ "Ping",    "Title Bar",    rgb("12402a") },
			{ "Ping",    "Window Border",rgb("3fd67f") },
			{ "Ping",    "Healer Marker",rgb("5cff99") },
			{ "Ping",    "Healer Edge",  rgb("5cff99") },
			{ "Ping",    "Cooldown",     rgb("ccff66") },
		},
	},
	mono = {
		name = "Monochrome",
		classTint = { toward = rgb("c8c8c8"), mix = 0.45 },
		chrome = { Icon=rgb("d8d8d8"), Navigation=rgb("b0b0b0"), Count=rgb("f0f0f0"), Close=rgb("d06060") },
		colors = {
			{ "Window", "Background",   rgb("222222") },
			{ "Window", "Title",        rgb("b4b4b4") },
			{ "Window", "Title Text",   rgb("ffffff") },
			{ "Ping",    "Title Bar",    rgb("2c2c2c") },
			{ "Ping",    "Window Border",rgb("b4b4b4") },
			{ "Ping",    "Healer Marker",rgb("e6e6e6") },
			{ "Ping",    "Healer Edge",  rgb("e6e6e6") },
			{ "Ping",    "Cooldown",     rgb("999999") },
		},
	},
	blackout = {
		name = "Blacked Out",
		classTint = { toward = rgb("202020"), mix = 0.3, value = 0.85 },
		chrome = { Icon=rgb("b0b0b0"), Navigation=rgb("8c8c8c"), Count=rgb("e0e0e0"), Close=rgb("c04040") },
		colors = {
			{ "Window", "Background",   rgb("020202") },
			{ "Window", "Title",        rgb("181818") },
			{ "Window", "Title Text",   rgb("f0f0f0") },
			{ "Ping",    "Title Bar",    rgb("050505") },
			{ "Ping",    "Window Border",rgb("242424") },
			{ "Ping",    "Healer Marker",rgb("d8d8d8") },
			{ "Ping",    "Healer Edge",  rgb("a8a8a8") },
			{ "Ping",    "Cooldown",     rgb("b8b8b8") },
		},
		settings = {
			ClassColoredNames = false,
			BarOpacity = 0.12,
			ShowBackground = true,
			BackgroundOpacity = 1,
			ShowBorder = false,
			TitleBarOpacity = 1,
		},
	},
	obsidian = {
		name = "Obsidian Tactical",
		classTint = { toward = rgb("53d5da"), mix = 0.22 },
		artwork = "obsidian",
		chrome = { Icon=rgb("d7e1e7"), Navigation=rgb("8ccbe6"), Count=rgb("3ec7f2"), Close=rgb("ef513f") },
		colors = {
			{ "Window", "Background",   rgb("0c0f12") },
			{ "Window", "Title",        rgb("3a464e") },
			{ "Window", "Title Text",   rgb("eef3f5") },
			{ "Ping",    "Title Bar",    rgb("101419") },
			{ "Ping",    "Window Border",rgb("5b7b89") },
			{ "Ping",    "Healer Marker",rgb("53d5da") },
			{ "Ping",    "Healer Edge",  rgb("53d5da") },
			{ "Ping",    "Cooldown",     rgb("ff9c38") },
		},
		settings = {
			Font = "Expressway",
			ClassColoredNames = false,
			BarOpacity = 0.55,
			ShowBackground = true,
			BackgroundOpacity = 0.98,
			ShowBorder = false,
			TitleBarOpacity = 1,
			TitleBarStyle = "solid",
			ObsidianArtworkRevision = 3,
		},
	},
	arcane = {
		name = "Arcane Glass",
		classTint = { toward = rgb("8a6fd4"), mix = 0.24 },
		artwork = "arcane",
		chrome = { Icon=rgb("d8e8ff"), Navigation=rgb("79ddff"), Count=rgb("63efff"), Close=rgb("ff5e88") },
		colors = {
			{ "Window", "Background",   rgb("090d1b") },
			{ "Window", "Title",        rgb("374f88") },
			{ "Window", "Title Text",   rgb("e6edff") },
			{ "Ping",    "Title Bar",    rgb("111a35") },
			{ "Ping",    "Window Border",rgb("668ed8") },
			{ "Ping",    "Healer Marker",rgb("62f2e7") },
			{ "Ping",    "Healer Edge",  rgb("62f2e7") },
			{ "Ping",    "Cooldown",     rgb("c69cff") },
		},
		settings = {
			Font = "Myriad",
			ClassColoredNames = false,
			BarOpacity = 0.52,
			ShowBackground = true,
			BackgroundOpacity = 0.98,
			ShowBorder = false,
			TitleBarOpacity = 1,
			TitleBarStyle = "solid",
		},
	},
	warcamp = {
		name = "Warcamp",
		classTint = { toward = rgb("a05a2a"), mix = 0.24 },
		artwork = "warcamp",
		chrome = { Icon=rgb("ead8b8"), Navigation=rgb("d9a254"), Count=rgb("ffc466"), Close=rgb("ef513f") },
		colors = {
			{ "Window", "Background",   rgb("15110e") },
			{ "Window", "Title",        rgb("6b4b2a") },
			{ "Window", "Title Text",   rgb("f1dfc0") },
			{ "Ping",    "Title Bar",    rgb("211812") },
			{ "Ping",    "Window Border",rgb("967044") },
			{ "Ping",    "Healer Marker",rgb("75d887") },
			{ "Ping",    "Healer Edge",  rgb("75d887") },
			{ "Ping",    "Cooldown",     rgb("ffb44a") },
		},
		settings = {
			Font = "Big Noodle Titling",
			ClassColoredNames = false,
			BarOpacity = 0.55,
			ShowBackground = true,
			BackgroundOpacity = 0.98,
			ShowBorder = false,
			TitleBarOpacity = 1,
			TitleBarStyle = "solid",
		},
	},
	minimal = {
		name = "Minimal Ink",
		classTint = { toward = rgb("d8d8d8"), mix = 0.16 },
		artwork = "minimal",
		chrome = { Icon=rgb("d4d8dc"), Navigation=rgb("aeb7bf"), Count=rgb("f3f5f7"), Close=rgb("e06a6a") },
		colors = {
			{ "Window", "Background",   rgb("111316") },
			{ "Window", "Title",        rgb("25292e") },
			{ "Window", "Title Text",   rgb("f2f3f4") },
			{ "Ping",    "Title Bar",    rgb("15181c") },
			{ "Ping",    "Window Border",rgb("69727b") },
			{ "Ping",    "Healer Marker",rgb("67d99a") },
			{ "Ping",    "Healer Edge",  rgb("67d99a") },
			{ "Ping",    "Cooldown",     rgb("e3bd70") },
		},
		settings = {
			Font = "Expressway",
			ClassColoredNames = false, BarOpacity = 0.85,
			ShowBackground = true, BackgroundOpacity = 0.98, ShowBorder = false,
			TitleBarOpacity = 1, TitleBarStyle = "solid",
			CleanThemeBorderRevision = 1,
		},
	},
	clean = {
		name = "Clean Glass",
		classTint = { toward = rgb("9fd3ff"), mix = 0.16 },
		artwork = "clean",
		chrome = { Icon=rgb("dcecff"), Navigation=rgb("84d9ff"), Count=rgb("a7ecff"), Close=rgb("ff6e79") },
		colors = {
			{ "Window", "Background",   rgb("07101a") },
			{ "Window", "Title",        rgb("214b67") },
			{ "Window", "Title Text",   rgb("e9f6ff") },
			{ "Ping",    "Title Bar",    rgb("0a1723") },
			{ "Ping",    "Window Border",rgb("70bce0") },
			{ "Ping",    "Healer Marker",rgb("64e5cf") },
			{ "Ping",    "Healer Edge",  rgb("64e5cf") },
			{ "Ping",    "Cooldown",     rgb("82caff") },
		},
		settings = {
			Font = "Myriad",
			ClassColoredNames = false, BarOpacity = 0.85,
			ShowBackground = true, BackgroundOpacity = 0.96, ShowBorder = false,
			TitleBarOpacity = 1, TitleBarStyle = "solid",
			CleanThemeBorderRevision = 1,
		},
	},
	unitframe = {
		name = "Unitframe Clean",
		classTint = { toward = rgb("b8b8b8"), mix = 0.18 },
		artwork = "unitframe",
		chrome = { Icon=rgb("d0d4d8"), Navigation=rgb("65aee8"), Count=rgb("3da9ff"), Close=rgb("e45757") },
		colors = {
			{ "Window", "Background",   rgb("0d0e10") },
			{ "Window", "Title",        rgb("30343a") },
			{ "Window", "Title Text",   rgb("e5e7e9") },
			{ "Ping",    "Title Bar",    rgb("111316") },
			{ "Ping",    "Window Border",rgb("555b62") },
			{ "Ping",    "Healer Marker",rgb("50d890") },
			{ "Ping",    "Healer Edge",  rgb("50d890") },
			{ "Ping",    "Cooldown",     rgb("e8b45f") },
		},
		settings = {
			Font = "Friz Quadrata TT",
			ClassColoredNames = false, BarOpacity = 0.88,
			ShowBackground = true, BackgroundOpacity = 1, ShowBorder = false,
			TitleBarOpacity = 1, TitleBarStyle = "solid",
			CleanThemeBorderRevision = 1,
		},
	},
	villain = {
		name = "Villain HUD",
		classTint = { toward = rgb("e04a3c"), mix = 0.26 },
		artwork = "villain",
		chrome = { Icon=rgb("e2d7d7"), Navigation=rgb("d94a4a"), Count=rgb("ff6767"), Close=rgb("ff3434") },
		colors = {
			{ "Window", "Background",   rgb("0d0809") },
			{ "Window", "Title",        rgb("50171b") },
			{ "Window", "Title Text",   rgb("f4e8e8") },
			{ "Ping",    "Title Bar",    rgb("170b0d") },
			{ "Ping",    "Window Border",rgb("a72c34") },
			{ "Ping",    "Healer Marker",rgb("68db8c") },
			{ "Ping",    "Healer Edge",  rgb("68db8c") },
			{ "Ping",    "Cooldown",     rgb("ff9a52") },
		},
		settings = {
			Font = "Ping Bangers",
			ClassColoredNames = false, BarOpacity = 0.88,
			ShowBackground = true, BackgroundOpacity = 0.99, ShowBorder = false,
			TitleBarOpacity = 1, TitleBarStyle = "solid",
			CleanThemeBorderRevision = 1,
		},
	},
}

-- Display order for the theme dropdown. pairs() over LookThemes is unordered,
-- so without this the list shuffles between sessions. The separator splits the
-- two kinds of theme: the first group only recolors Ping's original artwork,
-- the second replaces the window textures, control icons and (for Villain HUD)
-- the fonts as well. Picking the separator does nothing - ApplyLookTheme
-- returns on any key that is not a theme.
Ping.LookThemeSeparator = "__separator"
Ping.LookThemeOrder = {
	-- color only
	"classic", "midnight", "horde", "alliance", "emerald", "mono", "blackout",
	Ping.LookThemeSeparator,
	-- full artwork
	"obsidian", "arcane", "warcamp", "minimal", "clean", "unitframe", "villain",
}

-- The stock class colors, kept as the source of truth so a theme tints THESE
-- rather than compounding on whatever the last theme left behind.
local STOCK_CLASS = {
	HUNTER  = {0.67, 0.83, 0.45}, WARLOCK = {0.53, 0.53, 0.93},
	PRIEST  = {1.00, 1.00, 1.00}, PALADIN = {0.96, 0.55, 0.73},
	MAGE    = {0.25, 0.78, 0.92}, ROGUE   = {1.00, 0.96, 0.41},
	DRUID   = {1.00, 0.49, 0.04}, SHAMAN  = {0.00, 0.44, 0.87},
	WARRIOR = {0.78, 0.61, 0.43}, PET     = {0.09, 0.61, 0.55},
}

-- Class bars are tinted, never replaced. A theme supplies a pull colour and a
-- strength; each class is blended that far toward it. Blending preserves the
-- ORDER of the hues, so Warlock stays bluer than Druid and Priest stays the
-- lightest, which is what makes a class identifiable at a glance. Hand-picking
-- 126 values per theme would not guarantee that.
--
-- Strength is capped at 0.45 for the same reason: past roughly half way the
-- classes converge on the theme colour and stop being distinguishable.
local function tintedClass(class, tint)
	local base = STOCK_CLASS[class]
	if not base then return nil end
	local r, g, b = base[1], base[2], base[3]
	if tint and tint.toward then
		local mix = math.min(tint.mix or 0.25, 0.45)
		local t = tint.toward
		r = r + (t.r - r) * mix
		g = g + (t.g - g) * mix
		b = b + (t.b - b) * mix
	end
	-- Optional lift/darken, applied after the blend so it cannot invert the mix.
	local v = tint and tint.value
	if v then
		r, g, b = math.min(r * v, 1), math.min(g * v, 1), math.min(b * v, 1)
	end
	return { r = r, g = g, b = b, a = 0.6 }
end

-- Structural settings a theme is allowed to move. Snapshotted alongside the
-- colors so a revert puts back everything the theme touched, and nothing else.
local THEMED_SETTINGS = {
	"ClassColoredNames", "BarOpacity", "ShowBackground", "BackgroundOpacity",
	"ShowBorder", "TitleBarOpacity", "TitleBarStyle", "ArtworkStyle",
	"LookTheme", "BarTexture", "Font",
}

-- Captures the look BEFORE a theme lands, so one revert undoes it. Deliberately
-- taken on every apply rather than only the first: undo means "back to how it
-- was a moment ago", so picking Horde then Emerald and reverting returns you to
-- Horde, not to whatever you had before you started trying themes.
local function snapshotLook()
	local p = Ping.db.profile
	local snap = { colors = {}, settings = {} }
	for branch, slots in pairs(p.Colors or {}) do
		snap.colors[branch] = {}
		for slot, c in pairs(slots) do
			if type(c) == "table" then
				snap.colors[branch][slot] = { r = c.r, g = c.g, b = c.b, a = c.a }
			end
		end
	end
	for _, key in ipairs(THEMED_SETTINGS) do snap.settings[key] = p[key] end
	p.ThemeUndo = snap
end

function Ping:CanRevertLookTheme()
	local u = Ping.db and Ping.db.profile and Ping.db.profile.ThemeUndo
	return type(u) == "table" and type(u.colors) == "table"
end

-- Puts back what snapshotLook captured. Colors go through SetColor for the same
-- reason ApplyLookTheme does: registered widgets repaint only when told.
function Ping:RevertLookTheme()
	local p = Ping.db.profile
	local snap = p.ThemeUndo
	if type(snap) ~= "table" or type(snap.colors) ~= "table" then return end

	for branch, slots in pairs(snap.colors) do
		if p.Colors[branch] then
			for slot, c in pairs(slots) do
				if p.Colors[branch][slot] then
					Ping.Colors:SetColor(branch, slot, c)
				end
			end
		end
	end
	for key, value in pairs(snap.settings or {}) do p[key] = value end

	-- One level of undo only. Clearing it stops a second click from "reverting"
	-- to the state the first revert just left, which reads as nothing happening.
	p.ThemeUndo = nil

	Ping:ApplyWindowStyle()
	Ping:ApplyThemeChrome()
	Ping:UpdateMainWindow()
	Ping:RefreshCurrentList()
end

function Ping:ApplyLookTheme(key)
	-- Custom themes live in the profile, not the built-in table.
	local theme = Ping.LookThemes[key]
	if not theme and Ping.IsCustomTheme and Ping:IsCustomTheme(key) then
		theme = Ping:GetCustomTheme(key)
	end
	if not theme then return end
	snapshotLook()
	-- A theme selection is deterministic. Rebuild the structural settings that
	-- Blacked Out changes instead of restoring a snapshot which may itself have
	-- been captured after the old bug had already darkened the profile.
	Ping.db.profile.BlackoutRestore = nil
	if key ~= "blackout" then
		local preset = Ping.db.profile.LookPreset or "classbars"
		Ping.db.profile.ClassColoredNames = preset == "flat"
		Ping.db.profile.BarOpacity = preset == "flat" and 0 or 1
		Ping.db.profile.ShowBackground = true
		Ping.db.profile.BackgroundOpacity = 1
		Ping.db.profile.ShowBorder = false
		Ping.db.profile.TitleBarOpacity = 1
	end
	Ping.db.profile.LookTheme = key
	Ping.db.profile.ArtworkStyle = theme.artwork or "legacy"

	for _, entry in ipairs(theme.colors) do
		local branch, slot, color = entry[1], entry[2], entry[3]
		local target = Ping.db.profile.Colors[branch]
		if target and target[slot] then
			-- Through SetColor, not a raw write: registered widgets only repaint
			-- when told to, and Window/Background is one of them.
			Ping.Colors:SetColor(branch, slot, color)
		end
	end
	for slot, color in pairs(theme.chrome or {}) do Ping.Colors:SetColor("Ping", slot, color) end

	-- Class bars follow the theme. A built-in supplies a tint recipe, always
	-- recomputed from STOCK_CLASS so switching themes never stacks tint on
	-- tint. A saved theme supplies the finished colors instead, so it looks
	-- tomorrow exactly as it did when it was saved.
	local classTable = Ping.db.profile.Colors.Class
	if classTable then
		if theme.classes then
			for class, c in pairs(theme.classes) do
				if classTable[class] then Ping.Colors:SetColor("Class", class, c) end
			end
		else
			for class in pairs(STOCK_CLASS) do
				local c = tintedClass(class, theme.classTint)
				if c and classTable[class] then Ping.Colors:SetColor("Class", class, c) end
			end
		end
	end
	for setting, value in pairs(theme.settings or {}) do
		-- LockFont makes the font a personal choice a theme cannot take back.
		-- Someone who has picked a face they can read at a glance should not
		-- lose it for trying a theme on.
		if not (setting == "Font" and Ping.db.profile.LockFont) then
			Ping.db.profile[setting] = value
		end
	end

	-- With the lock on, restore the font the user actually chose rather than
	-- simply declining to overwrite - otherwise the "kept" font is whatever the
	-- previous theme left behind, which is not the user's font at all.
	if Ping.db.profile.LockFont and Ping.db.profile.UserFont then
		Ping.db.profile.Font = Ping.db.profile.UserFont
	end

	-- The themed title bar only draws in the solid style, so a theme switches to
	-- it rather than silently doing nothing on the classic style.
	Ping.db.profile.TitleBarStyle = "solid"
	Ping:ApplyWindowStyle()
	Ping:ApplyThemeChrome()
	Ping:UpdateMainWindow()
	Ping:RefreshCurrentList()
end

local function tintButton(button, color)
	if not button or not color then return end
	for _, texture in ipairs({ button:GetNormalTexture(), button:GetPushedTexture() }) do
		if texture then
			if texture.SetDesaturated then texture:SetDesaturated(true) end
			texture:SetVertexColor(color.r, color.g, color.b, color.a or 1)
		end
	end
	local highlight = button:GetHighlightTexture()
	if highlight then highlight:SetVertexColor(1, 1, 1, 0.9) end
end

function Ping:ApplyThemeChrome()
	local frame = Ping.MainWindow
	if not frame or not Ping.db or not Ping.db.profile then return end
	local colors = Ping.db.profile.Colors.Ping
	tintButton(frame.StatsButton, colors.Icon)
	tintButton(frame.ClearButton, colors.Icon)
	tintButton(frame.CountButton, colors.Icon)
	tintButton(frame.LeftButton, colors.Navigation)
	tintButton(frame.RightButton, colors.Navigation)
	tintButton(frame.CloseButton, colors.Close)
	Ping:UpdateActiveCount()
end

function Ping:AutomaticallyResize()
	local detected = Ping.ListAmountDisplayed
	if detected > Ping.db.profile.ResizePingLimit then detected = Ping.db.profile.ResizePingLimit end
	local height = 35 + (detected * (Ping.db.profile.MainWindow.RowHeight + Ping.db.profile.MainWindow.RowSpacing))
	Ping.MainWindow.CurRows = detected
	if not Ping.db.profile.InvertPing then
		if not InCombatLockdown() then 
			Ping:RestoreMainWindowPosition(Ping.MainWindow:GetLeft(), Ping.MainWindow:GetTop(), Ping.MainWindow:GetWidth(), height)
		end
	else
		if not InCombatLockdown() then 
			Ping:RestoreMainWindowPosition(Ping.MainWindow:GetLeft(), Ping.MainWindow:GetBottom(), Ping.MainWindow:GetWidth(), height)
		end
	end	
end

function Ping:ManageBarsDisplayed()
	local detected = Ping.ListAmountDisplayed
	local bars = math.floor((Ping.MainWindow:GetHeight() - 34) / (Ping.db.profile.MainWindow.RowHeight + Ping.db.profile.MainWindow.RowSpacing))
	if bars > detected then
		bars = detected
	end
	if bars > Ping.db.profile.ResizePingLimit then
		bars = Ping.db.profile.ResizePingLimit
	end	
	Ping.MainWindow.CurRows = bars

	if not InCombatLockdown() then
		for i,row in pairs(Ping.MainWindow.Rows) do	
			if i <= Ping.MainWindow.CurRows then
				row:Show()
			else
				row:Hide()
			end
		end
	end
end

function Ping:ResizeMainWindow()
	if Ping.MainWindow.Rows[0] then
		Ping.MainWindow.Rows[0]:Hide()
	end

	local CurWidth = Ping.MainWindow:GetWidth() - 4
	local headerReserve = usesFullArtwork() and 103 or 75
	Ping.MainWindow.Title:SetWidth(math.max(50, CurWidth - headerReserve))
	-- Rows can be absent if an earlier UI error interrupted window creation.
	for i,row in pairs(Ping.MainWindow.Rows or {}) do
		row:SetWidth(CurWidth)	
	end

	Ping:ManageBarsDisplayed()
end

function Ping:SetCurrentList(mode)
	if not mode or mode > #Ping.ListTypes then
		mode = 1
	end
	Ping.db.profile.CurrentList = mode
	Ping:ManageExpirations()

	Ping:UpdateWindowTitle()
	Ping:RefreshCurrentList()
end

-- Title reflects the active list, and flags the healer-only filter so a short
-- list is never mistaken for "no enemies around".
function Ping:UpdateWindowTitle()
	if not Ping.MainWindow or not Ping.MainWindow.Title then return end
	local mode = Ping.db.profile.CurrentList or 1
	local data = Ping.ListTypes[mode]
	if not data then return end
	local title = data[1]
	if Ping.db.profile.HealerOnlyFilter and mode == 1 then
		local hc = Ping.db.profile.Colors["Ping"]["Healer Edge"]
		local hex = hc and format("%02x%02x%02x", hc.r * 255, hc.g * 255, hc.b * 255) or "4fe27a"
		title = title .. format(" |cff%s(%s)|r", hex, L["HealersOnlyTag"])
	end
	if usesFullArtwork() then
		title = string.upper(title)
	end
	Ping.MainWindow.Title:SetText(title)
end

function Ping:MainWindowNextMode()
	local mode = Ping.db.profile.CurrentList + 1
	if mode > table.maxn(Ping.ListTypes) then
		mode = 1
	end
	Ping:SetCurrentList(mode)
end

function Ping:MainWindowPrevMode()
	local mode = Ping.db.profile.CurrentList - 1
	if mode == 0 then
		mode = table.maxn(Ping.ListTypes)
	end
	Ping:SetCurrentList(mode)
end

function Ping:MainWindowScroll(delta)
--  Work in progress to scroll the MainWindow
--	DEFAULT_CHAT_FRAME:AddMessage(delta)
	if delta > 0 then
--		Code for scrolling up
	else
--		Code for scrolling down
	end
end

function Ping:SaveMainWindowPosition()
	Ping.db.profile.MainWindow.Position.x = Ping.MainWindow:GetLeft()
	if not Ping.db.profile.InvertPing then 
		Ping.db.profile.MainWindow.Position.y = Ping.MainWindow:GetTop()
    else 
		Ping.db.profile.MainWindow.Position.y = Ping.MainWindow:GetBottom()
    end
	Ping.db.profile.MainWindow.Position.w = Ping.MainWindow:GetWidth()
	Ping.db.profile.MainWindow.Position.h = Ping.MainWindow:GetHeight()
	local h = Ping.MainWindow:GetHeight()
end

function Ping:RestoreMainWindowPosition(x, y, width, height)
	Ping.MainWindow:ClearAllPoints()
	if not Ping.db.profile.InvertPing then 	
		Ping.MainWindow:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
	else		
		Ping.MainWindow:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)	
	end
	Ping.MainWindow:SetWidth(width)
	for i,row in pairs(Ping.MainWindow.Rows or {}) do
		row:SetWidth(width -4) 
	end
	Ping.MainWindow:SetHeight(height)
end

function Ping:SaveAlertWindowPosition()
	Ping.db.profile.AlertWindow.Position.x = Ping.AlertWindow:GetLeft()
	Ping.db.profile.AlertWindow.Position.y = Ping.AlertWindow:GetTop()
end

function Ping:RestoreAlertWindowPosition(x, y)
	Ping.AlertWindow:ClearAllPoints()
	Ping.AlertWindow:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
end

function Ping:UpdateMainWindow()
	-- One transparency everywhere. There used to be a second value used inside
	-- instances, but it was labelled "in BGs" while IsInInstance() is also true
	-- in dungeons and raids, so it dimmed the window in places the label never
	-- implied - and nobody wants a different number there anyway.
	Ping.MainWindow:SetAlpha(Ping.db.profile.MainWindow.Alpha)
end

-- Position lock keeps the saved spot but refuses drags (SetMovable(false) makes
-- the existing StartMoving() calls no-ops). Size lock hides the resize grips.
-- Both layer cleanly on top of the legacy "Locked" toggle.
function Ping:ApplyWindowLocks()
	local frame = Ping.MainWindow
	if not frame then return end
	frame:SetMovable(not Ping.db.profile.LockPosition)

	local hideGrips = Ping.db.profile.LockSize or Ping.db.profile.Locked
	local grips = { frame.DragBottomRight, frame.DragBottomLeft, frame.DragTopRight, frame.DragTopLeft }
	for _, grip in pairs(grips) do
		if hideGrips then grip:Hide() else grip:Show() end
	end
end

local ARTWORK_ROOT = "Interface\\AddOns\\Ping\\Textures\\"
local ARTWORK_STYLES = {
	obsidian = { prefix = "obsidian-", showButtonPlate = false },
	arcane = { prefix = "arcane-", showButtonPlate = true, buttonPlateAlpha = 0.50 },
	warcamp = { prefix = "warcamp-", showButtonPlate = true, buttonPlateAlpha = 0.62 },
	minimal = { prefix = "minimal-", showButtonPlate = false },
	clean = { prefix = "clean-", showButtonPlate = true, buttonPlateAlpha = 0.28 },
	unitframe = { prefix = "unitframe-", showButtonPlate = true, buttonPlateAlpha = 0.55 },
	villain = { prefix = "villain-", showButtonPlate = true, buttonPlateAlpha = 0.46 },
}
local LEGACY_BUTTON_ART = {
	StatsButton = { "Interface\\AddOns\\Ping\\Textures\\button-file.tga", "Interface\\AddOns\\Ping\\Textures\\button-file.tga" },
	ClearButton = { "Interface\\AddOns\\Ping\\Textures\\button-clear.tga", "Interface\\AddOns\\Ping\\Textures\\button-clear.tga" },
	CountButton = { "Interface\\AddOns\\Ping\\Textures\\button-crosshairs.tga", "Interface\\AddOns\\Ping\\Textures\\button-crosshairs.tga" },
	LeftButton = { "Interface\\AddOns\\Ping\\Textures\\button-left.tga", "Interface\\AddOns\\Ping\\Textures\\button-left.tga" },
	RightButton = { "Interface\\AddOns\\Ping\\Textures\\button-right.tga", "Interface\\AddOns\\Ping\\Textures\\button-right.tga" },
	CloseButton = { "Interface\\Buttons\\UI-Panel-MinimizeButton-Up.blp", "Interface\\Buttons\\UI-Panel-MinimizeButton-Down.blp" },
}
local THEMED_BUTTON_ART = {
	StatsButton = "history",
	ClearButton = "target",
	CountButton = "target",
	LeftButton = "left",
	RightButton = "right",
	CloseButton = "close",
}

local function ensureThemedFrameArt(frame)
	if frame.ThemedArt then return frame.ThemedArt end
	local art = {}
	frame.ThemedArt = art
	for _, edge in ipairs({ "Top", "Bottom", "Left", "Right" }) do
		local texture = frame:CreateTexture(nil, "OVERLAY")
		texture:SetTexture("Interface\\Buttons\\WHITE8X8")
		art[edge] = texture
	end
	art.Top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
	art.Top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
	art.Top:SetHeight(1)
	art.Bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
	art.Bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
	art.Bottom:SetHeight(1)
	art.Left:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
	art.Left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
	art.Left:SetWidth(1)
	art.Right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
	art.Right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
	art.Right:SetWidth(1)
	return art
end

function Ping:ApplyArtworkStyle()
	local frame = Ping.MainWindow
	if not frame then return end
	local style = ARTWORK_STYLES[Ping.db.profile.ArtworkStyle]
	local art = ensureThemedFrameArt(frame)
	local border = Ping.Colors:GetColor("Ping", "Window Border")

	if style then
		local artworkPath = ARTWORK_ROOT .. style.prefix
		frame:SetBackdrop(nil)
		frame.Background:SetTexture(artworkPath .. "panel.tga")
		frame.Background:SetVertexColor(1, 1, 1, 1)
		frame.TitleFill:SetTexture(artworkPath .. "panel.tga")
		frame.TitleBar:SetBackdrop(nil)
		frame.Title:SetShadowColor(0, 0, 0, 0.95)
		frame.Title:SetShadowOffset(1, -1)
		for _, texture in pairs(art) do
			texture:SetVertexColor(border.r, border.g, border.b, border.a or 1)
			if Ping.db.profile.ShowBorder then texture:Show() else texture:Hide() end
		end
		for buttonName, icon in pairs(THEMED_BUTTON_ART) do
			local button = frame[buttonName]
			button:SetNormalTexture(artworkPath .. icon .. ".tga")
			button:SetPushedTexture(artworkPath .. icon .. ".tga")
			button:SetHighlightTexture(artworkPath .. "hover.tga")
			if not button.ThemeBackground then
				button.ThemeBackground = button:CreateTexture(nil, "BACKGROUND")
				button.ThemeBackground:SetAllPoints(button)
			end
			button.ThemeBackground:SetTexture(artworkPath .. "button.tga")
			button.ThemeBackground:SetAlpha(style.buttonPlateAlpha or 1)
			if style.showButtonPlate then button.ThemeBackground:Show() else button.ThemeBackground:Hide() end
		end
		local enabled = Ping.db.profile.MainWindow.Buttons or {}
		for _, name in ipairs({ "StatsButton", "ClearButton", "LeftButton", "RightButton", "CloseButton" }) do
			local button = frame[name]
			local visible = name == "StatsButton" or name == "CloseButton" or enabled[name] ~= false
			button:SetWidth(visible and 14 or 1)
			button:SetHeight(14)
		end
		frame.CloseButton:ClearAllPoints()
		frame.CloseButton:SetPoint("RIGHT", frame.TitleBar, "RIGHT", -3, 0)
		frame.RightButton:ClearAllPoints()
		frame.RightButton:SetPoint("RIGHT", frame.CloseButton, "LEFT", -1, 0)
		frame.LeftButton:ClearAllPoints()
		frame.LeftButton:SetPoint("RIGHT", frame.RightButton, "LEFT", -1, 0)
		frame.ClearButton:ClearAllPoints()
		frame.ClearButton:SetPoint("RIGHT", frame.LeftButton, "LEFT", -1, 0)
		frame.StatsButton:ClearAllPoints()
		frame.StatsButton:SetPoint("RIGHT", frame.ClearButton, "LEFT", -1, 0)
		frame.CountFrame:ClearAllPoints()
		frame.CountFrame:SetPoint("RIGHT", frame.StatsButton, "LEFT", -3, 0)
		frame.CountFrame.Text:ClearAllPoints()
		frame.CountFrame.Text:SetPoint("RIGHT", frame.StatsButton, "LEFT", -3, 0)
		frame.CountButton:ClearAllPoints()
		frame.CountButton:SetPoint("RIGHT", frame.StatsButton, "LEFT", -3, 0)
	else
		frame.Background:SetTexture("Interface\\CHARACTERFRAME\\UI-Party-Background")
		frame.Background:SetVertexColor(1, 1, 1, 1)
		frame.TitleFill:SetTexture("Interface\\Buttons\\WHITE8X8")
		frame.TitleBar:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 8,
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12,
			insets = {left = 2, right = 2, top = 2, bottom = 2},
		})
		frame.TitleBar:SetBackdropColor(0, 0, 0, 1)
		frame.TitleBar:SetBackdropBorderColor(1, 1, 1, 1)
		frame.Title:SetShadowOffset(0, 0)
		for _, texture in pairs(art) do texture:Hide() end
		for buttonName, paths in pairs(LEGACY_BUTTON_ART) do
			local button = frame[buttonName]
			button:SetNormalTexture(paths[1])
			button:SetPushedTexture(paths[2])
			button:SetHighlightTexture(buttonName == "CloseButton"
				and "Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight.blp"
				or "Interface\\AddOns\\Ping\\Textures\\button-highlight.tga")
			if button.ThemeBackground then button.ThemeBackground:Hide() end
		end
		local enabled = Ping.db.profile.MainWindow.Buttons or {}
		frame.CloseButton:SetSize(20, 20)
		frame.CloseButton:ClearAllPoints()
		if not Ping.db.profile.InvertPing then
			frame.CloseButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -12)
		else
			frame.CloseButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, -19)
		end
		frame.RightButton:SetSize(enabled.RightButton ~= false and 16 or 1, 16)
		frame.RightButton:ClearAllPoints()
		if not Ping.db.profile.InvertPing then
			frame.RightButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -23, -14.5)
		else
			frame.RightButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -23, -16.5)
		end
		frame.LeftButton:SetSize(enabled.LeftButton ~= false and 16 or 1, 16)
		frame.LeftButton:ClearAllPoints()
		frame.LeftButton:SetPoint("RIGHT", frame.RightButton, "LEFT", 0, 0)
		frame.ClearButton:SetSize(enabled.ClearButton ~= false and 16 or 1, 16)
		frame.ClearButton:ClearAllPoints()
		frame.ClearButton:SetPoint("RIGHT", frame.LeftButton, "LEFT", 0, 0)
		frame.StatsButton:SetSize(12, 12)
		frame.StatsButton:ClearAllPoints()
		frame.StatsButton:SetPoint("RIGHT", frame.ClearButton, "LEFT", -4, 0)
		frame.CountFrame:ClearAllPoints()
		frame.CountFrame:SetPoint("RIGHT", frame.StatsButton, "LEFT", -4, 0)
		frame.CountFrame.Text:ClearAllPoints()
		frame.CountFrame.Text:SetPoint("RIGHT", frame.StatsButton, "LEFT", -4, 0)
		frame.CountButton:SetSize(12, 12)
		frame.CountButton:ClearAllPoints()
		frame.CountButton:SetPoint("RIGHT", frame.StatsButton, "LEFT", -4, 0)
	end
	Ping:ApplyThemeFonts()
	Ping:ResizeMainWindow()
	Ping:UpdateWindowTitle()
end

-- Show/hide and recolor the window background fill and border, and apply the
-- window scale. Safe to call any time after the main window exists.
function Ping:ApplyWindowStyle()
	local frame = Ping.MainWindow
	if not frame then return end

	local o = Ping.db.profile.BackgroundOpacity
	if o == nil then o = 1 end
	if frame.Background then
		if Ping.db.profile.ShowBackground then
			frame.Background:SetAlpha(o)
			frame.Background:Show()
		else
			frame.Background:Hide()
		end
	end
	-- Title bar: "classic" hides the solid strip and lets the stock subtle
	-- backdrop show through; "solid" draws the colored strip at its own
	-- opacity, independent of the window background toggle.
	if frame.TitleFill then
		if Ping.db.profile.TitleBarStyle == "solid" then
			local tc = Ping.Colors:GetColor("Ping", "Title Bar")
			if tc then frame.TitleFill:SetVertexColor(tc.r, tc.g, tc.b, 1) end
			local to = Ping.db.profile.TitleBarOpacity
			if to == nil then to = 1 end
			frame.TitleFill:SetAlpha(to)
			frame.TitleFill:Show()
		else
			frame.TitleFill:Hide()
		end
	end

	if Ping.db.profile.ShowBorder then
		frame:SetBackdrop({
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = false, edgeSize = 14,
			insets = { left = 0, right = 0, top = 0, bottom = 0 },
		})
		local bc = Ping.Colors:GetColor("Ping", "Window Border")
		if bc then frame:SetBackdropBorderColor(bc.r, bc.g, bc.b, bc.a or 1) end
		local bg = Ping.Colors:GetColor("Window", "Background")
		if bg then frame:SetBackdropColor(bg.r, bg.g, bg.b, bg.a or 1) end
	else
		frame:SetBackdrop(nil)
	end

	frame:SetScale(Ping.db.profile.WindowScale or 1)
	Ping:ApplyArtworkStyle()
end

function Ping:UpdateAlertWindow()
	if Ping.db.profile.DisplayWarnings == "Moveable" then
		Ping.AlertWindow:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", Ping.db.profile.AlertWindow.Position.x, Ping.db.profile.AlertWindow.Position.y)
		Ping.AlertWindow:SetMovable(true)
		Ping.AlertWindow:EnableMouse(true)
		Ping.AlertWindow:SetScript("OnMouseDown", function(self, button) 
			if InCombatLockdown() or button ~= "LeftButton" then return end
			Ping.AlertWindow:StartMoving();
			Ping.AlertWindow.isMoving = true;
		end)
		Ping.AlertWindow:SetScript("OnMouseUp", function(self) 
			if (Ping.AlertWindow.isMoving) then
				Ping.AlertWindow:StopMovingOrSizing();
				Ping.AlertWindow.isMoving = false;
				Ping:SaveAlertWindowPosition()
			end
		end)
	else
		Ping.AlertWindow:ClearAllPoints()	
		Ping.AlertWindow:SetPoint("TOP", UIParent, "TOP", 0, -140)
	end		
end	

function Ping:ShowTooltip(self, show, id)
	if show then
		local unit = self.unit
		local name = Ping.ButtonName[self.id] or unit.name
		if name and name ~= "" then
			local titleText = Ping.db.profile.Colors.Tooltip["Title Text"]

			if not Ping.db.profile.DisplayTooltipNearPingWindow then
				GameTooltip:SetOwner(Ping.MainWindow, "ANCHOR_NONE")
				GameTooltip:SetPoint("BOTTOMRIGHT", "UIParent", "BOTTOMRIGHT", -CONTAINER_OFFSET_X - 13, CONTAINER_OFFSET_Y)
			else
				GameTooltip:SetOwner(self, Ping.db.profile.TooltipAnchor)
			end
			GameTooltip:ClearLines()
			GameTooltip:AddLine(string.gsub(name, "%-", " - "), titleText.r, titleText.g, titleText.b)

			local playerData = PingPerCharDB.PlayerData[name]
			if playerData then
				local detailsText = Ping.db.profile.Colors.Tooltip["Details Text"]
				if playerData.guild and playerData.guild ~= "" then
					GameTooltip:AddLine(playerData.guild, detailsText.r, detailsText.g, detailsText.b)
				end

				local details = ""
				if playerData.level then details = L["Level"].." "..playerData.level.." " end
				if playerData.race then details = details..playerData.race.." " end
				if playerData.class then details = details..L[playerData.class] end
				if details ~= "" then
					GameTooltip:AddLine(details..L["Player"], detailsText.r, detailsText.g, detailsText.b)
				end

				if Ping.db.profile.DisplayWinLossStatistics then
					local wins = "0"
					local loses = "0"
					if playerData.wins then wins = playerData.wins end
					if playerData.loses then loses = playerData.loses end
					GameTooltip:AddLine(L["StatsWins"]..wins..L["StatsSeparator"]..L["StatsLoses"]..loses, detailsText.r, detailsText.g, detailsText.b)
				end

				if PingPerCharDB.KOSData[name] then
					local reasonText = Ping.db.profile.Colors.Tooltip["Reason Text"]
					GameTooltip:AddLine(L["KOSReason"], reasonText.r, reasonText.g, reasonText.b)
					if playerData.reason and Ping.db.profile.DisplayKOSReason then
						for reason in pairs(playerData.reason) do
							if reason == L["KOSReasonOther"] then
								GameTooltip:AddLine(L["KOSReasonIndent"]..playerData.reason[reason], reasonText.r, reasonText.g, reasonText.b)
							else
								GameTooltip:AddLine(L["KOSReasonIndent"]..reason, reasonText.r, reasonText.g, reasonText.b)
							end
						end
					end
				end

				if Ping.db.profile.DisplayLastSeen then
					local locationText = Ping.db.profile.Colors.Tooltip["Location Text"]
					if playerData.time then
						local lastSeen = L["LastSeen"]
						local minutes = math.floor((time() - playerData.time) / 60)
						local hours = math.floor(minutes / 60)
						if minutes <= 0 then
							lastSeen = lastSeen.." "..L["LessThanOneMinuteAgo"]
						elseif minutes > 0 and minutes < 60 then
							lastSeen = lastSeen.." "..minutes.." "..L["MinutesAgo"]
						elseif hours > 0 and hours < 24 then
							lastSeen = lastSeen.." "..hours.." "..L["HoursAgo"]
						else
							local days = math.floor(hours / 24)
							lastSeen = lastSeen.." "..days.." "..L["DaysAgo"]
						end
						GameTooltip:AddLine(lastSeen, locationText.r, locationText.g, locationText.b)
					end
					GameTooltip:AddLine(Ping:GetPlayerLocation(playerData), locationText.r, locationText.g, locationText.b)
				end
			end

			GameTooltip:Show()
		end
	else
		GameTooltip:Hide()
	end
end

function Ping:ShowMapTooltip(icon, show)
	local tooltip = Ping.MapTooltip
	if show then
		local titleText = Ping.db.profile.Colors.Tooltip["Details Text"]
		local locationText = Ping.db.profile.Colors.Tooltip["Location Text"]

        local angle, distance = HBDP:GetVectorToIcon(icon)
		local distance = nil
		if distance == nil then
			distance = ""
		else
			distance = math.floor(distance).." "..L["DistanceUnit"]
		end

		tooltip:SetOwner(icon, "ANCHOR_NONE")
		tooltip:SetPoint("TOPLEFT", icon, "TOPRIGHT", 16, 0)
		tooltip:ClearLines()
		tooltip:AddDoubleLine(Ping.EnemyFactionName.." "..L["Located"], distance, titleText.r, titleText.g, titleText.b, locationText.r, locationText.g, locationText.b)

		for player in pairs(Ping.PlayerCommList) do
			if Ping.PlayerCommList[player] == icon.id then
				local name, description = player, ""
				local playerData = PingPerCharDB.PlayerData[player]
				if playerData and playerData.isEnemy then
					if playerData.guild and strlen(playerData.guild) > 0 then
						name = name..L["MinimapGuildText"].." <"..playerData.guild..">"
					end
					if Ping.db.profile.MinimapDetails then
						if playerData.class and playerData.level then
							description = description..L["MinimapClassText"..playerData.class].."["..playerData.level.." "..L[playerData.class].."]"
						elseif playerData.class then
							description = description..L["MinimapClassText"..playerData.class].."["..L[playerData.class].."]"
						elseif playerData.level then
							description = description.."["..playerData.level.."]"
						end
					end
				end
				tooltip:AddDoubleLine(name, description)
			end
		end
		tooltip:Show()
	else
		tooltip:Hide()
	end
end

function Ping:ShowAlert(type, name, source, location)
	if not PingFrameIsFading(Ping.AlertWindow) then
		Ping.AlertType = nil
	end

	if type == "kos" then
		Ping.Colors:RegisterBorder("Alert", "KOS Border", Ping.AlertWindow)
		Ping.AlertWindow.Icon:SetBackdrop({ bgFile = "Interface\\Icons\\Ability_Creature_Cursed_02" })
		Ping.Colors:RegisterBorder("Alert", "Background", Ping.AlertWindow.Icon)
		Ping.Colors:RegisterBackground("Alert", "Icon", Ping.AlertWindow.Icon)
		Ping.Colors:RegisterFont("Alert", "KOS Text", Ping.AlertWindow.Title)
		Ping.AlertWindow.Title:SetText(L["AlertKOSTitle"])
		Ping.Colors:RegisterFont("Alert", "Name Text", Ping.AlertWindow.Name)
		Ping.AlertWindow.Name:SetText(name)
		Ping.Colors:RegisterFont("Alert", "KOS Text", Ping.AlertWindow.Location)
		Ping.AlertWindow.Location:SetText(location)
		Ping.AlertWindow:SetWidth(Ping.AlertWindow.Title:GetStringWidth() + 52)
		if (Ping.AlertWindow.Title:GetStringWidth() < Ping.AlertWindow.Name:GetStringWidth()) then
			Ping.AlertWindow:SetWidth(Ping.AlertWindow.Name:GetStringWidth() + 52)
		else
			Ping.AlertWindow:SetWidth(Ping.AlertWindow.Title:GetStringWidth() + 52)
		end

		PingFrameFlashStop(Ping.AlertWindow)
		PingFrameFlash(Ping.AlertWindow, 0, 1, 4, false, 3, 0)
		Ping.AlertType = type
	elseif type == "kosguild" and Ping.AlertType ~= "kos" then
		Ping.Colors:RegisterBorder("Alert", "KOS Guild Border", Ping.AlertWindow)
		Ping.AlertWindow.Icon:SetBackdrop({ bgFile = "Interface\\Icons\\Spell_Holy_PrayerofSpirit" })
		Ping.Colors:RegisterBorder("Alert", "Background", Ping.AlertWindow.Icon)
		Ping.Colors:RegisterBackground("Alert", "Icon", Ping.AlertWindow.Icon)
		Ping.Colors:RegisterFont("Alert", "KOS Guild Text", Ping.AlertWindow.Title)
		Ping.AlertWindow.Title:SetText(L["AlertKOSGuildTitle"])
		Ping.Colors:RegisterFont("Alert", "Name Text", Ping.AlertWindow.Name)
		Ping.AlertWindow.Name:SetText(name)
		Ping.AlertWindow.Location:SetText("")
		Ping.AlertWindow:SetWidth(Ping.AlertWindow.Title:GetStringWidth() + 52)
		if (Ping.AlertWindow.Title:GetStringWidth() < Ping.AlertWindow.Name:GetStringWidth()) then
			Ping.AlertWindow:SetWidth(Ping.AlertWindow.Name:GetStringWidth() + 52)
		else
			Ping.AlertWindow:SetWidth(Ping.AlertWindow.Title:GetStringWidth() + 52)
		end

		PingFrameFlashStop(Ping.AlertWindow)
		PingFrameFlash(Ping.AlertWindow, 0, 1, 4, false, 3, 0)
		Ping.AlertType = type
	elseif type == "stealth" and Ping.AlertType ~= "kos" and Ping.AlertType ~= "kosguild" then
		Ping.Colors:RegisterBorder("Alert", "Stealth Border", Ping.AlertWindow)
		Ping.AlertWindow.Icon:SetBackdrop({ bgFile = "Interface\\Icons\\Ability_Stealth" })
		Ping.Colors:RegisterBorder("Alert", "Background", Ping.AlertWindow.Icon)
		Ping.Colors:RegisterBackground("Alert", "Icon", Ping.AlertWindow.Icon)
		Ping.Colors:RegisterFont("Alert", "Stealth Text", Ping.AlertWindow.Title)
		Ping.AlertWindow.Title:SetText(L["AlertStealthTitle"])
		Ping.Colors:RegisterFont("Alert", "Name Text", Ping.AlertWindow.Name)
		Ping.AlertWindow.Name:SetText(name)
		Ping.AlertWindow.Location:SetText("")
		Ping.AlertWindow:SetWidth(Ping.AlertWindow.Title:GetStringWidth() + 52)
		if (Ping.AlertWindow.Title:GetStringWidth() < Ping.AlertWindow.Name:GetStringWidth()) then
			Ping.AlertWindow:SetWidth(Ping.AlertWindow.Name:GetStringWidth() + 52)
		else
			Ping.AlertWindow:SetWidth(Ping.AlertWindow.Title:GetStringWidth() + 52)
		end

		PingFrameFlashStop(Ping.AlertWindow)
		PingFrameFlash(Ping.AlertWindow, 0, 1, 5, false, 4, 0)
		Ping.AlertType = type
	elseif type == "prowl" and Ping.AlertType ~= "kos" and Ping.AlertType ~= "kosguild" then
		Ping.Colors:RegisterBorder("Alert", "Stealth Border", Ping.AlertWindow)
		Ping.AlertWindow.Icon:SetBackdrop({ bgFile = "Interface\\Icons\\Ability_Ambush" })
		Ping.Colors:RegisterBorder("Alert", "Background", Ping.AlertWindow.Icon)
		Ping.Colors:RegisterBackground("Alert", "Icon", Ping.AlertWindow.Icon)
		Ping.Colors:RegisterFont("Alert", "Stealth Text", Ping.AlertWindow.Title)
		Ping.AlertWindow.Title:SetText(L["AlertStealthTitle"])
		Ping.Colors:RegisterFont("Alert", "Name Text", Ping.AlertWindow.Name)
		Ping.AlertWindow.Name:SetText(name)
		Ping.AlertWindow.Location:SetText("")
		Ping.AlertWindow:SetWidth(Ping.AlertWindow.Title:GetStringWidth() + 52)
		if (Ping.AlertWindow.Title:GetStringWidth() < Ping.AlertWindow.Name:GetStringWidth()) then
			Ping.AlertWindow:SetWidth(Ping.AlertWindow.Name:GetStringWidth() + 52)
		else
			Ping.AlertWindow:SetWidth(Ping.AlertWindow.Title:GetStringWidth() + 52)
		end

		PingFrameFlashStop(Ping.AlertWindow)
		PingFrameFlash(Ping.AlertWindow, 0, 1, 5, false, 4, 0)
		Ping.AlertType = type
	elseif (type == "kosaway" or type == "kosguildaway") and Ping.AlertType ~= "kos" and Ping.AlertType ~= "kosguild" and Ping.AlertType ~= "stealth" then
		local realmSeparator = strfind(source, "-")
		if realmSeparator and realmSeparator > 1 then
			source = string.gsub(strsub(source, 1, realmSeparator - 1), " ", "")
		end
		Ping.Colors:RegisterBorder("Alert", "Away Border", Ping.AlertWindow)
		Ping.AlertWindow.Icon:SetBackdrop({ bgFile = "Interface\\Icons\\Ability_Hunter_SniperShot" })
		Ping.Colors:RegisterBorder("Alert", "Background", Ping.AlertWindow.Icon)
		Ping.Colors:RegisterBackground("Alert", "Icon", Ping.AlertWindow.Icon)
		Ping.Colors:RegisterFont("Alert", "Away Text", Ping.AlertWindow.Title)
		Ping.AlertWindow.Title:SetText(L["AlertTitle_"..type]..source.."!")
		Ping.Colors:RegisterFont("Alert", "Name Text", Ping.AlertWindow.Name)
		Ping.AlertWindow.Name:SetText(name)
		Ping.Colors:RegisterFont("Alert", "Location Text", Ping.AlertWindow.Location)
		Ping.AlertWindow.Location:SetText(location)
		if (Ping.AlertWindow.Title:GetStringWidth() < Ping.AlertWindow.Location:GetStringWidth()) then
			Ping.AlertWindow:SetWidth(Ping.AlertWindow.Location:GetStringWidth() + 52)
		else
			Ping.AlertWindow:SetWidth(Ping.AlertWindow.Title:GetStringWidth() + 52)
		end

		PingFrameFlashStop(Ping.AlertWindow)
		PingFrameFlash(Ping.AlertWindow, 0, 1, 4, false, 3, 0)
		Ping.AlertType = type
	end
	Ping.AlertWindow.Name:SetWidth(Ping.AlertWindow:GetWidth() - 52)
	Ping.AlertWindow.Location:SetWidth(Ping.AlertWindow:GetWidth() - 52)
end

function Ping:BarsChanged()  
	for k, v in pairs(Ping.MainWindow.Rows) do
		v:SetHeight(Ping.db.profile.MainWindow.RowHeight)
		v:SetPoint("TOPLEFT", Ping.MainWindow, "TOPLEFT", 2, -34 - (Ping.db.profile.MainWindow.RowHeight + Ping.db.profile.MainWindow.RowSpacing) * (k - 1))			
		Ping:SetFontSize(v.LeftText, math.max(Ping.db.profile.MainWindow.RowHeight * 0.75, Ping.db.profile.MainWindow.RowHeight - 3))
		Ping:SetFontSize(v.RightText, math.max(Ping.db.profile.MainWindow.RowHeight * 0.5, Ping.db.profile.MainWindow.RowHeight - 12))
	end
	Ping:ApplyThemeFonts()
	Ping:ResizeMainWindow()
end

function Ping:CreateKoSButton()
	if not Ping.KoSButton then
		Ping.KoSButton = CreateFrame("Button", "Ping_KoSButton", TargetFrame)
		Ping.KoSButton:Hide()
		Ping.KoSButton:SetWidth(22) 
		Ping.KoSButton:SetHeight(22)
		Ping.KoSButton:SetPoint("TOPLEFT", TargetFrame, "BOTTOMLEFT", 141, 44)
		Ping.KoSButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
		Ping.KoSButton.Background = Ping.KoSButton:CreateTexture("KoSButtonBackground", "BACKGROUND")
		Ping.KoSButton.Background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
		Ping.KoSButton.Background:SetWidth(12)
		Ping.KoSButton.Background:SetHeight(12)
		Ping.KoSButton.Background:SetPoint("CENTER")
		Ping.KoSButton.Background:SetVertexColor(0, 0, 0, 0.7)
		Ping.KoSButton.Icon = Ping.KoSButton:CreateTexture("KoSButtonIcon", "ARTWORK")
		Ping.KoSButton.Icon:SetWidth(14)
		Ping.KoSButton.Icon:SetHeight(14)
		Ping.KoSButton.Icon:SetPoint("CENTER", 2, -1)
		Ping.KoSButton.Border = Ping.KoSButton:CreateTexture("KoSButtonBorder", "OVERLAY")
		Ping.KoSButton.Border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
		Ping.KoSButton.Border:SetWidth(44)
		Ping.KoSButton.Border:SetHeight(44)
		Ping.KoSButton.Border:SetPoint("CENTER", 11, -12)
		RaiseFrameLevel(Ping.KoSButton)

		Ping.KoSButton:SetScript("OnMouseDown", function(self, button)
			if (UnitIsEnemy("player","target") and UnitIsPlayer("target")) then
				local name = GetUnitName("target", true)
				if button == "LeftButton" then
					if PingPerCharDB.KOSData[name] then
						Ping:ToggleKOSPlayer(false, name)
					else
						Ping:ToggleKOSPlayer(true, name)
					end
				elseif button == "RightButton" then	
					Ping:SetKOSReason(name, L["KOSReasonOther"], other)
				end
			end
		end)
	end
end

--hooksecurefunc("TargetFrame_Update", function()
hooksecurefunc(TargetFrame, "Update", function()
	if Ping.db.profile.ShowKoSButton then
		if (UnitIsEnemy("player","target") and UnitIsPlayer("target")) then
			local name = GetUnitName("target", true)	
			if PingPerCharDB.KOSData[name] then
				Ping.KoSButton.Icon:SetTexture("Interface\\AddOns\\Ping\\Textures\\button-on.tga")
			else	
				Ping.KoSButton.Icon:SetTexture("Interface\\AddOns\\Ping\\Textures\\button-off.tga")
			end
			Ping.KoSButton:Show()
		else
			Ping.KoSButton:Hide()
		end
	end	
end)
