--[[--------------------------------------------------------------------------
  Ping Debug -- opt-in diagnostics.

  Off by default and costs nothing when off. When enabled it records the small
  number of things that are actually hard to judge by eye:

    * env      - client build / locale / which APIs exist, so a WoW patch that
                 removes or changes something shows up immediately
    * errors   - Lua errors raised from Ping's own code
    * levels   - guessed level vs the real level once it becomes known, which
                 is the only way to measure how wrong the guessing is
    * detect   - detection counts by method, and how often position data is
                 missing
    * notes    - whatever you type with /ping debug note <text>

  Buffers are bounded, but unlike a silent ring buffer the dump reports how
  many records were dropped so the data is never quietly incomplete.

  /ping debug            toggle on/off
  /ping debug note <t>   timestamp an observation
  /ping debug dump       open a copy box
  /ping debug reset      clear
----------------------------------------------------------------------------]]

local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:GetLocale("Ping")
local HBD = LibStub("HereBeDragons-2.0", true)

PingDebugDB = PingDebugDB or {}

-- Moved into the C_AddOns namespace; the bare global is gone on current clients.
local getAddOnMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata

local CAP = { errors = 60, levels = 250, notes = 100 }

local Debug = {}
Ping.Debug = Debug

local function db()
	if not PingDebugDB.started then
		PingDebugDB.started = date("%Y-%m-%d %H:%M:%S")
		PingDebugDB.errors = {}
		PingDebugDB.levels, PingDebugDB.notes = {}, {}
		PingDebugDB.detect = { method = {}, noPosition = 0, noMapID = 0, total = 0 }
		PingDebugDB.dropped = {}
		PingDebugDB.zones = {}
	end
	return PingDebugDB
end

