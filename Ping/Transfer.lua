local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:GetLocale("Ping")
local Serializer = LibStub("AceSerializer-3.0")

local MAX_CODE_BYTES = 500000
local PLAYER_FIELDS = {
	"name", "class", "level", "race", "guild", "faction", "isEnemy", "isGuess",
	"time", "wins", "loses", "mapX", "mapY", "mapID", "zone", "subZone",
	"reason", "isHealer", "healTotal", "healCount", "lastHeal",
}
local APPEARANCE_FIELDS = {
	"LookPreset", "LookTheme", "ClassColoredNames", "BarOpacity", "Font", "BarTexture",
	"ShowBackground", "BackgroundOpacity", "ShowBorder", "WindowScale", "TitleBarStyle",
	"TitleBarOpacity", "HealerGreenEdge",
	"MarkHealers", "DimNonHealers", "ArtworkStyle",
}
local MAIN_WINDOW_FIELDS = { "RowHeight", "RowSpacing", "TextHeight", "Alpha", "AlphaBG" }
local COLOR_BRANCHES = { "Window", "Bar", "Ping", "Class" }

local function copyValue(value, depth)
	if type(value) ~= "table" then return value end
	if (depth or 0) > 4 then return nil end
	local out = {}
	for k, v in pairs(value) do
		if type(k) == "string" or type(k) == "number" then
			local kind = type(v)
			if kind == "string" or kind == "number" or kind == "boolean" then out[k] = v
			elseif kind == "table" then out[k] = copyValue(v, (depth or 0) + 1) end
		end
	end
	return out
end

local function selectedPlayers()
	local out = {}
	for name in pairs(PingPerCharDB.KOSData or {}) do out[name] = true end
	for name in pairs(PingPerCharDB.IgnoreData or {}) do out[name] = true end
	return out
end

local function exportLists()
	local result = { kos = copyValue(PingPerCharDB.KOSData), ignore = copyValue(PingPerCharDB.IgnoreData), players = {} }
	for name in pairs(selectedPlayers()) do
		local source = PingPerCharDB.PlayerData[name]
		if type(source) == "table" then
			local player = {}
			for _, field in ipairs(PLAYER_FIELDS) do player[field] = copyValue(source[field]) end
			result.players[name] = player
		end
	end
	return result
end

local function exportAppearance()
	local p, out = Ping.db.profile, { profile = {}, mainWindow = {}, colors = {} }
	for _, field in ipairs(APPEARANCE_FIELDS) do out.profile[field] = copyValue(p[field]) end
	for _, field in ipairs(MAIN_WINDOW_FIELDS) do out.mainWindow[field] = copyValue(p.MainWindow[field]) end
	for _, branch in ipairs(COLOR_BRANCHES) do out.colors[branch] = copyValue(p.Colors[branch]) end
	return out
end

Ping.TransferScopes = Ping.TransferScopes or { lists = true, spells = true, appearance = true }
Ping.TransferText = Ping.TransferText or ""
Ping.TransferStatus = Ping.TransferStatus or nil

function Ping:GetTransferScope(scope) return Ping.TransferScopes[scope] == true end
function Ping:SetTransferScope(scope, value) Ping.TransferScopes[scope] = value == true end
function Ping:GetTransferText() return Ping.TransferText or "" end
function Ping:SetTransferText(value) Ping.TransferText = value or "" Ping.TransferStatus = nil end
function Ping:GetTransferStatus() return Ping.TransferStatus or L["TransferReady"] end

