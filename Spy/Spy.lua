local SM = LibStub:GetLibrary("LibSharedMedia-3.0")
local HBD = LibStub("HereBeDragons-2.0")
local HBDP = LibStub("HereBeDragons-Pins-2.0")
local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:GetLocale("Spy")
local fonts = SM:List("font")
local _

Spy = LibStub("AceAddon-3.0"):NewAddon("Spy", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceTimer-3.0")
Spy.Version = "2.1.0"
Spy.DatabaseVersion = "1.1"
Spy.Signature = "[Spy]"
Spy.ButtonLimit = 15
Spy.MaximumPlayerLevel = MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()]
--Spy.MaximumPlayerLevel = GetMaxLevelForLatestExpansion()
Spy.MapNoteLimit = 20
Spy.MapProximityThreshold = 0.02
Spy.CurrentMapNote = 1
Spy.ZoneID = {}
Spy.KOSGuild = {}
Spy.CurrentList = {}
Spy.NearbyList = {}
Spy.LastHourList = {}
Spy.ActiveList = {}
Spy.InactiveList = {}
Spy.PlayerCommList = {}
Spy.ListAmountDisplayed = 0
Spy.ButtonName = {}
Spy.EnabledInZone = false
Spy.InInstance = false
Spy.AlertType = nil
Spy.UpgradeMessageSent = false
Spy.zName = ""
Spy.ChnlTime = 0
Spy.Skull = -1
Spy.PetGUID = {}

-- Localizations for SpyStats
L_STATS = "Spy "..L["Statistics"]
L_WON = L["Won"]
L_LOST = L["Lost"]
L_REASON = L["Reason"]
L_LIST = L["List"]
L_TIME = L["Time"]
L_FILTER = L["Filter"]..":"
L_SHOWONLY = L["Show Only"]..":"

