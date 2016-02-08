--[[--------------------------------------------------------------------
	VisiHUD
	High visibility combat HUD for World of Warcraft
	Copyright (c) 2016 Drak <drak@derpydo.com>. All rights reserved.
	https://github.com/Drak1814/VisiHUD_Options
----------------------------------------------------------------------]]


local _, ns = ...
local L = ns.L

LibStub("VisiHUD-OptionsPanel").CreateOptionsPanel(L.Move, "VisiHUD", function(panel)
	local title, notes = panel:CreateHeader(panel.name, L.Move_Desc)
	local showDefaults, showAllDefaults = {}

end)