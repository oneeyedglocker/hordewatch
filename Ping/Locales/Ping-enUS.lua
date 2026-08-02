local AceLocale = LibStub:GetLibrary("AceLocale-3.0")
local L = AceLocale:NewLocale("Ping", "enUS", true)
if not L then return end

-- Configuration
L["Ping"] = "Ping"
L["Version"] = "Version"
L["Ping Option"] = "Ping"
L["Profiles"] = "Profiles"
L["Unknown"] = "Unknown"
L["TTabSpyImport"] = "Spy Import"
L["SpyImportDescription"] = "Merge lists from Spy for this character into Ping. Spy's saved data is never changed, and importing again is safe. Keep Spy enabled for one login so Ping can read its saved variables."
L["SpyImportUnavailable"] = "|cffff8000Spy data is not loaded.|r Enable the Spy addon, reload the UI, then return here."
L["SpyImportReady"] = "Spy data found: %d known players and %d Kill On Sight players."
L["SpyImportAll"] = "Import all Spy lists"
L["SpyImportAllDescription"] = "Imports player history, Ignore, and Kill On Sight lists. Existing Ping data is merged, not erased."
L["SpyImportKOS"] = "Import Kill On Sight only"
L["SpyImportKOSDescription"] = "Imports only Spy's Kill On Sight players and their known details."
L["SpyImportComplete"] = "Spy import complete: %d players, %d Kill On Sight, %d ignored."
L["TTabTransfer"] = "Import / Export"
L["TransferDescription"] = "Create a portable Ping code or paste one from another character. Only the selected sections are exported or applied. Imports are validated and merged; they never execute code."
L["TransferLists"] = "KoS and Ignore lists"
L["TransferSpells"] = "Healing and cooldown spells"
L["TransferAppearance"] = "Appearance settings"
L["TransferGenerate"] = "Generate export code"
L["TransferGenerateDescription"] = "Replaces the box below with a code containing the selected sections."
L["TransferApply"] = "Import pasted code"
L["TransferApplyDescription"] = "Validates and applies the selected sections from the pasted code."
L["TransferConfirm"] = "Import the selected Ping data? Existing KoS and Ignore entries are merged; selected spell and appearance settings are replaced."
L["TransferCode"] = "Ping transfer code"
L["TransferCodeDescription"] = "Copy this entire value for export, or replace it with a complete Ping code to import."
L["TransferReady"] = "Ready. Select sections, then generate or paste a code."
L["TransferGenerated"] = "Export created: %d characters."
L["TransferImported"] = "Import complete: %d KoS, %d ignored; spells=%s; appearance=%s."
L["TransferInvalid"] = "|cffff4040Import failed: %s|r"
L["MinimapButtonPage"] = "Minimap Button"
L["MinimapButtonDescription"] = "Configure Ping's minimap launcher. Unlock it to drag it around the minimap."
L["ShowMinimapButton"] = "Show Ping button on the minimap"
L["LockMinimapButton"] = "Lock button position"
L["HideMinimapButtonInCombat"] = "Hide while in combat"
L["MinimapLeftClick"] = "Left click"
L["MinimapRightClick"] = "Right click"
L["MinimapActionToggle"] = "Show / hide Ping window"
L["MinimapActionSettings"] = "Open Ping settings"
L["MinimapActionCycle"] = "Cycle list"
L["MinimapActionEnable"] = "Enable / disable Ping"
L["MinimapButtonCount"] = "Show detected enemy count on hover"
L["MinimapNearbyCount"] = "%d nearby enemies"
L["MinimapLeft"] = "Left"
L["MinimapRight"] = "Right"

-- Information
L["About"] = "About"
L["PingDescription1"] = [[
Ping is a world-PvP awareness addon. It detects hostile-player activity, keeps useful encounter history, and helps you identify priority targets before a fight develops.

|cffffd000 Detection and alerts|cffffffff
• Detects hostile players through combat events, targets, mouseover units and nameplates.
• Distinct nearby, stealth, Kill On Sight, KoS-guild and race alerts with configurable sounds and channels.
• Optional nameplate and world-view distance controls, with the accepted client values reported in settings.
• Humanoid tracking integration can enrich minimap tooltips with known enemy details.
]]

L["PingDescription2"] = [[
|cffffd000 Lists and target selection|cffffffff
• Nearby, Last Hour, Ignore and Kill On Sight lists, with configurable expiry and automatic resizing.
• KoS reasons, KoS-guild detection, class focus, healer-only filtering and kill-priority ordering.
• Confirmed-healer detection based on observed healing of other players. The healing-spell whitelist is editable.
• Editable enemy cooldown watch list. Used defensives and trinkets display a live countdown on the enemy row.
• Healer markers, healer/KoS edge accents, aggregate enemy/healer count, class bars and class-coloured names.

|cffffd000 History, maps and sharing|cffffffff
• Searchable encounter statistics with guild, level, wins, losses, last-seen location and KoS filters.
• Per-character encounter timeline for sightings, hostile attacks, healer evidence, cooldowns, stealth, kills and deaths.
• World-map/minimap notes for shared sightings and optional TomTom waypoints to the last known position.
• Encounter sharing with other Ping users in the party, raid or guild.
• Safe Spy import for all lists or Kill On Sight only; Spy's original data is never changed.
• Native Ping import/export codes for selected lists, spell rules and appearance settings.

]]

L["PingDescription3"] = [[
|cffffd000 Interface and customization|cffffffff
• Moveable, resizable and scalable main window with position, size and screen-clamp locks.
• One-page Look editor with semantic theme colours for the header controls, plus row presets, fonts, SharedMedia bar textures, opacity, background, title and border controls.
• Configurable minimap launcher: show/hide Ping, open settings, cycle lists or enable/disable detection.
• Moveable alert window, target-frame KoS button, chat announcements, slash commands and AceDB profiles.
• Optional diagnostics capture for API compatibility, detection counts, level-guess accuracy and Ping errors.

|cffffd000 Author:|cffffffff Oomkill
|cffffd000 Heritage:|cffffffff Forked from Spy by Slipjack, originally created by Immolation.
]]

