--[[--------------------------------------------------------------------------
  Spy Arrow -- native direction indicator.

  Points at a tracked enemy's last known position. Three layouts, all driven by
  the same engine and selectable in the options:

    "titlebar"  - arrow + name + distance replace the window title
    "dock"      - a strip below the rows with a larger arrow and staleness
    "floating"  - a separate movable frame, park it anywhere

  The arrow is a 256-frame sprite sheet of a shaded 3D model rotating on its
  axis; the frame is chosen with SetTexCoord from the bearing, so it tilts in
  perspective instead of spinning flat.

  Honest limit: the client never exposes a live enemy position. The bearing is
  to where the target was last SEEN, which is exact while they're on screen and
  progressively a guess afterwards - hence the staleness colouring and timeout.
----------------------------------------------------------------------------]]

local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:GetLocale("Spy")
local HBD = LibStub("HereBeDragons-2.0", true)

local ARROW_TEXTURE = "Interface\\AddOns\\Spy\\Textures\\SpyArrow"
local FRAMES, COLS, ROWS = 256, 16, 16
local TWOPI = math.pi * 2

-- Below this many yards the recorded position and ours are effectively the same
-- point, so any bearing we compute is just noise amplified into a random spin.
-- Treat it as "you are on top of the last-seen spot" instead of pointing wrong.
local NEAR_YARDS = 6

Spy.Arrow = Spy.Arrow or {}
local Arrow = Spy.Arrow

-- Pre-compute the texture coordinates of every sprite cell once.
local texcoords = {}
do
	local dx, dy = 1 / COLS, 1 / ROWS
	for i = 0, FRAMES - 1 do
		local col, row = i % COLS, math.floor(i / COLS)
		texcoords[i] = { col * dx, (col + 1) * dx, row * dy, (row + 1) * dy }
	end
end

------------------------------------------------------------------------------
-- tracking state
------------------------------------------------------------------------------
function Spy:TrackPlayer(name)
	if not name or name == "" then return end
	Arrow.target = name
	Arrow.since = GetTime()
	Spy:UpdateArrowVisibility()
	Spy:UpdateArrow()
	if Spy.UpdateGlow then Spy:UpdateGlow() end
	Spy:RefreshCurrentList()	-- highlight the tracked row
end

function Spy:StopTracking()
	Arrow.target = nil
	Arrow.since = nil
	Spy:UpdateArrowVisibility()
	if Spy.UpdateGlow then Spy:UpdateGlow() end
	Spy:RefreshCurrentList()
end

function Spy:GetTrackedPlayer()
	return Arrow.target
end

------------------------------------------------------------------------------
-- LIVE bearing from the enemy's nameplate
--
-- The client refuses to give us an enemy's position, but a nameplate is
-- anchored to the unit in the 3D world, so where it lands on screen encodes
-- the horizontal angle from the camera to that player. Dead centre means
-- dead ahead; the further from centre, the wider the angle.
--
-- This is the only genuinely live bearing available, and it is what makes the
-- arrow point at someone standing in front of you instead of at the spot where
-- you happened to be when Spy first noticed them.
--
-- Only the magnitude depends on the field-of-view estimate. Which side they
-- are on, and "dead ahead" when centred, are exact regardless.
------------------------------------------------------------------------------
-- Nameplate addons (Platynator, Plater, Kui, ElvUI, ...) hide or replace the
-- default UnitFrame that lives on each nameplate, and hang their own artwork
-- off it. What none of them can move is the base nameplate frame itself: the
-- engine owns it and anchors it to the unit in the world, which is exactly the
-- thing we read. So we deliberately measure the BASE frame, never the addon's
-- decoration, and we find it through the nameplateN unit tokens - which the
-- engine hands out regardless of what is drawing on top.
local MAX_NAMEPLATES = 40

