--[[--------------------------------------------------------------------------
  Spy Debug -- opt-in diagnostics.

  Off by default and costs nothing when off. When enabled it records the small
  number of things that are actually hard to judge by eye:

    * env      - client build / locale / which APIs exist, so a WoW patch that
                 removes or changes something shows up immediately
    * errors   - Lua errors raised from Spy's own code
    * arrow    - arrow accuracy: computed bearing+distance against ground truth
                 taken from the real unit whenever the tracked player is
                 actually in front of us
    * levels   - guessed level vs the real level once it becomes known, which
                 is the only way to measure how wrong the guessing is
    * detect   - detection counts by method, and how often position data is
                 missing
    * notes    - whatever you type with /spy debug note <text>

  Buffers are bounded, but unlike a silent ring buffer the dump reports how
  many records were dropped so the data is never quietly incomplete.

  /spy debug            toggle on/off
  /spy debug note <t>   timestamp an observation
  /spy debug dump       open a copy box
  /spy debug reset      clear
----------------------------------------------------------------------------]]

local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:GetLocale("Spy")
local HBD = LibStub("HereBeDragons-2.0", true)

SpyDebugDB = SpyDebugDB or {}

-- Moved into the C_AddOns namespace; the bare global is gone on current clients.
local getAddOnMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata

local CAP = { errors = 60, arrow = 250, levels = 250, notes = 100 }

local Debug = {}
Spy.Debug = Debug

local function db()
	if not SpyDebugDB.started then
		SpyDebugDB.started = date("%Y-%m-%d %H:%M:%S")
		SpyDebugDB.errors, SpyDebugDB.arrow = {}, {}
		SpyDebugDB.levels, SpyDebugDB.notes = {}, {}
		SpyDebugDB.detect = { method = {}, noPosition = 0, noMapID = 0, total = 0 }
		SpyDebugDB.dropped = {}
		SpyDebugDB.zones = {}
	end
	return SpyDebugDB
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

function Spy:IsDebugging()
	return Spy.db and Spy.db.profile and Spy.db.profile.DebugMode
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
-- that is a real enemy position and the arrow becomes exact - so probe it and
-- record the answer instead of assuming.
function Spy:ProbeEnemyPositionAPIs()
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
	out.nameplateAddon = Spy.GetNameplateDriver and Spy:GetNameplateDriver() or nil
	out.nameplates = Spy:ProbeNameplates()
	db().positionProbe = out
	return out
end

-- The arrow reads the engine's base nameplate frame, not whatever a nameplate
-- addon draws on top of it. This dumps both so a bad bearing can be traced to
-- the right layer: if tokenSweep finds units but the base frames have no centre
-- or a wild scale, that is the arrow's problem; if no units turn up at all,
-- nameplates simply are not showing.
function Spy:ProbeNameplates()
	local out = {
		driver = Spy.GetNameplateDriver and Spy:GetNameplateDriver() or "unknown",
		hasGetNamePlateForUnit = (C_NamePlate and C_NamePlate.GetNamePlateForUnit) ~= nil,
		hasGetNamePlates = (C_NamePlate and C_NamePlate.GetNamePlates) ~= nil,
		uiScale = UIParent:GetEffectiveScale(),
		uiWidth = UIParent:GetWidth(),
		tokenSweep = {},
		listed = 0,
	}
	if Spy.GetMeasureStrategy then
		local how, err = Spy:GetMeasureStrategy()
		out.measureStrategy = how or "none"
		out.measureError = err
	end
	out.glowAnchorError = Spy.Glow and Spy.Glow.lastError or nil
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
					-- arrow tries actually answers, because that is the whole
					-- question when the arrow has nothing to show.
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
				if entry.name and Spy.GetLiveBearing then
					local bearing = Spy:GetLiveBearing(entry.name)
					entry.bearingDeg = bearing and math.floor(math.deg(bearing) + 0.5) or nil
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

function Spy:CaptureDebugEnvironment()
	local d = db()
	local version, build, bdate, iface = GetBuildInfo()
	d.env = {
		spyVersion = getAddOnMetadata and getAddOnMetadata("Spy", "Version") or "?",
		wow = version, build = build, buildDate = bdate, interface = iface,
		locale = GetLocale(),
		player = UnitName("player"), realm = GetRealmName(),
		class = select(2, UnitClass("player")), level = UnitLevel("player"),
		faction = UnitFactionGroup("player"),
		hbd = HBD ~= nil,
		tomtom = TomTom ~= nil,
		nameplateAddon = Spy.GetNameplateDriver and Spy:GetNameplateDriver() or nil,
		api = apiPresence(),
	}
end