-- General Settings
L["GeneralSettings"] = "General Settings"
L["GeneralSettingsDescription"] = [[
Options for when Ping is Enabled or Disabled.
]]
L["EnablePing"] = "Enable Ping"
L["EnablePingDescription"] = "Enables or disables Ping."
L["EnabledInBattlegrounds"] = "Enable Ping in battlegrounds"
L["EnabledInBattlegroundsDescription"] = "Enables or disables Ping when you are in a battleground."
L["EnabledInArenas"] = "Enable Ping in arenas"
L["EnabledInArenasDescription"] = "Enables or disables Ping when you are in an arena."
L["EnabledInWintergrasp"] = "Enable Ping in world combat zones"
L["EnabledInWintergraspDescription"] = "Enables or disables Ping when you are in world combat zones such as Lake Wintergrasp in Northrend."
L["EnabledInSanctuaries"] = "Enable Ping in sanctuaries"
L["EnabledInSanctuariesDescription"] = "Enables or disables Ping when you are in a sanctuary."
L["DisableWhenPVPUnflagged"] = "Disable Ping when not flagged for PvP"
L["DisableWhenPVPUnflaggedDescription"] = "Enables or disables Ping depending on your PVP status."
L["DisabledInZones"] = "Disable Ping while in these locations"
L["DisabledInZonesDescription"]	= "Select locations where Ping will be disabled"
L["Booty Bay"] = "Booty Bay"
L["Everlook"] = "Everlook"						
L["Gadgetzan"] = "Gadgetzan"
L["Ratchet"] = "Ratchet"
L["The Salty Sailor Tavern"] = "The Salty Sailor Tavern"
L["Cenarion Hold"] = "Cenarion Hold"
L["Shattrath City"] = "Shattrath City"
L["Area 52"] = "Area 52"
L["Dalaran"] = "Dalaran"
L["Bogpaddle"] = "Bogpaddle"
L["The Vindicaar"] = "The Vindicaar"
L["Krasus' Landing"] = "Krasus' Landing"
L["The Violet Gate"] = "The Violet Gate"
L["Magni's Encampment"] = "Magni's Encampment"
L["Silithus"] = "Silithus"
L["Chamber of Heart"] = "Chamber of Heart"
L["Hall of Ancient Paths"] = "Hall of Ancient Paths"
L["Sanctum of the Sages"] = "Sanctum of the Sages"
L["Rustbolt"] = "Rustbolt"
L["Oribos"] = "Oribos"
L["Valdrakken"] = "Valdrakken"
L["The Roasted Ram"] = "The Roasted Ram"
L["Dornogal"] = "Dornogal"
L["Stonelight Rest"] = "Stonelight Rest"
L["Delver's Headquarters"] = "Delver's Headquarters"

-- Display
L["DisplayOptions"] = "Display"
L["DisplayOptionsDescription"] = [[
Options for the Ping window and tooltips.
]]
L["ShowOnDetection"] = "Show Ping when enemy players are detected"
L["ShowOnDetectionDescription"] = "Set this to display the Ping window and the Nearby list if Ping is hidden when enemy players are detected."
L["HidePing"] = "Hide Ping when no enemy players are detected"
L["HidePingDescription"] = "Set this to hide Ping when the Nearby list is displayed and it becomes empty. Ping will not be hidden if you clear the list manually."
L["ShowOnlyPvPFlagged"] = "Show only enemy players flagged for PvP"
L["ShowOnlyPvPFlaggedDescription"] = "Set this to show only enemy players that are flagged for PvP in the Nearby list."
L["ShowKoSButton"] = "Show KOS button on the enemy target frame"
L["ShowKoSButtonDescription"] = "Set this to show the KOS button on the enemy player's target frame."
L["Alpha"] = "Transparency"
L["AlphaDescription"] = "Set the transparency of the Ping window."
L["AlphaBG"] = "Transparency in BGs"
L["AlphaBGDescription"] = "Set the transparency of the Ping window in battlegrounds."
L["LockPing"] = "Lock the Ping window"
L["LockPingDescription"] = "Locks the Ping window in place so it doesn't move."
L["ClampToScreen"] = "Clamp to Screen"
L["ClampToScreenDescription"] = "Controls whether the Ping window can be dragged off screen."
L["InvertPing"] = "Invert the Ping window"
L["InvertPingDescription"] = "Flips the Ping window upside down."
L["Reload"] = "Reload UI"
L["ReloadDescription"] = "Required when changing the Ping window."
L["ResizePing"] = "Resize the Ping window automatically"
L["ResizePingDescription"] = "Set this to automatically resize the Ping window as enemy players are added and removed."
L["ResizePingLimit"] = "List Limit"
L["ResizePingLimitDescription"] = "Limit the number of enemy players shown in the Ping window."
L["DisplayTooltipNearPingWindow"] = "Display tooltip near the Ping window"
L["DisplayTooltipNearPingWindowDescription"] = "Set this to display tooltips near the Ping window."
L["SelectTooltipAnchor"] = "Tooltip Anchor Point"
L["SelectTooltipAnchorDescription"] = "Select the anchor point for the tooltip if the option above has been checked"
L["ANCHOR_CURSOR"] = "Cursor"
L["ANCHOR_TOP"] = "Top"
L["ANCHOR_BOTTOM"] = "Bottom"
L["ANCHOR_LEFT"] = "Left"			
L["ANCHOR_RIGHT"] = "Right"
L["TooltipDisplayWinLoss"] = "Display win/loss statistics in tooltip"
L["TooltipDisplayWinLossDescription"] = "Set this to display the win/loss statistics of a player in the player's tooltip."
L["TooltipDisplayKOSReason"] = "Display Kill On Sight reasons in tooltip"
L["TooltipDisplayKOSReasonDescription"] = "Set this to display the Kill On Sight reasons of a player in the player's tooltip."
L["TooltipDisplayLastSeen"] = "Display last seen details in tooltip"
L["TooltipDisplayLastSeenDescription"] = "Set this to display the last known time and location of a player in the player's tooltip."
L["DisplayListData"] = "Select enemy data to display"
L["Name"] = "Name"
L["Class"] = "Class"
L["Rank"] = "Rank"
L["SelectFont"] = "Select a Font"
L["SelectFontDescription"] = "Select a Font for the Ping Window."
L["RowHeight"] = "Select the Row Height"
L["RowHeightDescription"] = "Select the Row Height for the Ping window."
L["Texture"] = "Texture"
L["TextureDescription"] = "Select a texture for the Ping Window"