local function findNameplateUnit(name)
	if not C_NamePlate then return nil end

	-- Preferred path: engine unit tokens -> engine base frame. Works with any
	-- nameplate addon, and with none.
	if C_NamePlate.GetNamePlateForUnit then
		for i = 1, MAX_NAMEPLATES do
			local unit = "nameplate"..i
			if UnitExists(unit) and GetUnitName(unit, true) == name then
				local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, unit)
				if ok and plate then
					return unit, plate
				end
			end
		end
	end

	-- Fallback for clients where the token sweep comes up empty.
	if C_NamePlate.GetNamePlates then
		local ok, plates = pcall(C_NamePlate.GetNamePlates, C_NamePlate)
		if ok and type(plates) == "table" then
			for _, plate in ipairs(plates) do
				local unit = plate.namePlateUnitToken
					or (plate.UnitFrame and plate.UnitFrame.unit)
				if unit and UnitExists(unit) and GetUnitName(unit, true) == name then
					return unit, plate
				end
			end
		end
	end

	return nil
end

-- Exposed so the nameplate glow can hang off the same base frame the bearing is
-- measured from, rather than duplicating the lookup.
function Spy:FindNameplateForPlayer(name)
	return findNameplateUnit(name)
end

-- Which nameplate addon, if any, is decorating the plates. Purely diagnostic:
-- the bearing maths does not care, but knowing this makes a bug report legible.
local NAMEPLATE_ADDONS = {
	"Platynator", "Plater", "Kui_Nameplates", "TidyPlates", "ThreatPlates",
	"NeatPlates", "ElvUI", "NamePlateSCT", "BetterBlizzPlates",
}

function Spy:GetNameplateDriver()
	local loaded = IsAddOnLoaded
	if not loaded then return "unknown" end
	for _, addon in ipairs(NAMEPLATE_ADDONS) do
		local ok, isLoaded = pcall(loaded, addon)
		if ok and isLoaded then return addon end
	end
	return "Blizzard"
end

-- Coarse distance bracket for a unit we can see, used to place their position
-- rather than to display. Nameplates only draw within roughly 40 yards.
local function estimateRange(unit)
	if CheckInteractDistance then
		if CheckInteractDistance(unit, 3) then return 5 end	-- ~10yd duel range
		if CheckInteractDistance(unit, 1) then return 18 end	-- ~28yd inspect
		if CheckInteractDistance(unit, 4) then return 18 end	-- ~28yd follow
	end
	return 33
end

-- The client can pin your current target's nameplate to the edge of the screen
-- so it never disappears, including when they are directly behind you. That is
-- a helpful setting to play with and a poisonous one to read a bearing from:
-- the plate stops reporting where they are and starts reporting "off that way
-- somewhere". Platynator turns it on, so it is on for most people.
--
-- We cannot un-clamp a reading, but we can refuse to dress it up as precision.
local function targetPlateIsClamped(unit)
	if not GetCVar then return false end
	if GetCVar("clampTargetNameplateToScreen") ~= "1" then return false end
	return UnitIsUnit and UnitIsUnit(unit, "target") or false
end

-- Nameplates are RESTRICTED regions. Blizzard blocks the measurement widget
-- APIs on them from addon code - "Can't measure restricted regions" - and the
-- restriction exists for exactly the reason we are here: to stop addons reading
-- a unit's position off the screen. Anchoring to a plate is still allowed, which
-- is why the glow works and this does not.
--
-- So every measurement goes through here, and a refusal is a normal outcome
-- rather than an error. Restricted-ness is not constant: it depends on the taint
-- of the running call path, so a plate that refuses now may answer later. We
-- retry, but on a cooldown, because the failing call is not free.
local measure = { blockedUntil = 0, strategy = nil, lastError = nil }
local MEASURE_RETRY = 5

local function safeCenter(region)
	if not region or not region.GetCenter then return nil end
	local ok, x = pcall(region.GetCenter, region)
	if not ok then
		measure.lastError = tostring(x)
		return nil
	end
	return x
end

local function safeScale(region)
	if not region or not region.GetEffectiveScale then return nil end
	local ok, s = pcall(region.GetEffectiveScale, region)
	if ok and s and s > 0 then return s end
	return nil
