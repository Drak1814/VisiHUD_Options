--[[--------------------------------------------------------------------
	VisiHUD
	High visibility combat HUD for World of Warcraft
	Copyright (c) 2016 Drak <drak@derpydo.com>. All rights reserved.
	https://github.com/Drak1814/VisiHUD_Options
----------------------------------------------------------------------]]


local _name, ns = ...
local L = ns.L

assert(VisiHUD, _name .. " was unable to locate VisiHUD install.")

-- import other ns and remove global
setmetatable(ns, { __index = VisiHUD })
VisiHUD = nil

-- map values to labels
local outlineWeights = {
	NONE = L.None,
	OUTLINE = L.Thin,
	THICKOUTLINE = L.Thick,
}
local healthColorModes = {
	CLASS  = L.ColorClass,
	HEALTH = L.ColorHealth,
	CUSTOM = L.ColorCustom,
}
local powerColorModes = {
	CLASS  = L.ColorClass,
	POWER  = L.ColorPower,
	CUSTOM = L.ColorCustom,
}

ns.reload = false

------------------------------------------------------------------------
--	Options panel
------------------------------------------------------------------------

LibStub("VisiHUD-OptionsPanel"):New(VisiHUDOptions, nil, function(panel)
	
	ns.debug(panel.name)
	
	local db = VisiHUDConfig
	local Media = LibStub("LibSharedMedia-3.0")

	--------------------------------------------------------------------

	local title, notes = panel:CreateHeader(panel.name, L.Options_Desc)
	notes:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", -200, 0)
	
	--------------------------------------------------------------------

	local anchors = CreateFrame("Button", "VisiHUDMoveAnchors", panel, "UIPanelButtonTemplate")
	anchors:SetPoint("TOPLEFT", notes, "TOPRIGHT", 12, 0)
	anchors:SetSize(160, 22)
	anchors:SetText("Toggle Movers")
	anchors:SetScript("OnClick", ns.ToggleMovers)

	local statusbar = panel:CreateDropdown(L.Texture, nil, Media:List("statusbar"))
	statusbar:SetPoint("TOPLEFT", notes, "BOTTOMLEFT", 0, -12)
	statusbar:SetPoint("TOPRIGHT", notes, "BOTTOMRIGHT", -12, -12)

	local valueBG = statusbar:CreateTexture(nil, "OVERLAY")
	valueBG:SetPoint("LEFT", statusbar.valueText, -2, 1)
	valueBG:SetPoint("RIGHT", statusbar.valueText, 5, 1)
	valueBG:SetHeight(15)
	valueBG:SetVertexColor(0.35, 0.35, 0.35)
	statusbar.valueBG = valueBG

	function statusbar:OnValueChanged(value)
		local file = Media:Fetch("statusbar", value)
		valueBG:SetTexture(file)

		if value == db.statusbar then return end

		db.statusbar = value
		ns.SetAllStatusBarTextures()
	end

	do
		local button_OnClick = statusbar.button:GetScript("OnClick")
		statusbar.button:SetScript("OnClick", function(self)
			button_OnClick(self)
			statusbar.list:Hide()

			local function GetButtonBackground(self)
				if not self.bg then
					local bg = self:CreateTexture(nil, "BACKGROUND")
					bg:SetPoint("TOPLEFT", -3, 0)
					bg:SetPoint("BOTTOMRIGHT", 3, 0)
					bg:SetVertexColor(0.35, 0.35, 0.35)
					self.bg = bg
				end
				return self.bg
			end

			local function SetButtonBackgroundTextures(self)
				local numButtons = 0
				local buttons = statusbar.list.buttons
				for i = 1, #buttons do
					local button = buttons[i]
					if i > 1 then
						button:SetPoint("TOPLEFT", buttons[i - 1], "BOTTOMLEFT", 0, -1)
					end
					if button.value and button:IsShown() then
						local bg = button.bg or GetButtonBackground(button)
						bg:SetTexture(Media:Fetch("statusbar", button.value))
						local file, size = button.label:GetFont()
						button.label:SetFont(file, size, "OUTLINE")
						numButtons = numButtons + 1
					end
				end
				statusbar.list:SetHeight(statusbar.list:GetHeight() + (numButtons * 1))
			end

			local OnShow = statusbar.list:GetScript("OnShow")
			statusbar.list:SetScript("OnShow", function(self)
				OnShow(self)
				SetButtonBackgroundTextures(self)
			end)

			local OnVerticalScroll = statusbar.list.scrollFrame:GetScript("OnVerticalScroll")
			statusbar.list.scrollFrame:SetScript("OnVerticalScroll", function(self, delta)
				OnVerticalScroll(self, delta)
				SetButtonBackgroundTextures(self)
			end)

			button_OnClick(self)
			self:SetScript("OnClick", button_OnClick)
		end)
	end

	--------------------------------------------------------------------

	local font = panel:CreateDropdown(L.Font, nil, Media:List("font"))
	font:SetPoint("TOPLEFT", statusbar, "BOTTOMLEFT", 0, -12)
	font:SetPoint("TOPRIGHT", statusbar, "BOTTOMRIGHT", 0, -12)

	function font:OnValueChanged(value)
		local _, height, flags = self.valueText:GetFont()
		self.valueText:SetFont(Media:Fetch("font", value), height, flags)

		if value == db.font then return end

		db.font = value
		ns.SetAllFonts()
	end

	function font:OnListButtonChanged(button, value, selected)
		if button:IsShown() then
			button.label:SetFont(Media:Fetch("font", value), UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT)
		end
	end

	font.__SetValue = font.SetValue
	function font:SetValue(value)
		local _, height, flags = self.valueText:GetFont()
		self.valueText:SetFont(Media:Fetch("font", value), height, flags)
		self:__SetValue(value)
	end

	--------------------------------------------------------------------

	local outline = panel:CreateDropdown(L.Outline, nil, {
		{ value = "NONE", text = L.None },
		{ value = "OUTLINE", text = L.Thin },
		{ value = "THICKOUTLINE", text = L.Thick },
	})
	function outline:OnValueChanged(value)
		db.fontOutline = value
		ns.SetAllFonts()
	end
	outline:SetPoint("TOPLEFT", font, "BOTTOMLEFT", 0, -12)
	outline:SetPoint("TOPRIGHT", font, "BOTTOM", -6, -12)
	
	--------------------------------------------------------------------

	local shadow = panel:CreateCheckbox(L.Shadow)
	shadow:SetPoint("BOTTOMLEFT", outline, "BOTTOMRIGHT", 12, 0)

	function shadow:OnValueChanged(value)
		db.fontShadow = value
		ns.SetAllFonts()
	end
	
	--------------------------------------------------------------------
	
	local fontSize = panel:CreateSlider(L.FontSize, nil, .5, 1.5, .05, true)
	fontSize:SetPoint("TOPLEFT", outline, "BOTTOMLEFT", 0, -12)
	fontSize:SetPoint("TOPRIGHT", font, "BOTTOMRIGHT", -6, -24 - outline:GetHeight())

	function fontSize:OnValueChanged(value)
		db.fontScale = value
		ns.SetAllFonts()
		ns.reload = true
	end
	
	--------------------------------------------------------------------

	local borderSize = panel:CreateSlider(L.BorderSize, nil, 10, 24, 2)
	borderSize:SetPoint("TOPLEFT", fontSize, "BOTTOMLEFT", 0, -12)
	borderSize:SetPoint("TOPRIGHT", fontSize, "BOTTOMRIGHT", 0, -12)

	function borderSize:OnValueChanged(value)
		db.borderSize = value
		for i = 1, #ns.borderedObjects do
			ns.borderedObjects[i]:SetBorderSize(value)
		end
		return value
	end

	--------------------------------------------------------------------

	local borderColor = panel:CreateColorPicker(L.BorderColor, L.BorderColor_Desc)
	borderColor:SetPoint("LEFT", borderSize, "RIGHT", 24, -4)

	function borderColor:GetColor()
		return unpack(db.borderColor)
	end

	function borderColor:OnValueChanged(r, g, b)
		db.borderColor[1] = r
		db.borderColor[2] = g
		db.borderColor[3] = b
		for i = 1, #ns.borderedObjects do
			ns.borderedObjects[i]:SetBorderColor(r, g, b)
		end
		for i = 1, #ns.objects do
			local frame = ns.objects[i]
			if frame.UpdateBorder then
				frame:UpdateBorder()
			end
		end
	end

	--------------------------------------------------------------------

	local dispelFilter = panel:CreateCheckbox(L.FilterDebuffHighlight, L.FilterDebuffHighlight_Desc)
	dispelFilter:SetPoint("TOPLEFT", notes, "BOTTOMRIGHT", 12, -24)

	function dispelFilter:OnValueChanged(value)
		db.dispelFilter = value
		for i = 1, #ns.objects do
			local frame = ns.objects[i]
			if frame.DispelHighlight then
				frame.DispelHighlight.filter = value
				frame.DispelHighlight:ForceUpdate()
			end
		end
	end

	--------------------------------------------------------------------

	local healFilter = panel:CreateCheckbox(L.IgnoreOwnHeals, L.IgnoreOwnHeals_Desc)
	healFilter:SetPoint("TOPLEFT", dispelFilter, "BOTTOMLEFT", 0, -12)

	function healFilter:OnValueChanged(value)
		db.ignoreOwnHeals = value
		for i = 1, #ns.objects do
			local frame = ns.objects[i]
			if frame.HealPrediction and frame:IsShown() then
				frame.HealPrediction:ForceUpdate()
			end
		end
	end

	--------------------------------------------------------------------

	local threatLevels = panel:CreateCheckbox(L.ThreatLevels, L.ThreatLevels_Desc)
	threatLevels:SetPoint("TOPLEFT", healFilter, "BOTTOMLEFT", 0, -12)

	function threatLevels:OnValueChanged(value)
		db.ignoreOwnHeals = value
		for i = 1, #ns.objects do
			local frame = ns.objects[i]
			if frame.ThreatHighlight and frame:IsShown() then
				frame.ThreatHighlight:ForceUpdate()
			end
		end
	end

	--------------------------------------------------------------------

	local fastFocus = panel:CreateCheckbox("Fast focus", "Enable shift-click focus")
	fastFocus:SetPoint("TOPLEFT", threatLevels, "BOTTOMLEFT", 0, -12)

	function fastFocus:OnValueChanged(value)
		db.fastFocus = value
		ns.reload = true
	end
	
	--------------------------------------------------------------------

	local expandZoom = panel:CreateCheckbox("Expanded zoom", "Doubles maximum camera zoom out distance")
	expandZoom:SetPoint("TOPLEFT", fastFocus, "BOTTOMLEFT", 0, -12)

	function expandZoom:OnValueChanged(value)
		db.expandZoom = value
		ns.reload = true
	end	
	
	--------------------------------------------------------------------

	local healthColor

	local healthColorMode = panel:CreateDropdown(L.HealthColor, L.HealthColor_Desc)
	healthColorMode:SetPoint("TOPLEFT", borderSize, "BOTTOMLEFT", 0, -12)
	healthColorMode:SetPoint("TOPRIGHT", borderSize, "BOTTOMRIGHT", 0, -12)
	
	healthColorMode:SetList({
		{ value = "CLASS",  text = L.ColorClass  },
		{ value = "HEALTH", text = L.ColorHealth },
		{ value = "CUSTOM", text = L.ColorCustom },
	})

	function healthColorMode:OnValueChanged(value, text)
		db.healthColorMode = value
		for i = 1, #ns.objects do
			local frame = ns.objects[i]
			local health = frame.Health
			if type(health) == "table" then
				health.colorClass = value == "CLASS"
				health.colorReaction = value == "CLASS"
				health.colorSmooth = value == "HEALTH"
				if value == "CUSTOM" then
					local mu = health.bg.multiplier
					local r, g, b = unpack(db.healthColor)
					health:SetStatusBarColor(r, g, b)
					health.bg:SetVertexColor(r * mu, g * mu, b * mu)
				elseif frame:IsShown() then
					health:ForceUpdate()
				end
			end
		end
		if value == "CUSTOM" then
			healthColor:Show()
		else
			healthColor:Hide()
		end
	end

	--------------------------------------------------------------------

	healthColor = panel:CreateColorPicker(L.HealthColorCustom)
	healthColor:SetPoint("LEFT", healthColorMode, "RIGHT", 24, -8)

	function healthColor:GetColor()
		return unpack(db.healthColor)
	end

	function healthColor:OnValueChanged(r, g, b)
		db.healthColor[1] = r
		db.healthColor[2] = g
		db.healthColor[3] = b
		for i = 1, #ns.objects do
			local hp = ns.objects[i].Health
			if type(hp) == "table" then
				local mu = hp.bg.multiplier
				hp:SetStatusBarColor(r, g, b)
				hp.bg:SetVertexColor(r * mu, g * mu, b * mu)
			end
		end
	end

	--------------------------------------------------------------------

	local healthBG = panel:CreateSlider(L.HealthBG, L.HealthBG_Desc, 0, 3, 0.05, true)
	healthBG:SetPoint("TOPLEFT", healthColorMode, "BOTTOMLEFT", 0, -12)
	healthBG:SetPoint("TOPRIGHT", healthColorMode, "BOTTOMRIGHT", 0, -12)

	function healthBG:OnValueChanged(value)
		db.healthBG = value
		local custom = db.healthColorMode == "CUSTOM"
		for i = 1, #ns.objects do
			local frame = ns.objects[i]
			local health = frame.Health
			if health then
				health.bg.multiplier = value
				if custom then
					local r, g, b = unpack(db.healthColor)
					health:SetStatusBarColor(r, g, b)
					health.bg:SetVertexColor(r * value, g * value, b * value)
				elseif frame:IsShown() then
					health:ForceUpdate(frame.unit)
				end
			end
		end
		return value
	end

	--------------------------------------------------------------------

	local powerColor

	local powerColorMode = panel:CreateDropdown(L.PowerColor, L.PowerColor_Desc)
	powerColorMode:SetPoint("TOPLEFT", healthBG, "BOTTOMLEFT", 0, -12)
	powerColorMode:SetPoint("TOPRIGHT", healthBG, "BOTTOMRIGHT", 0, -12)
	
	powerColorMode:SetList({
		{ value = "CLASS",  text = L.ColorClass  },
		{ value = "POWER",  text = L.ColorPower  },
		{ value = "CUSTOM", text = L.ColorCustom },
	})

	function powerColorMode:OnValueChanged(value, text)
		db.powerColorMode = value
		for i = 1, #ns.objects do
			local frame = ns.objects[i]
			local power = frame.Power
			if type(power) == "table" then
				power.colorClass = value == "CLASS"
				power.colorReaction = value == "CLASS"
				power.colorPower = value == "POWER"
				if value == "CUSTOM" then
					local mu = power.bg.multiplier
					local r, g, b = unpack(db.powerColor)
					power:SetStatusBarColor(r, g, b)
					power.bg:SetVertexColor(r * mu, g * mu, b * mu)
				elseif frame:IsShown() then
					power:ForceUpdate()
				end
			end
		end
		if value == "CUSTOM" then
			powerColor:Show()
		else
			powerColor:Hide()
		end
	end

	--------------------------------------------------------------------

	powerColor = panel:CreateColorPicker(L.PowerColorCustom)
	powerColor:SetPoint("LEFT", powerColorMode, "RIGHT", 24, -4)

	function powerColor:GetColor()
		return unpack(db.powerColor)
	end

	function powerColor:OnValueChanged(r, g, b)
		db.powerColor[1] = r
		db.powerColor[2] = g
		db.powerColor[3] = b
		for i = 1, #ns.objects do
			local frame = ns.objects[i]
			local power = frame.Power
			if type(power) == "table" then
				local mu = power.bg.multiplier
				power:SetStatusBarColor(r, g, b)
				power.bg:SetVertexColor(r * mu, g * mu, b * mu)
			end
		end
	end

	--------------------------------------------------------------------

	local powerBG = panel:CreateSlider(L.PowerBG, L.PowerBG_Desc, 0, 3, 0.05, true)
	powerBG:SetPoint("TOPLEFT", powerColorMode, "BOTTOMLEFT", 0, -12)
	powerBG:SetPoint("TOPRIGHT", powerColorMode, "BOTTOMRIGHT", 0, -12)

	function powerBG:OnValueChanged(value)
		db.powerBG = value
		local custom = db.powerColorMode == "CUSTOM"
		for i = 1, #ns.objects do
			local frame = ns.objects[i]
			local Power = frame.Power
			if Power then
				Power.bg.multiplier = value
				if custom then
					local r, g, b = unpack(db.powerColor)
					Power:SetStatusBarColor(r, g, b)
					Power.bg:SetVertexColor(r * value, g * value, b * value)
				elseif frame:IsShown() then
					Power:ForceUpdate()
				end
			end

			local DruidMana = frame.DruidMana
			if DruidMana then
				local r, g, b = unpack(dUF.colors.power.MANA)
				DruidMana.bg.multiplier = value
				DruidMana:ForceUpdate()
			end

			local Runes = frame.Runes
			if Runes then
				for i = 1, #Runes do
					local r, g, b = Runes[i]:GetStatusBarColor()
					Runes[i].bg:SetVertexColor(r * value, g * value, b * value)
					Runes[i].bg.multiplier = value
				end
			end

			local Totems = frame.Totems
			if Totems then
				for i = 1, #Totems do
					local r, g, b = unpack(dUF.colors.totems[SHAMAN_TOTEM_PRIORITIES[i]])
					Totems[i].bg:SetVertexColor(r * value, g * value, b * value)
					Totems[i].bg.multiplier = value
				end
			end
		end
		return value
	end

	--------------------------------------------------------------------

	function panel.okay() 
		if (ns.reload == true) then
			StaticPopup_Show("VISIHUD_RELOADUIWARNING")
			ns.reload = false
		end
	end

	function panel.refresh()
		statusbar:SetValue(db.statusbar)
		statusbar.valueBG:SetTexture(Media:Fetch("statusbar", db.statusbar))

		font:SetValue(db.font)
		outline:SetValue(db.fontOutline, outlineWeights[db.fontOutline])
		fontSize:SetValue(db.fontScale)
		shadow:SetValue(db.fontShadow)

		borderSize:SetValue(db.borderSize)
		borderColor:SetValue(unpack(db.borderColor))

		dispelFilter:SetChecked(db.dispelFilter)
		healFilter:SetChecked(db.ignoreOwnHeals)
		threatLevels:SetChecked(db.threatLevels)
		fastFocus:SetChecked(db.fastFocus)
		expandZoom:SetChecked(db.expandZoom)
		
		healthColorMode:SetValue(db.healthColorMode, healthColorModes[db.healthColorMode])
		healthColor:SetValue(unpack(db.healthColor))
		if db.healthColorMode == "CUSTOM" then
			healthColor:Show()
		else
			healthColor:Hide()
		end
		healthBG:SetValue(db.healthBG)

		powerColorMode:SetValue(db.powerColorMode, powerColorModes[db.powerColorMode])
		powerColor:SetValue(unpack(db.powerColor))
		if db.powerColorMode == "CUSTOM" then
			powerColor:Show()
		else
			powerColor:Hide()
		end
		powerBG:SetValue(db.powerBG)

		for i = 1, #dUF.objects do
			dUF.objects[i]:UpdateAllElements("OptionsRefresh")
		end
	end
end)

------------------------------------------------------------------------

local LAP = LibStub("LibAboutPanel", true)
if LAP then
	LAP.new("VisiHUD", "VisiHUD")
end

_G.StaticPopupDialogs["VISIHUD_RELOADUIWARNING"] = {
	text = L['ReloadUIWarning_Desc'],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = ReloadUI,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}