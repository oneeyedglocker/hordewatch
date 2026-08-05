--[[--------------------------------------------------------------------------
  Ping custom themes -- save the look you have as a named theme.

  The built-in themes are a starting point, not a menu. Anyone who tunes the
  colors to their taste currently has that work living in one profile, lost the
  moment they pick a theme to see what it looks like, and impossible to carry to
  another character or hand to a guildmate.

  A saved theme is the same shape as a built-in one, with one deliberate
  difference: it stores the CLASS COLORS IT RESOLVED TO, not the tint recipe
  that produced them. A recipe would re-derive on load and drift if the stock
  colors ever change; a saved theme should look tomorrow exactly like it looked
  when it was saved.

  Saved themes live in the profile, appear in the same dropdown below their own
  separator, and export as a string so they can move between characters.
----------------------------------------------------------------------------]]

local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:GetLocale("Ping")
local Serializer = LibStub("AceSerializer-3.0")

-- Custom keys are prefixed so they can never collide with a built-in theme, and
-- so ApplyLookTheme can tell the two apart without a lookup.
local PREFIX = "custom:"
Ping.CustomThemePrefix = PREFIX

local function store()
	local p = Ping.db and Ping.db.profile
	if not p then return nil end
	if type(p.CustomThemes) ~= "table" then p.CustomThemes = {} end
	return p.CustomThemes
end