end

-- The plate itself is restricted, but the frames hanging off it are ordinary
-- addon or Blizzard-Lua frames anchored to it. Measuring one of those gives the
-- same horizontal position without touching the restricted region. Which one
-- exists depends entirely on what is drawing the nameplates, so try in order and
-- remember what worked.
local function plateCenterX(plate, glowFrame)
	-- 1. the plate itself, for the untainted case where this is simply allowed
	local x = safeCenter(plate)
	if x then return x, safeScale(plate) or 1, "plate" end

	-- 2. Blizzard's own nameplate UnitFrame. Present and anchored to the plate
	--    with default nameplates; reparented away by Platynator and friends, so
	--    only trust it while it is still a child of this plate.
	local uf = plate.UnitFrame
	if uf and uf.GetParent and uf:GetParent() == plate then
		x = safeCenter(uf)
		if x then return x, safeScale(uf) or 1, "unitframe" end
	end

	-- 3. whatever the nameplate addon put there - Platynator parents its display
	--    to the plate, so it tracks the unit just as faithfully
	local kids = { plate:GetChildren() }
	for i = 1, #kids do
		local kid = kids[i]
		if kid ~= glowFrame and kid ~= uf and kid.IsShown and kid:IsShown() then
			x = safeCenter(kid)
			if x then return x, safeScale(kid) or 1, "child" end
		end
	end

	return nil
end

-- Which measurement route is working, for diagnostics and for the UI to explain
-- itself: "plate", "unitframe", "child", or nil when everything is refused.
function Spy:GetMeasureStrategy()
	return measure.strategy, measure.lastError
end

-- relative angle in radians: 0 = dead ahead, positive = anticlockwise (left)
-- fourth return is true when the reading hit the screen rail and should be
-- treated as a direction to turn rather than a measured angle.
function Spy:GetLiveBearing(name)
	local unit, plate = findNameplateUnit(name)
	if not unit or not plate then return nil end

	local now = GetTime()
	if now < measure.blockedUntil then return nil, nil, nil, nil, "restricted" end

	local px, plateScale, how = plateCenterX(plate, Spy.Glow and Spy.Glow.frame)
	if not px then
		measure.strategy = nil
		measure.blockedUntil = now + MEASURE_RETRY
		return nil, nil, nil, nil, "restricted"
	end
	measure.strategy = how

	-- GetCenter reports in the frame's own scale, and nameplates do not share
	-- UIParent's scale (nameplateGlobalScale, and addons set their own). Convert
	-- both sides to real screen pixels before comparing them, otherwise every
	-- bearing is stretched or squashed by the ratio between the two scales.
	local uiScale = UIParent:GetEffectiveScale()
	if not plateScale or plateScale <= 0 then plateScale = 1 end
	if not uiScale or uiScale <= 0 then uiScale = 1 end

	local screenWidth = UIParent:GetWidth()
	if not screenWidth or screenWidth <= 0 then return nil end

	local halfScreen = (screenWidth * uiScale) / 2
	if halfScreen <= 0 then return nil end

	-- normalised horizontal offset from screen centre, -1 (left) .. 1 (right)
	local dx = (px * plateScale - halfScreen) / halfScreen
	if dx > 1 then dx = 1 elseif dx < -1 then dx = -1 end

	-- Sitting on the rail with target clamping on means the angle is a floor,
	-- not a measurement: they are at least this far round, possibly behind us.
	-- Say "turn hard that way" instead of naming a precise angle we don't have.
	local clamped = false
	if math.abs(dx) >= 0.98 and targetPlateIsClamped(unit) then
		clamped = true
		return (dx > 0 and -math.pi / 2 or math.pi / 2), unit, estimateRange(unit), true
	end

	local halfFov = math.rad((Spy.db.profile.ArrowFieldOfView or 100) / 2)
	local offset = math.atan(dx * math.tan(halfFov))
	-- screen-right is a clockwise turn, which is negative in our anticlockwise
	-- angle convention
	return -offset, unit, estimateRange(unit), clamped