function Ping:GenerateTransferCode()
	local payload = { magic = "PING_TRANSFER", schema = 1, addonVersion = Ping.Version, scopes = {} }
	if Ping:GetTransferScope("lists") then payload.scopes.lists = exportLists() end
	if Ping:GetTransferScope("spells") then
		payload.scopes.spells = {
			healer = Ping.db.profile.HealerSpellListText,
			cooldown = Ping.db.profile.CooldownListText,
		}
	end
	if Ping:GetTransferScope("appearance") then payload.scopes.appearance = exportAppearance() end
	Ping.TransferText = Serializer:Serialize(payload)
	Ping.TransferStatus = format(L["TransferGenerated"], #Ping.TransferText)
	Ping:Print(Ping.TransferStatus)
end

local function mergePlayer(name, source)
	if type(name) ~= "string" or #name > 80 or type(source) ~= "table" then return end
	local target = PingPerCharDB.PlayerData[name] or { name = name }
	PingPerCharDB.PlayerData[name] = target
	local sourceNewer = (tonumber(source.time) or 0) >= (tonumber(target.time) or 0)
	for _, field in ipairs(PLAYER_FIELDS) do
		local value = source[field]
		if value ~= nil then
			if field == "reason" and type(value) == "table" then
				target.reason = target.reason or {}
				for reason, detail in pairs(value) do
					if type(reason) == "string" and #reason <= 200 then target.reason[reason] = copyValue(detail) end
				end
			elseif target[field] == nil or sourceNewer then
				target[field] = copyValue(value)
			end
		end
	end
end

local function importLists(data)
	if type(data) ~= "table" then return 0, 0 end
	local players = type(data.players) == "table" and data.players or {}
	local kosCount, ignoreCount = 0, 0
	if type(data.ignore) == "table" then
		for name, value in pairs(data.ignore) do
			if type(name) == "string" and #name <= 80 and value then
				mergePlayer(name, players[name])
				PingPerCharDB.IgnoreData[name] = true
				ignoreCount = ignoreCount + 1
			end
		end
	end
	if type(data.kos) == "table" then
		for name, added in pairs(data.kos) do
			if type(name) == "string" and #name <= 80 then
				mergePlayer(name, players[name])
				PingPerCharDB.KOSData[name] = math.max(tonumber(PingPerCharDB.KOSData[name]) or 0, tonumber(added) or time())
				PingPerCharDB.IgnoreData[name] = nil
				if PingPerCharDB.PlayerData[name] then PingPerCharDB.PlayerData[name].kos = 1 end
				kosCount = kosCount + 1
			end
		end
	end
	return kosCount, ignoreCount
end

local function validScalar(value)
	local kind = type(value)
	return kind == "string" or kind == "number" or kind == "boolean"
end

local function importAppearance(data)
	if type(data) ~= "table" then return false end
	local p = Ping.db.profile
	if type(data.profile) == "table" then
		for _, field in ipairs(APPEARANCE_FIELDS) do
			if validScalar(data.profile[field]) then p[field] = data.profile[field] end
		end
	end
	if type(data.mainWindow) == "table" then
		for _, field in ipairs(MAIN_WINDOW_FIELDS) do
			local value = tonumber(data.mainWindow[field])
			if value and value >= 0 and value <= 200 then p.MainWindow[field] = value end
		end
	end
	if type(data.colors) == "table" then
		for _, branch in ipairs(COLOR_BRANCHES) do
			if type(data.colors[branch]) == "table" and type(p.Colors[branch]) == "table" then
				for slot, color in pairs(data.colors[branch]) do
					if type(slot) == "string" and type(color) == "table" and p.Colors[branch][slot] then
						local r, g, b, a = tonumber(color.r), tonumber(color.g), tonumber(color.b), tonumber(color.a)
						if r and g and b and r >= 0 and r <= 1 and g >= 0 and g <= 1 and b >= 0 and b <= 1 then
							Ping.Colors:SetColor(branch, slot, { r = r, g = g, b = b, a = a and math.max(0, math.min(1, a)) or 1 })
						end
					end
				end
			end
		end
	end
	Ping:ApplyWindowStyle()
	Ping:BarsChanged()
	Ping:RefreshCurrentList()
	return true
end

function Ping:ApplyTransferCode()
	local code = (Ping.TransferText or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if code == "" or #code > MAX_CODE_BYTES then
		Ping.TransferStatus = format(L["TransferInvalid"], code == "" and "empty code" or "code is too large")
		return Ping:Print(Ping.TransferStatus)
	end
	local ok, payload = Serializer:Deserialize(code)
	if not ok or type(payload) ~= "table" or payload.magic ~= "PING_TRANSFER" or payload.schema ~= 1 or type(payload.scopes) ~= "table" then
		Ping.TransferStatus = format(L["TransferInvalid"], ok and "unsupported format" or tostring(payload))
		return Ping:Print(Ping.TransferStatus)
	end
	local kos, ignored, spellsDone, appearanceDone = 0, 0, false, false
	if Ping:GetTransferScope("lists") and payload.scopes.lists then kos, ignored = importLists(payload.scopes.lists) end
	if Ping:GetTransferScope("spells") and type(payload.scopes.spells) == "table" then
		local spells = payload.scopes.spells
		if type(spells.healer) == "string" and #spells.healer <= 100000 then Ping.db.profile.HealerSpellListText = spells.healer Ping.db.profile.HealerSpellListSeeded = true end
		if type(spells.cooldown) == "string" and #spells.cooldown <= 100000 then Ping.db.profile.CooldownListText = spells.cooldown Ping.db.profile.CooldownListSeeded = true end
		Ping:BuildHealerSpellNames() Ping:BuildCooldownLookup() spellsDone = true
	end
	if Ping:GetTransferScope("appearance") and payload.scopes.appearance then appearanceDone = importAppearance(payload.scopes.appearance) end
	if Ping.db.profile.ShareKOSBetweenCharacters then Ping:RegenerateKOSCentralList() end
	Ping:RegenerateKOSGuildList() Ping:RefreshCurrentList()
	Ping.TransferStatus = format(L["TransferImported"], kos, ignored, tostring(spellsDone), tostring(appearanceDone))
	Ping:Print(Ping.TransferStatus)
end