local function push(list, key, item)
	local d = db()
	local cap = CAP[key] or 100
	if #list >= cap then
		d.dropped[key] = (d.dropped[key] or 0) + 1
		return
	end
	list[#list + 1] = item
end

function Ping:IsDebugging()
	return Ping.db and Ping.db.profile and Ping.db.profile.DebugMode
end

------------------------------------------------------------------------------
-- environment fingerprint: catches API changes after a WoW patch
------------------------------------------------------------------------------
local function apiPresence()
	local names = {
		"C_Map.GetBestMapForUnit", "C_Map.GetPlayerMapPosition", "GetPlayerFacing",
		"UnitAura", "UnitCastingInfo", "UnitGetTotalAbsorbs", "CheckInteractDistance",
		"CombatLogGetCurrentEventInfo", "GetPlayerInfoByGUID", "UnitSpellHaste",
		"C_ChatInfo.RegisterAddonMessagePrefix", "Settings.OpenToCategory",
		"UnitIsPVPFreeForAll", "SecondsToTime", "GetSpellInfo",
	}
	local out = {}
	for _, n in ipairs(names) do
		local ok, v = pcall(function()
			local cur = _G
			for part in n:gmatch("[^%.]+") do cur = cur and cur[part] end
			return cur
		end)
		out[n] = (ok and v ~= nil) or false
	end
	return out
end

-- Decisive test: does UnitPosition actually return anything for a hostile
-- player? It exists in this client, but is documented as working for only a
-- very limited set of unit ids. If it ever returns coordinates for an enemy
-- record the answer instead of assuming.
function Ping:ProbeEnemyPositionAPIs()
	local out = { checkedAt = date("%H:%M:%S") }
	local unit
	if UnitExists("target") and UnitIsPlayer("target") and UnitCanAttack("player", "target") then
		unit = "target"
	elseif UnitExists("mouseover") and UnitIsPlayer("mouseover") and UnitCanAttack("player", "mouseover") then
		unit = "mouseover"
	end
	out.unit = unit
	if unit then
		out.name = GetUnitName(unit, true)
		if UnitPosition then
			local ok, y, x, z, inst = pcall(UnitPosition, unit)
			out.unitPosition = ok and { y = y, x = x, z = z, instance = inst } or { err = tostring(y) }
			out.unitPositionWorked = (ok and x ~= nil) or false
		end
		-- for comparison, the same call on ourselves, which is known to work
		if UnitPosition then
			local ok, y, x, z, inst = pcall(UnitPosition, "player")
			out.selfPosition = ok and { y = y, x = x, z = z, instance = inst } or nil
		end
	end
	out.canCreateLine = (UIParent.CreateLine ~= nil)
	out.nameplateEnemies = GetCVar and GetCVar("nameplateShowEnemies") or nil
	out.nameplateMaxDistance = GetCVar and GetCVar("nameplateMaxDistance") or nil
	-- Clamping pins the target's plate to the screen edge, which silently
	-- destroys the bearing for the one unit we care most about.
	out.clampTargetNameplate = GetCVar and GetCVar("clampTargetNameplateToScreen") or nil
	out.nameplateGlobalScale = GetCVar and GetCVar("nameplateGlobalScale") or nil
	out.nameplateAddon = Ping.GetNameplateDriver and Ping:GetNameplateDriver() or nil
	out.nameplates = Ping:ProbeNameplates()
	db().positionProbe = out
	return out
end

function Ping:ProbeNameplates()
	local out = {
		driver = Ping.GetNameplateDriver and Ping:GetNameplateDriver() or "unknown",
		hasGetNamePlateForUnit = (C_NamePlate and C_NamePlate.GetNamePlateForUnit) ~= nil,
		hasGetNamePlates = (C_NamePlate and C_NamePlate.GetNamePlates) ~= nil,
		uiScale = UIParent:GetEffectiveScale(),
		uiWidth = UIParent:GetWidth(),
		tokenSweep = {},
		listed = 0,
	}
	if not C_NamePlate then return out end

	if C_NamePlate.GetNamePlateForUnit then
		for i = 1, 40 do
			local unit = "nameplate"..i
			if UnitExists(unit) then
				local entry = {
					unit = unit,
					name = GetUnitName(unit, true),
					hostile = UnitCanAttack("player", unit) or false,
					isPlayer = UnitIsPlayer(unit) or false,
				}
				local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, unit)
				if ok and plate then
					entry.baseFrame = plate:GetName() or "(anonymous)"
					-- Nameplates are restricted regions: the measurement APIs
					-- can be refused outright. Record WHICH of the routes the
					-- routes answer, since that is what a nameplate-position
					-- question comes down to.
					local okc, cx = pcall(plate.GetCenter, plate)
					entry.plateCenterX = okc and cx or nil
					entry.plateMeasureError = (not okc) and tostring(cx) or nil
					local uf = plate.UnitFrame
					if uf then
						entry.unitFrameOnPlate = (uf:GetParent() == plate)
						entry.unitFrameShown = uf:IsShown() or false
						local oku, ux = pcall(uf.GetCenter, uf)
						entry.unitFrameCenterX = oku and ux or nil
					end
					local kids = { plate:GetChildren() }
					entry.childCount = #kids
					for i = 1, #kids do
						local kid = kids[i]
						if kid ~= uf and kid.IsShown and kid:IsShown() then
							local okk, kx = pcall(kid.GetCenter, kid)
							if okk and kx then
								entry.childCenterX = kx
								entry.childName = kid:GetName() or "(anonymous)"
								break
							end
						end
					end
				else
					entry.baseFrame = false
				end
				tinsert(out.tokenSweep, entry)
			end
		end
	end

	if C_NamePlate.GetNamePlates then
		local ok, plates = pcall(C_NamePlate.GetNamePlates, C_NamePlate)
		if ok and type(plates) == "table" then out.listed = #plates end
	end

	return out
end

function Ping:CaptureDebugEnvironment()
	local d = db()
	local version, build, bdate, iface = GetBuildInfo()
	d.env = {
		spyVersion = getAddOnMetadata and getAddOnMetadata("Ping", "Version") or "?",
		wow = version, build = build, buildDate = bdate, interface = iface,
		locale = GetLocale(),
		player = UnitName("player"), realm = GetRealmName(),
		class = select(2, UnitClass("player")), level = UnitLevel("player"),
		faction = UnitFactionGroup("player"),
		hbd = HBD ~= nil,
		tomtom = TomTom ~= nil,
		nameplateAddon = Ping.GetNameplateDriver and Ping:GetNameplateDriver() or nil,
		api = apiPresence(),
	}
end

