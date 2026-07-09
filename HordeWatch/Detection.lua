local HW = HordeWatch

-- ============================================================
-- Shared unit -> sighting builder, used by target/mouseover/nameplate
-- (all three follow the same "I can see this unit token" shape).
-- ============================================================
local function buildRecordFromUnit(unit, method)
	if not UnitExists(unit) or not UnitIsPlayer(unit) then return nil end
	if not UnitIsEnemy("player", unit) then return nil end

	local name, realm = UnitName(unit)
	if not name then return nil end
	if realm and realm ~= "" then name = name .. "-" .. realm end

	local _, class = UnitClass(unit)
	local race = select(2, UnitRace(unit))
	local level = UnitLevel(unit)
	local levelIsGuess = false
	if level == -1 then
		-- skull-masked (too high above the reporter's own level); Spy tries
		-- to back this out from a large spell-ID->class/race/level table.
		-- We deliberately skip that here to keep detection lean - class/race
		-- already come for free from the unit token / GUID, level just goes
		-- in as unknown rather than guessed.
		level = nil
		levelIsGuess = true
	end
	local guild = GetGuildInfo(unit)

	local pos = HW:CaptureReporterPosition()

	return {
		player = name,
		class = class,
		race = race,
		level = level,
		levelIsGuess = levelIsGuess,
		guild = guild,
		zone = pos.zone,
		subZone = pos.subZone,
		mapID = pos.mapID,
		mapX = pos.mapX,
		mapY = pos.mapY,
		method = method,
	}
end

function HW:OnTargetChanged()
	if not self.EnabledInZone then return end
	local record = buildRecordFromUnit("target", self.Method.TARGET)
	if record then self:AddSighting(record) end
end

function HW:OnMouseoverUnit()
	if not self.EnabledInZone then return end
	local record = buildRecordFromUnit("mouseover", self.Method.MOUSEOVER)
	if record then self:AddSighting(record) end
end

function HW:OnNamePlateUnit(_, unit)
	if not self.EnabledInZone then return end
	local record = buildRecordFromUnit(unit, self.Method.NAMEPLATE)
	if record then self:AddSighting(record) end
end

-- ============================================================
-- Combat log: the widest net, doesn't require ever targeting/seeing them.
-- NOTE: GUIDs are always prefixed "Player-" (capital P). Spy's own
-- destination-unit branch checks the lowercase string "player" and so
-- never actually matches anything - confirmed by reading Spy.lua:2196-2220.
-- We check "Player-" correctly on both source and destination here.
-- ============================================================
local function isHostilePlayerGUID(guid, flags)
	if not guid or not flags then return false end
	if bit.band(flags, COMBATLOG_OBJECT_REACTION_HOSTILE) ~= COMBATLOG_OBJECT_REACTION_HOSTILE then
		return false
	end
	return strsub(guid, 1, 7) == "Player-"
end

local function buildRecordFromGUID(guid, name)
	if not name then return nil end
	local _, class, _, raceFile, _, actualName = GetPlayerInfoByGUID(guid)
	if not class then return nil end

	local pos = HW:CaptureReporterPosition()
	return {
		player = actualName or name,
		class = class,
		race = raceFile,
		level = nil,
		levelIsGuess = true,
		guild = nil,
		zone = pos.zone,
		subZone = pos.subZone,
		mapID = pos.mapID,
		mapX = pos.mapX,
		mapY = pos.mapY,
		method = HW.Method.COMBATLOG,
	}
end

function HW:OnCombatLogEvent()
	if not self.EnabledInZone then return end
	local _, _, _, srcGUID, srcName, srcFlags, _, dstGUID, dstName, dstFlags = CombatLogGetCurrentEventInfo()

	if isHostilePlayerGUID(srcGUID, srcFlags) then
		local record = buildRecordFromGUID(srcGUID, srcName)
		if record then self:AddSighting(record) end
	end

	if isHostilePlayerGUID(dstGUID, dstFlags) then
		local record = buildRecordFromGUID(dstGUID, dstName)
		if record then self:AddSighting(record) end
	end
end

-- ============================================================
-- Minimap tracking-blip scan (e.g. Hunter Track Humanoids): can reveal
-- position through line-of-sight/stealth, but the blip tooltip text alone
-- can't be trusted to distinguish a hostile player from an NPC or party
-- member of the same name. So - matching Spy's actual (correct) design -
-- this only REFRESHES players already confirmed hostile by one of the
-- methods above; it does not mint brand-new sightings from blip text alone.
-- ============================================================
local minimapScanFrame = CreateFrame("Frame")
local lastTooltipText

local function scanMinimapTooltip()
	local text = GameTooltipTextLeft1:GetText()
	if not text or text == lastTooltipText then return end
	lastTooltipText = text

	for line in text:gmatch("[^\n]+") do
		-- strip texture markup (|Tpath|t) and color codes (|cAARRGGBB ... |r)
		-- that Blizzard/other addons may have embedded in the raw blip line
		line = line:gsub("|T.-|t", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
		local name = HW:NormalizeName(strtrim(line))
		local current = HW.charDB.CurrentState[name]
		if current then
			local pos = HW:CaptureReporterPosition()
			HW:AddSighting({
				player = name,
				class = current.class,
				race = current.race,
				level = current.level,
				levelIsGuess = current.levelIsGuess,
				guild = current.guild,
				zone = pos.zone,
				subZone = pos.subZone,
				mapID = pos.mapID,
				mapX = pos.mapX,
				mapY = pos.mapY,
				method = HW.Method.MINIMAP,
			})
		end
	end
end

minimapScanFrame:SetScript("OnUpdate", function()
	if HW.EnabledInZone and not HW.InInstance and GameTooltip:IsOwned(Minimap) then
		scanMinimapTooltip()
	end
end)

-- ============================================================
-- Wiring
-- ============================================================
function HW:StartDetection()
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnTargetChanged")
	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT", "OnMouseoverUnit")
	self:RegisterEvent("NAME_PLATE_UNIT_ADDED", "OnNamePlateUnit")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "OnCombatLogEvent")
	minimapScanFrame:Show()
end

function HW:StopDetection()
	self:UnregisterEvent("PLAYER_TARGET_CHANGED")
	self:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
	self:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	minimapScanFrame:Hide()
end
