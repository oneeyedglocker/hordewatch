--[[--------------------------------------------------------------------------
  Ping Import -- bring an existing Spy database across.

  Ping is a fork of Spy with its own saved variables, so a fresh install starts
  empty: no Kill-on-Sight list, no win/loss record, no history of who you have
  met. This copies all of that over from a real Spy install.

  Three rules shape the whole thing:

    * READ ONLY. Spy's tables are never written to. If the import goes wrong,
      Spy is untouched and can simply be used again.

    * MERGE, never replace. Both addons can be run at once, so Ping may already
      hold data Spy does not, and vice versa. Per player we keep the higher win
      and loss counts and the more recent sighting, so importing can only ever
      add information.

    * REPORT what happened. A silent import that half worked looks exactly like
      one that worked. Every run returns counts and prints them.

  It can only run while Spy is INSTALLED AND ENABLED, because its saved
  variables have to be loaded into memory for us to read them. Spy does not
  have to be doing anything - it just has to exist.
----------------------------------------------------------------------------]]

local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:GetLocale("Ping")

Ping.Import = Ping.Import or {}

------------------------------------------------------------------------------
-- availability
------------------------------------------------------------------------------
-- Spy's per-character saved variable. Present as a global only when Spy is
-- installed and enabled for this character.
local function spyDB()
	local db = _G.SpyPerCharDB
	if type(db) ~= "table" then return nil end
	return db
end

-- How much there is to bring over, without importing anything. Used to decide
-- whether to offer the button at all, and to say what it would do.
function Ping:GetSpyImportSummary()
	local db = spyDB()
	if not db then return nil end
	local players, kos, ignored = 0, 0, 0
	if type(db.PlayerData) == "table" then
		for _ in pairs(db.PlayerData) do players = players + 1 end
	end
	if type(db.KOSData) == "table" then
		for _ in pairs(db.KOSData) do kos = kos + 1 end
	end
	if type(db.IgnoreData) == "table" then
		for _ in pairs(db.IgnoreData) do ignored = ignored + 1 end
	end
	return { players = players, kos = kos, ignored = ignored }
end

function Ping:CanImportFromSpy()
	return spyDB() ~= nil
end

------------------------------------------------------------------------------
-- merging one player record
------------------------------------------------------------------------------
-- Fields worth carrying that are simply "the newest non-nil wins" - they
-- describe the player rather than accumulating.
local DESCRIPTIVE = {
	"class", "race", "guild", "faction", "level", "isEnemy", "isGuess",
	"zone", "subZone", "mapID", "mapX", "mapY",
}

-- Returns true when it actually changed something, so the caller can count
-- players updated separately from players merely seen.
local function mergePlayer(destTable, name, src)
	if type(src) ~= "table" then return false end
	local dest = destTable[name]
	if not dest then
		-- New to us: take a copy rather than a reference, so nothing we do
		-- later can reach back into Spy's table.
		local copy = {}
		for k, v in pairs(src) do
			if type(v) ~= "table" then copy[k] = v end
		end
		destTable[name] = copy
		return true
	end

	local changed = false

	-- Counters accumulate: keep the larger. Someone who has been using both
	-- addons has a partial count in each, and the higher is the closer to true.
	for _, field in ipairs({ "wins", "loses" }) do
		local a, b = tonumber(dest[field]) or 0, tonumber(src[field]) or 0
		if b > a then dest[field] = b changed = true end
	end

	-- The sighting is only worth taking if it is NEWER than ours, and when it
	-- is we take the location with it - a time from one sighting and
	-- coordinates from another would describe a place they never were.
	local srcTime, destTime = tonumber(src.time) or 0, tonumber(dest.time) or 0
	if srcTime > destTime then
		dest.time = srcTime
		dest.zone, dest.subZone = src.zone, src.subZone
		dest.mapID, dest.mapX, dest.mapY = src.mapID, src.mapX, src.mapY
		changed = true
	end

	-- Descriptive fields: fill gaps only. A value we already hold was observed
	-- by this addon and is not worth overwriting with an older opinion.
	for _, field in ipairs(DESCRIPTIVE) do
		if dest[field] == nil and src[field] ~= nil then
			dest[field] = src[field]
			changed = true
		end
	end

	-- A confirmed healer stays confirmed. Spy's flag was set by its own
	-- (looser) rule, so it can promote but never demote.
	if src.isHealer and not dest.isHealer then
		dest.isHealer = true
		changed = true
	end

	return changed
end

------------------------------------------------------------------------------
-- the import
------------------------------------------------------------------------------
-- Pass preview = true to count what WOULD happen without writing anything.
function Ping:ImportFromSpy(preview)
	local db = spyDB()
	if not db then
		return nil, L["ImportNoSpy"]
	end

	local added, updated = 0, 0
	local kosAdded, ignoreAdded = 0, 0

	if type(db.PlayerData) == "table" then
		for name, src in pairs(db.PlayerData) do
			if type(name) == "string" and name ~= "" then
				if preview then
					if not PingPerCharDB.PlayerData[name] then
						added = added + 1
					else
						updated = updated + 1
					end
				else
					local existed = PingPerCharDB.PlayerData[name] ~= nil
					local changed = mergePlayer(PingPerCharDB.PlayerData, name, src)
					if not existed then
						added = added + 1
					elseif changed then
						updated = updated + 1
					end
				end
			end
		end
	end

	-- KoS entries are a timestamp keyed by name. Never overwrite one we already
	-- hold: ours may carry reasons Spy's does not.
	if type(db.KOSData) == "table" then
		for name, when in pairs(db.KOSData) do
			if type(name) == "string" and PingPerCharDB.KOSData[name] == nil then
				if not preview then PingPerCharDB.KOSData[name] = when end
				kosAdded = kosAdded + 1
			end
		end
	end

	if type(db.IgnoreData) == "table" then
		for name, v in pairs(db.IgnoreData) do
			if type(name) == "string" and PingPerCharDB.IgnoreData[name] == nil then
				if not preview then PingPerCharDB.IgnoreData[name] = v end
				ignoreAdded = ignoreAdded + 1
			end
		end
	end

	local result = {
		added = added, updated = updated,
		kos = kosAdded, ignored = ignoreAdded,
		preview = preview and true or false,
	}

	if not preview then
		Ping.Import.lastResult = result
		Ping:RefreshCurrentList()
	end
	return result
end

-- Runs the import and reports it in chat, which is what the options button
-- calls. Kept separate from ImportFromSpy so the import itself stays testable
-- and side-effect free apart from the merge.
function Ping:ImportFromSpyAndReport()
	local result, err = Ping:ImportFromSpy(false)
	if not result then
		Ping:Print(err or L["ImportNoSpy"])
		return
	end
	Ping:Print(format(L["ImportDone"],
		result.added, result.updated, result.kos, result.ignored))
end