end

------------------------------------------------------------------------------
-- bearing + distance to the tracked player's last known position
------------------------------------------------------------------------------
-- returns angle (radians, relative to the player's facing), distance in yards,
-- and how many seconds old the position is. nil when it can't be computed.
function Spy:GetArrowVector()
	local name = Arrow.target
	if not name then return nil end
	local playerData = SpyPerCharDB.PlayerData[name]
	if not playerData then return nil end

	-- A visible nameplate beats any stored position: it is where they are right
	-- now, not where we were when we last saw them.
	if Spy.db.profile.ArrowUseNameplates ~= false then
		local live, _, range, clamped, blocked = Spy:GetLiveBearing(name)
		if live then
			return live, range, 0, clamped and "edge" or "live"
		end
		-- Their plate is on screen but the client will not let us measure it.
		-- Say so rather than falling through to a remembered position, which
		-- would quietly replace a live answer with a stale one.
		if blocked == "restricted" then
			return nil, nil, nil, "restricted"
		end
	end

	-- Everything below is a REMEMBERED position. Only trust it if it was
	-- actually derived from a nameplate reading; a plain sighting records our
	-- own coordinates, not theirs, so pointing at it is worse than useless -
	-- it confidently points at a patch of ground we once stood on.
	if not playerData.posFromNameplate then
		return nil, nil, nil, "unknown"
	end
	local dZone, dX, dY = playerData.mapID, playerData.mapX, playerData.mapY
	if not dX or not dY then return nil end
	-- Older records were saved without a mapID. Coordinates are always recorded
	-- from where we were standing, so assume the zone we're in rather than
	-- refusing to show an arrow at all.
	dZone = dZone or (C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player"))
	if not dZone then return nil end
	if not HBD then return nil end

	local oZone = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
	if not oZone then return nil end
	local oPos = C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(oZone, "player")
	if not oPos then return nil end
	local oX, oY = oPos:GetXY()
	if not oX or not oY then return nil end

	-- Convert both points to continent world yards and let HereBeDragons compute
	-- the bearing exactly the way it does for its own map pins. Its GetWorldVector
	-- returns an absolute angle that is guaranteed to line up with GetPlayerFacing
	-- (0 = due north, growing anticlockwise), so subtracting our facing gives a
	-- bearing relative to where we are looking. The previous hand-rolled
	-- atan2(-deltaY, deltaX) had the axes swapped and skipped this normalisation,
	-- which is why the arrow pointed the wrong way.
	local oWX, oWY, oInstance = HBD:GetWorldCoordinatesFromZone(oX, oY, oZone)
	local dWX, dWY, dInstance = HBD:GetWorldCoordinatesFromZone(dX, dY, dZone)
	if not oWX or not dWX then return nil end
	if oInstance ~= dInstance then return nil end	-- different continent/instance

	local bearing, distance = HBD:GetWorldVector(oInstance, oWX, oWY, dWX, dWY)
	if not bearing or not distance then return nil end

	local facing = GetPlayerFacing()
	if not facing then return nil end

	-- 0 = dead ahead; grows anticlockwise, matching the sprite sheet (frame 0
	-- points up, frames advance anticlockwise).
	local angle = bearing - facing
	local age = playerData.time and (time() - playerData.time) or 0
	return angle, distance, age, "remembered"
end

------------------------------------------------------------------------------
-- nameplate settings, so the arrow can tell you why it has nothing to show
------------------------------------------------------------------------------
function Spy:EnemyNameplatesEnabled()
	if not GetCVar then return true end
	local v = GetCVar("nameplateShowEnemies")
	return v == "1" or v == 1
end

function Spy:GetNameplateRange()
	if not GetCVar then return nil end
	return tonumber(GetCVar("nameplateMaxDistance"))
end

-- 41 yards is the ceiling the TBC client enforces, but a nameplate addon may
-- have written a larger number in (Platynator writes 60). Never talk the
-- setting down: raise it to our ceiling only if it is currently below that.
local NAMEPLATE_RANGE_CEILING = 41

function Spy:SetMaxNameplateRange()
	if not SetCVar then return end
	SetCVar("nameplateShowEnemies", 1)
	local current = Spy:GetNameplateRange()
	if not current or current < NAMEPLATE_RANGE_CEILING then
		SetCVar("nameplateMaxDistance", NAMEPLATE_RANGE_CEILING)
	end
	Spy:Print(L["NameplatesMaxed"])
	Spy:UpdateArrow()
end

-- True when the range is already at or above what we would set it to, so the
-- UI can skip offering a button that would do nothing.
function Spy:NameplateRangeIsMaxed()
	local current = Spy:GetNameplateRange()
	return current ~= nil and current >= NAMEPLATE_RANGE_CEILING
end

function Spy:EnableEnemyNameplates()
	if not SetCVar then return end
	SetCVar("nameplateShowEnemies", 1)
	Spy:Print(L["NameplatesEnabled"])
	Spy:UpdateArrow()
end

-- What the arrow can currently show, and why.
--   "live"       - nameplate on screen, bearing is real
--   "edge"       - plate is clamped to the screen edge, so only "turn that way"
--   "remembered" - projected from an earlier nameplate reading
--   "restricted" - their plate is up, but the client refuses to let us measure it
--   "noplates"   - enemy nameplates are switched off
--   "unknown"    - we have no position for them that means anything
function Spy:GetArrowState()
	local name = Arrow.target
	if not name then return nil end
	local _, _, _, state = Spy:GetArrowVector()
	if state == "unknown" and not Spy:EnemyNameplatesEnabled() then
		return "noplates"
	end
	return state or "unknown"
end

-- Explain the restriction once per session. It is a client rule, not something
-- the user can fix by changing a setting, so nagging about it every tick would
-- be noise - but saying nothing leaves an arrow that silently never appears.
local warnedRestricted = false

local function warnRestrictedOnce()
	if warnedRestricted then return end
	warnedRestricted = true
	Spy:Print(L["ArrowRestrictedWarning"])
end

------------------------------------------------------------------------------
-- widgets
------------------------------------------------------------------------------
local function styleArrowTexture(tex, size)
	tex:SetTexture(ARROW_TEXTURE)
	tex:SetWidth(size)
	tex:SetHeight(size)
end

function Spy:CreateArrowFrames()
	if Arrow.built then return end
	local main = Spy.MainWindow
	if not main then return end

	-- ---- title bar variant: arrow sits left of the title text ----
	Arrow.titleArrow = main:CreateTexture(nil, "OVERLAY")
	styleArrowTexture(Arrow.titleArrow, 16)
	Arrow.titleArrow:Hide()

	-- ---- dock variant: strip attached under the window ----
	local dock = CreateFrame("Frame", "Spy_ArrowDock", main, "BackdropTemplate")
	dock:SetHeight(30)
	dock:SetPoint("TOPLEFT", main, "BOTTOMLEFT", 2, -1)
	dock:SetPoint("TOPRIGHT", main, "BOTTOMRIGHT", -2, -1)
	dock:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	dock:SetBackdropColor(0, 0, 0, 0.72)
	dock:SetBackdropBorderColor(0.25, 0.22, 0.18, 1)
	dock:EnableMouse(true)
	dock:SetScript("OnMouseUp", function(_, button)
		if button == "RightButton" then Spy:StopTracking() end
	end)
	dock.Arrow = dock:CreateTexture(nil, "OVERLAY")
	styleArrowTexture(dock.Arrow, 24)
	dock.Arrow:SetPoint("LEFT", dock, "LEFT", 8, 0)
	dock.Name = dock:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	dock.Name:SetPoint("LEFT", dock.Arrow, "RIGHT", 8, 6)
	dock.Name:SetJustifyH("LEFT")
	Spy:AddFontString(dock.Name)
	dock.Info = dock:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	dock.Info:SetPoint("LEFT", dock.Arrow, "RIGHT", 8, -7)
	dock.Info:SetJustifyH("LEFT")
	dock.Info:SetTextColor(0.72, 0.68, 0.6)
	Spy:AddFontString(dock.Info)
	dock.Dist = dock:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	dock.Dist:SetPoint("RIGHT", dock, "RIGHT", -9, 0)
	dock.Dist:SetJustifyH("RIGHT")
	Spy:AddFontString(dock.Dist)
	dock:Hide()
	Arrow.dock = dock

	-- ---- floating variant: independent movable frame ----
	local float = CreateFrame("Frame", "Spy_ArrowFloat", UIParent, "BackdropTemplate")
	float:SetWidth(120)
	float:SetHeight(124)
	float:SetPoint("CENTER", UIParent, "CENTER", 0, -140)
	float:SetMovable(true)
	float:EnableMouse(true)
	float:RegisterForDrag("LeftButton")
	float:SetScript("OnDragStart", function(self)
		if not Spy.db.profile.ArrowFloatLocked then self:StartMoving() end
	end)
	float:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local point, _, relPoint, x, y = self:GetPoint()
		local p = Spy.db.profile.ArrowFloatPosition
		p.point, p.relPoint, p.x, p.y = point, relPoint, x, y
	end)
	float:SetScript("OnMouseUp", function(_, button)
		if button == "RightButton" then Spy:StopTracking() end
	end)
	float.Arrow = float:CreateTexture(nil, "OVERLAY")
	styleArrowTexture(float.Arrow, 64)
	float.Arrow:SetPoint("TOP", float, "TOP", 0, -6)
	float.Name = float:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	float.Name:SetPoint("TOP", float.Arrow, "BOTTOM", 0, -4)
	Spy:AddFontString(float.Name)
	float.Dist = float:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	float.Dist:SetPoint("TOP", float.Name, "BOTTOM", 0, -2)
	Spy:AddFontString(float.Dist)
	float.Info = float:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	float.Info:SetPoint("TOP", float.Dist, "BOTTOM", 0, -2)
	float.Info:SetTextColor(0.72, 0.68, 0.6)
	Spy:AddFontString(float.Info)
	float:Hide()
	Arrow.float = float

	Arrow.built = true
	Spy:RestoreArrowPosition()
end

function Spy:RestoreArrowPosition()
	if not Arrow.float then return end
	local p = Spy.db.profile.ArrowFloatPosition
	if p and p.point then
		Arrow.float:ClearAllPoints()
		Arrow.float:SetPoint(p.point, UIParent, p.relPoint or p.point, p.x or 0, p.y or 0)
	end
end

------------------------------------------------------------------------------
-- visibility / styling
------------------------------------------------------------------------------
function Spy:UpdateArrowVisibility()
	if not Arrow.built then return end
	local style = Spy.db.profile.ArrowStyle
	local tracking = Arrow.target ~= nil and style ~= "off" and Spy.db.profile.ArrowEnabled

	if Arrow.dock then Arrow.dock:SetShown(tracking and style == "dock") end
	if Arrow.float then Arrow.float:SetShown(tracking and style == "floating") end
	if Arrow.titleArrow then Arrow.titleArrow:SetShown(tracking and style == "titlebar") end

	-- the title bar shows the tracked player instead of the list name
	if Spy.UpdateWindowTitle then Spy:UpdateWindowTitle() end
end

local function arrowColor(age)
	local c = Spy.db.profile.Colors["Spy"]["Arrow"]
	if not Spy.db.profile.ArrowColorByAge then return c.r, c.g, c.b end
	local stale = Spy.db.profile.Colors["Spy"]["Arrow Stale"]
	local limit = Spy.db.profile.ArrowStaleSeconds or 30
	local t = math.min(1, (age or 0) / math.max(1, limit))
	return c.r + (stale.r - c.r) * t, c.g + (stale.g - c.g) * t, c.b + (stale.b - c.b) * t
end

local function fmtDistance(yards)
	if not yards then return "" end
	if Spy.db.profile.ArrowDistanceUnit == "meters" then
		return format("%d%s", yards * 0.9144, L["ArrowMetersShort"])
	end
	return format("%d%s", yards, L["ArrowYardsShort"])
end

------------------------------------------------------------------------------
-- per-frame update
------------------------------------------------------------------------------
function Spy:UpdateArrow()
	if not Arrow.built then return end
	if not Spy.db.profile.ArrowEnabled or Spy.db.profile.ArrowStyle == "off" then return end
	local name = Arrow.target
	if not name then return end

	local angle, distance, age, state = Spy:GetArrowVector()

	-- give up on a position that has gone too stale to be useful
	local timeout = Spy.db.profile.ArrowTimeout or 0
	if timeout > 0 and age and age > timeout then
		Spy:StopTracking()
		return
	end
	if not angle then
		-- can't compute a bearing (different zone, or no recorded position)
		if state == "restricted" then warnRestrictedOnce() end
		if Spy.db.profile.ArrowHideOffZone then
			if Arrow.dock then Arrow.dock:Hide() end
			if Arrow.float then Arrow.float:Hide() end
			if Arrow.titleArrow then Arrow.titleArrow:Hide() end
		end
		return
	end
	Spy:UpdateArrowVisibility()

	-- When we're standing on the last-seen spot the direction is unknowable, so
	-- point straight up rather than spinning to noise. This is the case the old
	-- code got most visibly wrong: a target right on top of you (your current
	-- target, distance ~0) made the arrow point wherever you were NOT facing.
	local here = distance and distance < NEAR_YARDS
	local cell = here and 0 or (math.floor(angle / TWOPI * FRAMES + 0.5) % FRAMES)
	local tc = texcoords[cell]
	local r, g, b = arrowColor(age)
	local style = Spy.db.profile.ArrowStyle
	local dist = fmtDistance(distance)
	local playerData = SpyPerCharDB.PlayerData[name]
	local ageText = (age and age > 3) and format(L["ArrowAgo"], SecondsToTime(age)) or L["ArrowNow"]

	-- A clamped plate only tells us which way to spin, so say that rather than
	-- letting a hard 90 degrees read as a measurement, and drop the distance -
	-- an edge reading carries no range information at all.
	if state == "edge" then
		ageText = L["ArrowEdge"]
		dist = ""
	end

	if style == "titlebar" and Arrow.titleArrow then
		Arrow.titleArrow:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
		Arrow.titleArrow:SetVertexColor(r, g, b)
	elseif style == "dock" and Arrow.dock then
		local d = Arrow.dock
		d.Arrow:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
		d.Arrow:SetVertexColor(r, g, b)
		d.Name:SetText(name)
		local cls = playerData and playerData.class
		local cc = cls and Spy.Colors:GetColor("Class", cls)
		if cc then d.Name:SetTextColor(cc.r, cc.g, cc.b) else d.Name:SetTextColor(1, 1, 1) end
		d.Info:SetText(ageText)
		d.Dist:SetText(dist)
		d.Dist:SetTextColor(r, g, b)
	elseif style == "floating" and Arrow.float then
		local f = Arrow.float
		f.Arrow:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
		f.Arrow:SetVertexColor(r, g, b)
		f.Name:SetText(name)
		f.Dist:SetText(dist)
		f.Dist:SetTextColor(r, g, b)
		f.Info:SetText(ageText)
	end
end

-- Resizes/recolours after an options change.
function Spy:ApplyArrowSettings()
	if not Arrow.built then Spy:CreateArrowFrames() end
	if not Arrow.built then return end
	local size = Spy.db.profile.ArrowSize or 24
	if Arrow.titleArrow then
		Arrow.titleArrow:SetWidth(math.min(size, 18))
		Arrow.titleArrow:SetHeight(math.min(size, 18))
	end
	if Arrow.dock then
		Arrow.dock.Arrow:SetWidth(size)
		Arrow.dock.Arrow:SetHeight(size)
		Arrow.dock:SetHeight(math.max(28, size + 6))
	end
	if Arrow.float then
		local big = size * 2.6
		Arrow.float.Arrow:SetWidth(big)
		Arrow.float.Arrow:SetHeight(big)
		Arrow.float:SetWidth(math.max(110, big + 40))
		Arrow.float:SetHeight(big + 62)
	end
	Spy:UpdateArrowVisibility()
	Spy:UpdateArrow()
end

------------------------------------------------------------------------------
-- keep the tracked position warm from a live unit
--
-- The client never hands us an enemy's position, so a sighting is only ever
-- "where I was standing when I last saw them". If the tracked player is right
-- now our target or mouseover AND close enough to interact with, we're standing
-- next to them, so our own position is the best fix available - refresh it so
-- the trail doesn't go stale mid-fight and points true the moment they run.
------------------------------------------------------------------------------
local lastWarm = 0
local function warmTrackedPosition()
	local name = Arrow.target
	if not name then return end
	local now = GetTime()
	if now - lastWarm < 0.5 then return end
	lastWarm = now

	local pd = SpyPerCharDB.PlayerData[name]
	if not pd then return end

	local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
	local pos = mapID and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(mapID, "player")
	if not pos then return end
	local x, y = pos:GetXY()
	if not x or not y or x == 0 or y == 0 then return end

	-- If we can see their nameplate we know the direction and roughly the range,
	-- so project where they actually are and store THAT. This is the difference
	-- between the arrow remembering their position and remembering ours: once
	-- they break line of sight the stored point is still their spot, not the
	-- patch of ground we were standing on.
	local live, unit, range = Spy:GetLiveBearing(name)
	if live and HBD then
		local facing = GetPlayerFacing()
		local wx, wy, instance = HBD:GetWorldCoordinatesFromZone(x, y, mapID)
		if facing and wx then
			local bearing = facing + live			-- back to an absolute bearing
			-- HBD world axes: angle 0 = west, growing clockwise
			local tx = wx + range * math.sin(bearing)
			local ty = wy + range * math.cos(bearing)
			local zx, zy = HBD:GetZoneCoordinatesFromWorld(tx, ty, mapID, true)
			if zx and zy then
				pd.mapX, pd.mapY, pd.mapID, pd.time = zx, zy, mapID, time()
				pd.posFromNameplate = true
				return
			end
		end
	end

	-- No nameplate. Fall back to standing in for their position with our own,
	-- but only when we're right on top of them (~10yd), otherwise we'd drag
	-- their last-seen spot around as we move.
	local tunit
	if UnitExists("target") and GetUnitName("target", true) == name then tunit = "target"
	elseif UnitExists("mouseover") and GetUnitName("mouseover", true) == name then tunit = "mouseover" end
	if not tunit then return end
	if not (CheckInteractDistance and CheckInteractDistance(tunit, 3)) then return end

	pd.mapX, pd.mapY, pd.mapID, pd.time = x, y, mapID, time()
	pd.posFromNameplate = nil
end

------------------------------------------------------------------------------
-- driver: the bearing changes as you turn, so this needs a real frame update
------------------------------------------------------------------------------
local driver = CreateFrame("Frame")
local acc = 0
driver:SetScript("OnUpdate", function(_, elapsed)
	if not Spy.db or not Spy.db.profile then return end
	if not Arrow.target then return end
	acc = acc + elapsed
	if acc < 0.05 then return end	-- 20fps is plenty and stays cheap
	acc = 0
	warmTrackedPosition()
	Spy:UpdateArrow()
	-- Deliberately outside UpdateArrow: the glow is useful on its own, so it
	-- keeps working when the arrow itself is switched off.
	if Spy.UpdateGlow then Spy:UpdateGlow() end
end)
