local HW = HordeWatch

-- Unlike Spy (which overwrites a single "last known" record per player and
-- loses history), HordeWatch keeps an append-only event log so trends and
-- heatmaps can be built over time, plus a derived "current state" table
-- (latest record per player) for anything that just wants "where are they
-- now" - e.g. the status window.

local function normalizeName(name)
	return (name:gsub(" %- ", "-"))
end

function HW:NormalizeName(name)
	return normalizeName(name)
end

-- Merges `incoming` into `existing` in place (same table also sitting in
-- db.Sightings, so this updates the one stored row rather than creating a
-- new one). Keeps the freshest position/zone/method, backfills any field
-- existing didn't have yet (or only had a guess for), and tracks how many
-- distinct reporters have corroborated this encounter.
local function mergeSighting(existing, incoming)
	if incoming.ts >= existing.ts then
		existing.ts = incoming.ts
		existing.mapX = incoming.mapX or existing.mapX
		existing.mapY = incoming.mapY or existing.mapY
		existing.mapID = incoming.mapID or existing.mapID
		existing.subZone = incoming.subZone or existing.subZone
		existing.layer = incoming.layer or existing.layer
		existing.method = incoming.method or existing.method
		existing.relayed = incoming.relayed or existing.relayed
		existing.relaySender = incoming.relaySender or existing.relaySender
	end

	existing.class = existing.class or incoming.class
	existing.race = existing.race or incoming.race
	if incoming.level and (existing.level == nil or (existing.levelIsGuess and not incoming.levelIsGuess)) then
		existing.level = incoming.level
		existing.levelIsGuess = incoming.levelIsGuess
	end
	existing.guild = existing.guild or incoming.guild

	local reporter = incoming.reporter or "?"
	existing.reporters = existing.reporters or {}
	if not existing.reporters[reporter] then
		existing.reporters[reporter] = true
		existing.reportCount = (existing.reportCount or 1) + 1
	end
end

-- record fields: player, class, race, level, levelIsGuess, guild, zone,
-- subZone, mapID, mapX, mapY, layer, method, reporter, relayed,
-- windowStart, reportCount, reporters
function HW:AddSighting(record)
	if not record or not record.player then return end
	record.player = normalizeName(record.player)
	record.ts = record.ts or time()
	record.reporter = record.reporter or self.CharacterName

	local db = self.charDB
	local window = self.db.profile.CollapseWindowSeconds
	local current = db.CurrentState[record.player]

	-- Collapse into the existing row if this is very likely the SAME
	-- encounter: same player, same zone, and within `window` seconds of
	-- when that encounter was FIRST logged (a fixed origin, not a rolling
	-- one - so a target that lingers for minutes still gets a fresh row
	-- roughly every `window` seconds for movement/heatmap data, instead of
	-- one row swallowing the whole visit). This is what stops e.g. three
	-- guildmates all reporting one sighting, or your own nameplate+combat
	-- log both firing on the same GCD, from producing multiple rows for
	-- one real-world moment.
	if current and current.windowStart and current.zone == record.zone
		and math.abs(record.ts - current.windowStart) <= window then
		mergeSighting(current, record)
		self:SendMessage("HordeWatch_NewSighting", current)
		return
	end

	record.id = db.NextId
	db.NextId = db.NextId + 1
	record.windowStart = record.ts
	record.reportCount = 1
	record.reporters = { [record.reporter] = true }

	db.Sightings[#db.Sightings + 1] = record
	db.CurrentState[record.player] = record

	if #db.Sightings > self.db.profile.MaxRecords then
		table.remove(db.Sightings, 1)
	end

	self:SendMessage("HordeWatch_NewSighting", record)
end

function HW:PruneSightings()
	local db = self.charDB
	local cutoff = time() - (self.db.profile.RetentionDays * 86400)
	local kept = {}
	for _, rec in ipairs(db.Sightings) do
		if rec.ts >= cutoff then
			kept[#kept + 1] = rec
		end
	end
	db.Sightings = kept

	-- CurrentState can reference pruned records; that's fine, it's a
	-- point-in-time snapshot and gets overwritten on the next sighting.
end

function HW:ClearCurrentState()
	-- Only clears the "who's around right now" snapshot used by the UI.
	-- The historical Sightings log (the actual trend data) is left alone
	-- on purpose - that's the point of the append-only log.
	wipe(self.charDB.CurrentState)
	self:SendMessage("HordeWatch_StateCleared")
end
