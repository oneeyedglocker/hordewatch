local SM = LibStub:GetLibrary("LibSharedMedia-3.0")
local HBD = LibStub("HereBeDragons-2.0")
local HBDP = LibStub("HereBeDragons-Pins-2.0")
local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:GetLocale("Ping")
local fonts = SM:List("font")
local _

Ping = LibStub("AceAddon-3.0"):NewAddon("Ping", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceTimer-3.0")
Ping.Version = "2.9.2"
Ping.DatabaseVersion = "1.1"
Ping.Signature = "[Ping]"
Ping.ButtonLimit = 15
Ping.MaximumPlayerLevel = MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()]
--Ping.MaximumPlayerLevel = GetMaxLevelForLatestExpansion()
Ping.MapNoteLimit = 20
Ping.MapProximityThreshold = 0.02
Ping.CurrentMapNote = 1
Ping.ZoneID = {}
Ping.KOSGuild = {}
Ping.CurrentList = {}
Ping.NearbyList = {}
Ping.LastHourList = {}
Ping.ActiveList = {}
Ping.InactiveList = {}
Ping.PlayerCommList = {}
Ping.ListAmountDisplayed = 0
Ping.ButtonName = {}
Ping.EnabledInZone = false
-- Do not use Ping.IsEnabled for private state: AceAddon embeds IsEnabled() as a
-- method. Treating that function as a boolean made OnEnable return before any
-- detection events were registered.
Ping.RuntimeEnabled = false
Ping.InInstance = false
Ping.AlertType = nil
Ping.UpgradeMessageSent = false
Ping.zName = ""
Ping.ChnlTime = 0
Ping.Skull = -1
Ping.PetGUID = {}

-- Localizations for PingStats
L_STATS = "Ping "..L["Statistics"]
L_WON = L["Won"]
L_LOST = L["Lost"]
L_REASON = L["Reason"]
L_LIST = L["List"]
L_TIME = L["Time"]
L_FILTER = L["Filter"]..":"
L_SHOWONLY = L["Show Only"]..":"