Spy.options = {
	name = L["Spy"],
	type = "group",
	args = {
		About = {
			name = L["About"],
			desc = L["About"],
			type = "group",
			-- Reference material, not settings. AceConfigDialog sorts negative
			-- orders after positive ones, so this sits at the foot of the
			-- sidebar (just above Profiles at -2) and /spy config now opens on
			-- a page that actually has controls on it.
			order = -3,
			args = {
				intro1 = {
					name = L["SpyDescription1"],
					type = "description",
					order = 1,
					fontSize = "medium",
				},	
				intro2 = {
					name = L["SpyDescription2"],
					type = "description",
					order = 2,
					fontSize = "medium",
				},
				intro3 = {
					name = L["SpyDescription3"],
					type = "description",
					order = 3,
					fontSize = "medium",
				},
			},
		},
		SpyGroup = {
			name = L["TPageSpy"],
			desc = L["TPageSpy"],
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
								return Spy.db.profile.EnabledInBattlegrounds
							end,
							set = function(info, value)
								Spy.db.profile.EnabledInBattlegrounds = value
								Spy:ZoneChangedEvent()
							end,
						},
						EnabledInArenas = {
							name = L["EnabledInArenas"],
							desc = L["EnabledInArenasDescription"],
							type = "toggle",
							order = 2,
							width = "full",
							get = function(info)
								return Spy.db.profile.EnabledInArenas
							end,
							set = function(info, value)
								Spy.db.profile.EnabledInArenas = value
								Spy:ZoneChangedEvent()
							end,
						},
						EnabledInSanctuaries = {
							name = L["EnabledInSanctuaries"],
							desc = L["EnabledInSanctuariesDescription"],
							type = "toggle",
							order = 3,
							width = "full",
							get = function(info)
								return Spy.db.profile.EnabledInSanctuaries
							end,
							set = function(info, value)
								Spy.db.profile.EnabledInSanctuaries = value
								Spy:ZoneChangedEvent()
							end,
						},
						DisableWhenPVPUnflagged = {
							name = L["DisableWhenPVPUnflagged"],
							desc = L["DisableWhenPVPUnflaggedDescription"],
							type = "toggle",
							order = 4,
							width = "full",
							get = function(info)
								return Spy.db.profile.DisableWhenPVPUnflagged
							end,
							set = function(info, value)
								Spy.db.profile.DisableWhenPVPUnflagged = value
								Spy:ZoneChangedEvent()
							end,
						},
						DisabledInZones = {
							name = L["DisabledInZones"],
							desc = L["DisabledInZonesDescription"],
							type = "multiselect",
							order = 5,
							get = function(info, key) 
								return Spy.db.profile.FilteredZones[key] 
							end,
							set = function(info, key, value) 
								Spy.db.profile.FilteredZones[key] = value 
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
								return Spy.db.profile.ShowOnDetection
							end,
							set = function(info, value)
								Spy.db.profile.ShowOnDetection = value
							end,
						},
						HideSpy = {
							name = L["HideSpy"],
							desc = L["HideSpyDescription"],
							type = "toggle",
							order = 7,
							width = "full",
							get = function(info)
								return Spy.db.profile.HideSpy
							end,
							set = function(info, value)
								Spy.db.profile.HideSpy = value
								if Spy.db.profile.HideSpy and Spy:GetNearbyListSize() == 0 then
									Spy.MainWindow:Hide()
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
								return Spy.db.profile.ShowKoSButton
							end,
							set = function(info, value)
								Spy.db.profile.ShowKoSButton = value
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
								return Spy.db.profile.ShowNearbyList
							end,
							set = function(info, value)
								Spy.db.profile.ShowNearbyList = value
							end,
						},
						PrioritiseKoS = {
							name = L["PrioritiseKoS"],
							desc = L["PrioritiseKoSDescription"],
							type = "toggle",
							order = 2,
							width = "full",
							get = function(info)
								return Spy.db.profile.PrioritiseKoS
							end,
							set = function(info, value)
								Spy.db.profile.PrioritiseKoS = value
							end,
						},
						ResizeSpy = {
							name = L["ResizeSpy"],
							desc = L["ResizeSpyDescription"],
							type = "toggle",
							order = 3,
							width = "full",
							get = function(info)
								return Spy.db.profile.ResizeSpy
							end,
							set = function(info, value)
								Spy.db.profile.ResizeSpy = value
								if value then Spy:RefreshCurrentList() end
							end,
						},
						ResizeSpyLimit = {  
							type = "range",
							order = 4,
							name = L["ResizeSpyLimit"],
							desc = L["ResizeSpyLimitDescription"],
							min = 1, max = 15, step = 1,
							get = function() return Spy.db.profile.ResizeSpyLimit end,
							set = function(info, value)
								Spy.db.profile.ResizeSpyLimit = value
								if value then 
									Spy:ResizeMainWindow()
									Spy:RefreshCurrentList() 
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
								return Spy.db.profile.DisplayListData
							end,
							set = function(info, value)
								Spy.db.profile.DisplayListData = value
								Spy:RefreshCurrentList() 
							end,
						},
						DisplayLastSeen = {
							name = L["TooltipDisplayLastSeen"],
							desc = L["TooltipDisplayLastSeenDescription"],
							type = "toggle",
							order = 6,
							width = "full",
							get = function(info)
								return Spy.db.profile.DisplayLastSeen
							end,
							set = function(info, value)
								Spy.db.profile.DisplayLastSeen = value
							end,
						},
						DisplayKOSReason = {
							name = L["TooltipDisplayKOSReason"],
							desc = L["TooltipDisplayKOSReasonDescription"],
							type = "toggle",
							order = 7,
							width = "full",
							get = function(info)
								return Spy.db.profile.DisplayKOSReason
							end,
							set = function(info, value)
								Spy.db.profile.DisplayKOSReason = value
							end,
						},
						DisplayWinLossStatistics = {
							name = L["TooltipDisplayWinLoss"],
							desc = L["TooltipDisplayWinLossDescription"],
							type = "toggle",
							order = 8,
							width = "full",
							get = function(info)
								return Spy.db.profile.DisplayWinLossStatistics
							end,
							set = function(info, value)
								Spy.db.profile.DisplayWinLossStatistics = value
							end,
						},
						DisplayTooltipNearSpyWindow = {
							name = L["DisplayTooltipNearSpyWindow"],
							desc = L["DisplayTooltipNearSpyWindowDescription"],
							type = "toggle",
							order = 9,
							width = "full",
							get = function(info)
								return Spy.db.profile.DisplayTooltipNearSpyWindow
							end,
							set = function(info, value)
								Spy.db.profile.DisplayTooltipNearSpyWindow = value
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
								return Spy.db.profile.TooltipAnchor
							end,
							set = function(info, value)
								Spy.db.profile.TooltipAnchor = value
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
							get = function() return Spy.db.profile.MarkHealers end,
							set = function(_, value)
								Spy.db.profile.MarkHealers = value
								Spy:RefreshCurrentList()
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
							get = function() return Spy.db.profile.HealerDetectBy end,
							set = function(_, value)
								Spy.db.profile.HealerDetectBy = value
								Spy:RefreshCurrentList()
							end,
						},
						StrictHealerDetection = {
							name = L["StrictHealerDetection"],
							desc = L["StrictHealerDetectionDescription"],
							type = "toggle",
							order = 2.5,
							width = "full",
							get = function() return Spy.db.profile.StrictHealerDetection end,
							set = function(_, v)
								Spy.db.profile.StrictHealerDetection = v
								Spy:RefreshCurrentList()
							end,
						},
						HealerMinHeals = {
							name = L["HealerMinHeals"],
							desc = L["HealerMinHealsDescription"],
							type = "range",
							order = 2.7,
							min = 1, max = 6, step = 1,
							get = function() return Spy.db.profile.HealerMinHeals end,
							set = function(_, v) Spy.db.profile.HealerMinHeals = v end,
						},
						HealerMinHeal = {
							name = L["HealerMinHeal"],
							desc = L["HealerMinHealDescription"],
							type = "range",
							order = 3,
							min = 0, max = 3000, step = 50,
							disabled = function() return Spy.db.profile.HealerDetectBy ~= "heal" end,
							get = function() return Spy.db.profile.HealerMinHeal end,
							set = function(_, value) Spy.db.profile.HealerMinHeal = value end,
						},
						HealerMarkerStyle = {
							name = L["HealerMarkerStyle"],
							desc = L["HealerMarkerStyleDescription"],
							type = "select",
							order = 4,
							values = {
								["cross"] = L["HealerMarkerCross"],
								["asterisk"] = L["HealerMarkerAsterisk"],
								["dot"] = L["HealerMarkerDot"],
							},
							get = function() return Spy.db.profile.HealerMarkerStyle end,
							set = function(_, value)
								Spy.db.profile.HealerMarkerStyle = value
								Spy:RefreshCurrentList()
							end,
						},
						HealerMarkerSide = {
							name = L["HealerMarkerSide"],
							desc = L["HealerMarkerSideDescription"],
							type = "select",
							order = 5,
							values = {
								["right"] = L["HealerMarkerRight"],
								["left"] = L["HealerMarkerLeft"],
							},
							get = function() return Spy.db.profile.HealerMarkerSide end,
							set = function(_, value)
								Spy.db.profile.HealerMarkerSide = value
								Spy:RefreshCurrentList()
							end,
						},
						HealerMarkerColor = {
							name = L["HealerMarkerColor"],
							type = "color",
							order = 6,
							hasAlpha = false,
							get = function()
								local c = Spy.db.profile.Colors["Spy"]["Healer Marker"]
								return c.r, c.g, c.b
							end,
							set = function(_, r, g, b)
								local c = Spy.db.profile.Colors["Spy"]["Healer Marker"]
								c.r, c.g, c.b = r, g, b
								Spy:RefreshCurrentList()
							end,
						},
						SortHealersToTop = {
							name = L["SortHealersToTop"],
							desc = L["SortHealersToTopDescription"],
							type = "toggle",
							order = 7,
							width = "full",
							get = function() return Spy.db.profile.SortHealersToTop end,
							set = function(_, value)
								Spy.db.profile.SortHealersToTop = value
								Spy:RefreshCurrentList()
							end,
						},
						HealerGreenEdge = {
							name = L["HealerGreenEdge"],
							desc = L["HealerGreenEdgeDescription"],
							type = "toggle",
							order = 8,
							get = function() return Spy.db.profile.HealerGreenEdge end,
							set = function(_, value)
								Spy.db.profile.HealerGreenEdge = value
								Spy:RefreshCurrentList()
							end,
						},
						HealerEdgeColor = {
							name = L["HealerEdgeColor"],
							type = "color",
							order = 9,
							hasAlpha = true,
							get = function()
								local c = Spy.db.profile.Colors["Spy"]["Healer Edge"]
								return c.r, c.g, c.b, c.a
							end,
							set = function(_, r, g, b, a)
								local c = Spy.db.profile.Colors["Spy"]["Healer Edge"]
								c.r, c.g, c.b, c.a = r, g, b, a
								Spy:RefreshCurrentList()
							end,
						},
						DimNonHealers = {
							name = L["DimNonHealers"],
							desc = L["DimNonHealersDescription"],
							type = "toggle",
							order = 10,
							width = "full",
							get = function() return Spy.db.profile.DimNonHealers end,
							set = function(_, value)
								Spy.db.profile.DimNonHealers = value
								Spy:RefreshCurrentList()
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
							multiline = 10,
							width = "full",
							order = 22,
							disabled = function() return Spy.db.profile.StrictHealerDetection == false end,
							get = function()
								-- Seed on first read, so the box never appears empty
								-- while 24 spells are quietly being matched.
								if not Spy.db.profile.HealerSpellListSeeded then
									Spy:BuildHealerSpellNames()
								end
								return Spy.db.profile.HealerSpellListText
							end,
							set = function(_, v)
								Spy.db.profile.HealerSpellListText = v
								Spy.db.profile.HealerSpellListSeeded = true
								Spy:BuildHealerSpellNames()
								Spy:RefreshCurrentList()
							end,
						},
						healerListStatus = {
							name = function()
								return format(L["HealerSpellListStatus"], Spy.HealerSpellCount or 0)
							end,
							type = "description",
							order = 23,
						},
						healerListReset = {
							name = L["HealerSpellListReset"],
							desc = L["HealerSpellListResetDescription"],
							type = "execute",
							order = 24,
							func = function() Spy:ResetHealerSpellList() Spy:RefreshCurrentList() end,
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
							get = function() return Spy.db.profile.HealerOnlyFilter end,
							set = function(_, value)
								Spy.db.profile.HealerOnlyFilter = value
								Spy:UpdateWindowTitle()
								Spy:RefreshCurrentList()
							end,
						},
						KillPriorityOrder = {
							name = L["KillPriorityOrder"],
							desc = L["KillPriorityOrderDescription"],
							type = "toggle",
							order = 3,
							width = "full",
							get = function() return Spy.db.profile.KillPriorityOrder end,
							set = function(_, value)
								Spy.db.profile.KillPriorityOrder = value
								Spy:RefreshCurrentList()
							end,
						},
						ShowAggregateHeader = {
							name = L["ShowAggregateHeader"],
							desc = L["ShowAggregateHeaderDescription"],
							type = "toggle",
							order = 4,
							width = "full",
							get = function() return Spy.db.profile.ShowAggregateHeader end,
							set = function(_, value)
								Spy.db.profile.ShowAggregateHeader = value
								Spy:UpdateActiveCount()
							end,
						},
						UseZoneLevelFloor = {
							name = L["UseZoneLevelFloor"],
							desc = L["UseZoneLevelFloorDescription"],
							type = "toggle",
							order = 5,
							width = "full",
							get = function() return Spy.db.profile.UseZoneLevelFloor end,
							set = function(_, value)
								Spy.db.profile.UseZoneLevelFloor = value
								Spy:RefreshCurrentList()
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
							get = function() return Spy.db.profile.FocusClassMode end,
							set = function(_, v)
								Spy.db.profile.FocusClassMode = v
								Spy:RefreshCurrentList()
							end,
						},
						FocusClasses = {
							name = L["FocusClasses"],
							desc = L["FocusClassesDescription"],
							type = "multiselect",
							order = 13,
							disabled = function() return Spy.db.profile.FocusClassMode == "off" end,
							values = function()
								-- Driven by the client's own class list rather than a second
								-- hardcoded one, so it cannot drift out of step with detection.
								local t = {}
								for class in pairs(Spy.ValidClasses or {}) do
									t[class] = L[class] or class
								end
								return t
							end,
							get = function(_, class) return Spy.db.profile.FocusClasses[class] == true end,
							set = function(_, class, value)
								Spy.db.profile.FocusClasses[class] = value or nil
								Spy:RefreshCurrentList()
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
							get = function() return Spy.db.profile.TrackCooldowns end,
							set = function(_, value)
								Spy.db.profile.TrackCooldowns = value
								Spy:RefreshCurrentList()
							end,
						},
						AnnounceCooldowns = {
							name = L["AnnounceCooldowns"],
							desc = L["AnnounceCooldownsDescription"],
							type = "toggle",
							order = 2,
							width = "full",
							disabled = function() return not Spy.db.profile.TrackCooldowns end,
							get = function() return Spy.db.profile.AnnounceCooldowns end,
							set = function(_, value) Spy.db.profile.AnnounceCooldowns = value end,
						},
						CooldownColor = {
							name = L["CooldownColor"],
							type = "color",
							order = 3,
							hasAlpha = false,
							disabled = function() return not Spy.db.profile.TrackCooldowns end,
							get = function()
								local c = Spy.db.profile.Colors["Spy"]["Cooldown"]
								return c.r, c.g, c.b
							end,
							set = function(_, r, g, b)
								local c = Spy.db.profile.Colors["Spy"]["Cooldown"]
								c.r, c.g, c.b = r, g, b
								Spy:RefreshCurrentList()
							end,
						},
						KOSGuildAlertCooldown = {
							name = L["KOSGuildAlertCooldown"],
							desc = L["KOSGuildAlertCooldownDescription"],
							type = "range",
							order = 4,
							min = 0, max = 120, step = 5,
							get = function() return Spy.db.profile.KOSGuildAlertCooldown end,
							set = function(_, value) Spy.db.profile.KOSGuildAlertCooldown = value end,
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
							multiline = 12,
							width = "full",
							order = 12,
							disabled = function() return not Spy.db.profile.TrackCooldowns end,
							get = function()
								-- Seed on first read so the box is never shown empty while
								-- ten spells are quietly being tracked.
								if not Spy.db.profile.CooldownListSeeded then
									Spy:BuildCooldownLookup()
								end
								return Spy.db.profile.CooldownListText
							end,
							set = function(_, v)
								Spy.db.profile.CooldownListText = v
								Spy.db.profile.CooldownListSeeded = true
								Spy:BuildCooldownLookup()
							end,
						},
						cdListStatus = {
							name = function()
								local total = 0
								for _ in pairs(Spy.CooldownLookup or {}) do total = total + 1 end
								if (Spy.CooldownListUnresolved or 0) > 0 then
									return format(L["CooldownListStatusWithWarning"], total,
										Spy.CooldownListUnresolved)
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
							func = function() Spy:ResetCooldownList() end,
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
							get = function() return Spy.db.profile.NameplateDistanceMode end,
							set = function(_, v)
								Spy.db.profile.NameplateDistanceMode = v
								Spy:ApplyDistanceSettings(true)
							end,
						},
						NameplateDistanceValue = {
							name = L["NameplateDistanceValue"],
							desc = L["NameplateDistanceValueDescription"],
							type = "range",
							order = 3,
							min = 20, max = 100, step = 5,
							disabled = function() return Spy.db.profile.NameplateDistanceMode ~= "custom" end,
							get = function() return Spy.db.profile.NameplateDistanceValue end,
							set = function(_, v)
								Spy.db.profile.NameplateDistanceValue = v
								Spy:ApplyDistanceSettings(false)
							end,
						},
						MaxNameplateDistanceShowsEnemies = {
							name = L["MaxNameplateShowEnemies"],
							desc = L["MaxNameplateShowEnemiesDescription"],
							type = "toggle",
							order = 4,
							width = "full",
							disabled = function() return Spy.db.profile.NameplateDistanceMode == "off" end,
							get = function() return Spy.db.profile.MaxNameplateDistanceShowsEnemies end,
							set = function(_, v)
								Spy.db.profile.MaxNameplateDistanceShowsEnemies = v
								if v then Spy:ApplyDistanceSettings(true) end
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
							get = function() return Spy.db.profile.ViewDistanceMode end,
							set = function(_, v)
								Spy.db.profile.ViewDistanceMode = v
								Spy:ApplyDistanceSettings(true)
							end,
						},
						ViewDistanceValue = {
							name = L["ViewDistanceValue"],
							desc = L["ViewDistanceValueDescription"],
							type = "range",
							order = 7,
							min = 100, max = 1000, step = 25,
							disabled = function() return Spy.db.profile.ViewDistanceMode ~= "custom" end,
							get = function() return Spy.db.profile.ViewDistanceValue end,
							set = function(_, v)
								Spy.db.profile.ViewDistanceValue = v
								Spy:ApplyDistanceSettings(false)
							end,
						},
						status = {
							name = function()
								local plates, view = Spy:GetDistanceStatus()
								return format(L["DistanceStatus"],
									plates and tostring(plates) or "?",
									view and tostring(view) or "?")
							end,
							type = "description",
							order = 10,
						},
						ceilings = {
							name = function()
								local np = Spy:GetNameplateCeiling()
								local fc = Spy:GetViewCeiling()
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
							func = function() Spy:ApplyDistanceSettings(true) end,
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
								return Spy.db.profile.MinimapDetection
							end,
							set = function(info, value)
								Spy.db.profile.MinimapDetection = value
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
								return Spy.db.profile.MinimapDetails
							end,
							set = function(info, value)
								Spy.db.profile.MinimapDetails = value
							end,
						},
						DisplayOnMap = {
							name = L["DisplayOnMap"],
							desc = L["DisplayOnMapDescription"],
							type = "toggle",
							order = 4,
							width = "full",
							get = function(info)
								return Spy.db.profile.DisplayOnMap
							end,
							set = function(info, value)
								Spy.db.profile.DisplayOnMap = value
							end,
						},
						SwitchToZone = {
							name = L["SwitchToZone"],
							desc = L["SwitchToZoneDescription"],
							type = "toggle",
							order = 5,
							width = "full",
							get = function(info)
								return Spy.db.profile.SwitchToZone
							end,
							set = function(info, value)
								Spy.db.profile.SwitchToZone = value
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
										return Spy.db.profile.MapDisplayLimit == "SameZone"
									end,
									set = function(info, value)
										Spy.db.profile.MapDisplayLimit = "SameZone"
									end,
								},
								SameContinent = {
									name = L["LimitSameContinent"],
									desc = L["LimitSameContinentDescription"],
									type = "toggle",
									order = 2,
									width = "full",
									get = function(info)
										return Spy.db.profile.MapDisplayLimit == "SameContinent"
									end,
									set = function(info, value)
										Spy.db.profile.MapDisplayLimit = "SameContinent"
									end,
								},
								None = {
									name = L["LimitNone"],
									desc = L["LimitNoneDescription"],
									type = "toggle",
									order = 3,
									width = "full",
									get = function(info)
										return Spy.db.profile.MapDisplayLimit == "None"
									end,
									set = function(info, value)
										Spy.db.profile.MapDisplayLimit = "None"
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
			childGroups = "tab",
			args = {
				Rows = {
					name = L["TTabRows"],
					desc = L["TTabRows"],
					type = "group",
					order = 1,
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
							get = function() return Spy.db.profile.LookPreset end,
							set = function(_, value)
								Spy:ApplyLookPreset(value)
							end,
						},
						ClassColoredNames = {
							name = L["ClassColoredNames"],
							desc = L["ClassColoredNamesDescription"],
							type = "toggle",
							order = 2,
							width = "full",
							get = function() return Spy.db.profile.ClassColoredNames end,
							set = function(_, value)
								Spy.db.profile.ClassColoredNames = value
								Spy:RefreshCurrentList()
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
									if value == Spy.db.profile.Font then
										return info
									end
								end
							end,
							set = function(_, value)
								Spy.db.profile.Font = fonts[value]
								if value then
									Spy:UpdateBarTextures()
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
								return Spy.db.profile.MainWindow.RowHeight
							end,
							set = function(info, value)
								Spy.db.profile.MainWindow.RowHeight = value
								if value then
									Spy:BarsChanged()
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
								return Spy.db.profile.BarTexture
							end,
							set = function(_, key)
								Spy.db.profile.BarTexture = key
								Spy:UpdateBarTextures()
							end,
						},
						BarOpacity = {
							name = L["BarOpacity"],
							desc = L["BarOpacityDescription"],
							type = "range",
							order = 6,
							min = 0, max = 1, step = 0.05,
							isPercent = true,
							get = function() return Spy.db.profile.BarOpacity end,
							set = function(_, value)
								Spy.db.profile.BarOpacity = value
								Spy:RefreshCurrentList()
							end,
						},
						KoSEdgeColor = {
							name = L["KoSEdgeColor"],
							desc = L["KoSEdgeColorDescription"],
							type = "color",
							order = 7,
							hasAlpha = true,
							get = function()
								local c = Spy.db.profile.Colors["Spy"]["KoS Edge"]
								return c.r, c.g, c.b, c.a
							end,
							set = function(_, r, g, b, a)
								local c = Spy.db.profile.Colors["Spy"]["KoS Edge"]
								c.r, c.g, c.b, c.a = r, g, b, a
								Spy:RefreshCurrentList()
							end,
						},
					},
				},
				WindowTab = {
					name = L["TTabWindow"],
					desc = L["TTabWindow"],
					type = "group",
					order = 2,
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
								for key, theme in pairs(Spy.LookThemes) do t[key] = theme.name end
								return t
							end,
							get = function() return Spy.db.profile.LookTheme end,
							set = function(_, v) Spy:ApplyLookTheme(v) end,
						},
						LockPosition = {
							name = L["LockPosition"],
							desc = L["LockPositionDescription"],
							type = "toggle",
							order = 1,
							get = function() return Spy.db.profile.LockPosition end,
							set = function(_, value)
								Spy.db.profile.LockPosition = value
								Spy:ApplyWindowLocks()
							end,
						},
						LockSize = {
							name = L["LockSize"],
							desc = L["LockSizeDescription"],
							type = "toggle",
							order = 2,
							get = function() return Spy.db.profile.LockSize end,
							set = function(_, value)
								Spy.db.profile.LockSize = value
								Spy:ApplyWindowLocks()
							end,
						},
						Lock = {
							name = L["LockSpy"],
							desc = L["LockSpyDescription"],
							type = "toggle",
							order = 3,
							width = 1.6,
							get = function(info) 
								return Spy.db.profile.Locked
							end,
							set = function(info, value)
								Spy.db.profile.Locked = value
								Spy:LockWindows(value)
								Spy:RefreshCurrentList()
							end,
						},
						ClampToScreen = {
							name = L["ClampToScreen"],
							desc = L["ClampToScreenDescription"],
							type = "toggle",
							order = 4,
		--					width = "double",
							get = function(info) 
								return Spy.db.profile.ClampToScreen
							end,
							set = function(info, value)
								Spy.db.profile.ClampToScreen = value
								Spy:ClampToScreen(value)
							end,
						},
						InvertSpy = {
							name = L["InvertSpy"],
							desc = L["InvertSpyDescription"],
							type = "toggle",
							order = 5,
							get = function(info)
								return Spy.db.profile.InvertSpy
							end,
							set = function(info, value)
								Spy.db.profile.InvertSpy = value
							end,
						},
						WindowScale = {
							name = L["WindowScale"],
							desc = L["WindowScaleDescription"],
							type = "range",
							order = 6,
							min = 0.5, max = 2, step = 0.05,
							isPercent = true,
							get = function() return Spy.db.profile.WindowScale end,
							set = function(_, value)
								Spy.db.profile.WindowScale = value
								Spy:ApplyWindowStyle()
							end,
						},
						ShowBackground = {
							name = L["ShowBackground"],
							desc = L["ShowBackgroundDescription"],
							type = "toggle",
							order = 7,
							get = function() return Spy.db.profile.ShowBackground end,
							set = function(_, value)
								Spy.db.profile.ShowBackground = value
								Spy:ApplyWindowStyle()
							end,
						},
						BackgroundOpacity = {
							name = L["BackgroundOpacity"],
							desc = L["BackgroundOpacityDescription"],
							type = "range",
							order = 8,
							min = 0, max = 1, step = 0.05,
							isPercent = true,
							get = function() return Spy.db.profile.BackgroundOpacity end,
							set = function(_, value)
								Spy.db.profile.BackgroundOpacity = value
								Spy:ApplyWindowStyle()
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
								return Spy.db.profile.MainWindow.Alpha end,
							set = function(info, value)
								Spy.db.profile.MainWindow.Alpha = value
								Spy:UpdateMainWindow()

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
								return Spy.db.profile.MainWindow.AlphaBG end,
							set = function(info, value)
								Spy.db.profile.MainWindow.AlphaBG = value
								Spy:UpdateMainWindow()
							end,
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
							get = function() return Spy.db.profile.TitleBarStyle end,
							set = function(_, value)
								Spy.db.profile.TitleBarStyle = value
								Spy:ApplyWindowStyle()
							end,
						},
						TitleBarColor = {
							name = L["TitleBarColor"],
							desc = L["TitleBarColorDescription"],
							type = "color",
							order = 12,
							hasAlpha = false,
							disabled = function() return Spy.db.profile.TitleBarStyle ~= "solid" end,
							get = function()
								local c = Spy.db.profile.Colors["Spy"]["Title Bar"]
								return c.r, c.g, c.b
							end,
							set = function(_, r, g, b)
								local c = Spy.db.profile.Colors["Spy"]["Title Bar"]
								c.r, c.g, c.b = r, g, b
								Spy:ApplyWindowStyle()
							end,
						},
						TitleBarOpacity = {
							name = L["TitleBarOpacity"],
							desc = L["TitleBarOpacityDescription"],
							type = "range",
							order = 13,
							min = 0, max = 1, step = 0.05,
							isPercent = true,
							disabled = function() return Spy.db.profile.TitleBarStyle ~= "solid" end,
							get = function() return Spy.db.profile.TitleBarOpacity end,
							set = function(_, value)
								Spy.db.profile.TitleBarOpacity = value
								Spy:ApplyWindowStyle()
							end,
						},
						ShowBorder = {
							name = L["ShowBorder"],
							desc = L["ShowBorderDescription"],
							type = "toggle",
							order = 14,
							get = function() return Spy.db.profile.ShowBorder end,
							set = function(_, value)
								Spy.db.profile.ShowBorder = value
								Spy:ApplyWindowStyle()
							end,
						},
						WindowBorderColor = {
							name = L["WindowBorderColor"],
							type = "color",
							order = 15,
							hasAlpha = true,
							get = function()
								local c = Spy.db.profile.Colors["Spy"]["Window Border"]
								return c.r, c.g, c.b, c.a
							end,
							set = function(_, r, g, b, a)
								local c = Spy.db.profile.Colors["Spy"]["Window Border"]
								c.r, c.g, c.b, c.a = r, g, b, a
								Spy:ApplyWindowStyle()
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
								return Spy.db.profile.EnableSound
							end,
							set = function(info, value)
								Spy.db.profile.EnableSound = value
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
								return Spy.db.profile.SoundChannel
							end,
							set = function(info, value)
								Spy.db.profile.SoundChannel = value 
							end,
						},
						OnlySoundKoS = {
							name = L["OnlySoundKoS"],
							desc = L["OnlySoundKoSDescription"],
							type = "toggle",
							order = 3,
							width = "full",
							get = function(info)
								return Spy.db.profile.OnlySoundKoS
							end,
							set = function(info, value)
								Spy.db.profile.OnlySoundKoS = value
							end,
						},
						StopAlertsOnTaxi = {
							name = L["StopAlertsOnTaxi"],
							desc = L["StopAlertsOnTaxiDescription"],
							type = "toggle",
							order = 4,
							width = "full",
							get = function(info)
								return Spy.db.profile.StopAlertsOnTaxi
							end,
							set = function(info, value)
								Spy.db.profile.StopAlertsOnTaxi = value
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
										return Spy.db.profile.Announce == "None"
									end,
									set = function(info, value)
										Spy.db.profile.Announce = "None"
									end,
								},
								Self = {
									name = L["Self"],
									desc = L["SelfDescription"],
									type = "toggle",
									order = 2,
									get = function(info)
										return Spy.db.profile.Announce == "Self"
									end,
									set = function(info, value)
										Spy.db.profile.Announce = "Self"
									end,
								},
								Party = {
									name = L["Party"],
									desc = L["PartyDescription"],
									type = "toggle",
									order = 3,
									get = function(info)
										return Spy.db.profile.Announce == "Party"
									end,
									set = function(info, value)
										Spy.db.profile.Announce = "Party"
									end,
								},
								Guild = {
									name = L["Guild"],
									desc = L["GuildDescription"],
									type = "toggle",
									order = 4,
									get = function(info)
										return Spy.db.profile.Announce == "Guild"
									end,
									set = function(info, value)
										Spy.db.profile.Announce = "Guild"
									end,
								},
								Raid = {
									name = L["Raid"],
									desc = L["RaidDescription"],
									type = "toggle",
									order = 5,
									get = function(info)
										return Spy.db.profile.Announce == "Raid"
									end,
									set = function(info, value)
										Spy.db.profile.Announce = "Raid"
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
								return Spy.db.profile.OnlyAnnounceKoS
							end,
							set = function(info, value)
								Spy.db.profile.OnlyAnnounceKoS = value
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
								return Spy.db.profile.DisplayWarnings
							end,
							set = function(info, value)
								Spy.db.profile.DisplayWarnings = value
								Spy:UpdateAlertWindow()
							end,
						},
						WarnOnStealth = {
							name = L["WarnOnStealth"],
							desc = L["WarnOnStealthDescription"],
							type = "toggle",
							order = 4,
							width = "full",
							get = function(info)
								return Spy.db.profile.WarnOnStealth
							end,
							set = function(info, value)
								Spy.db.profile.WarnOnStealth = value
							end,
						},
						WarnOnKOS = {
							name = L["WarnOnKOS"],
							desc = L["WarnOnKOSDescription"],
							type = "toggle",
							order = 5,
							width = "full",
							get = function(info)
								return Spy.db.profile.WarnOnKOS
							end,
							set = function(info, value)
								Spy.db.profile.WarnOnKOS = value
							end,
						},
						WarnOnKOSGuild = {
							name = L["WarnOnKOSGuild"],
							desc = L["WarnOnKOSGuildDescription"],
							type = "toggle",
							order = 6,
							width = "full",
							get = function(info)
								return Spy.db.profile.WarnOnKOSGuild
							end,
							set = function(info, value)
								Spy.db.profile.WarnOnKOSGuild = value
							end,
						},
						WarnOnRace = {
							name = L["WarnOnRace"],
							desc = L["WarnOnRaceDescription"],
							type = "toggle",
							order = 7,
							width = "full",
							get = function(info)
								return Spy.db.profile.WarnOnRace
							end,
							set = function(info, value)
								Spy.db.profile.WarnOnRace = value
							end,
						},
						SelectWarnRace = {
							type = "select",
							order = 8,
							name = L["SelectWarnRace"],
							desc = L["SelectWarnRaceDescription"],
							get = function()
								return Spy.db.profile.SelectWarnRace
							end,
							set = function(info, value)
								Spy.db.profile.SelectWarnRace = value
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
								if Spy.EnemyFactionName == "Alliance" then
									raceOptions = races.Alliance
								end	
								if Spy.EnemyFactionName == "Horde" then
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
										return Spy.db.profile.RemoveUndetected == "OneMinute"
									end,
									set = function(info, value)
										Spy.db.profile.RemoveUndetected = "OneMinute"
										Spy:UpdateTimeoutSettings()
									end,
								},
								TwoMinutes = {
									name = L["2Min"],
									desc = L["2MinDescription"],
									type = "toggle",
									order = 2,
									get = function(info)
										return Spy.db.profile.RemoveUndetected == "TwoMinutes"
									end,
									set = function(info, value)
										Spy.db.profile.RemoveUndetected = "TwoMinutes"
										Spy:UpdateTimeoutSettings()
									end,
								},
								FiveMinutes = {
									name = L["5Min"],
									desc = L["5MinDescription"],
									type = "toggle",
									order = 3,
									get = function(info)
										return Spy.db.profile.RemoveUndetected == "FiveMinutes"
									end,
									set = function(info, value)
										Spy.db.profile.RemoveUndetected = "FiveMinutes"
										Spy:UpdateTimeoutSettings()
									end,
								},
								TenMinutes = {
									name = L["10Min"],
									desc = L["10MinDescription"],
									type = "toggle",
									order = 4,
									get = function(info)
										return Spy.db.profile.RemoveUndetected == "TenMinutes"
									end,
									set = function(info, value)
										Spy.db.profile.RemoveUndetected = "TenMinutes"
										Spy:UpdateTimeoutSettings()
									end,
								},
								FifteenMinutes = {
									name = L["15Min"],
									desc = L["15MinDescription"],
									type = "toggle",
									order = 5,
									get = function(info)
										return Spy.db.profile.RemoveUndetected == "FifteenMinutes"
									end,
									set = function(info, value)
										Spy.db.profile.RemoveUndetected = "FifteenMinutes"
										Spy:UpdateTimeoutSettings()
									end,
								},
								Never = {
									name = L["Never"],
									desc = L["NeverDescription"],
									type = "toggle",
									order = 6,
									get = function(info)
										return Spy.db.profile.RemoveUndetected == "Never"
									end,
									set = function(info, value)
										Spy.db.profile.RemoveUndetected = "Never"
										Spy:UpdateTimeoutSettings()
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
										return Spy.db.profile.PurgeData == "OneDay"
									end,
									set = function(info, value)
										Spy.db.profile.PurgeData = "OneDay"
									end,
								},
								FiveDays = {
									name = L["FiveDays"],
									desc = L["FiveDaysDescription"],
									type = "toggle",
									order = 2,
									get = function(info)
										return Spy.db.profile.PurgeData == "FiveDays"
									end,
									set = function(info, value)
										Spy.db.profile.PurgeData = "FiveDays"
									end,
								},
								TenDays = {
									name = L["TenDays"],
									desc = L["TenDaysDescription"],
									type = "toggle",
									order = 3,
									get = function(info)
										return Spy.db.profile.PurgeData == "TenDays"
									end,
									set = function(info, value)
										Spy.db.profile.PurgeData = "TenDays"
									end,
								},
								ThirtyDays = {
									name = L["ThirtyDays"],
									desc = L["ThirtyDaysDescription"],
									type = "toggle",
									order = 4,
									get = function(info)
										return Spy.db.profile.PurgeData == "ThirtyDays"
									end,
									set = function(info, value)
										Spy.db.profile.PurgeData = "ThirtyDays"
									end,
								},
								SixtyDays = {
									name = L["SixtyDays"],
									desc = L["SixtyDaysDescription"],
									type = "toggle",
									order = 5,
									get = function(info)
										return Spy.db.profile.PurgeData == "SixtyDays"
									end,
									set = function(info, value)
										Spy.db.profile.PurgeData = "SixtyDays"
									end,
								},
								NinetyDays = {
									name = L["NinetyDays"],
									desc = L["NinetyDaysDescription"],
									type = "toggle",
									order = 6,
									get = function(info)
										return Spy.db.profile.PurgeData == "NinetyDays"
									end,
									set = function(info, value)
										Spy.db.profile.PurgeData = "NinetyDays"
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
								return Spy.db.profile.PurgeKoS
							end,
							set = function(info, value)
								Spy.db.profile.PurgeKoS = value
							end,
						},
						PurgeWinLossData = {
							name = L["PurgeWinLossData"],
							desc = L["PurgeWinLossDataDescription"],
							type = "toggle",
							order = 4,
							width = "full",
							get = function(info)
								return Spy.db.profile.PurgeWinLossData
							end,
							set = function(info, value)
								Spy.db.profile.PurgeWinLossData = value
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
								return Spy.db.profile.ShareData
							end,
							set = function(info, value)
								Spy.db.profile.ShareData = value
							end,
						},
						UseData = {
							name = L["UseData"],
							desc = L["UseDataDescription"],
							type = "toggle",
							order = 2,
							width = "full",
							get = function(info)
								return Spy.db.profile.UseData
							end,
							set = function(info, value)
								Spy.db.profile.UseData = value
							end,
						},
						ShareKOSBetweenCharacters = {
							name = L["ShareKOSBetweenCharacters"],
							desc = L["ShareKOSBetweenCharactersDescription"],
							type = "toggle",
							order = 3,
							width = "full",
							get = function(info)
								return Spy.db.profile.ShareKOSBetweenCharacters
							end,
							set = function(info, value)
								Spy.db.profile.ShareKOSBetweenCharacters = value
								if value then
									Spy:RegenerateKOSCentralList()
								end
							end,
						},
					},
				},
				DiagnosticsTab = {
					name = L["TTabDiagnostics"],
					desc = L["TTabDiagnostics"],
					type = "group",
					order = 3,
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
							get = function() return Spy.db.profile.DebugMode end,
							set = function(_, v)
								Spy.db.profile.DebugMode = v
								if v then Spy:CaptureDebugEnvironment() end
							end,
						},
						DebugDump = {
							name = L["DebugDumpButton"],
							desc = L["DebugDumpButtonDescription"],
							type = "execute",
							order = 3,
							func = function() Spy:ShowDebugDump() end,
						},
						DebugStatus = {
							name = L["DebugStatusButton"],
							desc = L["DebugStatusButtonDescription"],
							type = "execute",
							order = 4,
							func = function() Spy:DebugStatus() end,
						},
						DebugReset = {
							name = L["DebugResetButton"],
							type = "execute",
							order = 5,
							func = function() Spy:ResetDebug() Spy:Print(L["DebugWasReset"]) end,
						},
					},
				},
			},
		},
},
}

