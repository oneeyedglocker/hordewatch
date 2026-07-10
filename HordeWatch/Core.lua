local ADDON_NAME = "HordeWatch"

HordeWatch = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceEvent-3.0", "AceTimer-3.0", "AceComm-3.0", "AceConsole-3.0", "AceSerializer-3.0")
local HW = HordeWatch

HW.Version = "0.1.0"
HW.Signature = "HWatch1"

-- account-wide settings/profile (AceDB) -- NOT sighting data, just config
local Defaults = {
	profile = {
		Enabled = true,
		ShareToGuild = true,
		ShowWindow = true,
		minimap = { hide = false },

		EnabledInSanctuaries = false,
		EnabledInBattlegrounds = true,
		EnabledInArenas = false,
		EnabledInWintergrasp = true,
		DisableWhenPVPUnflagged = false,

		FilteredZones = {},

		-- data retention for the append-only sighting log
		RetentionDays = 14,
		MaxRecords = 20000,

		-- comm mesh
		CommRateLimitSeconds = 2,	-- min seconds between broadcasts for the same player

		-- collapse near-duplicate sightings of the same player (same
		-- reporter re-detected via multiple methods, or several guildmates
		-- corroborating one encounter) into a single row instead of one
		-- row per detection
		CollapseWindowSeconds = 8,
	},
}

function HW:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("HordeWatchDB", Defaults, true)

	if type(HordeWatchCharDB) ~= "table" then
		HordeWatchCharDB = {}
	end
	if type(HordeWatchCharDB.Sightings) ~= "table" then HordeWatchCharDB.Sightings = {} end
	if type(HordeWatchCharDB.CurrentState) ~= "table" then HordeWatchCharDB.CurrentState = {} end
	if type(HordeWatchCharDB.NextId) ~= "number" then HordeWatchCharDB.NextId = 1 end
	self.charDB = HordeWatchCharDB

	self.RealmName = GetRealmName()
	self.CharacterName = UnitName("player")
	self.FactionName = select(1, UnitFactionGroup("player")) or "Unknown"
	if self.FactionName == "Alliance" then
		self.EnemyFactionName = "Horde"
	elseif self.FactionName == "Horde" then
		self.EnemyFactionName = "Alliance"
	else
		self.EnemyFactionName = "Unknown"
	end

	self.EnabledInZone = false
	self.InInstance = false

	self:RegisterChatCommand("hw", "SlashCommand")
	self:RegisterChatCommand("hordewatch", "SlashCommand")

	if self.SetupOptions then self:SetupOptions() end
	if self.SetupMinimapIcon then self:SetupMinimapIcon() end
end

function HW:OnEnable()
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ZoneChanged")
	self:RegisterEvent("ZONE_CHANGED", "ZoneChanged")
	self:RegisterEvent("ZONE_CHANGED_INDOORS", "ZoneChanged")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "ZoneChanged")
	self:RegisterEvent("UNIT_FACTION", "ZoneChanged")

	self:StartDetection()
	self:StartComm()

	self:ScheduleRepeatingTimer("PruneSightings", 300)

	self:ZoneChanged()
end

function HW:OnDisable()
	self:StopDetection()
	self:StopComm()
end

function HW:InFilteredZone(zone, subZone)
	local zones = self.db.profile.FilteredZones
	if zones[zone] then return true end
	if subZone and zones[subZone] then return true end
	return false
end

function HW:ZoneChanged()
	if not self.db.profile.Enabled then
		self.EnabledInZone = false
		return
	end

	self.InInstance = false
	local pvpType = GetZonePVPInfo()
	local zone = GetZoneText()
	local subZone = GetSubZoneText()

	if pvpType == "sanctuary" and not self.db.profile.EnabledInSanctuaries then
		self.EnabledInZone = false
	elseif zone == "" or self:InFilteredZone(zone, subZone) then
		self.EnabledInZone = false
	else
		local inInstance, instanceType = IsInInstance()
		self.EnabledInZone = true
		if inInstance then
			self.InInstance = true
			if instanceType == "party" or instanceType == "raid"
				or (instanceType == "pvp" and not self.db.profile.EnabledInBattlegrounds)
				or (instanceType == "arena" and not self.db.profile.EnabledInArenas) then
				self.EnabledInZone = false
			end
		elseif pvpType == "combat" and not self.db.profile.EnabledInWintergrasp then
			self.EnabledInZone = false
		elseif self.db.profile.DisableWhenPVPUnflagged and UnitIsPVP("player") == false then
			self.EnabledInZone = false
		end
	end

	if self.UpdateWindowVisibility then
		self:UpdateWindowVisibility()
	end
end

function HW:SlashCommand(input)
	input = strtrim(input or "")
	if input == "" or input == "show" then
		self.db.profile.ShowWindow = true
		if self.ShowWindow then self:ShowWindow() end
	elseif input == "hide" then
		self.db.profile.ShowWindow = false
		if self.HideWindow then self:HideWindow() end
	elseif input == "enable" then
		self.db.profile.Enabled = true
		self:ZoneChanged()
		print("|cff33ff99HordeWatch|r enabled")
	elseif input == "disable" then
		self.db.profile.Enabled = false
		self:ZoneChanged()
		print("|cff33ff99HordeWatch|r disabled")
	elseif input == "clear" then
		if self.ClearCurrentState then self:ClearCurrentState() end
	elseif input == "status" then
		local count = 0
		for _ in pairs(self.charDB.CurrentState) do count = count + 1 end
		print(("|cff33ff99HordeWatch|r enabled=%s inZone=%s tracked=%d totalRecords=%d"):format(
			tostring(self.db.profile.Enabled), tostring(self.EnabledInZone), count, #self.charDB.Sightings))
	elseif input == "config" or input == "options" then
		if self.OpenConfig then self:OpenConfig() end
	else
		print("|cff33ff99HordeWatch|r commands: show, hide, enable, disable, clear, status, config")
	end
end