Ping.options = {
	name = L["Ping"],
	type = "group",
	args = {
		About = {
			name = L["About"],
			desc = L["About"],
			type = "group",
			-- Reference material, not settings. AceConfigDialog sorts negative
			-- orders after positive ones, so this sits at the foot of the
			-- sidebar (just above Profiles at -2) and /ping config now opens on
			-- a page that actually has controls on it.
			order = -3,
			args = {
				intro1 = {
					name = L["PingDescription1"],
					type = "description",
					order = 1,
					fontSize = "medium",
				},	
				intro2 = {
					name = L["PingDescription2"],
					type = "description",
					order = 2,
					fontSize = "medium",
				},
				intro3 = {
					name = L["PingDescription3"],
					type = "description",
					order = 3,
					fontSize = "medium",
				},
			},
		},
		PingGroup = {
			name = L["TPagePing"],
			desc = L["TPagePing"],
			type = "group",
			order = 2,
			childGroups = "tab",
			args = {
				Zones = {
					name = L["TTabZones"],
					desc = L["TTabZones"],
					type = "group",
					order = 1,
					args = {
						EnabledInBattlegrounds = {
							name = L["EnabledInBattlegrounds"],
							desc = L["EnabledInBattlegroundsDescription"],
							type = "toggle",
							order = 1,
							width = "full",
							get = function(info)
								return Ping.db.profile.EnabledInBattlegrounds
							end,
							set = function(info, value)
								Ping.db.profile.EnabledInBattlegrounds = value
								Ping:ZoneChangedEvent()
							end,
						},
						EnabledInArenas = {
							name = L["EnabledInArenas"],
							desc = L["EnabledInArenasDescription"],
							type = "toggle",
							order = 2,
							width = "full",
							get = function(info)
								return Ping.db.profile.EnabledInArenas
							end,
							set = function(info, value)
								Ping.db.profile.EnabledInArenas = value
								Ping:ZoneChangedEvent()
							end,
						},
						EnabledInSanctuaries = {
							name = L["EnabledInSanctuaries"],
							desc = L["EnabledInSanctuariesDescription"],
							type = "toggle",
							order = 3,
							width = "full",
							get = function(info)
								return Ping.db.profile.EnabledInSanctuaries
							end,
							set = function(info, value)
								Ping.db.profile.EnabledInSanctuaries = value
								Ping:ZoneChangedEvent()
							end,
						},
						DisableWhenPVPUnflagged = {
							name = L["DisableWhenPVPUnflagged"],
							desc = L["DisableWhenPVPUnflaggedDescription"],
							type = "toggle",
							order = 4,
							width = "full",
							get = function(info)
								return Ping.db.profile.DisableWhenPVPUnflagged
							end,
							set = function(info, value)
								Ping.db.profile.DisableWhenPVPUnflagged = value
								Ping:ZoneChangedEvent()
							end,
						},
						DisabledInZones = {
							name = L["DisabledInZones"],
							desc = L["DisabledInZonesDescription"],
							type = "multiselect",
							order = 5,
							get = function(info, key) 
								return Ping.db.profile.FilteredZones[key] 
							end,
							set = function(info, key, value) 
								Ping.db.profile.FilteredZones[key] = value 
							end,
							values = {
								["Booty Bay"] = L["Booty Bay"],
								["Everlook"] = L["Everlook"],
								["Gadgetzan"] = L["Gadgetzan"],
								["Ratchet"] = L["Ratchet"],
								["The Salty Sailor Tavern"] = L["The Salty Sailor Tavern"],
								["Cenarion Hold"] = L["Cenarion Hold"],
								["Shattrath City"] = L["Shattrath City"],
								["Area 52"] = L["Area 52"],
		--						["Dalaran"] = L["Dalaran"],
		--						["Bogpaddle"] = L["Bogpaddle"],
		--						["The Vindicaar"] = L["The Vindicaar"],
		--						["Krasus' Landing"] = L["Krasus' Landing"],
		--						["The Violet Gate"] = L["The Violet Gate"],
		--						["Magni's Encampment"] = L["Magni's Encampment"],
		--						["Chamber of Heart"] = L["Chamber of Heart"],
		--						["Hall of Ancient Paths"] = L["Hall of Ancient Paths"],
		--						["Sanctum of the Sages"] = L["Sanctum of the Sages"],
		--						["Rustbolt"] = L["Rustbolt"],
		--						["Oribos"] = L["Oribos"],
		--						["Valdrakken"] = L["Valdrakken"],
		--						["The Roasted Ram"] = L["The Roasted Ram"],
		--						["Dornogal"] = L["Dornogal"],						
		--						["Stonelight Rest"] = L["Stonelight Rest"],
		--						["Delver's Headquarters"] = L["Delver's Headquarters"],
							},
						},
						ShowOnDetection = {
							name = L["ShowOnDetection"],
							desc = L["ShowOnDetectionDescription"],
							type = "toggle",
							order = 6,
							width = "full",
							get = function(info)
								return Ping.db.profile.ShowOnDetection
							end,
							set = function(info, value)
								Ping.db.profile.ShowOnDetection = value
							end,
						},
						HidePing = {
							name = L["HidePing"],
							desc = L["HidePingDescription"],
							type = "toggle",
							order = 7,
							width = "full",
							get = function(info)
								return Ping.db.profile.HidePing
							end,
							set = function(info, value)
								Ping.db.profile.HidePing = value
								if Ping.db.profile.HidePing and Ping:GetNearbyListSize() == 0 then
									Ping.MainWindow:Hide()
								end
							end,
						},
						ShowKoSButton = {
							name = L["ShowKoSButton"],
							desc = L["ShowKoSButtonDescription"],
							type = "toggle",
							order = 8,
							width = "full",
							get = function(info)
								return Ping.db.profile.ShowKoSButton
							end,
							set = function(info, value)
								Ping.db.profile.ShowKoSButton = value
							end,
						},
					},
				},
				TheList = {
					name = L["TTabList"],
					desc = L["TTabList"],
					type = "group",
					order = 2,
					args = {
						ShowNearbyList = {
							name = L["ShowNearbyList"],
							desc = L["ShowNearbyListDescription"],
							type = "toggle",
							order = 1,
							width = "full",
							get = function(info)
								return Ping.db.profile.ShowNearbyList
							end,
							set = function(info, value)
								Ping.db.profile.ShowNearbyList = value
							end,
						},
						PrioritiseKoS = {
							name = L["PrioritiseKoS"],
							desc = L["PrioritiseKoSDescription"],
							type = "toggle",
							order = 2,
							width = "full",
							get = function(info)
								return Ping.db.profile.PrioritiseKoS
							end,
							set = function(info, value)
								Ping.db.profile.PrioritiseKoS = value
							end,
						},
						ResizePing = {
							name = L["ResizePing"],
							desc = L["ResizePingDescription"],
							type = "toggle",
							order = 3,
							width = "full",
							get = function(info)
								return Ping.db.profile.ResizePing
							end,
							set = function(info, value)
								Ping.db.profile.ResizePing = value
								if value then Ping:RefreshCurrentList() end
							end,
						},
						ResizePingLimit = {  
							type = "range",
							order = 4,
							name = L["ResizePingLimit"],
							desc = L["ResizePingLimitDescription"],
							min = 1, max = 15, step = 1,
							get = function() return Ping.db.profile.ResizePingLimit end,
							set = function(info, value)
								Ping.db.profile.ResizePingLimit = value
								if value then 
									Ping:ResizeMainWindow()
									Ping:RefreshCurrentList() 
								end	
							end,
						},
						DisplayListData = {
							name = L["DisplayListData"],
							type = 'select',
							order = 5,
							values = {
								["1NameLevelClass"] = L["Name"].." / "..L["Level"].." / "..L["Class"],
								["2NameLevelGuild"] = L["Name"].." / "..L["Level"].." / "..L["Guild"],
								["3NameLevelOnly"] = L["Name"].." / "..L["Level"],
		--						["4NamePvPRank"] = L["Name"].." / "..L["Rank"], -- Classic
								["5NameGuild"] = L["Name"].." / "..L["Guild"],
								["6NameOnly"] = L["Name"],
							},
							get = function()
								return Ping.db.profile.DisplayListData
							end,
							set = function(info, value)
								Ping.db.profile.DisplayListData = value
								Ping:RefreshCurrentList() 
							end,
						},
						DisplayLastSeen = {
							name = L["TooltipDisplayLastSeen"],
							desc = L["TooltipDisplayLastSeenDescription"],
							type = "toggle",
							order = 6,
							width = "full",
							get = function(info)
								return Ping.db.profile.DisplayLastSeen
							end,
							set = function(info, value)
								Ping.db.profile.DisplayLastSeen = value
							end,
						},
						DisplayKOSReason = {
							name = L["TooltipDisplayKOSReason"],
							desc = L["TooltipDisplayKOSReasonDescription"],
							type = "toggle",
							order = 7,
							width = "full",
							get = function(info)
								return Ping.db.profile.DisplayKOSReason
							end,
							set = function(info, value)
								Ping.db.profile.DisplayKOSReason = value
							end,
						},
						DisplayWinLossStatistics = {
							name = L["TooltipDisplayWinLoss"],
							desc = L["TooltipDisplayWinLossDescription"],
							type = "toggle",
							order = 8,
							width = "full",
							get = function(info)
								return Ping.db.profile.DisplayWinLossStatistics
							end,
							set = function(info, value)
								Ping.db.profile.DisplayWinLossStatistics = value
							end,
						},
						DisplayTooltipNearPingWindow = {
							name = L["DisplayTooltipNearPingWindow"],
							desc = L["DisplayTooltipNearPingWindowDescription"],
							type = "toggle",
							order = 9,
							width = "full",
							get = function(info)
								return Ping.db.profile.DisplayTooltipNearPingWindow
							end,
							set = function(info, value)
								Ping.db.profile.DisplayTooltipNearPingWindow = value
							end,
						},
						SelectTooltipAnchor = {
							type = "select",
							order = 10,
							name = L["SelectTooltipAnchor"],
							desc = L["SelectTooltipAnchorDescription"],
							values = { 
								["ANCHOR_CURSOR"] = L["ANCHOR_CURSOR"],
								["ANCHOR_TOP"] = L["ANCHOR_TOP"],
								["ANCHOR_BOTTOM"] = L["ANCHOR_BOTTOM"],
								["ANCHOR_LEFT"] = L["ANCHOR_LEFT"],
								["ANCHOR_RIGHT"] = L["ANCHOR_RIGHT"], 
							},
							get = function()
								return Ping.db.profile.TooltipAnchor
							end,
							set = function(info, value)
								Ping.db.profile.TooltipAnchor = value
							end,
						},
					},
				},
			},
		},
		Targeting = {
			name = L["TPageTargeting"],
			desc = L["TPageTargeting"],
			type = "group",
			order = 3,
			childGroups = "tab",
			args = {
				Healers = {
					name = L["TTabHealers"],
					desc = L["TTabHealers"],
					type = "group",
					order = 1,
					args = {
						MarkHealers = {
							name = L["MarkHealers"],
							desc = L["MarkHealersDescription"],
							type = "toggle",
							order = 1,
							width = "full",
							get = function() return Ping.db.profile.MarkHealers end,
							set = function(_, value)
								Ping.db.profile.MarkHealers = value
								Ping:RefreshCurrentList()
							end,
						},
						HealerDetectBy = {
							name = L["HealerDetectBy"],
							desc = L["HealerDetectByDescription"],
							type = "select",
							order = 2,
							values = {
								["class"] = L["HealerDetectByClass"],
								["heal"] = L["HealerDetectByHeal"],
							},
							get = function() return Ping.db.profile.HealerDetectBy end,
							set = function(_, value)
								Ping.db.profile.HealerDetectBy = value
								Ping:RefreshCurrentList()
							end,
						},
						StrictHealerDetection = {
							name = L["StrictHealerDetection"],
							desc = L["StrictHealerDetectionDescription"],
							type = "toggle",
							order = 2.5,
							width = "full",
							get = function() return Ping.db.profile.StrictHealerDetection end,
							set = function(_, v)
								Ping.db.profile.StrictHealerDetection = v
								Ping:RefreshCurrentList()
							end,
						},
						HealerMinHeals = {
							name = L["HealerMinHeals"],
							desc = L["HealerMinHealsDescription"],
							type = "range",
							order = 2.7,
							min = 1, max = 6, step = 1,
							get = function() return Ping.db.profile.HealerMinHeals end,
							set = function(_, v) Ping.db.profile.HealerMinHeals = v end,
						},
						HealerMinHeal = {
							name = L["HealerMinHeal"],
							desc = L["HealerMinHealDescription"],
							type = "range",
							order = 3,
							min = 0, max = 3000, step = 50,
							disabled = function() return Ping.db.profile.HealerDetectBy ~= "heal" end,
							get = function() return Ping.db.profile.HealerMinHeal end,
							set = function(_, value) Ping.db.profile.HealerMinHeal = value end,
						},
						SortHealersToTop = {
							name = L["SortHealersToTop"],
							desc = L["SortHealersToTopDescription"],
							type = "toggle",
							order = 7,
							width = "full",
							get = function() return Ping.db.profile.SortHealersToTop end,
							set = function(_, value)
								Ping.db.profile.SortHealersToTop = value
								Ping:RefreshCurrentList()
							end,
						},
						HealerGreenEdge = {
							name = L["HealerGreenEdge"],
							desc = L["HealerGreenEdgeDescription"],
							type = "toggle",
							order = 8,
							get = function() return Ping.db.profile.HealerGreenEdge end,
							set = function(_, value)
								Ping.db.profile.HealerGreenEdge = value
								Ping:RefreshCurrentList()
							end,
						},
						HealerEdgeColor = {
							name = L["HealerEdgeColor"],
							type = "color",
							order = 9,
							hasAlpha = true,
							get = function()
								local c = Ping.db.profile.Colors["Ping"]["Healer Edge"]
								return c.r, c.g, c.b, c.a
							end,
							set = function(_, r, g, b, a)
								local c = Ping.db.profile.Colors["Ping"]["Healer Edge"]
								c.r, c.g, c.b, c.a = r, g, b, a
								Ping:RefreshCurrentList()
							end,
						},
						DimNonHealers = {
							name = L["DimNonHealers"],
							desc = L["DimNonHealersDescription"],
							type = "toggle",
							order = 10,
							width = "full",
							get = function() return Ping.db.profile.DimNonHealers end,
							set = function(_, value)
								Ping.db.profile.DimNonHealers = value
								Ping:RefreshCurrentList()
							end,
						},
						listHeader = {
							name = L["HealerSpellListHeader"],
							type = "header",
							order = 20,
						},
						healerListIntro = {
							name = L["HealerSpellListIntro"],
							type = "description",
							order = 21,
							fontSize = "medium",
						},
						HealerSpellList = {
							name = L["HealerSpellList"],
							desc = L["HealerSpellListDescription"],
							type = "input",
							dialogControl = "PingSpellList",
							multiline = 10,
							width = "full",
							order = 22,
							disabled = function() return Ping.db.profile.StrictHealerDetection == false end,
							get = function()
								-- Seed on first read, so the box never appears empty
								-- while 24 spells are quietly being matched.
								if not Ping.db.profile.HealerSpellListSeeded then
									Ping:BuildHealerSpellNames()
								end
								return Ping.db.profile.HealerSpellListText
							end,
							set = function(_, v)
								Ping.db.profile.HealerSpellListText = v
								Ping.db.profile.HealerSpellListSeeded = true
								Ping:BuildHealerSpellNames()
								Ping:RefreshCurrentList()
							end,
						},
						healerListStatus = {
							name = function()
								return format(L["HealerSpellListStatus"], Ping.HealerSpellCount or 0)
							end,
							type = "description",
							order = 23,
						},
						healerListReset = {
							name = L["HealerSpellListReset"],
							desc = L["HealerSpellListResetDescription"],
							type = "execute",
							order = 24,
							func = function() Ping:ResetHealerSpellList() Ping:RefreshCurrentList() end,
						},
					},
				},
				BigFights = {
					name = L["TTabBigFights"],
					desc = L["TTabBigFights"],
					type = "group",
					order = 2,
					args = {
						massDesc = {
							name = L["MassFightsDescription"],
							type = "description",
							order = 1,
						},
						HealerOnlyFilter = {
							name = L["HealerOnlyFilter"],
							desc = L["HealerOnlyFilterDescription"],
							type = "toggle",
							order = 2,
							width = "full",
							get = function() return Ping.db.profile.HealerOnlyFilter end,
							set = function(_, value)
								Ping.db.profile.HealerOnlyFilter = value
								Ping:UpdateWindowTitle()
								Ping:RefreshCurrentList()
							end,
						},
						KillPriorityOrder = {
							name = L["KillPriorityOrder"],
							desc = L["KillPriorityOrderDescription"],
							type = "toggle",
							order = 3,
							width = "full",
							get = function() return Ping.db.profile.KillPriorityOrder end,
							set = function(_, value)
								Ping.db.profile.KillPriorityOrder = value
								Ping:RefreshCurrentList()
							end,
						},
						ShowAggregateHeader = {
							name = L["ShowAggregateHeader"],
							desc = L["ShowAggregateHeaderDescription"],
							type = "toggle",
							order = 4,
							width = "full",
							get = function() return Ping.db.profile.ShowAggregateHeader end,
							set = function(_, value)
								Ping.db.profile.ShowAggregateHeader = value
								Ping:UpdateActiveCount()
							end,
						},
						UseZoneLevelFloor = {
							name = L["UseZoneLevelFloor"],
							desc = L["UseZoneLevelFloorDescription"],
							type = "toggle",
							order = 5,
							width = "full",
							get = function() return Ping.db.profile.UseZoneLevelFloor end,
							set = function(_, value)
								Ping.db.profile.UseZoneLevelFloor = value
								Ping:RefreshCurrentList()
							end,
						},
						focusHeader = {
							name = L["FocusClassHeader"],
							type = "header",
							order = 10,
						},
						focusIntro = {
							name = L["FocusClassIntro"],
							type = "description",
							order = 11,
							fontSize = "medium",
						},
						FocusClassMode = {
							name = L["FocusClassMode"],
							desc = L["FocusClassModeDescription"],
							type = "select",
							order = 12,
							values = {
								["off"]  = L["FocusClassOff"],
								["sort"] = L["FocusClassSort"],
								["only"] = L["FocusClassOnly"],
							},
							get = function() return Ping.db.profile.FocusClassMode end,
							set = function(_, v)
								Ping.db.profile.FocusClassMode = v
								Ping:RefreshCurrentList()
							end,
						},
						FocusClasses = {
							name = L["FocusClasses"],
							desc = L["FocusClassesDescription"],
							type = "multiselect",
							order = 13,
							disabled = function() return Ping.db.profile.FocusClassMode == "off" end,
							values = function()
								-- Driven by the client's own class list rather than a second
								-- hardcoded one, so it cannot drift out of step with detection.
								local t = {}
								for class in pairs(Ping.ValidClasses or {}) do
									t[class] = L[class] or class
								end
								return t
							end,
							get = function(_, class) return Ping.db.profile.FocusClasses[class] == true end,
							set = function(_, class, value)
								Ping.db.profile.FocusClasses[class] = value or nil
								Ping:RefreshCurrentList()
							end,
						},
					},
				},
				Cooldowns = {
					name = L["TTabCooldowns"],
					desc = L["TTabCooldowns"],
					type = "group",
					order = 3,
					args = {
						TrackCooldowns = {
							name = L["TrackCooldowns"],
							desc = L["TrackCooldownsDescription"],
							type = "toggle",
							order = 1,
							width = "full",
							get = function() return Ping.db.profile.TrackCooldowns end,
							set = function(_, value)
								Ping.db.profile.TrackCooldowns = value
								Ping:RefreshCurrentList()
							end,
						},
						AnnounceCooldowns = {
							name = L["AnnounceCooldowns"],
							desc = L["AnnounceCooldownsDescription"],
							type = "toggle",
							order = 2,
							width = "full",
							disabled = function() return not Ping.db.profile.TrackCooldowns end,
							get = function() return Ping.db.profile.AnnounceCooldowns end,
							set = function(_, value) Ping.db.profile.AnnounceCooldowns = value end,
						},
						CooldownColor = {
							name = L["CooldownColor"],
							type = "color",
							order = 3,
							hasAlpha = false,
							disabled = function() return not Ping.db.profile.TrackCooldowns end,
							get = function()
								local c = Ping.db.profile.Colors["Ping"]["Cooldown"]
								return c.r, c.g, c.b
							end,
							set = function(_, r, g, b)
								local c = Ping.db.profile.Colors["Ping"]["Cooldown"]
								c.r, c.g, c.b = r, g, b
								Ping:RefreshCurrentList()
							end,
						},
						cdListHeader = {
							name = L["CooldownListHeader"],
							type = "header",
							order = 10,
						},
						cdListIntro = {
							name = L["CooldownListIntro"],
							type = "description",
							order = 11,
							fontSize = "medium",
						},
						CooldownListText = {
							name = L["CooldownList"],
							desc = L["CooldownListDescription"],
							type = "input",
							-- Rows rather than raw text. The value is still the same
							-- newline-separated list, so BuildCooldownLookup and the
							-- transfer code are unaffected; if the widget is missing
							-- AceConfigDialog falls back to the multiline box.
							dialogControl = "PingSpellList",
							multiline = 12,
							width = "full",
							order = 12,
							disabled = function() return not Ping.db.profile.TrackCooldowns end,
							get = function()
								-- Seed on first read so the box is never shown empty while
								-- ten spells are quietly being tracked.
								if not Ping.db.profile.CooldownListSeeded then
									Ping:BuildCooldownLookup()
								end
								return Ping.db.profile.CooldownListText
							end,
							set = function(_, v)
								Ping.db.profile.CooldownListText = v
								Ping.db.profile.CooldownListSeeded = true
								Ping:BuildCooldownLookup()
							end,
						},
						cdListStatus = {
							name = function()
								local total = 0
								for _ in pairs(Ping.CooldownLookup or {}) do total = total + 1 end
								if (Ping.CooldownListUnresolved or 0) > 0 then
									return format(L["CooldownListStatusWithWarning"], total,
										Ping.CooldownListUnresolved)
								end
								return format(L["CooldownListStatus"], total)
							end,
							type = "description",
							order = 13,
						},
						cdListReset = {
							name = L["CooldownListReset"],
							desc = L["CooldownListResetDescription"],
							type = "execute",
							order = 14,
							func = function() Ping:ResetCooldownList() end,
						},
					},
				},
			},
		},
		Finding = {
			name = L["TPageFinding"],
			desc = L["TPageFinding"],
			type = "group",
			order = 4,
			childGroups = "tab",
			args = {
				DistanceTab = {
					name = L["TTabDistance"],
					desc = L["TTabDistance"],
					type = "group",
					order = 1,
					args = {
						intro = {
							name = L["DistanceIntro"],
							type = "description",
							order = 1,
							fontSize = "medium",
						},
						NameplateDistanceMode = {
							name = L["NameplateDistanceMode"],
							desc = L["NameplateDistanceModeDescription"],
							type = "select",
							order = 2,
							values = {
								["max"] = L["DistanceModeMax"],
								["custom"] = L["DistanceModeCustom"],
								["off"] = L["DistanceModeOff"],
							},
							get = function() return Ping.db.profile.NameplateDistanceMode end,
							set = function(_, v)
								Ping.db.profile.NameplateDistanceMode = v
								Ping:ApplyDistanceSettings(true)
							end,
						},
						NameplateDistanceValue = {
							name = L["NameplateDistanceValue"],
							desc = L["NameplateDistanceValueDescription"],
							type = "range",
							order = 3,
							min = 20, max = 100, step = 5,
							disabled = function() return Ping.db.profile.NameplateDistanceMode ~= "custom" end,
							get = function() return Ping.db.profile.NameplateDistanceValue end,
							set = function(_, v)
								Ping.db.profile.NameplateDistanceValue = v
								Ping:ApplyDistanceSettings(false)
							end,
						},
						MaxNameplateDistanceShowsEnemies = {
							name = L["MaxNameplateShowEnemies"],
							desc = L["MaxNameplateShowEnemiesDescription"],
							type = "toggle",
							order = 4,
							width = "full",
							disabled = function() return Ping.db.profile.NameplateDistanceMode == "off" end,
							get = function() return Ping.db.profile.MaxNameplateDistanceShowsEnemies end,
							set = function(_, v)
								Ping.db.profile.MaxNameplateDistanceShowsEnemies = v
								if v then Ping:ApplyDistanceSettings(true) end
							end,
						},
						viewHeader = {
							name = L["DistanceViewHeader"],
							type = "header",
							order = 5,
						},
						ViewDistanceMode = {
							name = L["ViewDistanceMode"],
							desc = L["ViewDistanceModeDescription"],
							type = "select",
							order = 6,
							values = {
								["max"] = L["DistanceModeMax"],
								["custom"] = L["DistanceModeCustom"],
								["off"] = L["DistanceModeOff"],
							},
							get = function() return Ping.db.profile.ViewDistanceMode end,
							set = function(_, v)
								Ping.db.profile.ViewDistanceMode = v
								Ping:ApplyDistanceSettings(true)
							end,
						},
						ViewDistanceValue = {
							name = L["ViewDistanceValue"],
							desc = L["ViewDistanceValueDescription"],
							type = "range",
							order = 7,
							min = 100, max = 1000, step = 25,
							disabled = function() return Ping.db.profile.ViewDistanceMode ~= "custom" end,
							get = function() return Ping.db.profile.ViewDistanceValue end,
							set = function(_, v)
								Ping.db.profile.ViewDistanceValue = v
								Ping:ApplyDistanceSettings(false)
							end,
						},
						status = {
							name = function()
								local plates, view = Ping:GetDistanceStatus()
								return format(L["DistanceStatus"],
									plates and tostring(plates) or "?",
									view and tostring(view) or "?")
							end,
							type = "description",
							order = 10,
						},
						ceilings = {
							name = function()
								local np = Ping:GetNameplateCeiling()
								local fc = Ping:GetViewCeiling()
								return format(L["DistanceCeilings"],
									np and tostring(np) or "?",
									fc and tostring(fc) or "?")
							end,
							type = "description",
							order = 11,
						},
						apply = {
							name = L["DistanceApplyNow"],
							desc = L["DistanceApplyNowDescription"],
							type = "execute",
							order = 12,
							func = function() Ping:ApplyDistanceSettings(true) end,
						},
					},
				},
				MapTab = {
					name = L["TTabMap"],
					desc = L["TTabMap"],
					type = "group",
					order = 2,
					args = {
						MinimapDetection = {
							name = L["MinimapDetection"],
							desc = L["MinimapDetectionDescription"],
							type = "toggle",
							order = 1,
							width = "full",
							get = function(info)
								return Ping.db.profile.MinimapDetection
							end,
							set = function(info, value)
								Ping.db.profile.MinimapDetection = value
							end,
						},
						MinimapNote = {
							order = 2,
							type = "description",
							name = L["MinimapNote"],
						},
						MinimapDetails = {
							name = L["MinimapDetails"],
							desc = L["MinimapDetailsDescription"],
							type = "toggle",
							order = 3,
							width = "full",
							get = function(info)
								return Ping.db.profile.MinimapDetails
							end,
							set = function(info, value)
								Ping.db.profile.MinimapDetails = value
							end,
						},
						DisplayOnMap = {
							name = L["DisplayOnMap"],
							desc = L["DisplayOnMapDescription"],
							type = "toggle",
							order = 4,
							width = "full",
							get = function(info)
								return Ping.db.profile.DisplayOnMap
							end,
							set = function(info, value)
								Ping.db.profile.DisplayOnMap = value
							end,
						},
						TomTomOnAltClick = {
							name = L["TomTomOnAltClick"],
							desc = L["TomTomOnAltClickDescription"],
							type = "toggle",
							order = 4.5,
							width = "full",
							-- Greyed out rather than hidden when TomTom is absent, so
							-- the feature is discoverable by someone deciding whether
							-- to install TomTom at all.
							disabled = function() return not Ping:HasTomTom() end,
							get = function() return Ping.db.profile.TomTomOnAltClick end,
							set = function(_, value)
								Ping.db.profile.TomTomOnAltClick = value
							end,
						},
						SwitchToZone = {
							name = L["SwitchToZone"],
							desc = L["SwitchToZoneDescription"],
							type = "toggle",
							order = 5,
							width = "full",
							get = function(info)
								return Ping.db.profile.SwitchToZone
							end,
							set = function(info, value)
								Ping.db.profile.SwitchToZone = value
							end,
						},
						MapDisplayLimit = {
							name = L["MapDisplayLimit"],
							type = "group",
							order = 6,
							inline = true,
							args = {
								SameZone = {
									name = L["LimitSameZone"],
									desc = L["LimitSameZoneDescription"],
									type = "toggle",
									order = 1,
									width = "full",
									get = function(info)
										return Ping.db.profile.MapDisplayLimit == "SameZone"
									end,
									set = function(info, value)
										Ping.db.profile.MapDisplayLimit = "SameZone"
									end,
								},
								SameContinent = {
									name = L["LimitSameContinent"],
									desc = L["LimitSameContinentDescription"],
									type = "toggle",
									order = 2,
									width = "full",
									get = function(info)
										return Ping.db.profile.MapDisplayLimit == "SameContinent"
									end,
									set = function(info, value)
										Ping.db.profile.MapDisplayLimit = "SameContinent"
									end,
								},
								None = {
									name = L["LimitNone"],
									desc = L["LimitNoneDescription"],
									type = "toggle",
									order = 3,
									width = "full",
									get = function(info)
										return Ping.db.profile.MapDisplayLimit == "None"
									end,
									set = function(info, value)
										Ping.db.profile.MapDisplayLimit = "None"
									end,
								},
							},
						},
					},
				},
			},
		},
			Look = {
			name = L["TPageLook"],
			desc = L["TPageLook"],
			type = "group",
			order = 5,
				args = {
					Rows = {
					name = L["TTabRows"],
					desc = L["TTabRows"],
					type = "group",
						order = 2,
						inline = true,
					args = {
						LookPreset = {
							name = L["LookPreset"],
							desc = L["LookPresetDescription"],
							type = "select",
							order = 1,
							values = {
								["classbars"] = L["LookClassBars"],
								["flat"] = L["LookFlat"],
								["compact"] = L["LookCompact"],
							},
							get = function() return Ping.db.profile.LookPreset end,
							set = function(_, value)
								Ping:ApplyLookPreset(value)
							end,
						},
						ClassColoredNames = {
							name = L["ClassColoredNames"],
							desc = L["ClassColoredNamesDescription"],
							type = "toggle",
							order = 2,
							width = "full",
							get = function() return Ping.db.profile.ClassColoredNames end,
							set = function(_, value)
								Ping.db.profile.ClassColoredNames = value
								Ping:RefreshCurrentList()
							end,
						},
						SelectFont = {
							type = "select",
							order = 3,
							name = L["SelectFont"],
							desc = L["SelectFontDescription"],
							values = fonts,
							get = function()
								for info, value in next, fonts do
									if value == Ping.db.profile.Font then
										return info
									end
								end
							end,
							set = function(_, value)
								Ping.db.profile.Font = fonts[value]
								if value then
									Ping:UpdateBarTextures()
								end
							end,
						},
						RowHeight = {
							type = "range",
							order = 4,
							name = L["RowHeight"], 
							desc = L["RowHeightDescription"], 
							min = 8, max = 20, step = 1,
							get = function()
								return Ping.db.profile.MainWindow.RowHeight
							end,
							set = function(info, value)
								Ping.db.profile.MainWindow.RowHeight = value
								if value then
									Ping:BarsChanged()
								end
							end,
						},
						BarTexture = {
							type = "select",
							order = 5,
							name = L["Texture"],
							desc = L["TextureDescription"],	
							dialogControl = "LSM30_Statusbar",
							width = "double",
							values = SM:HashTable("statusbar"),
							get = function()
								return Ping.db.profile.BarTexture
							end,
							set = function(_, key)
								Ping.db.profile.BarTexture = key
								Ping:UpdateBarTextures()
							end,
						},
						BarOpacity = {
							name = L["BarOpacity"],
							desc = L["BarOpacityDescription"],
							type = "range",
							order = 6,
							min = 0, max = 1, step = 0.05,
							isPercent = true,
							get = function() return Ping.db.profile.BarOpacity end,
							set = function(_, value)
								Ping.db.profile.BarOpacity = value
								Ping:RefreshCurrentList()
							end,
						},
						KoSEdgeColor = {
							name = L["KoSEdgeColor"],
							desc = L["KoSEdgeColorDescription"],
							type = "color",
							order = 7,
							hasAlpha = true,
							get = function()
								local c = Ping.db.profile.Colors["Ping"]["KoS Edge"]
								return c.r, c.g, c.b, c.a
							end,
							set = function(_, r, g, b, a)
								local c = Ping.db.profile.Colors["Ping"]["KoS Edge"]
								c.r, c.g, c.b, c.a = r, g, b, a
								Ping:RefreshCurrentList()
							end,
						},
					},
				},
					WindowTab = {
					name = L["TTabWindow"],
					desc = L["TTabWindow"],
					type = "group",
						order = 1,
						inline = true,
					args = {
						themeHeader = {
							name = L["LookThemeHeader"],
							type = "header",
							order = 0,
						},
							LookTheme = {
							name = L["LookTheme"],
							desc = L["LookThemeDescription"],
							type = "select",
							order = 0.5,
							width = "double",
							values = function()
								local t = {}
								for key, theme in pairs(Ping.LookThemes) do t[key] = theme.name end
								t[Ping.LookThemeSeparator] = "————————————"
								return t
							end,
							-- Explicit order, so the color-only themes come first and
							-- the artwork ones sit below the separator. Without this
							-- AceConfig sorts the labels alphabetically and the two
							-- kinds interleave.
							sorting = function() return Ping.LookThemeOrder end,
							get = function() return Ping.db.profile.LookTheme end,
							set = function(_, v) Ping:ApplyLookTheme(v) end,
						},
						LockFont = {
							name = L["LockFont"],
							desc = L["LockFontDescription"],
							type = "toggle",
							order = 0.7,
							width = "full",
							get = function() return Ping.db.profile.LockFont end,
							set = function(_, value) Ping.db.profile.LockFont = value end,
						},
						RevertLookTheme = {
							name = L["ThemeRevert"],
							desc = L["ThemeRevertDescription"],
							type = "execute",
							order = 0.6,
							disabled = function() return not Ping:CanRevertLookTheme() end,
							func = function() Ping:RevertLookTheme() end,
						},
						LockPosition = {
							name = L["LockPosition"],
							desc = L["LockPositionDescription"],
							type = "toggle",
							order = 1,
							get = function() return Ping.db.profile.LockPosition end,
							set = function(_, value)
								Ping.db.profile.LockPosition = value
								Ping:ApplyWindowLocks()
							end,
						},
						LockSize = {
							name = L["LockSize"],
							desc = L["LockSizeDescription"],
							type = "toggle",
							order = 2,
							get = function() return Ping.db.profile.LockSize end,
							set = function(_, value)
								Ping.db.profile.LockSize = value
								Ping:ApplyWindowLocks()
							end,
						},
						Lock = {
							name = L["LockPing"],
							desc = L["LockPingDescription"],
							type = "toggle",
							order = 3,
							width = 1.6,
							get = function(info) 
								return Ping.db.profile.Locked
							end,
							set = function(info, value)
								Ping.db.profile.Locked = value
								Ping:LockWindows(value)
								Ping:RefreshCurrentList()
							end,
						},
						ClampToScreen = {
							name = L["ClampToScreen"],
							desc = L["ClampToScreenDescription"],
							type = "toggle",
							order = 4,
		--					width = "double",
							get = function(info) 
								return Ping.db.profile.ClampToScreen
							end,
							set = function(info, value)
								Ping.db.profile.ClampToScreen = value
								Ping:ClampToScreen(value)
							end,
						},
						InvertPing = {
							name = L["InvertPing"],
							desc = L["InvertPingDescription"],
							type = "toggle",
							order = 5,
							get = function(info)
								return Ping.db.profile.InvertPing
							end,
							set = function(info, value)
								Ping.db.profile.InvertPing = value
							end,
						},
						WindowScale = {
							name = L["WindowScale"],
							desc = L["WindowScaleDescription"],
							type = "range",
							order = 6,
							min = 0.5, max = 2, step = 0.05,
							isPercent = true,
							get = function() return Ping.db.profile.WindowScale end,
							set = function(_, value)
								Ping.db.profile.WindowScale = value
								Ping:ApplyWindowStyle()
							end,
						},
						ShowBackground = {
							name = L["ShowBackground"],
							desc = L["ShowBackgroundDescription"],
							type = "toggle",
							order = 7,
							get = function() return Ping.db.profile.ShowBackground end,
							set = function(_, value)
								Ping.db.profile.ShowBackground = value
								Ping:ApplyWindowStyle()
							end,
						},
						BackgroundOpacity = {
							name = L["BackgroundOpacity"],
							desc = L["BackgroundOpacityDescription"],
							type = "range",
							order = 8,
							min = 0, max = 1, step = 0.05,
							isPercent = true,
							get = function() return Ping.db.profile.BackgroundOpacity end,
							set = function(_, value)
								Ping.db.profile.BackgroundOpacity = value
								Ping:ApplyWindowStyle()
							end,
						},
						Alpha = {
							name = L["Alpha"],
							desc = L["AlphaDescription"],
							type = "range",
							order = 9,
		--					width = "double",
							min = 0, max = 1, step = 0.01,
							isPercent = true,
							get = function()
								return Ping.db.profile.MainWindow.Alpha end,
							set = function(info, value)
								Ping.db.profile.MainWindow.Alpha = value
								Ping:UpdateMainWindow()

							end,
						},
						AlphaBG = {
							name = L["AlphaBG"],
							desc = L["AlphaBGDescription"],
							type = "range",
							order = 10,
		--					width = "double",
							min = 0, max = 1, step = 0.01,
							isPercent = true,
							get = function()
								return Ping.db.profile.MainWindow.AlphaBG end,
							set = function(info, value)
								Ping.db.profile.MainWindow.AlphaBG = value
								Ping:UpdateMainWindow()
							end,
						},
						ChromeColors = {
							name = L["ChromeColors"], type = "group", inline = true, order = 10.5,
							args = {
								IconColor = { name = L["IconColor"], type = "color", order = 1,
									get = function() local c=Ping.db.profile.Colors.Ping.Icon return c.r,c.g,c.b end,
									set = function(_,r,g,b) Ping.Colors:SetColor("Ping","Icon",{r=r,g=g,b=b,a=1}) Ping:ApplyThemeChrome() end },
								NavigationColor = { name = L["NavigationColor"], type = "color", order = 2,
									get = function() local c=Ping.db.profile.Colors.Ping.Navigation return c.r,c.g,c.b end,
									set = function(_,r,g,b) Ping.Colors:SetColor("Ping","Navigation",{r=r,g=g,b=b,a=1}) Ping:ApplyThemeChrome() end },
								CountColor = { name = L["CountColor"], type = "color", order = 3,
									get = function() local c=Ping.db.profile.Colors.Ping.Count return c.r,c.g,c.b end,
									set = function(_,r,g,b) Ping.Colors:SetColor("Ping","Count",{r=r,g=g,b=b,a=1}) Ping:ApplyThemeChrome() end },
								CloseColor = { name = L["CloseColor"], type = "color", order = 4,
									get = function() local c=Ping.db.profile.Colors.Ping.Close return c.r,c.g,c.b end,
									set = function(_,r,g,b) Ping.Colors:SetColor("Ping","Close",{r=r,g=g,b=b,a=1}) Ping:ApplyThemeChrome() end },
							},
						},
						TitleBarStyle = {
							name = L["TitleBarStyle"],
							desc = L["TitleBarStyleDescription"],
							type = "select",
							order = 11,
							values = {
								["classic"] = L["TitleBarClassic"],
								["solid"] = L["TitleBarSolid"],
							},
							get = function() return Ping.db.profile.TitleBarStyle end,
							set = function(_, value)
								Ping.db.profile.TitleBarStyle = value
								Ping:ApplyWindowStyle()
							end,
						},
						TitleBarColor = {
							name = L["TitleBarColor"],
							desc = L["TitleBarColorDescription"],
							type = "color",
							order = 12,
							hasAlpha = false,
							disabled = function() return Ping.db.profile.TitleBarStyle ~= "solid" end,
							get = function()
								local c = Ping.db.profile.Colors["Ping"]["Title Bar"]
								return c.r, c.g, c.b
							end,
							set = function(_, r, g, b)
								local c = Ping.db.profile.Colors["Ping"]["Title Bar"]
								c.r, c.g, c.b = r, g, b
								Ping:ApplyWindowStyle()
							end,
						},
						TitleBarOpacity = {
							name = L["TitleBarOpacity"],
							desc = L["TitleBarOpacityDescription"],
							type = "range",
							order = 13,
							min = 0, max = 1, step = 0.05,
							isPercent = true,
							disabled = function() return Ping.db.profile.TitleBarStyle ~= "solid" end,
							get = function() return Ping.db.profile.TitleBarOpacity end,
							set = function(_, value)
								Ping.db.profile.TitleBarOpacity = value
								Ping:ApplyWindowStyle()
							end,
						},
						TitleTextColor = {
							name = L["TitleTextColor"],
							desc = L["TitleTextColorDescription"],
							type = "color",
							order = 13.5,
							hasAlpha = true,
							-- Written through Colors:SetColor, not straight into the
							-- table: the title is a REGISTERED font, so it is painted
							-- once at creation and only repaints when the color system
							-- is told. A direct table write changes the saved value and
							-- nothing on screen until a reload.
							get = function()
								local c = Ping.Colors:GetColor("Window", "Title Text")
								return c.r, c.g, c.b, c.a or 1
							end,
							set = function(_, r, g, b, a)
								Ping.Colors:SetColor("Window", "Title Text",
									{ r = r, g = g, b = b, a = a })
							end,
						},
						ShowBorder = {
							name = L["ShowBorder"],
							desc = L["ShowBorderDescription"],
							type = "toggle",
							order = 14,
							get = function() return Ping.db.profile.ShowBorder end,
							set = function(_, value)
								Ping.db.profile.ShowBorder = value
								Ping:ApplyWindowStyle()
							end,
						},
						WindowBorderColor = {
							name = L["WindowBorderColor"],
							type = "color",
							order = 15,
							hasAlpha = true,
							get = function()
								local c = Ping.db.profile.Colors["Ping"]["Window Border"]
								return c.r, c.g, c.b, c.a
							end,
							set = function(_, r, g, b, a)
								local c = Ping.db.profile.Colors["Ping"]["Window Border"]
								c.r, c.g, c.b, c.a = r, g, b, a
								Ping:ApplyWindowStyle()
							end,
						},
					},
				},
			},
		},
		Alerts = {
			name = L["TPageAlerts"],
			desc = L["TPageAlerts"],
			type = "group",
			order = 6,
			childGroups = "tab",
			args = {
				Sound = {
					name = L["TTabSound"],
					desc = L["TTabSound"],
					type = "group",
					order = 1,
					args = {
						EnableSound = {
							name = L["EnableSound"],
							desc = L["EnableSoundDescription"],
							type = "toggle",
							order = 1,
							width = "full",
							get = function(info)
								return Ping.db.profile.EnableSound
							end,
							set = function(info, value)
								Ping.db.profile.EnableSound = value
							end,
						},
						SoundChannel = {
							name = L["SoundChannel"],
							type = 'select',
							order = 2,
							values = {
								["Master"] = L["Master"],
								["SFX"] = L["SFX"],
								["Music"] = L["Music"],
								["Ambience"] = L["Ambience"],
							},					
							get = function()
								return Ping.db.profile.SoundChannel
							end,
							set = function(info, value)
								Ping.db.profile.SoundChannel = value 
							end,
						},
						OnlySoundKoS = {
							name = L["OnlySoundKoS"],
							desc = L["OnlySoundKoSDescription"],
							type = "toggle",
							order = 3,
							width = "full",
							get = function(info)
								return Ping.db.profile.OnlySoundKoS
							end,
							set = function(info, value)
								Ping.db.profile.OnlySoundKoS = value
							end,
						},
						StopAlertsOnTaxi = {
							name = L["StopAlertsOnTaxi"],
							desc = L["StopAlertsOnTaxiDescription"],
							type = "toggle",
							order = 4,
							width = "full",
							get = function(info)
								return Ping.db.profile.StopAlertsOnTaxi
							end,
							set = function(info, value)
								Ping.db.profile.StopAlertsOnTaxi = value
							end,
						},
					},
				},
				Warnings = {
					name = L["TTabWarnings"],
					desc = L["TTabWarnings"],
					type = "group",
					order = 2,
					args = {
						-- Throttles an ALERT, so it belongs with the other alert
						-- controls rather than under Targeting's cooldown tracking,
						-- which is about enemy defensive cooldowns and unrelated.
						KOSGuildAlertCooldown = {
							name = L["KOSGuildAlertCooldown"],
							desc = L["KOSGuildAlertCooldownDescription"],
							type = "range",
							order = 0,
							width = "full",
							min = 0, max = 120, step = 5,
							get = function() return Ping.db.profile.KOSGuildAlertCooldown end,
							set = function(_, value) Ping.db.profile.KOSGuildAlertCooldown = value end,
						},
						Announce = {
							name = L["Announce"],
							type = "group",
							order = 1,
							inline = true,
							args = {
								None = {
									name = L["None"],
									desc = L["NoneDescription"],
									type = "toggle",
									order = 1,
									get = function(info)
										return Ping.db.profile.Announce == "None"
									end,
									set = function(info, value)
										Ping.db.profile.Announce = "None"
									end,
								},
								Self = {
									name = L["Self"],
									desc = L["SelfDescription"],
									type = "toggle",
									order = 2,
									get = function(info)
										return Ping.db.profile.Announce == "Self"
									end,
									set = function(info, value)
										Ping.db.profile.Announce = "Self"
									end,
								},
								Party = {
									name = L["Party"],
									desc = L["PartyDescription"],
									type = "toggle",
									order = 3,
									get = function(info)
										return Ping.db.profile.Announce == "Party"
									end,
									set = function(info, value)
										Ping.db.profile.Announce = "Party"
									end,
								},
								Guild = {
									name = L["Guild"],
									desc = L["GuildDescription"],
									type = "toggle",
									order = 4,
									get = function(info)
										return Ping.db.profile.Announce == "Guild"
									end,
									set = function(info, value)
										Ping.db.profile.Announce = "Guild"
									end,
								},
								Raid = {
									name = L["Raid"],
									desc = L["RaidDescription"],
									type = "toggle",
									order = 5,
									get = function(info)
										return Ping.db.profile.Announce == "Raid"
									end,
									set = function(info, value)
										Ping.db.profile.Announce = "Raid"
									end,
								},
							},
						},
						OnlyAnnounceKoS = {
							name = L["OnlyAnnounceKoS"],
							desc = L["OnlyAnnounceKoSDescription"],
							type = "toggle",
							order = 2,
							width = "full",
							get = function(info)
								return Ping.db.profile.OnlyAnnounceKoS
							end,
							set = function(info, value)
								Ping.db.profile.OnlyAnnounceKoS = value
							end,
						},
						DisplayWarnings = {
							name = L["DisplayWarnings"],
							type = 'select',
							order = 3,
							values = {
								["Default"] = L["Default"],
								["ErrorFrame"] = L["ErrorFrame"],
								["Moveable"] = L["Moveable"],
							},
							get = function()
								return Ping.db.profile.DisplayWarnings
							end,
							set = function(info, value)
								Ping.db.profile.DisplayWarnings = value
								Ping:UpdateAlertWindow()
							end,
						},
						WarnOnStealth = {
							name = L["WarnOnStealth"],
							desc = L["WarnOnStealthDescription"],
							type = "toggle",
							order = 4,
							width = "full",
							get = function(info)
								return Ping.db.profile.WarnOnStealth
							end,
							set = function(info, value)
								Ping.db.profile.WarnOnStealth = value
							end,
						},
						WarnOnKOS = {
							name = L["WarnOnKOS"],
							desc = L["WarnOnKOSDescription"],
							type = "toggle",
							order = 5,
							width = "full",
							get = function(info)
								return Ping.db.profile.WarnOnKOS
							end,
							set = function(info, value)
								Ping.db.profile.WarnOnKOS = value
							end,
						},
						WarnOnKOSGuild = {
							name = L["WarnOnKOSGuild"],
							desc = L["WarnOnKOSGuildDescription"],
							type = "toggle",
							order = 6,
							width = "full",
							get = function(info)
								return Ping.db.profile.WarnOnKOSGuild
							end,
							set = function(info, value)
								Ping.db.profile.WarnOnKOSGuild = value
							end,
						},
						WarnOnRace = {
							name = L["WarnOnRace"],
							desc = L["WarnOnRaceDescription"],
							type = "toggle",
							order = 7,
							width = "full",
							get = function(info)
								return Ping.db.profile.WarnOnRace
							end,
							set = function(info, value)
								Ping.db.profile.WarnOnRace = value
							end,
						},
						SelectWarnRace = {
							type = "select",
							order = 8,
							name = L["SelectWarnRace"],
							desc = L["SelectWarnRaceDescription"],
							get = function()
								return Ping.db.profile.SelectWarnRace
							end,
							set = function(info, value)
								Ping.db.profile.SelectWarnRace = value
							end,
							values = function()
								local raceOptions = {}
								local races = {
									Alliance = {
										["None"] = L["None"],
										["Human"] = L["Human"],
										["Dwarf"] = L["Dwarf"],
										["Night Elf"] = L["Night Elf"],
										["Gnome"] = L["Gnome"],
										["Draenei"] = L["Draenei"],
		--								["Worgen"] = L["Worgen"],
		--								["Pandaren"] = L["Pandaren"],
		--								["Lightforged Draenei"] = L["Lightforged Draenei"],
		--								["Void Elf"] = L["Void Elf"],
		--								["Dark Iron Dwarf"] = L["Dark Iron Dwarf"],
		--								["Kul Tiran"] = L["Kul Tiran"],
		--								["Mechagnome"] = L["Mechagnome"],
		--								["Dracthyr"] = L["Dracthyr"],
		--								["Earthen"] = L["Earthen"],
									},
									Horde = {
										["None"] = L["None"],
										["Orc"] = L["Orc"],
										["Tauren"] = L["Tauren"],
										["Troll"] = L["Troll"],
										["Undead"] = L["Undead"],
										["Blood Elf"] = L["Blood Elf"],
		--								["Goblin"] = L["Goblin"],
		--								["Pandaren"] = L["Pandaren"],
		--								["Highmountain Tauren"] = L["Highmountain Tauren"],
		--								["Nightborne"] = L["Nightborne"],
		--								["Mag'har Orc"] = L["Mag'har Orc"],
		--								["Zandalari Troll"] = L["Zandalari Troll"],
		--								["Vulpera"] = L["Vulpera"],
		--								["Dracthyr"] = L["Dracthyr"],
		--								["Earthen"] = L["Earthen"],
									},
								}
								if Ping.EnemyFactionName == "Alliance" then
									raceOptions = races.Alliance
								end	
								if Ping.EnemyFactionName == "Horde" then
									raceOptions = races.Horde
								end	
								return raceOptions
							end,
						},
						WarnRaceNote = {
							order = 9,
							type = "description",
							name = L["WarnRaceNote"],
						},
					},
				},
			},
		},
			MinimapButton = {
				name = L["MinimapButtonPage"],
				desc = L["MinimapButtonDescription"],
				type = "group",
				order = 6,
				args = {
					ShowMinimapButton = {
						name = L["ShowMinimapButton"], type = "toggle", order = 1, width = "full",
						get = function() return Ping.db.profile.ShowMinimapButton end,
						set = function(_, v) Ping.db.profile.ShowMinimapButton = v Ping:UpdateMinimapButton() end,
					},
					LockMinimapButton = {
						name = L["LockMinimapButton"], type = "toggle", order = 2, width = "full",
						get = function() return Ping.db.profile.LockMinimapButton end,
						set = function(_, v) Ping.db.profile.LockMinimapButton = v end,
					},
					HideMinimapButtonInCombat = {
						name = L["HideMinimapButtonInCombat"], type = "toggle", order = 3, width = "full",
						get = function() return Ping.db.profile.HideMinimapButtonInCombat end,
						set = function(_, v) Ping.db.profile.HideMinimapButtonInCombat = v Ping:UpdateMinimapButton() end,
					},
					LeftClick = {
						name = L["MinimapLeftClick"], type = "select", order = 4,
						values = { toggle = L["MinimapActionToggle"], settings = L["MinimapActionSettings"], cycle = L["MinimapActionCycle"] },
						get = function() return Ping.db.profile.MinimapLeftClick end,
						set = function(_, v) Ping.db.profile.MinimapLeftClick = v end,
					},
					RightClick = {
						name = L["MinimapRightClick"], type = "select", order = 5,
						values = { settings = L["MinimapActionSettings"], toggle = L["MinimapActionToggle"], enable = L["MinimapActionEnable"] },
						get = function() return Ping.db.profile.MinimapRightClick end,
						set = function(_, v) Ping.db.profile.MinimapRightClick = v end,
					},
					MinimapButtonCount = {
						name = L["MinimapButtonCount"], type = "toggle", order = 6, width = "full",
						get = function() return Ping.db.profile.MinimapButtonCount end,
						set = function(_, v) Ping.db.profile.MinimapButtonCount = v end,
					},
				},
			},
			Data = {
			name = L["TPageData"],
			desc = L["TPageData"],
			type = "group",
				order = 7,
			childGroups = "tab",
			args = {
				Storage = {
					name = L["TTabStorage"],
					desc = L["TTabStorage"],
					type = "group",
					order = 1,
					args = {
						RemoveUndetected = {
							name = L["RemoveUndetected"],
							type = "group",
							order = 1,
							inline = true,
							args = {
								OneMinute = {
									name = L["1Min"],
									desc = L["1MinDescription"],
									type = "toggle",
									order = 1,
									get = function(info)
										return Ping.db.profile.RemoveUndetected == "OneMinute"
									end,
									set = function(info, value)
										Ping.db.profile.RemoveUndetected = "OneMinute"
										Ping:UpdateTimeoutSettings()
									end,
								},
								TwoMinutes = {
									name = L["2Min"],
									desc = L["2MinDescription"],
									type = "toggle",
									order = 2,
									get = function(info)
										return Ping.db.profile.RemoveUndetected == "TwoMinutes"
									end,
									set = function(info, value)
										Ping.db.profile.RemoveUndetected = "TwoMinutes"
										Ping:UpdateTimeoutSettings()
									end,
								},
								FiveMinutes = {
									name = L["5Min"],
									desc = L["5MinDescription"],
									type = "toggle",
									order = 3,
									get = function(info)
										return Ping.db.profile.RemoveUndetected == "FiveMinutes"
									end,
									set = function(info, value)
										Ping.db.profile.RemoveUndetected = "FiveMinutes"
										Ping:UpdateTimeoutSettings()
									end,
								},
								TenMinutes = {
									name = L["10Min"],
									desc = L["10MinDescription"],
									type = "toggle",
									order = 4,
									get = function(info)
										return Ping.db.profile.RemoveUndetected == "TenMinutes"
									end,
									set = function(info, value)
										Ping.db.profile.RemoveUndetected = "TenMinutes"
										Ping:UpdateTimeoutSettings()
									end,
								},
								FifteenMinutes = {
									name = L["15Min"],
									desc = L["15MinDescription"],
									type = "toggle",
									order = 5,
									get = function(info)
										return Ping.db.profile.RemoveUndetected == "FifteenMinutes"
									end,
									set = function(info, value)
										Ping.db.profile.RemoveUndetected = "FifteenMinutes"
										Ping:UpdateTimeoutSettings()
									end,
								},
								Never = {
									name = L["Never"],
									desc = L["NeverDescription"],
									type = "toggle",
									order = 6,
									get = function(info)
										return Ping.db.profile.RemoveUndetected == "Never"
									end,
									set = function(info, value)
										Ping.db.profile.RemoveUndetected = "Never"
										Ping:UpdateTimeoutSettings()
									end,
								},
							},
						},
						PurgeData = {
							name = L["PurgeData"],
							type = "group",
							order = 2,
							inline = true,
							args = {
								OneDay = {
									name = L["OneDay"],
									desc = L["OneDayDescription"],
									type = "toggle",
									order = 1,
									get = function(info)
										return Ping.db.profile.PurgeData == "OneDay"
									end,
									set = function(info, value)
										Ping.db.profile.PurgeData = "OneDay"
									end,
								},
								FiveDays = {
									name = L["FiveDays"],
									desc = L["FiveDaysDescription"],
									type = "toggle",
									order = 2,
									get = function(info)
										return Ping.db.profile.PurgeData == "FiveDays"
									end,
									set = function(info, value)
										Ping.db.profile.PurgeData = "FiveDays"
									end,
								},
								TenDays = {
									name = L["TenDays"],
									desc = L["TenDaysDescription"],
									type = "toggle",
									order = 3,
									get = function(info)
										return Ping.db.profile.PurgeData == "TenDays"
									end,
									set = function(info, value)
										Ping.db.profile.PurgeData = "TenDays"
									end,
								},
								ThirtyDays = {
									name = L["ThirtyDays"],
									desc = L["ThirtyDaysDescription"],
									type = "toggle",
									order = 4,
									get = function(info)
										return Ping.db.profile.PurgeData == "ThirtyDays"
									end,
									set = function(info, value)
										Ping.db.profile.PurgeData = "ThirtyDays"
									end,
								},
								SixtyDays = {
									name = L["SixtyDays"],
									desc = L["SixtyDaysDescription"],
									type = "toggle",
									order = 5,
									get = function(info)
										return Ping.db.profile.PurgeData == "SixtyDays"
									end,
									set = function(info, value)
										Ping.db.profile.PurgeData = "SixtyDays"
									end,
								},
								NinetyDays = {
									name = L["NinetyDays"],
									desc = L["NinetyDaysDescription"],
									type = "toggle",
									order = 6,
									get = function(info)
										return Ping.db.profile.PurgeData == "NinetyDays"
									end,
									set = function(info, value)
										Ping.db.profile.PurgeData = "NinetyDays"
									end,
								},
							},
						},
						PurgeKoS = {
							name = L["PurgeKoS"],
							desc = L["PurgeKoSDescription"],
							type = "toggle",
							order = 3,
							width = "full",
							get = function(info)
								return Ping.db.profile.PurgeKoS
							end,
							set = function(info, value)
								Ping.db.profile.PurgeKoS = value
							end,
						},
						PurgeWinLossData = {
							name = L["PurgeWinLossData"],
							desc = L["PurgeWinLossDataDescription"],
							type = "toggle",
							order = 4,
							width = "full",
							get = function(info)
								return Ping.db.profile.PurgeWinLossData
							end,
							set = function(info, value)
								Ping.db.profile.PurgeWinLossData = value
							end,
						},
					},
				},
					Sharing = {
					name = L["TTabSharing"],
					desc = L["TTabSharing"],
					type = "group",
					order = 2,
					args = {
						ShareData = {
							name = L["ShareData"],
							desc = L["ShareDataDescription"],
							type = "toggle",
							order = 1,
							width = "full",
							get = function(info)
								return Ping.db.profile.ShareData
							end,
							set = function(info, value)
								Ping.db.profile.ShareData = value
							end,
						},
						UseData = {
							name = L["UseData"],
							desc = L["UseDataDescription"],
							type = "toggle",
							order = 2,
							width = "full",
							get = function(info)
								return Ping.db.profile.UseData
							end,
							set = function(info, value)
								Ping.db.profile.UseData = value
							end,
						},
						ShareKOSBetweenCharacters = {
							name = L["ShareKOSBetweenCharacters"],
							desc = L["ShareKOSBetweenCharactersDescription"],
							type = "toggle",
							order = 3,
							width = "full",
							get = function(info)
								return Ping.db.profile.ShareKOSBetweenCharacters
							end,
							set = function(info, value)
								Ping.db.profile.ShareKOSBetweenCharacters = value
								if value then
									Ping:RegenerateKOSCentralList()
								end
							end,
						},
					},
					},
					SpyImport = {
						name = L["TTabSpyImport"],
						desc = L["TTabSpyImport"],
						type = "group",
						order = 3,
						args = {
							intro = {
								name = L["SpyImportDescription"],
								type = "description",
								order = 1,
								fontSize = "medium",
							},
							status = {
								name = function() return Ping:GetSpyImportStatus() end,
								type = "description",
								order = 2,
							},
							all = {
								name = L["SpyImportAll"],
								desc = L["SpyImportAllDescription"],
								type = "execute",
								order = 3,
								disabled = function() return type(_G.SpyPerCharDB) ~= "table" end,
								func = function() Ping:ImportSpyData(false) end,
							},
							kos = {
								name = L["SpyImportKOS"],
								desc = L["SpyImportKOSDescription"],
								type = "execute",
								order = 4,
								disabled = function() return type(_G.SpyPerCharDB) ~= "table" end,
								func = function() Ping:ImportSpyData(true) end,
							},
						},
					},
					Transfer = {
						name = L["TTabTransfer"],
						desc = L["TransferDescription"],
						type = "group",
						order = 4,
						args = {
							intro = { name = L["TransferDescription"], type = "description", order = 1, fontSize = "medium" },
							lists = {
								name = L["TransferLists"], type = "toggle", order = 2,
								get = function() return Ping:GetTransferScope("lists") end,
								set = function(_, v) Ping:SetTransferScope("lists", v) end,
							},
							spells = {
								name = L["TransferSpells"], type = "toggle", order = 3,
								get = function() return Ping:GetTransferScope("spells") end,
								set = function(_, v) Ping:SetTransferScope("spells", v) end,
							},
							appearance = {
								name = L["TransferAppearance"], type = "toggle", order = 4,
								get = function() return Ping:GetTransferScope("appearance") end,
								set = function(_, v) Ping:SetTransferScope("appearance", v) end,
							},
							generate = {
								name = L["TransferGenerate"], desc = L["TransferGenerateDescription"],
								type = "execute", order = 5, func = function() Ping:GenerateTransferCode() end,
							},
							apply = {
								name = L["TransferApply"], desc = L["TransferApplyDescription"],
								type = "execute", order = 6,
								confirm = function() return L["TransferConfirm"] end,
								func = function() Ping:ApplyTransferCode() end,
							},
							code = {
								name = L["TransferCode"], desc = L["TransferCodeDescription"],
								type = "input", multiline = 14, width = "full", order = 7,
								get = function() return Ping:GetTransferText() end,
								set = function(_, v) Ping:SetTransferText(v) end,
							},
							status = {
								name = function() return Ping:GetTransferStatus() end,
								type = "description", order = 8,
							},
						},
						},
						History = {
							name = L["TTabHistory"],
							desc = L["HistoryDescription"],
							type = "group",
							order = 5,
							args = {
								intro = { name = L["HistoryDescription"], type = "description", order = 1, fontSize = "medium" },
								count = {
									name = function() return format(L["HistoryCount"], Ping:GetEncounterHistoryCount()) end,
									type = "description", order = 2,
								},
								clear = {
									name = L["HistoryClear"], desc = L["HistoryClearDescription"],
									type = "execute", order = 3,
									confirm = function() return L["HistoryClearConfirm"] end,
									func = function() Ping:ClearEncounterHistory() end,
								},
								log = {
									name = L["HistoryLog"], desc = L["HistoryLogDescription"],
									type = "input", multiline = 20, width = "full", order = 4,
									get = function() return Ping:GetEncounterHistoryText() end,
									set = function() end,
								},
							},
						},
					DiagnosticsTab = {
					name = L["TTabDiagnostics"],
					desc = L["TTabDiagnostics"],
					type = "group",
						order = 6,
					args = {
						intro = {
							name = L["DebugModeDescription"],
							type = "description",
							order = 1,
							fontSize = "medium",
						},
						DebugMode = {
							name = L["DebugMode"],
							desc = L["DebugModeDescription"],
							type = "toggle",
							order = 2,
							width = "full",
							get = function() return Ping.db.profile.DebugMode end,
							set = function(_, v)
								Ping.db.profile.DebugMode = v
								if v then Ping:CaptureDebugEnvironment() end
							end,
						},
						DebugDump = {
							name = L["DebugDumpButton"],
							desc = L["DebugDumpButtonDescription"],
							type = "execute",
							order = 3,
							func = function() Ping:ShowDebugDump() end,
						},
						DebugStatus = {
							name = L["DebugStatusButton"],
							desc = L["DebugStatusButtonDescription"],
							type = "execute",
							order = 4,
							func = function() Ping:DebugStatus() end,
						},
						DebugReset = {
							name = L["DebugResetButton"],
							type = "execute",
							order = 5,
							func = function() Ping:ResetDebug() Ping:Print(L["DebugWasReset"]) end,
						},
					},
				},
			},
		},
},
}