-- Target Picker
L["TargetPicker"] = "Target Picker"
L["TargetPickerDescription"] = [[
Tune the Nearby list for picking who to attack: highlight likely healers, keep the list tidy, and adjust the window's look and behaviour.
]]
L["THealers"] = "Healers"
L["MarkHealers"] = "Mark healers"
L["MarkHealersDescription"] = "Show a coloured marker on likely-healer rows so they stand out in the list."
L["HealerDetectBy"] = "Detect healers by"
L["HealerDetectByDescription"] = "How a player is judged to be a healer."
L["HealerDetectByClass"] = "Heal-capable class (guess)"
L["HealerDetectByHeal"] = "Confirmed heal only"
L["HealerMinHeal"] = "Confirming heal size"
L["HealerMinHealDescription"] = "One heal at least this large marks a healer immediately, whatever the count."
L["TDebug"] = "Diagnostics"
L["DebugMode"] = "Enable diagnostic logging"
L["DebugModeDescription"] = "Records information that is hard to judge by eye - how far level guesses are off, Ping's own Lua errors, and which game APIs are present so a WoW patch that changes something shows up straight away. Off by default and costs nothing when off. Use Copy diagnostics to send it on."
L["DebugDumpButton"] = "Copy diagnostics"
L["DebugDumpButtonDescription"] = "Open a window with everything recorded so far, ready to copy."
L["DebugStatusButton"] = "Show what has been recorded"
L["DebugStatusButtonDescription"] = "Print a one-line summary in chat: how many errors, level guesses and detections have been recorded so far."
L["DebugResetButton"] = "Clear diagnostics"
L["DebugDumpHint"] = "Click the box, Ctrl+A, Ctrl+C. Also saved to SavedVariables\\PingDebugDB.lua."
L["DebugSlashDescription"] = "Diagnostics: on, off, note <text>, dump, reset, status"
L["DebugOn"] = "diagnostics |cff40ff40on|r - use /ping debug note <text> to flag anything odd, /ping debug dump to copy it out."
L["DebugOff"] = "diagnostics |cffff4040off|r."
L["DebugNoted"] = "noted."
L["DebugWasReset"] = "diagnostics cleared."
L["DebugUsage"] = "usage: /ping debug on | off | note <text> | dump | reset | status"
L["DebugStatus"] = "diagnostics=%s  errors=%d  levels=%d  notes=%d  detections=%d"
L["DebugDropped"] = "|cffff8000%d records were dropped (buffer full) - dump and reset to keep collecting.|r"

L["TomTomWaypoint"] = "Point TomTom here"
L["TomTomOnAltClick"] = "Alt-click a name to set a TomTom waypoint"
L["TomTomOnAltClickDescription"] = "Alt-click any name in the list to drop a TomTom waypoint on the spot where that player was last seen, and target them. Also adds a right-click menu entry. Requires the TomTom addon."
L["TomTomTracking"] = "|cff33ff99Ping|r tracking %s - %s"
L["TomTomNoLocation"] = "|cff33ff99Ping|r has no recorded location for %s yet."
L["TomTomMissing"] = "|cff33ff99Ping|r requires the TomTom addon for waypoints."
L["UseZoneLevelFloor"] = "Use zone minimum level for guesses"
L["UseZoneLevelFloorDescription"] = "Ping guesses an enemy's level from the spells it has seen them cast, which can show impossible levels - a \"16+\" standing in Outland, where the entry level is 58. This raises a guessed level to the minimum for the zone they were seen in. Levels read directly off a player are never changed."
L["TMassFights"] = "Big Fights"
L["MassFightsDescription"] = "\nIn a big fight the list takes hundreds of detections a minute through a few rows. These cut it down to what is worth attacking.\n"
L["HealerOnlyFilter"] = "Show only healers"
L["HealerOnlyFilterDescription"] = "Hide everyone except confirmed healers (Kill-on-Sight players are always shown). Turns the Nearby list into a kill list when you're in a crowd. The window title shows when this is on."
L["HealersOnlyTag"] = "healers"
L["KillPriorityOrder"] = "Sort by kill priority"
L["KillPriorityOrderDescription"] = "Order the list by how worthwhile each target is - Kill-on-Sight first, then confirmed healers, then anyone actively fighting - instead of by who was seen most recently. In a big fight everyone is recent, so recency tells you nothing."
L["ShowAggregateHeader"] = "Show healer count in header"
L["ShowAggregateHeaderDescription"] = "Show how many nearby enemies are healers next to the enemy count, e.g. 12 3H. Useful when names scroll past too fast to read."
L["TCooldowns"] = "Enemy Cooldowns"
L["TrackCooldowns"] = "Track enemy defensive cooldowns"
L["TrackCooldownsDescription"] = "Show a countdown beside an enemy after they burn a PvP trinket, bubble, Ice Block or similar - so you know when they're out of outs."
L["AnnounceCooldowns"] = "Announce cooldowns in chat"
L["AnnounceCooldownsDescription"] = "Also print a chat line when an enemy uses one of these cooldowns."
L["CooldownColor"] = "Cooldown timer colour"
L["CooldownUsed"] = "%s used %s"
L["KOSGuildAlertCooldown"] = "Kill-on-Sight guild alert cooldown (seconds)"
L["KOSGuildAlertCooldownDescription"] = "Minimum time between alerts for the same Kill-on-Sight guild, so running into several of their members doesn't fire a stack of warnings. Set to 0 to alert every time."
L["HealerMarkerStyle"] = "Marker style"
L["HealerMarkerStyleDescription"] = "The glyph used to mark a healer row."
L["HealerMarkerCross"] = "Cross"
L["HealerMarkerAsterisk"] = "Asterisk"
L["HealerMarkerDot"] = "Dot"
L["HealerMarkerSide"] = "Marker side"
L["HealerMarkerSideDescription"] = "Which side of the row the healer marker sits on."
L["HealerMarkerRight"] = "Right"
L["HealerMarkerLeft"] = "Left"
L["HealerMarkerColor"] = "Marker colour"
L["SortHealersToTop"] = "Sort healers to the top"
L["SortHealersToTopDescription"] = "Float likely healers above other players within the Nearby list."
L["HealerGreenEdge"] = "Healer edge accent"
L["HealerGreenEdgeDescription"] = "Show a coloured stripe on the left edge of healer rows."
L["HealerEdgeColor"] = "Healer edge colour"
L["DimNonHealers"] = "Dim non-healers"
L["DimNonHealersDescription"] = "Lower the opacity of non-healer (and non-KoS) rows to make healers pop."
L["TLook"] = "List Look"
L["LookPreset"] = "Look preset"
L["LookPresetDescription"] = "A quick style for the rows. Adjusts row height, name colouring and bar fill under the hood."
L["LookClassBars"] = "Class bars"
L["LookFlat"] = "Flat"
L["LookCompact"] = "Compact"
L["ClassColoredNames"] = "Class-coloured names"
L["ClassColoredNamesDescription"] = "Colour each player's name by their class instead of using the bar text colour."
L["BarOpacity"] = "Bar fill opacity"
L["BarOpacityDescription"] = "How solid the class-coloured bar fill looks. Set to 0 for a flat, text-only list."
L["TWindow"] = "Window"
L["LockPosition"] = "Lock position"
L["LockPositionDescription"] = "Keep the window where it is and stop it being dragged around."
L["LockSize"] = "Lock size"
L["LockSizeDescription"] = "Hide the resize grips so the window can't be resized."
L["ShowBackground"] = "Show background"
L["ShowBackgroundDescription"] = "Show the window's background fill behind the rows."
L["BackgroundOpacity"] = "Background opacity"
L["BackgroundOpacityDescription"] = "How solid the window background looks."
L["TitleBarStyle"] = "Title bar style"
L["TitleBarStyleDescription"] = "How the window's title bar looks. Classic is Ping's original subtle bar; Solid is an opaque coloured strip."
L["TitleBarClassic"] = "Classic (subtle)"
L["TitleBarSolid"] = "Solid strip"
L["TitleBarColor"] = "Title bar colour"
L["TitleBarColorDescription"] = "Colour of the solid title strip."
L["TitleBarOpacity"] = "Title bar opacity"
L["TitleBarOpacityDescription"] = "Transparency of the solid title strip. Lower is see-through."
L["ShowBorder"] = "Show border"
L["ShowBorderDescription"] = "Draw a border around the window."
L["WindowBorderColor"] = "Border colour"
L["WindowScale"] = "Window scale"
L["WindowScaleDescription"] = "Scale the whole Ping window up or down."
L["KoSEdgeColor"] = "Kill-on-Sight edge colour"
L["KoSEdgeColorDescription"] = "Colour of the left-edge accent on Kill-on-Sight rows."

