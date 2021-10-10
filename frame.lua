--create addonHandler and add some utility features
local AddonName, Addon = ...
local Questra = _G.LibStub("AceAddon-3.0"):NewAddon(Addon, AddonName, 'AceEvent-3.0', 'AceConsole-3.0')
Questra.callbacks = LibStub('CallbackHandler-1.0'):New(Questra)
--Questra.localize = LibStub('AceLocale-3.0'):GetLocale(AddonName)
Questra.FlyPaper = LibStub('LibFlyPaper-2.0')
Questra.CTL = assert(ChatThrottleLib, "Quest_Compass requires ChatThrottleLib.")

Questra.offset = 1

local HBD = LibStub:GetLibrary("HereBeDragons-2.0", true)

local prin = print
local lastPrint
local function print(...)
	local p  = {...}
	local isRepeatPrint
	local newPrint = strjoin(", ", unpack(p))
	if lastPrint ~= newPrint then
		lastPrint = newPrint
		prin(...)
	end
end

--Background strata for baseFrame
--Medium strata for dragFrame
--Low Strata for all other UI Elements

local events

local canAutoTrack

local sandCastle --Not yet ready
do
-- sandCastle = LibStub("AceAddon-3.0"):GetAddon("sandCastle")
-- if not sandCastle then return end

-- local AddonName, sandCastle_Log = ...

-- function sandCastle_Log:IsEnabled()
	-- -- if self.sets.disabled == true then
		-- -- self:Hide()
	-- -- else
		-- -- self:Show()
	-- -- end
	
	-- self:SetShown(not self.sets.disabled)
-- end

-- function sandCastle_Log:Layout()
	-- self:Rescale()
	-- self:IsEnabled()
-- end

-- function sandCastle_Log:Rescale(newScale)
	-- local scale = newScale or self.sets.scale or 1

	-- --self.frame:SetScale(1)

	-- sandCastle.FlyPaper.SetScale(self.frame, scale)
	
	-- if self.updateScale then
		-- self.updateScale(scale)
	-- end
	
	-- sandCastle.SaveFramePosition(self)
-- end

-- function sandCastle_Log.updateScale(scale)

-- end

end
local options = {
	{
		"Basics",
		{
			{
				"checkButton",
				"Disable",
				function(parent) --getter
					return parent.sets.disabled
				end,
				function(parent, value) --setter
					parent.sets.disabled = value
					parent:IsEnabled()
				end,
			},
			{
				"slider",
				"Scale",
				function(parent) --getter
					return (parent.sets.scale or 1) * 100
				end,
				function(parent, value, ...) --setter
					parent.sets.scale = value/100
					parent:Rescale()
				end,
				{25, 250, 1, 10, 100}, --min, max, step, stepOnShiftKeyDown
			},
		},
	},
	{
		"Advanced",
		{

		},
	},
}

local defaults = {
	position = {
		point = "Center",
		x = 0,
		y = -200
	},
	scale = 1,
	height = 250,
}

function Questra:OnEnable()
	local size = 65
	do--Creation
		do self.baseFrame = CreateFrame("Frame", "Quest_Compass_Base")
			self.baseFrame:SetFrameStrata("BACKGROUND")
			self.baseFrame:SetFixedFrameStrata(true)
			self.baseFrame:SetPoint("Center", 0, -150)
			self.baseFrame:SetSize(size, size)

			self.baseFrame.dragFrame = CreateFrame("Button", "Quest_Compass_dragFrame", self.baseFrame)
				self.baseFrame.dragFrame:SetFrameStrata("MEDIUM")
				self.baseFrame.dragFrame:SetFixedFrameStrata(true)
				self.baseFrame.dragFrame:SetAllPoints(self.baseFrame)
				self.baseFrame.dragFrame:Hide()

				self.baseFrame.dragFrame.texture = self.baseFrame.dragFrame:CreateTexture(nil, "OVERLAY")
				self.baseFrame.dragFrame.texture:SetColorTexture(0, 1, 0, .45)
				self.baseFrame.dragFrame.texture:SetAllPoints(self.baseFrame.dragFrame)
		end

		do self.navButton = CreateFrame("Button", "Quest_Compass_NavigationButton", self.baseFrame)
			local size = (66/70) * size
			self.navButton:SetSize(size, size)
			self.navButton:SetPoint("TOP", 0, 7)
			self.navButton:SetFrameStrata("LOW")
			self.navButton:SetFrameLevel(10)
			self.navButton:SetFixedFrameStrata(true)
			self.navButton:SetHitRectInsets(15, 15, 15, 15)
			
			self.navButton:SetNormalTexture("Interface\\AddOns\\"..AddonName.."\\artwork\\".."Eye\\green")
			self.navButton:SetPushedTexture("Interface\\AddOns\\"..AddonName.."\\artwork\\".."Eye\\green")
			
			self.navButton.bg = self.navButton:GetNormalTexture()
				self.navButton.bg:ClearAllPoints()
				self.navButton.bg:SetPoint("Center")
				self.navButton.bg:SetSize(40, 40)
			
			self.navButton.push = self.navButton:GetPushedTexture()
				self.navButton.push:SetAllPoints(self.navButton.bg)
			
			self.navButton.push:SetDrawLayer("BACKGROUND")
			self.navButton.bg:SetDrawLayer("BACKGROUND")
	
			self.navButton.icon = self.navButton:CreateTexture(nil, "LOW", 1)
				self.navButton.icon:SetPoint("Center", 1, 0)
				self.navButton.icon:SetSize(35, 35)
				
			self.navButton.border = self.navButton:CreateTexture(nil, "LOW", 3)
				self.navButton.border:SetAllPoints(self.navButton)
				self.navButton.border:SetAtlas("auctionhouse-itemicon-border-white")

			self.navButton.hl = self.navButton:CreateTexture(nil, "LOW", 1)
				self.navButton.hl:SetPoint("Center")
				self.navButton.hl:SetSize((60/90) * size,(60/90) * size)
				self.navButton.hl:Hide()
				
				self.navButton.hl:SetTexture(166862)
			
			self.navButton.arrow = self.navButton:CreateTexture(nil, "OVERLAY", 25)
				self.navButton.arrow:SetAllPoints(self.navButton)
				self.navButton.arrow:SetTexture("Interface\\AddOns\\"..AddonName.."\\artwork\\".."RingArrow")
		end
		
		do  self.coordText = CreateFrame("EditBox", "Quest_Compass_coordText", self.baseFrame, "InputBoxScriptTemplate")
			self.coordText:SetSize((52/70) * size, 10)
			self.coordText:SetHighlightColor(.5,1,.5)
			self.coordText:SetClampedToScreen(true)
			self.coordText:SetJustifyH("CENTER")
			self.coordText:SetAutoFocus(false)
			self.coordText:SetPoint("Bottom", 0, 1)
			self.coordText:SetMovable(true)
			
			self.coordText:SetFrameStrata("LOW")
			self.coordText:SetFrameLevel(10)
			self.coordText:SetFixedFrameStrata(true)
			
			self.coordText:SetFontObject("GameFontNormal")
			local path = self.coordText:GetFont() -- Return the font path, height, and flags that may be used to construct an identical Font object.
			self.coordText:SetFont(path,7) --don't want to change font, just size.
			self.coordText:SetTextColor(1,1,1,1)

			self.coordText.button = CreateFrame("Button", nil, self.coordText)
				self.coordText.button:SetAllPoints(self.coordText)
				self.coordText.button:RegisterForClicks("AnyUp")
				self.coordText.button:SetScript("OnClick", function() self.coordText:SetFocus() end)

				local BORDER_THICKNESS = 1
				local r, g, b, a = 142/255,105/255,0, 1

				self.coordText.button.borderTop = self.coordText.button:CreateTexture(nil, 'HIGHLIGHT', 2)
					self.coordText.button.borderTop:SetColorTexture(r, g, b, a)
					self.coordText.button.borderTop:SetPoint("TOPLEFT", self.coordText.button, -BORDER_THICKNESS, BORDER_THICKNESS)
					self.coordText.button.borderTop:SetPoint("TOPRIGHT", self.coordText.button,  BORDER_THICKNESS, BORDER_THICKNESS)
					self.coordText.button.borderTop:SetHeight(BORDER_THICKNESS)

				self.coordText.button.borderBottom = self.coordText.button:CreateTexture(nil, 'HIGHLIGHT', 2)
					self.coordText.button.borderBottom:SetColorTexture(r, g, b, a)
					self.coordText.button.borderBottom:SetPoint("BOTTOMLEFT", self.coordText.button, -BORDER_THICKNESS, -BORDER_THICKNESS)
					self.coordText.button.borderBottom:SetPoint("BOTTOMRIGHT", self.coordText.button, BORDER_THICKNESS, -BORDER_THICKNESS)
					self.coordText.button.borderBottom:SetHeight(BORDER_THICKNESS)

				self.coordText.button.borderLeft = self.coordText.button:CreateTexture(nil, 'HIGHLIGHT', 2)
					self.coordText.button.borderLeft:SetColorTexture(r, g, b, a)
					self.coordText.button.borderLeft:SetPoint("TOPLEFT", self.coordText.button.borderTop)
					self.coordText.button.borderLeft:SetPoint("BOTTOMLEFT", self.coordText.button.borderBottom)
					self.coordText.button.borderLeft:SetWidth(BORDER_THICKNESS)

				self.coordText.button.borderRight = self.coordText.button:CreateTexture(nil, 'HIGHLIGHT', 2)
					self.coordText.button.borderRight:SetColorTexture(r, g, b, a)
					self.coordText.button.borderRight:SetPoint("TOPRIGHT", self.coordText.button.borderTop)
					self.coordText.button.borderRight:SetPoint("BOTTOMRIGHT", self.coordText.button.borderBottom)
					self.coordText.button.borderRight:SetWidth(BORDER_THICKNESS)

			    self.coordText.bg = self.coordText:CreateTexture(nil, 'BACKGROUND', 1)
					self.coordText.bg:SetPoint('TOPLEFT')
					self.coordText.bg:SetPoint('BOTTOMRIGHT')
					self.coordText.bg:SetColorTexture(0,0,0, .65)

				local r, g, b, a = 102/255,65/255,0, 1

				self.coordText.borderTop = self.coordText:CreateTexture(nil, 'OVERLAY', 2)
					self.coordText.borderTop:SetColorTexture(r, g, b, a)
					self.coordText.borderTop:SetPoint("TOPLEFT", self.coordText.bg, -BORDER_THICKNESS, BORDER_THICKNESS)
					self.coordText.borderTop:SetPoint("TOPRIGHT", self.coordText.bg,  BORDER_THICKNESS, BORDER_THICKNESS)
					self.coordText.borderTop:SetHeight(BORDER_THICKNESS)

				self.coordText.borderBottom = self.coordText:CreateTexture(nil, 'OVERLAY', 2)
					self.coordText.borderBottom:SetColorTexture(r, g, b, a)
					self.coordText.borderBottom:SetPoint("BOTTOMLEFT", self.coordText.bg, -BORDER_THICKNESS, -BORDER_THICKNESS)
					self.coordText.borderBottom:SetPoint("BOTTOMRIGHT", self.coordText.bg, BORDER_THICKNESS, -BORDER_THICKNESS)
					self.coordText.borderBottom:SetHeight(BORDER_THICKNESS)

				self.coordText.borderLeft = self.coordText:CreateTexture(nil, 'OVERLAY', 2)
					self.coordText.borderLeft:SetColorTexture(r, g, b, a)
					self.coordText.borderLeft:SetPoint("TOPLEFT", self.coordText.borderTop)
					self.coordText.borderLeft:SetPoint("BOTTOMLEFT", self.coordText.borderBottom)
					self.coordText.borderLeft:SetWidth(BORDER_THICKNESS)

				self.coordText.borderRight = self.coordText:CreateTexture(nil, 'OVERLAY', 2)
					self.coordText.borderRight:SetColorTexture(r, g, b, a)
					self.coordText.borderRight:SetPoint("TOPRIGHT", self.coordText.borderTop)
					self.coordText.borderRight:SetPoint("BOTTOMRIGHT", self.coordText.borderBottom)
					self.coordText.borderRight:SetWidth(BORDER_THICKNESS)
		end

		do--Set temp anchor Waypoint if you want to leave and then return to same spot, quickly.
			self.anchorButton = CreateFrame("Button", "Quest_Compass_SaveAnchorButton", self.baseFrame)
			self.anchorButton:SetSize(6.5, 10)
			self.anchorButton:SetPoint("BottomLeft", 1, 1)
			
			self.anchorButton:SetFrameStrata("LOW")
			self.anchorButton:SetFrameLevel(1)
			self.anchorButton:SetFixedFrameStrata(true)
			
			self.anchorButton:SetHighlightTexture("Interface\\AddOns\\"..AddonName.."\\artwork\\".."LeftArrow-Highlight")
			self.anchorButton:SetPushedTexture("Interface\\AddOns\\"..AddonName.."\\artwork\\".."LeftArrow-Pushed")
			self.anchorButton:SetNormalTexture("Interface\\AddOns\\"..AddonName.."\\artwork\\".."LeftArrow")
			--self.anchorButton:GetHighlightTexture():SetBlendMode("ADD")
			self.anchorButton:RegisterForClicks("AnyUp")
			
			self.anchorButton:GetNormalTexture():SetVertexColor(202/255,165/255,0, 1)
			self.anchorButton:GetPushedTexture():SetVertexColor(202/255,165/255,0, 1)
			self.anchorButton:GetHighlightTexture():SetVertexColor(202/255,165/255,0, 1)
		end		
		
		do--save button: save location onto world map as a permanent node for easier repeated return.
			self.saveButton = CreateFrame("Button", "Quest_Compass_SaveButton", self.baseFrame)
			self.saveButton:SetSize(6.5, 10)
			self.saveButton:SetPoint("BottomRight", -1, 1)
			
			self.saveButton:SetFrameStrata("LOW")
			self.saveButton:SetFrameLevel(1)
			self.saveButton:SetFixedFrameStrata(true)
			
			self.saveButton:SetHighlightTexture("Interface\\AddOns\\"..AddonName.."\\artwork\\".."LeftArrow-Highlight")
			self.saveButton:SetPushedTexture("Interface\\AddOns\\"..AddonName.."\\artwork\\".."LeftArrow-Pushed")
			self.saveButton:SetNormalTexture("Interface\\AddOns\\"..AddonName.."\\artwork\\".."LeftArrow")
			self.saveButton:GetHighlightTexture():SetTexCoord(1,0,0,1)
			self.saveButton:GetHighlightTexture():SetBlendMode("ADD")
			self.saveButton:GetNormalTexture():SetTexCoord(1,0,0,1)
			self.saveButton:GetPushedTexture():SetTexCoord(1,0,0,1)

			self.saveButton:GetNormalTexture():SetVertexColor(202/255,165/255,0, 1)
			self.saveButton:GetPushedTexture():SetVertexColor(202/255,165/255,0, 1)
			self.saveButton:GetHighlightTexture():SetVertexColor(202/255,165/255,0, 1)
		end
	
		do --Link tracking to chat
			self.Scroller = CreateFrame("Button", "Quest_Compass_notifyButton", self.baseFrame)
			self.Scroller:SetPoint("TopLeft", self.navButton, "BottomLeft", 0 , 16)
			self.Scroller:SetPoint("BottomRight", self.navButton, -0, 1)
			
			self.Scroller:SetHighlightTexture("Interface\\AddOns\\"..AddonName.."\\artwork\\".."NotifyBridgeHighlight")
			self.Scroller:SetPushedTexture("Interface\\AddOns\\"..AddonName.."\\artwork\\".."NotifyBridgeBackGround")
			self.Scroller:SetNormalTexture("Interface\\AddOns\\"..AddonName.."\\artwork\\".."NotifyBridgeBackGround")
			self.Scroller:SetHitRectInsets(15, 15, 0, 0)
			
			self.Scroller:SetFrameStrata("LOW")
			self.Scroller:SetFrameLevel(1)
			self.Scroller:SetFixedFrameStrata(true)
			
			self.Scroller.border = self.Scroller:CreateTexture(nil, "LOW")
			self.Scroller.border:SetAllPoints(self.Scroller)
			self.Scroller.border:SetTexture("Interface\\AddOns\\"..AddonName.."\\artwork\\".."NotifyBridgeBorder")
		end
		
		do--shortcut item button for quests that require them.
			self.itemButton = CreateFrame("Button", AddonName.."_ItemButton", self.baseFrame, "Quest_CompassItemButtonTemplate")

			self.itemButton:EnableMouse(true)
			self.itemButton:SetFrameStrata("BACKGROUND")
			self.itemButton.Cooldown:SetAllPoints(self.itemButton.icon)
			self.itemButton:SetPoint("Right", self.navButton, "Right", 7, -20)
		end
		
		do--distance text
			self.distanceText = self.Scroller:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
			self.distanceText:SetPoint("Bottom", 0, .5)
			
			local path = self.distanceText:GetFont() -- Return the font path, height, and flags that may be used to construct an identical Font object.
			self.distanceText:SetFont(path, 6) --don't want to change font, just size.
			self.distanceText:SetWordWrap(false)
			self.distanceText:SetText(" ")
			self.distanceText:SetWidth(35)
		end
		
		do--group button
			
		end

		do--map overlays
			self.MapOverlayContainer = CreateFrame("ScrollFrame", nil, WorldMapFrame.ScrollContainer)
			self.MapOverlayContainer:SetAllPoints(WorldMapFrame.ScrollContainer)
			self.MapOverlayContainer:SetFrameStrata("HIGH")
			self.MapOverlayContainer:SetFrameLevel(700)

			self.MapOverlayFrame = CreateFrame("Frame", nil, self.MapOverlayContainer)
			self.MapOverlayFrame:SetAllPoints(self.MapOverlayContainer)
			self.MapOverlayFrame:SetFrameStrata("HIGH")
			self.MapOverlayFrame:SetFrameLevel(700)
			self.MapOverlayFrame:EnableMouse(false)
			
			self.MapOverlayContainer:SetScrollChild(self.MapOverlayFrame)
			
			self.waypointsFrame = CreateFrame("Frame", nil, self.MapOverlayFrame)
			self.waypointsFrame:SetAllPoints(self.MapOverlayFrame)
			self.waypointsFrame:SetFrameStrata("HIGH")
			self.waypointsFrame:SetFrameLevel(700)

			self.waypointLocationHandler = CreateFrame("Frame", nil, UIParent)
			self.playerLocationHandler = CreateFrame("Frame", nil, UIParent)

			self.waypointLine = self.MapOverlayFrame:CreateLine(nil, "ARTWORK")
			self.waypointLine:SetColorTexture(1,1,1,1)
			self.waypointLine:SetThickness(9)

			self.waypointMarker = self.MapOverlayFrame:CreateTexture(nil, "HIGH")
			--self.waypointMarker:SetTexture("Interface\\BUTTONS\\UI-StopButton")
			self.waypointMarker:SetSize(25, 25)
		end
	
		do--tracking quantity
			self.qtyText = self.navButton:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
			self.qtyText:SetPoint("BottomRight", self.navButton, "Top", 0, -5)
			
			local path = self.qtyText:GetFont() -- Return the font path, height, and flags that may be used to construct an identical Font object.
			self.qtyText:SetFont(path, 6) --don't want to change font, just size.
			self.qtyText:SetWordWrap(false)
			self.qtyText:SetText(" ")
			self.qtyText:SetJustifyH("RIGHT")
			--self.qtyText:SetWidth(35)
		
		end
	end

	do  --Scripts
		self.baseFrame:SetScript("OnEnter", Questra.BaseOnEnter)
		self.baseFrame:SetScript("OnLeave", Questra.BaseOnLeave)

		self.baseFrame.dragFrame:SetScript("OnMouseDown", Questra.DragOnMouseDown)
		self.baseFrame.dragFrame:SetScript("OnMouseUp"  , Questra.DragOnMouseUp)
		self.baseFrame.dragFrame:SetScript("OnLeave"    , Questra.DragOnLeave)
		
		self.navButton:SetScript("OnMouseWheel", Questra.ScrollMetricIndex)		
		self.navButton:SetScript("OnMouseDown" , Questra.NavOnMouseDown)
		self.navButton:SetScript("OnMouseUp"   , Questra.NavOnMouseUp)		
		self.navButton:SetScript("OnEnter"     , Questra.NavOnEnter)
		self.navButton:SetScript("OnLeave"     , Questra.NavOnLeave)

		self.coordText:SetScript("OnEditFocusLost", function() self.coordText.hasFocus = nil self.coordText:HighlightText(0,0) end)
		self.coordText:SetScript("OnEditFocusGained", function() self.coordText.hasFocus = true self.coordText:SetText("") end)
		self.coordText:SetScript("OnEscapePressed", function() self.coordText:ClearFocus() end)
		self.coordText:SetScript("OnEnterPressed",	function() self:OnEnterPressed(self.coordText:GetText()) end)
		
		self.Scroller:SetScript("OnMouseWheel", Questra.ScrollTracking)		
		
		self.anchorButton:SetScript("OnMouseUp", Questra.AnchorOnMouseUp)
		
		self.saveButton:SetScript("OnMouseUp", Questra.SaveOnMouseUp)

		self.itemButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetItemByID(self:GetID())
			Questra:ShowItemButton(self:GetID()) --update on enter, in case combat has ended
		end)

		self.itemButton:SetScript("OnUpdate", function(self)
			if self:IsVisible() and self:GetID() then
				local start, duration, enable = GetItemCooldown(self:GetID())
				if ( start ) then
					CooldownFrame_Set(self.Cooldown, start, duration, enable)
					if ( duration > 0 and enable == 0 ) then
						SetItemButtonTextureVertexColor(self, 0.4, 0.4, 0.4)
					else
						SetItemButtonTextureVertexColor(self, 1, 1, 1)
					end
				end
			end
		end)

		self.itemButton:SetScript("OnMouseWheel", function(self, delta)
			self.scroll = self.scroll and self.scroll + delta or 1
			Questra:ShowItemButton()
		end)

		self.itemButton:HookScript("OnMouseUp", function()
			self.itemButton.textureHandler:SetSize(25,25)
			self.itemButton.icon:SetSize(15,15)
			self.itemButton.textureHandler:SetPoint("Center", self.itemButton)
		end)

		self.itemButton:HookScript("OnMouseDown", function()
			self.itemButton.textureHandler:SetSize(23, 17)
			self.itemButton.icon:SetSize(23, 7)
			self.itemButton.textureHandler:SetPoint("Center", self.itemButton, 0, -3)
		end)

		self.baseFrame:SetScript("OnUpdate", function()
		
			self:Update()
			
			if GameTooltip:IsShown() and (GameTooltip:GetOwner() == Questra.navButton) and MouseIsOver(Questra.navButton) then
				Questra.NavOnEnter(Questra.navButton)
			end
		end)

		for i, b in pairs(Questra.Events) do
			self.baseFrame:RegisterEvent(b)
		end

		local runnin
		 self.baseFrame:SetScript("OnEvent", function(_, event, ...)
			if not runnin then
				runnin = true
				Questra:UpdateAutoTracking(event)
				runnin = nil
			end
		 end)
		Questra:ScrollMetricIndex(0)
		self:Update()
	end

	Questra:HookMapPins()

	--Questra:GetOrCreatePortalDataCollector()
		
	if sandCastle then --not yet ready
		-- local frames = {Quest_Compass_Base}
		-- sandCastle.New(function()
			-- local testFrame = CreateFrame("Frame", "Quest_Compass_BaseContain", sandCastle.frame)
					
			-- Quest_Compass_Base:SetParent(testFrame)
			-- testFrame:SetSize(Quest_Compass_Base:GetSize())
			-- Quest_Compass_Base:SetAllPoints(testFrame)
			
			-- testFrame.displayID = "log"

			 

			-- sandCastle:Register("sandCastle", testFrame, sandCastle_Log, defaults, options)
			
			-- testFrame:Layout()
		-- end)
	end
