local HW = HordeWatch

-- Deliberately not Spy's full UI (no KOS list, ignore list, stats window,
-- sound-alert config, etc.) - just a movable, resizable status window
-- showing the most recently seen enemies, since the real "intelligence"
-- surface is meant to be the website, not this window.

local ROW_HEIGHT = 16
local TOP_PADDING = 46    -- space for title/status text before rows start
local BOTTOM_PADDING = 20 -- space below the last row before the frame edge
local MIN_WIDTH, MIN_HEIGHT = 260, 150
local MAX_WIDTH, MAX_HEIGHT = 700, 600
local MAX_ROWS = 40 -- hard cap on the row pool no matter how tall the window gets

local frame = CreateFrame("Frame", "HordeWatchFrame", UIParent, "BackdropTemplate")
frame:SetMovable(true)
frame:SetResizable(true)
if frame.SetResizeBounds then
	frame:SetResizeBounds(MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT)
else
	frame:SetMinResize(MIN_WIDTH, MIN_HEIGHT)
	frame:SetMaxResize(MAX_WIDTH, MAX_HEIGHT)
end
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self)
	if not HW.db.profile.window.locked then self:StartMoving() end
end)
frame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	local point, _, relPoint, x, y = self:GetPoint()
	local w = HW.db.profile.window
	w.point, w.relPoint, w.x, w.y = point, relPoint, x, y
end)
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

local resizeGrip = CreateFrame("Button", nil, frame)
resizeGrip:SetSize(16, 16)
resizeGrip:SetPoint("BOTTOMRIGHT", -4, 4)
resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
resizeGrip:SetScript("OnMouseDown", function()
	if not HW.db.profile.window.locked then frame:StartSizing("BOTTOMRIGHT") end
end)
resizeGrip:SetScript("OnMouseUp", function()
	frame:StopMovingOrSizing()
	local w = HW.db.profile.window
	w.width, w.height = frame:GetSize()
	HW:RefreshWindow()
end)

-- Row pool: grows on demand, and how many are actually shown adapts to the
-- window's current height so resizing taller genuinely shows more entries
-- instead of just being cosmetic.
local rows = {}
local function ensureRowPool(n)
	for i = #rows + 1, n do
		local row = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		row:SetPoint("TOPLEFT", 16, -TOP_PADDING - (i - 1) * ROW_HEIGHT)
		row:SetPoint("RIGHT", frame, "RIGHT", -16, 0)
		row:SetHeight(ROW_HEIGHT - 2)
		row:SetJustifyH("LEFT")
		row:SetWordWrap(false) -- a too-long line truncates instead of wrapping into the row below
		rows[i] = row
	end
end

local function visibleRowCount()
	local usable = frame:GetHeight() - TOP_PADDING - BOTTOM_PADDING
	local n = math.floor(usable / ROW_HEIGHT)
	if n < 1 then n = 1 end
	if n > MAX_ROWS then n = MAX_ROWS end
	return n
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
	if rec.layer then
		-- "layer" here is an opaque shard fingerprint, not the game's
		-- human-readable Layer 1/2/3 label - see Position.lua for why.
		loc = ("%s [Shard %s]"):format(loc, tostring(rec.layer))
	end
	local guildText = (rec.guild and rec.guild ~= "") and (" <" .. rec.guild .. ">") or ""
	local ago = math.floor((time() - rec.ts) / 60)
	local agoText = ago <= 0 and "just now" or (ago .. "m ago")
	local via = rec.relayed and (" via " .. (rec.relaySender or "?")) or ""
	local corroborated = (rec.reportCount and rec.reportCount > 1) and (" x" .. rec.reportCount) or ""
	return ("%s%s|r%s Lvl %s - %s - %s%s%s"):format(classColorPrefix(rec.class), rec.player, guildText, level, loc, agoText, via, corroborated)
end

function HW:RefreshWindow()
	local list = {}
	for _, rec in pairs(self.charDB.CurrentState) do
		list[#list + 1] = rec
	end
	table.sort(list, function(a, b) return a.ts > b.ts end)

	statusText:SetText(("%d tracked - %s"):format(#list, self.EnabledInZone and "active" or "inactive"))

	local visible = visibleRowCount()
	ensureRowPool(visible)
	for i = 1, #rows do
		if i <= visible then
			local rec = list[i]
			rows[i]:SetText(rec and formatRow(rec) or "")
			rows[i]:Show()
		else
			rows[i]:Hide()
		end
	end
end

-- Applies the saved position/size/opacity/lock state to the actual frame.
-- Safe to call any time (hidden or shown) - e.g. after a profile change.
function HW:ApplyWindowLayout()
	local w = self.db.profile.window
	frame:ClearAllPoints()
	frame:SetPoint(w.point or "CENTER", UIParent, w.relPoint or "CENTER", w.x or 0, w.y or 0)
	frame:SetSize(w.width or 360, w.height or 260)
	frame:SetBackdropColor(0, 0, 0, w.bgAlpha or 0.85)
	resizeGrip:SetShown(not w.locked)
end

function HW:SetBackgroundAlpha(alpha)
	self.db.profile.window.bgAlpha = alpha
	frame:SetBackdropColor(0, 0, 0, alpha)
end

function HW:SetWindowLocked(locked)
	self.db.profile.window.locked = locked
	resizeGrip:SetShown(not locked)
end

function HW:ResetWindowLayout()
	local d = HW.Defaults.profile.window
	local w = self.db.profile.window
	w.bgAlpha, w.locked = d.bgAlpha, d.locked
	w.width, w.height = d.width, d.height
	w.point, w.relPoint, w.x, w.y = d.point, d.relPoint, d.x, d.y
	self:ApplyWindowLayout()
	self:RefreshWindow()
end

function HW:ShowWindow()
	self:ApplyWindowLayout()
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