-- Alerts
L["AlertOptions"] = "Alerts"
L["AlertOptionsDescription"] = [[
Options for alerts, announcements and warnings when enemy players are detected.
]]
L["SoundChannel"] = "Select Sound Channel"
L["Master"] = "Master"
L["SFX"] = "Sound Effects"
L["Music"] = "Music"
L["Ambience"] = "Ambience"
L["Announce"] = "Send announcements to:"
L["None"] = "None"
L["NoneDescription"] = "Do not announce when enemy players are detected."
L["Self"] = "Self"
L["SelfDescription"] = "Announce to yourself when enemy players are detected."
L["Party"] = "Party"
L["PartyDescription"] = "Announce to your party when enemy players are detected."
L["Guild"] = "Guild"
L["GuildDescription"] = "Announce to your guild when enemy players are detected."
L["Raid"] = "Raid"
L["RaidDescription"] = "Announce to your raid when enemy players are detected."
L["LocalDefense"] = "Local Defense"
L["LocalDefenseDescription"] = "Announce to the Local Defense channel when enemy players are detected."
L["OnlyAnnounceKoS"] = "Only announce enemy players that are Kill On Sight"
L["OnlyAnnounceKoSDescription"] = "Set this to only announce enemy players that are on your Kill On Sight list."
L["WarnOnStealth"] = "Warn upon stealth detection"
L["WarnOnStealthDescription"] = "Set this to display a warning and sound an alert when an enemy player gains stealth."
L["WarnOnKOS"] = "Warn upon Kill On Sight detection"
L["WarnOnKOSDescription"] = "Set this to display a warning and sound an alert when an enemy player on your Kill On Sight list is detected."
L["WarnOnKOSGuild"] = "Warn upon Kill On Sight guild detection"
L["WarnOnKOSGuildDescription"] = "Set this to display a warning and sound an alert when an enemy player in the same guild as someone on your Kill On Sight list is detected."
L["WarnOnRace"] = "Warn upon Race detection"
L["WarnOnRaceDescription"] = "Set this to sound an alert when the selected Race is detected."
L["SelectWarnRace"] = "Select Race for detection"
L["SelectWarnRaceDescription"] = "Select a Race for audio alert."
L["WarnRaceNote"] = "Note: You must target an enemy at least once so their Race can be added to the database. Upon the next detection an alert will sound. This does not work the same as detecting nearby enemies in combat."
L["DisplayWarningsInErrorsFrame"] = "Display warnings in the errors frame"
L["DisplayWarningsInErrorsFrameDescription"] = "Set this to use the errors frame to display warnings instead of using the graphical popup frames."
L["DisplayWarnings"] = "Select warnings message location"
L["Default"] = "Default"
L["ErrorFrame"] = "Error Frame"
L["Moveable"] = "Moveable"
L["EnableSound"] = "Enable audio alerts"
L["EnableSoundDescription"] = "Set this to enable audio alerts when enemy players are detected. Different alerts sound if an enemy player gains stealth or if an enemy player is on your Kill On Sight list."
L["OnlySoundKoS"] = "Only sound audio alerts for Kill On Sight detection"
L["OnlySoundKoSDescription"] = "Set this to only play audio alerts when enemy players on the Kill on Sight list are detected."
L["StopAlertsOnTaxi"] = "Turn off alerts while on a flight path"
L["StopAlertsOnTaxiDescription"] = "Stop all new alerts and warnings while on a flight path."