Ping.optionsSlash = {
	name = L["SlashCommand"],
	order = -3,
	type = "group",
	args = {
		intro = {
			name = L["PingSlashDescription"],
			type = "description",
			order = 1,
			cmdHidden = true,
		},
		debug = {
			name = "debug",
			desc = L["DebugSlashDescription"],
			type = "input",
			order = 1.5,
			dialogHidden = true,
			usage = "<on|off|note <text>|dump|reset|status>",
			get = function() return "" end,
			set = function(_, val)
				val = strtrim(val or "")
				local cmd, rest = val:match("^(%S*)%s*(.-)$")
				cmd = (cmd or ""):lower()
				if cmd == "on" or (cmd == "" and not Ping.db.profile.DebugMode) then
					Ping.db.profile.DebugMode = true
					Ping:CaptureDebugEnvironment()
					Ping:Print(L["DebugOn"])
				elseif cmd == "off" or cmd == "" then
					Ping.db.profile.DebugMode = false
					Ping:Print(L["DebugOff"])
				elseif cmd == "note" then
					Ping:DebugNote(rest)
					Ping:Print(L["DebugNoted"])
				elseif cmd == "dump" then
					Ping:ShowDebugDump()
				elseif cmd == "reset" then
					Ping:ResetDebug()
					Ping:Print(L["DebugWasReset"])
				elseif cmd == "status" then
					Ping:DebugStatus()
				else
					Ping:Print(L["DebugUsage"])
				end
			end,
		},
		show = {
			name = L["Show"],
			desc = L["ShowDescription"],
			type = 'execute',
			order = 2,
			func = function()
				Ping:EnablePing(true, true)
			end,
			dialogHidden = true
		},
		hide = {
			name = L["Hide"],
			desc = L["HideDescription"],
			type = 'execute',
			order = 3,
			func = function()
				Ping:EnablePing(false, true)
			end,
			dialogHidden = true
		},		
		reset = {
			name = L["Reset"],
			desc = L["ResetDescription"],
			type = 'execute',
			order = 4,
			func = function()
				Ping:ResetPositions()
			end,
			dialogHidden = true
		},
		clear = {
			name = L["ClearSlash"],
			desc = L["ClearSlashDescription"],
			type = 'execute',
			order = 5,
			func = function()
				Ping:ClearList()
			end,
			dialogHidden = true
		},			
		config = {
			name = L["Config"],
			desc = L["ConfigDescription"],
			type = 'execute',
			order = 6,
			func = function()
				Ping:ShowConfig()
			end,
			dialogHidden = true
		},
		kos = {
			name = L["KOS"],
			desc = L["KOSDescription"],
			type = 'input',
			order = 7,
			pattern = ".",	-- Changed so names with special characters can be added
			set = function(info, value)
				if Ping_IgnoreList[value] or strmatch(value, "[%s%d]+") then
					DEFAULT_CHAT_FRAME:AddMessage(value .. " - " .. L["InvalidInput"])
				else
					Ping:ToggleKOSPlayer(not PingPerCharDB.KOSData[value], value)
				end	
			end,
			dialogHidden = true
		}, 
		ignore = {
			name = L["Ignore"],
			desc = L["IgnoreDescription"],
			type = 'input',
			order = 8,
			pattern = ".",
			set = function(info, value)
				if Ping_IgnoreList[value] or strmatch(value, "[%s%d]+") then
					DEFAULT_CHAT_FRAME:AddMessage(value .. " - " .. L["InvalidInput"])
				else
					Ping:ToggleIgnorePlayer(not PingPerCharDB.IgnoreData[value], value)
				end
			end,
			dialogHidden = true
		},
		stats = {
			name = L["Statistics"],
			desc = L["StatsDescription"],
			type = 'execute',
			order = 9,
			func = function()
				PingStats:Toggle()
			end,
			dialogHidden = true
		},
		test = {
			name = L["Test"],
			desc = L["TestDescription"],
			type = 'execute',
			order = 10,
			func = function()
				Ping:AlertStealthPlayer("Bazzalan")
			end
		},
		sanc = {
			name = L["Sanctuary"],
			desc = L["SanctuaryDescription"],
			type = 'execute',
			order = 11,
			func = function()
				Ping.db.profile.EnabledInSanctuaries = not Ping.db.profile.EnabledInSanctuaries
				Ping:ZoneChangedEvent()
	--			Ping:UpdateMainWindow()
	--			Ping:EnablePing(false, true)
			end,
			dialogHidden = true
		},
	},
}