end

local portalDataCollector --Quick tool for collecting new portal data in the required format. So much faster this way!
function Questra:GetOrCreatePortalDataCollector()
	if not portalDataCollector then
		local panel = CreateFrame("Frame", "PortalDataCollector", UIParent, "BackdropTemplate")
		panel:SetSize(300, 200)
		panel:SetPoint("Center", UIParent)
		
		panel:EnableMouse(true)
		panel:SetScript("OnMouseDown", function()
			panel:SetMovable(true)
			panel:StartMoving()
		end)
		panel:SetScript("OnMouseUP", function()
			panel:StopMovingOrSizing()
			panel:SetMovable(false)
		end)
		
		panel:SetFrameStrata("Low")
		panel:SetFrameLevel(1)

		panel:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = true,
			tileEdge = true,
			tileSize = 32,
			edgeSize = 16,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		})

		panel:SetBackdropColor(0,0,0)

		panel.Set = CreateFrame("Button", panel:GetName().."Set", panel, "UIMenuButtonStretchTemplate")

		panel.Set:SetSize(125, 25)
		panel.Set:SetPoint("TopLeft", 5, -5)
	
		panel.Set:SetText("Set Origin")
	
		panel.Clear = CreateFrame("Button", panel:GetName().."ClearButton", panel, "UIMenuButtonStretchTemplate")
		panel.Clear:SetText("Clear")
		panel.Clear:SetSize(125, 25)
		panel.Clear:SetPoint("TopLeft", panel.Set, "TopRight", 5, 0)
		local t = CreateFrame("EditBox", "PortalDataCollectorDisplay", panel, "InputBoxScriptTemplate")
		t:SetAutoFocus(false)
		t:SetPoint("TopLeft", 5 , -30)
		t:SetPoint("BottomRight", -5, 5)
		t:SetHighlightColor(.5,1,.5)
		t:SetClampedToScreen(true)
		t:SetJustifyH("LEFT")
		t:SetJustifyV("BOTTOM")
		t:SetAutoFocus(false)
		t:SetMovable(true)
		t:SetMultiLine(true)
		t:SetFrameStrata("LOW")
		t:SetFrameLevel(10)
		t:SetFixedFrameStrata(true)
		t:SetFontObject("GameFontNormal")

		t:SetScript("OnKeyDown", function(_, key)
			if key == "DELETE" then
				ReloadUI()
			end
		end)

		panel.Clear:SetScript("OnClick" , function() t:SetText("") end)

		local o = ""
		local d = "{}"
		

		
		panel.Set:SetScript("OnClick", function()
			local x, y, id = Questra.GetPlayerPosition()
			
			if o == "" then
				o = [[tooltip = "",
            origin = {
                x = ]]..x..[[,
                y = ]]..y..[[,
                mapID = ]]..id..[[,
            }]]
				d = "{}"
				panel.Set:SetText("Set Destination")
			else
				d = [[{
                x = ]]..x..[[,
                y = ]]..y..[[,
                mapID = ]]..id..[[,
            }]]
				panel.Set:SetText("Set Origin")
			end

			local text = [[{
            ]]..o..[[,
            destination = ]]..d..[[ 
        },]]


			t:SetText(text)
			if o ~= "" and d ~= "{}" then
				o, d = "", "{}"
			end
		end)

		panel.close = CreateFrame("Button", panel:GetName().."Close", panel, "UIPanelCloseButton")
		panel.close:SetPoint("TopRight")
		
		portalDataCollector = t
	end
	return portalDataCollector
end

do --group button
	local oldold = C_LFGList.CanCreateQuestGroup
	local function CanCreateQuestGroup(questID, ...)
		local o = oldold(questID, ...)
		if o then
			return o
		end
							local info = questID and C_QuestLog.GetQuestTagInfo(questID)
						-- .quality
						-- .isElite
						-- .worldQuestType
						-- .tagID
						-- .displayExpiration
						-- .tagName

					local tagID, worldQuestType, rarity, displayTimeLeft, isElite, tagName = info and info.tagID, info and info.worldQuestType, info and info.quality, info and info.displayExpiration, info and info.isElite, info and info.tagName

		if worldQuestType == 6 then
			return true, true
		end
	end

	local op = {
		Left = "Right",
		Right = "Left",
		Bottom = "Top",
		Top = "Bottom",
	}

	local categories = {}
	local function GetQueueInfo(index)
		local lfgDungeonIDs = C_LFGInfo.GetAllEntriesForCategory(LE_LFG_CATEGORY_LFD)

		local total = 0
		for i = 1, 7 do
			local ids = C_LFGInfo.GetAllEntriesForCategory(i)
			categories[i] = categories[i] or {}
			wipe(categories[i])
			tinsert(categories[i], ids)
			total = total + #ids
		end

		return id and categories[id] or categories, id and #categories[id] or total
	end

	local function QuickJoinToastMixin_OnEnter(button, questID, queued)
		if not questID then
			return --print(button, questID)
		end
		local canMake = C_LFGList.CanCreateQuestGroup(questID)

		--local ids, numIDs = GetQueueInfo(index)

		local looking = queued

		if  looking or canMake and looking then
			QueueStatusMinimapButton:GetScript("OnEnter")(button)

			local x, y = button:GetCenter()
			local w, h = UIParent:GetSize()
			local half_w, half_h = w/2, h/2
			local ver, hor = "Bottom", "Left"

			if not (y and x and half_h and half_w) then return end

			if y >= half_h then
				ver = "Top"
			end
			if x >= half_w then
				hor = "Right"
			end
			QueueStatusFrame:ClearAllPoints()
			QueueStatusFrame:SetPoint(ver..hor, button, op[ver]..op[hor])

			local eScale = QueueStatusFrame:GetEffectiveScale()
			if eScale ~= 1 then
				local scale = 1
				button.scale = scale  -- Saved in case it needs to be re-calculated when the parent's scale changes.
				local parent = QueueStatusFrame:GetParent()
				if ( parent ) then
					scale = scale / parent:GetEffectiveScale()
				end
				QueueStatusFrame:SetScale(scale)
			end
			QueueStatusFrame:SetFrameStrata("TOOLTIP")
			QueueStatusFrame:SetFrameLevel(100)
		else
			GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
			GameTooltip:SetText(button.tooltip or "")
			GameTooltip:AddLine(button.tooltip2 or "")
			GameTooltip:Show()
		end
	end

	local function GetInstanceIDByName(zoneID, name)
		local dungeonEntrances = C_EncounterJournal.GetDungeonEntrancesForMap(zoneID)
		for i, b in pairs(dungeonEntrances) do
			if b.name == name then
				return b.journalInstanceID
			end
		end
	end


	--let's make the LFG eye look around and blink at random!
	local actionStep = 8

	local updateInterval = 1/8 --fraction of a second: think Frame Per Second

	local function secs()
		return GetTimePreciseSec()
	end
	local cTime = secs()
	local lastElapsed = -updateInterval

	local lastAction

	local active = 1
	local actions = {
		{count = 0, repeatCount = 0, maxRepeat = 6, sequenceLength = 8, uppercount = 0, lowercount = 0}, 
		{count = 0, repeatCount = 0, maxRepeat = 3, sequenceLength = 9},
		{count = 0, repeatCount = 0, maxRepeat = 2, sequenceLength = 3},
		{count = 0, repeatCount = 0, maxRepeat = 1, sequenceLength = 32, uppercount = 0, lowercount = 0}}

	local coords = {
		x = { --x
			current = 0,
			movement = 1,
			range = 20,
			returnRate = 0
		},
		y = {--y
			current = 0,
			movement = 1,
			range = 20,
			returnRate = 0
		},
	}

	local xRange = (coords.x.range / actions[1].sequenceLength) * 10
	local yRange = (coords.y.range / actions[1].sequenceLength) * 10

	local lastUpdate

	local function Update(index)
		local action = actions[index]
		if action.repeatCount > action.maxRepeat then
			action.repeatCount = 0
			actionStep = 0
			lastUpdate = nil
			return action.repeatReset()
		elseif (actionStep > action.sequenceLength ) or (lastAction == index) then --ether it's finishing, or it's the last action to have happened.
			action.repeatCount = action.repeatCount + 1
			actionStep = 0
			lastUpdate = nil
			return action.reset()
		else
			if lastUpdate ~= index then
				--reset me
				action.count = 0
				action.repeatCount = 0
			end
			lastUpdate = index
			action.count = action.count > action.sequenceLength and 1 or action.count + 1
			return action.update()
		end
	end

	local nextAction


	local look = actions[1]
	do
		local lastStep = 0
		look.update = function()

			-- if actionStep >= lastStep + 4 then
				-- lastStep = actionStep
				-- coords.x.movement = random(-xRange, xRange)/10
				-- coords.y.movement = random(-yRange, yRange)/10
			-- end
		
			coords.x.current = math.min(coords.x.range, math.max(-coords.x.range, (coords.x.current + coords.x.movement) ))
			coords.y.current = math.min(coords.y.range, math.max(-coords.y.range, (coords.y.current + coords.y.movement) ))
		end

		look.reset = function()
			lastStep = 0
			actionStep = 0
			lastAction = 1
			active = (random(1, 2) == 2) and 3 or 1
			if active == 1 then
				lastAction = 3
				coords.x.movement = random(-xRange, xRange)/10
				coords.y.movement = random(-yRange, yRange)/10
			end
			
			coords.x.returnRate = coords.x.current/5
			coords.y.returnRate = coords.y.current/5
			look.uppercount, look.lowerCount = 1, 1

			return  Update(active)
		end

		look.repeatReset = function()
			lastStep = 0
			lastAction = 1
			active = 3
			actionStep = 0
			look.count = 0
			look.uppercount, look.lowerCount = 1, 1
			return  Update(3)
		end
	end

	local blink = actions[2]
	do
		blink.update = function()

			coords.x.current = 0
			coords.y.current = 0
			return "Blinking"
		end

		blink.reset = function(skip)
			blink.count = 0
			active = random(1, 2)
			actionStep = 0
			lastAction = 2
			if active == 1 then
				coords.x.movement = random(-xRange, xRange)/10
				coords.y.movement = random(-yRange, yRange)/10
			end
			return  not skip and Update(active)
		end

		blink.repeatReset = function()
			lastAction = 2
			active = 1
			blink.count = 0
			return Update(1)
		end
		blink.reset()
	end

	local center = actions[3]
	do
		center.update = function()
			coords.x.current = coords.x.current - (coords.x.returnRate)
			coords.y.current = coords.y.current - (coords.y.returnRate)
			return "Centering"
		end

		center.reset = function()
			lastAction = 3
			actionStep = 0
			coords.x.movement = random(-xRange, xRange)/10
			coords.y.movement = random(-yRange, yRange)/10

			active = random(1,3)
			if active == 3 then
				lastAction = nil
				coords.x.movement = 0
				coords.y.movement = 0
			end
			return  Update(active)
		end

		center.repeatReset = function()	
			
			lastAction = 3
			actionStep = 0
			coords.x.movement = random(-xRange, xRange)/10
			coords.y.movement = random(-yRange, yRange)/10
			active = random(1,2)
			return  Update(active)
		end
	end

	local swirl = actions[4]
	do
		swirl.update = function()
				coords.x.current = 0
				coords.y.current = 0
				
				blink.count = 1
				coords.rotate = coords.rotate or {degree = 0}
				coords.rotate.degree = coords.rotate.degree + 360/(33) --1.5 "spins" before stopping
				
				return "Swirling"
		end

		swirl.reset = function(skip)
			
			return  swirl.update()
		end

		swirl.repeatReset = function()	
			blink.count = 0
			lastAction = 4
			actionStep = 0
			coords.x.movement = 0
			coords.y.movement = 0
			coords.rotate = nil
			active = 2
			return  Update(active)
		end
	end

	local mouseIsOver
	local function watchCursor(self, justCenter)
		local focus = GetMouseFocus()
	
		local focus = focus ~= Questra.baseFrame and DoesAncestryInclude(Questra.baseFrame, focus) == true or nil
	
		local curX, curY = GetCursorPosition()
	
		if active ~= 4 and focus then
			local sX, sY, w, h = self:GetScaledRect()
			sX = sX + (w/2)
			sY = sY + (h/2)
			local s = self:GetScale()
			coords.x.current = -(1 + curX - sX)
			coords.y.current = (curY - sY)
			mouseIsOver = true
			look.count = 0
			blink.count = 0
			center.count = 0
			return true
		elseif  mouseIsOver == true then
			mouseIsOver = nil
			lastAction = nil
			actionStep = 0
			coords.x.movement = random(-xRange, xRange)
			coords.y.movement = random(-yRange, yRange)
			reset = true
			active = 3--random(1,3)
			return Update(active)
		end

	end

	local update = 0
	local function AnimateTexCoords(self)
		local texture = self.texture
		local _time = secs()
		local seconds = _time - cTime
		if seconds - lastElapsed  <= updateInterval then return end
		lastElapsed = seconds
		
		update = update < actionStep and update + 1 or 1
		--only update if enough time has passed
		if update < 1 then return else update = 0 end 

		local self = texture:GetParent()

		actionStep = actionStep + 1

		if watchCursor(self) ~= true then
			Update(active)
		end

		local distance = sqrt(coords.x.current^2 + coords.y.current^2, 2)

		local angle = (math.atan2(coords.y.current, coords.x.current))
		
		local maxX = coords.x.range * cos(angle)
		local maxY = coords.y.range * sin(deg(angle))
		maxX, maxY = math.abs(tostring(maxX) ~= "-nan(ind)" and maxX or 0), math.abs(tostring(maxY) ~= "-nan(ind)" and maxY or 0)
		
		coords.x.current = math.min(maxX, math.max(-maxX, coords.x.current))
		coords.y.current = math.min(maxY, math.max(-maxY, coords.y.current))

		local pX = coords.x.current / (100)
		local pY = coords.y.current / (100)

		local aX, bX, aY, bY = 0 + pX/1.4, 1 + pX/1.4, 0 + pY/2.3, 1 + pY/2.3
		local saX, sbX, saY, sbY = 0 + pX/4, 1 + pX/4, 0 + pY/4, 1 + pY/4

		local x, y = coords.x.current, coords.y.current
		
		local upperPercent, lowerPercent = 1, 1
		
		local percent =(y/coords.y.range)
		
		upperPercent = (percent <= 0) and math.floor((5 * math.abs(percent))+.25) or 1
		lowerPercent = (percent >= 0) and math.floor((5 * math.abs(percent))+.25) or 1

		self.pupil:SetTexCoord(aX, bX, aY, bY)
		local numApply = C_LFGList.GetNumPendingApplicantMembers()

		if self.isQueued then
			active = 4
			local radian = coords.rotate and rad(coords.rotate.degree) or rad(0)

			self.pupil:SetRotation(radian)
			texture = coords.rotate and "Interface\\AddOns\\"..AddonName.."\\artwork\\".."Eye\\pupilSwirl" or "Interface\\AddOns\\"..AddonName.."\\artwork\\".."Eye\\pupil"

			self.pupil:SetTexture(texture)
		else
			if active == 4 then
				swirl.reset(true)
			end
			self.pupil:SetRotation(rad(0))
		end
		
		self.shine:SetTexCoord(saX, sbX, saY, sbY)
		self.shine:SetVertexColor(1,1,1,.5)
		
		local up = (blink.count == 0) and ((upperPercent ~= 0 ) and upperPercent) or math.min(9, math.max(1, blink.count))
		local low = (blink.count == 0) and ((lowerPercent ~= 0 ) and lowerPercent) or math.min(9, math.max(1, blink.count))
		
		self.upper:SetTexture("Interface\\AddOns\\"..AddonName.."\\artwork\\".."Eye\\eyelids\\upper"..(up))
		self.lower:SetTexture("Interface\\AddOns\\"..AddonName.."\\artwork\\".."Eye\\eyelids\\lower"..(low))
		
		self.upper:SetVertexColor(255/255,215/255,0)
		self.lower:SetVertexColor(255/255,215/255,0)
		
		--self.green:SetVertexColor(0,1,0)
		local inGroup = IsInGroup()
		if inGroup then
			self.green:SetVertexColor(0, 1, 0, 1)
		else
			self.green:SetVertexColor(.3, .53, 1)
		end
	end

	local isAnim

	local function EyeTemplate_StartAnimating(eye)
		if not isAnim then
			isAnim = true
			eye:SetScript("OnUpdate", AnimateTexCoords)
		end
	end

	local function EyeTemplate_StartSpin(eye)
		if not isAnim then
			isAnim = true
			eye:SetScript("OnUpdate", function(...) actvie = 4 AnimateTexCoords(...) end)
		end
	end

	local function EyeTemplate_StopAnimating(eye)
		active = 3
		lastAction = nil
		actions[2].count = 0
		Update(active)
		isAnim = nil
		
		
		eye:SetScript("OnUpdate", function()
			if actions[3].count <= actions[3].sequenceLength then
		--coords.x.current = coords.x.current - (coords.x.returnRate)
				--coords.y.current = coords.y.current - (coords.y.returnRate)
				Update(3)
				--return "Centering"
			else
				eye:SetScript("OnUpdate", nil)
			end
		end)
		eye.pupil:SetTexCoord(0,1, 0, 1)
		eye.pupil:SetRotation(rad(0))
		eye.shine:SetTexCoord(0,1, 0, 1)
		eye.pupil:SetTexture("Interface\\AddOns\\"..AddonName.."\\artwork\\".."Eye\\pupil")
		eye.upper:SetTexture("Interface\\AddOns\\"..AddonName.."\\artwork\\".."Eye\\eyelids\\upper"..1)
		eye.lower:SetTexture("Interface\\AddOns\\"..AddonName.."\\artwork\\".."Eye\\eyelids\\lower"..1)
		local inGroup = IsInGroup()
		if inGroup then
			eye.green:SetVertexColor(0/255, 255/255, 0/255, 1)
		else
			eye.green:SetVertexColor(255/255, 255/255, 255/255, 1)
		end
	end

	-- LFG
	local categories = {
		LE_LFG_CATEGORY_LFD,
		LE_LFG_CATEGORY_RF,
		LE_LFG_CATEGORY_SCENARIO,
		LE_LFG_CATEGORY_LFR,
		LE_LFG_CATEGORY_FLEXRAID,
		LE_LFG_CATEGORY_WORLDPVP,
		LE_LFG_CATEGORY_BATTLEFIELD,
	}

	local function shouldShowAndOrAnimate()
		local animateEye
		local showButton
		--Try each LFG type

		local isQueued

		for category=1, NUM_LE_LFG_CATEGORYS do
			local mode, submode = GetLFGMode(category)
		
			isQueued = (mode == "proposal") and true or isQueued

			if  mode and submode ~= "noteleport"  then
				showButton = true
				if ( mode == "queued" ) then
					animateEye = true
				end
			end
			local ids = C_LFGInfo.GetAllEntriesForCategory(category)
			for i, id in ipairs(ids) do
				local inParty, joined, queued, noPartialClear, achievements, lfgComment, slotCount, category,
				leader, tank, healer, dps = GetLFGInfoServer(category, id)
				if queued == true then
					showButton = true
					animateEye = true
				end
			end
		end

		--Try LFGList applications
		local apps = C_LFGList.GetApplications()
		for i=1, #apps do
			local _, appStatus = C_LFGList.GetApplicationInfo(apps[i])
			
			if ( appStatus == "applied" or appStatus == "invited" ) then
				showButton = true
				if ( appStatus == "applied" ) then
					animateEye = true
				end
			end
		end

		--Try all PvP queues
		for i=1, GetMaxBattlefieldID() do
			local status, mapName, teamSize, registeredMatch, suspend = GetBattlefieldStatus(i)
			if ( status and status ~= "none" ) then
				showButton = true
				if ( status == "queued" and not suspend ) then
					animateEye = true
				end
			end
		end

		--Try all World PvP queues
		for i=1, MAX_WORLD_PVP_QUEUES do
			local status, mapName, queueID = GetWorldPVPQueueStatus(i)
			if ( status and status ~= "none" ) then
				showButton = true
				if ( status == "queued" ) then
					animateEye = true
				end
			end
		end

		-- Try LFGList entries
		local isActive = C_LFGList.HasActiveEntryInfo()
		
		-- Try PvP Role Check
		local inProgress, _, _, _, _, isBattleground = GetLFGRoleUpdate()

		-- Try PvP Ready Check
		local readyCheckInProgress, readyCheckIsBattleground = GetLFGReadyCheckUpdate()
		
		-- Pet Battle PvP Queue
		local pbStatus = C_PetBattles.GetPVPMatchmakingInfo()
		
		if ( inProgress and isBattleground ) 
		or ( readyCheckInProgress and readyCheckIsBattleground )
		or ( CanHearthAndResurrectFromArea() )
		or (isActive) 
		or (pbStatus) then
			showButton = true
		end

		if (pbStatus and ( pbStatus == "queued" )) or isActive then
			animateEye = true
		end

		return showButton, isQueued or animateEye,  isQueued
	end

	local accept
	local dungeonTitle = ""
	local _text = ""
	_G.StaticPopupDialogs.ConfirmDungeonEntry = {
		text = _text,
		button1 = OKAY,
		button2 = CANCEL,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		--hasEditBox = true,
		OnAccept = function(self, data)
			if accept then
				accept()
			end
		end,
		OnCancel = function(self, data)
			
		end,

		--enterClicksFirstButton = true,
		--OnCancel = function() show() end, -- Need to wrap it so we don't pass |self| as an error argument to show().
		preferredIndex = STATICPOPUP_NUMDIALOGS,
	}

	local function GetDisplayNameFromCategory(category)
		if (category == LE_LFG_CATEGORY_BATTLEFIELD) then
			local brawlInfo
			if (C_PvP.IsInBrawl()) then
				brawlInfo = C_PvP.GetActiveBrawlInfo()
			else
				brawlInfo = C_PvP.GetAvailableBrawlInfo()
			end
			if (brawlInfo and brawlInfo.canQueue and brawlInfo.name) then
				return brawlInfo.name
			end
		end

		if (category == LE_LFG_CATEGORY_SCENARIO) then
			local scenarioIDs = C_LFGInfo.GetAllEntriesForCategory(category)
			for i, scenID in ipairs(scenarioIDs) do
				if (not C_LFGInfo.HideNameFromUI(scenID)) then
					local instanceName = GetLFGDungeonInfo(scenID)
					if(instanceName) then
						return instanceName
					end
				end
			end
		end

		return LFG_CATEGORY_NAMES[category]
	end
	local on, off = {1,1,1,1}, {1,0,0,1}
	local canCreateGroup = {}
		
	local GetRelPos = function(self)
		local width, height = GetScreenWidth()/self:GetScale(), GetScreenHeight()/self:GetScale()
		local x, y = self:GetCenter()
		local xOffset, yOffset
		local Hori = (x > width/2) and 'RIGHT' or 'LEFT'
		if Hori == 'RIGHT' then
			xOffset = self:GetRight() - width
		else
			xOffset = self:GetLeft()
		end
		local Vert = (y > height/2) and 'TOP' or 'BOTTOM'
		if Vert == 'TOP' then
			yOffset = self:GetTop() - height
		else
			yOffset = self:GetBottom()
		end
		return Vert, Hori, xOffset, yOffset
	end

	local function SelectProperSide(self)
		local width = GetScreenWidth()

		local Vert, Hori, xOffset, yOffset = GetRelPos(self)
		local vert, hori

		if Vert == "TOP" then
			vert = "BOTTOM"
		elseif Vert == "BOTTOM" then
			vert = "TOP"
		end

		if Hori == "LEFT" then
			hori = "RIGHT"
		elseif Hori == "RIGHT" then
			hori = "LEFT"
		end

		return Vert..Hori, vert..hori
	end
	Questra.SelectProperSide = SelectProperSide

	local GB = {
		scripts = {
			OnClick = function(self, btn, ...)
				self.DropDown = self.DropDown or QueueStatusMinimapButton.DropDown
				if not InCombatLockdown() then
					local title =  C_TaskQuest.GetQuestInfoByQuestID(self.questID) or C_QuestLog.GetTitleForQuestID(self.questID) or nil

					local show, animate, isQueued = shouldShowAndOrAnimate()
					
					local lfgListActiveEntry = C_LFGList.HasActiveEntryInfo()
					
					if btn == "RightButton" then
						do
							local inBattlefield, showScoreboard = QueueStatus_InActiveBattlefield()
							if isQueued then
							--user is searching for group
							self.DropDown.id = self.questID
							QueueStatusDropDown_Show(self.DropDown, self:GetName())
							local p1, p2 = Questra.SelectProperSide(self)
							DropDownList1:ClearAllPoints()
							DropDownList1:SetPoint(p2, self, p1)
							return
							elseif (animate == true) then
							--user is searching for group

							elseif IsInLFDBattlefield() then
								inBattlefield = true
								showScoreboard = true
							end
							if ( inBattlefield )and showScoreboard then
								return TogglePVPScoreboardOrResults()
							else
								--See if we have any active LFGList applications
								local apps = C_LFGList.GetApplications()
								for i=1, #apps do
									local _, appStatus = C_LFGList.GetApplicationInfo(apps[i])
									if ( appStatus == "applied" or appStatus == "invited" ) then
										--We want to open to the LFGList screen
										LFGListUtil_OpenBestWindow(true)
										return
									end
								end
							end
							if IsInLFGDungeon() then
								self.DropDown.id = self.questID
								QueueStatusDropDown_Show(self.DropDown, self:GetName())
								local p1, p2 = Questra.SelectProperSide(self)
								DropDownList1:ClearAllPoints()
								DropDownList1:SetPoint(p2, self, p1)
								return
							end
							
							
							PVEFrame_ToggleFrame("GroupFinderFrame", "LFDParentFrame")
							return
						end
					elseif ( lfgListActiveEntry ) then
						return LFGListUtil_OpenBestWindow(true)
					else
						if isQueued then
							--group full, dungeon ready to enter
							LFGDungeonReadyPopup.closeIn = nil
							LFGDungeonReadyPopup:SetScript("OnUpdate", nil)
							LFGDungeonReadyStatus_ResetReadyStates()
							StaticPopupSpecial_Show(LFGDungeonReadyPopup)
							return
						elseif (animate == true) then
							--user is searching for group
							self.DropDown.id = self.questID
							QueueStatusDropDown_Show(self.DropDown, self:GetName())
							local p1, p2 = Questra.SelectProperSide(self)
							DropDownList1:ClearAllPoints()
							DropDownList1:SetPoint(p2, self, p1)
							return
						else
							local x,y, zoneID = Questra:GetQuestLocation(self.questID, true)
							local name = title and string.split(":", title)
							local dungeonID = GetInstanceIDByName(name, zoneID)
						
						
							if dungeonID then
								local isLocked = dungeonID and (GetLFGInviteRoleAvailability(dungeonID) == true) and "   You are already locked to "..name.."." or nil
								_G.StaticPopupDialogs.ConfirmDungeonEntry.text = isLocked or "Are you sure you want to queue for "..name.."?"
								accept = function()
									if dungeonID and isLocked == nil then
										LFDFrame_DisplayDungeonByID(dungeonID)
										PVEFrame_ShowFrame("GroupFinderFrame", LFDParentFrame)
										do--can i auto-queue? lets find out!
											local list = {}
											local count = 0
											local last
											for i = 1, NUM_LFD_CHOICE_BUTTONS do
												local button = _G["LFDQueueFrameSpecificListButton"..i]
												if GetLFGDungeonInfo(button.id) == name then
													count = count + 1
													if count == 2 and last then
														tremove(list, 1)
														LFGDungeonList_SetDungeonEnabled(last, false)
													end
													tinsert(list, button.id)
													LFGDungeonList_SetDungeonEnabled(button.id, true)
													last = button.id
												end
											end
											if #list > 0 then
												LFDQueueFrame_Join()
											end
											HideUIPanel(PVEFrame)
										end--i can auto-queue! i fully expect Blizzard to kill this one day.
									end
								end
								StaticPopup_Show("ConfirmDungeonEntry")
								return
							end
							
							if canCreateGroup[self.questID] == true then
								--This quest suggest a group, open the group finder page
								return QuestObjectiveFindGroup_OnClick(self)
							elseif LFGListUtil_GetQuestCategoryData(self.questID) then
								local isFromGreenEyeButton = true
								--print(LFGListFrame.SearchPanel.SearchBox:SetText(""))
								LFGListUtil_FindQuestGroup(self.questID, true)
								return
							end
						end
					
						PVEFrame_ToggleFrame("GroupFinderFrame", "LFDParentFrame")
					end
				end
			end,
			OnMouseDown = function(self)
				self:SetSize(30, 20)
				self:SetPoint("Left", self:GetParent(), "Left", -9.5, -22)
			end,
			OnMouseUp = function(self)
				self:SetSize(25, 25)
				self:SetPoint("Left", self:GetParent(), "Left", -7, -20)
			end,
			OnEnter = function(self)
				local show, animate = shouldShowAndOrAnimate()
				QuickJoinToastMixin_OnEnter(self, self.questID, show)
			end,
			OnLeave = function()
				GameTooltip:Hide()
				QueueStatusFrame:Hide()
			end,
		}
	}
	
	function GB:Create(parent)
		if not GB.Button then
			GB.Button = CreateFrame("Button", "Questra-GroupFinder", parent, "Q_C_GroupFinderButton")
			GB.Button:ClearAllPoints()
			GB.Button:SetFrameStrata("BACKGROUND")
			GB.Button:SetPoint("Left", parent, "Left", -7, -20)

			GB.Button:SetSize(25,25)
			GB.Button.icon = GB.Button.pupil

			 GB.Button.green:SetTexture("Interface\\AddOns\\"..AddonName.."\\artwork\\".."Eye\\green")
			 GB.Button.pupil:SetTexture("Interface\\AddOns\\"..AddonName.."\\artwork\\".."Eye\\pupil")
			 GB.Button.shine:SetTexture("Interface\\AddOns\\"..AddonName.."\\artwork\\".."Eye\\shine")
	
			GB.Button.texture = GB.Button.icon
			GB.Button:RegisterForClicks("AnyUp")
			
			for i, b in pairs(GB.scripts) do
				GB.Button:SetScript(i, b)
			end
			
			parent.groupButton = GB.Button
		end
		
		EyeTemplate_StopAnimating(GB.Button)

		return GB.Button
	end

	function Questra:ShowGroupButton(questID)
		local showGroup, shouldAnimate, isQueued = shouldShowAndOrAnimate()

		canCreateGroup[questID or 0] = questID and canCreateGroup[questID] or questID and CanCreateQuestGroup(questID) or false
		local state = UnitInAnyGroup("player") == true and true or showGroup or canCreateGroup[questID]
		
		local alwaysShow = true--self:GetSets().display.showGroup == true
		
		local groupButton = (alwaysShow or state) and GB:Create(self.navButton)
		
		groupButton.isQueued = isQueued
				
		if groupButton then
			if isQueued then
				EyeTemplate_StartSpin(groupButton)
			elseif shouldAnimate and (alwaysShow or state) then
				EyeTemplate_StartAnimating(groupButton)

			else
				EyeTemplate_StopAnimating(groupButton)
			end
			groupButton.glowLocks = QueueStatusMinimapButton.glowLocks
			QueueStatusMinimapButton_UpdateGlow(groupButton)
		end
		
		local textureInfo = LFG_EYE_TEXTURES["default"]
		if groupButton and not InCombatLockdown() then
			groupButton.questID = questID
			local shouldShow = ((state == true) or (UnitInAnyGroup("player") == true) or (showGroup)) and true or nil
			groupButton.tooltip, groupButton.tooltip2  = (((state == true) and (not inGroup)) and (showGroup)) and "You are looking for a group." --and you need to be in a group for this quest.
			or ((state == true) and (not inGroup))and "This task suggests a group." --and you aren't in one yet.
			or ((UnitInAnyGroup("player") == true)) and "You are in a group, but this task does not require one" --some quests won't provide credit if you are in the wrong type of group...
			or (alwaysShow == true) and "Right click for Dungeon Finder.",
			(((state == true) and (not inGroup)) and (showGroup)) and "Be patient..."
			or ((state == true) and (not inGroup)) and "Left click to find one."
			or (UnitInAnyGroup("player") == true) and "Right click to leave the group."
			or (alwaysShow == true) --and "Right click for Dungeon Finder."
			
			groupButton.Normal:SetVertexColor(unpack(((state == true) and (not inGroup)) and on or off))
			--groupButton:GetPushedTexture():SetVertexColor(unpack(((state == true) and (not inGroup)) and on or off))
			local showGroup = shouldShowAndOrAnimate()
			shouldShow = shouldShow or showGroup or alwaysShow

			local d = (((UnitInAnyGroup("player") == true) or shouldShow) and not groupButton:IsShown()) and groupButton:Show() or (groupButton:IsShown() and not shouldShow) and groupButton:Hide() --why not?
		
		
			if groupButton:IsShown() then
				QueueStatusMinimapButton:Hide()
			end
		
			return d
		end
	end