-- Nearby List
L["ListOptions"] = "Nearby List"
L["ListOptionsDescription"] = [[
Options on how enemy players are added and removed.
]]
L["RemoveUndetected"] = "Remove enemy players from the Nearby list after:"
L["1Min"] = "1 minute"
L["1MinDescription"] = "Remove an enemy player who has been undetected for over 1 minute."
L["2Min"] = "2 minutes"
L["2MinDescription"] = "Remove an enemy player who has been undetected for over 2 minutes."
L["5Min"] = "5 minutes"
L["5MinDescription"] = "Remove an enemy player who has been undetected for over 5 minutes."
L["10Min"] = "10 minutes"
L["10MinDescription"] = "Remove an enemy player who has been undetected for over 10 minutes."
L["15Min"] = "15 minutes"
L["15MinDescription"] = "Remove an enemy player who has been undetected for over 15 minutes."
L["Never"] = "Never remove"
L["NeverDescription"] = "Never remove enemy players. The Nearby list can still be cleared manually."
L["ShowNearbyList"] = "Switch to the Nearby list upon enemy player detection"
L["ShowNearbyListDescription"] = "Set this to display the Nearby list if it is not already visible when enemy players are detected."
L["PrioritiseKoS"] = "Prioritise Kill On Sight enemy players in the Nearby list"
L["PrioritiseKoSDescription"] = "Set this to always show Kill On Sight enemy players first in the Nearby list."

-- Map
L["MapOptions"] = "Map"
L["MapOptionsDescription"] = [[
Options for world map and minimap including icons and tooltips.
]]
L["MinimapDetection"] = "Enable minimap detection"
L["MinimapDetectionDescription"] = "Rolling the cursor over known enemy players detected on the minimap will add them to the Nearby list."
L["MinimapNote"] = "          Note: Only works for players that can Track Humanoids."
L["MinimapDetails"] = "Display level/class details in tooltips"
L["MinimapDetailsDescription"] = "Set this to update the map tooltips so that level/class details are displayed alongside enemy names."
L["DisplayOnMap"] = "Display icons on the map"
L["DisplayOnMapDescription"] = "Display map icons for the location of other Ping users in your party, raid and guild when they detect enemies."
L["SwitchToZone"] = "Switch to current zone map on enemy detection"
L["SwitchToZoneDescription"] = "Change the map to the players current zone map when enemies are detected."
L["MapDisplayLimit"] = "Limit displayed map icons to:"
L["LimitNone"] = "Everywhere"
L["LimitNoneDescription"] = "Displays all detected enemies on the map regardless of your current location."
L["LimitSameZone"] = "Same zone"
L["LimitSameZoneDescription"] = "Only displays detected enemies on the map if you are in the same zone."
L["LimitSameContinent"] = "Same continent"
L["LimitSameContinentDescription"] = "Only displays detected enemies on the map if you are on the same continent."

-- Data Management
L["DataOptions"] = "Data Management"
L["DataOptionsDescription"] = [[

Options on how Ping maintains and gathers data.
]]
L["PurgeData"] = "Purge undetected enemy player data after:"
L["OneDay"] = "1 day"
L["OneDayDescription"] = "Purge data for enemy players that have been undetected for 1 day."
L["FiveDays"] = "5 days"
L["FiveDaysDescription"] = "Purge data for enemy players that have been undetected for 5 days."
L["TenDays"] = "10 days"
L["TenDaysDescription"] = "Purge data for enemy players that have been undetected for 10 days."
L["ThirtyDays"] = "30 days"
L["ThirtyDaysDescription"] = "Purge data for enemy players that have been undetected for 30 days."
L["SixtyDays"] = "60 days"
L["SixtyDaysDescription"] = "Purge data for enemy players that have been undetected for 60 days."
L["NinetyDays"] = "90 days"
L["NinetyDaysDescription"] = "Purge data for enemy players that have been undetected for 90 days."
L["PurgeKoS"] = "Purge Kill on Sight players based on undetected time."
L["PurgeKoSDescription"] = "Set this to purge Kill on Sight players that have been undetected based on the time settings for undetected players."
L["PurgeWinLossData"] = "Purge win/loss data based on undetected time."
L["PurgeWinLossDataDescription"] = "Set this to purge win/loss data of your enemy encounters based on the time settings for undetected players."
L["ShareData"] = "Share data with other Ping addon users"
L["ShareDataDescription"] = "Set this to share the details of your enemy player encounters with other Ping users in your party, raid and guild."
L["UseData"] = "Use data from other Ping addon users"
L["UseDataDescription"] = "Set this to use the data collected by other Ping users in your party, raid and guild."
L["ShareKOSBetweenCharacters"] = "Share Kill On Sight players between your characters"
L["ShareKOSBetweenCharactersDescription"] = "Set this to share the players you mark as Kill On Sight between other characters that you play on the same server and faction."

-- Commands
L["SlashCommand"] = "Slash Command"
L["PingSlashDescription"] = "These buttons execute the same functions as the ones in the slash command /ping"
L["Enable"] = "Enable"
L["EnableDescription"] = "Enables Ping and shows the main window."
L["Show"] = "Show"
L["ShowDescription"] = "Shows the main window."
L["Hide"] = "Hide"
L["HideDescription"] = "Hides the main window."
L["Reset"] = "Reset"
L["ResetDescription"] = "Resets the position and appearance of the main window."
L["ClearSlash"] = "Clear"
L["ClearSlashDescription"] = "Clears the list of players that have been detected."
L["Config"] = "Config"
L["ConfigDescription"] = "Open the Interface Addons configuration window for Ping."
L["KOS"] = "KOS"
L["KOSDescription"] = "Add/remove a player to/from the Kill On Sight list."
L["InvalidInput"] = "Invalid Input"
L["Ignore"] = "Ignore"
L["IgnoreDescription"] = "Add/remove a player to/from the Ignore list."
L["Test"] = "Test"
L["TestDescription"] = "Shows a warning so it can be repositioned."
L["Sanctuary"] = "Sanctuary"
L["SanctuaryDescription"] = "Show/Hide Ping in a Sanctuary area."

-- Lists
L["Nearby"] = "Nearby"
L["LastHour"] = "Last Hour"
L["Ignore"] = "Ignore"
L["KillOnSight"] = "Kill On Sight"