Spy.optionsSlash = {
	name = L["SlashCommand"],
	order = -3,
	type = "group",
	args = {
		intro = {
			name = L["SpySlashDescription"],
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
				if cmd == "on" or (cmd == "" and not Spy.db.profile.DebugMode) then
					Spy.db.profile.DebugMode = true
					Spy:CaptureDebugEnvironment()
					Spy:Print(L["DebugOn"])
				elseif cmd == "off" or cmd == "" then
					Spy.db.profile.DebugMode = false
					Spy:Print(L["DebugOff"])
				elseif cmd == "note" then
					Spy:DebugNote(rest)
					Spy:Print(L["DebugNoted"])
				elseif cmd == "dump" then
					Spy:ShowDebugDump()
				elseif cmd == "reset" then
					Spy:ResetDebug()
					Spy:Print(L["DebugWasReset"])
				elseif cmd == "status" then
					Spy:DebugStatus()
				else
					Spy:Print(L["DebugUsage"])
				end
			end,
		},
		show = {
			name = L["Show"],
			desc = L["ShowDescription"],
			type = 'execute',
			order = 2,
			func = function()
				Spy:EnableSpy(true, true)
			end,
			dialogHidden = true
		},
		hide = {
			name = L["Hide"],
			desc = L["HideDescription"],
			type = 'execute',
			order = 3,
			func = function()
				Spy:EnableSpy(false, true)
			end,
			dialogHidden = true
		},		
		reset = {
			name = L["Reset"],
			desc = L["ResetDescription"],
			type = 'execute',
			order = 4,
			func = function()
				Spy:ResetPositions()
			end,
			dialogHidden = true
		},
		clear = {
			name = L["ClearSlash"],
			desc = L["ClearSlashDescription"],
			type = 'execute',
			order = 5,
			func = function()
				Spy:ClearList()
			end,
			dialogHidden = true
		},			
		config = {
			name = L["Config"],
			desc = L["ConfigDescription"],
			type = 'execute',
			order = 6,
			func = function()
				Spy:ShowConfig()
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
				if Spy_IgnoreList[value] or strmatch(value, "[%s%d]+") then
					DEFAULT_CHAT_FRAME:AddMessage(value .. " - " .. L["InvalidInput"])
				else
					Spy:ToggleKOSPlayer(not SpyPerCharDB.KOSData[value], value)
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
				if Spy_IgnoreList[value] or strmatch(value, "[%s%d]+") then
					DEFAULT_CHAT_FRAME:AddMessage(value .. " - " .. L["InvalidInput"])
				else
					Spy:ToggleIgnorePlayer(not SpyPerCharDB.IgnoreData[value], value)
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
				SpyStats:Toggle()
			end,
			dialogHidden = true
		},
		test = {
			name = L["Test"],
			desc = L["TestDescription"],
			type = 'execute',
			order = 10,
			func = function()
				Spy:AlertStealthPlayer("Bazzalan")
			end
		},
		sanc = {
			name = L["Sanctuary"],
			desc = L["SanctuaryDescription"],
			type = 'execute',
			order = 11,
			func = function()
				Spy.db.profile.EnabledInSanctuaries = not Spy.db.profile.EnabledInSanctuaries
				Spy:ZoneChangedEvent()
	--			Spy:UpdateMainWindow()
	--			Spy:EnableSpy(false, true)
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
			-- Target-picker (healer marking / window styling) colours.
			["Spy"] = {
				["Healer Marker"] = { r = 79/255, g = 226/255, b = 122/255, a = 1 },
				["Healer Edge"] = { r = 79/255, g = 226/255, b = 122/255, a = 1 },
				["KoS Edge"] = { r = 1, g = 0, b = 0, a = 1 },
				["Window Border"] = { r = 1, g = 1, b = 1, a = 1 },
				["Title Bar"] = { r = 13/255, g = 11/255, b = 10/255, a = 1 },
				["Cooldown"] = { r = 1, g = 0.82, b = 0, a = 1 },
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
		CurrentList=1,
		Locked=false,

		-- ===== Target-picker enhancements =====
		-- Rows / look
		LookPreset="classbars",		-- classbars | flat | compact
		LookTheme="classic",		-- which colour bundle WindowTab's Theme picker last applied
		ClassColoredNames=false,	-- colour the name text by class (flat look)
		BarOpacity=1,				-- class-bar fill opacity (0 hides the fill)
		-- Healer detection & marking
		MarkHealers=true,
		HealerDetectBy="heal",		-- heal (confirmed only, default) | class (guess by class)
		HealerMinHeal=400,			-- a single heal this big confirms a healer outright
		HealerMinHeals=2,			-- or this many whitelisted heals, for smaller ones
		StrictHealerDetection=true,	-- only real healing spells count, not anything that heals
		HealerSpellListText="",		-- seeded from the built-in whitelist the first time it's needed
		HealerSpellListSeeded=false,
		HealerMarkerStyle="cross",	-- cross | asterisk | dot
		HealerMarkerSide="right",	-- right | left
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
		DisplayTooltipNearSpyWindow=false,
		TooltipAnchor="ANCHOR_CURSOR",
		DisplayWinLossStatistics=true,
		DisplayKOSReason=true,
		DisplayLastSeen=true,
		DisplayListData="1NameLevelClass",
		ShowOnDetection=true,
		HideSpy=false,
--		ShowOnlyPvPFlagged=false,
		ShowKoSButton=false,
		InvertSpy=false,
		ResizeSpy=true,
		ResizeSpyLimit=15,
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

SM:Register("statusbar", "Flat", [[Interface\Addons\Spy\Textures\bar-flat.tga]])

function Spy:CheckDatabase()
	if not SpyPerCharDB or not SpyPerCharDB.PlayerData then
		SpyPerCharDB = {}
	end
	SpyPerCharDB.version = Spy.DatabaseVersion
	if not SpyPerCharDB.PlayerData then
		SpyPerCharDB.PlayerData = {}
	end
	if not SpyPerCharDB.IgnoreData then
		SpyPerCharDB.IgnoreData = {}
	end
	if not SpyPerCharDB.KOSData then
		SpyPerCharDB.KOSData = {}
	end
	if SpyDB.kosData == nil then SpyDB.kosData = {} end
	if SpyDB.kosData[Spy.RealmName] == nil then SpyDB.kosData[Spy.RealmName] = {} end
	if SpyDB.kosData[Spy.RealmName][Spy.FactionName] == nil then SpyDB.kosData[Spy.RealmName][Spy.FactionName] = {} end
	if SpyDB.kosData[Spy.RealmName][Spy.FactionName][Spy.CharacterName] == nil then SpyDB.kosData[Spy.RealmName][Spy.FactionName][Spy.CharacterName] = {} end
	if SpyDB.removeKOSData == nil then SpyDB.removeKOSData = {} end
	if SpyDB.removeKOSData[Spy.RealmName] == nil then SpyDB.removeKOSData[Spy.RealmName] = {} end
	if SpyDB.removeKOSData[Spy.RealmName][Spy.FactionName] == nil then SpyDB.removeKOSData[Spy.RealmName][Spy.FactionName] = {} end
--[[	if Spy.db.profile == nil then Spy.db.profile = Default_Profile.profile end
	if Spy.db.profile.Colors == nil then Spy.db.profile.Colors = Default_Profile.profile.Colors end
	if Spy.db.profile.Colors["Window"] == nil then Spy.db.profile.Colors["Window"] = Default_Profile.profile.Colors["Window"] end
	if Spy.db.profile.Colors["Window"]["Title"] == nil then Spy.db.profile.Colors["Window"]["Title"] = Default_Profile.profile.Colors["Window"]["Title"] end
	if Spy.db.profile.Colors["Window"]["Background"] == nil then Spy.db.profile.Colors["Window"]["Background"] = Default_Profile.profile.Colors["Window"]["Background"] end
	if Spy.db.profile.Colors["Window"]["Title Text"] == nil then Spy.db.profile.Colors["Window"]["Title Text"] = Default_Profile.profile.Colors["Window"]["Title Text"] end
	if Spy.db.profile.Colors["Other Windows"] == nil then Spy.db.profile.Colors["Other Windows"] = Default_Profile.profile.Colors["Other Windows"] end
	if Spy.db.profile.Colors["Other Windows"]["Title"] == nil then Spy.db.profile.Colors["Other Windows"]["Title"] = Default_Profile.profile.Colors["Other Windows"]["Title"] end
	if Spy.db.profile.Colors["Other Windows"]["Background"] == nil then Spy.db.profile.Colors["Other Windows"]["Background"] = Default_Profile.profile.Colors["Other Windows"]["Background"] end
	if Spy.db.profile.Colors["Other Windows"]["Title Text"] == nil then Spy.db.profile.Colors["Other Windows"]["Title Text"] = Default_Profile.profile.Colors["Other Windows"]["Title Text"] end
	if Spy.db.profile.Colors["Bar"] == nil then Spy.db.profile.Colors["Bar"] = Default_Profile.profile.Colors["Bar"] end
	if Spy.db.profile.Colors["Bar"]["Bar Text"] == nil then Spy.db.profile.Colors["Bar"]["Bar Text"] = Default_Profile.profile.Colors["Bar"]["Bar Text"] end
	if Spy.db.profile.Colors["Warning"] == nil then Spy.db.profile.Colors["Warning"] = Default_Profile.profile.Colors["Warning"] end
	if Spy.db.profile.Colors["Warning"]["Warning Text"] == nil then Spy.db.profile.Colors["Warning"]["Warning Text"] = Default_Profile.profile.Colors["Warning"]["Warning Text"] end
	if Spy.db.profile.Colors["Tooltip"] == nil then Spy.db.profile.Colors["Tooltip"] = Default_Profile.profile.Colors["Tooltip"] end
	if Spy.db.profile.Colors["Tooltip"]["Title Text"] == nil then Spy.db.profile.Colors["Tooltip"]["Title Text"] = Default_Profile.profile.Colors["Tooltip"]["Title Text"] end
	if Spy.db.profile.Colors["Tooltip"]["Details Text"] == nil then Spy.db.profile.Colors["Tooltip"]["Details Text"] = Default_Profile.profile.Colors["Tooltip"]["Details Text"] end
	if Spy.db.profile.Colors["Tooltip"]["Location Text"] == nil then Spy.db.profile.Colors["Tooltip"]["Location Text"] = Default_Profile.profile.Colors["Tooltip"]["Location Text"] end
	if Spy.db.profile.Colors["Tooltip"]["Reason Text"] == nil then Spy.db.profile.Colors["Tooltip"]["Reason Text"] = Default_Profile.profile.Colors["Tooltip"]["Reason Text"] end
	if Spy.db.profile.Colors["Alert"] == nil then Spy.db.profile.Colors["Alert"] = Default_Profile.profile.Colors["Alert"] end
	if Spy.db.profile.Colors["Alert"]["Background"] == nil then Spy.db.profile.Colors["Alert"]["Background"] = Default_Profile.profile.Colors["Alert"]["Background"] end
	if Spy.db.profile.Colors["Alert"]["Icon"] == nil then Spy.db.profile.Colors["Alert"]["Icon"] = Default_Profile.profile.Colors["Alert"]["Icon"] end
	if Spy.db.profile.Colors["Alert"]["KOS Border"] == nil then Spy.db.profile.Colors["Alert"]["KOS Border"] = Default_Profile.profile.Colors["Alert"]["KOS Border"] end
	if Spy.db.profile.Colors["Alert"]["KOS Text"] == nil then Spy.db.profile.Colors["Alert"]["KOS Text"] = Default_Profile.profile.Colors["Alert"]["KOS Text"] end
	if Spy.db.profile.Colors["Alert"]["KOS Guild Border"] == nil then Spy.db.profile.Colors["Alert"]["KOS Guild Border"] = Default_Profile.profile.Colors["Alert"]["KOS Guild Border"] end
	if Spy.db.profile.Colors["Alert"]["KOS Guild Text"] == nil then Spy.db.profile.Colors["Alert"]["KOS Guild Text"] = Default_Profile.profile.Colors["Alert"]["KOS Guild Text"] end
	if Spy.db.profile.Colors["Alert"]["Stealth Border"] == nil then Spy.db.profile.Colors["Alert"]["Stealth Border"] = Default_Profile.profile.Colors["Alert"]["Stealth Border"] end
	if Spy.db.profile.Colors["Alert"]["Stealth Text"] == nil then Spy.db.profile.Colors["Alert"]["Stealth Text"] = Default_Profile.profile.Colors["Alert"]["Stealth Text"] end
	if Spy.db.profile.Colors["Alert"]["Away Border"] == nil then Spy.db.profile.Colors["Alert"]["Away Border"] = Default_Profile.profile.Colors["Alert"]["Away Border"] end
	if Spy.db.profile.Colors["Alert"]["Away Text"] == nil then Spy.db.profile.Colors["Alert"]["Away Text"] = Default_Profile.profile.Colors["Alert"]["Away Text"] end
	if Spy.db.profile.Colors["Alert"]["Location Text"] == nil then Spy.db.profile.Colors["Alert"]["Location Text"] = Default_Profile.profile.Colors["Alert"]["Location Text"] end
	if Spy.db.profile.Colors["Alert"]["Name Text"] == nil then Spy.db.profile.Colors["Alert"]["Name Text"] = Default_Profile.profile.Colors["Alert"]["Name Text"] end
	if Spy.db.profile.Colors["Class"] == nil then Spy.db.profile.Colors["Class"] = Default_Profile.profile.Colors["Class"] end
	if Spy.db.profile.Colors["Class"]["HUNTER"] == nil then Spy.db.profile.Colors["Class"]["HUNTER"] = Default_Profile.profile.Colors["Class"]["HUNTER"] end
	if Spy.db.profile.Colors["Class"]["WARLOCK"] == nil then Spy.db.profile.Colors["Class"]["WARLOCK"] = Default_Profile.profile.Colors["Class"]["WARLOCK"] end
	if Spy.db.profile.Colors["Class"]["PRIEST"] == nil then Spy.db.profile.Colors["Class"]["PRIEST"] = Default_Profile.profile.Colors["Class"]["PRIEST"] end
	if Spy.db.profile.Colors["Class"]["PALADIN"] == nil then Spy.db.profile.Colors["Class"]["PALADIN"] = Default_Profile.profile.Colors["Class"]["PALADIN"] end
	if Spy.db.profile.Colors["Class"]["MAGE"] == nil then Spy.db.profile.Colors["Class"]["MAGE"] = Default_Profile.profile.Colors["Class"]["MAGE"] end
	if Spy.db.profile.Colors["Class"]["ROGUE"] == nil then Spy.db.profile.Colors["Class"]["ROGUE"] = Default_Profile.profile.Colors["Class"]["ROGUE"] end
	if Spy.db.profile.Colors["Class"]["DRUID"] == nil then Spy.db.profile.Colors["Class"]["DRUID"] = Default_Profile.profile.Colors["Class"]["DRUID"] end
	if Spy.db.profile.Colors["Class"]["SHAMAN"] == nil then Spy.db.profile.Colors["Class"]["SHAMAN"] = Default_Profile.profile.Colors["Class"]["SHAMAN"] end
	if Spy.db.profile.Colors["Class"]["WARRIOR"] == nil then Spy.db.profile.Colors["Class"]["WARRIOR"] = Default_Profile.profile.Colors["Class"]["WARRIOR"] end
	if Spy.db.profile.Colors["Class"]["DEATHKNIGHT"] == nil then Spy.db.profile.Colors["Class"]["DEATHKNIGHT"] = Default_Profile.profile.Colors["Class"]["DEATHKNIGHT"] end
	if Spy.db.profile.Colors["Class"]["MONK"] == nil then Spy.db.profile.Colors["Class"]["MONK"] = Default_Profile.profile.Colors["Class"]["MONK"] end
	if Spy.db.profile.Colors["Class"]["DEMONHUNTER"] == nil then Spy.db.profile.Colors["Class"]["DEMONHUNTER"] = Default_Profile.profile.Colors["Class"]["DEMONHUNTER"] end	
	if Spy.db.profile.Colors["Class"]["PET"] == nil then Spy.db.profile.Colors["Class"]["PET"] = Default_Profile.profile.Colors["Class"]["PET"] end
	if Spy.db.profile.Colors["Class"]["MOB"] == nil then Spy.db.profile.Colors["Class"]["MOB"] = Default_Profile.profile.Colors["Class"]["MOB"] end
	if Spy.db.profile.Colors["Class"]["UNKNOWN"] == nil then Spy.db.profile.Colors["Class"]["UNKNOWN"] = Default_Profile.profile.Colors["Class"]["UNKNOWN"] end
	if Spy.db.profile.Colors["Class"]["HOSTILE"] == nil then Spy.db.profile.Colors["Class"]["HOSTILE"] = Default_Profile.profile.Colors["Class"]["HOSTILE"] end
	if Spy.db.profile.Colors["Class"]["UNGROUPED"] == nil then Spy.db.profile.Colors["Class"]["UNGROUPED"] = Default_Profile.profile.Colors["Class"]["UNGROUPED"] end
	if Spy.db.profile.MainWindow == nil then Spy.db.profile.MainWindow = Default_Profile.profile.MainWindow end
	if Spy.db.profile.MainWindow.Buttons == nil then Spy.db.profile.MainWindow.Buttons = Default_Profile.profile.MainWindow.Buttons end
	if Spy.db.profile.MainWindow.Buttons.ClearButton == nil then Spy.db.profile.MainWindow.Buttons.ClearButton = Default_Profile.profile.MainWindow.Buttons.ClearButton end
	if Spy.db.profile.MainWindow.Buttons.LeftButton == nil then Spy.db.profile.MainWindow.Buttons.LeftButton = Default_Profile.profile.MainWindow.Buttons.LeftButton end
	if Spy.db.profile.MainWindow.Buttons.RightButton == nil then Spy.db.profile.MainWindow.Buttons.RightButton = Default_Profile.profile.MainWindow.Buttons.RightButton end
	if Spy.db.profile.MainWindow.RowHeight == nil then Spy.db.profile.MainWindow.RowHeight = Default_Profile.profile.MainWindow.RowHeight end
	if Spy.db.profile.MainWindow.RowSpacing == nil then Spy.db.profile.MainWindow.RowSpacing = Default_Profile.profile.MainWindow.RowSpacing end
	if Spy.db.profile.MainWindow.TextHeight == nil then Spy.db.profile.MainWindow.TextHeight = Default_Profile.profile.MainWindow.TextHeight end
	if Spy.db.profile.MainWindow.AutoHide == nil then Spy.db.profile.MainWindow.AutoHide = Default_Profile.profile.MainWindow.AutoHide end
	if Spy.db.profile.MainWindow.BarText == nil then Spy.db.profile.MainWindow.BarText = Default_Profile.profile.MainWindow.BarText end
	if Spy.db.profile.MainWindow.BarText.RankNum == nil then Spy.db.profile.MainWindow.BarText.RankNum = Default_Profile.profile.MainWindow.BarText.RankNum end
	if Spy.db.profile.MainWindow.BarText.PerSec == nil then Spy.db.profile.MainWindow.BarText.PerSec = Default_Profile.profile.MainWindow.BarText.PerSec end
	if Spy.db.profile.MainWindow.BarText.Percent == nil then Spy.db.profile.MainWindow.BarText.Percent = Default_Profile.profile.MainWindow.BarText.Percent end
	if Spy.db.profile.MainWindow.BarText.NumFormat == nil then Spy.db.profile.MainWindow.BarText.NumFormat = Default_Profile.profile.MainWindow.BarText.NumFormat end
	if Spy.db.profile.MainWindow.Position == nil then Spy.db.profile.MainWindow.Position = Default_Profile.profile.MainWindow.Position end
	if Spy.db.profile.MainWindow.Position.x == nil then Spy.db.profile.MainWindow.Position.x = Default_Profile.profile.MainWindow.Position.x end
	if Spy.db.profile.MainWindow.Position.y == nil then Spy.db.profile.MainWindow.Position.y = Default_Profile.profile.MainWindow.Position.y end
	if Spy.db.profile.MainWindow.Position.w == nil then Spy.db.profile.MainWindow.Position.w = Default_Profile.profile.MainWindow.Position.w end
	if Spy.db.profile.MainWindow.Position.h == nil then Spy.db.profile.MainWindow.Position.h = Default_Profile.profile.MainWindow.Position.h end
	if Spy.db.profile.AlertWindowNameSize == nil then Spy.db.profile.AlertWindowNameSize = Default_Profile.profile.AlertWindowNameSize end
	if Spy.db.profile.AlertWindowLocationSize == nil then Spy.db.profile.AlertWindowLocationSize = Default_Profile.profile.AlertWindowLocationSize end
	if Spy.db.profile.BarTexture == nil then Spy.db.profile.BarTexture = Default_Profile.profile.BarTexture end
	if Spy.db.profile.MainWindowVis == nil then Spy.db.profile.MainWindowVis = Default_Profile.profile.MainWindowVis end
	if Spy.db.profile.CurrentList == nil then Spy.db.profile.CurrentList = Default_Profile.profile.CurrentList end
	if Spy.db.profile.Locked == nil then Spy.db.profile.Locked = Default_Profile.profile.Locked end
	if Spy.db.profile.Font == nil then Spy.db.profile.Font = Default_Profile.profile.Font end
	if Spy.db.profile.Scaling == nil then Spy.db.profile.Scaling = Default_Profile.profile.Scaling end
	if Spy.db.profile.Enabled == nil then Spy.db.profile.Enabled = Default_Profile.profile.Enabled end
	if Spy.db.profile.EnabledInBattlegrounds == nil then Spy.db.profile.EnabledInBattlegrounds = Default_Profile.profile.EnabledInBattlegrounds end
	if Spy.db.profile.EnabledInSanctuaries == nil then Spy.db.profile.EnabledInSanctuaries = Default_Profile.profile.EnabledInSanctuaries end
	if Spy.db.profile.EnabledInArenas == nil then Spy.db.profile.EnabledInArenas = Default_Profile.profile.EnabledInArenas end
	if Spy.db.profile.EnabledInWintergrasp == nil then Spy.db.profile.EnabledInWintergrasp = Default_Profile.profile.EnabledInWintergrasp end
	if Spy.db.profile.DisableWhenPVPUnflagged == nil then Spy.db.profile.DisableWhenPVPUnflagged = Default_Profile.profile.DisableWhenPVPUnflagged end
	if Spy.db.profile.MinimapDetection == nil then Spy.db.profile.MinimapDetection = Default_Profile.profile.MinimapDetection end
	if Spy.db.profile.MinimapDetails == nil then Spy.db.profile.MinimapDetails = Default_Profile.profile.MinimapDetails end
	if Spy.db.profile.DisplayOnMap == nil then Spy.db.profile.DisplayOnMap = Default_Profile.profile.DisplayOnMap end
	if Spy.db.profile.SwitchToZone == nil then Spy.db.profile.SwitchToZone = Default_Profile.profile.SwitchToZone end	
	if Spy.db.profile.MapDisplayLimit == nil then Spy.db.profile.MapDisplayLimit = Default_Profile.profile.MapDisplayLimit end
	if Spy.db.profile.DisplayTooltipNearSpyWindow == nil then Spy.db.profile.DisplayTooltipNearSpyWindow = Default_Profile.profile.DisplayTooltipNearSpyWindow end	
	if Spy.db.profile.TooltipAnchor == nil then Spy.db.profile.TooltipAnchor = Default_Profile.profile.TooltipAnchor end	
	if Spy.db.profile.DisplayWinLossStatistics == nil then Spy.db.profile.DisplayWinLossStatistics = Default_Profile.profile.DisplayWinLossStatistics end
	if Spy.db.profile.DisplayKOSReason == nil then Spy.db.profile.DisplayKOSReason = Default_Profile.profile.DisplayKOSReason end
	if Spy.db.profile.DisplayLastSeen == nil then Spy.db.profile.DisplayLastSeen = Default_Profile.profile.DisplayLastSeen end
	if Spy.db.profile.ShowOnDetection == nil then Spy.db.profile.ShowOnDetection = Default_Profile.profile.ShowOnDetection end
	if Spy.db.profile.HideSpy == nil then Spy.db.profile.HideSpy = Default_Profile.profile.HideSpy end
--	if Spy.db.profile.ShowOnlyPvPFlagged == nil then Spy.db.profile.ShowOnlyPvPFlagged = Default_Profile.profile.ShowOnlyPvPFlagged end	
	if Spy.db.profile.ShowKoSButton == nil then Spy.db.profile.ShowKoSButton = Default_Profile.profile.ShowKoSButton end	
	if Spy.db.profile.InvertSpy == nil then Spy.db.profile.InvertSpy = Default_Profile.profile.InvertSpy end
	if Spy.db.profile.ResizeSpy == nil then Spy.db.profile.ResizeSpy = Default_Profile.profile.ResizeSpy end
	if Spy.db.profile.ResizeSpyLimit == nil then Spy.db.profile.ResizeSpyLimit = Default_Profile.profile.ResizeSpyLimit end 
	if Spy.db.profile.Announce == nil then Spy.db.profile.Announce = Default_Profile.profile.Announce end
	if Spy.db.profile.OnlyAnnounceKoS == nil then Spy.db.profile.OnlyAnnounceKoS = Default_Profile.profile.OnlyAnnounceKoS end
	if Spy.db.profile.WarnOnStealth == nil then Spy.db.profile.WarnOnStealth = Default_Profile.profile.WarnOnStealth end
	if Spy.db.profile.WarnOnKOS == nil then Spy.db.profile.WarnOnKOS = Default_Profile.profile.WarnOnKOS end
	if Spy.db.profile.WarnOnKOSGuild == nil then Spy.db.profile.WarnOnKOSGuild = Default_Profile.profile.WarnOnKOSGuild end
	if Spy.db.profile.WarnOnRace == nil then Spy.db.profile.WarnOnRace = Default_Profile.profile.WarnOnRace end
	if Spy.db.profile.SelectWarnRace == nil then Spy.db.profile.SelectWarnRace = Default_Profile.profile.SelectWarnRace end
	if Spy.db.profile.DisplayWarningsInErrorsFrame == nil then Spy.db.profile.DisplayWarningsInErrorsFrame = Default_Profile.profile.DisplayWarningsInErrorsFrame end
	if Spy.db.profile.EnableSound == nil then Spy.db.profile.EnableSound = Default_Profile.profile.EnableSound end
	if Spy.db.profile.OnlySoundKoS == nil then Spy.db.profile.OnlySoundKoS = Default_Profile.profile.OnlySoundKoS end	
	if Spy.db.profile.StopAlertsOnTaxi == nil then Spy.db.profile.StopAlertsOnTaxi = Default_Profile.profile.StopAlertsOnTaxi end 	
	if Spy.db.profile.RemoveUndetected == nil then Spy.db.profile.RemoveUndetected = Default_Profile.profile.RemoveUndetected end
	if Spy.db.profile.ShowNearbyList == nil then Spy.db.profile.ShowNearbyList = Default_Profile.profile.ShowNearbyList end
	if Spy.db.profile.PrioritiseKoS == nil then Spy.db.profile.PrioritiseKoS = Default_Profile.profile.PrioritiseKoS end
	if Spy.db.profile.PurgeData == nil then Spy.db.profile.PurgeData = Default_Profile.profile.PurgeData end
	if Spy.db.profile.PurgeKoS == nil then Spy.db.profile.PurgeKoS = Default_Profile.profile.PurgeKoSData end	
	if Spy.db.profile.PurgeWinLossData == nil then Spy.db.profile.PurgeWinLossData = Default_Profile.profile.PurgeWinLossData end	
	if Spy.db.profile.ShareData == nil then Spy.db.profile.ShareData = Default_Profile.profile.ShareData end
	if Spy.db.profile.UseData == nil then Spy.db.profile.UseData = Default_Profile.profile.UseData end
	if Spy.db.profile.ShareKOSBetweenCharacters == nil then Spy.db.profile.ShareKOSBetweenCharacters = Default_Profile.profile.ShareKOSBetweenCharacters end
	if Spy.db.profile.AppendUnitNameCheck == nil then Spy.db.profile.AppendUnitNameCheck = Default_Profile.profile.AppendUnitNameCheck end
	if Spy.db.profile.AppendUnitKoSCheck == nil then Spy.db.profile.AppendUnitKoSCheck = Default_Profile.profile.AppendUnitKoSCheck end	]]--

	-- Target-picker settings migration. AceDB merges the Default_Profile
	-- defaults for us, but guard the new keys explicitly so existing profiles
	-- saved before this version pick them up cleanly (and any partially-saved
	-- nested Colors table is completed).
	local p = Spy.db.profile
	if p.MarkHealers == nil then p.MarkHealers = Default_Profile.profile.MarkHealers end
	if p.HealerDetectBy == nil then p.HealerDetectBy = Default_Profile.profile.HealerDetectBy end
	if p.HealerMarkerStyle == nil then p.HealerMarkerStyle = Default_Profile.profile.HealerMarkerStyle end
	if p.HealerMarkerSide == nil then p.HealerMarkerSide = Default_Profile.profile.HealerMarkerSide end
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
	if p.UseZoneLevelFloor == nil then p.UseZoneLevelFloor = Default_Profile.profile.UseZoneLevelFloor end
	if p.TomTomOnAltClick == nil then p.TomTomOnAltClick = Default_Profile.profile.TomTomOnAltClick end
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
	if SpyPerCharDB and SpyPerCharDB.PlayerData and not SpyPerCharDB.healerFlagsReset then
		for _, data in pairs(SpyPerCharDB.PlayerData) do
			data.isHealer = nil
			data.healTotal = nil
			data.healCount = nil
		end
		SpyPerCharDB.healerFlagsReset = true
	end
	if p.Colors["Spy"] == nil then p.Colors["Spy"] = {} end
	for k, v in pairs(Default_Profile.profile.Colors["Spy"]) do
		if p.Colors["Spy"][k] == nil then
			p.Colors["Spy"][k] = { r = v.r, g = v.g, b = v.b, a = v.a }
		end
	end
end

function Spy:ResetProfile()
	Spy.db.profile = Default_Profile.profile
--	Spy:CheckDatabase()
end

function Spy:HandleProfileChanges()
	Spy:CreateMainWindow()
	Spy:RestoreMainWindowPosition(Spy.db.profile.MainWindow.Position.x, Spy.db.profile.MainWindow.Position.y, Spy.db.profile.MainWindow.Position.w, 34)
	Spy:ResizeMainWindow()
	Spy:UpdateTimeoutSettings()
	Spy:LockWindows(Spy.db.profile.Locked)
	Spy:ApplyWindowLocks()
	Spy:ApplyWindowStyle()
	Spy:ClampToScreen(Spy.db.profile.ClampToScreen)
end

function Spy:RegisterModuleOptions(name, optionTbl, displayName)
	Spy.options.args[name] = (type(optionTbl) == "function") and optionTbl() or optionTbl
	self.optionsFrames[name] = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Spy", displayName, L["Spy Option"], name)
end

function Spy:SetupOptions()
	self.optionsFrames = {}

 	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("Spy", Spy.options)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Spy Commands", Spy.optionsSlash, "spy")

	-- One Blizzard sub-panel per page. The second level lives in tabs inside
	-- each page rather than as more entries here, which is the whole point of
	-- the layout: seven rows in the sidebar instead of ten.
	local ACD3 = LibStub("AceConfigDialog-3.0")
	self.optionsFrames.Spy = ACD3:AddToBlizOptions("Spy", L["Spy Option"], nil, "SpyGroup")
	self.optionsFrames.About = ACD3:AddToBlizOptions("Spy", L["About"], L["Spy Option"], "About")
	self.optionsFrames.Targeting = ACD3:AddToBlizOptions("Spy", L["TPageTargeting"], L["Spy Option"], "Targeting")
	self.optionsFrames.Finding = ACD3:AddToBlizOptions("Spy", L["TPageFinding"], L["Spy Option"], "Finding")
	self.optionsFrames.Look = ACD3:AddToBlizOptions("Spy", L["TPageLook"], L["Spy Option"], "Look")
	self.optionsFrames.Alerts = ACD3:AddToBlizOptions("Spy", L["TPageAlerts"], L["Spy Option"], "Alerts")
	self.optionsFrames.Data = ACD3:AddToBlizOptions("Spy", L["TPageData"], L["Spy Option"], "Data")

	self:RegisterModuleOptions("Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db), L["Profiles"])
	Spy.options.args.Profiles.order = -2
end

function Spy:UpdateTimeoutSettings()
	if not Spy.db.profile.RemoveUndetected or Spy.db.profile.RemoveUndetected == "OneMinute" then
		Spy.ActiveTimeout = 30
		Spy.InactiveTimeout = 60
	elseif Spy.db.profile.RemoveUndetected == "TwoMinutes" then
		Spy.ActiveTimeout = 60
		Spy.InactiveTimeout = 120
	elseif Spy.db.profile.RemoveUndetected == "FiveMinutes" then
		Spy.ActiveTimeout = 150
		Spy.InactiveTimeout = 300
	elseif Spy.db.profile.RemoveUndetected == "TenMinutes" then
		Spy.ActiveTimeout = 300
		Spy.InactiveTimeout = 600
	elseif Spy.db.profile.RemoveUndetected == "FifteenMinutes" then
		Spy.ActiveTimeout = 450
		Spy.InactiveTimeout = 900
	elseif Spy.db.profile.RemoveUndetected == "Never" then
		Spy.ActiveTimeout = 30
		Spy.InactiveTimeout = -1
	else
		Spy.ActiveTimeout = 150
		Spy.InactiveTimeout = 300
	end
end

function Spy:ResetMainWindow() -- not used
	Spy:EnableSpy(true, true)
	Spy:CreateMainWindow()
	Spy:RestoreMainWindowPosition(Default_Profile.profile.MainWindow.Position.x, Default_Profile.profile.MainWindow.Position.y, Default_Profile.profile.MainWindow.Position.w, 34)
	Spy:RefreshCurrentList()
end

function Spy:ResetPositions()
	Spy:ResetPositionAllWindows()
end

function Spy:ShowConfig()
	-- Open the top-level Spy category. NOTE: on the modern Settings API,
	-- AceConfigDialog gives sub-categories (e.g. "Profiles") a generated
	-- numeric ID, so passing the string "Profiles" to Settings.OpenToCategory
	-- errors ("outside of expected range"). Only the top-level category keeps
	-- a string ID, so open that via the frame name AceConfigDialog stored.
	local spyCategory = self.optionsFrames and self.optionsFrames.Spy and self.optionsFrames.Spy.name or "Spy"
	if Settings and Settings.OpenToCategory then
		Settings.OpenToCategory(spyCategory)
	elseif InterfaceOptionsFrame_OpenToCategory then
		-- Older clients need the call twice to actually land on the panel.
		InterfaceOptionsFrame_OpenToCategory(self.optionsFrames.Spy)
		InterfaceOptionsFrame_OpenToCategory(self.optionsFrames.Spy)
	end
end

function Spy:OnEnable(first)
	-- Resolve the healer spell whitelist to localised names, and merge any
	-- user-added cooldowns into the runtime lookup. Done here rather than at
	-- file scope because GetSpellInfo is not reliable until the addon is enabled.
	Spy:BuildHealerSpellNames()
	Spy:BuildCooldownLookup()
	Spy.timeid = Spy:ScheduleRepeatingTimer("ManageExpirations", 10, true)
	Spy:RegisterEvent("ZONE_CHANGED", "ZoneChangedEvent")
	Spy:RegisterEvent("ZONE_CHANGED_INDOORS", "ZoneChangedEvent")
--	Spy:RegisterEvent("ZONE_CHANGED_NEW_AREA", "ZoneChangedEvent")
	Spy:RegisterEvent("ZONE_CHANGED_NEW_AREA", "ZoneChangedNewAreaEvent")
--	Spy:RegisterEvent("PLAYER_ENTERING_WORLD", "ZoneChangedEvent")
	Spy:RegisterEvent("PLAYER_ENTERING_WORLD", "PlayerEnteringWorldEvent")
	Spy:RegisterEvent("UNIT_FACTION", "ZoneChangedEvent")
	Spy:RegisterEvent("PLAYER_TARGET_CHANGED", "PlayerTargetEvent")
	Spy:RegisterEvent("UPDATE_MOUSEOVER_UNIT", "PlayerMouseoverEvent")
	Spy:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "CombatLogEvent")
	Spy:RegisterEvent("UNIT_PET", "UnitPets")
	Spy:RegisterEvent("PLAYER_REGEN_ENABLED", "LeftCombatEvent")
	Spy:RegisterEvent("PLAYER_DEAD", "PlayerDeadEvent")
	Spy:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE", "ChannelNoticeEvent")
	Spy:RegisterEvent("NAME_PLATE_UNIT_ADDED", "NamePlateEvent")
	Spy:RegisterEvent("NAME_PLATE_UNIT_REMOVED", "NamePlateEvent")
	-- Enemy defensive cooldowns (PvP trinket, immunities) are NOT emitted by the
	-- combat log - they only surface through the spellcast events.
	Spy:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "UnitSpellcastEvent")
	Spy:RegisterComm(Spy.Signature, "CommReceived")
	if Spy.HookDebugErrors then Spy:HookDebugErrors() end
	if Spy:IsDebugging() then Spy:CaptureDebugEnvironment() end
	Spy.IsEnabled = true
--	Spy:RefreshCurrentList()
end

function Spy:OnDisable()
	if not Spy.IsEnabled then
		return
	end
	if Spy.timeid then
		Spy:CancelTimer(Spy.timeid)
		Spy.timeid = nil
	end
	Spy:UnregisterEvent("ZONE_CHANGED")
	Spy:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
	Spy:UnregisterEvent("ZONE_CHANGED_INDOORS")
	Spy:UnregisterEvent("PLAYER_ENTERING_WORLD")
	Spy:UnregisterEvent("UNIT_FACTION")
	Spy:UnregisterEvent("PLAYER_TARGET_CHANGED")
	Spy:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
	Spy:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	Spy:UnregisterEvent("PLAYER_REGEN_ENABLED")
	Spy:UnregisterEvent("PLAYER_DEAD")
	Spy:UnregisterEvent("CHAT_MSG_CHANNEL_NOTICE")
	Spy:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
	Spy:UnregisterEvent("NAME_PLATE_UNIT_REMOVED")
	Spy:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	Spy:UnregisterComm(Spy.Signature)
	Spy.IsEnabled = false
end

function Spy:EnableSpy(value, changeDisplay, hideEnabledMessage)
	Spy.db.profile.Enabled = value
	if value then
		if changeDisplay and not InCombatLockdown() then
			Spy.MainWindow:Show()
		end
		Spy:OnEnable()
		if not hideEnabledMessage then
			DEFAULT_CHAT_FRAME:AddMessage(L["SpyEnabled"])
		end
	else
		if changeDisplay and not InCombatLockdown() then
			Spy.MainWindow:Hide()
		end
		Spy:OnDisable()
		DEFAULT_CHAT_FRAME:AddMessage(L["SpyDisabled"])
	end
end

function Spy:EnableSound(value)
	Spy.db.profile.EnableSound = value
	if value then
		DEFAULT_CHAT_FRAME:AddMessage(L["SoundEnabled"]) 
	else
		DEFAULT_CHAT_FRAME:AddMessage(L["SoundDisabled"])
	end
end

function Spy:OnInitialize()
--	WorldMapFrame:Show()
--	WorldMapFrame:Hide()

	Spy.RealmName = GetRealmName()
    Spy.FactionName = select(1, UnitFactionGroup("player"))
	if Spy.FactionName == "Alliance" then
		Spy.EnemyFactionName = "Horde"
	elseif Spy.FactionName == "Horde" then
		Spy.EnemyFactionName = "Alliance"
	else
		Spy.EnemyFactionName = "None"
	end
	Spy.CharacterName = UnitName("player")

	Spy.ValidClasses = {
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

	Spy.ValidRaces = {
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

	Spy.db = acedb:New("SpyDB", Default_Profile)
	Spy:CheckDatabase()

--	self.db.RegisterCallback(self, "OnNewProfile", "ResetProfile")
	self.db.RegisterCallback(self, "OnNewProfile", "HandleProfileChanges")
--	self.db.RegisterCallback(self, "OnProfileReset", "ResetProfile")
	self.db.RegisterCallback(self, "OnProfileReset", "HandleProfileChanges")
	self.db.RegisterCallback(self, "OnProfileChanged", "HandleProfileChanges")
	self.db.RegisterCallback(self, "OnProfileCopied", "HandleProfileChanges")
	self:SetupOptions()

	SpyTempTooltip = CreateFrame("GameTooltip", "SpyTempTooltip", nil, "GameTooltipTemplate")
	SpyTempTooltip:SetOwner(UIParent, "ANCHOR_NONE")

	Spy:RegenerateKOSGuildList()
	if Spy.db.profile.ShareKOSBetweenCharacters then
		Spy:RemoveLocalKOSPlayers()
		Spy:RegenerateKOSCentralList()
		Spy:RegenerateKOSListFromCentral()
	end
	Spy:PurgeUndetectedData()
	Spy:CreateMainWindow()
	Spy:CreateKoSButton()
	Spy:UpdateTimeoutSettings()

	SM.RegisterCallback(Spy, "LibSharedMedia_Registered", "UpdateBarTextures")
	SM.RegisterCallback(Spy, "LibSharedMedia_SetGlobal", "UpdateBarTextures")
	if Spy.db.profile.BarTexture then
		Spy:SetBarTextures(Spy.db.profile.BarTexture)
	end

	Spy:LockWindows(Spy.db.profile.Locked)
	Spy:ClampToScreen(Spy.db.profile.ClampToScreen)	
	ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", Spy.FilterNotInParty)
	Spy.WoWBuildInfo = select(4, GetBuildInfo())
	if Spy.WoWBuildInfo < 20000 or Spy.WoWBuildInfo > 30000 then
		DEFAULT_CHAT_FRAME:AddMessage(L["VersionCheck"])
	end
end

function Spy:ChannelNoticeEvent(_, chStatus, _, _, Channel)
	if chStatus ~= "SUSPENDED" then
		Spy.ChnlTime = time()
		local channel, zone = string.match(Channel, "(.+) %- (.+)")
--		local subZone = GetSubZoneText()
		local InFilteredZone = Spy:InFilteredZone(zone)
		if InFilteredZone then
			Spy.EnabledInZone = false
		end
	end
end

function Spy:PlayerEnteringWorldEvent()
	Spy.EnabledInZone = false
	local now = time()
	if Spy.ChnlTime > (now - 6) then
		self:ScheduleTimer("PlayerEnteringWorldEvent",6)
		return	
	else 
		Spy:ZoneChanged()
	end
end

function Spy:ZoneChangedEvent()
	local now = time()
	if Spy.ChnlTime > (now - 6) then
		self:ScheduleTimer("ZoneChangedEvent",6)
		return
	else 
		Spy:ZoneChanged()
	end
end

function Spy:ZoneChangedNewAreaEvent()
	local now = time()
	if Spy.ChnlTime > (now - 6) then
		self:ScheduleTimer("ZoneChangedNewAreaEvent",6)
		return
	else 
		Spy:ZoneChanged()
	end
end

function Spy:ZoneChanged()
	Spy.InInstance = false
	local pvpType = GetZonePVPInfo()
 	local zone = GetZoneText()
	local subZone = GetSubZoneText()
	local InFilteredZone = Spy:InFilteredZone(zone, subZone)
	if pvpType == "sanctuary" and not Spy.db.profile.EnabledInSanctuaries then
		Spy.EnabledInZone = false
	else
		Spy.EnabledInZone = true
		if zone == "" or InFilteredZone then
			Spy.EnabledInZone = false
		else
			Spy.EnabledInZone = true
		local inInstance, instanceType = IsInInstance()
		if inInstance then
			Spy.InInstance = true
			if instanceType == "party" or instanceType == "raid" or (not Spy.db.profile.EnabledInBattlegrounds and instanceType == "pvp") or (not Spy.db.profile.EnabledInArenas and instanceType == "arena") then
				Spy.EnabledInZone = false
			end
		elseif pvpType == "combat" then
			if not Spy.db.profile.EnabledInWintergrasp then
				Spy.EnabledInZone = false
			end
--		elseif (pvpType == "friendly" or pvpType == nil) then
			elseif UnitIsPVP("player") == false and Spy.db.profile.DisableWhenPVPUnflagged then
				Spy.EnabledInZone = false
--				end
			end
		end
	end

	if Spy.EnabledInZone then
		if not Spy.db.profile.HideSpy then
			if not InCombatLockdown() then Spy.MainWindow:Show() end
			Spy:RefreshCurrentList()
		end
	else
		if not InCombatLockdown() then Spy.MainWindow:Hide() end
	end
	Spy:UpdateMainWindow()
end

function Spy:InFilteredZone(zone, subzone)
	local InFilteredZone = false
	for filteredZone, value in pairs(Spy.db.profile.FilteredZones) do
		if zone == filteredZone and value then
			InFilteredZone = true
		elseif subzone == filteredZone and value then
			InFilteredZone = true
--			break
		end
	end
	return InFilteredZone
end

function Spy:PlayerTargetEvent()
	local name = GetUnitName("target", true)
	if name and UnitIsPlayer("target") and not SpyPerCharDB.IgnoreData[name] then
		local playerData = SpyPerCharDB.PlayerData[name]
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
			if level == Spy.Skull then
				if playerData and playerData.level then
					if playerData.level > (UnitLevel("player") + 10) and playerData.level < Spy.MaximumPlayerLevel then	
						guess = true
						level = nil
					elseif UnitLevel("player") < Spy.MaximumPlayerLevel - 9 then
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
			
			Spy:UpdatePlayerData(name, class, level, race, guild, faction, true, guess)
			if Spy.EnabledInZone then
				Spy:AddDetected(name, time(), learnt)
			end
		elseif playerData then
			Spy:RemovePlayerData(name)
		end
	end
end

function Spy:PlayerMouseoverEvent()
	local name = GetUnitName("mouseover", true)
	if name and UnitIsPlayer("mouseover") and not SpyPerCharDB.IgnoreData[name] then
		local playerData = SpyPerCharDB.PlayerData[name]
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
			if level == Spy.Skull then
				if playerData and playerData.level then
					if playerData.level > (UnitLevel("player") + 10) and playerData.level < Spy.MaximumPlayerLevel then	
						guess = true
						level = nil
					elseif UnitLevel("player") < Spy.MaximumPlayerLevel - 9 then
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

			Spy:UpdatePlayerData(name, class, level, race, guild, faction, true, guess)
			if Spy.EnabledInZone then
				Spy:AddDetected(name, time(), learnt)
			end
		elseif playerData then 
			Spy:RemovePlayerData(name)
		end
	end
end

function Spy:NamePlateEvent(_, unit)
	local name = GetUnitName(unit, true)
	if name and UnitIsPlayer(unit) and not SpyPerCharDB.IgnoreData[name] then
		local playerData = SpyPerCharDB.PlayerData[name]
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
			if level == Spy.Skull then
				if playerData and playerData.level then
					if playerData.level > (UnitLevel("player") + 10) and playerData.level < Spy.MaximumPlayerLevel then	
						guess = true
						level = nil
					elseif UnitLevel("player") < Spy.MaximumPlayerLevel - 9 then
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

			Spy:UpdatePlayerData(name, class, level, race, guild, faction, true, guess)
			if Spy.EnabledInZone then
				Spy:AddDetected(name, time(), learnt)
			end
		elseif playerData then 
			Spy:RemovePlayerData(name)
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
Spy.TrackedCooldowns = {
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
Spy.CooldownLookup = {}
Spy.CooldownListAdded = 0
Spy.CooldownListUnresolved = 0

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
	for id in pairs(Spy.TrackedCooldowns) do ids[#ids + 1] = id end
	-- Sorted by cooldown length then name, so the list reads in a stable order
	-- rather than pairs() order, which differs between sessions.
	table.sort(ids, function(a, b)
		local ia, ib = Spy.TrackedCooldowns[a], Spy.TrackedCooldowns[b]
		if ia.cd ~= ib.cd then return ia.cd < ib.cd end
		return ia.name < ib.name
	end)
	local lines = {}
	for _, id in ipairs(ids) do
		local info = Spy.TrackedCooldowns[id]
		local mins = info.cd / 60
		local pretty = (mins >= 1) and (format("%gm", mins)) or (format("%ds", info.cd))
		lines[#lines + 1] = format("%d  -- %s (%s)", id, info.name, pretty)
	end
	defaultCooldownListTextCache = table.concat(lines, "\n")
	return defaultCooldownListTextCache
end

-- Every watched spell comes from the profile's list - there is no hidden set
-- running underneath it. Deleting a line genuinely stops that cooldown being
-- tracked, which is the whole point of showing the list instead of describing
-- it. TrackedCooldowns is now only reference data: the researched durations for
-- the spells Spy ships with, used when the client cannot supply one.
--
-- A line needs a resolvable spell id, unlike the healer list which matches on
-- name: UnitSpellcastEvent is handed the numeric id by
-- UNIT_SPELLCAST_SUCCEEDED, so a bare name could never match. Unresolvable
-- lines are counted and surfaced rather than silently ignored.
function Spy:BuildCooldownLookup()
	wipe(Spy.CooldownLookup)
	local p = Spy.db and Spy.db.profile
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
			local id = tonumber(trimmed:match("spell:(%d+)")) or tonumber(trimmed:match("^(%d+)"))
			if id then
				local known = Spy.TrackedCooldowns[id]
				if known then
					Spy.CooldownLookup[id] = known
				else
					local ok, name = pcall(GetSpellInfo, id)
					name = (ok and type(name) == "string" and name ~= "") and name or ("Spell "..id)
					Spy.CooldownLookup[id] = {
						name = name,
						cd = resolveCooldownSeconds(id) or 120,
						short = (#name <= 6) and name or name:sub(1, 6),
					}
				end
			else
				unresolved = unresolved + 1
			end
		end
	end
	Spy.CooldownListUnresolved = unresolved
end

-- Restores the ten researched defaults, discarding any edits.
function Spy:ResetCooldownList()
	Spy.db.profile.CooldownListText = defaultCooldownListText()
	Spy.db.profile.CooldownListSeeded = true
	Spy:BuildCooldownLookup()
end

function Spy:UnitSpellcastEvent(_, unit, _, spellId)
	if not Spy.db.profile.TrackCooldowns then return end
	if not unit or not spellId then return end
	local info = Spy.CooldownLookup[spellId]
	if not info then return end
	-- only care about hostile players
	if not UnitExists(unit) or not UnitIsPlayer(unit) then return end
	if not UnitCanAttack("player", unit) then return end

	local name = GetUnitName(unit, true)
	if not name then return end
	name = gsub(name, " %- ", "-")
	local playerData = SpyPerCharDB.PlayerData[name]
	if not playerData then return end

	playerData.cdSpell = info.short
	playerData.cdName = info.name
	playerData.cdUsed = GetTime()
	playerData.cdExpires = GetTime() + info.cd

	if Spy.db.profile.AnnounceCooldowns then
		DEFAULT_CHAT_FRAME:AddMessage(format(L["CooldownUsed"], name, info.name))
	end
	Spy:RefreshCurrentList()
end

-- Redraws the list once per second while any displayed enemy has a cooldown
-- running, so the countdown actually ticks. No-op the rest of the time.
function Spy:TickCooldowns()
	if not Spy.db.profile.TrackCooldowns then return end
	if not Spy.MainWindow or not Spy.MainWindow:IsShown() then return end
	local active = false
	for i = 1, (Spy.ListAmountDisplayed or 0) do
		local name = Spy.ButtonName[i]
		local playerData = name and SpyPerCharDB.PlayerData[name]
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
	if active then Spy:RefreshCurrentList() end
end

-- Remaining seconds on a tracked enemy cooldown, or nil when nothing is active.
function Spy:GetCooldownRemaining(playerData)
	if not playerData or not playerData.cdExpires then return nil end
	local left = playerData.cdExpires - GetTime()
	if left <= 0 then return nil end
	return left, playerData.cdSpell
end

-- ============================================================
-- Zone level floors.
--
-- Spy guesses levels from which spells it has seen an enemy cast, which
-- produces nonsense in Outland: a capture of two sessions there had EVERY
-- hostile at level 70, while Spy was displaying "16+" and "30+". Nobody can
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
Spy.ContinentLevelFloor = {
	[530] = 58,	-- Outland - Dark Portal, so Hellfire's entry level
	[571] = 68,	-- Northrend, harmless here and correct if ever used
}

-- Per-zone refinement, keyed by UiMapID. Both id spaces are listed because the
-- same addon runs on both, and a wrong floor is worse than no floor - so only
-- ids that have been confirmed against a real client are here. Anything absent
-- falls back to the continent floor above.
Spy.ZoneLevelFloor = {
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
function Spy:GetZoneLevelFloor(mapID)
	if not Spy.db.profile.UseZoneLevelFloor then return nil end
	if not mapID and C_Map and C_Map.GetBestMapForUnit then
		mapID = C_Map.GetBestMapForUnit("player")
	end

	local floor = (type(mapID) == "number") and Spy.ZoneLevelFloor[mapID] or nil

	local instanceID = currentInstanceID()
	local continent = instanceID and Spy.ContinentLevelFloor[instanceID] or nil
	if continent and (not floor or continent > floor) then floor = continent end

	if floor and floor > Spy.MaximumPlayerLevel then floor = Spy.MaximumPlayerLevel end
	return floor
end

-- Applies the floor to a stored record. Only ever raises a GUESSED level -
-- a level read directly off a unit is authoritative and left alone.
function Spy:ApplyZoneLevelFloor(playerData)
	if not playerData or playerData.isGuess == false then return end
	-- mapID is only recorded on a first sighting where coordinates resolved, so
	-- it's nil for most records. Detection always happens near us, so fall back
	-- to the zone we're standing in.
	local floor = Spy:GetZoneLevelFloor(playerData.mapID) or Spy:GetZoneLevelFloor()
	if Spy.DebugZone then
		Spy:DebugZone(playerData.mapID or (C_Map and C_Map.GetBestMapForUnit
			and C_Map.GetBestMapForUnit("player")))
	end
	if not floor then return end
	local current = tonumber(playerData.level)
	if not current or current < floor then
		playerData.level = floor
	end
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
local Spy_HealerSpellIDs = {
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
	for _, id in ipairs(Spy_HealerSpellIDs) do
		local ok, name = pcall(GetSpellInfo, id)
		if ok and type(name) == "string" and name ~= "" then
			names[#names + 1] = name
		end
	end
	table.sort(names)
	defaultHealerListTextCache = table.concat(names, "\n")
	return defaultHealerListTextCache
end

-- A line in the editable list is a plain spell name (what the seeded defaults
-- look like), a bare spell id, or a full spell link. Shift-clicking a spell or
-- spellbook entry into the box while it has keyboard focus inserts a link
-- automatically - the easiest way to add one Spy does not already know about,
-- since there is no in-game way to type an exact spell name from memory and be
-- sure it matches.
local function parseSpellListLine(line)
	line = line:gsub("^%s+", ""):gsub("%s+$", "")
	if line == "" or line:sub(1, 2) == "--" then return nil end
	local bracketed = line:match("%[([^%]]+)%]")
	if bracketed then return bracketed end
	local id = tonumber(line)
	if id and GetSpellInfo then
		local ok, name = pcall(GetSpellInfo, id)
		if ok and type(name) == "string" and name ~= "" then return name end
	end
	return line
end

-- name -> true, rebuilt from the profile's text list whenever it changes.
Spy.HealerSpellNames = {}
Spy.HealerSpellCount = 0

function Spy:BuildHealerSpellNames()
	local p = Spy.db and Spy.db.profile
	if not p then return 0 end
	if not p.HealerSpellListSeeded then
		p.HealerSpellListText = defaultHealerListText()
		p.HealerSpellListSeeded = true
	end
	wipe(Spy.HealerSpellNames)
	local n = 0
	for line in (p.HealerSpellListText or ""):gmatch("[^\n]+") do
		local name = parseSpellListLine(line)
		if name and not Spy.HealerSpellNames[name] then
			Spy.HealerSpellNames[name] = true
			n = n + 1
		end
	end
	Spy.HealerSpellCount = n
	return n
end

-- Restores the researched TBC list, discarding any edits.
function Spy:ResetHealerSpellList()
	Spy.db.profile.HealerSpellListText = defaultHealerListText()
	Spy.db.profile.HealerSpellListSeeded = true
	Spy:BuildHealerSpellNames()
end

-- Only these four classes can actually heal another player as a role. Used as a
-- second gate when the class is known - the spell alone already implies it, but
-- a contradiction means we misidentified somebody and should not mark them.
local Spy_HealerCapableClasses = {
	DRUID = true, PALADIN = true, PRIEST = true, SHAMAN = true,
}

-- True when this heal is evidence of a healer rather than incidental healing.
function Spy:IsHealerEvidence(spellName, class)
	if Spy.db.profile.StrictHealerDetection ~= false then
		-- If the whitelist is empty - never built, or the user cleared it on
		-- purpose - fall back to the old exclusion list rather than detecting
		-- nobody at all.
		if (Spy.HealerSpellCount or 0) > 0 then
			if not Spy.HealerSpellNames[spellName] then return false end
			if class and not Spy_HealerCapableClasses[class] then return false end
			return true
		end
	end
	return not Spy_NonHealerHeals[spellName]
end

local Spy_NonHealerHeals = {
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
local Spy_CombatEvents = {
	["SWING_DAMAGE"] = true,
	["RANGE_DAMAGE"] = true,
	["SPELL_DAMAGE"] = true,
	["SPELL_PERIODIC_DAMAGE"] = true,
}

function Spy:CombatLogEvent(info, timestamp, event, hideCaster, srcGUID, srcName, srcFlags, sourceRaidFlags, dstGUID, dstName, dstFlags, destRaidFlags, ...)
timestamp, event, hideCaster, srcGUID, srcName, srcFlags, sourceRaidFlags, dstGUID, dstName, dstFlags, destRaidFlags, arg12, arg13, arg14, arg15, arg16 = CombatLogGetCurrentEventInfo()
	if Spy.EnabledInZone then

		--PetKill code start
		local spellID, spellName, spellSchool, amount, overkill
		local petName = UnitName("pet"); 
		local _, overkill 	
		overkill = 0;		--PetKill code end
	
		-- analyse the source unit
		if bit.band(srcFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE and srcGUID and srcName and not SpyPerCharDB.IgnoreData[srcName] then
			local srcType = strsub(srcGUID, 1,6)
			if srcType == "Player" then
				local _, class, race, raceFile, _, name = GetPlayerInfoByGUID(srcGUID)
				if not Spy.ValidClasses[class] then
					class = nil
				end	
				if not Spy.ValidRaces[raceFile] then
					race = nil
				end
				local learnt = false
				local detected = true
				local playerData = SpyPerCharDB.PlayerData[srcName]
				if not playerData or playerData.isGuess then
					learnt, playerData = Spy:ParseUnitAbility(true, event, srcName, class, race, arg12, arg13)
				end
				if not learnt then
					detected = Spy:UpdatePlayerData(srcName, class, nil, race, nil, nil, true, nil)
				end

				if detected then
					Spy:AddDetected(srcName, timestamp, learnt)
					if event == "SPELL_AURA_APPLIED" and (arg13 == L["Stealth"]) then
						Spy:AlertStealthPlayer(srcName)
					end	
					if event == "SPELL_AURA_APPLIED" and (arg13 == L["Prowl"]) then
						Spy:AlertProwlPlayer(srcName)
					end
				end
			end

			if dstGUID == UnitGUID("player") then
				Spy.LastAttack = srcName
				Spy.LastAttackTime = GetTime()
--				print(Spy.LastAttackTime, " ", Spy.LastAttack)
			end
		end

		-- analyse the destination unit
		if bit.band(dstFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE and dstGUID and dstName and not SpyPerCharDB.IgnoreData[dstName] then
			local dstType = strsub(dstGUID, 1,6)
			if dstType == "Player" then
				local _, class, race, raceFile, _, name = GetPlayerInfoByGUID(dstGUID)
				if not Spy.ValidClasses[class] then
					class = nil
				end	
				if not Spy.ValidRaces[raceFile] then
					race = nil
				end				
				local learnt = false
				local detected = true
				local playerData = SpyPerCharDB.PlayerData[dstName]
				if not playerData or playerData.isGuess then
					learnt, playerData = Spy:ParseUnitAbility(false, event, dstName, class, race, arg12, arg13)
				end
				if not learnt then
					detected = Spy:UpdatePlayerData(dstName, class, nil, race, nil, nil, true, nil)
				end
				if detected then
					Spy:AddDetected(dstName, timestamp, learnt)
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
					local playerData = SpyPerCharDB.PlayerData[srcName]
					if playerData and Spy:IsHealerEvidence(arg13, playerData.class) then
						playerData.healTotal = (playerData.healTotal or 0) + amount
						playerData.healCount = (playerData.healCount or 0) + 1
						playerData.lastHeal = time()
						-- meaningful = a big single heal, or sustained healing
						local big = amount >= (Spy.db.profile.HealerMinHeal or 400)
						local enough = playerData.healCount >= (Spy.db.profile.HealerMinHeals or 2)
						if (big or enough) and not playerData.isHealer then
							playerData.isHealer = true
							if Spy.db.profile.MarkHealers then Spy:RefreshCurrentList() end
							Spy:UpdateActiveCount()
						end
					end
				end
			end
		end

		-- update win stats
		if event == "PARTY_KILL" then
			if srcGUID == UnitGUID("player") and dstName then
				local playerData = SpyPerCharDB.PlayerData[dstName]
				if playerData then
					if not playerData.wins then
						playerData.wins = 0
					end
					playerData.wins = playerData.wins + 1
				end
			end
		end

		-- adds pet kills to the win stats
		if Spy_CombatEvents[event] then
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
				if Spy.PetGUID[srcGUID] then
					local playerData = SpyPerCharDB.PlayerData[dstName]
					if playerData then
						if not playerData.wins then playerData.wins = 0 end
							playerData.wins = playerData.wins + 1
--							PlaySoundFile("Interface\\AddOns\\Spy\\Sounds\\neck-snap.mp3", Spy.db.profile.SoundChannel)
--							DEFAULT_CHAT_FRAME:AddMessage("Your pet/guardian killed " .. dstName);
					end
				end
			end
		end
		if event == "SPELL_SUMMON" and srcName == Spy.CharacterName then
			local petGUID = dstGUID
			Spy.PetGUID[petGUID] = time()
		end
		if event == "ENVIRONMENTAL_DAMAGE" and dstGUID == UnitGUID("player") then
			local environmentalType = arg12
			local amount = arg13
			Spy.LastAttack = nil		
--			print(timestamp, "Ouch ", environmentalType, amount, " hurts!")
		end		
	end
end

function Spy:LeftCombatEvent()
	Spy.LastAttack = nil
	Spy:RefreshCurrentList()
end

function Spy:PlayerDeadEvent()
	if Spy.LastAttack then
		local timeDiff = GetTime() - Spy.LastAttackTime
		if (timeDiff < .5 ) then
--			print("Killed by ", Spy.LastAttack, " ", timeDiff, " seconds ago")
			local playerData = SpyPerCharDB.PlayerData[Spy.LastAttack]
			if playerData then
				if not playerData.loses then
					playerData.loses = 0
				end
				playerData.loses = playerData.loses + 1
			end
		end
	end
end

function Spy:UnitPets(event, unit)
	local petUnit
	if unit == "player" then
		petUnit = "pet"
	end
	if petUnit and UnitExists(petUnit) then
		local guid = UnitGUID(unit)
		local petGUID = UnitGUID(petUnit)
		Spy.PetGUID[petGUID] = time()
		local petCount = 0
		for k, v in pairs(Spy.PetGUID) do
			petCount = petCount + 1
			if petCount > 50 then
				if (time() - 9000) > v then
					Spy.PetGUID[k] = nil
				end	
			end
		end	
	end
end

function Spy:CommReceived(prefix, message, distribution, source)
	if Spy.EnabledInZone and Spy.db.profile.UseData then
		if prefix == Spy.Signature and message and source ~= Spy.CharacterName then
			local version, player, class, level, race, zone, subZone, mapX, mapY, guild, mapID = strsplit("|", message)
			if mapID == nil then
				mapID = ""
			end	
			if player ~= nil and (not Spy.InInstance or zone == GetZoneText()) then
				if not Spy.PlayerCommList[player] then
					local upgrade = Spy:VersionCheck(Spy.Version, version)
					if upgrade and not Spy.UpgradeMessageSent then
						DEFAULT_CHAT_FRAME:AddMessage(L["UpgradeAvailable"])
						Spy.UpgradeMessageSent = true
					end
					if strlen(class) > 0 then
						if not Spy.ValidClasses[class] then
							return
						end
					else
						class = nil
					end
					if strlen(level) > 0 then
						level = tonumber(level)
						if type(level) == "number" then
							if level < 1 or level > Spy.MaximumPlayerLevel or math.floor(level) ~= level then
								return
							end
						else
							return
						end
					else
						level = nil
					end
					if strlen(race) > 0 then
						if not Spy.ValidRaces[race] then
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

					local learnt, playerData = Spy:ParseUnitDetails(player, class, level, race, zone, subZone, mapX, mapY, guild, mapID)
					if playerData and playerData.isEnemy and not SpyPerCharDB.IgnoreData[player] then
						Spy.PlayerCommList[player] = Spy.CurrentMapNote
						Spy:AddDetected(player, time(), learnt, source)
						-- test for nil or 0 mapID
						if Spy.db.profile.DisplayOnMap and mapID > 0 then
							Spy:ShowMapNote(player)
						end
					end
				end
			end
		end
	end
end

function Spy:VersionCheck(version1, version2)
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

function Spy:TrackHumanoids()
	local tooltip = GameTooltipTextLeft1:GetText()
	if tooltip and tooltip ~= Spy.LastTooltip then
		tooltip = Spy:ParseMinimapTooltip(tooltip)
		if Spy.db.profile.MinimapDetails then
			GameTooltipTextLeft1:SetText(tooltip)
			Spy.LastTooltip = tooltip
		end
		GameTooltip:Show()
	end
end

function Spy:FilterNotInParty(frame, event, message)
	if (event == ERR_NOT_IN_GROUP or event == ERR_NOT_IN_RAID) then
		return true
	end
	return false
end

function Spy:ShowMapNote(player)
	local playerData = SpyPerCharDB.PlayerData[player]
	if playerData then
		local currentMapID, TOP_MOST = C_Map.GetBestMapForUnit('player'), true
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
		if continentID ~= nil and mapID ~= nil and type(playerData.mapX) == "number" and type(playerData.mapY) == "number" and (Spy.db.profile.MapDisplayLimit == "None" or (Spy.db.profile.MapDisplayLimit == "SameZone" and mapID == currentMapID) or (Spy.db.profile.MapDisplayLimit == "SameContinent" and continentID == currentContinentID)) then
			local note = Spy.MapNoteList[Spy.CurrentMapNote]
			note.displayed = true
			note.continentID = continentID
			note.mapID = mapID
			note.mapX = mapX
			note.mapY = mapY

			if Spy.db.profile.MapDisplayLimit == "SameZone" then
				HBDP:AddWorldMapIconMap(WorldMapFrame, note.worldIcon, mapID, mapX, mapY, 1)
			elseif Spy.db.profile.MapDisplayLimit == "SameContinent" then
				HBDP:AddWorldMapIconMap(WorldMapFrame, note.worldIcon, mapID, mapX, mapY, 2)
			else
				HBDP:AddWorldMapIconMap(WorldMapFrame, note.worldIcon, mapID, mapX, mapY, 3)
			end	
			HBDP:AddMinimapIconMap(self, note.miniIcon, note.mapID, note.mapX, note.mapY, false, false)

			for i = 1, Spy.MapNoteLimit do
				if i ~= Spy.CurrentMapNote and Spy.MapNoteList[i].displayed then
					if continentID == Spy.MapNoteList[i].continentID and mapID == Spy.MapNoteList[i].mapID and abs(mapX - Spy.MapNoteList[i].mapX) < Spy.MapProximityThreshold and abs(mapY - Spy.MapNoteList[i].mapY) < Spy.MapProximityThreshold then
						Spy.MapNoteList[i].displayed = false
						Spy.MapNoteList[i].worldIcon:Hide()
							HBDP:RemoveMinimapIcon(self, Spy.MapNoteList[i].miniIcon)
						for player in pairs(Spy.PlayerCommList) do
							if Spy.PlayerCommList[player] == i then
								Spy.PlayerCommList[player] = Spy.CurrentMapNote
							end
						end
					end
				end
			end

			Spy.CurrentMapNote = Spy.CurrentMapNote + 1
			if Spy.CurrentMapNote > Spy.MapNoteLimit then
				Spy.CurrentMapNote = 1
			end
		end
	end
end

function Spy:GetPlayerLocation(playerData)
	local location = playerData.zone
	local mapX = playerData.mapX
	local mapY = playerData.mapY
	if location and playerData.subZone and playerData.subZone ~= "" and playerData.subZone ~= location then
		location = playerData.subZone..", "..location
	end
	if mapX and mapX ~= 0 and mapY and mapY ~= 0 then
		location = location.." ("..math.floor(tonumber(mapX) * 100)..","..math.floor(tonumber(mapY) * 100)..")"
	end
	return location
end

function Spy:HideSpyCombatCheck()
	if InCombatLockdown() then
		-- MainWindow did not Hide while in combat, try again in 10 seconds.
		self:ScheduleTimer("HideSpyCombatCheck",10)
		return
	else
		Spy.MainWindow:Hide()
	end
end

function Spy:FormatTime(timestamp)
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

-- recieves pointer to SpyData Spy_db
function Spy:SetDataDb(val)
    Spy_db = val
end