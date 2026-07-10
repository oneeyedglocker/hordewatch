local HW = HordeWatch

local dataObject = LibStub("LibDataBroker-1.1"):NewDataObject("HordeWatch", {
	type = "launcher",
	text = "Horde Watch",
	icon = "Interface\\Icons\\INV_Misc_Spyglass_03",
	OnClick = function(_, button)
		if button == "LeftButton" then
			HW.db.profile.ShowWindow = not HW.db.profile.ShowWindow
			if HW.db.profile.ShowWindow then
				if HW.ShowWindow then HW:ShowWindow() end
			else
				if HW.HideWindow then HW:HideWindow() end
			end
		elseif button == "RightButton" then
			if HW.OpenConfig then HW:OpenConfig() end
		end
	end,
	OnTooltipShow = function(tooltip)
		local count = 0
		for _ in pairs(HW.charDB.CurrentState) do count = count + 1 end
		tooltip:AddLine("Horde Watch")
		tooltip:AddLine(("Tracked: %d"):format(count), 1, 1, 1)
		tooltip:AddLine(("Status: %s"):format(HW.EnabledInZone and "active" or "inactive"), 1, 1, 1)
		tooltip:AddLine(" ")
		tooltip:AddLine("Left-click to toggle window", 0.9, 0.8, 0.4)
		tooltip:AddLine("Right-click for settings", 0.9, 0.8, 0.4)
	end,
})

function HW:SetupMinimapIcon()
	LibStub("LibDBIcon-1.0"):Register("HordeWatch", dataObject, self.db.profile.minimap)
end