local Default_Profile = {
	profile = {
		Colors = {
			["Window"] = {
				["Title"] = { r = 1, g = 1, b = 1, a = 1 },
				["Background"]= { r = 24/255, g = 24/255, b = 24/255, a = 1 },
				["Title Text"] = { r = 1, g = 1, b = 1, a = 1 },
			},
			["Other Windows"] = {
				["Title"] = { r = 1, g = 0, b = 0, a = 1 },
				["Background"]= { r = 24/255, g = 24/255, b = 24/255, a = 1 },
				["Title Text"] = { r = 1, g = 1, b = 1, a = 1 },
			},
			["Bar"] = {
				["Bar Text"] = { r = 1, g = 1, b = 1 },
			},
			["Warning"] = {
				["Warning Text"] = { r = 1, g = 1, b = 1 },
			},
			["Tooltip"] = {
				["Title Text"] = { r = 0.8, g = 0.3, b = 0.22 },
				["Details Text"] = { r = 1, g = 1, b = 1 },
				["Location Text"] = { r = 1, g = 0.82, b = 0 },
				["Reason Text"] = { r = 1, g = 0, b = 0 },
			},
			["Alert"] = {
				["Background"]= { r = 0, g = 0, b = 0, a = 0.4 },
				["Icon"] = { r = 1, g = 1, b = 1, a = 0.5 },
				["KOS Border"] = { r = 1, g = 0, b = 0, a = 0.4 },
				["KOS Text"] = { r = 1, g = 0, b = 0 },
				["KOS Guild Border"] = { r = 1, g = 0.82, b = 0, a = 0.4 },
				["KOS Guild Text"] = { r = 1, g = 0.82, b = 0 },
				["Stealth Border"] = { r = 0.6, g = 0.2, b = 1, a = 0.4 },
				["Stealth Text"] = { r = 0.6, g = 0.2, b = 1 },
				["Away Border"] = { r = 0, g = 1, b = 0, a = 0.4 },
				["Away Text"] = { r = 0, g = 1, b = 0 },
				["Location Text"] = { r = 1, g = 0.82, b = 0 },
				["Name Text"] = { r = 1, g = 1, b = 1 },
			},
			["Class"] = {
				["HUNTER"] = { r = 0.67, g = 0.83, b = 0.45, a = 0.6 },
				["WARLOCK"] = { r = 0.53, g = 0.53, b = 0.93, a = 0.6 },
				["PRIEST"] = { r = 1.00, g = 1.00, b = 1.00, a = 0.6 },
				["PALADIN"] = { r = 0.96, g = 0.55, b = 0.73, a = 0.6 },
				["MAGE"] = { r = 0.25, g = 0.78, b = 0.92, a = 0.6 },
				["ROGUE"] = { r = 1.00, g = 0.96, b = 0.41, a = 0.6 },
				["DRUID"] = { r = 1.00, g = 0.49, b = 0.04, a = 0.6 },
				["SHAMAN"] = { r = 0.00, g = 0.44, b = 0.87, a = 0.6 },
				["WARRIOR"] = { r = 0.78, g = 0.61, b = 0.43, a = 0.6 },
--				["DEATHKNIGHT"] = { r = 0.77, g = 0.12, b = 0.23, a = 0.6 },
--				["MONK"] = { r = 0.00, g = 1.00, b = 0.60, a = 0.6 },
--				["DEMONHUNTER"] = { r = 0.64, g = 0.19, b = 0.79, a = 0.6 },
--				["EVOKER"] = { r = 0.20, g = 0.58, b = 0.50, a = 0.6 },
				["PET"] = { r = 0.09, g = 0.61, b = 0.55, a = 0.6 },
				["MOB"] = { r = 0.58, g = 0.24, b = 0.63, a = 0.6 },
				["UNKNOWN"] = { r = 0.1, g = 0.1, b = 0.1, a = 0.6 },
				["HOSTILE"] = { r = 0.7, g = 0.1, b = 0.1, a = 0.6 },
				["UNGROUPED"] = { r = 0.63, g = 0.58, b = 0.24, a = 0.6 },
			},
			-- Target-picker (healer marking / window styling) colors.
			["Ping"] = {
				["Healer Marker"] = { r = 79/255, g = 226/255, b = 122/255, a = 1 },
				["Healer Edge"] = { r = 79/255, g = 226/255, b = 122/255, a = 1 },
				["KoS Edge"] = { r = 1, g = 0, b = 0, a = 1 },
				["Window Border"] = { r = 1, g = 1, b = 1, a = 1 },
				["Title Bar"] = { r = 13/255, g = 11/255, b = 10/255, a = 1 },
					["Cooldown"] = { r = 1, g = 0.82, b = 0, a = 1 },
					["Icon"] = { r = 0.85, g = 0.85, b = 0.85, a = 1 },
					["Navigation"] = { r = 0.3, g = 0.7, b = 1, a = 1 },
					["Count"] = { r = 0, g = 0.44, b = 0.87, a = 1 },
					["Close"] = { r = 1, g = 0.2, b = 0.2, a = 1 },
			},
		},
		MainWindow={
			Alpha=1,
			AlphaBG=1,
			Buttons={
				ClearButton=true,
				LeftButton=true,
				RightButton=true,
			},
			RowHeight=14,
			RowSpacing=2,
			TextHeight=12,
			AutoHide=true,
			BarText={
				RankNum = true,
				PerSec = true,
				Percent = true,
				NumFormat = 1,
			},
			Position={
				x = 4,
				y = 740,
				w = 160,
				h = 34,
			},
		},
		AlertWindow={
			Position={
--				x = 0,
--				y = -140,
				x = 750,
				y = 750,
			},
			NameSize=14,
			LocationSize=10,
		},
		BarTexture="Flat",
		MainWindowVis=true,
		ShowMinimapButton=true,
		LockMinimapButton=true,
		HideMinimapButtonInCombat=false,
		MinimapButtonAngle=225,
		MinimapLeftClick="toggle",
		MinimapRightClick="settings",
		MinimapButtonCount=true,
		CurrentList=1,
		Locked=false,

		-- ===== Target-picker enhancements =====
		-- Rows / look
			LookPreset="classbars",		-- classbars | flat | compact
			LookTheme="classic",
		LockFont=false,		-- when true a theme may not change the font		-- which color bundle WindowTab's Theme picker last applied
			ArtworkStyle="legacy",		-- legacy or one of the full generated-artwork themes
		ClassColoredNames=false,	-- color the name text by class (flat look)
		BarOpacity=1,				-- class-bar fill opacity (0 hides the fill)
		-- Healer detection & marking
		MarkHealers=true,
		HealerDetectBy="heal",		-- heal (confirmed only, default) | class (guess by class)
		HealerMinHeal=400,			-- a single heal this big confirms a healer outright
		HealerMinHeals=2,			-- or this many whitelisted heals, for smaller ones
		StrictHealerDetection=true,	-- only real healing spells count, not anything that heals
		HealerSpellListText="",		-- seeded from the built-in whitelist the first time it's needed
		HealerSpellListSeeded=false,
		SortHealersToTop=true,
		HealerGreenEdge=true,
		DimNonHealers=false,
		-- Mass-fight controls: in a city raid the list can take 600 detections a
		-- minute through 15 rows, so these cut it down to what's worth attacking.
		UseZoneLevelFloor=true,		-- clamp guessed levels to the zone's entry level
		TomTomOnAltClick=true,		-- alt-click a row to point TomTom at their last position
		-- See enemies sooner. Both ship well below their maximum and both are just
		-- CVar writes, so there is nothing here the client can refuse.
		NameplateDistanceMode="max",	-- max | custom | off
		NameplateDistanceValue=60,		-- used when the mode is custom
		MaxNameplateDistanceShowsEnemies=true,
		ViewDistanceMode="max",			-- max | custom | off
		ViewDistanceValue=777,			-- used when the mode is custom
		DebugMode=false,
		HealerOnlyFilter=false,		-- show only confirmed healers (and KoS)
		-- Focus specific classes, independently of the healer controls.
		FocusClassMode="off",		-- off | sort (float to top) | only (filter)
		FocusClasses={},			-- set of CLASS tokens, e.g. { ROGUE = true }
		KillPriorityOrder=false,	-- order by target value instead of recency
		ShowAggregateHeader=true,	-- "12 3H" beside the title
		-- Window options
		LockPosition=false,
		LockSize=false,
		ShowBackground=true,
		BackgroundOpacity=1,
		ShowBorder=false,
		WindowScale=1,
		TitleBarStyle="solid",		-- classic (stock, subtle) | solid (opaque strip)
		TitleBarOpacity=1,
		-- Enemy defensive cooldowns + alert throttling
		TrackCooldowns=true,
		AnnounceCooldowns=false,
		CooldownListText="",		-- seeded from the ten researched defaults the first time it is needed
		CooldownListSeeded=false,
		KOSGuildAlertCooldown=20,	-- seconds between alerts for the same KoS guild
		ClampToScreen=true,
		Font="Friz Quadrata TT",
		Scaling=1,
		Enabled=true,
		EnabledInBattlegrounds=true,
		EnabledInSanctuaries=false,
		EnabledInArenas=true,
		EnabledInWintergrasp=true,
		DisableWhenPVPUnflagged=true,
		MinimapDetection=false,
		MinimapDetails=true,
		DisplayOnMap=true,
		SwitchToZone=false,
		MapDisplayLimit="SameZone",
		DisplayTooltipNearPingWindow=false,
		TooltipAnchor="ANCHOR_CURSOR",
		DisplayWinLossStatistics=true,
		DisplayKOSReason=true,
		DisplayLastSeen=true,
		DisplayListData="1NameLevelClass",
		ShowOnDetection=true,
		HidePing=false,
--		ShowOnlyPvPFlagged=false,
		ShowKoSButton=false,
		InvertPing=false,
		ResizePing=true,
		ResizePingLimit=15,
		SoundChannel="SFX",
		Announce="None",
		OnlyAnnounceKoS=false,
		WarnOnStealth=true,
		WarnOnKOS=true,
		WarnOnKOSGuild=false,
		WarnOnRace=false,
		SelectWarnRace="None",
		DisplayWarnings="Default",
		EnableSound=true,
		OnlySoundKoS=false, 
		StopAlertsOnTaxi=true,
		RemoveUndetected="OneMinute",
		ShowNearbyList=true,
		PrioritiseKoS=true,
		PurgeData="NinetyDays",
		PurgeKoS=false,
		PurgeWinLossData=false,
		ShareData=false,
		UseData=false,
		ShareKOSBetweenCharacters=true,
		AppendUnitNameCheck=false,
		AppendUnitKoSCheck=false,
		FilteredZones = {
			["Booty Bay"] = false,
			["Gadgetzan"] = false,
			["Ratchet"] = false,
			["Everlook"] = false,
			["The Salty Sailor Tavern"] = false,
			["Cenarion Hold"] = false,
			["Shattrath City"] = false,
			["Area 52"] = false,
--			["Dalaran"] = false,
--			["Bogpaddle"] = false,
--			["The Vindicaar"] = false,
--			["Krasus' Landing"] = false,
--			["The Violet Gate"] = false,
--			["Magni's Encampment"] = false,
--			["Chamber of Heart"] = false,
--			["Hall of Ancient Paths"] = false,
--			["Sanctum of the Sages"] = false,
--			["Rustbolt"] = false,
--			["Oribos"] = false,
--			["Valdrakken"] = false,
--			["The Roasted Ram"] = false,
--			["Dornogal"] = false,
--			["Stonelight Rest"] = false,
--			["Delver's Headquarters"] = false,
		},
	},
}

SM:Register("statusbar", "Flat", [[Interface\Addons\Ping\Textures\bar-flat.tga]])

function Ping:CheckDatabase()
	if not PingPerCharDB or not PingPerCharDB.PlayerData then
		PingPerCharDB = {}
	end
	PingPerCharDB.version = Ping.DatabaseVersion
	if not PingPerCharDB.PlayerData then
		PingPerCharDB.PlayerData = {}
	end
	if not PingPerCharDB.IgnoreData then
		PingPerCharDB.IgnoreData = {}
	end
	if not PingPerCharDB.KOSData then
		PingPerCharDB.KOSData = {}
	end
	if not PingPerCharDB.EncounterHistory then
		PingPerCharDB.EncounterHistory = {}
	end
	if PingDB.kosData == nil then PingDB.kosData = {} end
	if PingDB.kosData[Ping.RealmName] == nil then PingDB.kosData[Ping.RealmName] = {} end
	if PingDB.kosData[Ping.RealmName][Ping.FactionName] == nil then PingDB.kosData[Ping.RealmName][Ping.FactionName] = {} end
	if PingDB.kosData[Ping.RealmName][Ping.FactionName][Ping.CharacterName] == nil then PingDB.kosData[Ping.RealmName][Ping.FactionName][Ping.CharacterName] = {} end
	if PingDB.removeKOSData == nil then PingDB.removeKOSData = {} end
	if PingDB.removeKOSData[Ping.RealmName] == nil then PingDB.removeKOSData[Ping.RealmName] = {} end
	if PingDB.removeKOSData[Ping.RealmName][Ping.FactionName] == nil then PingDB.removeKOSData[Ping.RealmName][Ping.FactionName] = {} end