end

do --item button
local  questItems = {}
	local lastItemQuestID
	function Questra:ShowItemButton(itemQuestID)
		wipe(questItems)

		for i = 1, C_QuestLog.GetNumQuestWatches() do
			local quest = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
			if quest then
				local questLogIndex = quest and C_QuestLog.GetLogIndexForQuestID(quest)
				
				if questLogIndex then
					local link, item, charges, showItemWhenComplete = GetQuestLogSpecialItemInfo(questLogIndex)
					if link then
						if itemQuestID == quest then
							tinsert(questItems, 1, quest)
						else
							tinsert(questItems, quest)
						end
					end
				end
			end
		end
		
		local index = itemQuestID and C_QuestLog.GetLogIndexForQuestID(itemQuestID)
		if index then
			local link, item, charges, showItemWhenComplete = GetQuestLogSpecialItemInfo(index)
			if link then
				tinsert(questItems, 1, itemQuestID)
			end	
		end
		if #questItems > 1 then
			self.scroll = ( self.scroll and ((self.scroll > #questItems) and 1 or (self.scroll < 1) and #questItems)) or self.scroll or 1
			itemQuestID = questItems[self.scroll] or itemQuestID
		else
			--return
		end
		if itemQuestID then
			--if itemQuestID ~= lastitemQuestID then --don't update if item hasn't changed.
				lastItemQuestID = itemQuestID
				local questLogIndex = C_QuestLog.GetLogIndexForQuestID(itemQuestID)
				if questLogIndex then
				--	self.itemButton:SetID(itemQuestID)
					local link, item, charges, showItemWhenComplete = GetQuestLogSpecialItemInfo(questLogIndex)
					if link then
						local itemID = GetItemInfoInstant(link)

						if IsItemInRange(itemID, "target") == true or IsItemInRange(itemID, "mouseover") == true then
							self.itemButton.Normal:SetVertexColor(1,1,1,1)
						else
							self.itemButton.Normal:SetVertexColor(1,0,0,1)
						end



						--if self.itemButton.lastItem ~= item then
							local itemID = GetItemInfoInstant(link)
							self.itemButton.charges = charges
							self.itemButton.rangeTimer = -1
							SetItemButtonTexture(self.itemButton, item)
							SetItemButtonCount(self.itemButton, GetItemCount(link))

							--self.itemButton.Count:SetText(GetItemCount(link))

							if not InCombatLockdown() then
								self.itemButton:SetAttribute('type', 'macro')
								self.itemButton:SetAttribute('macrotext', '/use ' .. GetItemInfo(itemID))
								self.itemButton:SetID(itemID)
							end
							SetPortraitToTexture(self.itemButton.icon, self.itemButton.icon:GetTexture())

						--	self.itemButton.lastItem = item
						--end
						if not InCombatLockdown() and not self.itemButton:IsShown() then
							self.itemButton:Show()
						end
					end
				end
			--end
		else
			if self.itemButton and not InCombatLockdown() and self.itemButton:IsShown() then
				self.itemButton:Hide()
			end
		end
	end
end

do --odds and ends...
	function Questra:AddRewardsToTooltip(tooltip, questID, style)
		style = style or TOOLTIP_QUEST_REWARDS_STYLE_DEFAULT

		if ( GetQuestLogRewardXP(questID) > 0 or GetNumQuestLogRewardCurrencies(questID) > 0 or GetNumQuestLogRewards(questID) > 0 or
			GetQuestLogRewardMoney(questID) > 0 or GetQuestLogRewardArtifactXP(questID) > 0 or GetQuestLogRewardHonor(questID) > 0 or
			GetNumQuestLogRewardSpells(questID) > 0) then
			if tooltip.ItemTooltip then
				tooltip.ItemTooltip:Hide()
			end

			GameTooltip_AddBlankLinesToTooltip(tooltip, style.prefixBlankLineCount)
			if style.headerText and style.headerColor then
				GameTooltip_AddColoredLine(tooltip, style.headerText, style.headerColor, style.wrapHeaderText)
			end
			GameTooltip_AddBlankLinesToTooltip(tooltip, style.postHeaderBlankLineCount)

			local hasAnySingleLineRewards, showRetrievingData = QuestUtils_AddQuestRewardsToTooltip(tooltip, questID, style)

			if hasAnySingleLineRewards and tooltip.ItemTooltip and tooltip.ItemTooltip:IsShown() then
				GameTooltip_AddBlankLinesToTooltip(tooltip, 1)
				if showRetrievingData then
					GameTooltip_AddColoredLine(tooltip, RETRIEVING_DATA, RED_FONT_COLOR)
				end
			end
		end
	end

	function Questra:GetFactionInfo(questID)
		if not questID then return end
		local title, factionID, capped = C_TaskQuest.GetQuestInfoByQuestID(questID)

		if factionID == nil then
				local logIndex = questID and C_QuestLog.GetLogIndexForQuestID(questID)

				title = logIndex and C_QuestLog.GetTitleForLogIndex(logIndex)
				--shadowlands made extensive changes. I can't seem to find faction info for non world quests now.
			--title, factionID, capped = C_TaskQuest.GetQuestInfoByQuestID(questID)
		end

		return title, factionID, capped, factionID and GetFactionInfoByID(factionID)
	end

	function Questra:GetQuestLocation(questId, noLocalize)
			if not questId then
				return
			end

			local playerMapID = self:GetViewedMapID()

			if  QuestUtils_IsQuestWorldQuest(questId) == true then
				local mapID = C_TaskQuest.GetQuestZoneID(questId) or GetQuestUiMapID(questId) or playerMapID
				local x, y = C_TaskQuest.GetQuestLocation(questId, mapID)

				if noLocalize then
					return x, y, mapID
				end

				local _x, _y = HBD:TranslateZoneCoordinates(x, y, mapID, Questra:GetWorldID(mapID), true)
				local _x, _y = HBD:TranslateZoneCoordinates(_x, _y,  Questra:GetWorldID(mapID), playerMapID, true)

				return _x or x , _y or y, playerMapID or mapID
			else
				local mapID, x, y = C_QuestLog.GetNextWaypoint(questId)
				if not (x and y) then
					mapID = GetQuestUiMapID(questId) or playerMapID
					local mapQuests = C_QuestLog.GetQuestsOnMap(mapID)
					if mapQuests then
						for i, info in ipairs(mapQuests) do
							if questId == (info.questId or info.questID) then
								if mapID == Questra:GetPlayerMapID() then
									return info.x, info.y, mapID
								end

								if noLocalize then
									return info.x, info.y, mapID
								end

								local _x, _y = HBD:TranslateZoneCoordinates(info.x, info.y, mapID, Questra:GetWorldID(mapID), true)
								local _x, _y = HBD:TranslateZoneCoordinates(_x, _y, Questra:GetWorldID(mapID), playerMapID, true)
								return _x or x, _y or y, playerMapID or mapID
							end
						end
					end
				end
				return x, y, mapID
			end
		end
end

do --script functions
	function Questra:BaseOnEnter()
		-- if IsShiftKeyDown() then
				-- self.dragFrame:Show()
			-- return
		-- end
	end

	function Questra:BaseOnLeave()
		if self.dragFrame:IsVisible() and not MouseIsOver(self.dragFrame) then
			self.dragFrame:Hide()
		end
	end

	function Questra:DragOnLeave()
		if self:IsVisible() then
			self:Hide()
		end
	end

	function Questra:DragOnMouseDown(button)
		self:GetParent():SetMovable(true)
		self:GetParent():StartMoving()
	end

	function Questra:DragOnMouseUp(button)
		self:GetParent():StopMovingOrSizing()
	end

	function Questra:NavOnMouseDown(button)
		local tracker = Questra:GetTracked()
		
		if tracker then
			tracker.OnClick(button)
		end
	end

	function Questra:NavOnMouseUp(button)

	end

	function Questra:NavOnEnter()
		if self.hl and not self.hl:IsVisible() then
			self.hl:Show()
		end
		GameTooltip_OnHide(GameTooltip)
		
		local tracker = Questra:GetTracked()
		local _ = tracker and tracker.SetTooltip()
	end

	function Questra:NavOnLeave()
		if self.hl:IsVisible() then
			self.hl:Hide()
		end
		GameTooltip:Hide()
	end

	function Questra:OnEnterPressed(text, ...)
		self:ClearFocus()
		--set nav point
	end

	function Questra:AnchorOnMouseUp(button)
		print(_, button)
	end

	function Questra:SaveOnMouseUp(button)
		print(_, button)
	end
end

do --map shortcuts
	function Questra.GetPlayerPosition()
		return HBD:GetPlayerZonePosition(true)
	end

	function Questra:GetWorldID(id)
		local _, _, world  = HBD:GetWorldCoordinatesFromZone(.5, .5, id)
		return world
	end

	function Questra:GetMap()
		return _G["WorldMapFrame"]
	end

	function Questra:GetViewedMapID()
		local view = _G["WorldMapFrame"]:GetMapID() or MapUtil.GetDisplayableMapForPlayer()
		local _, _, world = Questra:GetWorldID(view)

		local zoneName = GetRealZoneText(view)
		if IsInInstance() then
			local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceID, instanceGroupSize, LfgDungeonID = GetInstanceInfo()
			if zoneName == name then
			Questra_DB = Questra_DB or {}
				local info = Questra_DB and Questra_DB.instanceLocations and Questra_DB.instanceLocations[zoneNamemm]
				if info then
					return info.position.mapID, Questra:GetWorldID(info.position.mapID)
				end
			end
		end

		if view then
			return view, world
		else
			return self:GetPlayerMapID()
		end
	end

	function Questra:GetPlayerMapID()
		if IsInInstance() then
			local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceID, instanceGroupSize, LfgDungeonID = GetInstanceInfo()

			local info = Questra_DB and Questra_DB.instanceLocations and Questra_DB.instanceLocations[name]
			if info then
		
				return info.position.mapID, Questra:GetWorldID(info.position.mapID)
			end
		end
		return MapUtil.GetDisplayableMapForPlayer()
	end

	function Questra:GetCanvas()
		return _G["WorldMapFrame"]:GetCanvas()
	end
end

do --visual display update functions
	local trackingIndex = 1

	function Questra:GetTracking()
		return trackingIndex or 1
	end

	function Questra:SetTracking(index)
		trackingIndex = index or tIndexOf(Questra.typesIndex, Questra.lastSwap) or 1
	end

	function Questra:ScrollMetricIndex(delta)
		Questra:UpdateDisplayed("Forced")
				
		local tracker = Questra:GetTracked()
		if tracker then
			tracker.ScrollMetrics(-delta)
		end

		Questra:CollectUpdate()
		Questra:Update()
	end
	
	function Questra:ScrollTracking(delta)
		Questra:UpdateDisplayed("Forced")

		Questra:UpdateTracking(delta)
			
		Questra:CollectUpdate()
		Questra:Update()
	end
	
	function Questra:UpdateTracking(delta)
		trackingIndex = trackingIndex and trackingIndex - delta or 1
		trackingIndex = trackingIndex > #Questra.typesIndex and 1
			or trackingIndex < 1 and #Questra.typesIndex
			or trackingIndex --rollover from start to finish or finish to start
			
		local i = Questra.typesIndex[trackingIndex]
		
		if not (i == "dungeon" or i == "flight" or i == "offer") then
			Questra.lastSwap = Questra.typesIndex[trackingIndex]
		end
	end

	function Questra:UpdateDisplayed(event)
		for i, track in pairs(Questra.tracking) do
			track.OnEvent(event)

			local shouldShow = track.ShouldShow()

			if shouldShow then
				if not tContains(Questra.typesIndex, track.trackingName) then
					tinsert(Questra.typesIndex, track.trackingName)
				end
			else
				if tContains(Questra.typesIndex, track.trackingName) then
					tremove(Questra.typesIndex, tIndexOf(Questra.typesIndex, track.trackingName))
				end
			end
		end
	end

	function Questra:UpdateAutoTracking(event)
		Questra:UpdateDisplayed(event)

		local newAutoSwap
		for i, track in pairs(Questra.tracking) do
			local shouldSwap, metric = track.ShouldAutoSwap()			
			if shouldSwap and not newAutoSwap then
				newAutoSwap = tIndexOf(Questra.typesIndex, track.trackingName)
				Questra.lastSwap = track.trackingName
				track.SetToMetric(metric)
				Questra:SetTracking(newAutoSwap)
				Questra:CollectUpdate()
				return
			end
		end
	end

	function Questra:GetTracked()
		return Questra.trackByName[Questra.typesIndex[Questra:GetTracking()]]
	end
	
	function Questra:CollectUpdate()
		local tracker = Questra:GetTracked()
				
		local skinDetails, position, texture, l, r, t, b, extra = Questra.basicSkin, nil, nil, 0, 1, 0, 1, nil
		if tracker then
			skinDetails, position, texture, l, r, t, b, extra  = tracker.GetIconInfo()
			
			
			Questra.qtyText:SetText(tracker.GetScrollValue().." / "..#tracker.metrics)
		else
		
			Questra.qtyText:SetText("")
			self.navButton.icon:SetTexture("")
			self.navButton.icon:SetTexCoord(0,1,0,1)
			self.distanceText:SetText("")
			self.navButton.arrow:Hide() 
			self.navButton.arrow:SetRotation(0)
		end
		
		Questra.storedUpdate = {
			position and position.x,
			position and position.y,
			position and position.mapID,
			texture,
			l, r, t, b,
			skinDetails,
			extra,
			questID = (extra and type(extra) ~= "boolean") and extra or nil,
		}
		
		
		--Questra:ShowGroupButton(extra)
		--Questra:ShowItemButton(extra)
	end
	
	function Questra:Update()
		local  x, y, id = Questra.GetPlayerPosition()
		local questID

		
		if Questra.storedUpdate then
			questID = Questra.storedUpdate.questID
			Questra:SetDisplay(x, y, id, unpack(Questra.storedUpdate))
			
			if Questra.storedUpdate then

			end
		end
		
		Questra:ShowGroupButton(questID)
		Questra:ShowItemButton(questID)
	end

	function Questra:SetDisplay(oX, oY, oID, dX, dY, dID, icon, L, R, T, B, skinDetails, extra)
		if oX and oY and self.coordText:HasFocus() ~= true then
			self.coordText:SetText(floor(oX*10000)/100 ..", "..floor(oY*10000)/100)
		end
		
		local vID = Questra:GetViewedMapID()
		local _, _, vID_World = HBD:GetWorldCoordinatesFromZone(.21, 1, vID)
		
		--Get World Coordinates for origin and destination
		if oX and oY and oID and dX and dY and dID then
			local portalAvailable = Questra:GetPortal(dID)
			if portalAvailable then			
				Questra.portalSense = portalAvailable
				dX = portalAvailable.origin.x
				dY = portalAvailable.origin.y
				dID = portalAvailable.origin.mapID
			end
			
			local flightAvailable = Questra:GetFlight(dID, dX, dY) --not completely ready: sometimes inaccurate
			if flightAvailable then			
				Questra.portalSense = flightAvailable
				dX = flightAvailable.origin.x
				dY = flightAvailable.origin.y
				dID = flightAvailable.origin.mapID
			elseif not portalAvailable then
				Questra.portalSense = nil
			end
			

			local oX_World, oY_World, oID_World  = HBD:GetWorldCoordinatesFromZone(oX, oY, oID)
			local dX_World, dY_World, dID_World  = HBD:GetWorldCoordinatesFromZone(dX, dY, dID)
		
			--dungeon entrance conversion?
		
			if oID_World == dID_World then
				local sameZone = oID == dID or nil
				if not sameZone then
					dX, dY = HBD:TranslateZoneCoordinates(dX, dY, dID, oID, true)
					dID = oID
				end
			
				if oID ~= dID then
					local viewed_wX, viewed_wY = HBD:TranslateZoneCoordinates(dX, dY, dID, oID, true)
					dX, dY, dID = viewed_wX, viewed_wY, oID
				end
		
				local angle, dist
				local playerAngle = GetPlayerFacing()

				angle = HBD:GetWorldVector(oID_World, oX_World, oY_World, dX_World, dY_World)
				dist = IN_GAME_NAVIGATION_RANGE:format(Round(HBD:GetZoneDistance(oID, oX, oY, dID, dX, dY)))
				
				self.distanceText:SetText((dist and string.split(" ", dist)) ~= "0" and dist or "")

				if angle and playerAngle then
					self.navButton.arrow:Show()
					self.navButton.arrow:SetRotation(rad((deg(angle) - deg(playerAngle))))

					if vID_World == oID_World then
						local viewed_pX, viewed_pY = HBD:TranslateZoneCoordinates(oX, oY, oID, vID, true)
						local viewed_wX, viewed_wY = HBD:TranslateZoneCoordinates(dX, dY, dID, vID, true)
						Questra:SetLine( _G["WorldMapFrame"]:GetCanvas(), angle, viewed_pX, viewed_pY, viewed_wX, viewed_wY)
					else
						Questra:SetLine()
					end
				else
					Questra:SetLine()
					self.navButton.arrow:Hide()
					self.navButton.arrow:SetRotation(0)
				end
			end
		else
			Questra.portalSense = nil
			self.distanceText:SetText("")
			self.navButton.arrow:Hide()
			self.navButton.arrow:SetRotation(0)
			Questra:SetLine()
		end

		local bgtexture, normCoords, pushedCoords, normColor, pushedColor = unpack(skinDetails or Questra.basicSkin)
		self.navButton:SetNormalAtlas(bgtexture)
		self.navButton:SetPushedAtlas(bgtexture)
		self.navButton:GetNormalTexture():SetTexCoord(unpack(normCoords))
		self.navButton:GetPushedTexture():SetTexCoord(unpack(pushedCoords))
		self.navButton:GetNormalTexture():SetVertexColor(unpack(normColor))
		self.navButton:GetPushedTexture():SetVertexColor(unpack(pushedColor))
		
		if type(icon) == "string" then
			self.navButton.icon:SetAtlas(icon)
			--prin("atlas")
		else
			--self.navButton.icon:SetTexture(icon)
			--prin("texture")
		end
		--prin(L or 0, R or 1, T or 0, B or 1)
		--self.navButton.icon:SetTexCoord(L or 0, R or 1, T or 0, B or 1)
		
		Questra.tracking[Questra:GetTracking()].portal = Questra.portalSense
	end

	function Questra:SetLine(canvas, angle, x, y, vX, vY)
			if not canvas then
				self.waypointLine:Hide()
				self.waypointMarker:Hide()
				return
			end
		do
			--using these cheaters helps to reduce intense maths.
			self.playerLocationHandler:SetPoint("TopLeft", WorldMapFrame)
			self.playerLocationHandler:SetPoint("BottomRight", canvas, x*canvas:GetWidth(), y*canvas:GetHeight())
			self.waypointLocationHandler:SetPoint("TopLeft", WorldMapFrame)
			self.waypointLocationHandler:SetPoint("BottomRight", canvas, vX, vY)

			local wayW, wayH = self.waypointLocationHandler:GetSize()
			local playW, playH = self.playerLocationHandler:GetSize()

			if math.sqrt(math.pow((playW - wayW), 2) + math.pow((playH - wayH), 2)) < .03 then
				self.waypointLine:Hide()
				self.waypointMarker:Hide()
				return
			else
				self.waypointLine:Show()
				self.waypointMarker:Show()
			end
		end

		local w, h = canvas:GetSize()
		local scale = canvas:GetScale()

		self.waypointLine:SetThickness(3)

		local dist = 1--10 / scale


		local a = math.deg(math.rad(90) - angle) * (math.pi/180)


		local pX = ((w * x)       - (math.cos(a) * dist)) * scale
		local pY = (((1 - y) * h) - (math.sin(a) * dist)) * scale

		local _wX = vX * w
		local _wY = (1 - vY) * h


		local wX = _wX + (math.cos(a) * dist)
		local wY = _wY + (math.sin(a)* dist)

		self.waypointLine:SetStartPoint("BottomLeft", canvas, pX, pY)
		self.waypointLine:SetEndPoint("BottomLeft", canvas, wX * scale, wY * scale)

		self.waypointMarker:Show()
		self.waypointMarker:SetPoint("Center", canvas, "BottomLeft", _wX * scale, _wY * scale)
		self.waypointMarker:SetSize(15 , 15 )
	end
end

Questra.Events  = {
	"PLAYER_ENTERING_WORLD",

	-- "QUEST_CURRENCY_LOOT_RECEIVED",
	-- "QUEST_LOOT_RECEIVED",
	-- "QUEST_ACCEPTED",
	-- "QUEST_AUTOCOMPLETE",
	-- "QUEST_COMPLETE",	
	-- --"QUEST_DATA_LOAD_RESULT",
	-- --"QUEST_DETAIL",
	-- --"QUEST_LOG_CRITERIA_UPDATE",
	-- "QUEST_LOG_UPDATE",
	-- "QUEST_POI_UPDATE",
	-- "QUEST_REMOVED",
	-- "QUEST_TURNED_IN",
	-- "QUEST_WATCH_LIST_CHANGED",
	-- "QUEST_WATCH_UPDATE",
	-- "QUESTLINE_UPDATE",
	-- --"TASK_PROGRESS_UPDATE",
	-- --"TREASURE_PICKER_CACHE_FLUSH",
	-- 
	-- "WORLD_QUEST_COMPLETED_BY_SPELL",

	--"QUEST_ACCEPT_CONFIRM",
	--"QUEST_GREETING",
	--"QUEST_ITEM_UPDATE",


	
	--group button update events
	
	-- "LFG_UPDATE",
	-- "UPDATE_LFG_LIST",
	-- "ISLAND_COMPLETED",
	-- "LFG_PROPOSAL_SHOW",
	-- "LFG_PROPOSAL_DONE",
	-- "ISLANDS_QUEUE_OPEN",
	-- "ISLANDS_QUEUE_CLOSE",
	-- "LFG_PROPOSAL_FAILED",
	-- "LFG_PROPOSAL_UPDATE",
	-- "LFG_LIST_JOINED_GROUP",
	-- "LFG_LOCK_INFO_RECEIVED",
	-- "LFG_UPDATE_RANDOM_INFO",
	-- "LFG_PROPOSAL_SUCCEEDED",
	-- "LFG_QUEUE_STATUS_UPDATE",
	-- "PET_BATTLE_QUEUE_STATUS",
	-- "LFG_LIST_AVAILABILITY_UPDATE",
	-- "PET_BATTLE_QUEUE_PROPOSE_MATCH",
	-- "PET_BATTLE_QUEUE_PROPOSAL_ACCEPTED",
	-- "PET_BATTLE_QUEUE_PROPOSAL_DECLINED",

}

local eventManager = {Forced = {}, }

do --tracking management
	local function LinkAnywhere(mapID, x, y, questID)
		local activeLinkWindow = ChatEdit_GetActiveWindow()
		if activeLinkWindow then
			local mapLink = ""
			if x and y and mapID then
				--normalize values
				while x > 1 do
					x = x / 10
				end
				while y > 1 do
					y = y / 10
				end
			
				--format values for the link
				x = floor(x * 10000)
				y = floor(y * 10000)
				mapLink = "|cffffff00|Hworldmap:"..mapID ..":".. x ..":".. y.."|h[|A:Waypoint-MapPin-ChatIcon:13:13:0:0|a Map Pin Location]|h|r"
			end

			local questLink = questID
				and (GetQuestLink(questID)
					or (C_QuestLog.IsQuestTask(questID) and C_TaskQuest.GetQuestInfoByQuestID(questID))
					or C_QuestLog.GetTitleForQuestID(questID))
			local questText = (questLink) and questLink or ""
			
			local at = (mapLink ~= "") and " @ " or ""
			
			
			mapLink = mapLink or ""
			activeLinkWindow:SetText(questText .. at ..mapLink)
			PlaySound(SOUNDKIT.UI_MAP_WAYPOINT_CHAT_SHARE)
		end
	end
	
	local pingAnywherePin,  lastPing
	local function PingAnywhere(x, y, wayMapID)
		local sense = Questra.portalSense
		if sense then
			x, y, wayMapID = sense.x or sense.origin.x, sense.y or sense.origin.y, sense.mapID or sense.origin.mapID 
		end		
		
		--handy tool derived from: "Interface\AddOns\Blizzard_SharedMapDataProviders\WorldQuestDataProvider.lua"
		OpenWorldMap(wayMapID)

		pingAnywherePin = pingAnywherePin or WorldMapFrame:AcquirePin("QuestraPingPinTemplate")

		if x and y then
			--safety precaution
			while x > 1 do
				x = x / 10
			end
			while y > 1 do
				y = y / 10
			end
			if (not pingAnywherePin.DriverAnimation:IsPlaying()) or lastPing ~= x..y..wayMapID then
				pingAnywherePin:Show()
				pingAnywherePin:GetMap():SetPinPosition(pingAnywherePin, x, y)
				pingAnywherePin.DriverAnimation:Play()
				lastPing = x..y..wayMapID
			end
		else
			pingAnywherePin.DriverAnimation:Stop()
			pingAnywherePin:Hide()
		end
	end
	
	do
		Questra.basicSkin = {
			"common-radiobutton-dot",
			{.25, .75, .25, .75},
			{.22, .78, .22, .78},
			{242/256, 140/256, 40/256, 1},
			{242/256, 140/256, 40/256, 1},
		}

		Questra.professionsMap = {
			[164] = CHARACTER_PROFESSION_BLACKSMITHING,
			[165] = CHARACTER_PROFESSION_LEATHERWORKING,
			[171] = CHARACTER_PROFESSION_ALCHEMY,
			[182] = CHARACTER_PROFESSION_HERBALISM,
			[186] = CHARACTER_PROFESSION_MINING,
			[197] = CHARACTER_PROFESSION_TAILORING,
			[202] = CHARACTER_PROFESSION_ENGINEERING,
			[333] = CHARACTER_PROFESSION_ENCHANTING,
			[393] = CHARACTER_PROFESSION_SKINNING,
			[755] = CHARACTER_PROFESSION_JEWELCRAFTING,
			[773] = CHARACTER_PROFESSION_INSCRIPTION,
		}

		Questra.iconDisplayInfo = {
			[129] = {"worldquest-icon-firstaid"      , -.1, 1.1, -.1, 1.1},
			[164] = {"worldquest-icon-blacksmithing" , -.1, 1.1, -.1, 1.1},
			[165] = {"worldquest-icon-leatherworking", -.1, 1.1, -.1, 1.1},
			[171] = {"worldquest-icon-alchemy"       , -.1, 1.1, -.1, 1.1},
			[182] = {"worldquest-icon-herbalism"     , -.1, 1.1, -.1, 1.1},
			[186] = {"worldquest-icon-mining"        , -.1, 1.1, -.1, 1.1},
			[202] = {"worldquest-icon-engineering"   , -.1, 1.1, -.1, 1.1},
			[333] = {"worldquest-icon-enchanting"    , -.1, 1.1, -.1, 1.1},
			[755] = {"worldquest-icon-jewelcrafting" , -.1, 1.1, -.1, 1.1},
			[773] = {"worldquest-icon-inscription"   , -.1, 1.1, -.1, 1.1},
			[794] = {"worldquest-icon-archaeology"   , -.1, 1.1, -.1, 1.1},
			[356] = {"Mobile-Fishing"                , 0,1,0,1},
			[185] = {"worldquest-icon-cooking"       , -.1, 1.1, -.1, 1.1},
			[197] = {"worldquest-icon-tailoring"     , -.1, 1.1, -.1, 1.1},
			[393] = {"Mobile-Skinning"               , 0,1,0,1},
		
			["treasure"]                   = function() return "vignetteloot", 0, 1, 0, 1 end,
			["dig"]                        = function() return "worldquest-icon-archaeology", 0, 1, 0, 1 end,
			["way"]                        = function() return "ShipMissionIcon-Bonus-Mission", 0, 1, 0, 1 end,
			["dead"]                       = function() return "poi-graveyard-neutral", -.25, 1.25, -.25, 1.1 end,
			["daily"]                      = function() return "QuestDaily" end,
			["flight"]                     = function() return "Taxi_Frame_Gray" end,
			["normal"]                     = function() return "QuestNormal" end,
			["trivial"]                    = function() return "TrivialQuests" end,
			["campaign"]                   = function() return "Quest-Campaign-Available" end,
			["complete"]                   = function() return "questlog-waypoint-finaldestination-questionmark", -.05, 1.01, .16, .87 end,
			["legendary"]                  = function() return "QuestLegendary" end,
			
			[Enum.QuestTagType.PvP]        = function() return "Mobile-CombatBadgeIcon", 0, 1, 0, 1 end,
			[Enum.QuestTagType.Raid]       = function() return "worldquest-icon-raid", -.2, 1.2, -.2, 1.2 end,
			[Enum.QuestTagType.Threat]     = function() return "worldquest-icon-nzoth" end,
			[Enum.QuestTagType.Islands]    = function() return "poi-islands-table" end,
			[Enum.QuestTagType.Dungeon]    = function() return "worldquest-icon-dungeon", -.2, 1.2, -.2, 1.2 end,
			[Enum.QuestTagType.Invasion]   = function() return "worldquest-icon-burninglegion", -.1, 1.1, -.1, 1.1 end,
			[Enum.QuestTagType.PetBattle]  = function() return "Mobile-Pets", 0, 1, 0, 1 end,
			
			[Enum.QuestTagType.Profession] = function(tradeskillLineID)
				if Questra.iconDisplayInfo[tradeskillLineID] then
					return unpack(Questra.iconDisplayInfo[tradeskillLineID])
				end
			end,
			
			[Enum.QuestTagType.FactionAssault] = function()
				local faction = UnitFactionGroup("player")
				return (faction == "Horde") and "QuestPortraitIcon-Horde-small"
					or (faction == "Alliance") and "QuestPortraitIcon-Alliance-small"
					or "QuestPortraitIcon-SandboxQuest"
			end,


			--[Enum.QuestTagType.Contribution]   = function() return "", 0, 1, 0, 1 end,
			--[Enum.QuestTagType.RatedReward]   = function() return "", 0, 1, 0, 1 end,
			--[Enum.QuestTagType.Normal]   = function() return "", 0, 1, 0, 1 end,
			--[Enum.QuestTagType.Bounty]   = function() return "", 0, 1, 0, 1 end,
			--[Enum.QuestTagType.CovenantCalling]   = function() return "", 0, 1, 0, 1 end,
			--[Enum.QuestTagType.InvasionWrapper]   = function() return "", 0, 1, 0, 1 end,
		}

		Questra.questQualityBorderTextures = { --NYI: do not delete
			[Enum.WorldQuestQuality.Common] = "auctionhouse-itemicon-border-white",
			[Enum.WorldQuestQuality.Rare] = "auctionhouse-itemicon-border-blue",
			[Enum.WorldQuestQuality.Epic] = "auctionhouse-itemicon-border-purple",
		}

		Questra.questQualityTextures = {
			[Enum.WorldQuestQuality.Epic]   = {"worldquest-questmarker-epic", {138/256, 43/256, 226/256, 1}},
			[Enum.WorldQuestQuality.Rare]   = {"worldquest-questmarker-rare", {1, 1, 1, 1}},
			[Enum.WorldQuestQuality.Common] = {"CircleMask"                 , {139/256,69/256,19/256, 1}},
		}
			
		Questra.typesIndex = {}

		Questra.tracking = {}
	
		Questra.trackByName = {}
	end

	local worldZoneLog = {}
	local isWorld = {[Enum.UIMapType.Continent] = true, [Enum.UIMapType.World] = true}
	local function digForWorldMapID(id)
		if worldZoneLog[id] then return worldZoneLog[id] end
		local oID = id
		
		local info = C_Map.GetMapInfo(id)
		if info and isWorld[info.mapType] then
			worldZoneLog[oID] = info.mapID
			return info.mapID
		end
	
		while info do
			local parent = C_Map.GetMapInfo(info.parentMapID)
			if parent and isWorld[parent.mapType] then
				worldZoneLog[oID] = parent.mapID
				return parent.mapID
			end
			id = parent and parent.mapID
			info = C_Map.GetMapInfo(id)
		end
		
		worldZoneLog[oID] = id or oID
		return id or oID
	end
	
	local function AddTracking(infoTable)
		tinsert(Questra.typesIndex, infoTable.trackingName)
		tinsert(Questra.tracking, infoTable)
		Questra.trackByName[infoTable.trackingName] = infoTable
		
		
		if infoTable.events then
			for i, event in pairs(infoTable.events) do
				eventManager[event] = eventManager[event] or {}
				local _ = nil, (not tContains(Questra.Events, event)) and tinsert(Questra.Events, event)
				_ = nil, (not tContains(eventManager[event], infoTable)) and tinsert(eventManager[event], infoTable)
			end
		end
		
		local _ = nil, (not tContains(eventManager.Forced, infoTable)) and tinsert(eventManager.Forced, infoTable)		
	end

	do local track = {trackingName = "dead", metrics = {[1] = {}}, scrollValue = 1,}
		--[[constants: to be used by each tracking type, for consistency!
			track.metrics --what to track ID or Table (prefer ID, less to track)
			track.lastMetric
			track.scrollValue
			...to be continued!
		--]]
		
		track.GetLocation = function(questID)
			return track.metrics[1]
		end
		
		track.GetMetricInfo = function(playerX, playerY, playerMapID)
			
		end
		
		track.OnEvent = function()
			if not track.metricUpdate then
				track.metricUpdate = true
				local id = Questra:GetPlayerMapID() --digForWorldMapID(Questra:GetPlayerMapID())
				local userPoint = C_DeathInfo.GetCorpseMapPosition(id)
				
				if userPoint then
					local id, x, y = id , userPoint.x, userPoint.y
					if id and x and y then

						track.metrics[1].x = floor(x * 10000)/10000
						track.metrics[1].y = floor(y * 10000)/10000
						track.metrics[1].mapID = id
						return true
					end
				else
					track.metrics[1].x = nil
					track.metrics[1].y = nil
					track.metrics[1].id = nil
				end
				track.metricUpdate = nil
			end
		end
		
		track.ScrollMetrics = function(delta) end

		track.GetScrollValue = function(delta) end
		
		track.SetToMetric = function() end
		
		track.SetTooltip = function()
			local userPoint = track.GetLocation()
			if userPoint then
				local id, x, y = userPoint.mapID , userPoint.x, userPoint.y
				if id and x and y then	
		
					GameTooltip:SetOwner(Questra.navButton, "ANCHOR_LEFT")
					GameTooltip:SetText("Dead", 1, 1, 1)
					GameTooltip:AddLine("You have died!", 1, 0, 0)
					if Questra.portalSense then
						GameTooltip:AddLine("Take the "..Questra.portalSense.tooltip)
					end
					
					local mapInfo = C_Map.GetMapInfo(id)
				
					local _ = mapInfo and GameTooltip:AddDoubleLine(mapInfo.name..":", x*100 .. ", ".. y  * 100, id ~= Questra:GetPlayerMapID() and unpack({1,0,0,1}), id ~= Questra:GetPlayerMapID()and unpack({1,0,0,1}))
					
					
					
					GameTooltip_CalculatePadding(GameTooltip) --must be called to resize tooltip while scrolling.
					GameTooltip:Show()
				end
			end
		end
		
		track.ShouldShow = function()
			local userPoint = track.GetLocation()
			if userPoint then
				local id, x, y = userPoint.mapID , userPoint.x, userPoint.y
				if id and x and y then
					return true
				end
			end
		end
		
		track.ShouldAutoSwap = function(newAutoSwap)
			local id = digForWorldMapID(Questra:GetPlayerMapID())
			local corpse = C_DeathInfo.GetCorpseMapPosition(id)
			
			if corpse then
				local metric  = corpse.x .. corpse.y .. id
				if metric and (metric ~= track.lastMetric) then
					track.lastMetric = metric
					if C_DeathInfo.GetCorpseMapPosition(id) then
						return true
					end
				end
			end
		end
		
		local deadSkin = {
			"jailerstower-animapowerlist-rank",
			{.01, 1-.01, .01, 1-.01},
			{-.01, 1.01, -.01, 1.01},
			{1,1,1,1},
			{1,1,1,1},
		}

		track.GetIconInfo = function()
			local userPoint = track.GetLocation()
			if userPoint then
				if userPoint.mapID and userPoint.x and userPoint.y then
					return deadSkin, userPoint, Questra.iconDisplayInfo["dead"]()
				end
			end
		end
		
		track.OnClick = function()
			local userPoint = track.GetLocation()
			if IsControlKeyDown() then
				local userPoint = track.GetLocation()
				LinkAnywhere(userPoint.mapID, userPoint.x, userPoint.y)
			elseif userPoint then
				if userPoint.mapID and userPoint.x and userPoint.y then
					PingAnywhere(userPoint.x, userPoint.y, userPoint.mapID)
				end
			end
		end
		
		track.SetByPin = function(pin)
			Questra:SetTracking(tIndexOf(Questra.typesIndex, track.trackingName))
			Questra:CollectUpdate()
		end
		
		track.events = {
			"PLAYER_DEAD",
			"CEMETERY_PREFERENCE_UPDATED",
			"REQUEST_CEMETERY_LIST_RESPONSE",
			"CORPSE_IN_INSTANCE",
			"CORPSE_IN_RANGE",
			"CORPSE_OUT_OF_RANGE",
		}
		
		AddTracking(track)
	end

	do local track = {trackingName = "quest", metrics = {}, scrollValue = 1,}
		--[[constants: to be used by each tracking type, for consistency!
			track.metrics --what to track ID or Table (prefer ID, less to track)
			track.lastMetric
			track.scrollValue
			...to be continued!
		--]]
		
		track.GetLocation = function(questID)
			local questID = questID or track.metrics[track.GetScrollValue()]
			
			local uiMapID = GetQuestUiMapID(questID)
						
			local x, y, mapID


			do --waypoint check					
				local wayID = C_QuestLog.GetNextWaypoint(questID) or uiMapID --This one can return incorrect x and y coords
				local wayX, wayY = C_QuestLog.GetNextWaypointForMap(questID, wayID) -- Gets accurate x and y coords
				if wayID and wayX and wayY then
					x, y, mapID = wayX, wayY, wayID
				end
			end
			
			if not (x and y and mapID) then
				--no waypoint found, check world maps
				local id = uiMapID or dID
				local mapQuests = id and C_QuestLog.GetQuestsOnMap(id)
				if mapQuests then
					for i, quest in pairs(mapQuests) do
						if C_QuestLog.GetLogIndexForQuestID(quest.questID) == (questLogIndex) then
							x, y, mapID = quest.x, quest.y, id
							break
						end
					end
				end
			end
			
			if (not (x and y)) and QuestHasPOIInfo(questID) and C_QuestLog.IsOnMap(questID) then
				local px, py, pID = Questra.GetPlayerPosition()
				local nearestDist, nearest = math.huge
				local points = QuestPOIGetSecondaryLocations(questID)
				if points and #points > 0 then
					for i, b in pairs(points) do
						local compDist = HBD:GetZoneDistance(pID, b.x, b.y, pID, px, py)
						if compDist and compDist < nearestDist then
							nearestDist = compDist
							x, y, mapID = b.x, b.y, pID
						end
					end
				end				
			end
			
			
			if x and y and mapID then
				--translate any waypoint located inside of a dungeon into the dungeon's entrance
				local mapInfo = C_Map.GetMapInfo(mapID)
				if (mapInfo.mapType) == 4 then --location is inside a dungeon
					local parentMapDungeons = C_EncounterJournal.GetDungeonEntrancesForMap(mapInfo.parentMapID)
					for i, b in pairs(parentMapDungeons) do
						if  b.name and b.name == mapInfo.name then
							x, y = b.position:GetXY()
							mapID = mapInfo.parentMapID
						end
					end
				end
			end
			
			
			
			return {x = x, y = y, mapID = mapID}
		end
		
		track.GetMetricInfo = function()
			local questID = track.metrics[track.GetScrollValue()]
			local questLogIndex = questID and C_QuestLog.GetLogIndexForQuestID(questID)
			local info = questLogIndex and C_QuestLog.GetInfo(questLogIndex)
				--[[info = {
						title,
						questLogIndex,
						questID,
						campaignID,
						level,
						difficultyLevel,
						suggestedGroup,
						frequency,  -- QuestFrequency
						isHeader,
						isCollapsed,
						startEvent,
						isTask,
						isBounty,
						isStory,
						isScaling,
						isOnMap,
						hasLocalPOI,
						isHidden,
						isAutoComplete,
						overridesSortOrder,
						readyForTranslation,
					}
				--]]

			if info then
				local waytext = C_QuestLog.GetNextWaypointText(questID)

				info.objectives = info.objectives or {}
				
				wayText =  waytext and WAYPOINT_OBJECTIVE_FORMAT_OPTIONAL:format(waytext)
				if waytext and not tContains(info.objectives, wayText) then
					tinsert(info.objectives, wayText)
				end
				
				for index = 1, C_QuestLog.GetNumQuestObjectives(questID) do
					local text, objectiveType, finished, fulfilled, required = GetQuestObjectiveInfo(questID, index, false)
					if text and not tContains(info.objectives, text) then
						tinsert(info.objectives, text)
					end
				end
				
				info.difficultyColor  = GetDifficultyColor(C_PlayerInfo.GetContentDifficultyQuestForPlayer(questID))
				info.questDescription = questLogIndex and select(2, GetQuestLogQuestText(questLogIndex))
				info.completeText = GetQuestLogCompletionText(questLogIndex)
				info.distance, info.onContinent = C_QuestLog.GetDistanceSqToQuest(questID)
				info.percent = GetQuestProgressBarPercent(questID)			
				info.tagInfo = C_QuestLog.GetQuestTagInfo(questID)
				info.complete = C_QuestLog.IsComplete(questID)
				info.position = track.GetLocation(questID)
				
				return info
			end
		end
		
		track.OnEvent = function()
			wipe(track.metrics)
			
			local index = 1
			local info = C_QuestLog.GetInfo(index)
			
			while info do
				local skip = info.isHeader or info.isBounty or QuestUtils_IsQuestWorldQuest(info.questID) or info.isTask or info.isHidden

				local _ = (not skip) and (not tContains(track.metrics, info.questID)) and tinsert(track.metrics, info.questID) --cause i can.
				
				index = index + 1
				info = C_QuestLog.GetInfo(index)
			end

			table.sort(track.metrics, function(a, b)
				local adist = C_QuestLog.GetDistanceSqToQuest(a)
				local bdist = C_QuestLog.GetDistanceSqToQuest(b)
		
				return (adist or math.huge) < (bdist or math.huge)
			end)
			
			
			return track.metrics
		end
		
		track.ScrollMetrics = function(delta)
			track.scrollValue = track.scrollValue + delta
			track.scrollValue = track.scrollValue > #track.metrics and 1 or track.scrollValue < 1 and #track.metrics or track.scrollValue --rollover from start to finish or finish to start
		end

		track.GetScrollValue = function(delta)
			return track.scrollValue or 1
		end
		
		track.SetToMetric = function(id)
			for i, b in pairs(track.metrics) do
				if b == id then
					track.scrollValue = i
				end
			end
		end
		
		track.SetTooltip = function()
			local info = track.GetMetricInfo()
			if info and info.title then
				GameTooltip:Hide()
				GameTooltip:SetOwner(Questra.navButton, "ANCHOR_LEFT")

				GameTooltip:SetText(info.title, info.difficultyColor.r, info.difficultyColor.g, info.difficultyColor.b)

				if Questra.portalSense then
					GameTooltip:AddLine("Take the "..Questra.portalSense.tooltip)
				end

				local mapInfo = info.position.mapID and C_Map.GetMapInfo(info.position.mapID)
				local _ = mapInfo and GameTooltip:AddLine(mapInfo.name, info.position.mapID ~= Questra:GetPlayerMapID()and unpack({1,0,0,1})) 

				QuestUtils_AddQuestTypeToTooltip(GameTooltip, info.questID, NORMAL_FONT_COLOR)

				local _ = info.questDescription and GameTooltip:AddLine(info.questDescription, 1, 1, 1, true)
				local _ = info.questDescription and GameTooltip_AddBlankLinesToTooltip(GameTooltip, 1)

				for i, text in pairs(info.objectives) do
					local text, r, g, b, bool = text, 1, 1, 1, true
					if type(text) == "table" then
						text, r, b, g, bool = unpack(text)
					end
				
					if text ~= info.questDescription then
						GameTooltip:AddLine(QUEST_DASH..text, r, g, b, bool)
					end
				end
									
				local _ = ( info.percent and info.percent > 0) and GameTooltip_ShowProgressBar(GameTooltip, 0, 100, info.percent, PERCENTAGE_STRING:format(info.percent))

				Questra:AddRewardsToTooltip(GameTooltip, info.questID)
				
				GameTooltip_CalculatePadding(GameTooltip) --must be called to resize tooltip while scrolling.
				GameTooltip:Show()
			end
		end
		
		track.ShouldShow = function()
			return #track.metrics > 0 or nil
		end
		
		track.ShouldAutoSwap = function(newAutoSwap)
			if (not newAutoSwap) then
				local metric  = C_SuperTrack.GetSuperTrackedQuestID()
				if metric and (metric ~= track.lastMetric) then
					track.lastMetric = metric
					if (metric ~= 0) and not QuestUtils_IsQuestWorldQuest(metric) then
						return tIndexOf(Questra.typesIndex, track.trackingName), metric
					end
				end
			end
		end

		track.GetIconInfo = function()
			local info = track.GetMetricInfo()
			local questID = info.questID
			
			if questID then
				local display = info.complete and Questra.iconDisplayInfo["complete"]
					or Questra.iconDisplayInfo[info.tagInfo and Enum.QuestTagType[info.tagInfo.tagName]]
					or Questra.iconDisplayInfo["normal"]

				local icon, l, r, t, b = display(info.tagInfo and info.tagInfo.tagID)
						
				local backgroundTexture, bachgroundColor = unpack(Questra.questQualityTextures[0])

				local skinDetails = {
						backgroundTexture,
						{.09, 1 - .09, .09, 1 - .09},
						{-.09, 1.09, 0 - .09, 1.09},
						{unpack(bachgroundColor or {1, 1, 1, 1})},
						{unpack(bachgroundColor or {1, 1, 1, 1})},
					}

				return skinDetails, info.position, icon, l or 0, r or 1, t or 0, b or 1, questID
			end
		end
			
		track.OnClick = function(btn)
			local info = track.GetMetricInfo()
			local id = info.questID
			if IsControlKeyDown() then
				LinkAnywhere(info.position and info.position.mapID, info.position and info.position.x, info.position and info.position.y, id)
			elseif btn == "LeftButton" then
				if (info and info.isAutoComplete) and  C_QuestLog.IsComplete(id) then
					AutoQuestPopupTracker_RemovePopUp(id)
					ShowQuestComplete(id)
				else
					local loc = id and track.GetLocation(id)
					if loc and loc.mapID ~= WorldMapFrame:GetMapID() then
						local _ = loc.mapID and OpenWorldMap(loc.mapID)
						QuestMapFrame_OpenToQuestDetails(id)
					end
					local _ = loc and PingAnywhere(loc.x, loc.y, loc.mapID)
				end
			else
				Questra.navButton.id = id
				ObjectiveTracker_ToggleDropDown(Questra.navButton, QuestObjectiveTracker_OnOpenDropDown)
				local p1, p2 = Questra.SelectProperSide(Questra.navButton)
				DropDownList1:ClearAllPoints()
				DropDownList1:SetPoint(p2, Questra.navButton, p1)
			end
		end

		track.events = {
			"SUPER_TRACKING_CHANGED",
			"ADVENTURE_MAP_QUEST_UPDATE",
			"QUEST_FINISHED",
			"QUEST_PROGRESS",
		}

		AddTracking(track)
	end
	
	do local track = {trackingName = "worldQuest", metrics = {}, scrollValue = 1,}		
		track.GetLocation = function(questID)
			local x, y, mapID = Questra:GetQuestLocation(questID)
			
			mapID = questID and C_TaskQuest.GetQuestZoneID(questID) or mapID
			
			return {x = x, y = y, mapID = mapID}
		end
		
		track.GetMetricInfo = function()
			local questID = track.metrics[track.GetScrollValue()]

			local uiMapID = Questra:GetPlayerMapID()
			
			uiMapID = (digForWorldMapID(uiMapID))
										
			local taskInfo = uiMapID and C_TaskQuest.GetQuestsForPlayerByMapID(uiMapID)
					
			-- if taskInfo then
				-- for i, info in ipairs(taskInfo) do
					-- local id = info.questID or info.questId
					if questID then
						local info = {}
						info.title =  C_QuestLog.GetTitleForQuestID(questID) 
						local _, factionID, capped, factionName = Questra:GetFactionInfo(questID)
						if factionID then
							--possibility to ignore quests from factions that you don't care about
						end
	
						info.capped = capped
						info.questID = questID
						info.factionID = factionID
						info.factionName = factionName
						info.position = track.GetLocation(questID)
						info.tradeskillLineIndex = tradeskillLineIndex
						info.complete =  C_QuestLog.IsComplete(questID)
						info.percent = GetQuestProgressBarPercent(questID)
						info.distance, info.onContinent = C_QuestLog.GetDistanceSqToQuest(questID)
						info.wayPointText = C_QuestLog.GetNextWaypointText(questID)
						info.tagInfo = questID and C_QuestLog.GetQuestTagInfo(questID)
						
						if factionID and not capped then
							local _, _, standingID, _, factionMax, factionValue = GetFactionInfoByID(factionID)
							info.standingID = standingID
							info.factionMax = factionMax
							info.factionValue = factionValue
						end

						info.objectives = info.objectives or {}
						for index = 1, C_QuestLog.GetNumQuestObjectives(questID) do
							local text, objectiveType, finished, fulfilled, required = GetQuestObjectiveInfo(questID, index, false)
							if text and not tContains(info.objectives, text) then
								tinsert(info.objectives, text)
							end
						end
					
						return info
					end
				-- end
			-- end
		end
		
		track.OnEvent = function()
			wipe(track.metrics)

			local uiMapID = Questra:GetPlayerMapID()

			uiMapID = digForWorldMapID(uiMapID)

			local taskInfo = uiMapID and C_TaskQuest.GetQuestsForPlayerByMapID(uiMapID)
			if taskInfo then
				for i, info in ipairs(taskInfo) do
					local questID = info.questID or info.questId
					if QuestUtils_IsQuestWorldQuest(questID) and HaveQuestData(questID) then
						--if C_TaskQuest.GetQuestZoneID(questID) == uiMapID then
							if not tContains(track.metrics, questID) then
								tinsert(track.metrics, questID)
							end
						--end
					end
				end
			end
			
			table.sort(track.metrics, function(a, b)
				local adist = C_QuestLog.GetDistanceSqToQuest(a)
				local bdist = C_QuestLog.GetDistanceSqToQuest(b)
		
				return (adist or math.huge) < (bdist or math.huge)
			end)

			local super = (C_SuperTrack.IsSuperTrackingQuest() and QuestUtils_IsQuestWorldQuest(C_SuperTrack.GetSuperTrackedQuestID())) and C_SuperTrack.GetSuperTrackedQuestID()
			if super then
				if not tContains(track.metrics, super) then
					tinsert(track.metrics, 1, super)
				end
			end

			return track.metrics		
		end
		
		track.ScrollMetrics = function(delta)
			track.scrollValue = track.scrollValue + delta
			track.scrollValue = track.scrollValue > #track.metrics and 1 or track.scrollValue < 1 and #track.metrics or track.scrollValue --rollover from start to finish or finish to start
		end

		track.GetScrollValue = function(delta)
			return track.scrollValue or 1
		end
		
		track.SetToMetric = function(id)
			for i, b in pairs(track.metrics) do
				if b == id then
					track.scrollValue = i
				end
			end

		end
		
		track.SetTooltip = function()
			local info = track.GetMetricInfo()
			if info then
				GameTooltip:Hide()--must be called to resize tooltip while scrolling.
				GameTooltip:SetOwner(Questra.navButton, "ANCHOR_LEFT")
				
				local color = WORLD_QUEST_QUALITY_COLORS[info.quality] or {r=1,g=1,b=1}

				if not info.title then return end
									
				GameTooltip:SetText(info.title, color.r, color.g, color.b)
				
				if Questra.portalSense then
					GameTooltip:AddLine("Take the "..Questra.portalSense.tooltip)
				end
				
				local mapInfo = C_Map.GetMapInfo(info.position.mapID)
				
				local _ = mapInfo and GameTooltip:AddLine(mapInfo.name, info.position.mapID ~= Questra:GetPlayerMapID()and unpack({1,0,0,1})) 
				
				QuestUtils_AddQuestTypeToTooltip(GameTooltip, info.questID, NORMAL_FONT_COLOR)
				
				local pMap = Questra.professionsMap[info.tagInfo and (info.tagInfo.tradeskillLineID or info.tagInfo.professionIndex)]
				
				if pMap then
					GameTooltip:AddLine(pMap, 1, 1, 1)
				end
				
				local currency = ""
				
				local factionStatus = (info.factionID and not info.capped)
					and getglobal("FACTION_STANDING_LABEL"..info.standingID) .. QUEST_DASH .. (floor((info.factionValue / info.factionMax) * 10000) / 100) .. "%"
					or ""

				if factionStatus ~= "" then
					local currencies = 0
					for i = 1, GetNumQuestLogRewardCurrencies(info.questID) do
						local _, _, numItems, currencyID = GetQuestLogRewardCurrencyInfo(i, info.questID)
						if info.factionID and C_CurrencyInfo.GetFactionGrantedByCurrency(currencyID) == info.factionID then
							currencies = currencies + numItems
						end
					end
					if currencies > 0 then
						currency = " + "..((floor(((currencies) / info.factionMax) * 10000) / 100) .. "%")
					end
				end
				
				local _ = info.factionName
					and (GameTooltip:AddDoubleLine(info.factionName, tostring(factionStatus) .. currency, unpack(color)))
				
				WorldMap_AddQuestTimeToTooltip(info.questID)

				local _ = info.wayPointText
					and GameTooltip:AddLine("    "..QUEST_DASH .. WAYPOINT_OBJECTIVE_FORMAT_OPTIONAL:format(info.wayPointText), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, true)

				for i, text in pairs(info.objectives) do
					GameTooltip:AddLine(QUEST_DASH..text, 1, 1, 1)
				end
					
				local _ = ( info.percent and info.percent > 0)
					and GameTooltip_ShowProgressBar(GameTooltip, 0, 100, info.percent, PERCENTAGE_STRING:format(info.percent))

				Questra:AddRewardsToTooltip(GameTooltip, info.questID)
				GameTooltip_CalculatePadding(GameTooltip) --must be called to resize tooltip while scrolling.
				GameTooltip:Show()
			end
		end
		
		track.ShouldShow = function()
			return #track.metrics > 0 or nil
		end
		
		track.ShouldAutoSwap = function()
			local metric  = C_SuperTrack.GetSuperTrackedQuestID()
				if metric and (metric ~= track.lastMetric) then
				track.lastMetric = metric
				if (metric ~= 0) and QuestUtils_IsQuestWorldQuest(metric) then
					return tIndexOf(Questra.typesIndex, track.trackingName), metric
				end
			end
		end

		track.GetIconInfo = function()
			local info = track.GetMetricInfo()
			if info then
				local questID = info.questID
				local display = info.complete and Questra.iconDisplayInfo["complete"]
					or Questra.iconDisplayInfo[info.tagInfo.worldQuestType]
					or Questra.iconDisplayInfo["normal"]

				local icon, l, r, t, b = display(info.tagInfo and (info.tagInfo.professionIndex or info.tagInfo.tradeskillLineID))
							
				local rarity = info.tagInfo.quality or 0
		
				local backgroundTexture, bachgroundColor = unpack(Questra.questQualityTextures[rarity] or Questra.questQualityTextures[0])
				
				local skinDetails = {
						backgroundTexture,
						{.09, 1 - .09, .09, 1 - .09},
						{-.09, 1.09, 0 - .09, 1.09},
						{unpack(bachgroundColor or {1, 1, 1, 1})},
						{unpack(bachgroundColor or {1, 1, 1, 1})},
					}
				
				return skinDetails, info.position, icon, l or 0, r or 1, t or 0, b or 1, questID
			end
		end
		
		local function BonusObjectiveTracker_OnOpenDropDown(self)
			local block = self.activeFrame;
			local questID = block.id;

			-- Add title
			local info = UIDropDownMenu_CreateInfo();
			
			info.text = C_TaskQuest.GetQuestInfoByQuestID(questID) or C_QuestLog.GetTitleForQuestID(questID)
			info.isTitle = 1;
			info.notCheckable = 1;
			UIDropDownMenu_AddButton(info, UIDROPDOWN_MENU_LEVEL);

			-- Add "stop tracking" or "start tracking"
			local watched = QuestUtils_IsQuestWatched(questID)
			
			info = UIDropDownMenu_CreateInfo();
			info.notCheckable = true;
			if not watched then
				info.text = TRACK_QUEST_ABBREV;
				info.func = function()
					BonusObjectiveTracker_TrackWorldQuest(questID);
				end
			else
			info.text = OBJECTIVES_STOP_TRACKING;
				info.func = function()
					BonusObjectiveTracker_UntrackWorldQuest(questID);
				end
			end
			UIDropDownMenu_AddButton(info, UIDROPDOWN_MENU_LEVEL);
			
			--show on map
			info = UIDropDownMenu_CreateInfo();
			info.text = OBJECTIVES_SHOW_QUEST_MAP;
			info.notCheckable = true;
			info.func = function()
				local loc = questID and track.GetLocation(questID)
				if loc and loc.mapID ~= WorldMapFrame:GetMapID() then
					local _ = loc.mapID and OpenWorldMap(loc.mapID)
					QuestMapFrame_OpenToQuestDetails(questID)
				end
				local _ = loc and PingAnywhere(loc.x, loc.y, loc.mapID)
			end
			info.arg1 = id;
			info.checked = false;
			info.noClickSound = 1;
			UIDropDownMenu_AddButton(info, UIDROPDOWN_MENU_LEVEL);
		end
		
		track.OnClick = function(btn)
			local info = track.GetMetricInfo()
			local id = info and info.questID

			if IsControlKeyDown() then
				LinkAnywhere(info.position and info.position.mapID, info.position and info.position.x, info.position and info.position.y, id)
			elseif btn == "LeftButton" then
				--local quest = QuestCache:Get(id)
				if (info and info.isAutoComplete) and  C_QuestLog.IsComplete(id) then
					AutoQuestPopupTracker_RemovePopUp(id)
					ShowQuestComplete(id)
				else
					local loc = id and track.GetLocation(id)
					if loc and loc.mapID ~= WorldMapFrame:GetMapID() then
						local _ = loc.mapID and OpenWorldMap(loc.mapID)
						QuestMapFrame_OpenToQuestDetails(id)
					end
					local _ = loc and PingAnywhere(loc.x, loc.y, loc.mapID)
				end
			elseif not C_QuestLog.IsThreatQuest(id) then
				Questra.navButton.id = id
				ObjectiveTracker_ToggleDropDown(Questra.navButton, BonusObjectiveTracker_OnOpenDropDown)
				
				local p1, p2 = Questra.SelectProperSide(Questra.navButton)
				DropDownList1:ClearAllPoints()
				DropDownList1:SetPoint(p2, Questra.navButton, p1)
			end
		end

		track.events = {
			"SUPER_TRACKING_CHANGED",
			"ADVENTURE_MAP_QUEST_UPDATE",
			"QUEST_FINISHED",
			"QUEST_PROGRESS",
		}

		AddTracking(track)
	end
	
	do local track = {trackingName = "way", metrics = {}, referenceDetails = {}, scrollValue = 1,}

		track.GetLocation = function()
			return track.metrics[track.GetScrollValue()]
		end
		
		track.GetMetricInfo = function()
			return track.metrics[track.GetScrollValue()]
		end
		
		track.OnEvent = function(event)
			local wayPoint = C_Map.GetUserWaypoint()
			local id, x, y
			
			if wayPoint and wayPoint.position then
				local id, x, y = wayPoint.uiMapID , wayPoint.position.x, wayPoint.position.y
				local metric = id..x..y
				if metric and not track.referenceDetails[metric] then
					local details = {x = floor(x*10000) / 10000 , y = floor(y*10000) / 10000 , mapID = id, tooltip = "Waypoint", icon = "way", _time = GetTime()}
					tinsert(track.metrics, 1, details)
					details.referenceDetailsIndex = metric
					track.referenceDetails[metric] = details
				end	
			end
		end
		
		track.ScrollMetrics = function(delta)
			track.scrollValue = track.scrollValue and track.scrollValue + delta or 1
			track.scrollValue = track.scrollValue > #track.metrics and 1 or track.scrollValue < 1 and #track.metrics or track.scrollValue --rollover from start to finish or finish to start
		end

		track.GetScrollValue = function(delta)
			return track.scrollValue or 1
		end
		
		track.SetToMetric = function(id)
			track.scrollValue = id
		end
		
		track.SetTooltip = function()
		
			local userPoint = track.GetMetricInfo()
			if userPoint then
				local id, x, y = userPoint.mapID , userPoint.x, userPoint.y
				if id and x and y then	
		
					GameTooltip:SetOwner(Questra.navButton, "ANCHOR_LEFT")
						
					if userPoint.tooltip then
						GameTooltip:SetText(userPoint.tooltip, 1, 1, 1)
					else
						GameTooltip:SetText("Waypoint", 1, 1, 1)
						GameTooltip:AddLine("Were you going somewhere?", 1, 1, 1)
					end 


					if Questra.portalSense then
						GameTooltip:AddLine("Take the "..Questra.portalSense.tooltip)
					end

					local mapInfo = C_Map.GetMapInfo(tonumber(id))
					
					if Questra.portalSense then
						GameTooltip:AddLine("Take the "..Questra.portalSense.tooltip)
					end				
					
					
					if userPoint.title then
						GameTooltip:AddDoubleLine(userPoint.title)
					end
					GameTooltip:AddDoubleLine(mapInfo.name..":", x*100 .. ", ".. y  * 100)
					
					GameTooltip_CalculatePadding(GameTooltip) --must be called to resize tooltip while scrolling.
					GameTooltip:Show()
				end
			end
		end
		
		track.ShouldShow = function()
			return #track.metrics > 0 or nil
		end
		
		track.ShouldAutoSwap = function()
			local m1, m2 = C_SuperTrack.GetSuperTrackedQuestID(), C_Map.GetUserWaypoint()
			local id, x, y
			
			if m2 and m2.position then
				id, x, y = m2.uiMapID , m2.position.x, m2.position.y
				m2 = id..x..y
			end
			
			m1Changed = m1 and m1 ~= track.lastMetric or nil
			m2Changed = m2 and m2 ~= track.lastMetric2 or nil
						
			if m1Changed or m2Changed then
				track.lastMetric = m1Changed and m1 or track.lastMetric
				track.lastMetric2 = m2Changed and m2 or track.lastMetric2
				if m2Changed or (m1Changed and ((m1 == 0) or (m1 == nil))) then
					track.OnEvent()	
					if m1Changed and ((m1 == 0) or (m1 == nil)) then
						local index = (metric and track.referenceDetails[metric]) and tIndexOf(track.metrics, track.referenceDetails[metric])
						local _ = index and track.SetToMetric(index)
					end
					return true
				end
			end
		end

		track.GetIconInfo = function()
			local userPoint = track.GetMetricInfo()
			if userPoint then
				local id, x, y = userPoint.mapID , userPoint.x, userPoint.y
				if id and x and y then
				
					local icon = (userPoint.icon == "raid") and Enum.QuestTagType.Raid
						or (userPoint.icon == "dungeon") and Enum.QuestTagType.Dungeon
						or userPoint.icon


					return Questra.basicSkin, {x = x, y = y, mapID = id}, Questra.iconDisplayInfo[icon]()
				end
			end
		end
		
		track.OnClick = function(btn)
			if IsControlKeyDown() then
				local userPoint = track.GetLocation()
				LinkAnywhere(userPoint.mapID, userPoint.x, userPoint.y)
			elseif btn == "LeftButton" then
				local userPoint = track.GetLocation()
				if userPoint then
					local id, x, y = userPoint.mapID , userPoint.x, userPoint.y
					
					if track.portal then
					
					
						x = track.portal.x or track.portal.origin and track.portal.origin.x
						y = track.portal.y or track.portal.origin and track.portal.origin.y
						id = track.portal.mapID or track.portal.origin and track.portal.origin.mapID
					end
					
					
					if id and x and y then
						PingAnywhere(x, y, id)
					end
				end
			else
				local toRemove = track.GetScrollValue()
				if track.metrics[toRemove] then
					track.referenceDetails[track.metrics[toRemove].referenceDetailsIndex] = nil
					tremove(track.metrics, toRemove)
					Questra:UpdateDisplayed("Forced")
					if #track.metrics == 0 then
						Questra:SetTracking()
					end
					Questra:CollectUpdate()
					Questra:Update()
				end
			end
		end
		
		track.events = {
			--"WAYPOINT_UPDATE",
			"USER_WAYPOINT_UPDATED",
			"ZONE_CHANGED",
			"ZONE_CHANGED_INDOORS",
		}
		
		-- track.SetByPin = function(pin, wayType)
			-- local id, x, y = pin.owningMap.mapID, pin.normalizedX, pin.normalizedY
			-- local name = pin.name 
			-- --local instanceID = pin.journalInstanceID
			-- local description = pin.description or "Flight"
			-- local icon = (pin.description) and string.lower(pin.description) or "flight"
			-- icon = string.gsub(icon, " ", "")
			-- local metric = id..x..y
			
			-- if metric and not track.referenceDetails[metric] then
				-- local details = {x = floor(x*10000) / 10000 , y = floor(y*10000) / 10000 , mapID = id, title = name, tooltip = description, icon = icon, _time = GetTime()}
				-- tinsert(track.metrics, 1, details)
				-- details.referenceDetailsIndex = metric
				-- track.referenceDetails[metric] = details
				-- track.SetToMetric(tIndexOf(track.metrics, details))
			-- else
				-- local index = (metric and track.referenceDetails[metric]) and tIndexOf(track.metrics, track.referenceDetails[metric])
				-- local _ = index and track.SetToMetric(index)
			-- end	

			-- Questra:UpdateDisplayed("Forced")
			-- Questra:SetTracking(tIndexOf(Questra.typesIndex, track.trackingName))
			-- Questra:CollectUpdate()
		-- end
		
		AddTracking(track)
	end

	do local track = {trackingName = "flight", metrics = {}, referenceDetails = {}, scrollValue = 1,}

		track.GetLocation = function()
			return track.metrics[track.GetScrollValue()]
		end
		
		track.GetMetricInfo = function()
			return track.metrics[track.GetScrollValue()]
		end
		
		track.OnEvent = function()

		end
		
		track.ScrollMetrics = function(delta)
			track.scrollValue = track.scrollValue and track.scrollValue + delta or 1
			track.scrollValue = track.scrollValue > #track.metrics and 1 or track.scrollValue < 1 and #track.metrics or track.scrollValue --rollover from start to finish or finish to start
		end

		track.GetScrollValue = function(delta)
			return track.scrollValue or 1
		end
		
		track.SetToMetric = function(id)
			track.scrollValue = id
		end
		
		track.SetTooltip = function()
		
			local userPoint = track.GetMetricInfo()
			if userPoint then
				local id, x, y = userPoint.mapID , userPoint.x, userPoint.y
				if id and x and y then	
		
					GameTooltip:SetOwner(Questra.navButton, "ANCHOR_LEFT")
					GameTooltip:SetText("Flight Point", 1, 1, 1)
					
					if Questra.portalSense then
						GameTooltip:AddLine("Take the "..Questra.portalSense.tooltip)
					end	
					
					local mapInfo = C_Map.GetMapInfo(tonumber(id))
										
					if userPoint.title then
						GameTooltip:AddDoubleLine(userPoint.title)
					end
					GameTooltip:AddDoubleLine(mapInfo.name..":", x*100 .. ", ".. y  * 100)
					
					GameTooltip_CalculatePadding(GameTooltip) --must be called to resize tooltip while scrolling.
					GameTooltip:Show()
				end
			end
		end
		
		track.ShouldShow = function()
			return #track.metrics > 0 or nil
		end
		
		track.ShouldAutoSwap = function()

		end

		track.GetIconInfo = function()
			local userPoint = track.GetMetricInfo()
			if userPoint then
				local id, x, y = userPoint.mapID , userPoint.x, userPoint.y
				if id and x and y then
				
					local icon = (userPoint.icon == "raid") and Enum.QuestTagType.Raid
						or (userPoint.icon == "dungeon") and Enum.QuestTagType.Dungeon
						or userPoint.icon

					return Questra.basicSkin, {x = x, y = y, mapID = id}, Questra.iconDisplayInfo[icon]()
				end
			end
		end
		
		track.OnClick = function(btn)
			if IsControlKeyDown() then
				local userPoint = track.GetLocation()
				LinkAnywhere(userPoint.mapID, userPoint.x, userPoint.y)
			elseif btn == "LeftButton" then
				local userPoint = track.GetLocation()
				if userPoint then
					local id, x, y = userPoint.mapID , userPoint.x, userPoint.y
					if id and x and y then	
						PingAnywhere(x, y, id)
					end
				end
			else
				local toRemove = track.GetScrollValue()
				if track.metrics[toRemove] then
					track.referenceDetails[track.metrics[toRemove].referenceDetailsIndex] = nil
					tremove(track.metrics, toRemove)
					Questra:UpdateDisplayed("Forced")
					if #track.metrics == 0 then
						Questra:SetTracking()
					end
					Questra:CollectUpdate()
					Questra:Update()
				end
			end
		end
		
		track.SetByPin = function(pin, wayType)
			local id, x, y = pin.owningMap.mapID, pin.normalizedX, pin.normalizedY
			local name = pin.name 
			--local instanceID = pin.journalInstanceID
			local description = pin.description or "Flight"
			local icon = (pin.description) and string.lower(pin.description) or "flight"
			icon = string.gsub(icon, " ", "")
			local metric = id..x..y
			
			if metric and not track.referenceDetails[metric] then
				local details = {x = floor(x*10000) / 10000 , y = floor(y*10000) / 10000 , mapID = id, title = name, tooltip = description, icon = icon, _time = GetTime()}
				tinsert(track.metrics, 1, details)
				details.referenceDetailsIndex = metric
				track.referenceDetails[metric] = details
				track.SetToMetric(tIndexOf(track.metrics, details))
			else
				local index = (metric and track.referenceDetails[metric]) and tIndexOf(track.metrics, track.referenceDetails[metric])
				local _ = index and track.SetToMetric(index)
			end	

			Questra:UpdateDisplayed("Forced")
			Questra:SetTracking(tIndexOf(Questra.typesIndex, track.trackingName))
			Questra:CollectUpdate()
		end
		
		AddTracking(track)
	end

	do-- local track = {trackingName = "dungeon", metrics = {}, referenceDetails = {}, scrollValue = 1,}

		-- track.GetLocation = function()
			-- return track.metrics[track.GetScrollValue()]
		-- end
		
		-- track.GetMetricInfo = function()
			-- return track.metrics[track.GetScrollValue()]
		-- end
		
		-- track.OnEvent = function()

		-- end
		
		-- track.ScrollMetrics = function(delta)
			-- track.scrollValue = track.scrollValue and track.scrollValue + delta or 1
			-- track.scrollValue = track.scrollValue > #track.metrics and 1 or track.scrollValue < 1 and #track.metrics or track.scrollValue --rollover from start to finish or finish to start
		-- end

		-- track.GetScrollValue = function(delta)
			-- return track.scrollValue or 1
		-- end
		
		-- track.SetToMetric = function(id)
			-- track.scrollValue = id
		-- end
		
		-- track.SetTooltip = function()
		
			-- local userPoint = track.GetMetricInfo()
			-- if userPoint then
				-- local id, x, y = userPoint.mapID , userPoint.x, userPoint.y
				-- if id and x and y then	
		
					-- GameTooltip:SetOwner(Questra.navButton, "ANCHOR_LEFT")
						
					-- GameTooltip:SetText(userPoint.tooltip or "Instance", 1, 1, 1)
					
					-- if Questra.portalSense then
						-- GameTooltip:AddLine("Take the "..Questra.portalSense.tooltip)
					-- end

					
					-- local mapInfo = C_Map.GetMapInfo(tonumber(id))
										
					-- if userPoint.title then
						-- GameTooltip:AddDoubleLine(userPoint.title)
					-- end
					-- GameTooltip:AddDoubleLine(mapInfo.name..":", x*100 .. ", ".. y  * 100)
					
					-- GameTooltip_CalculatePadding(GameTooltip) --must be called to resize tooltip while scrolling.
					-- GameTooltip:Show()
				-- end
			-- end
		-- end
		
		-- track.ShouldShow = function()
			-- return #track.metrics > 0 or nil
		-- end
		
		-- track.ShouldAutoSwap = function()

		-- end

		-- track.GetIconInfo = function()
			-- local userPoint = track.GetMetricInfo()
			-- if userPoint then
				-- local id, x, y = userPoint.mapID , userPoint.x, userPoint.y
				-- if id and x and y then
				
					-- local icon = (userPoint.icon == "raid") and Enum.QuestTagType.Raid
						-- or (userPoint.icon == "dungeon") and Enum.QuestTagType.Dungeon
						-- or userPoint.icon

					-- return Questra.basicSkin, {x = x, y = y, mapID = id}, Questra.iconDisplayInfo[icon]()
				-- end
			-- end
		-- end
		
		-- track.OnClick = function(btn)
			-- if btn == "LeftButton" then
				-- local userPoint = track.GetLocation()
				-- if userPoint then
					-- local id, x, y = userPoint.mapID , userPoint.x, userPoint.y
					-- if id and x and y then	
						-- PingAnywhere(x, y, id)
					-- end
				-- end
			-- else
				-- local toRemove = track.GetScrollValue()
				-- if track.metrics[toRemove] then
					-- track.referenceDetails[track.metrics[toRemove].referenceDetailsIndex] = nil
					-- tremove(track.metrics, toRemove)
					-- Questra:UpdateDisplayed("Forced")
					-- if #track.metrics == 0 then
						-- Questra:SetTracking()
					-- end
					-- Questra:CollectUpdate()
					-- Questra:Update()
				-- end
			-- end
		-- end
		
		-- track.SetByPin = function(pin, wayType)
			-- local id, x, y = pin.owningMap.mapID, pin.normalizedX, pin.normalizedY
			-- local name = pin.name 
			-- --local instanceID = pin.journalInstanceID
			-- local description = pin.description or "Dungeon"
			-- local icon = (pin.description) and string.lower(pin.description) or "dungeon"
			-- icon = string.gsub(icon, " ", "")
			-- local metric = id..x..y
			
			-- if metric and not track.referenceDetails[metric] then
				-- local details = {x = floor(x*10000) / 10000 , y = floor(y*10000) / 10000 , mapID = id, title = name, tooltip = description, icon = icon, _time = GetTime()}
				-- tinsert(track.metrics, 1, details)
				-- details.referenceDetailsIndex = metric
				-- track.referenceDetails[metric] = details
				-- track.SetToMetric(tIndexOf(track.metrics, details))
			-- else
				-- local index = (metric and track.referenceDetails[metric]) and tIndexOf(track.metrics, track.referenceDetails[metric])
				-- local _ = index and track.SetToMetric(index)
			-- end	

			-- Questra:UpdateDisplayed("Forced")
			-- Questra:SetTracking(tIndexOf(Questra.typesIndex, track.trackingName))
			-- Questra:CollectUpdate()
		-- end
		
		-- AddTracking(track)
	 end
	
	do local track = {trackingName = "offer", metrics = {}, referenceDetails = {}, scrollValue = 1,}

		track.GetLocation = function()
			return track.metrics[track.GetScrollValue()]
		end
		
		track.GetMetricInfo = function()
			return track.metrics[track.GetScrollValue()]
		end
		
		track.OnEvent = function()

		end
		
		track.ScrollMetrics = function(delta)
			track.scrollValue = track.scrollValue and track.scrollValue + delta or 1
			track.scrollValue = track.scrollValue > #track.metrics and 1 or track.scrollValue < 1 and #track.metrics or track.scrollValue --rollover from start to finish or finish to start
		end

		track.GetScrollValue = function(delta)
			return track.scrollValue or 1
		end
		
		track.SetToMetric = function(id)
			track.scrollValue = id
		end
		
		track.SetTooltip = function()
		
			local userPoint = track.GetMetricInfo()
			if userPoint then
				local id, x, y = userPoint.mapID , userPoint.x, userPoint.y
				if id and x and y then	
		
					GameTooltip:SetOwner(Questra.navButton, "ANCHOR_LEFT")
					GameTooltip:SetText(userPoint.title)
						
					if Questra.portalSense then
						GameTooltip:AddLine("Take the "..Questra.portalSense.tooltip)
					end
						
					if userPoint.tooltip then
						GameTooltip:AddLine(userPoint.tooltip, 1, 1, 1)
					end 
					
					local mapInfo = C_Map.GetMapInfo(tonumber(id))
										
					GameTooltip:AddDoubleLine(mapInfo.name..":", x*100 .. ", ".. y  * 100)
					
					GameTooltip_CalculatePadding(GameTooltip) --must be called to resize tooltip while scrolling.
					GameTooltip:Show()
				end
			end
		end
		
		track.ShouldShow = function()
			return #track.metrics > 0 or nil
		end
		
		track.ShouldAutoSwap = function()

		end

		track.GetIconInfo = function()
			local userPoint = track.GetMetricInfo()
			if userPoint then
				local id, x, y = userPoint.mapID , userPoint.x, userPoint.y
				if id and x and y then
					return Questra.basicSkin, {x = x, y = y, mapID = id}, Questra.iconDisplayInfo[userPoint.icon]()
				end
			end
		end
		
		track.OnClick = function(btn)
			if IsControlKeyDown() then
				local userPoint = track.GetLocation()
				LinkAnywhere(userPoint.mapID, userPoint.x, userPoint.y)
			elseif btn == "LeftButton" then
				local userPoint = track.GetLocation()
				if userPoint then
					local id, x, y = userPoint.mapID , userPoint.x, userPoint.y
					if id and x and y then	
						PingAnywhere(x, y, id)
					end
				end
				
				
			else
				local toRemove = track.GetScrollValue()
				if track.metrics[toRemove] then
					track.referenceDetails[track.metrics[toRemove].referenceDetailsIndex] = nil
					tremove(track.metrics, toRemove)
					Questra:UpdateDisplayed("Forced")
					if #track.metrics == 0 then
						Questra:SetTracking()
					end
					Questra:CollectUpdate()
					Questra:Update()
				end
			end
		end
		
		track.SetByPin = function(pin, wayType)
			local id, x, y = pin.owningMap.mapID, pin.normalizedX, pin.normalizedY

			local metric = id..x..y
			
			if metric and not track.referenceDetails[metric] then
				local questID = pin.questID
				local icon = "normal"

				local description
				local name = AVAILABLE_QUEST

				local questInfo = C_QuestLine.GetQuestLineInfo(questID, id)
				if questInfo then
					description = name
					name = questInfo.questName


					local inf = C_QuestLog.GetQuestTagInfo(questID)
					local qType =  inf and inf.tagName

					icon = ((questInfo.isDaily == true)       and "daily")
						or ((questInfo.isLegendary == true)   and "legendary")
						or ((questInfo.isHidden == true)      and "trivial")
						or ((QuestUtil.ShouldQuestIconsUseCampaignAppearance(questID) == true) and "campaign")
						or icon
				end
			
				local details = {x = floor(x*10000) / 10000 , y = floor(y*10000) / 10000 , mapID = id, title = name, tooltip = description, icon = icon, _time = GetTime(), questID = pin.questID, qType = qType}
				tinsert(track.metrics, 1, details)
				details.referenceDetailsIndex = metric
				track.referenceDetails[metric] = details
				track.SetToMetric(tIndexOf(track.metrics, details))
			else
				local index = (metric and track.referenceDetails[metric]) and tIndexOf(track.metrics, track.referenceDetails[metric])
				local _ = index and track.SetToMetric(index)
			end	

			Questra:UpdateDisplayed("Forced")
			Questra:SetTracking(tIndexOf(Questra.typesIndex, track.trackingName))
			Questra:CollectUpdate()
		end
		
		AddTracking(track)
	end
	
	do local track = {trackingName = "other", metrics = {}, referenceDetails = {}, scrollValue = 1,}
		track.GetLocation = function()
			return track.metrics[track.GetScrollValue()]
		end
		
		track.GetMetricInfo = function()
			return track.metrics[track.GetScrollValue()]
		end
		
		track.OnEvent = function()

		end
		
		track.ScrollMetrics = function(delta)
			track.scrollValue = track.scrollValue and track.scrollValue + delta or 1
			track.scrollValue = track.scrollValue > #track.metrics and 1 or track.scrollValue < 1 and #track.metrics or track.scrollValue --rollover from start to finish or finish to start
		end

		track.GetScrollValue = function(delta)
			return track.scrollValue or 1
		end
		
		track.SetToMetric = function(id)
			track.scrollValue = id
		end
		
		track.SetTooltip = function()
		
			local userPoint = track.GetMetricInfo()
			if userPoint then
				if userPoint.questID then
					local info = userPoint
					--if info and info.title then
						GameTooltip:Hide()
						GameTooltip:SetOwner(Questra.navButton, "ANCHOR_LEFT")

						GameTooltip:SetText(info.title, info.difficultyColor.r, info.difficultyColor.g, info.difficultyColor.b)

						if Questra.portalSense then
							GameTooltip:AddLine("Take the "..Questra.portalSense.tooltip)
						end

						local mapInfo = info.position and info.position.mapID and C_Map.GetMapInfo(info.position.mapID) or info.mapID and C_Map.GetMapInfo(info.mapID)
						local _ = mapInfo and GameTooltip:AddLine(mapInfo.name, (info.position and info.position.mapID or info.mapID) ~= Questra:GetPlayerMapID()and unpack({1,0,0,1})) 

						QuestUtils_AddQuestTypeToTooltip(GameTooltip, info.questID, NORMAL_FONT_COLOR)

						local _ = info.questDescription and GameTooltip:AddLine(info.questDescription, 1, 1, 1, true)
						local _ = info.questDescription and GameTooltip_AddBlankLinesToTooltip(GameTooltip, 1)

						for i, text in pairs(info.objectives) do
							local text, r, g, b, bool = text, 1, 1, 1, true
							if type(text) == "table" then
								text, r, b, g, bool = unpack(text)
							end
						
							if text ~= info.questDescription then
								GameTooltip:AddLine(QUEST_DASH..text, r, g, b, bool)
							end
						end
											
						local _ = ( info.percent and info.percent > 0) and GameTooltip_ShowProgressBar(GameTooltip, 0, 100, info.percent, PERCENTAGE_STRING:format(info.percent))

						Questra:AddRewardsToTooltip(GameTooltip, info.questID)
						
						GameTooltip_CalculatePadding(GameTooltip) --must be called to resize tooltip while scrolling.
						GameTooltip:Show()
					--end
				else
				
					local id, x, y = userPoint.mapID , userPoint.x, userPoint.y
					if id and x and y then	
			
						GameTooltip:SetOwner(Questra.navButton, "ANCHOR_LEFT")
							
						GameTooltip:SetText(userPoint.tooltip or "Instance", 1, 1, 1)
						
						if Questra.portalSense then
							GameTooltip:AddLine("Take the "..Questra.portalSense.tooltip)
						end

						
						local mapInfo = C_Map.GetMapInfo(tonumber(id))
											
						if userPoint.title then
							GameTooltip:AddDoubleLine(userPoint.title)
						end
						GameTooltip:AddDoubleLine(mapInfo.name..":", x*100 .. ", ".. y  * 100)
						
						GameTooltip_CalculatePadding(GameTooltip) --must be called to resize tooltip while scrolling.
						GameTooltip:Show()
					end
				end
			end
		end
		
		track.ShouldShow = function()
			return #track.metrics > 0 or nil
		end
		
		track.ShouldAutoSwap = function()

		end

		track.GetIconInfo = function()
			local userPoint = track.GetMetricInfo()
			if userPoint then
				local id, x, y = userPoint.mapID , userPoint.x, userPoint.y
				if id and x and y then
					local icon = userPoint.icon
					if userPoint.questID then
						local questID = userPoint.questID

						local info = userPoint
						local display = info.complete and Questra.iconDisplayInfo["complete"]
							or Questra.iconDisplayInfo[info.tagInfo and Enum.QuestTagType[info.tagInfo.tagName]]
							or Questra.iconDisplayInfo["normal"]
							
						local icon, l, r, t, b = display(info.tagInfo and info.tagInfo.tagID)
								
						local backgroundTexture, bachgroundColor = unpack(Questra.questQualityTextures[0])

						local skinDetails = {
								backgroundTexture,
								{.09, 1 - .09, .09, 1 - .09},
								{-.09, 1.09, 0 - .09, 1.09},
								{unpack(bachgroundColor or {1, 1, 1, 1})},
								{unpack(bachgroundColor or {1, 1, 1, 1})},
							}

						return skinDetails, info.position or info, icon, l or 0, r or 1, t or 0, b or 1, questID
					elseif type(icon) ~= "table" then
						return Questra.basicSkin, {x = x, y = y, mapID = id}, Questra.iconDisplayInfo[icon] and Questra.iconDisplayInfo[icon]()
					else
					
					
						local icon, coord, isTexture = unpack(icon)
						local l, r, t, b = unpack(coord)
						return Questra.basicSkin, {x = x, y = y, mapID = id}, icon, l, r, t, b, isTexture
					end
				end
			end
		end
		
		track.OnClick = function(btn)
			if IsControlKeyDown() then
				local userPoint = track.GetLocation()
				LinkAnywhere(userPoint.mapID, userPoint.x, userPoint.y)
			elseif btn == "LeftButton" then
				local userPoint = track.GetLocation()
				if userPoint then
					local id, x, y = userPoint.mapID , userPoint.x, userPoint.y
					if id and x and y then	
						PingAnywhere(x, y, id)
					end
				end
			else
				local toRemove = track.GetScrollValue()
				if track.metrics[toRemove] then
					track.referenceDetails[track.metrics[toRemove].referenceDetailsIndex] = nil
					tremove(track.metrics, toRemove)
					Questra:UpdateDisplayed("Forced")
					if #track.metrics == 0 then
						Questra:SetTracking()
					end
					Questra:CollectUpdate()
					Questra:Update()
				end
			end
		end
		
		local templateToTrackingType = {
			PetTamerPinTemplate = Enum.QuestTagType.PetBattle,
			DigSitePinTemplate  = "dig",
			[197] = "treasure",
			[196] = Enum.QuestTagType.PetBattle,
			[177] = "dig",
			Dungeon = Enum.QuestTagType.Dungeon,
			Raid = Enum.QuestTagType.Raid,
			QuestDaily = "daily",
			QuestNormal = "normal",
		}
		
		track.SetByPin = function(pin, wayType, template)
			local id, x, y = pin.owningMap.mapID, pin.normalizedX, pin.normalizedY
			
			local texture = pin.Texture and (pin.Texture:GetTexture())
			local atlas = pin.Texture and (pin.Texture:GetAtlas())

			local iconType, iconTexture, iconCoords

			if  pin:GetNumRegions() > 0 then
				for o, l in pairs({pin:GetRegions()}) do
					if type(l) == "table" then
					
						if l.GetTexture and l:GetTexture() and not iconType then
							iconTexture = l:GetTexture()
							iconType = "texture"
							iconCoords = {l:GetTexCoord()}
						end					
						if l.GetAtlas and l:GetAtlas()  and iconType ~= "atlas"then
							iconTexture = l:GetAtlas()
							iconType = "atlas"
							iconCoords = {l:GetTexCoord()}
						end
					end				
				end
			end

			if  pin:GetNumChildren() > 0 then
				for o, l in pairs({pin:GetChildren()}) do
					if type(l) == "table" then
					
						if l.GetTexture and l:GetTexture() and not iconType then
							iconTexture = l:GetTexture()
							iconType = "texture"
							iconCoords = {l:GetTexCoord()}
						end					
						if l.GetAtlas and l:GetAtlas()  and iconType ~= "atlas"then
							iconTexture = l:GetAtlas()
							iconType = "atlas"
							iconCoords = {l:GetTexCoord()}
						end
					end				
				end
			end
			
			prin(iconType, iconTexture)
			
			local det = unpack(pin.__details)
					


			local poiInfo = (type(det) == "table") and det or nil

			local name = pin.name 
			--local instanceID = pin.journalInstanceID
			local description = poiInfo and poiInfo.name or "Other"
			
	
			
			local icon = iconTexture or "way"

			local coord = iconCoords or {0,1,0,1}
			
			
			local atlas
			
			if iconType == "atlas" then
				atlas = icon
			end
			
			local pinTexture = templateToTrackingType[icon] or atlas or {icon, coord} 
			
			local metric = id..x..y
			if metric and not track.referenceDetails[metric] then
				local details = {x = floor(x*10000) / 10000 , y = floor(y*10000) / 10000 , mapID = id, title = name, tooltip = description, icon = pinTexture, _time = GetTime(), questID = pin.questID}
				local questID = pin.questID

				if questID then
					local info = details
					--[[info = {
							title,
							questLogIndex,
							questID,
							campaignID,
							level,
							difficultyLevel,
							suggestedGroup,
							frequency,  -- QuestFrequency
							isHeader,
							isCollapsed,
							startEvent,
							isTask,
							isBounty,
							isStory,
							isScaling,
							isOnMap,
							hasLocalPOI,
							isHidden,
							isAutoComplete,
							overridesSortOrder,
							readyForTranslation,
						}
					--]]

				local waytext = C_QuestLog.GetNextWaypointText(questID)

				info.objectives = info.objectives or {}
				
				wayText =  waytext and WAYPOINT_OBJECTIVE_FORMAT_OPTIONAL:format(waytext)
				if waytext and not tContains(info.objectives, wayText) then
					tinsert(info.objectives, wayText)
				end
				
				for index = 1, C_QuestLog.GetNumQuestObjectives(questID) do
					local text, objectiveType, finished, fulfilled, required = GetQuestObjectiveInfo(questID, index, false)
					if text and not tContains(info.objectives, text) then
						tinsert(info.objectives, text)
					end
				end
				
				info.difficultyColor  = GetDifficultyColor(C_PlayerInfo.GetContentDifficultyQuestForPlayer(questID))
				info.distance, info.onContinent = C_QuestLog.GetDistanceSqToQuest(questID)
				info.percent = GetQuestProgressBarPercent(questID)	
				info.complete = C_QuestLog.IsComplete(questID)
				info.position = track.GetLocation(questID)
				info.tagInfo = C_QuestLog.GetQuestTagInfo(questID)
				
				local questTitle, factionID, capped, displayAsObjective = C_TaskQuest.GetQuestInfoByQuestID(questID)		
						
				info.title = questTitle
				info.factionID = factionID
				info.capped = capped
				info.displayAsObjective = displayAsObjective
						
			end

				tinsert(track.metrics, 1, details)
				details.referenceDetailsIndex = metric
				track.referenceDetails[metric] = details
				track.SetToMetric(tIndexOf(track.metrics, details))
			else
				local index = (metric and track.referenceDetails[metric]) and tIndexOf(track.metrics, track.referenceDetails[metric])
				local _ = index and track.SetToMetric(index)
			end	

			Questra:UpdateDisplayed("Forced")
			Questra:SetTracking(tIndexOf(Questra.typesIndex, track.trackingName))
			Questra:CollectUpdate()
		end
		
		AddTracking(track)
	end
end

do --hook map pins
	local pinToTrackingType = {
		["WayPointLocationPinTemplate"] = "way",
		["WorldMap_WorldQuestPinTemplate"] = "worldQuest",
		["QuestPinTemplate"] = "Quest",
		["StorylineQuestPinTemplate"] = "offer",
		["CorpsePinTemplate"] = "dead",
		["FlightPointPinTemplate"] = "flight",
		--["DungeonEntrancePinTemplate"] = "dungeon",
		["Other"] = "other",
	}

	local tempClicks = {
		["FlightPointPinTemplate"] = "flight",
		["DungeonEntrancePinTemplate"] = "dungeon",
	}

	function Questra:PinClickSetTracking(pin, pinTemplateName, template)
		local trackingName = pinToTrackingType[pinTemplateName]
		local tracker = trackingName and Questra.trackByName[trackingName]

		if tracker then
			if tracker.SetByPin then
				Questra:UpdateAutoTracking()
				tracker.SetByPin(pin, pinTemplateName, template)
			end
		else
			if trackingName then
				--if tempClicks[pinTemplateName] then
					local tracker =  Questra.trackByName["other"]
				
					Questra:UpdateAutoTracking()
					tracker.SetByPin(pin, trackingName, template)
				--end
			end
		end	
	end

	function Questra:HookMapPins()
		local map = WorldMapFrame
		if not map.oldAcquirePin then
			map.oldAcquirePin = map.AcquirePin
			function map:AcquirePin(pinTemplateName, ...)
				local pin = map:oldAcquirePin(pinTemplateName, ...)
				pin.__details = {...}
				if pinToTrackingType[pinTemplateName] then
					if not pin.Hooked then
						pin.Hooked = true
						if pin.OnMouseClickAction then
							pin.oldOnMouseClickAction = pin.OnMouseClickAction
							function pin:OnMouseClickAction(btn, ...)
								if btn == "LeftButton" then
									return pin:oldOnMouseClickAction(...)
								else
									Questra:PinClickSetTracking(pin, pinTemplateName)
								end
							end
						else
							if pin:HasScript("OnMouseUp") then
								pin:HookScript("OnMouseUp", function()
									Questra:PinClickSetTracking(pin, pinTemplateName)
								end)
							else
								pin:SetScript("OnMouseUp", function()
									Questra:PinClickSetTracking(pin, pinTemplateName)
								end)
							end
						end
					end
				else
					if not pin.Hooked then
						pin.Hooked = true
						if pin.OnMouseClickAction then
							pin.oldOnMouseClickAction = pin.OnMouseClickAction
							function pin:OnMouseClickAction(btn, ...)
								if btn == "LeftButton" then
									return pin:oldOnMouseClickAction(...)
								else
									Questra:PinClickSetTracking(pin, "Other", pinTemplateName)
								end
							end
						else
							if pin:HasScript("OnMouseUp") then
								pin:HookScript("OnMouseUp", function()
									Questra:PinClickSetTracking(pin, "Other", pinTemplateName)
								end)
							else
								pin:SetScript("OnMouseUp", function()
									Questra:PinClickSetTracking(pin, "Other", pinTemplateName)
									
								end)
							end
						end
					end
				end
				return pin
			end
		end
	end
end

do --portal  transit system!
	local storedIDs = {}
	local mapOverrides = { --maps that must be considered there own world map for portal reasons
		[875] = true,
		[876] = true,
		[619] = true,
		[424] = true,
		[1355] = true,
		[905] = true,
		[948] = true,
		[12] = true,
		[13] = true,
		[113] = true,
		[1543] = true,
		[203] = true,
		[1670] = true,
		--[1671] = true,
	}	
	local function GetZoneIDs(baseID) --get parent zone IDS for baseID
		if baseID and not storedIDs[baseID] then
			local _ids = {baseID}
			local info = C_Map.GetMapInfo(baseID)
			local count 
			while info do
				local parentInfo = C_Map.GetMapInfo(info.parentMapID)
				if parentInfo then
					if (info.parentMapID and tContains(_ids, info.parentMapID) or (parentInfo.mapType == Enum.UIMapType.Cosmic)) then
						break --we've hit a repeat id or the cosmic map
					end
					 if (not mapOverrides[info.mapID]) 
					 and ((parentInfo.mapType ~= Enum.UIMapType.World) 
					 and (parentInfo.mapType ~= Enum.UIMapType.Cosmic))
					 and not tContains(_ids, info.parentMapID) then
					
						local _ = info.parentMapID and tinsert(_ids, info.parentMapID)
					end
				end
				info = parentInfo
			end
			storedIDs[baseID] = _ids --store it, so we don't have to dig for this ID again
		end
		return baseID and storedIDs[baseID] or {}--return then stored id
	end
	Questra.GetZoneIDs = GetZoneIDs

	--List all known portals(no alliance only data has been collected yet.)
	local networkLocations = {
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.37890044201114,
				mapID = 85,
				x = 0.50135588842975,
			},
			origin = {
				y = 0.57890164852142,
				x = 0.33675336837769,
				mapID = 619,
			},
		}, -- [1]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.89813858019974,
				mapID = 85,
				x = 0.57103620194035,
			},
			origin = {
				y = 0.5475,
				x = 0.2089,
				mapID = 1670,
			},
		}, -- [2]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.89813858019974,
				mapID = 85,
				x = 0.57103620194035,
			},
			origin = {
				y = 0.098700038554703,
				x = 0.63762695780944,
				mapID = 1530,
			},
		}, -- [3]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.89813858019974,
				mapID = 85,
				x = 0.57103620194035,
			},
			origin = {
				y = 0.14021435795428,
				x = 0.28511899099554,
				mapID = 371,
			},
		}, -- [4]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.89813858019974,
				mapID = 85,
				x = 0.57103620194035,
			},
			origin = {
				y = 0.41296159312871,
				x = 0.46663798048915,
				mapID = 630,
			},
		}, -- [5]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.89813858019974,
				mapID = 85,
				x = 0.57103620194035,
			},
			origin = {
				y = 0.2395178315967,
				x = 0.55211635002278,
				mapID = 627,
			},
		}, -- [6]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.89813858019974,
				mapID = 85,
				x = 0.57103620194035,
			},
			origin = {
				y = 0.267044943523,
				x = 0.58198599758397,
				mapID = 74,
			},
		}, -- [7]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.89813858019974,
				mapID = 85,
				x = 0.57103620194035,
			},
			origin = {
				y = 0.24446088576159,
				x = 0.63479490345888,
				mapID = 198,
			},
		}, -- [8]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.89813858019974,
				mapID = 85,
				x = 0.57103620194035,
			},
			origin = {
				y = 0.25476156859977,
				x = 0.55301410416057,
				mapID = 125,
			},
		}, -- [9]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.89813858019974,
				mapID = 85,
				x = 0.57103620194035,
			},
			origin = {
				y = 0.70166727701823,
				x = 0.73611111111111,
				mapID = 1163,
			},
		}, -- [10]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.89813858019974,
				mapID = 85,
				x = 0.57103620194035,
			},
			origin = {
				y = 0.53103871944398,
				x = 0.50934902393179,
				mapID = 207,
			},
		}, -- [11]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.89813858019974,
				mapID = 85,
				x = 0.57103620194035,
			},
			origin = {
				y = 0.48866477166798,
				x = 0.56823639354067,
				mapID = 111,
			},
		}, -- [12]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.89813858019974,
				mapID = 85,
				x = 0.57103620194035,
			},
			origin = {
				y = 0.51649872833174,
				x = 0.60789520263672,
				mapID = 624,
			},
		}, -- [13]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.89813858019974,
				mapID = 85,
				x = 0.57103620194035,
			},
			origin = {
				y = 0.49464972688152,
				x = 0.89232424936608,
				mapID = 100,
			},
		}, -- [14]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.89813858019974,
				mapID = 85,
				x = 0.57103620194035,
			},
			origin = {
				y = 0.18680549839493,
				x = 0.58536847841333,
				mapID = 110,
			},
		}, -- [15]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.39140493181188,
				mapID = 85,
				x = 0.4764620014373,
			},
			origin = {
				y = 0.79655785617416,
				x = 0.56321089764031,
				mapID = 245,
			},
		}, -- [16]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.37890044201114,
				mapID = 85,
				x = 0.50135588842975,
			},
			origin = {
				y = 0.53492878438869,
				x = 0.73593721339996,
				mapID = 241,
			},
		}, -- [17]
		{
			tooltip = "Portal to HellFire Peninsula, Outland",
			destination = {
				y = 0.49560798548094,
				mapID = 100,
				x = 0.89162719838972,
			},
			origin = {
				y = 0.17035557881295,
				x = 0.85221381072501,
				mapID = 90,
			},
		}, -- [18]
		{
			tooltip = "Portal to Zuldazar",
			destination = {
				y = 0.68583374023438,
				mapID = 1163,
				x = 0.70333319769965,
			},
			origin = {
				y = 0.62772743942331,
				x = 0.4727348470357,
				mapID = 1355,
			},
		}, -- [19]
		{
			tooltip = "Banshee's Wail to Drustvar",
			destination = {
				y = 0.43693684881455,
				mapID = 896,
				x = 0.20607681440632,
			},
			origin = {
				y = 0.62980799772618,
				x = 0.58454345381237,
				mapID = 862,
			},
		}, -- [20]
		{
			tooltip = "Banshee's Wail to Stormsong Valley",
			destination = {
				y = 0.31070487254826,
				mapID = 942,
				x = 0.51058783027949,
			},
			origin = {
				y = 0.62980799772618,
				x = 0.58454345381237,
				mapID = 862,
			},
		}, -- [21]
		{
			tooltip = "Banshee's Wail to Tiragarde Sound",
			destination = {
				y = 0.51159193712012,
				mapID = 895,
				x = 0.88203434638142,
			},
			origin = {
				y = 0.62980799772618,
				x = 0.58454345381237,
				mapID = 862,
			},
		}, -- [22]
		{
			tooltip = "Portal to Nazjatar",
			destination = {
				y = 0.6262505365728,
				mapID = 1355,
				x = 0.47193758468472,
			},
			origin = {
				y = 0.85333353678385,
				x = 0.62999979654948,
				mapID = 1163,
			},
		}, -- [23]
		{
			tooltip = "Portal to Silithus",
			destination = {
				y = 0.44943381928406,
				mapID = 81,
				x = 0.41537530710609,
			},
			origin = {
				y = 0.85416666666667,
				x = 0.73611111111111,
				mapID = 1163,
			},
		}, -- [24]
		{
			tooltip = "Portal to Thunder Bluff",
			destination = {
				y = 0.1687186758094,
				mapID = 88,
				x = 0.22214766105373,
			},
			origin = {
				y = 0.775,
				x = 0.73666653103299,
				mapID = 1163,
			},
		}, -- [25]
		{
			tooltip = "Portal to Silvermoon City",
			destination = {
				y = 0.19238329952114,
				mapID = 110,
				x = 0.58264465141624,
			},
			origin = {
				y = 0.62250061035156,
				x = 0.73944430881076,
				mapID = 1163,
			},
		}, -- [26]
		{
			tooltip = "Greasy Eel to Mechagon",
			destination = {
				y = 0.21320900152281,
				mapID = 1462,
				x = 0.75731763870321,
			},
			origin = {
				y = 0.87604148782861,
				x = 0.41825685012782,
				mapID = 1165,
			},
		}, -- [27]
		{
			tooltip = "Portal to Dalaran, Crystalsong Forest",
			destination = {
				y = 0.467831174332,
				mapID = 125,
				x = 0.55915854190679,
			},
			origin = {
				y = 0.91711090955257,
				x = 0.56224005120374,
				mapID = 85,
			},
		}, -- [28]
		{
			tooltip = "Portal to Jade Forest",
			destination = {
				y = 0.13982759669818,
				mapID = 371,
				x = 0.2855772268634,
			},
			origin = {
				y = 0.9226301536912,
				x = 0.57460081297161,
				mapID = 85,
			},
		}, -- [29]
		{
			tooltip = "Portal to Zuldazar",
			destination = {
				y = 0.68583374023438,
				mapID = 1163,
				x = 0.70333319769965,
			},
			origin = {
				y = 0.91348896151172,
				x = 0.5858117364355,
				mapID = 85,
			},
		}, -- [30]
		{
			tooltip = "Portal to Azsuna",
			destination = {
				y = 0.41362162170844,
				mapID = 630,
				x = 0.46817071748393,
			},
			origin = {
				y = 0.89537901076584,
				x = 0.58885869565217,
				mapID = 85,
			},
		}, -- [31]
		{
			tooltip = "Portal to Warspear, Ashran (Lower Pathfinder's Den)",
			destination = {
				y = 0.4973742659755,
				mapID = 624,
				x = 0.56951995849609,
			},
			origin = {
				y = 0.9204,
				x = 0.5517,
				mapID = 85,
			},
		}, -- [32]
		{
			tooltip = "Portal to Shattrath (Lower Pathfinder's Den)",
			destination = {
				y = 0.49210974806648,
				mapID = 111,
				x = 0.53003551136364,
			},
			origin = {
				y = 0.9164,
				x = 0.5751,
				mapID = 85,
			},
		}, -- [33]
		{
			tooltip = "Portal to Silvermoon City",
			destination = {
				y = 0.19238329952114,
				mapID = 110,
				x = 0.58264465141624,
			},
			origin = {
				y = 0.88218457597122,
				x = 0.55982527847646,
				mapID = 85,
			},
		}, -- [34]
		{
			tooltip = "Portal to Cavern of Times (Lower Pathfinder's Den)",
			destination = {
				y = 0.28302714070312,
				mapID = 74,
				x = 0.5460492553501,
			},
			origin = {
				y = 0.9258,
				x = 0.5641,
				mapID = 85,
			},
		}, -- [35]
		{
			tooltip = "Portal to Undercity",
			destination = {
				y = 0.16332547124834,
				mapID = 90,
				x = 0.84585550612658,
			},
			origin = {
				y = 0.55594681212568,
				x = 0.50745008758534,
				mapID = 85,
			},
		}, -- [36]
		{
			tooltip = "Portal to Uldum",
			destination = {
				y = 0.34247656465072,
				mapID = 1527,
				x = 0.54895175722124,
			},
			origin = {
				y = 0.38545449836978,
				x = 0.48876521514553,
				mapID = 85,
			},
		}, -- [37]
		{
			tooltip = "Portal to Uldum",
			destination = {
				y = 0.34247656465072,
				mapID = 249,
				x = 0.54895175722124,
			},
			origin = {
				y = 0.38545449836978,
				x = 0.48876521514553,
				mapID = 85,
			},
		}, -- [38]
		{
			tooltip = "Portal to Vashj'ir",
			destination = {
				y = 0.60947867366724,
				mapID = 204,
				x = 0.51370135161043,
			},
			origin = {
				y = 0.36544725152611,
				x = 0.49221473005749,
				mapID = 85,
			},
		}, -- [39]
		{
			tooltip = "Portal to Deepholm",
			destination = {
				y = 0.52942107099127,
				mapID = 207,
				x = 0.5059176514649,
			},
			origin = {
				y = 0.36311887139568,
				x = 0.50808255479698,
				mapID = 85,
			},
		}, -- [40]
		{
			tooltip = "Portal to Hyjal",
			destination = {
				y = 0.2337236134106,
				mapID = 198,
				x = 0.63486551497068,
			},
			origin = {
				y = 0.38278114574241,
				x = 0.5111870620733,
				mapID = 85,
			},
		}, -- [41]
		{
			tooltip = "Portal to Twilight Highlands",
			destination = {
				y = 0.53393293284393,
				mapID = 241,
				x = 0.73631666027462,
			},
			origin = {
				y = 0.39450947374272,
				x = 0.50227581521739,
				mapID = 85,
			},
		}, -- [42]
		{
			tooltip = "Portal to Tol Barad",
			destination = {
				y = 0.62372974957755,
				mapID = 245,
				x = 0.44771604383759,
			},
			origin = {
				y = 0.39287103860618,
				x = 0.47387486525332,
				mapID = 85,
			},
		}, -- [43]
		{
			tooltip = "Portal to Zuldazar",
			destination = {
				y = 0.64583333333333,
				mapID = 1163,
				x = 0.68277757432726,
			},
			origin = {
				y = 0.4520574119515,
				x = 0.41601595868837,
				mapID = 81,
			},
		}, -- [44]
		{
			tooltip = "Banshee's Wail to Zuldazar",
			destination = {
				y = 0.62495129448905,
				mapID = 862,
				x = 0.58402363790205,
			},
			origin = {
				y = 0.43340743614875,
				x = 0.20602456086601,
				mapID = 896,
			},
		}, -- [45]
		{
			tooltip = "Banshee's Wail to Zuldazar",
			destination = {
				y = 0.62495129448905,
				mapID = 862,
				x = 0.58402363790205,
			},
			origin = {
				y = 0.51185500686031,
				x = 0.87841985717018,
				mapID = 895,
			},
		}, -- [46]
		{
			tooltip = "Banshee's Wail to Zuldazar",
			destination = {
				y = 0.62495129448905,
				mapID = 862,
				x = 0.58402363790205,
			},
			origin = {
				y = 0.24462557170856,
				x = 0.51955369973581,
				mapID = 942,
			},
		}, -- [47]
		{
			tooltip = "Greasy Eel to Zuldazar",
			destination = {
				y = 0.87433673840999,
				mapID = 1165,
				x = 0.41751074550264,
			},
			origin = {
				y = 0.22668496550168,
				x = 0.75500752005348,
				mapID = 1462,
			},
		}, -- [48]
		{
			tooltip = "Portal to Oribos",
			destination = {
				y = 0.50311940044438,
				x = 0.20336391437309,
				mapID = 1670,
			},
			origin = {
				y = 0.87839019431731,
				x = 0.58328186758893,
				mapID = 85,
			},
		}, -- [49]
		{
			tooltip = "Zeppelin to Borean Tundra",
			destination = {
				y = 0.5354,
				mapID = 114,
				x = 0.4129,
			},
			origin = {
				y = 0.6168,
				x = 0.4525,
				mapID = 85,
			},
		}, -- [50]
		{
			tooltip = "Zeppelin to Orgrimmar",
			destination = {
				y = 0.6168,
				x = 0.4525,
				mapID = 85,
			},
			origin = {
				y = 0.5354,
				mapID = 114,
				x = 0.4129,
			},
		}, -- [51]
		{
			tooltip = "Waystone to Oribos",
			destination = {
				y = 0.5031,
				x = 0.1924,
				mapID = 1670,
			},
			origin = {
				y = 0.4217,
				x = 0.4237,
				mapID = 1543,
			},
		}, -- [52]
		{
			tooltip = "Pad to Ring of Fates",
			destination = {
				y = 0.50293573502007,
				x = 0.47113152833524,
				mapID = 1670,
			},
			origin = {
				y = 0.51546868982912,
				x = 0.43374996185303,
				mapID = 1671,
			},
		}, -- [53]
		{
			tooltip = "Pad to Ring of Transference",
			destination = {
				y = 0.51546868982912,
				x = 0.43374996185303,
				mapID = 1671,
			},
			origin = {
				y = 0.50293573502007,
				x = 0.47113152833524,
				mapID = 1670,
			},
		}, -- [54]
		{
			tooltip = "Pad to Ring of Transference",
			destination = {
				y = 0.42007819746433,
				x = 0.49375,
				mapID = 1671,
			},
			origin = {
				y = 0.42440375931766,
				x = 0.52091740132836,
				mapID = 1670,
			},
		}, -- [55]
		{
			tooltip = "Pad to Ring of Fates",
			destination = {
				y = 0.42440375931766,
				x = 0.52091740132836,
				mapID = 1670,
			},
			origin = {
				y = 0.42007819746433,
				x = 0.49375,
				mapID = 1671,
			},
		}, -- [56]
		{
			tooltip = "Pad to Ring of Fates",
			destination = {
				y = 0.50366972477064,
				x = 0.5714373387328,
				mapID = 1670,
			},
			origin = {
				y = 0.51617192913591,
				x = 0.55656242370605,
				mapID = 1671,
			},
		}, -- [57]
		{
			tooltip = "Pad to Ring of Transference",
			destination = {
				y = 0.51617192913591,
				x = 0.55656242370605,
				mapID = 1671,
			},
			origin = {
				y = 0.50366972477064,
				x = 0.5714373387328,
				mapID = 1670,
			},
		}, -- [58]
		{
			tooltip = "Pad to Ring of Transference",
			destination = {
				y = 0.60921867194773,
				x = 0.49515628814697,
				mapID = 1671,
			},
			origin = {
				y = 0.57853219968463,
				x = 0.52067281273891,
				mapID = 1670,
			},
		}, -- [59]
		{
			tooltip = "Pad to Ring of Fates",
			destination = {
				y = 0.57853219968463,
				x = 0.52067281273891,
				mapID = 1670,
			},
			origin = {
				y = 0.60921867194773,
				x = 0.49515628814697,
				mapID = 1671,
			},
		}, -- [60]
		{
			tooltip = "Ring of Transference",
			destination = {
				y = 0.4098,
				x = 0.4495,
				mapID = 1543,
			},
			origin = {
				y = 0.5,
				mapID = 1671,
				x = 0.5,
			},
		}, -- [61]
	}
	
	do --Add internal reference for each portal's index
		for i, b in pairs(networkLocations) do
			b.index = i
		end
	end
	
	--Sort portal list into 2 lists. Saves time later, as this info is needed every time.
	local portalsBy; do
		portalsBy = {
			originMapID = {},
			destinationMapID = {},
		}

		--Portals starting on each map, based on originMapID
		for portalID, portalData in pairs(networkLocations) do
			for i, mapID in pairs(GetZoneIDs(portalData.origin.mapID)) do
				portalsBy.originMapID[mapID] = portalsBy.originMapID[mapID] or {}
				if mapID~= 946 and not tContains(portalsBy.originMapID[mapID], portalID) then
					tinsert(portalsBy.originMapID[mapID], portalID)
				end
			end
		end

		--Portals leading to each map, based on destinationMapID
		for portalID, portalData in pairs(networkLocations) do
			for i, mapID in pairs(GetZoneIDs(portalData.destination.mapID)) do
				portalsBy.destinationMapID[mapID] = portalsBy.destinationMapID[mapID] or {}
				if mapID ~= 946 and not tContains(portalsBy.destinationMapID[mapID], portalID) then
					tinsert(portalsBy.destinationMapID[mapID], portalID)
				end
			end
		end
	end

	local function GetPortalByID(portalID)
		return networkLocations[portalID]
	end

	local function GetPortals(mapID, UseDestList)
		local list = UseDestList and portalsBy.destinationMapID or portalsBy.originMapID
		local mapIDS = GetZoneIDs(mapID)
		local portals = list[mapID]
		return mapIDS, (portals and #portals > 0) and portals or list[mapIDS[#mapIDS]]
	end
	
	local function GetGateway(destinationPortalList, originMapID, potentialPortals, m, numJumpsRequired, originPortalID, optionsFound)
		--there were no direct portals available, digging deeper.
		if trace then
			--store this mapID, so we only try looking it up once.
			trace[originMapID] = true
		end
		local originMapIDs,  originPortalList = GetPortals(originMapID)
		if originPortalList then
			for i, possibleOriginPortalID in pairs(originPortalList) do
				if tContains(destinationPortalList, possibleOriginPortalID) then
					if not tContains(potentialPortals, originPortalID or possibleOriginPortalID) then
						tinsert(potentialPortals, {originPortalID or possibleOriginPortalID, numJumpsRequired})
						optionsFound = true --options have been found
					end
				elseif not optionsFound then
					--if no options have been found, keep digging
					local portal = GetPortalByID(possibleOriginPortalID)
					
					if (not trace or (not trace[portal.destination.mapID]))
					and (not numJumpsRequired or (numJumpsRequired < 3)) then
						GetGateway(destinationPortalList, portal.destination.mapID, potentialPortals, trace, (numJumpsRequired or 1) + 1 or {}, originPortalID or possibleOriginPortalID, optionsFound)
					end
				end		
			end
		end
	end

	local nopotentialPortals = {
		--dungeons don't allow coords or waypoints
		[Enum.UIMapType.Dungeon] = true,
	}
	
	local storedTransit = {}

	local potentialPortals = {}--reusable; Collect multiple portal options
	function Questra:GetPortal(destinationMapID)
		--[[Simplified Explanation:
				1. Get a list of portals leading to destination and a list of portals of available at origin
				2. check if any portals available at origin are on the destinationPortalList, and store them.
					2A. 
		--]]
	
		--Get player's current location
		local x, y, originMapID = Questra.GetPlayerPosition()
	
		--check if this origin/destination combination has been looked up before, and return the stored result.
		if nopotentialPortals[destinationMapID..originMapID] then
			--Origin to destination have been checked before and no options were available.
			return 
		elseif storedTransit[destinationMapID..originMapID] then
			--Origin to destination have been checked before and options were available.
			return storedTransit[destinationMapID..originMapID]
		end
		
		--Clean the table for reuse
		wipe(potentialPortals)
		
		--Get parent mapIDs and possible portals
		local destinationMapIDS, destinationPortalList = GetPortals(destinationMapID, true)--portals that lead to destination
		local originMapIDs, originPortalList = GetPortals(originMapID) --portals the start at origin

		do --Makes sure origin and destination are not the same and are not on same world and/or continent
			if (destinationPortalList and #destinationPortalList < 1) 
			or tContains(originMapIDs, destinationMapID)
			or tContains(destinationMapIDS, originMapID)
			or originMapID == destinationMapID then
				nopotentialPortals[destinationMapID..originMapID] = true
				return
			end

			for _,portalID in pairs(originMapIDs) do
				if  tContains(destinationMapIDS, portalID) then
					nopotentialPortals[destinationMapID..originMapID] = true
					return
				end
			end
		end
		
		local optionsFound; do
			--Try to find a one hop portal that leads directly from origin to destination
			for i, originPortalID in pairs(originPortalList) do
				if tContains(destinationPortalList, originPortalID) then
					if not tContains(potentialPortals, originPortalID) then
						tinsert(potentialPortals, {originPortalID, 1})
						optionsFound = true
					end
				end		
			end

			if not optionsFound then
				--If no portal has been found above, dig a little deeper
				GetGateway(destinationPortalList, originMapID, potentialPortals, {})
			end
		end
		
		table.sort(potentialPortals, function(a, b)
			--sort potentialPortals by fewest number of jumps required
			return a[2] > b[2]
		end)
		
		if #potentialPortals < 1 then
			nopotentialPortals[destinationMapID..originMapID] = true
		else
			storedTransit[destinationMapID..originMapID] = GetPortalByID(potentialPortals[#potentialPortals][1])
		end
		
		return potentialPortals and GetPortalByID(potentialPortals[#potentialPortals][1])
	end
end

do --flight recommendations
	--Track combined distance from player to nearest flight  point, and the destination's nearest flight point
	--compare difference of player's distance to destination to flight distance
	--if flight is shorter distance, recommend it.

	local storedIDs = {}
	local function GetZoneIDs(baseID) --get parent zone IDS for baseID
		if baseID and not storedIDs[baseID] then
			local _ids = {baseID}

			local info = C_Map.GetMapInfo(baseID)
			local count 
			while info do
				local parentInfo = C_Map.GetMapInfo(info.parentMapID)
				if parentInfo then
					if (info.parentMapID and tContains(_ids, info.parentMapID) or (parentInfo.mapType == Enum.UIMapType.Cosmic)) then
						break --we've hit a repeat id or the cosmic map
					end
					 if (parentInfo.mapType ~= Enum.UIMapType.Cosmic)then
					
						local _ = info.parentMapID and tinsert(_ids, info.parentMapID)
					end
				end
				info = parentInfo
			end
			storedIDs[baseID] = _ids --store it, so we don't have to dig for this ID again
		end
		return baseID and storedIDs[baseID] or {}--return then stored id
	end
	
	local function ShouldShowTaxiNode(factionGroup, taxiNodeInfo)
		if taxiNodeInfo.faction == Enum.FlightPathFaction.Horde then
			return factionGroup == "Horde";
		end

		if taxiNodeInfo.faction == Enum.FlightPathFaction.Alliance then
			return factionGroup == "Alliance";
		end
		
		if taxiNodeInfo.faction == Enum.FlightPathFaction.Neutral then
			return true
		end
		
		return true
	end
	local pingAnywherePin
	
	
	function doTHIS()
		FlightMapFrame.oldOnEvent = FlightMapFrame:GetScript("OnEvent")
		FlightMapFrame:SetScript("OnEvent", function(self, event, ...)
			prin(self, event, ...)
			return FlightMapFrame:oldOnEvent(self, event, ...)
		end)
	
	end
	
	
	local lastPing
	local function PingFlightMapAnywhere(x, y, wayMapID)
		--handy tool derived from: "Interface\AddOns\Blizzard_SharedMapDataProviders\WorldQuestDataProvider.lua"
		pingAnywherePin = pingAnywherePin or FlightMapFrame:AcquirePin("QuestraPingPinTemplate")
		
		pingAnywherePin.DriverAnimation:Stop()
		pingAnywherePin:Hide()

		if wayMapID and x and y then
			do --override display, if ping point isn't displayed at current zoom level and position
				local x, y = HBD:TranslateZoneCoordinates(.5, .5, wayMapID, FlightMapFrame.mapID, true)					
				FlightMapFrame:InstantPanAndZoom(FlightMapFrame:GetScaleForMaxZoom(), x, y, true);
			end
			local x, y = HBD:TranslateZoneCoordinates(x, y, wayMapID, FlightMapFrame.mapID, true)

			if (not pingAnywherePin.DriverAnimation:IsPlaying()) or lastPing ~= x..y..wayMapID then
				pingAnywherePin:Show()
				FlightMapFrame:SetPinPosition(pingAnywherePin, x, y)
				pingAnywherePin.DriverAnimation:Play()
				lastPing = x..y..wayMapID
			end
		else
			pingAnywherePin.DriverAnimation:Stop()
			pingAnywherePin:Hide()
		end
	end
	Questra.PingFlightMapAnywhere = PingFlightMapAnywhere
	
	local destStore = {}
	local one
	local noFlyList = {}
	
	local storedNodes = {}
	
	local unlearnedPoints = {
		
	
	}
	
	local function getNearestFlightPoint(mapID, x,  y)
		local ClosestFlightDist, ClosestFlight = math.huge

		local nodesToStore = (FlightMapFrame and FlightMapFrame:IsShown()) and C_TaxiMap.GetAllTaxiNodes(mapID)
		if nodesToStore then
			storedNodes[mapID] = nodesToStore
		end
		unlearnedPoints[mapID] = unlearnedPoints[mapID] or {}
		
		local nodes = storedNodes[mapID] or C_TaxiMap.GetTaxiNodesForMap(mapID)		
		
		if nodes and (#nodes > 0) then
			for index, taxiNodeInfo in pairs(nodes) do
				if taxiNodeInfo.name then
					if ShouldShowTaxiNode(UnitFactionGroup("player"), taxiNodeInfo) then
						if taxiNodeInfo.position then
							if nodesToStore then
								unlearnedPoints[mapID][taxiNodeInfo.name] = TaxiNodeGetType(index)
							end
							if (unlearnedPoints[mapID][taxiNodeInfo.name] ~= "DISTANT") or (unlearnedPoints[mapID][taxiNodeInfo.name] ~= "NONE") then
								local compDist = HBD:GetZoneDistance(mapID, x, y, mapID, taxiNodeInfo.position.x, taxiNodeInfo.position.y)
								if ClosestFlightDist > compDist then
									ClosestFlightDist, ClosestFlight = compDist, taxiNodeInfo
									taxiNodeInfo.position.mapID = mapID
								end
							end
						end
					end
				end
			end			
		end
		return ClosestFlight, ClosestFlightDist
	end
	
	local noFly = {}
	function  Questra:GetFlight(destinationID, destX, destY)
		if UnitOnTaxi("player") then return  end
		local x, y, originID = Questra.GetPlayerPosition()
		
		if noFly[originID..destinationID] then
			return 
		end
		
		local oIDS = GetZoneIDs(originID)
		local isAzeroth = tContains(oIDS, 947)
		local dIDS 
		if isAzeroth then
			oIDS = Questra.GetZoneIDs(originID) --Azeroth does not allow flights between continents, use similar function from portal system
			dIDS = Questra.GetZoneIDs(destinationID)
		else
			dIDS = GetZoneIDs(destinationID)
		end
		
		--if tContains(oIDS, destinationID)
		--or tContains(dIDS, originID)
		if originID == destinationID then
			return
		end
				
		local sameWorld
		for i, oid in pairs(oIDS) do
			if tContains(dIDS, oid) then
				sameWorld = true
			end
		end
		if sameWorld then
			local factionGroup = UnitFactionGroup("player")
			
			if not destStore[destinationID..destX..destY] then
				---destination is static, so look it up and save it
				destStore[destinationID..destX..destY] = {getNearestFlightPoint(destinationID, destX, destY)}
			end
			
			local nearestDestFlight,   nearestDestFlightDist   = unpack(destStore[destinationID..destX..destY])
			local nearestOriginFlight, nearestOriginFlightDist = getNearestFlightPoint(originID, x, y)

			if nearestOriginFlight and nearestDestFlight then
				local dist = nearestOriginFlightDist + nearestDestFlightDist
				local fullDist = HBD:GetZoneDistance(destinationID, destX, destY, originID, x, y)
				
				if dist < fullDist then
					--flight is faster
					if (FlightMapFrame and FlightMapFrame:IsShown()) then
						if not one then
							one = true
							prin("ping")
							PingFlightMapAnywhere(nearestDestFlight.position.x, nearestDestFlight.position.y, nearestDestFlight.position.mapID)
						end
					else
						one = nil
					end					

					--nearestOriginFlight.position.mapID = (nearestOriginFlight.position.mapID == 1670) and 1671 or nearestOriginFlight.position.mapID
										
					return {origin = {
							x = nearestOriginFlight.position.x,
							y = nearestOriginFlight.position.y,
							mapID = nearestOriginFlight.position.mapID,
						},
						tooltip = "Flight from "..nearestOriginFlight.name.. " to "..nearestDestFlight.name,
					}
				end
			else			
				noFly[originID..destinationID] = true
			end
		end
	end
end
