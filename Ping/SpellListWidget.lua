--[[--------------------------------------------------------------------------
  PingSpellList -- an AceGUI widget that shows a spell list as ROWS.

  Ping keeps two spell lists in the profile: the healer whitelist and the
  cooldown watch list. Both were multiline text boxes, which is honest but
  unpleasant - a column of names with no icons, no way to tell a typo from a
  spell that simply is not in your client, and removal by selecting text.

  This shows the same list as one row per spell: icon, name, spell id, and an X
  to remove it, with an add box underneath. It is the same widget for both
  lists, because they have the same shape.

  Two things are deliberate:

    * THE DATA MODEL DOES NOT CHANGE. The value going in and out is still the
      newline-separated text the profile has always stored, so nothing that
      parses those lists had to be touched, transfer codes still carry them,
      and a broken widget cannot cost anybody their list.

    * ROWS ARE RE-SERIALISED VERBATIM. A row the user did not touch is written
      back exactly as it came in, comments and all. The cooldown list uses a
      trailing "= 120" to override a duration; regenerating lines from parsed
      fields would quietly discard that.

  Registered as a dialogControl. If this file fails to load, AceConfigDialog
  falls back to the plain multiline box on its own, so the lists stay editable.
----------------------------------------------------------------------------]]

local Type, Version = "PingSpellList", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Silent lookup: this file is loaded after the locales, but a widget that
-- errors takes the whole options page with it, so it is not worth assuming.
local L = LibStub("AceLocale-3.0"):GetLocale("Ping", true)
local function loc(key, fallback)
	local text = L and L[key]
	if type(text) == "string" and text ~= "" then return text end
	return fallback
end

local pairs, ipairs, tonumber, format = pairs, ipairs, tonumber, format
local CreateFrame, UIParent, GameTooltip = CreateFrame, UIParent, GameTooltip
local _G = _G

local ROW_HEIGHT = 20
local ICON_SIZE = 16
local ADD_HEIGHT = 24
local QUESTION_MARK = "Interface\\Icons\\INV_Misc_QuestionMark"

------------------------------------------------------------------------------
-- spell lookup
------------------------------------------------------------------------------
-- Classic and current clients disagree about which of these exist, and a
-- missing global is a hard error rather than a nil return, so every call is
-- guarded. A spell we cannot resolve still gets a row - it just wears the
-- question mark icon, which is exactly the signal the user needs: "this line
-- is not matching anything".
local function spellName(id)
	if not id then return nil end
	if _G.C_Spell and _G.C_Spell.GetSpellInfo then
		local ok, info = pcall(_G.C_Spell.GetSpellInfo, id)
		if ok and type(info) == "table" and info.name then return info.name end
	end
	if _G.GetSpellInfo then
		local ok, name = pcall(_G.GetSpellInfo, id)
		if ok and type(name) == "string" and name ~= "" then return name end
	end
	return nil
end

local function spellTexture(id)
	if not id then return nil end
	if _G.C_Spell and _G.C_Spell.GetSpellTexture then
		local ok, tex = pcall(_G.C_Spell.GetSpellTexture, id)
		if ok and tex then return tex end
	end
	if _G.GetSpellTexture then
		local ok, tex = pcall(_G.GetSpellTexture, id)
		if ok and tex then return tex end
	end
	if _G.GetSpellInfo then
		-- Classic's GetSpellInfo returns the icon as its third value.
		local ok, _, _, icon = pcall(_G.GetSpellInfo, id)
		if ok and icon then return icon end
	end
	return nil
end

------------------------------------------------------------------------------
-- parsing
------------------------------------------------------------------------------
local function trim(s)
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- One line -> one entry. Mirrors what Ping.lua's own parsers accept so the
-- rows show the same reading of the list that the detection code uses: a
-- spell link, "Name (id)", a bare id, or a bare name.
--
-- `raw` is kept whole. Everything else is display.
local function parseLine(raw)
	local line = trim(raw)
	if line == "" then return nil end

	local entry = { raw = raw }

	-- A comment-only line has nothing to show as a row, but throwing it away
	-- would edit the user's list behind their back, so it is carried.
	if line:sub(1, 2) == "--" then
		entry.comment = true
		entry.name = line
		return entry
	end

	entry.id = tonumber(line:match("spell:(%d+)"))
		or tonumber(line:match("%((%d+)%)"))
		or tonumber(line:match("^(%d+)"))

	local bracketed = line:match("%[([^%]]+)%]")
	if bracketed then
		entry.name = bracketed
	else
		-- "Name (1234) = 120  -- 2m" -> "Name"
		local head = line:match("^(.-)%s*%(%d+%)") or line:match("^(.-)%s*=") or line:match("^(.-)%s*%-%-")
		head = head and trim(head) or nil
		if head == "" then head = nil end
		entry.name = head
	end

	entry.duration = tonumber(line:match("=%s*(%d+)"))

	local resolved = spellName(entry.id)
	if resolved then
		-- The client's own name wins for display. If it disagrees with what is
		-- written, what is written is the stale one.
		entry.name = resolved
		entry.known = true
	elseif not entry.name and entry.id then
		entry.name = format("Spell %d", entry.id)
	end

	entry.name = entry.name or line
	return entry