function Ping:IsCustomTheme(key)
	return type(key) == "string" and key:sub(1, #PREFIX) == PREFIX
end

function Ping:GetCustomTheme(key)
	local s = store()
	return s and s[key] or nil
end

------------------------------------------------------------------------------
-- capture
------------------------------------------------------------------------------
-- Branches a theme is allowed to own. Anything outside these is a setting the
-- user tunes per profile rather than part of a look, so saving must not drag
-- it along and applying must not stamp on it.
local THEME_BRANCHES = { "Window", "Ping", "Bar", "Alert", "Warning" }

local function copyColor(c)
	if type(c) ~= "table" then return nil end
	return { r = c.r, g = c.g, b = c.b, a = c.a }
end

-- Snapshots the live look. Class colors are read back from the profile, which
-- means whatever the last theme's tint produced is what gets saved - the whole
-- point, since that is what the user is looking at and chose to keep.
function Ping:CaptureCurrentLook()
	local p = Ping.db.profile
	local look = { colors = {}, classes = {}, settings = {} }

	for _, branch in ipairs(THEME_BRANCHES) do
		local slots = p.Colors and p.Colors[branch]
		if slots then
			for slot, c in pairs(slots) do
				local copy = copyColor(c)
				if copy then look.colors[#look.colors + 1] = { branch, slot, copy } end
			end
		end
	end

	for class, c in pairs((p.Colors and p.Colors.Class) or {}) do
		look.classes[class] = copyColor(c)
	end

	for _, key in ipairs({ "ClassColoredNames", "BarOpacity", "ShowBackground",
		"BackgroundOpacity", "ShowBorder", "TitleBarOpacity", "TitleBarStyle",
		"BarTexture", "Font" }) do
		look.settings[key] = p[key]
	end
	look.artwork = p.ArtworkStyle or "legacy"
	return look
end

------------------------------------------------------------------------------
-- save / delete
------------------------------------------------------------------------------
function Ping:SaveCustomTheme(name)
	name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if name == "" then
		Ping:Print(L["CustomThemeNeedsName"])
		return false
	end
	if #name > 40 then name = name:sub(1, 40) end

	local s = store()
	if not s then return false end

	local look = Ping:CaptureCurrentLook()
	look.name = name
	look.custom = true
	s[PREFIX .. name] = look

	Ping.db.profile.LookTheme = PREFIX .. name
	Ping:Print(format(L["CustomThemeSaved"], name))
	return true
end

function Ping:DeleteCustomTheme(key)
	local s = store()
	if not s or not s[key] then return false end
	local name = s[key].name or key
	s[key] = nil
	-- Deleting the theme you are wearing leaves the look alone and just stops
	-- claiming it came from a saved theme, which is less surprising than
	-- snapping back to a built-in.
	if Ping.db.profile.LookTheme == key then
		Ping.db.profile.LookTheme = "classic"
	end
	Ping:Print(format(L["CustomThemeDeleted"], name))
	return true
end

function Ping:GetCustomThemeList()
	local s = store() or {}
	local keys = {}
	for key in pairs(s) do keys[#keys + 1] = key end
	table.sort(keys, function(a, b)
		return (s[a].name or a):lower() < (s[b].name or b):lower()
	end)
	return keys
end

function Ping:HasCustomThemes()
	return next(store() or {}) ~= nil
end

------------------------------------------------------------------------------
-- export / import
------------------------------------------------------------------------------
function Ping:ExportCustomTheme(key)
	local theme = Ping:GetCustomTheme(key)
	if not theme then
		Ping:Print(L["CustomThemeNoneSelected"])
		return
	end
	local payload = { magic = "PING_THEME", schema = 1, theme = theme }
	Ping.CustomThemeText = Serializer:Serialize(payload)
	Ping:Print(format(L["CustomThemeExported"], theme.name or key, #Ping.CustomThemeText))
end

-- Everything below is treated as hostile: a theme string can arrive from
-- anywhere. Only the fields a theme is allowed to carry are copied across, and
-- each is checked, so a malformed or malicious payload cannot write arbitrary
-- profile keys.
local ALLOWED_SETTINGS = {
	ClassColoredNames = "boolean", BarOpacity = "number",
	ShowBackground = "boolean", BackgroundOpacity = "number",
	ShowBorder = "boolean", TitleBarOpacity = "number",
	TitleBarStyle = "string", BarTexture = "string", Font = "string",
}

local function sanitizeColor(c)
	if type(c) ~= "table" then return nil end
	local out = {}
	for _, k in ipairs({ "r", "g", "b", "a" }) do
		local v = tonumber(c[k])
		if v then out[k] = math.max(0, math.min(1, v)) end
	end
	if not (out.r and out.g and out.b) then return nil end
	return out
end

function Ping:ImportCustomTheme(code)
	code = tostring(code or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if code == "" then
		Ping:Print(L["CustomThemeNoCode"])
		return false
	end
	local ok, payload = Serializer:Deserialize(code)
	if not ok or type(payload) ~= "table" or payload.magic ~= "PING_THEME"
		or payload.schema ~= 1 or type(payload.theme) ~= "table" then
		Ping:Print(L["CustomThemeBadCode"])
		return false
	end

	local src = payload.theme
	local name = tostring(src.name or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if name == "" then name = L["CustomThemeImportedName"] end
	if #name > 40 then name = name:sub(1, 40) end

	local clean = { name = name, custom = true, colors = {}, classes = {}, settings = {} }

	if type(src.colors) == "table" then
		for _, entry in ipairs(src.colors) do
			if type(entry) == "table" and type(entry[1]) == "string" and type(entry[2]) == "string" then
				local c = sanitizeColor(entry[3])
				-- Only branches that exist here, so a code from a future version
				-- cannot invent one.
				if c and Ping.db.profile.Colors[entry[1]] then
					clean.colors[#clean.colors + 1] = { entry[1], entry[2], c }
				end
			end
		end
	end
	if type(src.classes) == "table" then
		for class, c in pairs(src.classes) do
			local col = sanitizeColor(c)
			if type(class) == "string" and col then clean.classes[class] = col end
		end
	end
	if type(src.settings) == "table" then
		for key, expected in pairs(ALLOWED_SETTINGS) do
			if type(src.settings[key]) == expected then
				clean.settings[key] = src.settings[key]
			end
		end
	end
	clean.artwork = type(src.artwork) == "string" and src.artwork or "legacy"

	local s = store()
	if not s then return false end
	-- Never silently overwrite: a name clash gets a suffix so the existing one
	-- survives.
	local key = PREFIX .. name
	local n = 2
	while s[key] do
		key = format("%s%s (%d)", PREFIX, name, n)
		n = n + 1
	end
	clean.name = key:sub(#PREFIX + 1)
	s[key] = clean

	Ping:Print(format(L["CustomThemeImported"], clean.name))
	return true
end
