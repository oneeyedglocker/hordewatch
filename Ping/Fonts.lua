local FontStrings={}
local FontFile
local SM = LibStub:GetLibrary("LibSharedMedia-3.0")
local _

SM:Register("font", "Big Noodle Titling", [[Interface\AddOns\Ping\Fonts\BigNoodleTitling.ttf]])
SM:Register("font", "Expressway", [[Interface\AddOns\Ping\Fonts\Expressway.ttf]])
SM:Register("font", "Myriad", [[Interface\AddOns\Ping\Fonts\Myriad.ttf]])
SM:Register("font", "Ping Bangers", [[Interface\AddOns\Ping\Fonts\Bangers-Regular.ttf]])
SM:Register("font", "Ping Bebas Neue", [[Interface\AddOns\Ping\Fonts\BebasNeue-Regular.ttf]])

function Ping:AddFontString(string)
	local Font, Height, Flags

	FontStrings[#FontStrings+1] = string

	if not FontFile and Ping.db.profile.Font then
		FontFile = SM:Fetch("font", Ping.db.profile.Font)
	end

	if FontFile then
		Font, Height, Flags = string:GetFont()
		if Font ~= FontFile then
			string:SetFont(FontFile, Height, Flags)
		end
	end
end

function Ping:SetFont(fontname)
	local Height, Flags

	Ping.db.profile.Font = fontname
	FontFile = SM:Fetch("font",fontname)

	for k, v in pairs(FontStrings) do
		k, Height, Flags = v:GetFont()
		v:SetFont(FontFile, Height, Flags)
	end
	if Ping.ApplyThemeFonts then Ping:ApplyThemeFonts() end
end	

-- Full artwork can carry a small, theme-specific type system without changing
-- the user's global Ping font choice. Villain HUD follows the original SVUI
-- principle: expressive display face only in the header, condensed readable
-- rows, and a narrow face for the numeric/data side of the list.
function Ping:ApplyThemeFonts()
	local frame = Ping.MainWindow
	if not frame or not Ping.db or not Ping.db.profile then return end

	local profileFont = SM:Fetch("font", Ping.db.profile.Font or "Friz Quadrata TT")
	local villain = Ping.db.profile.ArtworkStyle == "villain"
	local titleFont = villain and SM:Fetch("font", "Ping Bangers") or profileFont
	local rowFont = villain and SM:Fetch("font", "Expressway") or profileFont
	local dataFont = villain and SM:Fetch("font", "Ping Bebas Neue") or profileFont
	local rowHeight = Ping.db.profile.MainWindow.RowHeight or 15

	if frame.Title then
		frame.Title:SetFont(titleFont, villain and math.max(13, rowHeight * 0.95) or math.max(11, rowHeight * 0.8), villain and "OUTLINE" or "")
	end
	for _, row in pairs(frame.Rows or {}) do
		if row.LeftText then row.LeftText:SetFont(rowFont, math.max(rowHeight * 0.75, rowHeight - 3), villain and "OUTLINE" or "") end
		if row.RightText then row.RightText:SetFont(dataFont, math.max(rowHeight * 0.65, rowHeight - 12), villain and "OUTLINE" or "") end
		if row.HealerMarker then row.HealerMarker:SetFont(rowFont, math.max(rowHeight * 0.9, rowHeight - 2), "OUTLINE") end
	end
	if frame.CountFrame and frame.CountFrame.Text then
		frame.CountFrame.Text:SetFont(dataFont, rowHeight * 0.85, "OUTLINE")
	end
end
