--[[--------------------------------------------------------------------------
  Spy Glow -- marks the tracked enemy's nameplate.

  The arrow tells you which way to turn. This tells you which of the forty
  nameplates in front of you is the one you clicked, which is the harder problem
  in a mass fight.

  It hangs off the BASE nameplate frame - the one the engine owns and anchors to
  the unit in the world - not off any nameplate addon's artwork. That is what
  makes it work identically under Platynator, Plater, or no nameplate addon at
  all: those addons replace the decoration, but none of them can take the base
  frame away, because the engine is what moves it.

  The halo is drawn above whatever the nameplate addon draws, but its interior is
  nearly transparent, so the health bar underneath stays readable rather than
  being covered by a slab of colour.
----------------------------------------------------------------------------]]

local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:GetLocale("Spy")

local GLOW_TEXTURE = "Interface\\AddOns\\Spy\\Textures\\SpyGlow"

-- The texture's own aspect ratio. The art is a rounded rectangle with a soft
-- halo baked into the outer margin, so stretching it far from this ratio makes
-- the corners visibly lopsided - the defaults sit close to it on purpose.
local TEX_W, TEX_H = 256, 128

Spy.Glow = Spy.Glow or {}
local Glow = Spy.Glow

------------------------------------------------------------------------------
-- frame
------------------------------------------------------------------------------
function Spy:CreateGlowFrame()
	if Glow.frame then return end

	local f = CreateFrame("Frame", "SpyNameplateGlow", UIParent)
	f:SetSize(TEX_W / 2, TEX_H / 2)
	f:Hide()

	local tex = f:CreateTexture(nil, "OVERLAY")
	tex:SetTexture(GLOW_TEXTURE)
	tex:SetAllPoints(f)
	tex:SetBlendMode("ADD")
	f.Texture = tex

	-- Pulse, so the mark reads as "this one" even against a screen full of
	-- nameplates that are themselves moving. Driven by an animation group rather
	-- than the update tick, so its speed is independent of the refresh rate.
	local ag = f:CreateAnimationGroup()
	ag:SetLooping("BOUNCE")
	local fade = ag:CreateAnimation("Alpha")
	fade:SetFromAlpha(1)
	fade:SetToAlpha(0.35)
	fade:SetDuration(0.55)
	fade:SetSmoothing("IN_OUT")
	f.Pulse = ag
	f.PulseFade = fade

	Glow.frame = f
	Glow.plate = nil
end

------------------------------------------------------------------------------
-- settings
------------------------------------------------------------------------------
local function glowColor()
	local p = Spy.db.profile
	if p.GlowUseClassColor then
		local name = Spy.GetTrackedPlayer and Spy:GetTrackedPlayer()
		local playerData = name and SpyPerCharDB.PlayerData[name]
		local class = playerData and playerData.class
		local c = class and Spy.Colors:GetColor("Class", class)
		if c then return c.r, c.g, c.b end
	end
	local c = p.Colors["Spy"]["Glow"]
	if c then return c.r, c.g, c.b end
	return 1, 0.3, 0.25
end

function Spy:ApplyGlowSettings()
	if not Glow.frame then Spy:CreateGlowFrame() end
	local f = Glow.frame
	if not f then return end
	local p = Spy.db.profile

	f:SetWidth(p.GlowWidth or 128)
	f:SetHeight(p.GlowHeight or 64)
	f.Texture:SetVertexColor(glowColor())
	f.Texture:SetBlendMode(p.GlowAdditive == false and "BLEND" or "ADD")

	-- The pulse animates the frame's own alpha, so it would otherwise stomp on
	-- the opacity setting. Scale the animation's endpoints by the opacity
	-- instead, and only set the alpha directly when nothing is animating it.
	local alpha = p.GlowAlpha or 1
	f.Pulse:Stop()
	if p.GlowPulse == false then
		f:SetAlpha(alpha)
	else
		f.PulseFade:SetDuration(p.GlowPulseSpeed or 0.55)
		f.PulseFade:SetFromAlpha(alpha)
		f.PulseFade:SetToAlpha(alpha * (p.GlowPulseDepth or 0.35))
		if f:IsShown() then f.Pulse:Play() end
	end

	Spy:UpdateGlow()
end

------------------------------------------------------------------------------
-- per-tick update
------------------------------------------------------------------------------
-- We have to sit above whatever the nameplate addon hung on this plate, and a
-- fixed offset from the plate's own level will not do it: addons set their
-- frames' levels explicitly. Find the highest child actually present and clear
-- it. Only worth computing when we move to a new plate - by the time a plate is
-- handed to us the addon has already built its display on it.
local function topChildLevel(plate, exclude)
	local level = plate:GetFrameLevel() or 0
	local kids = { plate:GetChildren() }
	for i = 1, #kids do
		local child = kids[i]
		if child ~= exclude and child.GetFrameLevel then
			local cl = child:GetFrameLevel()
			if cl and cl > level then level = cl end
		end
	end
	return level
end

local function hideGlow()
	local f = Glow.frame
	if not f then return end
	if f:IsShown() then
		f.Pulse:Stop()
		f:Hide()
	end
	Glow.plate = nil
end

function Spy:UpdateGlow()
	-- The preview owns the frame until it is switched off, otherwise the tick
	-- would yank it back onto a nameplate mid-adjustment.
	if Glow.previewing then return end
	local p = Spy.db.profile
	if not p.GlowEnabled then
		hideGlow()
		return
	end
	if not Glow.frame then
		Spy:CreateGlowFrame()
		if not Glow.frame then return end
	end

	local name = Spy.GetTrackedPlayer and Spy:GetTrackedPlayer()
	if not name then
		hideGlow()
		return
	end

	-- No plate means we genuinely cannot say which unit on screen is theirs, so
	-- mark nothing. A glow on the wrong nameplate is worse than no glow.
	local unit, plate = Spy:FindNameplateForPlayer(name)
	if not unit or not plate then
		hideGlow()
		return
	end

	local f = Glow.frame
	if Glow.plate ~= plate then
		-- Plates are recycled between units, so re-anchor whenever ours moves.
		f:SetParent(plate)
		f:SetFrameStrata(plate:GetFrameStrata())
		f:ClearAllPoints()
		f:SetPoint("CENTER", plate, "CENTER", p.GlowOffsetX or 0, p.GlowOffsetY or 0)
		f:SetFrameLevel(topChildLevel(plate, f) + 5)
		Glow.plate = plate
	end

	f.Texture:SetVertexColor(glowColor())

	if not f:IsShown() then
		f:Show()
		if p.GlowPulse ~= false then f.Pulse:Play() end
	end
end

------------------------------------------------------------------------------
-- preview, so the size sliders can be judged without finding an enemy
------------------------------------------------------------------------------
function Spy:ToggleGlowPreview()
	if not Glow.frame then Spy:CreateGlowFrame() end
	local f = Glow.frame
	if not f then return end

	if Glow.previewing then
		Glow.previewing = nil
		hideGlow()
		Spy:UpdateGlow()
		return
	end

	Glow.previewing = true
	Glow.plate = nil
	f:SetParent(UIParent)
	f:SetFrameStrata("HIGH")
	f:ClearAllPoints()
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
	f.Texture:SetVertexColor(glowColor())
	f:Show()
	if Spy.db.profile.GlowPulse ~= false then f.Pulse:Play() end
	Spy:Print(L["GlowPreviewOn"])
end