--Stats
L["Won"] = "Won"
L["Lost"] = "Lost"
L["Time"] = "Time"	
L["List"] = "List"
L["Filter"] = "Filter"
L["Show Only"] = "Show Only"
L["Realm"] = "Realm"
L["KOS"] = "KOS"
L["Won/Lost"] = "Won/Lost"
L["Reason"] = "Reason"	 
L["HonorKills"] = "Honor Kills"
L["PvPDeaths"] = "PvP Deaths"

-- Output Messages
L["VersionCheck"] = "|cffc41e3aWarning! The wrong version of Ping is installed. Uninstall this version and install the one that matches your current game version."
L["PingEnabled"] = "|cff9933ffPing addon enabled."
L["PingDisabled"] = "|cff9933ffPing addon disabled. Type |cffffffff/ping show|cff9933ff to enable."
L["UpgradeAvailable"] = "|cff9933ffA new version of Ping is available. It can be downloaded from:\n|cffffffffhttps://www.curseforge.com/wow/addons/spy-tbc"
L["AlertStealthTitle"] = "Stealth player detected!"
L["AlertKOSTitle"] = "Kill On Sight player detected!"
L["AlertKOSGuildTitle"] = "Kill On Sight player guild detected!"
L["AlertTitle_kosaway"] = "Kill On Sight player located by "
L["AlertTitle_kosguildaway"] = "Kill On Sight player guild located by "
L["StealthWarning"] = "|cff9933ffStealth player detected: |cffffffff"
L["KOSWarning"] = "|cffff0000Kill On Sight player detected: |cffffffff"
L["KOSGuildWarning"] = "|cffff0000Kill On Sight player guild detected: |cffffffff"
L["PingSignatureColored"] = "|cff9933ff[Ping] "
L["PlayerDetectedColored"] = "Player detected: |cffffffff"
L["PlayersDetectedColored"] = "Players detected: |cffffffff"
L["KillOnSightDetectedColored"] = "Kill On Sight player detected: |cffffffff"
L["PlayerAddedToIgnoreColored"] = "Added player to Ignore list: |cffffffff"
L["PlayerRemovedFromIgnoreColored"] = "Removed player from Ignore list: |cffffffff"
L["PlayerAddedToKOSColored"] = "Added player to Kill On Sight list: |cffffffff"
L["PlayerRemovedFromKOSColored"] = "Removed player from Kill On Sight list: |cffffffff"
L["PlayerDetected"] = "[Ping] Player detected: "
L["KillOnSightDetected"] = "[Ping] Kill On Sight player detected: "
L["Level"] = "Level"
L["LastSeen"] = "Last seen"
L["LessThanOneMinuteAgo"] = "less than a minute ago"
L["MinutesAgo"] = "minutes ago"
L["HoursAgo"] = "hours ago"
L["DaysAgo"] = "days ago"
L["Close"] = "Close"
L["CloseDescription"] = "|cffffffffHides the Ping window. By default will show again when the next enemy player is detected."
L["Left/Right"] = "Left/Right"
L["Left/RightDescription"] = "|cffffffffNavigates between the Nearby, Last Hour, Ignore and Kill On Sight lists."
L["Clear"] = "Clear"
L["ClearDescription"] = "|cffffffffClears the list of players that have been detected. CTRL-Click will turn Ping On/Off. Shift-Click will turn all sound On/Off."
L["SoundEnabled"] = "Audio alerts enabled"
L["SoundDisabled"] = "Audio alerts disabled"
L["NearbyCount"] = "Nearby Count"
L["NearbyCountDescription"] = "|cffffffffNumber of nearby players."
L["Statistics"] = "Statistics"
L["StatsDescription"] = "|cffffffffShows a list of enemy players encountered, win/loss records and where they were last seen."
L["AddToIgnoreList"] = "Add to Ignore list"
L["AddToKOSList"] = "Add to Kill On Sight list"
L["RemoveFromIgnoreList"] = "Remove from Ignore list"
L["RemoveFromKOSList"] = "Remove from Kill On Sight list"
L["RemoveFromStatsList"] = "Remove from Statistics List"
L["AnnounceDropDownMenu"] = "Announce"
L["KOSReasonDropDownMenu"] = "Set Kill On Sight reason"
L["PartyDropDownMenu"] = "Party"
L["RaidDropDownMenu"] = "Raid"
L["GuildDropDownMenu"] = "Guild"
L["LocalDefenseDropDownMenu"] = "Local Defense"
L["Player"] = " (Player)"
L["KOSReason"] = "Kill On Sight"
L["KOSReasonIndent"] = "    "
L["KOSReasonOther"] = "Enter your own reason..."
L["EnterKOSReason"] = "Enter the Kill On Sight reason for %s"
L["KOSReasonClear"] = "Clear Reason"
L["StatsWins"] = "|cff40ff00Wins: "
L["StatsSeparator"] = "  "
L["StatsLoses"] = "|cff0070ddLosses: "
L["Located"] = "located:"
L["DistanceUnit"] = "yards"
L["LocalDefenseChannelName"] = "LocalDefense"

Ping_KOSReasonListLength = 6
Ping_KOSReasonList = {
	[1] = {
		["title"] = "Started combat";
		["content"] = {
			"Attacked me for no reason",
			"Attacked me at a quest giver", 
			"Attacked me while I was fighting NPCs",
			"Attacked me while I was near an instance",
			"Attacked me while I was AFK",
			"Attacked me while I was mounted/flying",
			"Attacked me while I had low health/mana",
		};
	},
	[2] = {
		["title"] = "Style of combat";
		["content"] = {
			"Ambushed me",
			"Always attacks me on sight",
			"Killed me with a higher level character",
			"Killed me with a group of enemies",
			"Doesn't attack without backup",
			"Always calls for help",
			"Uses too much crowd control",
		};
	},
	[3] = {
		["title"] = "Camping";
		["content"] = {
			"Camped me",
			"Camped an alt",
			"Camped lowbies",
			"Camped from stealth",
			"Camped guild members",
			"Camped game NPCs/objectives",
			"Camped a city/site",
		};
	},
	[4] = {
		["title"] = "Questing";
		["content"] = {
			"Attacked me while I was questing",
			"Attacked me after I helped with a quest",
			"Interfered with a quest objective",
			"Started a quest I wanted to do",
			"Killed my faction's NPCs",
			"Killed a quest NPC",
		};
	},
	[5] = {
		["title"] = "Stole resources";
		["content"] = {
			"Gathered herbs I wanted",
			"Gathered minerals I wanted",
			"Gathered resources I wanted",
			"Killed me and stole my target/rare NPC",
			"Skinned my kills",
			"Salvaged my kills",
			"Fished in my pool",
		};
	},
	[6] = {
		["title"] = "Other";
		["content"] = {
			"Flagged for PvP",
			"Pushed me off a cliff",
			"Uses engineering tricks",
			"Always manages to escape",
			"Uses items and skills to escape",
			"Exploits game mechanics",
			"Enter your own reason...",
		};
	},
}

