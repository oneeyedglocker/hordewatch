local HW = HordeWatch
local HBD = LibStub("HereBeDragons-2.0")

HW.Method = {
	TARGET     = "target",     -- targeted directly: interact/targeting range
	MOUSEOVER  = "mouseover",  -- moused over directly: on-screen, similar range
	NAMEPLATE  = "nameplate",  -- nameplate rendered: nameplate view distance
	COMBATLOG  = "combatlog",  -- seen only in combat log: ~100yd log radius
	MINIMAP    = "minimap",    -- minimap tracking blip (Track Humanoids etc.): widest, LoS/stealth-piercing
	COMM       = "comm",       -- relayed from another HordeWatch user
}

-- ============================================================
-- Layer/shard fingerprint.
--
-- Blizzard does not expose a documented "what layer am I on" API to
-- addons - deliberately, since it would make cross-layer ganking/world
-- boss coordination trivial (Blizzard has actively hotfixed prior
-- addon-side layer-detection tricks, e.g. a /who-based method). What we
-- use instead is a reverse-engineered signal: non-player GUIDs
-- (Creature/Vehicle/Pet) are formatted as
--   Type-0-<serverID>-<instanceID>-<zoneUID>-<unitID>-<spawnUID>
-- and that serverID segment differs per layer, because each layer runs as
-- its own server process. Player GUIDs ("Player-<realmID>-<UID>") do NOT
-- expose an equivalent field, so we sample it opportunistically off any
-- nearby non-player unit (target, a nameplate, or your own pet) instead.
--
-- This gives an OPAQUE token that's stable while you stay on one layer and
-- changes when you change layers (via zoning/grouping) - enough to tell
-- "this sighting was on the same layer as that one" apart from "different
-- layer, don't treat these as the same world-state". It is NOT the
-- human-readable "Layer 1/2/3" the game shows nowhere to addons at all,
-- and there's no guarantee this keeps working after a future patch.
-- ============================================================

local currentLayer, currentLayerAt = nil, 0

local function extractServerID(guid)
	if not guid then return nil end
	local kind, _, serverID = strsplit("-", guid)
	if not kind or kind == "Player" then return nil end
	return tonumber(serverID)
end

local function refreshLayerFingerprint()
	if GetTime() - currentLayerAt < 20 then return end -- layer only changes via zoning/grouping, no need to resample often

	local serverID = UnitExists("target") and extractServerID(UnitGUID("target"))

	if not serverID and C_NamePlate then
		for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
			local unit = plate.namePlateUnitToken
			if unit and UnitExists(unit) and not UnitIsPlayer(unit) then
				serverID = extractServerID(UnitGUID(unit))
				if serverID then break end
			end
		end
	end

	if not serverID and UnitExists("pet") then
		serverID = extractServerID(UnitGUID("pet"))
	end

	if serverID then
		currentLayer = serverID
		currentLayerAt = GetTime()
	end
end

function HW:GetCurrentLayer()
	refreshLayerFingerprint()
	return currentLayer
end

-- Finds a live unit token whose GUID matches the given GUID, if one is
-- currently visible (target/mouseover/a nameplate). Used to backfill guild
-- (and sometimes level) for combat-log-only sightings, since neither is
-- exposed by GetPlayerInfoByGUID.
function HW:FindUnitByGUID(guid)
	if not guid then return nil end
	if UnitExists("target") and UnitGUID("target") == guid then return "target" end
	if UnitExists("mouseover") and UnitGUID("mouseover") == guid then return "mouseover" end
	if C_NamePlate then
		for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
			local unit = plate.namePlateUnitToken
			if unit and UnitGUID(unit) == guid then return unit end
		end
	end
	return nil
end

-- Captures the REPORTING PLAYER's own position/zone/layer. This is the
-- position that gets stamped onto a sighting record - we are never able to
-- read a hostile unit's actual coordinates, only infer "they were near me,
-- on my layer, when I detected them".
function HW:CaptureReporterPosition()
	local mapID = C_Map.GetBestMapForUnit("player")
	local zone = GetZoneText()
	local subZone = GetSubZoneText()
	local layer = self:GetCurrentLayer()

	-- Continent/world coordinates (continuous across every zone on one
	-- continent, in yards) via HereBeDragons, in ADDITION to the zone-local
	-- 0-1 mapX/mapY below. mapX/mapY alone can't back a multi-zone map -
	-- each zone is its own independent 0-1 image with no shared reference
	-- frame between them. worldX/worldY share one frame for every zone
	-- under the same continentID; a different continent (Kalimdor vs
	-- Eastern Kingdoms vs Outland) is still a different coordinate space,
	-- same as Blizzard's own world map - that seam isn't something this
	-- can paper over, only a continent switcher on the map UI can.
	local worldX, worldY, continentID = HBD:GetPlayerWorldPosition()
	if worldX and worldY then
		worldX = math.floor(worldX * 10) / 10
		worldY = math.floor(worldY * 10) / 10
	end

	if not mapID then
		local instanceName = GetInstanceInfo()
		return {
			mapID = nil,
			mapX = nil,
			mapY = nil,
			worldX = worldX,
			worldY = worldY,
			continentID = continentID,
			zone = instanceName or zone,
			subZone = subZone,
			layer = layer,
		}
	end

	local pos = C_Map.GetPlayerMapPosition(mapID, "player")
	if not pos then
		return {
			mapID = mapID,
			mapX = nil,
			mapY = nil,
			worldX = worldX,
			worldY = worldY,
			continentID = continentID,
			zone = zone,
			subZone = subZone,
			layer = layer,
		}
	end

	local x, y = pos:GetXY()
	if x == 0 and y == 0 then
		-- 0,0 is indistinguishable from "no data" for GetPlayerMapPosition;
		-- treat it the same way Spy does, as unusable.
		x, y = nil, nil
	else
		x = math.floor(x * 1000) / 1000
		y = math.floor(y * 1000) / 1000
	end

	return {
		mapID = mapID,
		mapX = x,
		mapY = y,
		worldX = worldX,
		worldY = worldY,
		continentID = continentID,
		zone = zone,
		subZone = subZone,
		layer = layer,
	}
end
