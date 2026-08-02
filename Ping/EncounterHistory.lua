local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:GetLocale("Ping")

local MAX_HISTORY = 250
local DEDUPE_SECONDS = {
	attacked = 10,
	detected = 5,
	returned = 5,
	cooldown = 2,
	healer = 30,
	stealth = 10,
	killed = 10,
	killed_by = 10,
}

local labels = {
	attacked = "HistoryAttacked",
	detected = "HistoryDetected",
	returned = "HistoryReturned",
	cooldown = "HistoryCooldown",
	healer = "HistoryHealer",
	stealth = "HistoryStealth",
	killed = "HistoryKilled",
	killed_by = "HistoryKilledBy",
}

local function historyTable()
	PingPerCharDB = PingPerCharDB or {}
	PingPerCharDB.EncounterHistory = PingPerCharDB.EncounterHistory or {}
	return PingPerCharDB.EncounterHistory
end

function Ping:RecordEncounter(kind, player, detail)
	if type(kind) ~= "string" or type(player) ~= "string" or player == "" then return end
	local history = historyTable()
	local now = time()
	local window = DEDUPE_SECONDS[kind] or 2
	-- Check every entry inside the short window, not only the newest one. Combat
	-- log events interleave (for example attack, cooldown, attack), and checking
	-- only the tail would let high-frequency damage flood the history.
	for i = #history, 1, -1 do
		local previous = history[i]
		if now - (tonumber(previous.time) or 0) > window then break end
		if previous.kind == kind and previous.player == player then return end
	end

	history[#history + 1] = {
		time = now,
		kind = kind,
		player = player,
		detail = type(detail) == "string" and detail ~= "" and detail or nil,
		zone = GetZoneText and GetZoneText() or nil,
	}
	while #history > MAX_HISTORY do table.remove(history, 1) end
end

function Ping:GetEncounterHistoryCount()
	return #historyTable()
end

function Ping:GetEncounterHistoryText()
	local history = historyTable()
	if #history == 0 then return L["HistoryEmpty"] end
	local lines = {}
	for i = #history, 1, -1 do
		local item = history[i]
		local stamp = date("%Y-%m-%d %H:%M:%S", tonumber(item.time) or 0)
		local label = L[labels[item.kind] or "HistoryEncounter"]
		local line = format("[%s] %s - %s", stamp, label, item.player or L["Unknown"])
		if item.detail then line = line .. " - " .. item.detail end
		if item.zone and item.zone ~= "" then line = line .. " (" .. item.zone .. ")" end
		lines[#lines + 1] = line
	end
	return table.concat(lines, "\n")
end

function Ping:ClearEncounterHistory()
	wipe(historyTable())
end
