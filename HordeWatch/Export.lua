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

-- Blizzard's StaticPopup dialogs only pre-create an editBox widget on the
-- first few numbered popup frames (historically 4) - if any other addon or
-- system dialog is already occupying those slots when this one shows, it
-- gets bumped to a plain popup frame with no editBox at all, and
-- `self.editBox:SetText(...)` crashes with "attempt to index field
-- 'editBox' (a nil value)". A self-owned AceGUI frame sidesteps that
-- limited shared pool entirely - it always has its own edit box.
local exportFrame

function HW:ShowExportDialog(all)
	local encoded, count = self:BuildExportString(all)
	if not encoded then
		print("|cff33ff99HordeWatch|r nothing new to export" .. (all and "" or " (try '/hw export all' for the full log)"))
		return
	end

	local AceGUI = LibStub("AceGUI-3.0")
	if exportFrame then
		AceGUI:Release(exportFrame)
		exportFrame = nil
	end

	local frame = AceGUI:Create("Frame")
	frame:SetTitle("HordeWatch Export")
	frame:SetStatusText(("%d sighting(s) - Ctrl+A, Ctrl+C to copy, then close"):format(count))
	frame:SetLayout("Fill")
	frame:SetWidth(520)
	frame:SetHeight(320)
	frame:SetCallback("OnClose", function(widget)
		AceGUI:Release(widget)
		exportFrame = nil
	end)
	exportFrame = frame

	local editBox = AceGUI:Create("MultiLineEditBox")
	editBox:SetLabel("")
	editBox:SetText(encoded)
	editBox:DisableButton(true)
	frame:AddChild(editBox)

	-- Focus/highlight need to happen after the frame has actually laid
	-- itself out, or SetFocus silently no-ops.
	C_Timer.After(0, function()
		editBox:SetFocus()
		editBox:HighlightText()
	end)
end
