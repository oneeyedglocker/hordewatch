local HW = HordeWatch

-- Deliberately not Spy's full UI (no KOS list, ignore list, stats window,
-- sound-alert config, etc.) - just a movable status window showing the
-- most recently seen enemies, since the real "intelligence" surface is
-- meant to be the website, not this window.

local NUM_ROWS = 12

local frame = CreateFrame("Frame", "HordeWatchFrame", UIParent, "BackdropTemplate")
frame:SetSize(360, 260)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:SetFrameStrata("MEDIUM")
frame:SetBackdrop({
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true, tileSize = 32, edgeSize = 32,
	insets = { left = 11, right = 12, top = 12, bottom = 11 },
})
frame:Hide()

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -16)
title:SetText("Horde Watch")

local statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
statusText:SetPoint("TOP", title, "BOTTOM", 0, -6)

local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -4, -4)
closeBtn:SetScript("OnClick", function()
	HW.db.profile.ShowWindow = false
	frame:Hide()
end)

local rows = {}
for i = 1, NUM_ROWS do
	local row = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row:SetPoint("TOPLEFT", 16, -50 - (i - 1) * 16)
	row:SetPoint("RIGHT", frame, "RIGHT", -16, 0)
	row:SetJustifyH("LEFT")
	rows[i] = row
end

local function classColorPrefix(class)
	local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
	if not c then return "|cffffffff" end
	return ("|cff%02x%02x%02x"):format(c.r * 255, c.g * 255, c.b * 255)
end

local function formatRow(rec)
	local level = rec.level and tostring(rec.level) or "??"
	local loc = rec.zone or "?"
	if rec.mapX and rec.mapY then
		loc = ("%s (%d,%d)"):format(loc, math.floor(rec.mapX * 100), math.floor(rec.mapY * 100))
	end
	local ago = math.floor((time() - rec.ts) / 60)
	local agoText = ago <= 0 and "just now" or (ago .. "m ago")
	local via = rec.relayed and (" via " .. (rec.relaySender or "?")) or ""
	return ("%s%s|r Lvl %s - %s - %s%s"):format(classColorPrefix(rec.class), rec.player, level, loc, agoText, via)
end

function HW:RefreshWindow()
	local list = {}
	for _, rec in pairs(self.charDB.CurrentState) do
		list[#list + 1] = rec
	end
	table.sort(list, function(a, b) return a.ts > b.ts end)

	statusText:SetText(("%d tracked - %s"):format(#list, self.EnabledInZone and "active" or "inactive"))

	for i = 1, NUM_ROWS do
		local rec = list[i]
		rows[i]:SetText(rec and formatRow(rec) or "")
	end
end

function HW:ShowWindow()
	frame:Show()
	self:RefreshWindow()
end

function HW:HideWindow()
	frame:Hide()
end

function HW:UpdateWindowVisibility()
	if self.db.profile.ShowWindow and self.db.profile.Enabled and self.EnabledInZone then
		self:ShowWindow()
	elseif not self.db.profile.Enabled or not self.EnabledInZone then
		frame:Hide()
	end
end

HW:RegisterMessage("HordeWatch_NewSighting", "RefreshWindow")
HW:RegisterMessage("HordeWatch_StateCleared", "RefreshWindow")
HW:ScheduleRepeatingTimer("RefreshWindow", 30) -- keeps "Nm ago" text moving even with no new sightings