-- Class descriptions
L["UNKNOWN"] = "Unknown"
L["DRUID"] = "Druid"
L["HUNTER"] = "Hunter"
L["MAGE"] = "Mage"
L["PALADIN"] = "Paladin"
L["PRIEST"] = "Priest"
L["ROGUE"] = "Rogue"
L["SHAMAN"] = "Shaman"
L["WARLOCK"] = "Warlock"
L["WARRIOR"] = "Warrior"
L["DEATHKNIGHT"] = "Death Knight"
L["MONK"] = "Monk"
L["DEMONHUNTER"] = "Demon Hunter"
L["EVOKER"] = "Evoker"

-- Race descriptions
L["Human"] = "Human"
L["Orc"] = "Orc"
L["Dwarf"] = "Dwarf"
L["Tauren"] = "Tauren"
L["Troll"] = "Troll"
L["Night Elf"] = "Night Elf"
L["Undead"] = "Undead"
L["Gnome"] = "Gnome"
L["Blood Elf"] = "Blood Elf"
L["Draenei"] = "Draenei"
L["Goblin"] = "Goblin"
L["Worgen"] = "Worgen"
L["Pandaren"] = "Pandaren"
L["Highmountain Tauren"] = "Highmountain Tauren"
L["Lightforged Draenei"] = "Lightforged Draenei"
L["Nightborne"] = "Nightborne"
L["Void Elf"] = "Void Elf"
L["Dark Iron Dwarf"] = "Dark Iron Dwarf"
L["Mag'har Orc"] = "Mag'har Orc"
L["Kul Tiran"] = "Kul Tiran"
L["Zandalari Troll"] = "Zandalari Troll"
L["Mechagnome"] = "Mechagnome"
L["Vulpera"] = "Vulpera"
L["Dracthyr"] = "Dracthyr"
L["Earthen"] = "Earthen"

-- Stealth abilities
L["Stealth"] = "Stealth"
L["Prowl"] = "Prowl"

-- Minimap color codes
L["MinimapGuildText"] = "|cffffffff"
L["MinimapClassTextUNKNOWN"] = "|cff191919"
L["MinimapClassTextDRUID"] = "|cffff7c0a"
L["MinimapClassTextHUNTER"] = "|cffaad372"
L["MinimapClassTextMAGE"] = "|cff68ccef"
L["MinimapClassTextPALADIN"] = "|cfff48cba"
L["MinimapClassTextPRIEST"] = "|cffffffff"
L["MinimapClassTextROGUE"] = "|cfffff468"
L["MinimapClassTextSHAMAN"] = "|cff2359ff"
L["MinimapClassTextWARLOCK"] = "|cff9382c9"
L["MinimapClassTextWARRIOR"] = "|cffc69b6d"
L["MinimapClassTextDEATHKNIGHT"] = "|cffc41e3a"
L["MinimapClassTextMONK"] = "|cff00ff96"
L["MinimapClassTextDEMONHUNTER"] = "|cffa330c9"
L["MinimapClassTextEVOKER"] = "|cff33937f"

Ping_IgnoreList = {
	["Mailbox"]=true, ["Shred Master Mk1"]=true, ["Scrap-O-Matic 1000"]=true,
	["Boat to Stormwind City"]=true, ["Boat to Boralus Harbor, Tiragarde Sound"]=true,
	["Treasure Chest"]=true, ["Small Treasure Chest"]=true,	
	["Akunda's Bite"]=true, ["Anchor Weed"]=true, ["Riverbud"]=true,    
	["Sea Stalk"]=true, ["Siren's Pollen"]=true, ["Star Moss"]=true,   
	["Winter's Kiss"]=true, ["War Headquarters (PvP)"]=true,
	["Alliance Assassin"]=true, ["Horde Assassin"]=true,	
	["Mystic Birdhat"]=true, ["Cousin Slowhands"]=true,	
	["Azerite for the Alliance"]=true, ["Azerite for the Horde"]=true,
};
------------------------------------------------------------------------------
-- Options panel pages and tabs.
--
-- Seven rows in the sidebar, and the second level runs across the top of each
-- page as tabs. Tab labels are drawn at a fixed width and clip rather than
-- wrap, so these are deliberately short and no page carries more than three.
------------------------------------------------------------------------------
L["TPagePing"] = "Ping"
L["TTabZones"] = "Where it runs"
L["TTabList"] = "The list"

L["TPageTargeting"] = "Targeting"
L["TTabHealers"] = "Healers"
L["TTabBigFights"] = "WPvP & Raids"
L["TTabCooldowns"] = "Cooldowns"

L["TPageFinding"] = "Radar"
L["TTabMap"] = "Map"

L["TPageLook"] = "Look"
L["TTabRows"] = "Rows & text"
L["TTabWindow"] = "Window"

L["TPageAlerts"] = "Alerts"
L["TTabSound"] = "Sound"
L["TTabWarnings"] = "Warnings"

L["TPageData"] = "Data"
L["TTabStorage"] = "Storage"
L["TTabSharing"] = "Sharing"
L["TTabDiagnostics"] = "Diagnostics"
L["TTabHistory"] = "History"

