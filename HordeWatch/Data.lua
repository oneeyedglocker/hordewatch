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

-- record fields: player, class, race, level, levelIsGuess, guild, zone,
-- subZone, mapID, mapX, mapY, layer, method, reporter, relayed
function HW:AddSighting(record)
	if not record or not record.player then return end
	record.player = normalizeName(record.player)
	record.ts = record.ts or time()
	record.reporter = record.reporter or self.CharacterName

	local db = self.charDB
	record.id = db.NextId
	db.NextId = db.NextId + 1

	db.Sightings[#db.Sightings + 1] = record

	local current = db.CurrentState[record.player]
	if not current or record.ts >= current.ts then
		db.CurrentState[record.player] = record
	end

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
