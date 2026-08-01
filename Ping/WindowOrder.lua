local TopWindow
local AddToScale = {}
local AllWindows = {}
local LevelDiff
local _

local function SetLevel_ProcessChildFrames(...)
	for i = 1, select('#', ...) do
		local frame = select(i, ...)
		Ping:SetLevel(frame, frame:GetFrameLevel() + LevelDiff)
	end
end

function Ping:SetLevel(frame, level)
	LevelDiff = level - frame:GetFrameLevel()
	frame:SetFrameLevel(level)
end

function Ping:InitOrder()
	TopWindow = UIParent
	Ping:AddWindow(Ping.MainWindow)
end

function Ping:SetWindowTop(window)
	if InCombatLockdown() then
		return
	end
	local Check = window.Above

	while Check ~= nil do
		window.Above = Check.Above
		Check.Above = window

		Check.Below = window.Below
		window.Below = Check

		Check.Below.Above = Check

		Ping:SetLevel(Check, Check.Below:GetFrameLevel() + 10)
		Check = window.Above
	end
	Ping:SetLevel(window, window.Below:GetFrameLevel() + 10)
	TopWindow = window
end

function Ping:AddWindow(window)
	window.Below = TopWindow
	TopWindow.Above = window
	window.Above = nil

	Ping:SetLevel(window, TopWindow:GetFrameLevel() + 10)
	TopWindow = window

	AddToScale[#AddToScale + 1] = window
	AllWindows[#AllWindows + 1] = window

	window.isLocked = Ping.db.profile.Locked
end

function Ping:ResetPositionAllWindows()
	for k, v in pairs(AllWindows) do
		v:ClearAllPoints()
		v:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
end

function Ping:LockWindows(lock)
	for k, v in pairs(AllWindows) do
		if not Ping.db.profile.InvertPing then
			if v.DragBottomRight then
				v.isLocked = lock
				v:EnableMouse(not lock)
				if lock then
					v.DragBottomRight:Hide()
					v.DragBottomLeft:Hide()
				else
					v.DragBottomRight:Show()
					v.DragBottomLeft:Show()
				end
			else
				v.isLocked = false
				v:EnableMouse(true)
			end
		else
			if v.DragTopRight then
				v.isLocked = lock
				v:EnableMouse(not lock)
				if lock then
					v.DragTopRight:Hide()
					v.DragTopLeft:Hide()
				else
					v.DragTopRight:Show()
					v.DragTopLeft:Show()
				end
			else
				v.isLocked = false
				v:EnableMouse(true)	
			end
		end
	end
end

function Ping:ClampToScreen()
	for k, v in pairs(AllWindows) do
		v:SetClampedToScreen(Ping.db.profile.ClampToScreen)
	end
end