--[[	if Ping.db.profile == nil then Ping.db.profile = Default_Profile.profile end
	if Ping.db.profile.Colors == nil then Ping.db.profile.Colors = Default_Profile.profile.Colors end
	if Ping.db.profile.Colors["Window"] == nil then Ping.db.profile.Colors["Window"] = Default_Profile.profile.Colors["Window"] end
	if Ping.db.profile.Colors["Window"]["Title"] == nil then Ping.db.profile.Colors["Window"]["Title"] = Default_Profile.profile.Colors["Window"]["Title"] end
	if Ping.db.profile.Colors["Window"]["Background"] == nil then Ping.db.profile.Colors["Window"]["Background"] = Default_Profile.profile.Colors["Window"]["Background"] end
	if Ping.db.profile.Colors["Window"]["Title Text"] == nil then Ping.db.profile.Colors["Window"]["Title Text"] = Default_Profile.profile.Colors["Window"]["Title Text"] end
	if Ping.db.profile.Colors["Other Windows"] == nil then Ping.db.profile.Colors["Other Windows"] = Default_Profile.profile.Colors["Other Windows"] end
	if Ping.db.profile.Colors["Other Windows"]["Title"] == nil then Ping.db.profile.Colors["Other Windows"]["Title"] = Default_Profile.profile.Colors["Other Windows"]["Title"] end
	if Ping.db.profile.Colors["Other Windows"]["Background"] == nil then Ping.db.profile.Colors["Other Windows"]["Background"] = Default_Profile.profile.Colors["Other Windows"]["Background"] end
	if Ping.db.profile.Colors["Other Windows"]["Title Text"] == nil then Ping.db.profile.Colors["Other Windows"]["Title Text"] = Default_Profile.profile.Colors["Other Windows"]["Title Text"] end
	if Ping.db.profile.Colors["Bar"] == nil then Ping.db.profile.Colors["Bar"] = Default_Profile.profile.Colors["Bar"] end
	if Ping.db.profile.Colors["Bar"]["Bar Text"] == nil then Ping.db.profile.Colors["Bar"]["Bar Text"] = Default_Profile.profile.Colors["Bar"]["Bar Text"] end
	if Ping.db.profile.Colors["Warning"] == nil then Ping.db.profile.Colors["Warning"] = Default_Profile.profile.Colors["Warning"] end
	if Ping.db.profile.Colors["Warning"]["Warning Text"] == nil then Ping.db.profile.Colors["Warning"]["Warning Text"] = Default_Profile.profile.Colors["Warning"]["Warning Text"] end
	if Ping.db.profile.Colors["Tooltip"] == nil then Ping.db.profile.Colors["Tooltip"] = Default_Profile.profile.Colors["Tooltip"] end
	if Ping.db.profile.Colors["Tooltip"]["Title Text"] == nil then Ping.db.profile.Colors["Tooltip"]["Title Text"] = Default_Profile.profile.Colors["Tooltip"]["Title Text"] end
	if Ping.db.profile.Colors["Tooltip"]["Details Text"] == nil then Ping.db.profile.Colors["Tooltip"]["Details Text"] = Default_Profile.profile.Colors["Tooltip"]["Details Text"] end
	if Ping.db.profile.Colors["Tooltip"]["Location Text"] == nil then Ping.db.profile.Colors["Tooltip"]["Location Text"] = Default_Profile.profile.Colors["Tooltip"]["Location Text"] end
	if Ping.db.profile.Colors["Tooltip"]["Reason Text"] == nil then Ping.db.profile.Colors["Tooltip"]["Reason Text"] = Default_Profile.profile.Colors["Tooltip"]["Reason Text"] end
	if Ping.db.profile.Colors["Alert"] == nil then Ping.db.profile.Colors["Alert"] = Default_Profile.profile.Colors["Alert"] end
	if Ping.db.profile.Colors["Alert"]["Background"] == nil then Ping.db.profile.Colors["Alert"]["Background"] = Default_Profile.profile.Colors["Alert"]["Background"] end
	if Ping.db.profile.Colors["Alert"]["Icon"] == nil then Ping.db.profile.Colors["Alert"]["Icon"] = Default_Profile.profile.Colors["Alert"]["Icon"] end
	if Ping.db.profile.Colors["Alert"]["KOS Border"] == nil then Ping.db.profile.Colors["Alert"]["KOS Border"] = Default_Profile.profile.Colors["Alert"]["KOS Border"] end
	if Ping.db.profile.Colors["Alert"]["KOS Text"] == nil then Ping.db.profile.Colors["Alert"]["KOS Text"] = Default_Profile.profile.Colors["Alert"]["KOS Text"] end
	if Ping.db.profile.Colors["Alert"]["KOS Guild Border"] == nil then Ping.db.profile.Colors["Alert"]["KOS Guild Border"] = Default_Profile.profile.Colors["Alert"]["KOS Guild Border"] end
	if Ping.db.profile.Colors["Alert"]["KOS Guild Text"] == nil then Ping.db.profile.Colors["Alert"]["KOS Guild Text"] = Default_Profile.profile.Colors["Alert"]["KOS Guild Text"] end
	if Ping.db.profile.Colors["Alert"]["Stealth Border"] == nil then Ping.db.profile.Colors["Alert"]["Stealth Border"] = Default_Profile.profile.Colors["Alert"]["Stealth Border"] end
	if Ping.db.profile.Colors["Alert"]["Stealth Text"] == nil then Ping.db.profile.Colors["Alert"]["Stealth Text"] = Default_Profile.profile.Colors["Alert"]["Stealth Text"] end
	if Ping.db.profile.Colors["Alert"]["Away Border"] == nil then Ping.db.profile.Colors["Alert"]["Away Border"] = Default_Profile.profile.Colors["Alert"]["Away Border"] end
	if Ping.db.profile.Colors["Alert"]["Away Text"] == nil then Ping.db.profile.Colors["Alert"]["Away Text"] = Default_Profile.profile.Colors["Alert"]["Away Text"] end
	if Ping.db.profile.Colors["Alert"]["Location Text"] == nil then Ping.db.profile.Colors["Alert"]["Location Text"] = Default_Profile.profile.Colors["Alert"]["Location Text"] end
	if Ping.db.profile.Colors["Alert"]["Name Text"] == nil then Ping.db.profile.Colors["Alert"]["Name Text"] = Default_Profile.profile.Colors["Alert"]["Name Text"] end
	if Ping.db.profile.Colors["Class"] == nil then Ping.db.profile.Colors["Class"] = Default_Profile.profile.Colors["Class"] end
	if Ping.db.profile.Colors["Class"]["HUNTER"] == nil then Ping.db.profile.Colors["Class"]["HUNTER"] = Default_Profile.profile.Colors["Class"]["HUNTER"] end
	if Ping.db.profile.Colors["Class"]["WARLOCK"] == nil then Ping.db.profile.Colors["Class"]["WARLOCK"] = Default_Profile.profile.Colors["Class"]["WARLOCK"] end
	if Ping.db.profile.Colors["Class"]["PRIEST"] == nil then Ping.db.profile.Colors["Class"]["PRIEST"] = Default_Profile.profile.Colors["Class"]["PRIEST"] end
	if Ping.db.profile.Colors["Class"]["PALADIN"] == nil then Ping.db.profile.Colors["Class"]["PALADIN"] = Default_Profile.profile.Colors["Class"]["PALADIN"] end
	if Ping.db.profile.Colors["Class"]["MAGE"] == nil then Ping.db.profile.Colors["Class"]["MAGE"] = Default_Profile.profile.Colors["Class"]["MAGE"] end
	if Ping.db.profile.Colors["Class"]["ROGUE"] == nil then Ping.db.profile.Colors["Class"]["ROGUE"] = Default_Profile.profile.Colors["Class"]["ROGUE"] end
	if Ping.db.profile.Colors["Class"]["DRUID"] == nil then Ping.db.profile.Colors["Class"]["DRUID"] = Default_Profile.profile.Colors["Class"]["DRUID"] end
	if Ping.db.profile.Colors["Class"]["SHAMAN"] == nil then Ping.db.profile.Colors["Class"]["SHAMAN"] = Default_Profile.profile.Colors["Class"]["SHAMAN"] end
	if Ping.db.profile.Colors["Class"]["WARRIOR"] == nil then Ping.db.profile.Colors["Class"]["WARRIOR"] = Default_Profile.profile.Colors["Class"]["WARRIOR"] end
	if Ping.db.profile.Colors["Class"]["DEATHKNIGHT"] == nil then Ping.db.profile.Colors["Class"]["DEATHKNIGHT"] = Default_Profile.profile.Colors["Class"]["DEATHKNIGHT"] end
	if Ping.db.profile.Colors["Class"]["MONK"] == nil then Ping.db.profile.Colors["Class"]["MONK"] = Default_Profile.profile.Colors["Class"]["MONK"] end
	if Ping.db.profile.Colors["Class"]["DEMONHUNTER"] == nil then Ping.db.profile.Colors["Class"]["DEMONHUNTER"] = Default_Profile.profile.Colors["Class"]["DEMONHUNTER"] end	
	if Ping.db.profile.Colors["Class"]["PET"] == nil then Ping.db.profile.Colors["Class"]["PET"] = Default_Profile.profile.Colors["Class"]["PET"] end
	if Ping.db.profile.Colors["Class"]["MOB"] == nil then Ping.db.profile.Colors["Class"]["MOB"] = Default_Profile.profile.Colors["Class"]["MOB"] end
	if Ping.db.profile.Colors["Class"]["UNKNOWN"] == nil then Ping.db.profile.Colors["Class"]["UNKNOWN"] = Default_Profile.profile.Colors["Class"]["UNKNOWN"] end
	if Ping.db.profile.Colors["Class"]["HOSTILE"] == nil then Ping.db.profile.Colors["Class"]["HOSTILE"] = Default_Profile.profile.Colors["Class"]["HOSTILE"] end
	if Ping.db.profile.Colors["Class"]["UNGROUPED"] == nil then Ping.db.profile.Colors["Class"]["UNGROUPED"] = Default_Profile.profile.Colors["Class"]["UNGROUPED"] end
	if Ping.db.profile.MainWindow == nil then Ping.db.profile.MainWindow = Default_Profile.profile.MainWindow end
	if Ping.db.profile.MainWindow.Buttons == nil then Ping.db.profile.MainWindow.Buttons = Default_Profile.profile.MainWindow.Buttons end
	if Ping.db.profile.MainWindow.Buttons.ClearButton == nil then Ping.db.profile.MainWindow.Buttons.ClearButton = Default_Profile.profile.MainWindow.Buttons.ClearButton end
	if Ping.db.profile.MainWindow.Buttons.LeftButton == nil then Ping.db.profile.MainWindow.Buttons.LeftButton = Default_Profile.profile.MainWindow.Buttons.LeftButton end
	if Ping.db.profile.MainWindow.Buttons.RightButton == nil then Ping.db.profile.MainWindow.Buttons.RightButton = Default_Profile.profile.MainWindow.Buttons.RightButton end
	if Ping.db.profile.MainWindow.RowHeight == nil then Ping.db.profile.MainWindow.RowHeight = Default_Profile.profile.MainWindow.RowHeight end
	if Ping.db.profile.MainWindow.RowSpacing == nil then Ping.db.profile.MainWindow.RowSpacing = Default_Profile.profile.MainWindow.RowSpacing end
	if Ping.db.profile.MainWindow.TextHeight == nil then Ping.db.profile.MainWindow.TextHeight = Default_Profile.profile.MainWindow.TextHeight end
	if Ping.db.profile.MainWindow.AutoHide == nil then Ping.db.profile.MainWindow.AutoHide = Default_Profile.profile.MainWindow.AutoHide end
	if Ping.db.profile.MainWindow.BarText == nil then Ping.db.profile.MainWindow.BarText = Default_Profile.profile.MainWindow.BarText end
	if Ping.db.profile.MainWindow.BarText.RankNum == nil then Ping.db.profile.MainWindow.BarText.RankNum = Default_Profile.profile.MainWindow.BarText.RankNum end
	if Ping.db.profile.MainWindow.BarText.PerSec == nil then Ping.db.profile.MainWindow.BarText.PerSec = Default_Profile.profile.MainWindow.BarText.PerSec end
	if Ping.db.profile.MainWindow.BarText.Percent == nil then Ping.db.profile.MainWindow.BarText.Percent = Default_Profile.profile.MainWindow.BarText.Percent end
	if Ping.db.profile.MainWindow.BarText.NumFormat == nil then Ping.db.profile.MainWindow.BarText.NumFormat = Default_Profile.profile.MainWindow.BarText.NumFormat end
	if Ping.db.profile.MainWindow.Position == nil then Ping.db.profile.MainWindow.Position = Default_Profile.profile.MainWindow.Position end
	if Ping.db.profile.MainWindow.Position.x == nil then Ping.db.profile.MainWindow.Position.x = Default_Profile.profile.MainWindow.Position.x end
	if Ping.db.profile.MainWindow.Position.y == nil then Ping.db.profile.MainWindow.Position.y = Default_Profile.profile.MainWindow.Position.y end
	if Ping.db.profile.MainWindow.Position.w == nil then Ping.db.profile.MainWindow.Position.w = Default_Profile.profile.MainWindow.Position.w end
	if Ping.db.profile.MainWindow.Position.h == nil then Ping.db.profile.MainWindow.Position.h = Default_Profile.profile.MainWindow.Position.h end
	if Ping.db.profile.AlertWindowNameSize == nil then Ping.db.profile.AlertWindowNameSize = Default_Profile.profile.AlertWindowNameSize end
	if Ping.db.profile.AlertWindowLocationSize == nil then Ping.db.profile.AlertWindowLocationSize = Default_Profile.profile.AlertWindowLocationSize end
	if Ping.db.profile.BarTexture == nil then Ping.db.profile.BarTexture = Default_Profile.profile.BarTexture end
	if Ping.db.profile.MainWindowVis == nil then Ping.db.profile.MainWindowVis = Default_Profile.profile.MainWindowVis end
	if Ping.db.profile.ShowMinimapButton == nil then Ping.db.profile.ShowMinimapButton = Default_Profile.profile.ShowMinimapButton end
	if Ping.db.profile.LockMinimapButton == nil then Ping.db.profile.LockMinimapButton = Default_Profile.profile.LockMinimapButton end
	if Ping.db.profile.HideMinimapButtonInCombat == nil then Ping.db.profile.HideMinimapButtonInCombat = Default_Profile.profile.HideMinimapButtonInCombat end
	if Ping.db.profile.MinimapButtonAngle == nil then Ping.db.profile.MinimapButtonAngle = Default_Profile.profile.MinimapButtonAngle end
	if Ping.db.profile.MinimapLeftClick == nil then Ping.db.profile.MinimapLeftClick = Default_Profile.profile.MinimapLeftClick end
	if Ping.db.profile.MinimapRightClick == nil then Ping.db.profile.MinimapRightClick = Default_Profile.profile.MinimapRightClick end
	if Ping.db.profile.MinimapButtonCount == nil then Ping.db.profile.MinimapButtonCount = Default_Profile.profile.MinimapButtonCount end
	if Ping.db.profile.CurrentList == nil then Ping.db.profile.CurrentList = Default_Profile.profile.CurrentList end
	if Ping.db.profile.Locked == nil then Ping.db.profile.Locked = Default_Profile.profile.Locked end
	if Ping.db.profile.Font == nil then Ping.db.profile.Font = Default_Profile.profile.Font end
	if Ping.db.profile.Scaling == nil then Ping.db.profile.Scaling = Default_Profile.profile.Scaling end
	if Ping.db.profile.Enabled == nil then Ping.db.profile.Enabled = Default_Profile.profile.Enabled end
	if Ping.db.profile.EnabledInBattlegrounds == nil then Ping.db.profile.EnabledInBattlegrounds = Default_Profile.profile.EnabledInBattlegrounds end
	if Ping.db.profile.EnabledInSanctuaries == nil then Ping.db.profile.EnabledInSanctuaries = Default_Profile.profile.EnabledInSanctuaries end
	if Ping.db.profile.EnabledInArenas == nil then Ping.db.profile.EnabledInArenas = Default_Profile.profile.EnabledInArenas end
	if Ping.db.profile.EnabledInWintergrasp == nil then Ping.db.profile.EnabledInWintergrasp = Default_Profile.profile.EnabledInWintergrasp end
	if Ping.db.profile.DisableWhenPVPUnflagged == nil then Ping.db.profile.DisableWhenPVPUnflagged = Default_Profile.profile.DisableWhenPVPUnflagged end
	if Ping.db.profile.MinimapDetection == nil then Ping.db.profile.MinimapDetection = Default_Profile.profile.MinimapDetection end
	if Ping.db.profile.MinimapDetails == nil then Ping.db.profile.MinimapDetails = Default_Profile.profile.MinimapDetails end
	if Ping.db.profile.DisplayOnMap == nil then Ping.db.profile.DisplayOnMap = Default_Profile.profile.DisplayOnMap end
	if Ping.db.profile.SwitchToZone == nil then Ping.db.profile.SwitchToZone = Default_Profile.profile.SwitchToZone end	
	if Ping.db.profile.MapDisplayLimit == nil then Ping.db.profile.MapDisplayLimit = Default_Profile.profile.MapDisplayLimit end
	if Ping.db.profile.DisplayTooltipNearPingWindow == nil then Ping.db.profile.DisplayTooltipNearPingWindow = Default_Profile.profile.DisplayTooltipNearPingWindow end	
	if Ping.db.profile.TooltipAnchor == nil then Ping.db.profile.TooltipAnchor = Default_Profile.profile.TooltipAnchor end	
	if Ping.db.profile.DisplayWinLossStatistics == nil then Ping.db.profile.DisplayWinLossStatistics = Default_Profile.profile.DisplayWinLossStatistics end
	if Ping.db.profile.DisplayKOSReason == nil then Ping.db.profile.DisplayKOSReason = Default_Profile.profile.DisplayKOSReason end
	if Ping.db.profile.DisplayLastSeen == nil then Ping.db.profile.DisplayLastSeen = Default_Profile.profile.DisplayLastSeen end
	if Ping.db.profile.ShowOnDetection == nil then Ping.db.profile.ShowOnDetection = Default_Profile.profile.ShowOnDetection end
	if Ping.db.profile.HidePing == nil then Ping.db.profile.HidePing = Default_Profile.profile.HidePing end
--	if Ping.db.profile.ShowOnlyPvPFlagged == nil then Ping.db.profile.ShowOnlyPvPFlagged = Default_Profile.profile.ShowOnlyPvPFlagged end	
	if Ping.db.profile.ShowKoSButton == nil then Ping.db.profile.ShowKoSButton = Default_Profile.profile.ShowKoSButton end	
	if Ping.db.profile.InvertPing == nil then Ping.db.profile.InvertPing = Default_Profile.profile.InvertPing end
	if Ping.db.profile.ResizePing == nil then Ping.db.profile.ResizePing = Default_Profile.profile.ResizePing end
	if Ping.db.profile.ResizePingLimit == nil then Ping.db.profile.ResizePingLimit = Default_Profile.profile.ResizePingLimit end 
	if Ping.db.profile.Announce == nil then Ping.db.profile.Announce = Default_Profile.profile.Announce end
	if Ping.db.profile.OnlyAnnounceKoS == nil then Ping.db.profile.OnlyAnnounceKoS = Default_Profile.profile.OnlyAnnounceKoS end
	if Ping.db.profile.WarnOnStealth == nil then Ping.db.profile.WarnOnStealth = Default_Profile.profile.WarnOnStealth end
	if Ping.db.profile.WarnOnKOS == nil then Ping.db.profile.WarnOnKOS = Default_Profile.profile.WarnOnKOS end
	if Ping.db.profile.WarnOnKOSGuild == nil then Ping.db.profile.WarnOnKOSGuild = Default_Profile.profile.WarnOnKOSGuild end
	if Ping.db.profile.WarnOnRace == nil then Ping.db.profile.WarnOnRace = Default_Profile.profile.WarnOnRace end
	if Ping.db.profile.SelectWarnRace == nil then Ping.db.profile.SelectWarnRace = Default_Profile.profile.SelectWarnRace end
	if Ping.db.profile.DisplayWarningsInErrorsFrame == nil then Ping.db.profile.DisplayWarningsInErrorsFrame = Default_Profile.profile.DisplayWarningsInErrorsFrame end
	if Ping.db.profile.EnableSound == nil then Ping.db.profile.EnableSound = Default_Profile.profile.EnableSound end
	if Ping.db.profile.OnlySoundKoS == nil then Ping.db.profile.OnlySoundKoS = Default_Profile.profile.OnlySoundKoS end	
	if Ping.db.profile.StopAlertsOnTaxi == nil then Ping.db.profile.StopAlertsOnTaxi = Default_Profile.profile.StopAlertsOnTaxi end 	
	if Ping.db.profile.RemoveUndetected == nil then Ping.db.profile.RemoveUndetected = Default_Profile.profile.RemoveUndetected end
	if Ping.db.profile.ShowNearbyList == nil then Ping.db.profile.ShowNearbyList = Default_Profile.profile.ShowNearbyList end
	if Ping.db.profile.PrioritiseKoS == nil then Ping.db.profile.PrioritiseKoS = Default_Profile.profile.PrioritiseKoS end
	if Ping.db.profile.PurgeData == nil then Ping.db.profile.PurgeData = Default_Profile.profile.PurgeData end
	if Ping.db.profile.PurgeKoS == nil then Ping.db.profile.PurgeKoS = Default_Profile.profile.PurgeKoSData end	
	if Ping.db.profile.PurgeWinLossData == nil then Ping.db.profile.PurgeWinLossData = Default_Profile.profile.PurgeWinLossData end	
	if Ping.db.profile.ShareData == nil then Ping.db.profile.ShareData = Default_Profile.profile.ShareData end
	if Ping.db.profile.UseData == nil then Ping.db.profile.UseData = Default_Profile.profile.UseData end
	if Ping.db.profile.ShareKOSBetweenCharacters == nil then Ping.db.profile.ShareKOSBetweenCharacters = Default_Profile.profile.ShareKOSBetweenCharacters end
	if Ping.db.profile.AppendUnitNameCheck == nil then Ping.db.profile.AppendUnitNameCheck = Default_Profile.profile.AppendUnitNameCheck end
	if Ping.db.profile.AppendUnitKoSCheck == nil then Ping.db.profile.AppendUnitKoSCheck = Default_Profile.profile.AppendUnitKoSCheck end	]]--

	-- Target-picker settings migration. AceDB merges the Default_Profile
	-- defaults for us, but guard the new keys explicitly so existing profiles
	-- saved before this version pick them up cleanly (and any partially-saved
	-- nested Colors table is completed).
	local p = Ping.db.profile
	if p.MarkHealers == nil then p.MarkHealers = Default_Profile.profile.MarkHealers end
	if p.HealerDetectBy == nil then p.HealerDetectBy = Default_Profile.profile.HealerDetectBy end
	if p.SortHealersToTop == nil then p.SortHealersToTop = Default_Profile.profile.SortHealersToTop end
	if p.HealerGreenEdge == nil then p.HealerGreenEdge = Default_Profile.profile.HealerGreenEdge end
	if p.DimNonHealers == nil then p.DimNonHealers = Default_Profile.profile.DimNonHealers end
	if p.LookPreset == nil then p.LookPreset = Default_Profile.profile.LookPreset end
	if p.ClassColoredNames == nil then p.ClassColoredNames = Default_Profile.profile.ClassColoredNames end
	if p.BarOpacity == nil then p.BarOpacity = Default_Profile.profile.BarOpacity end
	if p.LockPosition == nil then p.LockPosition = Default_Profile.profile.LockPosition end
	if p.LockSize == nil then p.LockSize = Default_Profile.profile.LockSize end
	if p.ShowBackground == nil then p.ShowBackground = Default_Profile.profile.ShowBackground end
	if p.BackgroundOpacity == nil then p.BackgroundOpacity = Default_Profile.profile.BackgroundOpacity end
	if p.ShowBorder == nil then p.ShowBorder = Default_Profile.profile.ShowBorder end
	if p.WindowScale == nil then p.WindowScale = Default_Profile.profile.WindowScale end
	if p.TitleBarStyle == nil then p.TitleBarStyle = Default_Profile.profile.TitleBarStyle end
	if p.TitleBarOpacity == nil then p.TitleBarOpacity = Default_Profile.profile.TitleBarOpacity end
	if p.HealerMinHeal == nil then p.HealerMinHeal = Default_Profile.profile.HealerMinHeal end
	if p.HealerMinHeals == nil then p.HealerMinHeals = Default_Profile.profile.HealerMinHeals end
	if p.StrictHealerDetection == nil then p.StrictHealerDetection = Default_Profile.profile.StrictHealerDetection end
	if p.HealerSpellListText == nil then p.HealerSpellListText = Default_Profile.profile.HealerSpellListText end
	if p.HealerSpellListSeeded == nil then p.HealerSpellListSeeded = Default_Profile.profile.HealerSpellListSeeded end
	if p.CooldownListText == nil then p.CooldownListText = Default_Profile.profile.CooldownListText end
	if p.CooldownListSeeded == nil then p.CooldownListSeeded = Default_Profile.profile.CooldownListSeeded end
	-- The watch list used to be an "extras only" box sitting on top of ten hidden
	-- built-ins. Anything already typed there is appended once the full list is
	-- seeded, so a previously-added spell is not quietly dropped.
	if p.ExtraCooldownsText and p.ExtraCooldownsText ~= "" then
		p.pendingExtraCooldowns = p.ExtraCooldownsText
	end
	p.ExtraCooldownsText = nil
	if p.LookTheme == nil then p.LookTheme = Default_Profile.profile.LookTheme end
	if p.ArtworkStyle == nil then
		local theme = Ping.LookThemes and Ping.LookThemes[p.LookTheme]
		p.ArtworkStyle = theme and theme.artwork or "legacy"
	end
	-- The first Obsidian pass was intentionally subdued, but in the live game
	-- the class fills did not separate enough from its dark generated panel.
	-- Apply this once so existing profiles receive the readability correction.
	if p.ArtworkStyle == "obsidian" and (tonumber(p.ObsidianArtworkRevision) or 0) < 3 then
		p.BarOpacity = 0.55
		p.ObsidianArtworkRevision = 3
	end
	-- These generated panels already draw their own edge. Earlier presets also
	-- enabled Ping's overlay border, producing a redundant double outline.
	local cleanArtwork = p.ArtworkStyle == "minimal" or p.ArtworkStyle == "clean"
		or p.ArtworkStyle == "unitframe" or p.ArtworkStyle == "villain"
	if cleanArtwork and (tonumber(p.CleanThemeBorderRevision) or 0) < 1 then
		p.ShowBorder = false
		p.CleanThemeBorderRevision = 1
	end
	if p.UseZoneLevelFloor == nil then p.UseZoneLevelFloor = Default_Profile.profile.UseZoneLevelFloor end
	if p.TomTomOnAltClick == nil then p.TomTomOnAltClick = Default_Profile.profile.TomTomOnAltClick end
	if p.LockFont == nil then p.LockFont = Default_Profile.profile.LockFont end
	for _, k in ipairs({"NameplateDistanceMode","NameplateDistanceValue",
		"MaxNameplateDistanceShowsEnemies","ViewDistanceMode","ViewDistanceValue"}) do
		if p[k] == nil then p[k] = Default_Profile.profile[k] end
	end
	-- These were plain on/off toggles before the values became configurable.
	-- Carry the old answer across rather than silently re-enabling something the
	-- user had turned off.
	if p.MaxNameplateDistance ~= nil then
		if p.MaxNameplateDistance == false then p.NameplateDistanceMode = "off" end
		p.MaxNameplateDistance = nil
	end
	if p.MaxViewDistance ~= nil then
		if p.MaxViewDistance == false then p.ViewDistanceMode = "off" end
		p.MaxViewDistance = nil
	end
	if p.DebugMode == nil then p.DebugMode = Default_Profile.profile.DebugMode end
	if p.HealerOnlyFilter == nil then p.HealerOnlyFilter = Default_Profile.profile.HealerOnlyFilter end
	if p.FocusClassMode == nil then p.FocusClassMode = Default_Profile.profile.FocusClassMode end
	if type(p.FocusClasses) ~= "table" then p.FocusClasses = {} end
	if p.KillPriorityOrder == nil then p.KillPriorityOrder = Default_Profile.profile.KillPriorityOrder end
	if p.ShowAggregateHeader == nil then p.ShowAggregateHeader = Default_Profile.profile.ShowAggregateHeader end
	if p.TrackCooldowns == nil then p.TrackCooldowns = Default_Profile.profile.TrackCooldowns end
	if p.AnnounceCooldowns == nil then p.AnnounceCooldowns = Default_Profile.profile.AnnounceCooldowns end
	if p.KOSGuildAlertCooldown == nil then p.KOSGuildAlertCooldown = Default_Profile.profile.KOSGuildAlertCooldown end
	-- Existing profiles defaulted healers to a class guess, which marks shadow
	-- priests and ret paladins as healers. Move them to confirmed-heal once.
	if not p.HealerDetectByMigrated then
		p.HealerDetectBy = Default_Profile.profile.HealerDetectBy
		p.HealerDetectByMigrated = true
	end
	-- An earlier build counted ANY heal event, including self-healing and
	-- lifesteal, so warlocks (Death Coil / Drain Life) and warriors
	-- (Bloodthirst / Blood Craze) were wrongly flagged. Clear the bad flags
	-- once so they get re-learned under the corrected rules.
	if PingPerCharDB and PingPerCharDB.PlayerData and not PingPerCharDB.healerFlagsReset then
		for _, data in pairs(PingPerCharDB.PlayerData) do
			data.isHealer = nil
			data.healTotal = nil
			data.healCount = nil
		end
		PingPerCharDB.healerFlagsReset = true
	end
	if p.Colors["Ping"] == nil then p.Colors["Ping"] = {} end
	for k, v in pairs(Default_Profile.profile.Colors["Ping"]) do
		if p.Colors["Ping"][k] == nil then
			p.Colors["Ping"][k] = { r = v.r, g = v.g, b = v.b, a = v.a }
		end
	end
