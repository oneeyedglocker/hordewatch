local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:GetLocale("Ping")

local function placeButton(button)
	local angle = math.rad(Ping.db.profile.MinimapButtonAngle or 225)
	local radius = 80
	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function runAction(action)
	if action == "settings" then
		Ping:ShowConfig()
	elseif action == "cycle" then
		Ping:MainWindowNextMode()
	elseif action == "enable" then
		Ping:EnablePing(not Ping.db.profile.Enabled, false)
	else
		if Ping.MainWindow:IsShown() then Ping.MainWindow:Hide() else Ping.MainWindow:Show() end
	end
end

local function actionLabel(action)
	if action == "settings" then return L["MinimapActionSettings"] end
	if action == "cycle" then return L["MinimapActionCycle"] end
	if action == "enable" then return L["MinimapActionEnable"] end
	return L["MinimapActionToggle"]
end

function Ping:UpdateMinimapButton()
	local button = Ping.MinimapButton
	if not button then return end
	local hiddenForCombat = Ping.db.profile.HideMinimapButtonInCombat and InCombatLockdown()
	if Ping.db.profile.ShowMinimapButton and not hiddenForCombat then button:Show() else button:Hide() end
	placeButton(button)
end

function Ping:CreateMinimapButton()
	if Ping.MinimapButton then Ping:UpdateMinimapButton() return end
	local button = CreateFrame("Button", "Ping_MinimapButton", Minimap)
	Ping.MinimapButton = button
	button:SetSize(32, 32)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:RegisterForDrag("LeftButton")

	local icon = button:CreateTexture(nil, "BACKGROUND")
	icon:SetTexture("Interface\\AddOns\\Ping\\Textures\\button-crosshairs.tga")
	icon:SetPoint("TOPLEFT", 7, -7)
	icon:SetPoint("BOTTOMRIGHT", -7, 7)
	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	border:SetSize(54, 54)
	border:SetPoint("TOPLEFT")
	button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	button:SetScript("OnClick", function(_, mouseButton)
		runAction(mouseButton == "RightButton" and Ping.db.profile.MinimapRightClick or Ping.db.profile.MinimapLeftClick)
	end)
	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine("Ping", 1, 0.82, 0)
		if Ping.db.profile.MinimapButtonCount then
			GameTooltip:AddLine(format(L["MinimapNearbyCount"], Ping.DisplayedCount or 0), 1, 1, 1)
		end
		GameTooltip:AddLine(L["MinimapLeft"]..": "..actionLabel(Ping.db.profile.MinimapLeftClick), .7, .7, .7)
		GameTooltip:AddLine(L["MinimapRight"]..": "..actionLabel(Ping.db.profile.MinimapRightClick), .7, .7, .7)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function() GameTooltip:Hide() end)
	button:SetScript("OnDragStart", function(self)
		if Ping.db.profile.LockMinimapButton then return end
		self:SetScript("OnUpdate", function()
			local mx, my = Minimap:GetCenter()
			local scale = Minimap:GetEffectiveScale()
			local x, y = GetCursorPosition()
			x, y = x / scale - mx, y / scale - my
			Ping.db.profile.MinimapButtonAngle = math.deg(math.atan2(y, x))
			placeButton(self)
		end)
	end)
	button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

	local events = CreateFrame("Frame")
	events:RegisterEvent("PLAYER_REGEN_DISABLED")
	events:RegisterEvent("PLAYER_REGEN_ENABLED")
	events:SetScript("OnEvent", function() Ping:UpdateMinimapButton() end)
	Ping:UpdateMinimapButton()
end
