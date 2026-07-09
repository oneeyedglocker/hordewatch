local HW = HordeWatch

-- TBC-era tokens only (matches the classes/races actually reachable on
-- this Interface version) - used to sanity-check inbound comm payloads
-- before trusting them.
HW.ValidClasses = {
	DRUID = true, HUNTER = true, MAGE = true, PALADIN = true, PRIEST = true,
	ROGUE = true, SHAMAN = true, WARLOCK = true, WARRIOR = true,
}
HW.ValidRaces = {
	Human = true, Orc = true, Dwarf = true, Tauren = true, Troll = true,
	NightElf = true, Scourge = true, Gnome = true, BloodElf = true, Draenei = true,
}

-- Improvements over Spy's comm layer:
--  1. AceSerializer instead of hand-rolled pipe-delimited strings - a "|"
--     inside a guild name would silently corrupt Spy's strsplit parsing.
--  2. Restricted to the GUILD distribution only. Blizzard authenticates
--     GUILD-channel membership server-side, so senders are at least a
--     verified member of your guild (still not proof the DATA is honest -
--     see validation below - but strictly stronger than Spy's PARTY/RAID
--     options, which admit any pickup group).
--  3. Per-player rate limiting on send, so a combat-log burst against one
--     target doesn't spam the guild channel with near-duplicate packets.
--  4. Relayed sightings are tagged as such (method=COMM, relayed=true,
--     relaySender, relayDelay) so a dashboard can tell a secondhand report
--     apart from a personal one. Spy makes no such distinction - a relayed
--     sighting looks identical to a personal one once it lands in
--     PlayerData.

local lastBroadcastAt = {}

local function validatePayload(p)
	if type(p) ~= "table" then return false end
	if type(p.player) ~= "string" or p.player == "" or #p.player > 48 then return false end
	if p.class ~= nil and not HW.ValidClasses[p.class] then return false end
	if p.race ~= nil and not HW.ValidRaces[p.race] then return false end
	if p.level ~= nil then
		if type(p.level) ~= "number" or p.level < 1 or p.level > 80 or p.level ~= math.floor(p.level) then
			return false
		end
	end
	if p.mapX ~= nil and (type(p.mapX) ~= "number" or p.mapX < 0 or p.mapX > 1) then return false end
	if p.mapY ~= nil and (type(p.mapY) ~= "number" or p.mapY < 0 or p.mapY > 1) then return false end
	if p.layer ~= nil and type(p.layer) ~= "number" then return false end
	if type(p.ts) ~= "number" then return false end
	if p.zone ~= nil and (type(p.zone) ~= "string" or #p.zone > 64) then return false end
	if p.guild ~= nil and (type(p.guild) ~= "string" or #p.guild > 64) then return false end
	return true
end

function HW:OnLocalSighting(_, record)
	if not self.db.profile.ShareToGuild then return end
	if record.method == self.Method.COMM then return end -- never re-relay relayed data (no gossip loops)
	if not IsInGuild() then return end
	if self.InInstance then return end -- don't leak instance/BG composition to the wider guild channel

	local now = time()
	local last = lastBroadcastAt[record.player]
	if last and (now - last) < self.db.profile.CommRateLimitSeconds then return end
	lastBroadcastAt[record.player] = now

	local payload = {
		v = self.Version,
		player = record.player,
		class = record.class,
		race = record.race,
		level = record.level,
		levelIsGuess = record.levelIsGuess,
		guild = record.guild,
		zone = record.zone,
		subZone = record.subZone,
		mapID = record.mapID,
		mapX = record.mapX,
		mapY = record.mapY,
		layer = record.layer,
		method = record.method,
		ts = record.ts,
		reporter = record.reporter,
	}

	local serialized = self:Serialize(payload)
	self:SendCommMessage(self.Signature, serialized, "GUILD")
end

function HW:OnCommReceived(prefix, message, _, sender)
	if prefix ~= self.Signature then return end
	if not self.db.profile.ShareToGuild then return end

	local ok, payload = self:Deserialize(message)
	if not ok or not validatePayload(payload) then return end

	self:AddSighting({
		player = payload.player,
		class = payload.class,
		race = payload.race,
		level = payload.level,
		levelIsGuess = payload.levelIsGuess,
		guild = payload.guild,
		zone = payload.zone,
		subZone = payload.subZone,
		mapID = payload.mapID,
		mapX = payload.mapX,
		mapY = payload.mapY,
		layer = payload.layer,
		method = self.Method.COMM,
		ts = payload.ts,
		reporter = payload.reporter or sender,
		relayed = true,
		relaySender = sender,
		relayDelay = time() - payload.ts,
	})
end

function HW:StartComm()
	self:RegisterComm(self.Signature, "OnCommReceived")
	self:RegisterMessage("HordeWatch_NewSighting", "OnLocalSighting")
end

function HW:StopComm()
	self:UnregisterComm(self.Signature)
	self:UnregisterMessage("HordeWatch_NewSighting")
end