end

function Ping:ResetProfile()
	Ping.db.profile = Default_Profile.profile
--	Ping:CheckDatabase()
end

function Ping:HandleProfileChanges()
	Ping:UpdateMinimapButton()
	Ping:CreateMainWindow()
	Ping:RestoreMainWindowPosition(Ping.db.profile.MainWindow.Position.x, Ping.db.profile.MainWindow.Position.y, Ping.db.profile.MainWindow.Position.w, 34)
	Ping:ResizeMainWindow()
	Ping:UpdateTimeoutSettings()
	Ping:ApplyThemeChrome()
	Ping:LockWindows(Ping.db.profile.Locked)
	Ping:ApplyWindowLocks()
	Ping:ApplyWindowStyle()
	Ping:ClampToScreen(Ping.db.profile.ClampToScreen)
end

function Ping:RegisterModuleOptions(name, optionTbl, displayName)
	Ping.options.args[name] = (type(optionTbl) == "function") and optionTbl() or optionTbl
	self.optionsFrames[name] = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Ping", displayName, L["Ping Option"], name)
end

function Ping:SetupOptions()
	self.optionsFrames = {}

 	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("Ping", Ping.options)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Ping Commands", Ping.optionsSlash, "ping")

	-- One Blizzard sub-panel per page. The second level lives in tabs inside
	-- each page rather than as more entries here, which is the whole point of
	-- the layout: seven rows in the sidebar instead of ten.
	local ACD3 = LibStub("AceConfigDialog-3.0")
	self.optionsFrames.Ping = ACD3:AddToBlizOptions("Ping", L["Ping Option"], nil, "PingGroup")
	self.optionsFrames.About = ACD3:AddToBlizOptions("Ping", L["About"], L["Ping Option"], "About")
	self.optionsFrames.Targeting = ACD3:AddToBlizOptions("Ping", L["TPageTargeting"], L["Ping Option"], "Targeting")
	self.optionsFrames.Finding = ACD3:AddToBlizOptions("Ping", L["TPageFinding"], L["Ping Option"], "Finding")
	self.optionsFrames.Look = ACD3:AddToBlizOptions("Ping", L["TPageLook"], L["Ping Option"], "Look")
	self.optionsFrames.Alerts = ACD3:AddToBlizOptions("Ping", L["TPageAlerts"], L["Ping Option"], "Alerts")
	self.optionsFrames.MinimapButton = ACD3:AddToBlizOptions("Ping", L["MinimapButtonPage"], L["Ping Option"], "MinimapButton")
	self.optionsFrames.Data = ACD3:AddToBlizOptions("Ping", L["TPageData"], L["Ping Option"], "Data")

	self:RegisterModuleOptions("Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db), L["Profiles"])
	Ping.options.args.Profiles.order = -2
end

function Ping:UpdateTimeoutSettings()
	if not Ping.db.profile.RemoveUndetected or Ping.db.profile.RemoveUndetected == "OneMinute" then
		Ping.ActiveTimeout = 30
		Ping.InactiveTimeout = 60
	elseif Ping.db.profile.RemoveUndetected == "TwoMinutes" then
		Ping.ActiveTimeout = 60
		Ping.InactiveTimeout = 120
	elseif Ping.db.profile.RemoveUndetected == "FiveMinutes" then
		Ping.ActiveTimeout = 150
		Ping.InactiveTimeout = 300
	elseif Ping.db.profile.RemoveUndetected == "TenMinutes" then
		Ping.ActiveTimeout = 300
		Ping.InactiveTimeout = 600
	elseif Ping.db.profile.RemoveUndetected == "FifteenMinutes" then
		Ping.ActiveTimeout = 450
		Ping.InactiveTimeout = 900
	elseif Ping.db.profile.RemoveUndetected == "Never" then
		Ping.ActiveTimeout = 30
		Ping.InactiveTimeout = -1
	else
		Ping.ActiveTimeout = 150
		Ping.InactiveTimeout = 300
	end
end

function Ping:ResetMainWindow() -- not used
	Ping:EnablePing(true, true)
	Ping:CreateMainWindow()
	Ping:RestoreMainWindowPosition(Default_Profile.profile.MainWindow.Position.x, Default_Profile.profile.MainWindow.Position.y, Default_Profile.profile.MainWindow.Position.w, 34)
	Ping:RefreshCurrentList()
end

function Ping:ResetPositions()
	Ping:ResetPositionAllWindows()
end

function Ping:ShowConfig()
	-- Open the top-level Ping category. NOTE: on the modern Settings API,
	-- AceConfigDialog gives sub-categories (e.g. "Profiles") a generated
	-- numeric ID, so passing the string "Profiles" to Settings.OpenToCategory
	-- errors ("outside of expected range"). Only the top-level category keeps
	-- a string ID, so open that via the frame name AceConfigDialog stored.
	local spyCategory = self.optionsFrames and self.optionsFrames.Ping and self.optionsFrames.Ping.name or "Ping"
	if Settings and Settings.OpenToCategory then
		Settings.OpenToCategory(spyCategory)
	elseif InterfaceOptionsFrame_OpenToCategory then
		-- Older clients need the call twice to actually land on the panel.
		InterfaceOptionsFrame_OpenToCategory(self.optionsFrames.Ping)
		InterfaceOptionsFrame_OpenToCategory(self.optionsFrames.Ping)
	end
end

function Ping:OnEnable(first)
	-- EnablePing can be called merely to reveal the window on a new detection.
	-- Do not register everything again or leak another pair of repeating timers.
	if Ping.RuntimeEnabled then return end
	-- Resolve the healer spell whitelist to localised names, and merge any
	-- user-added cooldowns into the runtime lookup. Done here rather than at
	-- file scope because GetSpellInfo is not reliable until the addon is enabled.
	Ping:BuildHealerSpellNames()
	Ping:BuildCooldownLookup()
	Ping.timeid = Ping:ScheduleRepeatingTimer("ManageExpirations", 10, true)
	Ping.cooldownTimer = Ping:ScheduleRepeatingTimer("TickCooldowns", 1)
	Ping:RegisterEvent("ZONE_CHANGED", "ZoneChangedEvent")
	Ping:RegisterEvent("ZONE_CHANGED_INDOORS", "ZoneChangedEvent")
--	Ping:RegisterEvent("ZONE_CHANGED_NEW_AREA", "ZoneChangedEvent")
	Ping:RegisterEvent("ZONE_CHANGED_NEW_AREA", "ZoneChangedNewAreaEvent")
--	Ping:RegisterEvent("PLAYER_ENTERING_WORLD", "ZoneChangedEvent")
	Ping:RegisterEvent("PLAYER_ENTERING_WORLD", "PlayerEnteringWorldEvent")
	Ping:RegisterEvent("UNIT_FACTION", "ZoneChangedEvent")
	Ping:RegisterEvent("PLAYER_TARGET_CHANGED", "PlayerTargetEvent")
	Ping:RegisterEvent("UPDATE_MOUSEOVER_UNIT", "PlayerMouseoverEvent")
	Ping:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "CombatLogEvent")
	Ping:RegisterEvent("UNIT_PET", "UnitPets")
	Ping:RegisterEvent("PLAYER_REGEN_ENABLED", "LeftCombatEvent")
	Ping:RegisterEvent("PLAYER_DEAD", "PlayerDeadEvent")
	Ping:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE", "ChannelNoticeEvent")
	Ping:RegisterEvent("NAME_PLATE_UNIT_ADDED", "NamePlateEvent")
	Ping:RegisterEvent("NAME_PLATE_UNIT_REMOVED", "NamePlateEvent")
	-- Unit events catch target/nameplate tokens; the combat-log handler supplies
	-- coverage for hostile players without a current unit token.
	Ping:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "UnitSpellcastEvent")
	Ping:RegisterComm(Ping.Signature, "CommReceived")
	if Ping.HookDebugErrors then Ping:HookDebugErrors() end
	if Ping:IsDebugging() then Ping:CaptureDebugEnvironment() end
	Ping.RuntimeEnabled = true
	-- Do not wait for the channel-notice settling window before deciding whether
	-- detection is allowed. On reload that old six-second blackout let Spy fill
	-- its window while Ping remained at zero.
	Ping:ZoneChanged()
	Ping.detectionHealthTimer = Ping:ScheduleTimer("EnsureDetectionActive", 2)
--	Ping:RefreshCurrentList()
end

function Ping:OnDisable()
	if not Ping.RuntimeEnabled then
		return
	end
	if Ping.timeid then
		Ping:CancelTimer(Ping.timeid)
		Ping.timeid = nil
	end
	if Ping.cooldownTimer then
		Ping:CancelTimer(Ping.cooldownTimer)
		Ping.cooldownTimer = nil
	end
	Ping:UnregisterEvent("ZONE_CHANGED")
	Ping:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
	Ping:UnregisterEvent("ZONE_CHANGED_INDOORS")
	Ping:UnregisterEvent("PLAYER_ENTERING_WORLD")
	Ping:UnregisterEvent("UNIT_FACTION")
	Ping:UnregisterEvent("PLAYER_TARGET_CHANGED")
	Ping:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
	Ping:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	Ping:UnregisterEvent("PLAYER_REGEN_ENABLED")
	Ping:UnregisterEvent("PLAYER_DEAD")
	Ping:UnregisterEvent("CHAT_MSG_CHANNEL_NOTICE")
	Ping:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
	Ping:UnregisterEvent("NAME_PLATE_UNIT_REMOVED")
	Ping:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	Ping:UnregisterComm(Ping.Signature)
	Ping.RuntimeEnabled = false
end

function Ping:EnablePing(value, changeDisplay, hideEnabledMessage)
	Ping.db.profile.Enabled = value
	if value then
		if changeDisplay and not InCombatLockdown() then
			Ping.MainWindow:Show()
		end
		Ping:OnEnable()
		if not hideEnabledMessage then
			DEFAULT_CHAT_FRAME:AddMessage(L["PingEnabled"])
		end
	else
		if changeDisplay and not InCombatLockdown() then
			Ping.MainWindow:Hide()
		end
		Ping:OnDisable()
		DEFAULT_CHAT_FRAME:AddMessage(L["PingDisabled"])
	end
end

function Ping:EnableSound(value)
	Ping.db.profile.EnableSound = value
	if value then
		DEFAULT_CHAT_FRAME:AddMessage(L["SoundEnabled"]) 
	else
		DEFAULT_CHAT_FRAME:AddMessage(L["SoundDisabled"])
	end
end

-- Re-checks the critical runtime pieces after login/reload and processes enemy
-- unit tokens that already existed before Ping registered its events. This is a
-- guarded recovery path, not a second detector; normal events remain primary.
function Ping:EnsureDetectionActive()
	if not Ping.db or Ping.db.profile.Enabled == false then return end
	-- CallbackHandler safely replaces an existing registration for this object,
	-- so re-registering these critical events is both compatible with the older
	-- bundled AceEvent and idempotent.
	Ping:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "CombatLogEvent")
	Ping:RegisterEvent("NAME_PLATE_UNIT_ADDED", "NamePlateEvent")
	Ping:RegisterEvent("PLAYER_TARGET_CHANGED", "PlayerTargetEvent")
	if not Ping.timeid then Ping.timeid = Ping:ScheduleRepeatingTimer("ManageExpirations", 10, true) end
	if not Ping.cooldownTimer then Ping.cooldownTimer = Ping:ScheduleRepeatingTimer("TickCooldowns", 1) end
	Ping:ZoneChanged()
	Ping:ScanVisibleEnemies()
end

function Ping:ScanVisibleEnemies()
	if not Ping.EnabledInZone then return end
	Ping:PlayerTargetEvent()
	Ping:PlayerMouseoverEvent()
	if C_NamePlate and C_NamePlate.GetNamePlates then
		for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
			local unit = plate.namePlateUnitToken
			if unit then Ping:NamePlateEvent(nil, unit) end
		end
	end
end

function Ping:OnInitialize()
--	WorldMapFrame:Show()
--	WorldMapFrame:Hide()

	Ping.RealmName = GetRealmName()
    Ping.FactionName = select(1, UnitFactionGroup("player"))
	if Ping.FactionName == "Alliance" then
		Ping.EnemyFactionName = "Horde"
	elseif Ping.FactionName == "Horde" then
		Ping.EnemyFactionName = "Alliance"
	else
		Ping.EnemyFactionName = "None"
	end
	Ping.CharacterName = UnitName("player")

	Ping.ValidClasses = {
		["DRUID"] = true,
		["HUNTER"] = true,
		["MAGE"] = true,
		["PALADIN"] = true,
		["PRIEST"] = true,
		["ROGUE"] = true,
		["SHAMAN"] = true,
		["WARLOCK"] = true,
		["WARRIOR"] = true,
--		["DEATHKNIGHT"] = true,
--		["MONK"] = true,
--		["DEMONHUNTER"] = true,
--		["EVOKER"] = true,
	}

	Ping.ValidRaces = {
		["Human"] = true,
		["Orc"] = true,
		["Dwarf"] = true,
		["Tauren"] = true,
		["Troll"] = true,
		["NightElf"] = true,
		["Scourge"] = true,
		["Gnome"] = true,
		["BloodElf"] = true,
		["Draenei"] = true,
--		["Goblin"] = true,
--		["Worgen"] = true,
--		["Pandaren"] = true,
--		["HighmountainTauren"] = true,
--		["LightforgedDraenei"] = true,
--		["Nightborne"] = true,
--		["VoidElf"] = true,
--		["DarkIronDwarf"] = true,
--		["MagharOrc"] = true,
--		["KulTiran"] = true,
--		["ZandalariTroll"] = true,
--		["Mechagnome"] = true,
--		["Vulpera"] = true,
--		["Dracthyr"] = true,
--		["Earthen"] = true,
	}

	local acedb = LibStub:GetLibrary("AceDB-3.0")

	Ping.db = acedb:New("PingDB", Default_Profile)
	Ping:CheckDatabase()
	Ping:CreateMinimapButton()

--	self.db.RegisterCallback(self, "OnNewProfile", "ResetProfile")
	self.db.RegisterCallback(self, "OnNewProfile", "HandleProfileChanges")
--	self.db.RegisterCallback(self, "OnProfileReset", "ResetProfile")
	self.db.RegisterCallback(self, "OnProfileReset", "HandleProfileChanges")
	self.db.RegisterCallback(self, "OnProfileChanged", "HandleProfileChanges")
	self.db.RegisterCallback(self, "OnProfileCopied", "HandleProfileChanges")
	self:SetupOptions()

	PingTempTooltip = CreateFrame("GameTooltip", "PingTempTooltip", nil, "GameTooltipTemplate")
	PingTempTooltip:SetOwner(UIParent, "ANCHOR_NONE")

	Ping:RegenerateKOSGuildList()
	if Ping.db.profile.ShareKOSBetweenCharacters then
		Ping:RemoveLocalKOSPlayers()
		Ping:RegenerateKOSCentralList()
		Ping:RegenerateKOSListFromCentral()
	end
	Ping:PurgeUndetectedData()
	Ping:CreateMainWindow()
	Ping:CreateKoSButton()
	Ping:UpdateTimeoutSettings()

	SM.RegisterCallback(Ping, "LibSharedMedia_Registered", "UpdateBarTextures")
	SM.RegisterCallback(Ping, "LibSharedMedia_SetGlobal", "UpdateBarTextures")
	if Ping.db.profile.BarTexture then
		Ping:SetBarTextures(Ping.db.profile.BarTexture)
	end

	Ping:LockWindows(Ping.db.profile.Locked)
	Ping:ClampToScreen(Ping.db.profile.ClampToScreen)	
	ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", Ping.FilterNotInParty)
	Ping.WoWBuildInfo = select(4, GetBuildInfo())
	if Ping.WoWBuildInfo < 20000 or Ping.WoWBuildInfo > 30000 then
		DEFAULT_CHAT_FRAME:AddMessage(L["VersionCheck"])
	end
end

function Ping:ChannelNoticeEvent(_, chStatus, _, _, Channel)
	if chStatus ~= "SUSPENDED" then
		Ping.ChnlTime = time()
		local channel, zone = string.match(Channel, "(.+) %- (.+)")
--		local subZone = GetSubZoneText()
		local InFilteredZone = Ping:InFilteredZone(zone)
		if InFilteredZone then
			Ping.EnabledInZone = false
		end
	end
end

function Ping:PlayerEnteringWorldEvent()
	local now = time()
	Ping:ZoneChanged()
	if Ping.ChnlTime > (now - 6) then
		self:ScheduleTimer("PlayerEnteringWorldEvent",6)
	end
end

function Ping:ZoneChangedEvent()
	local now = time()
	Ping:ZoneChanged()
	if Ping.ChnlTime > (now - 6) then
		self:ScheduleTimer("ZoneChangedEvent",6)
	end
end

function Ping:ZoneChangedNewAreaEvent()
	local now = time()
	Ping:ZoneChanged()
	if Ping.ChnlTime > (now - 6) then
		self:ScheduleTimer("ZoneChangedNewAreaEvent",6)
	end
end

function Ping:ZoneChanged()
	Ping.InInstance = false
	local pvpType = GetZonePVPInfo()
 	local zone = GetZoneText()
	local subZone = GetSubZoneText()
	local InFilteredZone = Ping:InFilteredZone(zone, subZone)
	if pvpType == "sanctuary" and not Ping.db.profile.EnabledInSanctuaries then
		Ping.EnabledInZone = false
	else
		Ping.EnabledInZone = true
		if zone == "" or InFilteredZone then
			Ping.EnabledInZone = false
		else
			Ping.EnabledInZone = true
		local inInstance, instanceType = IsInInstance()
		if inInstance then
			Ping.InInstance = true
			if instanceType == "party" or instanceType == "raid" or (not Ping.db.profile.EnabledInBattlegrounds and instanceType == "pvp") or (not Ping.db.profile.EnabledInArenas and instanceType == "arena") then
				Ping.EnabledInZone = false
			end
		elseif pvpType == "combat" then
			if not Ping.db.profile.EnabledInWintergrasp then
				Ping.EnabledInZone = false
			end
--		elseif (pvpType == "friendly" or pvpType == nil) then
			elseif UnitIsPVP("player") == false and Ping.db.profile.DisableWhenPVPUnflagged then
				Ping.EnabledInZone = false
--				end
			end
		end
	end

	if Ping.EnabledInZone then
		if not Ping.db.profile.HidePing then
			if not InCombatLockdown() then Ping.MainWindow:Show() end
			Ping:RefreshCurrentList()
		end
		Ping:ScanVisibleEnemies()
	else
		if not InCombatLockdown() then Ping.MainWindow:Hide() end
	end
	Ping:UpdateMainWindow()
end

function Ping:InFilteredZone(zone, subzone)
	local InFilteredZone = false
	for filteredZone, value in pairs(Ping.db.profile.FilteredZones) do
		if zone == filteredZone and value then
			InFilteredZone = true
		elseif subzone == filteredZone and value then
			InFilteredZone = true
--			break
		end
	end
	return InFilteredZone
