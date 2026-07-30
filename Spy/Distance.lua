--[[--------------------------------------------------------------------------
  Spy Distance -- see enemies sooner.

  Two console variables decide how far away an enemy can be before the client
  stops telling you about them at all:

    nameplateMaxDistance   how far nameplates draw
    farclip                how far the world itself is drawn

  Both ship well below their maximum, and in world PvP that is the difference
  between spotting a group forming and walking into it. Spy pushes each to the
  highest value the client accepts.

  Unlike the direction arrow this cannot be blocked: writing a CVar is ordinary
  addon behaviour, not a measurement of a protected frame. The values are read
  back after writing so what the UI reports is what the client actually took,
  never what we asked for.

  Re-applied on login and on zone change, because other addons write these too -
  Platynator sets nameplateMaxDistance itself - and whoever writes last wins.
  Spy never lowers a value: if something else has already set a higher one than
  we would, that one stands.
----------------------------------------------------------------------------]]

local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:GetLocale("Spy")

Spy.Distance = Spy.Distance or {}
local Distance = Spy.Distance

-- Candidate values, highest first. The accepted maximum differs between
-- clients - and between builds of the same client - so rather than hardcode one
-- number and hope, try each and keep the first that survives a read-back.
local NAMEPLATE_STEPS = { 100, 80, 60, 41, 40 }
local FARCLIP_STEPS = { 1000, 777, 500, 300 }

local function getNumber(cvar)
	if not GetCVar then return nil end
	local ok, v = pcall(GetCVar, cvar)
	return ok and tonumber(v) or nil
end

-- Write the highest value that sticks, and return what the client settled on.
-- A CVar that rejects a value either clamps it or refuses it outright, and both
-- are visible in the read-back, so this needs no table of per-build limits.
local function raiseTo(cvar, steps)
	if not SetCVar or not GetCVar then return nil end
	if getNumber(cvar) == nil then return nil end	-- CVar absent on this client

	local best = getNumber(cvar) or 0
	local original = best

	for _, want in ipairs(steps) do
		if want > best then
			local ok = pcall(SetCVar, cvar, want)
			if ok then
				local got = getNumber(cvar)
				if got and got > best then best = got end
				if got and got >= want then break end
			end
		end
	end

	-- Never end up below where we started.
	if best < original then
		pcall(SetCVar, cvar, original)
		best = original
	end
	return best
end

function Spy:GetNameplateDistance()
	return getNumber("nameplateMaxDistance")
end

function Spy:GetViewDistance()
	return getNumber("farclip")
end

------------------------------------------------------------------------------
-- applying
------------------------------------------------------------------------------
function Spy:ApplyDistanceSettings(announce)
	if not Spy.db or not Spy.db.profile then return end
	local p = Spy.db.profile
	local plates, view

	if p.MaxNameplateDistance then
		plates = raiseTo("nameplateMaxDistance", NAMEPLATE_STEPS)
		-- Nameplates that are switched off have no distance worth setting, so
		-- turn enemy plates on as part of the same intent.
		if p.MaxNameplateDistanceShowsEnemies and SetCVar then
			pcall(SetCVar, "nameplateShowEnemies", 1)
		end
	end
	if p.MaxViewDistance then
		view = raiseTo("farclip", FARCLIP_STEPS)
	end

	Distance.lastNameplate = plates
	Distance.lastView = view

	if announce then
		if plates then Spy:Print(format(L["DistanceNameplateSet"], plates)) end
		if view then Spy:Print(format(L["DistanceViewSet"], view)) end
		if not plates and not view then Spy:Print(L["DistanceNothingToDo"]) end
	end
	return plates, view
end

-- What the client is actually using right now, for the options page to show.
function Spy:GetDistanceStatus()
	local plates = Spy:GetNameplateDistance()
	local view = Spy:GetViewDistance()
	return plates, view
end

------------------------------------------------------------------------------
-- re-apply when something else may have overwritten us
------------------------------------------------------------------------------
local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
watcher:RegisterEvent("ZONE_CHANGED_NEW_AREA")
watcher:SetScript("OnEvent", function()
	if not Spy.db or not Spy.db.profile then return end
	-- Deferred a moment: other addons apply their own CVars on these same
	-- events, and the last write is the one that counts.
	if C_Timer and C_Timer.After then
		C_Timer.After(2, function() Spy:ApplyDistanceSettings(false) end)
	else
		Spy:ApplyDistanceSettings(false)
	end
end)

------------------------------------------------------------------------------
-- which addon is drawing the nameplates
--
-- Diagnostic only, but it earned its place: it is what identified Platynator as
-- the nameplate driver on this setup, and nameplate CVars are exactly the ones
-- such an addon is likely to be fighting us over.
------------------------------------------------------------------------------
local isAddOnLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded

local NAMEPLATE_ADDONS = {
	"Platynator", "Plater", "Kui_Nameplates", "TidyPlates", "ThreatPlates",
	"NeatPlates", "ElvUI", "NamePlateSCT", "BetterBlizzPlates",
}

function Spy:GetNameplateDriver()
	if not isAddOnLoaded then return "unknown" end
	for _, addon in ipairs(NAMEPLATE_ADDONS) do
		local ok, loaded = pcall(isAddOnLoaded, addon)
		if ok and loaded then return addon end
	end
	return "Blizzard"
end
