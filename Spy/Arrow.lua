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
	Spy:RefreshCurrentList()	-- highlight the tracked row
end

function Spy:StopTracking()
	Arrow.target = nil
	Arrow.since = nil
	Spy:UpdateArrowVisibility()
	Spy:RefreshCurrentList()
end

function Spy:GetTrackedPlayer()
	return Arrow.target
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

	local distance, deltaX, deltaY = HBD:GetZoneDistance(oZone, oX, oY, dZone, dX, dY)
	if not distance then return nil end	-- different continent/instance

	local facing = GetPlayerFacing()
	if not facing then return nil end

	-- HBD world axes: +X is north, +Y is west. Screen-up is the way we face.
	local angle = math.atan2(-deltaY, deltaX) - facing
	local age = playerData.time and (time() - playerData.time) or 0
	return angle, distance, age
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

	local angle, distance, age = Spy:GetArrowVector()

	-- give up on a position that has gone too stale to be useful
	local timeout = Spy.db.profile.ArrowTimeout or 0
	if timeout > 0 and age and age > timeout then
		Spy:StopTracking()
		return
	end
	if not angle then
		-- can't compute a bearing (different zone, or no recorded position)
		if Spy.db.profile.ArrowHideOffZone then
			if Arrow.dock then Arrow.dock:Hide() end
			if Arrow.float then Arrow.float:Hide() end
			if Arrow.titleArrow then Arrow.titleArrow:Hide() end
		end
		return
	end
	Spy:UpdateArrowVisibility()

	local cell = math.floor(angle / TWOPI * FRAMES + 0.5) % FRAMES
	local tc = texcoords[cell]
	local r, g, b = arrowColor(age)
	local style = Spy.db.profile.ArrowStyle
	local dist = fmtDistance(distance)
	local playerData = SpyPerCharDB.PlayerData[name]
	local ageText = (age and age > 3) and format(L["ArrowAgo"], SecondsToTime(age)) or L["ArrowNow"]

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
	Spy:UpdateArrow()
end)