end

function Ping:PlayerTargetEvent()
	local name = GetUnitName("target", true)
	if name and UnitIsPlayer("target") and not PingPerCharDB.IgnoreData[name] then
		local playerData = PingPerCharDB.PlayerData[name]
		if UnitIsEnemy("player", "target") then
			name = string.gsub(name, " %- ", "-")

			local learnt = true
			if playerData and playerData.isGuess == false then learnt = false end

			local x, class = UnitClass("target")
			local race = select(1,UnitRace("target"))
			local level = tonumber(UnitLevel("target"))
			local guild = GetGuildInfo("target")
			local faction = select(1,UnitFactionGroup("target"))
			local guess = false
			if level == Ping.Skull then
				if playerData and playerData.level then
					if playerData.level > (UnitLevel("player") + 10) and playerData.level < Ping.MaximumPlayerLevel then	
						guess = true
						level = nil
					elseif UnitLevel("player") < Ping.MaximumPlayerLevel - 9 then
						guess = true
						level = UnitLevel("player") + 10
					end	
				else
					guess = true
					level = UnitLevel("player") + 10
				end
--			else
--				guess = true
--				level = nil
			end
			
			Ping:UpdatePlayerData(name, class, level, race, guild, faction, true, guess)
			if Ping.EnabledInZone then
				Ping:AddDetected(name, time(), learnt)
			end
		elseif playerData then
			Ping:RemovePlayerData(name)
		end
	end
end

function Ping:PlayerMouseoverEvent()
	local name = GetUnitName("mouseover", true)
	if name and UnitIsPlayer("mouseover") and not PingPerCharDB.IgnoreData[name] then
		local playerData = PingPerCharDB.PlayerData[name]
		if UnitIsEnemy("player", "mouseover") then
			name = string.gsub(name, " %- ", "-")

			local learnt = true
			if playerData and playerData.isGuess == false then learnt = false end

			local x, class = UnitClass("mouseover")
			local race = select(1,UnitRace("mouseover"))
			local level = tonumber(UnitLevel("mouseover"))
			local guild = GetGuildInfo("mouseover")
			local faction = select(1,UnitFactionGroup("mouseover"))
			local guess = false
			if level == Ping.Skull then
				if playerData and playerData.level then
					if playerData.level > (UnitLevel("player") + 10) and playerData.level < Ping.MaximumPlayerLevel then	
						guess = true
						level = nil
					elseif UnitLevel("player") < Ping.MaximumPlayerLevel - 9 then
						guess = true
						level = UnitLevel("player") + 10
					end	
				else
					guess = true
					level = UnitLevel("player") + 10
				end
--			else
--				guess = true
--				level = nil
			end

			Ping:UpdatePlayerData(name, class, level, race, guild, faction, true, guess)
			if Ping.EnabledInZone then
				Ping:AddDetected(name, time(), learnt)
			end
		elseif playerData then 
			Ping:RemovePlayerData(name)
		end
	end
end

function Ping:NamePlateEvent(_, unit)
	local name = GetUnitName(unit, true)
	if name and UnitIsPlayer(unit) and not PingPerCharDB.IgnoreData[name] then
		local playerData = PingPerCharDB.PlayerData[name]
		if UnitIsEnemy("player", unit) then
			name = string.gsub(name, " %- ", "-")

			local learnt = true
			if playerData and playerData.isGuess == false then learnt = false end

			local x, class = UnitClass(unit)
			local race = select(1,UnitRace(unit))
			local level = tonumber(UnitLevel(unit))
			local guild = GetGuildInfo(unit)
			local faction = select(1,UnitFactionGroup(unit))
			local guess = false
			if level == Ping.Skull then
				if playerData and playerData.level then
					if playerData.level > (UnitLevel("player") + 10) and playerData.level < Ping.MaximumPlayerLevel then	
						guess = true
						level = nil
					elseif UnitLevel("player") < Ping.MaximumPlayerLevel - 9 then
						guess = true
						level = UnitLevel("player") + 10
					end	
				else
					guess = true
					level = UnitLevel("player") + 10
				end
--			else
--				guess = true
--				level = nil
			end

			Ping:UpdatePlayerData(name, class, level, race, guild, faction, true, guess)
			if Ping.EnabledInZone then
				Ping:AddDetected(name, time(), learnt)
			end
		elseif playerData then 
			Ping:RemovePlayerData(name)
		end
	end
end

-- ============================================================
-- Enemy defensive cooldown tracking.
--
-- The PvP trinket and the big immunities never appear in COMBAT_LOG_EVENT_
-- UNFILTERED - verified against a full session capture, zero hits in ~4000
-- events. They DO fire UNIT_SPELLCAST_SUCCEEDED on any unit we have a token
-- for (target / focus / nameplate), which is how this is caught.
-- ============================================================
Ping.TrackedCooldowns = {
	[42292] = { name = "PvP Trinket", cd = 120, short = "Trink" },	-- Insignia / Medallion
	[7744]  = { name = "Will of the Forsaken", cd = 120, short = "WotF" },
	[20594] = { name = "Stoneform", cd = 180, short = "Stone" },
	[642]   = { name = "Divine Shield", cd = 300, short = "Bubble" },
	[1022]  = { name = "Blessing of Protection", cd = 300, short = "BoP" },
	[45438] = { name = "Ice Block", cd = 300, short = "Block" },
	[31224] = { name = "Cloak of Shadows", cd = 60, short = "Cloak" },
	[5277]  = { name = "Evasion", cd = 300, short = "Evade" },
	[871]   = { name = "Shield Wall", cd = 1800, short = "SWall" },
	[19752] = { name = "Divine Intervention", cd = 3600, short = "DI" },
}

-- The base table above is a fixed list, and asking for it to grow every time
-- someone wants one more spell watched is how it would end up either bloated
-- with rarely-wanted entries or permanently missing somebody's. Extra entries
-- live in a separate profile text list instead and are merged into this lookup
-- at runtime - the table actually read by UnitSpellcastEvent never mutates the
-- base list, so a bad user entry can't corrupt the built-in one.
Ping.CooldownLookup = {}
Ping.CooldownListAdded = 0
Ping.CooldownListUnresolved = 0

-- The cooldown length cannot be observed for an enemy the way it can for our
-- own bars - there is no "how long until their trinket is back up" API - so a
-- watched spell needs a duration from somewhere. GetSpellBaseCooldown reads the
-- spell's own static template data, which works for ANY spell id regardless of
-- whether we know it, unlike the runtime cooldown APIs which only answer for
-- spells in our own spellbook.
local function resolveCooldownSeconds(id)
	if GetSpellBaseCooldown then
		local ok, ms = pcall(GetSpellBaseCooldown, id)
		if ok and type(ms) == "number" and ms > 0 then
			return math.floor(ms / 1000 + 0.5)
		end
	end
	if C_Spell and C_Spell.GetSpellCooldown then
		local ok, info = pcall(C_Spell.GetSpellCooldown, id)
		if ok and type(info) == "table" and type(info.duration) == "number" and info.duration > 0 then
			return math.floor(info.duration + 0.5)
		end
	end
	return nil
end

-- Seeded text form of the defaults above: one spell id per line with the name
-- and cooldown as a trailing comment, so the list is READABLE rather than a
-- column of bare numbers. Only the leading number is parsed - everything after
-- it is ignored - so the comment can be edited or dropped freely.
local defaultCooldownListTextCache = nil

