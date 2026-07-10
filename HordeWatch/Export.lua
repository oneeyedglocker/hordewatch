local HW = HordeWatch

-- Turns the sighting log into a copy-pasteable string the website can
-- decode client-side, since WoW addons cannot make HTTP calls (see
-- DATA_MODEL.md "Where the data actually lives today"). Pipeline:
--   AceSerializer:Serialize -> LibDeflate:CompressZlib -> LibDeflate:EncodeForPrint
-- The web app reverses all three steps (pako zlib inflate + a JS port of
-- AceSerializer's deserializer and LibDeflate's print encoding).

local function buildExportRows(sightings)
	local rows = {}
	for i, rec in ipairs(sightings) do
		rows[i] = {
			id = rec.id,
			player = rec.player,
			class = rec.class,
			race = rec.race,
			level = rec.level,
			levelIsGuess = rec.levelIsGuess,
			guild = rec.guild,
			zone = rec.zone,
			subZone = rec.subZone,
			mapID = rec.mapID,
			mapX = rec.mapX,
			mapY = rec.mapY,
			worldX = rec.worldX,
			worldY = rec.worldY,
			continentID = rec.continentID,
			layer = rec.layer,
			method = rec.method,
			ts = rec.ts,
			reporter = rec.reporter,
			relayed = rec.relayed,
			relaySender = rec.relaySender,
			relayDelay = rec.relayDelay,
			windowStart = rec.windowStart,
			reportCount = rec.reportCount,
			reporters = rec.reporters,
		}
	end
	return rows
end

--- Builds the export string.
-- @param all if true, export the entire log; otherwise only sightings added
--   since the last export (tracked via charDB.LastExportedId), so repeated
--   exports across a play session stay small.
-- @return encoded string (nil if nothing to export), number of rows exported
function HW:BuildExportString(all)
	local db = self.charDB
	local watermark = db.LastExportedId or 0
	local rows = {}
	for _, rec in ipairs(db.Sightings) do
		if all or (rec.id or 0) > watermark then
			rows[#rows + 1] = rec
		end
	end
	if #rows == 0 then return nil, 0 end

	local payload = {
		v = 1,
		char = self.CharacterName,
		realm = self.RealmName,
		exportedAt = time(),
		sightings = buildExportRows(rows),
	}

	local serialized = self:Serialize(payload)
	local LibDeflate = LibStub("LibDeflate")
	local compressed = LibDeflate:CompressZlib(serialized)
	local encoded = LibDeflate:EncodeForPrint(compressed)

	-- Advance the watermark regardless of `all` so the *next* export - full
	-- or incremental - doesn't resend rows we just handed over.
	local maxId = watermark
	for _, rec in ipairs(rows) do
		if rec.id and rec.id > maxId then maxId = rec.id end
	end
	db.LastExportedId = maxId

	return encoded, #rows
end

StaticPopupDialogs["HORDEWATCH_EXPORT"] = {
	text = "HordeWatch export (%d sighting(s)) - Ctrl+A, Ctrl+C to copy:",
	button1 = CLOSE,
	hasEditBox = true,
	editBoxWidth = 350,
	maxLetters = 0,
	OnShow = function(self)
		self.editBox:SetText(self.data)
		self.editBox:HighlightText()
		self.editBox:SetFocus()
	end,
	EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
	EditBoxOnEnterPressed = function(self) self:GetParent():Hide() end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

function HW:ShowExportDialog(all)
	local encoded, count = self:BuildExportString(all)
	if not encoded then
		print("|cff33ff99HordeWatch|r nothing new to export" .. (all and "" or " (try '/hw export all' for the full log)"))
		return
	end
	local dialog = StaticPopup_Show("HORDEWATCH_EXPORT", count)
	if dialog then
		dialog.data = encoded
	end
end