L["HistoryDescription"] = "A per-character, newest-first timeline of enemy sightings, attacks, healer evidence, cooldown use, stealth, kills and deaths. Ping keeps the latest 250 entries."
L["HistoryCount"] = "%d encounters saved."
L["HistoryClear"] = "Clear history"
L["HistoryClearDescription"] = "Permanently clears this character's encounter timeline. Player records and win/loss totals are not changed."
L["HistoryClearConfirm"] = "Clear this character's encounter history?"
L["HistoryLog"] = "Encounter timeline"
L["HistoryLogDescription"] = "This field is read-only. Select and copy its text if you want to save or share the timeline."
L["HistoryEmpty"] = "No encounters recorded yet."
L["HistoryEncounter"] = "Encounter"
L["HistoryDetected"] = "Detected"
L["HistoryReturned"] = "Returned"
L["HistoryAttacked"] = "Attacked you"
L["HistoryCooldown"] = "Used cooldown"
L["HistoryHealer"] = "Confirmed healer"
L["HistoryStealth"] = "Entered stealth"
L["HistoryKilled"] = "You killed"
L["HistoryKilledBy"] = "Killed you"
L["HistoryReportedBy"] = "reported by %s"

------------------------------------------------------------------------------
-- Sight distance
------------------------------------------------------------------------------
L["TTabDistance"] = "Distance"
L["DistanceIntro"] = "How far away the game will tell you an enemy exists. Ping never lowers a value another addon set higher."
L["MaxNameplateShowEnemies"] = "Turn enemy nameplates on"
L["MaxNameplateShowEnemiesDescription"] = "Nameplates that are switched off have no distance worth setting, so this turns enemy plates on as part of the same intent. Untick if you deliberately play without them."
L["DistanceStatus"] = "|cffffd000In use now:|r nameplates %s yards, view distance %s."
L["DistanceApplyNow"] = "Apply now"
L["DistanceApplyNowDescription"] = "Write the values again immediately, and report what the client actually accepted."
L["DistanceNameplateSet"] = "nameplate distance set to %s yards."
L["DistanceViewSet"] = "view distance set to %s."
L["DistanceNothingToDo"] = "both distance options are switched off - nothing to apply."
L["StrictHealerDetection"] = "Only count real healing spells"
L["StrictHealerDetectionDescription"] = "Only spells on the list below count. Off, anything that heals another player counts."
L["HealerMinHeals"] = "Healing spells needed"
L["HealerMinHealsDescription"] = "How many healing spells Ping must see before marking someone."
L["NameplateDistanceMode"] = "Nameplate distance"
L["NameplateDistanceModeDescription"] = "How Ping handles nameplateMaxDistance - how far away enemy nameplates will draw. Re-applied on login and on zone change, because other addons write this too and the last write wins."
L["NameplateDistanceValue"] = "Nameplate distance (yards)"
L["NameplateDistanceValueDescription"] = "The exact value to use. Anything above what your client accepts is clamped by the game, and the line below reports what it actually took."
L["DistanceViewHeader"] = "View distance"
L["ViewDistanceMode"] = "View distance"
L["ViewDistanceModeDescription"] = "How Ping handles farclip - how far the world itself is drawn. Higher costs frame rate on a weak machine, which is the whole trade."
L["ViewDistanceValue"] = "View distance"
L["ViewDistanceValueDescription"] = "The exact value to use. Lower this if maximum view distance costs you too much frame rate but you still want it above the default."
L["DistanceModeMax"] = "Maximum (never lower it)"
L["DistanceModeCustom"] = "Set my own value"
L["DistanceModeOff"] = "Leave it alone"
L["DistanceCeilings"] = "Highest your client accepts: nameplates %s yards, view distance %s."

------------------------------------------------------------------------------
-- Healer spell list - editable
------------------------------------------------------------------------------
L["HealerSpellListHeader"] = "Healing spells"
L["HealerSpellListIntro"] = "Only these spells mark a healer. Delete a line to stop counting it; add a name, spell id, or shift-clicked spell link to start."
L["HealerSpellList"] = "Whitelisted healing spells"
L["HealerSpellListDescription"] = "One spell per line in Spell Name (ID) format. IDs, names, and shift-clicked spell links are also accepted."
L["HealerSpellListStatus"] = "%d spells recognised right now."
L["HealerSpellListReset"] = "Reset to the researched TBC list"
L["HealerSpellListResetDescription"] = "Discards every edit and restores the 24 spells Ping shipped with."

------------------------------------------------------------------------------
-- Spell list rows - shared by the healer and cooldown lists
------------------------------------------------------------------------------
L["SpellListAdd"] = "Add"
L["SpellListEmpty"] = "Nothing in this list."
L["SpellListUnknown"] = "This client does not know this spell id."

------------------------------------------------------------------------------
-- Cooldown watch list - editable
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Look themes
------------------------------------------------------------------------------
L["LookThemeHeader"] = "Theme"
L["LookTheme"] = "Colour theme"
L["LookThemeDescription"] = "Applies a coordinated palette. Themes marked as new artwork also replace the window textures and control icons. Choosing any legacy theme restores the original Ping artwork."
L["ChromeColors"] = "Header controls"
L["IconColor"] = "Utility icons"
L["NavigationColor"] = "Navigation arrows"
L["CountColor"] = "Enemy count"
L["CloseColor"] = "Close button"
L["CooldownListHeader"] = "Cooldowns watched"
L["CooldownListIntro"] = "Only these spells are tracked. Delete a line to stop watching it; add a spell id or a shift-clicked spell link to start."
L["CooldownList"] = "Watched spells"
L["CooldownListDescription"] = "One spell per line in Spell Name (ID) = seconds format. The duration is optional; IDs and shift-clicked spell links are also accepted."
L["CooldownListStatus"] = "%d spells watched."
L["CooldownListStatusWithWarning"] = "%d spells watched. |cffff8000%d lines have no spell id|r and are being ignored."
L["CooldownListReset"] = "Reset to the ten defaults"
L["CooldownListResetDescription"] = "Discards every edit and restores the spells Ping ships with."

------------------------------------------------------------------------------
-- Class focus
------------------------------------------------------------------------------
L["FocusClassHeader"] = "Focus classes"
L["FocusClassIntro"] = "Float chosen classes to the top of the list, or show only those classes. Works alongside the healer controls above - healers still outrank focused classes when both are on."
L["FocusClassMode"] = "Class focus"
L["FocusClassModeDescription"] = "Off, sort chosen classes to the top, or hide everything except them."
L["FocusClassOff"] = "Off"
L["FocusClassSort"] = "Sort them to the top"
L["FocusClassOnly"] = "Show only these classes"
L["FocusClasses"] = "Classes to focus"
L["FocusClassesDescription"] = "Kill-on-Sight players are always shown regardless of this."