local function defaultCooldownListText()
	if defaultCooldownListTextCache then return defaultCooldownListTextCache end
	local ids = {}
	for id in pairs(Ping.TrackedCooldowns) do ids[#ids + 1] = id end
	-- Sorted by cooldown length then name, so the list reads in a stable order
	-- rather than pairs() order, which differs between sessions.
	table.sort(ids, function(a, b)
		local ia, ib = Ping.TrackedCooldowns[a], Ping.TrackedCooldowns[b]
		if ia.cd ~= ib.cd then return ia.cd < ib.cd end
		return ia.name < ib.name
	end)
	local lines = {}
	for _, id in ipairs(ids) do
		local info = Ping.TrackedCooldowns[id]
		local mins = info.cd / 60
		local pretty = (mins >= 1) and (format("%gm", mins)) or (format("%ds", info.cd))
		lines[#lines + 1] = format("%s (%d) = %d  -- %s", info.name, id, info.cd, pretty)
	end
	defaultCooldownListTextCache = table.concat(lines, "\n")
	return defaultCooldownListTextCache
end

-- Every watched spell comes from the profile's list - there is no hidden set
-- running underneath it. Deleting a line genuinely stops that cooldown being
-- tracked, which is the whole point of showing the list instead of describing
-- it. TrackedCooldowns is now only reference data: the researched durations for
-- the spells Ping ships with, used when the client cannot supply one.
--
-- A line needs a resolvable spell id, unlike the healer list which matches on
-- name: UnitSpellcastEvent is handed the numeric id by
-- UNIT_SPELLCAST_SUCCEEDED, so a bare name could never match. Unresolvable
-- lines are counted and surfaced rather than silently ignored.
function Ping:BuildCooldownLookup()
	wipe(Ping.CooldownLookup)
	local p = Ping.db and Ping.db.profile
	if not p then return end
	if not p.CooldownListSeeded then
		p.CooldownListText = defaultCooldownListText()
		p.CooldownListSeeded = true
		-- Carry over anything the old extras-only box held (see the profile
		-- migration), now that there is a full list to append it to.
		if p.pendingExtraCooldowns and p.pendingExtraCooldowns ~= "" then
			p.CooldownListText = p.CooldownListText .. "\n" .. p.pendingExtraCooldowns
			p.pendingExtraCooldowns = nil
		end
	end
	local unresolved = 0
	for line in (p.CooldownListText or ""):gmatch("[^\n]+") do
		local trimmed = line:gsub("^%s+", ""):gsub("%s+$", "")
		if trimmed ~= "" and trimmed:sub(1, 2) ~= "--" then
			local id = tonumber(trimmed:match("spell:(%d+)")) or tonumber(trimmed:match("%((%d+)%)")) or tonumber(trimmed:match("^(%d+)"))
			if id then
				local known = Ping.TrackedCooldowns[id]
				local explicitDuration = tonumber(trimmed:match("=%s*(%d+)"))
				if known and not explicitDuration then
					Ping.CooldownLookup[id] = known
				else
					local ok, name = pcall(GetSpellInfo, id)
					name = (ok and type(name) == "string" and name ~= "") and name or (known and known.name) or ("Spell "..id)
					Ping.CooldownLookup[id] = {
						name = name,
						cd = explicitDuration or (known and known.cd) or resolveCooldownSeconds(id) or 120,
						short = (#name <= 6) and name or name:sub(1, 6),
					}
				end
			else
				unresolved = unresolved + 1
			end
		end
	end
	Ping.CooldownListUnresolved = unresolved
end

-- Restores the ten researched defaults, discarding any edits.
function Ping:ResetCooldownList()
	Ping.db.profile.CooldownListText = defaultCooldownListText()
	Ping.db.profile.CooldownListSeeded = true
	Ping:BuildCooldownLookup()
end

function Ping:RecordCooldownUse(name, spellId)
	if not Ping.db.profile.TrackCooldowns then return end
	if not name or not spellId then return end
	local info = Ping.CooldownLookup[spellId]
	if not info then return end
	local playerData = PingPerCharDB.PlayerData[name]
	if not playerData then return end
	local now = GetTime()
	if playerData.cdSpellId == spellId and playerData.cdUsed and (now - playerData.cdUsed) < 0.5 then return end

	playerData.cdSpell = info.short
	playerData.cdName = info.name
	playerData.cdSpellId = spellId
	playerData.cdUsed = now
	playerData.cdExpires = now + info.cd
	Ping:RecordEncounter("cooldown", name, info.name)

	if Ping.db.profile.AnnounceCooldowns then
		DEFAULT_CHAT_FRAME:AddMessage(format(L["CooldownUsed"], name, info.name))
	end
	Ping:RefreshCurrentList()
end

-- Redraws the list once per second while any displayed enemy has a cooldown
-- running, so the countdown actually ticks. No-op the rest of the time.
function Ping:TickCooldowns()
	if not Ping.db.profile.TrackCooldowns then return end
	if not Ping.MainWindow or not Ping.MainWindow:IsShown() then return end
	local active = false
	for i = 1, (Ping.ListAmountDisplayed or 0) do
		local name = Ping.ButtonName[i]
		local playerData = name and PingPerCharDB.PlayerData[name]
		if playerData and playerData.cdExpires then
			if playerData.cdExpires > GetTime() then
				active = true
				break
			else
				playerData.cdExpires = nil
				playerData.cdSpell = nil
				active = true	-- one final redraw to clear the stale text
				break
			end
		end
	end
	if active then Ping:RefreshCurrentList() end
end

-- Remaining seconds on a tracked enemy cooldown, or nil when nothing is active.
function Ping:GetCooldownRemaining(playerData)
	if not playerData or not playerData.cdExpires then return nil end
	local left = playerData.cdExpires - GetTime()
	if left <= 0 then return nil end
	return left, playerData.cdSpell
end

-- ============================================================
-- Zone level floors.
--
-- Ping guesses levels from which spells it has seen an enemy cast, which
-- produces nonsense in Outland: a capture of two sessions there had EVERY
-- hostile at level 70, while Ping was displaying "16+" and "30+". Nobody can
-- reach these zones below the entry level, so a guessed level is clamped to
-- the minimum for the zone it was seen in. Keyed by UiMapID rather than zone
-- name so it works in every locale.
-- ============================================================
-- The CONTINENT floor is the one that does the work, and it is keyed by
-- instanceID - the map file's own id, which is the same number on retail, on
-- Classic and in every locale. Reaching Outland at all requires the Dark Portal,
-- so nothing standing there is level 11 whatever the guess says.
--
-- This replaces a per-zone table keyed by UiMapID that never once matched:
-- those were the RETAIL ids (Terokkar 108), and this client reports 1952. The
-- floor silently did nothing, which is why the level guesses stayed bad after
-- being "fixed". Per-zone refinement lives below and is now a bonus rather than
-- the mechanism.
Ping.ContinentLevelFloor = {
	[530] = 58,	-- Outland - Dark Portal, so Hellfire's entry level
	[571] = 68,	-- Northrend, harmless here and correct if ever used
}

-- Per-zone refinement, keyed by UiMapID. Both id spaces are listed because the
-- same addon runs on both, and a wrong floor is worse than no floor - so only
-- ids that have been confirmed against a real client are here. Anything absent
-- falls back to the continent floor above.
Ping.ZoneLevelFloor = {
	-- TBC Classic (2.5.x). Confirmed from a live client:
	[1952] = 62,	-- Terokkar Forest
	-- Retail, for the same zones:
	[100] = 58,	-- Hellfire Peninsula
	[102] = 60,	-- Zangarmarsh
	[104] = 67,	-- Shadowmoon Valley
	[105] = 65,	-- Blade's Edge Mountains
	[107] = 64,	-- Nagrand
	[108] = 62,	-- Terokkar Forest
	[109] = 67,	-- Netherstorm
	[111] = 58,	-- Shattrath City
	[122] = 70,	-- Isle of Quel'Danas
}

-- Which continent the player is standing on, as an instanceID.
local function currentInstanceID()
	if not GetInstanceInfo then return nil end
	local ok, _, _, _, _, _, _, _, instanceID = pcall(GetInstanceInfo)
	return ok and instanceID or nil
end

-- Floor for a given map, or for where the player is standing when omitted.
-- Takes the higher of the zone floor and the continent floor, so a known zone
-- refines the continent rather than being overridden by it.
function Ping:GetZoneLevelFloor(mapID)
	if not Ping.db.profile.UseZoneLevelFloor then return nil end
	if not mapID and C_Map and C_Map.GetBestMapForUnit then
		mapID = C_Map.GetBestMapForUnit("player")
	end

	local floor = (type(mapID) == "number") and Ping.ZoneLevelFloor[mapID] or nil

	local instanceID = currentInstanceID()
	local continent = instanceID and Ping.ContinentLevelFloor[instanceID] or nil
	if continent and (not floor or continent > floor) then floor = continent end

	if floor and floor > Ping.MaximumPlayerLevel then floor = Ping.MaximumPlayerLevel end
	return floor
end

-- Applies the floor to a stored record. Only ever raises a GUESSED level -
-- a level read directly off a unit is authoritative and left alone.
-- knownMapID lets a caller pass the map it has already resolved, so a hot
-- detection path does not re-query C_Map for every single event.
function Ping:ApplyZoneLevelFloor(playerData, knownMapID)
	if not playerData or playerData.isGuess == false then return end
	-- mapID is only recorded on a first sighting where coordinates resolved, so
	-- it's nil for most records. Detection always happens near us, so fall back
	-- to the zone we're standing in.
	local floor = Ping:GetZoneLevelFloor(playerData.mapID or knownMapID)
	if not floor and playerData.mapID and knownMapID then
		floor = Ping:GetZoneLevelFloor(knownMapID)
	end
	if Ping.DebugZone then
		Ping:DebugZone(playerData.mapID or (C_Map and C_Map.GetBestMapForUnit
			and C_Map.GetBestMapForUnit("player")))
	end
	if not floor then return end
	local current = tonumber(playerData.level)
	if not current or current < floor then
		playerData.level = floor
	end
end

function Ping:UnitSpellcastEvent(_, unit, _, spellId)
	if not unit or not spellId then return end
	if not UnitExists(unit) or not UnitIsPlayer(unit) or not UnitCanAttack("player", unit) then return end
	local name = GetUnitName(unit, true)
	if not name then return end
	Ping:RecordCooldownUse(gsub(name, " %- ", "-"), spellId)
end

-- Heals that reach another player but say nothing about being a healer:
-- passive procs, leech/lifetap effects, pet upkeep, consumables and shadow
-- specs' party leech. Rule 1 (source ~= destination) already discards pure
-- self-healing; this list catches the rest.
-- ============================================================
-- What counts as a healer
--
-- The rule is a WHITELIST of real healing spells, not a blacklist of things to
-- ignore. A blacklist fails in the wrong direction: any spell nobody thought to
-- list marks its caster a healer, which is how a warlock draining life and a
-- draenei using Gift of the Naaru both ended up flagged. With a whitelist an
-- unrecognised spell simply proves nothing, and the list is finite because TBC
-- has four healing classes and a knowable set of heals.
--
-- Bandages, potions, food, healthstones, life leech, Judgement of Light, Leader
-- of the Pack and every other incidental heal are excluded for free by not being
-- on the list. Bandages matter in particular: First Aid can be used on another
-- player, so it beats the source-is-not-the-target rule.
--
-- Shipped as spell IDs, resolved to the client's own localised names, and used
-- to seed a single editable list the first time it's needed - not baked in as
-- read-only, because "did you get them all" has no permanent answer: a client
-- patch can add a spell, or the researched list can simply be wrong for someone.
-- One id per spell is enough - all ranks of a spell share a name.
-- ============================================================
local Ping_HealerSpellIDs = {
	-- Priest
	2050,	-- Lesser Heal
	2054,	-- Heal
	2060,	-- Greater Heal
	2061,	-- Flash Heal
	139,	-- Renew
	596,	-- Prayer of Healing
	33076,	-- Prayer of Mending
	34861,	-- Circle of Healing
	32546,	-- Binding Heal
	15237,	-- Holy Nova
	-- Paladin
	635,	-- Holy Light
	19750,	-- Flash of Light
	20473,	-- Holy Shock
	633,	-- Lay on Hands
	-- Druid
	5185,	-- Healing Touch
	8936,	-- Regrowth
	774,	-- Rejuvenation
	33763,	-- Lifebloom
	18562,	-- Swiftmend
	740,	-- Tranquility
	-- Shaman
	331,	-- Healing Wave
	8004,	-- Lesser Healing Wave
	1064,	-- Chain Heal
	974,	-- Earth Shield
}

-- Text form of the defaults above, one spell name per line - built once
-- GetSpellInfo can actually answer, and cached rather than recomputed, since
-- resolving 24 ids is wasted work on every reparse.
local defaultHealerListTextCache = nil

local function defaultHealerListText()
	if defaultHealerListTextCache then return defaultHealerListTextCache end
	if not GetSpellInfo then return "" end
	local names = {}
	for _, id in ipairs(Ping_HealerSpellIDs) do
		local ok, name = pcall(GetSpellInfo, id)
		if ok and type(name) == "string" and name ~= "" then
			names[#names + 1] = format("%s (%d)", name, id)
		end
	end
	table.sort(names)
	defaultHealerListTextCache = table.concat(names, "\n")
	return defaultHealerListTextCache
end

-- A line in the editable list is a plain spell name (what the seeded defaults
-- look like), a bare spell id, or a full spell link. Shift-clicking a spell or
-- spellbook entry into the box while it has keyboard focus inserts a link
-- automatically - the easiest way to add one Ping does not already know about,
-- since there is no in-game way to type an exact spell name from memory and be
-- sure it matches.
local function parseSpellListLine(line)
	line = line:gsub("^%s+", ""):gsub("%s+$", "")
	if line == "" or line:sub(1, 2) == "--" then return nil end
	local bracketed = line:match("%[([^%]]+)%]")
	if bracketed then return bracketed end
	local id = tonumber(line:match("spell:(%d+)")) or tonumber(line:match("%((%d+)%)")) or tonumber(line)
	if id and GetSpellInfo then
		local ok, name = pcall(GetSpellInfo, id)
		if ok and type(name) == "string" and name ~= "" then return name end
	end
	return line
end

-- name -> true, rebuilt from the profile's text list whenever it changes.
Ping.HealerSpellNames = {}
Ping.HealerSpellCount = 0

-- Early builds seeded this list as bare spell names, then set the seeded flag,
-- so those profiles never received the "Name (id)" format that replaced it.
-- Matching is by name and works either way, but with no id there is no icon and
-- no id to show, which is what the rows UI ends up drawing: a column of
-- question marks.
--
-- This adds the id back to any line whose name is one Ping ships with. Lines
-- that already carry an id, and anything the user added themselves, are left
-- exactly as they are.
local function upgradeHealerListIds(p)
	if p.HealerSpellListIdsUpgraded then return end
	if not p.HealerSpellListSeeded then return end	-- a fresh profile seeds with ids anyway
	if not GetSpellInfo then return end

	local idByName = {}
	local resolved = 0
	for _, id in ipairs(Ping_HealerSpellIDs) do
		local ok, name = pcall(GetSpellInfo, id)
		if ok and type(name) == "string" and name ~= "" then
			idByName[name] = id
			resolved = resolved + 1
		end
	end
	-- Called before the client can answer: leave the flag alone and try again
	-- on the next build rather than marking a profile upgraded that is not.
	if resolved == 0 then return end

	local lines, changed = {}, false
	for line in (p.HealerSpellListText or ""):gmatch("[^\n]+") do
		local trimmed = line:gsub("^%s+", ""):gsub("%s+$", "")
		local hasId = trimmed:match("spell:(%d+)") or trimmed:match("%((%d+)%)") or trimmed:match("^%d+$")
		local id = (not hasId) and idByName[trimmed] or nil
		if id then
			lines[#lines + 1] = format("%s (%d)", trimmed, id)
			changed = true
		else
			lines[#lines + 1] = line
		end
	end

	if changed then
		p.HealerSpellListText = table.concat(lines, "\n")
	end
	p.HealerSpellListIdsUpgraded = true
end

function Ping:BuildHealerSpellNames()
	local p = Ping.db and Ping.db.profile
	if not p then return 0 end
	if not p.HealerSpellListSeeded then
		p.HealerSpellListText = defaultHealerListText()
		p.HealerSpellListSeeded = true
		p.HealerSpellListIdsUpgraded = true
	else
		upgradeHealerListIds(p)
	end
	wipe(Ping.HealerSpellNames)
	local n = 0
	for line in (p.HealerSpellListText or ""):gmatch("[^\n]+") do
		local name = parseSpellListLine(line)
		if name and not Ping.HealerSpellNames[name] then
			Ping.HealerSpellNames[name] = true
			n = n + 1
		end
	end
	Ping.HealerSpellCount = n
	return n
end

-- Restores the researched TBC list, discarding any edits.
function Ping:ResetHealerSpellList()
	Ping.db.profile.HealerSpellListText = defaultHealerListText()
	Ping.db.profile.HealerSpellListSeeded = true
	Ping.db.profile.HealerSpellListIdsUpgraded = true
	Ping:BuildHealerSpellNames()
end

-- Only these four classes can actually heal another player as a role. Used as a
-- second gate when the class is known - the spell alone already implies it, but
-- a contradiction means we misidentified somebody and should not mark them.
local Ping_HealerCapableClasses = {
	DRUID = true, PALADIN = true, PRIEST = true, SHAMAN = true,
}

-- True when this heal is evidence of a healer rather than incidental healing.
function Ping:IsHealerEvidence(spellName, class)
	if Ping.db.profile.StrictHealerDetection ~= false then
		-- If the whitelist is empty - never built, or the user cleared it on
		-- purpose - fall back to the old exclusion list rather than detecting
		-- nobody at all.
		if (Ping.HealerSpellCount or 0) > 0 then
			if not Ping.HealerSpellNames[spellName] then return false end
			if class and not Ping_HealerCapableClasses[class] then return false end
			return true
		end
	end
	return not Ping_NonHealerHeals[spellName]
end

local Ping_NonHealerHeals = {
	-- warlock leech / pet
	["Death Coil"] = true, ["Drain Life"] = true, ["Siphon Life"] = true,
	["Health Funnel"] = true, ["Fel Armor"] = true, ["Healthstone"] = true,
	["Master Healthstone"] = true, ["Major Healthstone"] = true,
	-- warrior / melee self-sustain
	["Bloodthirst"] = true, ["Blood Craze"] = true, ["Second Wind"] = true,
	["Victory Rush"] = true, ["Enraged Regeneration"] = true,
	-- passive party procs (not healing output)
	["Improved Leader of the Pack"] = true, ["Leader of the Pack"] = true,
	["Blessed Recovery"] = true, ["Spirit Bond"] = true, ["Mend Pet"] = true,
	["Judgement of Light"] = true, ["Seal of Light"] = true, ["Mercy"] = true,
	["Holy Concentration"] = true, ["Vampiric Embrace"] = true,
	["Improved Vampiric Embrace"] = true, ["Vampiric Touch"] = true,
	["Blood Pact"] = true, ["Twin Empathy"] = true,
	-- racials: any class can have these, so they prove nothing about role
	["Gift of the Naaru"] = true, ["Cannibalize"] = true,
	-- consumables / non-class healing
	["First Aid"] = true, ["Healing Potion"] = true, ["Super Healing Potion"] = true,
	["Major Healing Potion"] = true, ["Heavy Netherweave Bandage"] = true,
	["Netherweave Bandage"] = true, ["Heavy Runecloth Bandage"] = true,
	["Runecloth Bandage"] = true, ["Whipper Root Tuber"] = true,
	["Nightmare Seed"] = true, ["Lifegiving Gem"] = true,
	-- environment / misc
	["Drain Soul"] = true, ["Consume Magic"] = true,
}

-- Defined once at file scope rather than rebuilt on every combat-log event
-- (this fires many times per second in a crowd). Used only to gate the
-- pet-kill win-tracking below.
local Ping_CombatEvents = {
	["SWING_DAMAGE"] = true,
	["RANGE_DAMAGE"] = true,
	["SPELL_DAMAGE"] = true,
	["SPELL_PERIODIC_DAMAGE"] = true,
}

function Ping:CombatLogEvent(info, timestamp, event, hideCaster, srcGUID, srcName, srcFlags, sourceRaidFlags, dstGUID, dstName, dstFlags, destRaidFlags, ...)
-- arg12..arg16 were globals, written on EVERY combat log event - the hottest
-- path in the addon - and Spy writes globals of the same name. Every use is
-- inside this function, so they are locals now.
local arg12, arg13, arg14, arg15, arg16
timestamp, event, hideCaster, srcGUID, srcName, srcFlags, sourceRaidFlags, dstGUID, dstName, dstFlags, destRaidFlags, arg12, arg13, arg14, arg15, arg16 = CombatLogGetCurrentEventInfo()
	if Ping.EnabledInZone then

		--PetKill code start
		local spellID, spellName, spellSchool, amount, overkill
		local petName = UnitName("pet"); 
		local _, overkill 	
		overkill = 0;		--PetKill code end
	
		-- analyse the source unit
		if bit.band(srcFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE and srcGUID and srcName and not PingPerCharDB.IgnoreData[srcName] then
			local srcType = strsub(srcGUID, 1,6)
				if srcType == "Player" then
				local _, class, race, raceFile, _, name = GetPlayerInfoByGUID(srcGUID)
				if not Ping.ValidClasses[class] then
					class = nil
				end	
				if not Ping.ValidRaces[raceFile] then
					race = nil
				end
				local learnt = false
				local detected = true
				local playerData = PingPerCharDB.PlayerData[srcName]
				if not playerData or playerData.isGuess then
					learnt, playerData = Ping:ParseUnitAbility(true, event, srcName, class, race, arg12, arg13)
				end
				if not learnt then
					detected = Ping:UpdatePlayerData(srcName, class, nil, race, nil, nil, true, nil)
				end

					if detected then
						Ping:AddDetected(srcName, timestamp, learnt)
						if event == "SPELL_CAST_SUCCESS" then Ping:RecordCooldownUse(srcName, arg12) end
						if event == "SPELL_AURA_APPLIED" and (arg13 == L["Stealth"]) then
							Ping:RecordEncounter("stealth", srcName, arg13)
							Ping:AlertStealthPlayer(srcName)
						end	
						if event == "SPELL_AURA_APPLIED" and (arg13 == L["Prowl"]) then
							Ping:RecordEncounter("stealth", srcName, arg13)
							Ping:AlertProwlPlayer(srcName)
					end
				end
			end

			if dstGUID == UnitGUID("player") then
				Ping:RecordEncounter("attacked", srcName, arg13)
				Ping.LastAttack = srcName
				Ping.LastAttackTime = GetTime()
--				print(Ping.LastAttackTime, " ", Ping.LastAttack)
			end
		end

		-- analyse the destination unit
		if bit.band(dstFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE and dstGUID and dstName and not PingPerCharDB.IgnoreData[dstName] then
			local dstType = strsub(dstGUID, 1,6)
			if dstType == "Player" then
				local _, class, race, raceFile, _, name = GetPlayerInfoByGUID(dstGUID)
				if not Ping.ValidClasses[class] then
					class = nil
				end	
				if not Ping.ValidRaces[raceFile] then
					race = nil
				end				
				local learnt = false
				local detected = true
				local playerData = PingPerCharDB.PlayerData[dstName]
				if not playerData or playerData.isGuess then
					learnt, playerData = Ping:ParseUnitAbility(false, event, dstName, class, race, arg12, arg13)
				end
				if not learnt then
					detected = Ping:UpdatePlayerData(dstName, class, nil, race, nil, nil, true, nil)
				end
				if detected then
					Ping:AddDetected(dstName, timestamp, learnt)
				end
			end
		end

		-- CONFIRMED healer detection.
		--
		-- A healer is someone who heals OTHER PLAYERS. Almost every class has
		-- self-healing that fires the same SPELL_HEAL event - warlock Death
		-- Coil / Drain Life / Siphon Life, warrior Bloodthirst / Blood Craze /
		-- Second Wind, bandages, potions, healthstones - so counting raw heal
		-- events marks half the server as healers. Three rules keep it honest:
		--   1. source ~= destination  (self-healing and lifesteal never count)
		--   2. both source and destination are players (not pets or totems)
		--   3. the spell isn't a known non-healer proc/leech/pet heal
		if event == "SPELL_HEAL" or event == "SPELL_PERIODIC_HEAL" then
			if srcGUID and srcName and dstGUID
				and strsub(srcGUID, 1, 6) == "Player"
				and strsub(dstGUID, 1, 6) == "Player"
				and srcGUID ~= dstGUID
				and bit.band(srcFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE then
				local amount = arg15
				if type(amount) == "number" and amount > 0 then
					local playerData = PingPerCharDB.PlayerData[srcName]
					if playerData and Ping:IsHealerEvidence(arg13, playerData.class) then
						playerData.healTotal = (playerData.healTotal or 0) + amount
						playerData.healCount = (playerData.healCount or 0) + 1
						playerData.lastHeal = time()
						-- meaningful = a big single heal, or sustained healing
						local big = amount >= (Ping.db.profile.HealerMinHeal or 400)
						local enough = playerData.healCount >= (Ping.db.profile.HealerMinHeals or 2)
							if (big or enough) and not playerData.isHealer then
								playerData.isHealer = true
								Ping:RecordEncounter("healer", srcName, arg13)
							if Ping.db.profile.MarkHealers then Ping:RefreshCurrentList() end
							Ping:UpdateActiveCount()
						end
					end
				end
			end
		end

		-- update win stats
		if event == "PARTY_KILL" then
			if srcGUID == UnitGUID("player") and dstName then
				local playerData = PingPerCharDB.PlayerData[dstName]
				if playerData then
					if not playerData.wins then
						playerData.wins = 0
					end
						playerData.wins = playerData.wins + 1
						Ping:RecordEncounter("killed", dstName)
				end
			end
		end

		-- adds pet kills to the win stats
		if Ping_CombatEvents[event] then
			if event == "SWING_DAMAGE" then
				if arg13 == nil then
					overkill = 0
				else
					overkill = arg13
				end
			else
				if arg16 == nil then
					overkill = 0
				else
					overkill = arg16
				end
			end
			if (overkill > 1) and dstName then
				if Ping.PetGUID[srcGUID] then
					local playerData = PingPerCharDB.PlayerData[dstName]
					if playerData then
						if not playerData.wins then playerData.wins = 0 end
							playerData.wins = playerData.wins + 1
--							PlaySoundFile("Interface\\AddOns\\Ping\\Sounds\\neck-snap.mp3", Ping.db.profile.SoundChannel)
--							DEFAULT_CHAT_FRAME:AddMessage("Your pet/guardian killed " .. dstName);
					end
				end
			end
		end
		if event == "SPELL_SUMMON" and srcName == Ping.CharacterName then
			local petGUID = dstGUID
			Ping.PetGUID[petGUID] = time()
		end
		if event == "ENVIRONMENTAL_DAMAGE" and dstGUID == UnitGUID("player") then
			local environmentalType = arg12
			local amount = arg13
			Ping.LastAttack = nil		
--			print(timestamp, "Ouch ", environmentalType, amount, " hurts!")
		end		
	end
end

function Ping:LeftCombatEvent()
	Ping.LastAttack = nil
	Ping:RefreshCurrentList()
end

function Ping:PlayerDeadEvent()
	if Ping.LastAttack then
		local timeDiff = GetTime() - Ping.LastAttackTime
		if (timeDiff < .5 ) then
--			print("Killed by ", Ping.LastAttack, " ", timeDiff, " seconds ago")
			local playerData = PingPerCharDB.PlayerData[Ping.LastAttack]
			if playerData then
				if not playerData.loses then
					playerData.loses = 0
				end
					playerData.loses = playerData.loses + 1
					Ping:RecordEncounter("killed_by", Ping.LastAttack)
			end
		end
	end
end

function Ping:UnitPets(event, unit)
	local petUnit
	if unit == "player" then
		petUnit = "pet"
	end
	if petUnit and UnitExists(petUnit) then
		local guid = UnitGUID(unit)
		local petGUID = UnitGUID(petUnit)
		Ping.PetGUID[petGUID] = time()
		local petCount = 0
		for k, v in pairs(Ping.PetGUID) do
			petCount = petCount + 1
			if petCount > 50 then
				if (time() - 9000) > v then
					Ping.PetGUID[k] = nil
				end	
			end
		end	
	end
end

function Ping:CommReceived(prefix, message, distribution, source)
	if Ping.EnabledInZone and Ping.db.profile.UseData then
		if prefix == Ping.Signature and message and source ~= Ping.CharacterName then
			local version, player, class, level, race, zone, subZone, mapX, mapY, guild, mapID = strsplit("|", message)
			if mapID == nil then
				mapID = ""
			end	
			if player ~= nil and (not Ping.InInstance or zone == GetZoneText()) then
				if not Ping.PlayerCommList[player] then
					local upgrade = Ping:VersionCheck(Ping.Version, version)
					if upgrade and not Ping.UpgradeMessageSent then
						DEFAULT_CHAT_FRAME:AddMessage(L["UpgradeAvailable"])
						Ping.UpgradeMessageSent = true
					end
					if strlen(class) > 0 then
						if not Ping.ValidClasses[class] then
							return
						end
					else
						class = nil
					end
					if strlen(level) > 0 then
						level = tonumber(level)
						if type(level) == "number" then
							if level < 1 or level > Ping.MaximumPlayerLevel or math.floor(level) ~= level then
								return
							end
						else
							return
						end
					else
						level = nil
					end
					if strlen(race) > 0 then
						if not Ping.ValidRaces[race] then
							return
						end
					else
						race = nil
					end
					if strlen(zone) == 0 then
						zone = nil
					end
					if strlen(mapID) > 0 then
						mapID = tonumber(mapID)
					else
						mapID = 0
					end
					if strlen(subZone) == 0 then
						subZone = nil
					end
					if strlen(mapX) > 0 then
						mapX = tonumber(mapX)
						if type(mapX) == "number" and mapX >= 0 and mapX <= 1 then
							mapX = math.floor(mapX * 100) / 100
						else
							return
						end
					else
						mapX = nil
					end
					if strlen(mapY) > 0 then
						mapY = tonumber(mapY)
						if type(mapY) == "number" and mapY >= 0 and mapY <= 1 then
							mapY = math.floor(mapY * 100) / 100
						else
							return
						end
					else
						mapY = nil
					end
					if strlen(guild) > 0 then
						if strlen(guild) > 24 then
							return
						end
					else
						guild = nil
					end

					local learnt, playerData = Ping:ParseUnitDetails(player, class, level, race, zone, subZone, mapX, mapY, guild, mapID)
					if playerData and playerData.isEnemy and not PingPerCharDB.IgnoreData[player] then
						Ping.PlayerCommList[player] = Ping.CurrentMapNote
						Ping:AddDetected(player, time(), learnt, source)
						-- test for nil or 0 mapID
						if Ping.db.profile.DisplayOnMap and mapID > 0 then
							Ping:ShowMapNote(player)
						end
					end
				end
			end
		end
	end
end

function Ping:VersionCheck(version1, version2)
	local major1, minor1, update1 = strsplit(".", version1)
	local major2, minor2, update2 = strsplit(".", version2)
	major1, minor1, update1 = tonumber(major1), tonumber(minor1), tonumber(update1)
	major2, minor2, update2 = tonumber(major2), tonumber(minor2), tonumber(update2)
	if major1 < major2 then
		return true
	elseif ((major1 == major2) and (minor1 < minor2)) then
		return true
	elseif ((major1 == major2) and (minor1 == minor2) and (update1 < update2)) then
		return true
	else	
		return false
	end
end

function Ping:TrackHumanoids()
	local tooltip = GameTooltipTextLeft1:GetText()
	if tooltip and tooltip ~= Ping.LastTooltip then
		tooltip = Ping:ParseMinimapTooltip(tooltip)
		if Ping.db.profile.MinimapDetails then
			GameTooltipTextLeft1:SetText(tooltip)
			Ping.LastTooltip = tooltip
		end
		GameTooltip:Show()
	end
end

function Ping:FilterNotInParty(frame, event, message)
	if (event == ERR_NOT_IN_GROUP or event == ERR_NOT_IN_RAID) then
		return true
	end
	return false
end

function Ping:ShowMapNote(player)
	local playerData = PingPerCharDB.PlayerData[player]
	if playerData then
		local currentMapID, TOP_MOST = C_Map.GetBestMapForUnit('player'), true
		-- Declared local: without this both of these are globals, and Spy
		-- writes globals of the same name, so the two addons scribble on each
		-- other whenever a map note is placed.
		local continentID, currentContinentID
		local currentContinentInfo = MapUtil.GetMapParentInfo(currentMapID, Enum.UIMapType.Continent, true)
		if currentContinentInfo then
			currentContinentID = currentContinentInfo.mapID	
		else
			currentContinentID = currentMapID
		end
		local mapID, mapX, mapY = playerData.mapID, playerData.mapX, playerData.mapY
		local continentInfo = MapUtil.GetMapParentInfo(mapID, Enum.UIMapType.Continent, true)
		if continentInfo then
			continentID = continentInfo.mapID	
		else
			continentID = mapID
		end
		if continentID ~= nil and mapID ~= nil and type(playerData.mapX) == "number" and type(playerData.mapY) == "number" and (Ping.db.profile.MapDisplayLimit == "None" or (Ping.db.profile.MapDisplayLimit == "SameZone" and mapID == currentMapID) or (Ping.db.profile.MapDisplayLimit == "SameContinent" and continentID == currentContinentID)) then
			local note = Ping.MapNoteList[Ping.CurrentMapNote]
			note.displayed = true
			note.continentID = continentID
			note.mapID = mapID
			note.mapX = mapX
			note.mapY = mapY

			if Ping.db.profile.MapDisplayLimit == "SameZone" then
				HBDP:AddWorldMapIconMap(WorldMapFrame, note.worldIcon, mapID, mapX, mapY, 1)
			elseif Ping.db.profile.MapDisplayLimit == "SameContinent" then
				HBDP:AddWorldMapIconMap(WorldMapFrame, note.worldIcon, mapID, mapX, mapY, 2)
			else
				HBDP:AddWorldMapIconMap(WorldMapFrame, note.worldIcon, mapID, mapX, mapY, 3)
			end	
			HBDP:AddMinimapIconMap(self, note.miniIcon, note.mapID, note.mapX, note.mapY, false, false)

			for i = 1, Ping.MapNoteLimit do
				if i ~= Ping.CurrentMapNote and Ping.MapNoteList[i].displayed then
					if continentID == Ping.MapNoteList[i].continentID and mapID == Ping.MapNoteList[i].mapID and abs(mapX - Ping.MapNoteList[i].mapX) < Ping.MapProximityThreshold and abs(mapY - Ping.MapNoteList[i].mapY) < Ping.MapProximityThreshold then
						Ping.MapNoteList[i].displayed = false
						Ping.MapNoteList[i].worldIcon:Hide()
							HBDP:RemoveMinimapIcon(self, Ping.MapNoteList[i].miniIcon)
						for player in pairs(Ping.PlayerCommList) do
							if Ping.PlayerCommList[player] == i then
								Ping.PlayerCommList[player] = Ping.CurrentMapNote
							end
						end
					end
				end
			end

			Ping.CurrentMapNote = Ping.CurrentMapNote + 1
			if Ping.CurrentMapNote > Ping.MapNoteLimit then
				Ping.CurrentMapNote = 1
			end
		end
	end
end

function Ping:GetPlayerLocation(playerData)
	if not playerData then return L["Unknown"] or "Unknown" end
	local location = playerData.zone or L["Unknown"] or "Unknown"
	local mapX = tonumber(playerData.mapX)
	local mapY = tonumber(playerData.mapY)
	if location and playerData.subZone and playerData.subZone ~= "" and playerData.subZone ~= location then
		location = playerData.subZone..", "..location
	end
	if mapX and mapX ~= 0 and mapY and mapY ~= 0 then
		location = location.." ("..math.floor(mapX * 100)..","..math.floor(mapY * 100)..")"
	end
	return location
end

function Ping:HidePingCombatCheck()
	if InCombatLockdown() then
		-- MainWindow did not Hide while in combat, try again in 10 seconds.
		self:ScheduleTimer("HidePingCombatCheck",10)
		return
	else
		Ping.MainWindow:Hide()
	end
end

function Ping:FormatTime(timestamp)
    if timestamp == 0 then return "Long " end

    local age = time() - timestamp

    local days
    if age >= 86400 then
        days = math.modf(age / 86400)
        age = age - (days * 86400)
    end

    local hours
    if age >= 3600 then
        hours = math.modf(age / 3600)
        age = age - (hours * 3600)
    end

    local minutes
    if age >= 60 then
        minutes = math.modf(age / 60)
        age = age - (minutes * 60)
    end

    local seconds = age

    local text = (days and days .. "d " or "") .. ((hours and not days) and hours .. "h " or "") .. ((minutes and not hours and not days) and minutes .. "m " or "") .. ((seconds and not minutes and not hours and not days) and seconds .. "s " or "")

    return strtrim(text)
end

-- recieves pointer to PingData Ping_db
function Ping:SetDataDb(val)
    Ping_db = val
end
