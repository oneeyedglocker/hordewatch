local HW = HordeWatch

-- Detection methods, roughly ordered by how tightly they bound the true
-- distance between the reporter and the target at the moment of capture.
-- Spy stamps every sighting with the reporter's own coordinates regardless
-- of *how* the enemy was noticed; we keep that same trick (Blizzard never
-- exposes a hostile unit's real position) but tag *how* confident that
-- substitution is, so a heatmap/trend consumer can weight or blur points
-- instead of treating every dot as equally precise.
HW.Method = {
	TARGET     = "target",     -- targeted directly: interact/targeting range
	MOUSEOVER  = "mouseover",  -- moused over directly: on-screen, similar range
	NAMEPLATE  = "nameplate",  -- nameplate rendered: nameplate view distance
	COMBATLOG  = "combatlog",  -- seen only in combat log: ~100yd log radius
	MINIMAP    = "minimap",    -- minimap tracking blip (Track Humanoids etc.): widest, LoS/stealth-piercing
	COMM       = "comm",       -- relayed from another HordeWatch user
}

-- Confidence tier per method: 1 = tightest bound on distance, 4 = loosest.
-- Used for weighting/blur-radius on the dashboard side, not for anything
-- gameplay-facing.
HW.MethodConfidence = {
	[HW.Method.TARGET]    = 1,
	[HW.Method.MOUSEOVER] = 1,
	[HW.Method.NAMEPLATE] = 2,
	[HW.Method.COMBATLOG] = 3,
	[HW.Method.MINIMAP]   = 4,
}

-- Captures the REPORTING PLAYER's own position/zone. This is the position
-- that gets stamped onto a sighting record - we are never able to read a
-- hostile unit's actual coordinates, only infer "they were near me when I
-- detected them".
function HW:CaptureReporterPosition()
	local mapID = C_Map.GetBestMapForUnit("player")
	local zone = GetZoneText()
	local subZone = GetSubZoneText()

	if not mapID then
		local instanceName = GetInstanceInfo()
		return {
			mapID = nil,
			mapX = nil,
			mapY = nil,
			zone = instanceName or zone,
			subZone = subZone,
		}
	end

	local pos = C_Map.GetPlayerMapPosition(mapID, "player")
	if not pos then
		return {
			mapID = mapID,
			mapX = nil,
			mapY = nil,
			zone = zone,
			subZone = subZone,
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
		zone = zone,
		subZone = subZone,
	}
end