end

local function parseText(text)
	local entries = {}
	for line in (text or ""):gmatch("[^\n]+") do
		local entry = parseLine(line)
		if entry then entries[#entries + 1] = entry end
	end
	return entries
end

local function serialise(entries)
	local lines = {}
	for _, entry in ipairs(entries) do
		lines[#lines + 1] = entry.raw
	end
	return table.concat(lines, "\n")
end

------------------------------------------------------------------------------
-- rows
------------------------------------------------------------------------------
local function rowOnEnter(row)
	local entry = row.entry
	if not entry then return end
	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	if entry.id and entry.known then
		local shown = false
		if GameTooltip.SetSpellByID then
			shown = pcall(GameTooltip.SetSpellByID, GameTooltip, entry.id)
		end
		if not shown then
			pcall(GameTooltip.SetHyperlink, GameTooltip, "spell:" .. entry.id)
		end
	else
		GameTooltip:SetText(entry.name or "", 1, 1, 1)
		if entry.id then
			-- The id parsed but the client has never heard of it. Worth saying
			-- outright: this line is dead weight, not a working entry.
			GameTooltip:AddLine(loc("SpellListUnknown", "This client does not know this spell id."), 1, 0.4, 0.4)
		end
	end
	GameTooltip:Show()
end

local function rowOnLeave()
	GameTooltip:Hide()
end

local function removeOnClick(button)
	local widget = button.obj
	local index = button:GetParent().index
	if not widget or not index then return end
	table.remove(widget.entries, index)
	widget:Commit()
end

local function acquireRow(widget, index)
	local row = widget.rows[index]
	if row then return row end

	row = CreateFrame("Button", nil, widget.content)
	row:SetHeight(ROW_HEIGHT)
	row:SetPoint("LEFT", widget.content, "LEFT", 0, 0)
	row:SetPoint("RIGHT", widget.content, "RIGHT", 0, 0)
	row:SetPoint("TOP", widget.content, "TOP", 0, -(index - 1) * ROW_HEIGHT)

	local highlight = row:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetAllPoints()
	highlight:SetColorTexture(1, 1, 1, 0.08)

	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(ICON_SIZE, ICON_SIZE)
	row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)
	-- Trim the default icon border so the art lines up with the text baseline.
	row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
	row.name:SetJustifyH("LEFT")

	row.remove = CreateFrame("Button", nil, row)
	row.remove:SetSize(16, 16)
	row.remove:SetPoint("RIGHT", row, "RIGHT", -2, 0)
	row.remove:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
	row.remove:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
	row.remove:SetScript("OnClick", removeOnClick)
	row.remove.obj = widget

	row.info = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	row.info:SetPoint("RIGHT", row.remove, "LEFT", -6, 0)
	row.info:SetJustifyH("RIGHT")

	row.name:SetPoint("RIGHT", row.info, "LEFT", -6, 0)

	row:SetScript("OnEnter", rowOnEnter)
	row:SetScript("OnLeave", rowOnLeave)

	widget.rows[index] = row
	return row
end

local function fillRow(row, entry, index, disabled)
	row.index = index
	row.entry = entry

	if entry.comment then
		row.icon:SetTexture(nil)
		row.name:SetText(entry.name)
		row.name:SetTextColor(0.5, 0.5, 0.5)
		row.info:SetText("")
	else
		row.icon:SetTexture(spellTexture(entry.id) or QUESTION_MARK)
		row.name:SetText(entry.name or "")
		if entry.known or not entry.id then
			row.name:SetTextColor(1, 1, 1)
		else
			-- Parsed as a spell id the client cannot resolve.
			row.name:SetTextColor(1, 0.4, 0.4)
		end
		local info = entry.id and tostring(entry.id) or ""
		if entry.duration then
			info = format("%s  %ds", info, entry.duration)
		end
		row.info:SetText(info)
	end

	if disabled then
		row.remove:Hide()
		row:EnableMouse(false)
	else
		row.remove:Show()
		row:EnableMouse(true)
	end
	row:Show()
end

------------------------------------------------------------------------------
-- adding
------------------------------------------------------------------------------
-- Accepts what a person can actually produce in game: a shift-clicked spell
-- link, an id copied from a website, or a typed name.
local function addFromText(widget, text)
	text = trim(text or "")
	if text == "" then return end

	local id = tonumber(text:match("spell:(%d+)")) or tonumber(text:match("%((%d+)%)")) or tonumber(text:match("^(%d+)$"))
	local bracketed = text:match("%[([^%]]+)%]")
	local name = bracketed or (id and spellName(id)) or text

	local raw
	if id and name then
		raw = format("%s (%d)", name, id)
	elseif id then
		raw = tostring(id)
	else
		raw = name
	end

	-- Silently adding a second copy would look like the add did nothing.
	local lowerName = name and name:lower()
	for _, entry in ipairs(widget.entries) do
		if (id and entry.id == id) or (lowerName and entry.name and entry.name:lower() == lowerName) then
			widget.addBox:SetText("")
			widget.addBox:ClearFocus()
			return
		end
	end

	widget.entries[#widget.entries + 1] = parseLine(raw)
	widget.addBox:SetText("")
	widget.addBox:ClearFocus()
	widget:Commit()
end

local function addOnClick(button)
	local widget = button.obj
	addFromText(widget, widget.addBox:GetText())
end

local function addBoxOnEnter(frame)
	addFromText(frame.obj, frame:GetText())
end

------------------------------------------------------------------------------
-- shift-click link insertion
------------------------------------------------------------------------------
-- Same trick AceGUI's own edit boxes use: hook the game's link insertion and
-- hand the link to whichever of our add boxes has focus. Without this,
-- shift-clicking a spell does nothing while the options window is open.
if not _G.PingSpellListInsertLink then
	hooksecurefunc("ChatEdit_InsertLink", function(...) return _G.PingSpellListInsertLink(...) end)
end

function _G.PingSpellListInsertLink(text)
	for i = 1, AceGUI:GetWidgetCount(Type) do
		local box = _G[format("%s%dAdd", Type, i)]
		if box and box:IsVisible() and box:HasFocus() then
			box:Insert(text)
			return true
		end
	end
end

------------------------------------------------------------------------------
-- widget
------------------------------------------------------------------------------
local function Layout(self)
	local height = self.labelHeight + self.numlines * ROW_HEIGHT + ADD_HEIGHT + 20
	self:SetHeight(height)
	if self.labelHeight == 0 then
		self.listBG:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, 0)
	else
		self.listBG:SetPoint("TOPLEFT", self.label, "BOTTOMLEFT", 0, -2)
	end
end

local methods = {
	["OnAcquire"] = function(self)
		self:SetWidth(200)
		self.entries = {}
		self.numlines = 8
		self:SetDisabled(false)
		self.addBox:SetText("")
		Layout(self)
	end,

	["OnRelease"] = function(self)
		self.addBox:ClearFocus()
		self.entries = {}
		for _, row in pairs(self.rows) do row:Hide() end
	end,

	["SetLabel"] = function(self, text)
		if text and text ~= "" then
			self.label:SetText(text)
			self.label:Show()
			self.labelHeight = 14
		else
			self.label:Hide()
			self.labelHeight = 0
		end
		Layout(self)
	end,

	-- AceConfigDialog passes the option's `multiline` value here, so the number
	-- of visible rows is set the same way the text box's height was.
	["SetNumLines"] = function(self, value)
		value = tonumber(value) or 8
		if value < 4 then value = 4 end
		self.numlines = value
		Layout(self)
	end,

	["SetText"] = function(self, text)
		self.text = text or ""
		self.entries = parseText(self.text)
		self:Refresh()
	end,

	["GetText"] = function(self)
		return serialise(self.entries)
	end,

	["SetDisabled"] = function(self, disabled)
		self.disabled = disabled
		if disabled then
			self.label:SetTextColor(0.5, 0.5, 0.5)
			self.addBox:EnableMouse(false)
			self.addBox:ClearFocus()
			self.addBox:SetTextColor(0.5, 0.5, 0.5)
			self.addButton:Disable()
		else
			self.label:SetTextColor(1, 0.82, 0)
			self.addBox:EnableMouse(true)
			self.addBox:SetTextColor(1, 1, 1)
			self.addButton:Enable()
		end
		self:Refresh()
	end,

	["Refresh"] = function(self)
		local count = #self.entries
		for i = 1, count do
			fillRow(acquireRow(self, i), self.entries[i], i, self.disabled)
		end
		for i = count + 1, #self.rows do
			self.rows[i]:Hide()
		end
		self.content:SetHeight(math.max(count * ROW_HEIGHT, 1))
		self.empty:SetShown(count == 0)
	end,

	-- Writes the list back through the same path the text box used, so the
	-- profile, the rebuild of the lookup tables and the list refresh all happen
	-- exactly as before.
	["Commit"] = function(self)
		self:Refresh()
		self:Fire("OnEnterPressed", serialise(self.entries))
	end,
}

local function Constructor()
	local widgetNum = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", nil, UIParent)
	frame:Hide()

	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -2)
	label:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -2)
	label:SetJustifyH("LEFT")
	label:SetHeight(14)

	local listBG = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	listBG:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	listBG:SetBackdropColor(0, 0, 0, 0.6)
	listBG:SetBackdropBorderColor(0.4, 0.4, 0.4)
	listBG:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
	listBG:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
	listBG:SetPoint("BOTTOM", frame, "BOTTOM", 0, ADD_HEIGHT + 4)

	local scrollFrame = CreateFrame("ScrollFrame", format("%s%dScroll", Type, widgetNum), listBG, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", listBG, "TOPLEFT", 6, -6)
	scrollFrame:SetPoint("BOTTOMRIGHT", listBG, "BOTTOMRIGHT", -26, 6)

	local scrollBar = _G[scrollFrame:GetName() .. "ScrollBar"] or scrollFrame.ScrollBar
	if scrollBar then
		scrollBar:ClearAllPoints()
		scrollBar:SetPoint("TOPRIGHT", listBG, "TOPRIGHT", -6, -18)
		scrollBar:SetPoint("BOTTOMRIGHT", listBG, "BOTTOMRIGHT", -6, 18)
	end

	local content = CreateFrame("Frame", nil, scrollFrame)
	content:SetSize(1, 1)
	scrollFrame:SetScrollChild(content)
	scrollFrame:SetScript("OnSizeChanged", function(self, width)
		content:SetWidth(width or self:GetWidth())
	end)

	-- Set explicitly rather than relying on the template: which of the scroll
	-- templates carries a wheel handler has changed between client versions,
	-- and a list you can only scroll by dragging the bar is a poor list.
	scrollFrame:EnableMouseWheel(true)
	scrollFrame:SetScript("OnMouseWheel", function(self, delta)
		local current = self:GetVerticalScroll()
		local maximum = self:GetVerticalScrollRange()
		local target = current - delta * ROW_HEIGHT * 2
		if target < 0 then target = 0 elseif target > maximum then target = maximum end
		self:SetVerticalScroll(target)
	end)

	local empty = listBG:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	empty:SetPoint("TOPLEFT", listBG, "TOPLEFT", 10, -10)
	empty:SetText(loc("SpellListEmpty", "Nothing in this list."))
	empty:Hide()

	local addBox = CreateFrame("EditBox", format("%s%dAdd", Type, widgetNum), frame, "InputBoxTemplate")
	addBox:SetHeight(20)
	addBox:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 6, 2)
	addBox:SetAutoFocus(false)
	addBox:SetScript("OnEnterPressed", addBoxOnEnter)
	addBox:SetScript("OnEscapePressed", addBox.ClearFocus)

	local addButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	addButton:SetSize(60, 22)
	addButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 1)
	addButton:SetText(loc("SpellListAdd", "Add"))
	addButton:SetScript("OnClick", addOnClick)

	addBox:SetPoint("RIGHT", addButton, "LEFT", -6, 0)

	local widget = {
		frame       = frame,
		label       = label,
		labelHeight = 14,
		listBG      = listBG,
		scrollFrame = scrollFrame,
		content     = content,
		empty       = empty,
		addBox      = addBox,
		addButton   = addButton,
		rows        = {},
		entries     = {},
		numlines    = 8,
		type        = Type,
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end
	addBox.obj, addButton.obj = widget, widget

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