------------------------------------------------------------------------------
-- Lua errors raised by Spy
------------------------------------------------------------------------------
local errorHooked = false
function Spy:HookDebugErrors()
	if errorHooked then return end
	errorHooked = true
	local previous = geterrorhandler()
	seterrorhandler(function(err)
		if Spy:IsDebugging() then
			local text = tostring(err)
			-- Matching only the message misses most of Spy's own errors, because
			-- the message describes the failed API and never mentions us. The
			-- nameplate measurement error is exactly that shape:
			-- "NamePlate3:GetCenter(): ... Can't measure restricted regions".
			-- Only the stack names Spy, so check the stack too.
			local stack = debugstack and debugstack(2, 8, 0) or ""
			if text:find("Spy", 1, true) or stack:find("Spy", 1, true) then
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
function Spy:DebugZone(mapID)
	if not Spy:IsDebugging() then return end
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
	entry.floorApplied = Spy.GetZoneLevelFloor and Spy:GetZoneLevelFloor(mapID) or nil
	d.zones[mapID] = entry
end

------------------------------------------------------------------------------
-- detection accounting
------------------------------------------------------------------------------
function Spy:DebugDetection(method, playerData)
	if not Spy:IsDebugging() then return end
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
-- Called when we read a real level off a unit. If Spy was guessing before,
-- the delta says exactly how wrong the guess was.
------------------------------------------------------------------------------
function Spy:DebugLevelCheck(name, actualLevel)
	if not Spy:IsDebugging() then return end
	if type(actualLevel) ~= "number" or actualLevel <= 0 then return end
	local playerData = SpyPerCharDB.PlayerData[name]
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
-- arrow accuracy
--
-- Ground truth is hard to come by because the client won't tell us where an
-- enemy is. But when the tracked player IS our current target we can bracket
-- the real distance with CheckInteractDistance, and compare that against what
-- the arrow computed from the stored sighting.
------------------------------------------------------------------------------
local lastArrowSample = 0

local function realRangeBand(unit)
	-- returns a coarse "actual" distance bracket in yards
	if not UnitExists(unit) then return nil end
	if CheckInteractDistance(unit, 3) then return 0, 10 end     -- duel range
	if CheckInteractDistance(unit, 2) then return 10, 11 end    -- trade
	if CheckInteractDistance(unit, 1) then return 11, 28 end    -- inspect
	if CheckInteractDistance(unit, 4) then return 11, 28 end    -- follow
	return 28, nil                                              -- further than 28
end

function Spy:DebugArrowSample(force)
	if not Spy:IsDebugging() then return end
	local name = Spy.GetTrackedPlayer and Spy:GetTrackedPlayer()
	if not name then return end
	local now = GetTime()
	if not force and (now - lastArrowSample) < 2 then return end
	lastArrowSample = now

	local angle, distance, age, isLive = Spy:GetArrowVector()
	if not angle then return end
	local liveAngle = Spy.GetLiveBearing and Spy:GetLiveBearing(name) or nil

	-- is the tracked player actually in front of us right now?
	local unit
	if UnitExists("target") and GetUnitName("target", true) == name then unit = "target"
	elseif UnitExists("mouseover") and GetUnitName("mouseover", true) == name then unit = "mouseover" end

	local lo, hi
	if unit then lo, hi = realRangeBand(unit) end

	local playerData = SpyPerCharDB.PlayerData[name]
	local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
	local px, py
	if mapID and C_Map.GetPlayerMapPosition then
		local pos = C_Map.GetPlayerMapPosition(mapID, "player")
		if pos then px, py = pos:GetXY() end
	end

	push(db().arrow, "arrow", {
		when = date("%H:%M:%S"), name = name,
		computedDist = distance and math.floor(distance * 10) / 10,
		computedAngle = math.floor(angle * 100) / 100,
		isLive = isLive or nil,
		liveAngle = liveAngle and math.floor(liveAngle * 100) / 100 or nil,
		fov = Spy.db.profile.ArrowFieldOfView,
		posFromNameplate = playerData and playerData.posFromNameplate or nil,
		facing = GetPlayerFacing() and math.floor(GetPlayerFacing() * 100) / 100,
		age = age,
		-- ground truth bracket, only present when they were actually in front of us
		realMin = lo, realMax = hi, verified = unit or nil,
		myX = px and math.floor(px * 10000) / 10000,
		myY = py and math.floor(py * 10000) / 10000,
		theirX = playerData and playerData.mapX and math.floor(playerData.mapX * 10000) / 10000,
		theirY = playerData and playerData.mapY and math.floor(playerData.mapY * 10000) / 10000,
		mapID = mapID, theirMapID = playerData and playerData.mapID,
		zone = GetZoneText(),
	})
end

------------------------------------------------------------------------------
-- notes / dump
------------------------------------------------------------------------------
function Spy:DebugNote(text)
	local d = db()
	push(d.notes, "notes", {
		when = date("%H:%M:%S"), text = text,
		zone = GetZoneText(), target = GetUnitName("target", true),
		tracking = Spy.GetTrackedPlayer and Spy:GetTrackedPlayer() or nil,
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

function Spy:ShowDebugDump()
	Spy:CaptureDebugEnvironment()
	local d = db()
	local text = "SpyDebug=" .. table.concat(serialize(d))

	local fr = Spy_DebugDumpFrame
	if not fr then
		fr = CreateFrame("Frame", "Spy_DebugDumpFrame", UIParent, "BackdropTemplate")
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
		local sc = CreateFrame("ScrollFrame", "Spy_DebugDumpScroll", fr, "UIPanelScrollFrameTemplate")
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

function Spy:ResetDebug()
	wipe(SpyDebugDB)
	db()
	Spy:CaptureDebugEnvironment()
end

function Spy:DebugStatus()
	local d = db()
	Spy:Print(format(L["DebugStatus"],
		tostring(Spy:IsDebugging()), #d.errors, #d.arrow, #d.levels, #d.notes, d.detect.total))
	local dropped = 0
	for _, n in pairs(d.dropped) do dropped = dropped + n end
	if dropped > 0 then Spy:Print(format(L["DebugDropped"], dropped)) end
end

------------------------------------------------------------------------------
-- sampling driver
------------------------------------------------------------------------------
local sampler = CreateFrame("Frame")
local acc = 0
sampler:SetScript("OnUpdate", function(_, elapsed)
	if not Spy.db or not Spy.db.profile or not Spy.db.profile.DebugMode then return end
	acc = acc + elapsed
	if acc < 1 then return end
	acc = 0
	Spy:DebugArrowSample()
end)
