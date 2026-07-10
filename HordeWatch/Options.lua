local HW = HordeWatch

-- Every tweakable knob lives in HW.db.profile (see Core.lua's Defaults).
-- This just exposes that table through a real AceConfig options panel
-- (Interface -> AddOns -> Horde Watch, or /hw config) instead of requiring
-- an edit to Core.lua's Defaults and a /reload to change a setting.

local function get(info)
	return HW.db.profile[info[#info]]
end

local function set(info, value)
	HW.db.profile[info[#info]] = value
end

local options = {
	type = "group",
	name = "Horde Watch",
	args = {
		general = {
			type = "group",
			name = "General",
			inline = true,
			order = 1,
			args = {
				Enabled = {
					type = "toggle",
					name = "Enabled",
					desc = "Master on/off switch. Disables all detection and guild sharing.",
					width = "full",
					order = 1,
					get = get,
					set = function(info, value)
						set(info, value)
						HW:ZoneChanged()
					end,
				},
				ShowWindow = {
					type = "toggle",
					name = "Show status window",
					desc = "Show the movable window listing recently tracked players.",
					order = 2,
					get = get,
					set = function(info, value)
						set(info, value)
						if value then HW:ShowWindow() else HW:HideWindow() end
					end,
				},
				ShareToGuild = {
					type = "toggle",
					name = "Share sightings with guild",
					desc = "Broadcast your sightings to other Horde Watch users in your guild, and accept sightings from them.",
					order = 3,
					get = get,
					set = set,
				},
				ShowMinimapIcon = {
					type = "toggle",
					name = "Show minimap icon",
					desc = "Left-click toggles the status window, right-click opens these settings.",
					order = 4,
					get = function() return not HW.db.profile.minimap.hide end,
					set = function(_, value)
						HW.db.profile.minimap.hide = not value
						local icon = LibStub("LibDBIcon-1.0")
						if value then icon:Show("HordeWatch") else icon:Hide("HordeWatch") end
					end,
				},
			},
		},

		zones = {
			type = "group",
			name = "Where It Runs",
			inline = true,
			order = 2,
			args = {
				EnabledInSanctuaries = {
					type = "toggle",
					name = "Sanctuaries",
					desc = "Track while in sanctuary zones (PvP is disabled there; off by default).",
					order = 1,
					get = get,
					set = function(info, value) set(info, value) HW:ZoneChanged() end,
				},
				EnabledInBattlegrounds = {
					type = "toggle",
					name = "Battlegrounds",
					desc = "Track while inside a battleground instance.",
					order = 2,
					get = get,
					set = function(info, value) set(info, value) HW:ZoneChanged() end,
				},
				EnabledInArenas = {
					type = "toggle",
					name = "Arenas",
					desc = "Track while inside an arena instance.",
					order = 3,
					get = get,
					set = function(info, value) set(info, value) HW:ZoneChanged() end,
				},
				EnabledInWintergrasp = {
					type = "toggle",
					name = "World PvP objective zones",
					desc = "Track while in an active world PvP objective zone (e.g. Wintergrasp).",
					order = 4,
					get = get,
					set = function(info, value) set(info, value) HW:ZoneChanged() end,
				},
				DisableWhenPVPUnflagged = {
					type = "toggle",
					name = "Pause while PvP-unflagged",
					desc = "Stop tracking whenever you yourself are not PvP-flagged.",
					order = 5,
					get = get,
					set = function(info, value) set(info, value) HW:ZoneChanged() end,
				},
				filteredZonesDesc = {
					type = "description",
					order = 6,
					name = "\nZones to always skip (one exact zone or subzone name per line):",
				},
				FilteredZonesText = {
					type = "input",
					name = "",
					order = 7,
					width = "full",
					multiline = 6,
					get = function()
						local lines = {}
						for zone in pairs(HW.db.profile.FilteredZones) do
							lines[#lines + 1] = zone
						end
						table.sort(lines)
						return table.concat(lines, "\n")
					end,
					set = function(_, text)
						wipe(HW.db.profile.FilteredZones)
						for line in text:gmatch("[^\n]+") do
							line = strtrim(line)
							if line ~= "" then
								HW.db.profile.FilteredZones[line] = true
							end
						end
						HW:ZoneChanged()
					end,
				},
			},
		},

		data = {
			type = "group",
			name = "Data & Sharing",
			inline = true,
			order = 3,
			args = {
				RetentionDays = {
					type = "range",
					name = "Keep sightings for (days)",
					desc = "Sightings older than this are pruned automatically every 5 minutes.",
					order = 1,
					min = 1, max = 90, step = 1,
					get = get,
					set = set,
				},
				MaxRecords = {
					type = "range",
					name = "Max stored sightings",
					desc = "The single oldest sighting is dropped once this many are stored, regardless of age.",
					order = 2,
					min = 1000, max = 50000, step = 1000,
					get = get,
					set = set,
				},
				CollapseWindowSeconds = {
					type = "range",
					name = "Collapse window (seconds)",
					desc = "Sightings of the same player in the same zone within this many seconds of the first one are merged into a single row instead of logged separately.",
					order = 3,
					min = 0, max = 60, step = 1,
					get = get,
					set = set,
				},
				CommRateLimitSeconds = {
					type = "range",
					name = "Guild broadcast rate limit (seconds)",
					desc = "Minimum time between broadcasting sightings of the same player to your guild.",
					order = 4,
					min = 0, max = 30, step = 1,
					get = get,
					set = set,
				},
			},
		},

		actions = {
			type = "group",
			name = "Actions",
			inline = true,
			order = 4,
			args = {
				ClearNearby = {
					type = "execute",
					name = "Clear nearby list",
					desc = "Clears the status window's current snapshot. Does not delete the historical sighting log used for trends.",
					order = 1,
					func = function() HW:ClearCurrentState() end,
				},
			},
		},
	},
}

function HW:SetupOptions()
	local AceConfig = LibStub("AceConfig-3.0")
	local AceConfigDialog = LibStub("AceConfigDialog-3.0")
	AceConfig:RegisterOptionsTable("HordeWatch", options)
	AceConfigDialog:AddToBlizOptions("HordeWatch", "Horde Watch")
end

function HW:OpenConfig()
	LibStub("AceConfigDialog-3.0"):Open("HordeWatch")
end