------------------------------------------------------------------------------
-- Lua errors raised by Ping
------------------------------------------------------------------------------
local errorHooked = false
function Ping:HookDebugErrors()
	if errorHooked then return end
	errorHooked = true
	local previous = geterrorhandler()
	seterrorhandler(function(err)
		if Ping:IsDebugging() then
			local text = tostring(err)
			-- Matching only the message misses most of Ping's own errors, because
			-- the message describes the failed API and never mentions us. The
			-- nameplate measurement error is exactly that shape:
			-- "NamePlate3:GetCenter(): ... Can't measure restricted regions".
			-- Only the stack names Ping, so check the stack too.
			local stack = debugstack and debugstack(2, 8, 0) or ""
			if text:find("Ping", 1, true) or stack:find("Ping", 1, true) then
				push(db().errors, "errors", {
					when = date("%H:%M:%S"),
					err = text:sub(1, 400),
					stack = stack:sub(1, 500),
				})
			end
		end
		return previous(err)
	end)
end

------------------------------------------------------------------------------
-- zone identity
--
-- The level floor is keyed by UiMapID, and those ids differ between retail and
-- Classic - which is how the floor came to be keyed entirely by the wrong ones.
-- Record the real id, name and continent for every zone visited so the table can
-- be completed from evidence instead of from assumption.
------------------------------------------------------------------------------
function Ping:DebugZone(mapID)
	if not Ping:IsDebugging() then return end
	if type(mapID) ~= "number" then return end
	local d = db()
	d.zones = d.zones or {}
	if d.zones[mapID] then return end

	local entry = { mapID = mapID }
	if C_Map and C_Map.GetMapInfo then
		local ok, info = pcall(C_Map.GetMapInfo, mapID)
		if ok and info then
			entry.name = info.name
			entry.mapType = info.mapType
			entry.parent = info.parentMapID
		end
	end
	if GetInstanceInfo then
		local ok, _, _, _, _, _, _, _, instanceID = pcall(GetInstanceInfo)
		if ok then entry.instanceID = instanceID end
	end
	entry.floorApplied = Ping.GetZoneLevelFloor and Ping:GetZoneLevelFloor(mapID) or nil
	d.zones[mapID] = entry
end

------------------------------------------------------------------------------
-- detection accounting
------------------------------------------------------------------------------
function Ping:DebugDetection(method, playerData)
	if not Ping:IsDebugging() then return end
	local d = db().detect
	d.total = d.total + 1
	method = tostring(method or "?")
	d.method[method] = (d.method[method] or 0) + 1
	if playerData then
		if not playerData.mapX or not playerData.mapY then d.noPosition = d.noPosition + 1 end
		if not playerData.mapID then d.noMapID = d.noMapID + 1 end
	end
end

------------------------------------------------------------------------------
-- level guess vs reality
--
-- Called when we read a real level off a unit. If Ping was guessing before,
-- the delta says exactly how wrong the guess was.
------------------------------------------------------------------------------
function Ping:DebugLevelCheck(name, actualLevel)
	if not Ping:IsDebugging() then return end
	if type(actualLevel) ~= "number" or actualLevel <= 0 then return end
	local playerData = PingPerCharDB.PlayerData[name]
	if not playerData or playerData.isGuess ~= true then return end
	local guess = tonumber(playerData.level)
	if not guess then return end
	push(db().levels, "levels", {
		when = date("%H:%M:%S"), name = name, guess = guess, actual = actualLevel,
		delta = actualLevel - guess, zone = GetZoneText(),
		class = playerData.class,
	})
end

------------------------------------------------------------------------------
-- level guess accuracy
--
-- Ground truth is hard to come by because the client won't tell us where an
-- enemy is. But when the tracked player IS our current target we can bracket
-- the real distance with CheckInteractDistance, and compare that against what
------------------------------------------------------------------------------

local function realRangeBand(unit)
	-- returns a coarse "actual" distance bracket in yards
	if not UnitExists(unit) then return nil end
	if CheckInteractDistance(unit, 3) then return 0, 10 end     -- duel range
	if CheckInteractDistance(unit, 2) then return 10, 11 end    -- trade
	if CheckInteractDistance(unit, 1) then return 11, 28 end    -- inspect
	if CheckInteractDistance(unit, 4) then return 11, 28 end    -- follow
	return 28, nil                                              -- further than 28
end

------------------------------------------------------------------------------
-- notes / dump
------------------------------------------------------------------------------
function Ping:DebugNote(text)
	local d = db()
	push(d.notes, "notes", {
		when = date("%H:%M:%S"), text = text,
		zone = GetZoneText(), target = GetUnitName("target", true),
	})
end

local function serialize(v, indent, out, depth)
	indent = indent or ""
	out = out or {}
	depth = depth or 0
	if depth > 6 then out[#out + 1] = '"<deep>"' return out end
	if type(v) == "table" then
		out[#out + 1] = "{\n"
		local keys = {}
		for k in pairs(v) do keys[#keys + 1] = k end
		table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
		for _, k in ipairs(keys) do
			out[#out + 1] = indent .. "  ["
			out[#out + 1] = (type(k) == "string") and string.format("%q", k) or tostring(k)
			out[#out + 1] = "]="
			serialize(v[k], indent .. "  ", out, depth + 1)
			out[#out + 1] = ",\n"
		end
		out[#out + 1] = indent .. "}"
	elseif type(v) == "string" then
		out[#out + 1] = string.format("%q", v)
	else
		out[#out + 1] = tostring(v)
	end
	return out
end

function Ping:ShowDebugDump()
	Ping:CaptureDebugEnvironment()
	-- Run the position probes as part of taking a dump rather than leaving them
	-- to a separate command nobody knows to type. Two dumps arrived without this
	-- block because it had to be triggered by hand.
	if Ping.ProbeEnemyPositionAPIs then pcall(Ping.ProbeEnemyPositionAPIs, Ping) end
	local d = db()
	local text = "PingDebug=" .. table.concat(serialize(d))

	local fr = Ping_DebugDumpFrame
	if not fr then
		fr = CreateFrame("Frame", "Ping_DebugDumpFrame", UIParent, "BackdropTemplate")
		fr:SetSize(660, 470)
		fr:SetPoint("CENTER")
		fr:SetFrameStrata("DIALOG")
		fr:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true, tileSize = 32, edgeSize = 32,
			insets = { left = 11, right = 12, top = 12, bottom = 11 },
		})
		fr:SetMovable(true)
		fr:EnableMouse(true)
		fr:RegisterForDrag("LeftButton")
		fr:SetScript("OnDragStart", fr.StartMoving)
		fr:SetScript("OnDragStop", fr.StopMovingOrSizing)
		local sc = CreateFrame("ScrollFrame", "Ping_DebugDumpScroll", fr, "UIPanelScrollFrameTemplate")
		sc:SetPoint("TOPLEFT", 16, -16)
		sc:SetPoint("BOTTOMRIGHT", -36, 44)
		local eb = CreateFrame("EditBox", nil, sc)
		eb:SetMultiLine(true)
		eb:SetFontObject(ChatFontNormal)
		eb:SetWidth(596)
		eb:SetAutoFocus(false)
		eb:SetScript("OnEscapePressed", function() fr:Hide() end)
		sc:SetScrollChild(eb)
		fr.eb = eb
		local hint = fr:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		hint:SetPoint("BOTTOMLEFT", 16, 16)
		hint:SetPoint("RIGHT", -120, 0)
		hint:SetJustifyH("LEFT")
		hint:SetText(L["DebugDumpHint"])
		local cb = CreateFrame("Button", nil, fr, "UIPanelButtonTemplate")
		cb:SetSize(90, 22)
		cb:SetPoint("BOTTOMRIGHT", -16, 12)
		cb:SetText(CLOSE or "Close")
		cb:SetScript("OnClick", function() fr:Hide() end)
	end
	fr.eb:SetText(text)
	fr.eb:HighlightText()
	fr.eb:SetFocus()
	fr:Show()
end

function Ping:ResetDebug()
	wipe(PingDebugDB)
	db()
	Ping:CaptureDebugEnvironment()
end

function Ping:DebugStatus()
	local d = db()
	Ping:Print(format(L["DebugStatus"],
		tostring(Ping:IsDebugging()), #d.errors, #d.levels, #d.notes, d.detect.total))
	local dropped = 0
	for _, n in pairs(d.dropped) do dropped = dropped + n end
	if dropped > 0 then Ping:Print(format(L["DebugDropped"], dropped)) end
end

------------------------------------------------------------------------------
-- sampling driver
------------------------------------------------------------------------------
local sampler = CreateFrame("Frame")
local acc = 0
sampler:SetScript("OnUpdate", function(_, elapsed)
	if not Ping.db or not Ping.db.profile or not Ping.db.profile.DebugMode then return end
	acc = acc + elapsed
	if acc < 1 then return end
	acc = 0
end)
