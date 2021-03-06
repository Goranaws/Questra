local AddonName, Questra = ...
local HBD = Questra.HBD
local FlyPaper = LibStub('LibFlyPaper-2.0')

Questra.sets = {}

Questra.ignoredIDS = {}
Questra.ignoredTYPES = {}


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

local events

local canAutoTrack

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
	Quest_Compass_DB = Quest_Compass_DB or {}
	
	Quest_Compass_DB.ignoredIDS = Quest_Compass_DB.ignoredIDS or {}
	Quest_Compass_DB.ignoredTYPES = Quest_Compass_DB.ignoredTYPES or {}
	
	Questra.ignoredIDS = Quest_Compass_DB.ignoredIDS
	Questra.ignoredTYPES = Quest_Compass_DB.ignoredTYPES
	
	
	Quest_Compass_DB.widgets = Quest_Compass_DB.widgets or {}
	
	Questra:SaveAndRestoreTracking()
	
	Questra.BuildElements()

	Questra:AddElementOptions()

	Questra:LoadTrackingOptions()
	
	Questra:EnableElementScripts()
	
	Questra:OnPostLoad()
	
	Questra:Update()

	Questra:HookMapPins()
	
	Questra.MapPinHandler = CreateFromMixins(QuestraDataProviderMixin)
	
	WorldMapFrame:AddDataProvider(Questra.MapPinHandler);
	
	for i, elementDetails in pairs(Questra.Elements) do
		if elementDetails.UpdateSettings then
			elementDetails.UpdateSettings()
		end
	
	end
	
	Questra:EnableSlash()
	
	--Questra:GetOrCreatePortalDataCollector()
end

do --slash Commands
	function Questra:EnableSlash()


		SlashCmdList["QUESTRA"] = function(Cmd, ...)
			if string.find(Cmd, "reset", 1) then
				Quest_Compass_DB = nil
				ReloadUI()
			--elseif string.find(Cmd, "save", 1) then
			--	Q_C:SavePrompt()
			-- elseif string.find(Cmd, "import", 1) then
				-- if TomTomWaypointsM and TomTomWaypointsM.profiles then
					-- local info = {}
					-- for i, profile in pairs(TomTomWaypointsM.profiles) do
						-- for mapID, inf in pairs(profile) do
							-- for mapID, inf in pairs(inf) do
								-- tinsert(info, {position = {x = inf[2], y = inf[3], mapID = inf[1]}, name = inf.title})
							-- end
						-- end
					-- end

					-- for i, b in pairs(info) do
						-- for q,z in pairs(Quest_CompassAltDB) do
							-- --ignore and remove duplicates before importing
							-- if (math.floor(z.x*100) == math.floor(b.x*100)) and (math.floor(z.y*100) == math.floor(b.y*100)) and (z.name == b.name) and (z.mapID == b.mapID) then
								-- tremove(info, i)
							-- end
						-- end
					-- end

					-- for i, b in pairs(info) do
						-- tinsert(Quest_CompassAltDB, b)
					-- end
					-- print("Quest_Compass:", #info, "Waypoints have been imported from TomTom!")
				--end
			else
				Questra:ToggleOptions()
			end
		end
		
		SLASH_QUESTRA1 = "/questra"
		SLASH_QUESTRA2 = "/qc"
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


	Questra.questTypes  =	{ 
		"Profession", --1
		"", --2
		"PvP", --3
		"Pet Battle", --4
		"Bounty", --5
		"Dungeon", --6
		"Invasion", --7
		"Raid", --8
		"Contribution", --9
		"Rated", --10
		"Invasion", --11
		"Faction Assault", --12
		"Islands", --13
		"Threat", --14
		"Covenant Calling", --15
	}
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
			Quest_Compass_DB = Quest_Compass_DB or {}
				local info = Quest_Compass_DB and Quest_Compass_DB.instanceLocations and Quest_Compass_DB.instanceLocations[zoneNamemm]
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

			local info = Quest_Compass_DB and Quest_Compass_DB.instanceLocations and Quest_Compass_DB.instanceLocations[name]
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

do --visual display functions
	local trackingIndex = 1
	Questra.trackingIndex = trackingIndex
	function Questra:GetTracking()
		return trackingIndex or 1
	end

	function Questra:SetTracking(index)
		trackingIndex = index or tIndexOf(Questra.typesIndex, Questra.lastSwap) or 1
	end

	function Questra:SetTrackingByName(name)
		trackingIndex = tIndexOf(Questra.typesIndex, name)
		Questra.lastSwap = name
		
		Questra:UpdateAutoTracking("FORCED")

		Questra:CollectUpdate()
		Questra:Update()
	end

	function Questra:UpdateTracking(delta)
		trackingIndex = trackingIndex and trackingIndex - delta or 1
		trackingIndex = trackingIndex > #Questra.typesIndex and 1
			or trackingIndex < 1 and #Questra.typesIndex
			or trackingIndex --rollover from start to finish or finish to start

		local trackingName = Questra.typesIndex[trackingIndex]

		if not (trackingName == "dungeon" or trackingName == "flight" or trackingName == "offer" or trackingName == "achievement") then
			Questra.lastSwap = trackingName
		end
	end

	function Questra:UpdateDisplayed(event)
		CloseDropDownMenus()
		local _ = DropDownList1 and DropDownList1:ClearAllPoints()
		for i, track in pairs(Questra.tracking) do
			track.OnEvent(event)

			local shouldShow = track.ShouldShow() == true

			if track.sets and track.sets.disable == true then
				shouldShow = nil
			end

			if shouldShow == true then
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
			if shouldSwap == true and not newAutoSwap then
				newAutoSwap = tIndexOf(Questra.typesIndex, track.trackingName)
				Questra.lastSwap = track.trackingName
				track.SetToMetric(metric)
				Questra:SetTracking(newAutoSwap)
				break
			end
		end
		
		Questra:CollectUpdate()
	end

	function Questra:GetTracked()
		return Questra.trackByName[Questra.typesIndex[Questra:GetTracking()]]
	end

	function Questra:CollectUpdate()
		local tracker = Questra:GetTracked()
		if not tracker then return end
		--colorize
		Questra.TrackerScrollButton:GetNormalTexture():SetVertexColor(unpack(tracker.color))

		local skinDetails, position, texture, l, r, t, b, extra, textureIndex = Questra.basicSkin, nil, nil, 0, 1, 0, 1, nil
		if tracker then
			skinDetails, position, texture, l, r, t, b, extra, textureIndex  = tracker.GetIconInfo()
		else
			self.pin.icon:SetTexture("")
			self.pin.icon:SetTexCoord(0,1,0,1)
			self.distanceText:SetText("")
			self.pin.compassArrow:Hide()
			self.pin.compassArrow:SetRotation(0)
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
			textureIndex = textureIndex
		}
	
		Questra:Update()
	end

	function Questra:Update()
		local  x, y, id = Questra.GetPlayerPosition()
		local questID

		if Questra.storedUpdate then
			questID = Questra.storedUpdate.questID
			Questra:SetDisplay(x, y, id, unpack(Questra.storedUpdate))
		end

		Questra:OnQuestUpdate(questID)
	end

	function Questra:SetDisplay(oX, oY, oID, dX, dY, dID, icon, L, R, T, B, skinDetails, textureIndex)

		--Get World Coordinates for origin and destination
		if oX and oY and oID and dX and dY and dID then
		
			dX, dY, dID = Questra:GetAlternateWaypoints(dX, dY, dID)
			

			local oX_World, oY_World, oID_World  = HBD:GetWorldCoordinatesFromZone(oX, oY, oID)
			local dX_World, dY_World, dID_World  = HBD:GetWorldCoordinatesFromZone(dX, dY, dID)

			--dungeon entrance conversion?
			--To do: if player or destination
			--is inside dungeon, convert them
			--to the dungeon's external entrance, maybe..

			if oID_World == dID_World then --Destination and Origin are on same World
			
				if oID ~= dID then
					--convert destinationMapID coords to originMapID coords
					local viewed_wX, viewed_wY = HBD:TranslateZoneCoordinates(dX, dY, dID, oID, true)
					dX, dY, dID = viewed_wX, viewed_wY, oID
				end
	
				local playerAngle = GetPlayerFacing()
				local angle = HBD:GetWorldVector(oID_World, oX_World, oY_World, dX_World, dY_World)

				Questra:OnLocationUpdate(oX, oY, oID, dX, dY, dID, playerAngle, angle, oID_World)
			else
				Questra:OnLocationUpdate(oX, oY, oID)
				Questra.portalSense = nil
				
			end
		else
			Questra:OnLocationUpdate(oX, oY, oID)
			Questra.portalSense = nil
		end

		Questra:OnPostLocationUpdate(oX, oY, oID, dX, dY, dID, icon, L, R, T, B, skinDetails, textureIndex)
		Questra.tracking[Questra:GetTracking()].portal = Questra.portalSense
	end
end

do --Visual display elements
	local size = 95
	local _size = size
	
	local layoutUpdates = {}
	Questra.layoutUpdates = layoutUpdates 
	
	Questra:AddElement({
		name = "frame",
		Build = function()
			Quest_Compass_DB = Quest_Compass_DB or {}
			Quest_Compass_AltDB = Quest_Compass_AltDB or {}
			Questra.sets = Quest_Compass_AltDB
		
			local frame = CreateFrame("Frame", AddonName.."_Frame", UIParent)
			frame:SetFrameStrata("BACKGROUND")
			frame:SetFixedFrameStrata(true)
			frame:SetPoint("Center", 0, -250)
			frame:SetSize(size, size)

			return frame
		end,
		
		OnPostLoad = function(self)
			for i, b in pairs(Questra.Events) do
				self:RegisterEvent(b)
			end
		
			FlyPaper.AddFrame(AddonName, 1, self)
			
			
			if Questra:IsAnchored() then
				Questra:RestoreAnchor()
			else
				Questra:RestorePosition()
			end
		end,
		
		scripts = {
			OnLoad = function(self)

			end,
			
			OnEvent = function(self, event, ...)
				if not self.runnin then
					self.runnin = true
					Questra:UpdateAutoTracking(event)
					self.runnin = nil
				end
			end,
			
			OnUpdate = function(self)
				Questra:Update()

				if GameTooltip:IsShown() and (GameTooltip:GetOwner() == Questra.pin) and MouseIsOver(Questra.pin) then
					 Questra.pin:GetScript("OnEnter")(Questra.pin)
				end
				
				Questra:UpdateElements()
			end,
			
			OnEnter = function(self)
	
			end,
			
			OnLeave = function(self)

			end,
		},
	})
	
	do --waypoint icon, arrow and tooltip
		local pin = {name = "pin", displayName = "Basic", parentElementName = "frame",}
		function pin:Build(...)
			local button = CreateFrame("Button",  AddonName.."NavigationButton", self)

			button:SetSize(_size, _size)
			button:SetPoint("Center", 0, 7)
			button:SetFrameStrata("LOW")
			button:SetFrameLevel(10)
			button:SetFixedFrameStrata(true)
			button:SetHitRectInsets(15, 15, 15, 15)


			button:SetNormalTexture(Questra.textures.Green)
			button.bg = button:GetNormalTexture()

			button:SetPushedTexture(Questra.textures.Green)
			button.push = button:GetPushedTexture()
				button.push:SetAllPoints(button.bg)
				button.push:SetDrawLayer("BACKGROUND")
				button.push:SetTexCoord(.75, .25, .75, .25)
				
				button.bg:ClearAllPoints()
				button.bg:SetPoint("Center")
				button.bg:SetDrawLayer("BACKGROUND", 2)
				button.bg:SetTexCoord(.25, .75, .25, .75)
				button.bg:SetSize(_size - 30, _size - 30)

			button.border = button:CreateTexture(nil, "BORDER", 3)
				button.border:SetAllPoints(button)
				button.border:SetAtlas("auctionhouse-itemicon-border-artifact")

			button.hl = button:CreateTexture(nil, "HIGHLIGHT", 1)
				button.hl:SetPoint("Center")
				button.hl:SetSize(_size - 30, _size - 30)
				button.hl:Hide()

				button.hl:SetTexture(166862)

			button.compassArrow = button:CreateTexture(nil, "OVERLAY", 25)
				button.compassArrow:SetAllPoints(button)
				button.compassArrow:SetTexture(Questra.textures.RingArrow)
				
			button.metricDial = button:CreateTexture(nil, "BACKGROUND", 1)
				button.metricDial:SetAllPoints(button)
				button.metricDial:SetTexture(Questra.textures.metricDial)
				
			button.icon = button:CreateTexture(nil, "LOW", 1)
			button.icon:SetDrawLayer("BACKGROUND", 7)
				button.icon:SetPoint("Center", 1, 0)
				button.icon:SetSize(_size - 40, _size - 40)
				button.icon.width, button.icon.height = button.icon:GetSize()
			
			pin.parent = self
			

			
			
			return button
		end
		
			
		pin.Layout = function(self, sets)
			self:GetParent():SetScale(sets.scale/100)
			
			self:ClearAllPoints()
			if sets.flip == true then
				self:SetPoint("Center", 0, -14)
				self.metricDial:SetTexCoord(1, 0, 1, 0)
			else
				self:SetPoint("Center", 0, 11)
				self.metricDial:SetTexCoord(0, 1, 0, 1)
			end
		end
		
		local infoTable = pin
		
		function pin.UpdateSettings()
			for _, update in pairs(layoutUpdates) do
				update(pin.sets)
			end
		end
		
		pin.options = {
			{
				kind = "Slider",
				title = "Scale",
				key = "scale",
				default = 100,
				style = "percent",
				OnValueChanged = function(self)
					local val = self:GetValue()
					pin.sets.scale = val

					pin.UpdateSettings()					
				end,
				OnShow = function(self)
					self:SetValue(pin.sets.scale)
				end,
			},
			{
				kind = "CheckButton",
				title = "Flip Vertical",
				key = "flip",
				default = false,
				OnClick = function(self)
					pin.sets.flip = not pin.sets.flip
					self:SetChecked(pin.sets.flip)
					
					pin.UpdateSettings()	
				end,
				OnShow = function(self)
					self:SetChecked(pin.sets.flip)
				end,
			},
			{
				kind = "CheckButton",
				title = "Disable Alternate Routes",
				key = "noRoutes",
				default = false,
				OnClick = function(self)
					pin.sets.noRoutes = not pin.sets.noRoutes
					self:SetChecked(pin.sets.noRoutes)
					
					pin.UpdateSettings()	
				end,
				OnShow = function(self)
					self:SetChecked(pin.sets.noRoutes)
				end,
			},
			{
				kind = "CheckButton",
				title = "Always use Alternate Routes",
				key = "alwaysAltRoute",
				default = false,
				OnClick = function(self)
					pin.sets.alwaysAltRoute = not pin.sets.alwaysAltRoute
					self:SetChecked(pin.sets.alwaysAltRoute)
					
					pin.UpdateSettings()	
				end,
				OnShow = function(self)
					self:SetChecked(pin.sets.alwaysAltRoute)
				end,
			},
			{
				kind = "Button",
				title = "Move Compass",
				default = false,
				OnClick = function(self)
					ToggleFrame(_G[AddonName.."_dragFrame"])	
				end,
			},
		
		}
			
		function pin:OnPostLoad()
			Questra:UpdateDisplayed("Forced")

			local tracker = Questra:GetTracked()
			if tracker then
				tracker.ScrollMetrics(0)
			end

			Questra:CollectUpdate()
			Questra:Update()
		end

		function Questra:GetAlternate()
			if pin.sets then
				return pin.sets.noRoutes,  pin.sets.alwaysAltRoute
			end
		end

		function pin:OnLocationUpdate(x, y, mapID, destX, destY, destMapID, playerAngle, angle)
			if angle and playerAngle then
				self.compassArrow:Show()
				self.compassArrow:SetRotation(rad((deg(angle) - deg(playerAngle))))
			else
				self.compassArrow:Hide()
				self.compassArrow:SetRotation(0)
			end
			
					
			local _min, _max = 0, 210
			
			local tracker = Questra:GetTracked()
			if not tracker then
				return
			end
			
			local _Min, _Max

			if tracker.metrics and tracker.GetScrollValue() then
				_Min, _Max = tracker.GetScrollValue(), #tracker.metrics
			end
			
			local percent = 0
			if (_Min and _Max) and _Max ~= 1 then
				local percent = (_Min-1) / (_Max-1)
				self.metricDial:Show()
				self.metricDial:SetRotation(-rad(_max * percent))
			else
				self.metricDial:Hide()
				self.metricDial:SetRotation(0)
				return
			end
		end
		
		function pin:OnPostLocationUpdate(x, y, mapID, destX, destY, destMapID, icon, L, R, T, B, skinDetails, textureIndex)
			if skinDetails then
				local bgtexture, normCoords, pushedCoords, normColor, pushedColor = unpack(skinDetails or Questra.basicSkin)
				self:SetNormalAtlas(bgtexture)
				self:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
				self:GetNormalTexture():SetVertexColor(unpack(normColor))
				
				self:SetPushedAtlas(bgtexture)
				self:GetPushedTexture():SetTexCoord(1, 0, 1, 0)
				self:GetPushedTexture():SetVertexColor(unpack(pushedColor))
			else
				self:SetNormalTexture(Questra.textures.Green)
				self:GetNormalTexture():SetTexCoord(.25, .75, .25, .75)
				self:GetNormalTexture():SetVertexColor(1, 1, 1, 1)
				
				self:SetPushedTexture(Questra.textures.Green)
				self:GetPushedTexture():SetTexCoord(.75, .25, .75, .25)
				self:GetPushedTexture():SetVertexColor(1, 1, 1, 1)
			end
			
			if type(icon) ~= "table" then
				if textureIndex == "texture" then
					self.icon:SetTexCoord(0, 1, 0, 1)
					SetPortraitToTexture(self.icon, icon)
					
				elseif icon == "Interface/Minimap/POIIcons" and textureIndex then
					self.icon:SetTexture(icon)
					self.icon:SetTexCoord(GetPOITextureCoords(textureIndex))
				else
					self.icon:SetAtlas(icon)
					self.icon:SetTexCoord(L or 0, R or 1, T or 0, B or 1)
				end
			else
				self.icon:SetTexture("")
			end
		end

		pin.scripts = {
			OnMouseWheel = function(self, delta)
				Questra:UpdateDisplayed("Forced")

				local tracker = Questra:GetTracked()
				if tracker then
					tracker.ScrollMetrics(-delta)
				end

				Questra:CollectUpdate()
				Questra:Update()
			end,
			
			OnMouseDown = function(self, button)
				self.icon:SetSize(self.icon.width-5, self.icon.height-5)
			end,
			
			OnMouseUp = function(self, button)
				self.icon:SetSize(self.icon.width, self.icon.height)
			
				if MouseIsOver(self) then
					local tracker = Questra:GetTracked()
					if tracker then
						tracker.OnClick(button)
					end
				end
			end,
			
			OnEnter = function(self)
				if self.hl and not self.hl:IsVisible() then
					self.hl:Show()
				end
				GameTooltip_OnHide(GameTooltip)

				local tracker = Questra:GetTracked()
				local _ = tracker and tracker.SetTooltip()
			end,
			
			OnLeave = function(self)
				if self.hl:IsVisible() then
					self.hl:Hide()
				end
				GameTooltip:Hide()
			end,
		}
	
		Questra:AddElement(pin)
	end
	
	
	function Questra:UpdateEditIcon(editIcon, icon, L, R, T, B, skinDetails, textureIndex)
		if type(icon) ~= "table" then
			if textureIndex == "texture" then
				editIcon:SetTexCoord(0, 1, 0, 1)
				SetPortraitToTexture(editIcon, icon)
				
			elseif icon == "Interface/Minimap/POIIcons" and textureIndex then
				editIcon:SetTexture(icon)
				editIcon:SetTexCoord(GetPOITextureCoords(textureIndex))
			else
				editIcon:SetAtlas(icon)
				editIcon:SetTexCoord(L or 0, R or 1, T or 0, B or 1)
			end
		else
			editIcon:SetTexture("")
		end
	end
	
	Questra:AddElement({
		name = "coordinateText",
		parentElementName = "frame",

		Build = function(parentElement, ...)
			local editBox = CreateFrame("EditBox", AddonName.."_coordText", parentElement, "InputBoxScriptTemplate")
			editBox:SetSize((52/70) * size, 12)
			editBox:SetHighlightColor(.5,1,.5)
			editBox:SetClampedToScreen(true)
			editBox:SetJustifyH("CENTER")
			editBox:SetAutoFocus(false)
			editBox:SetPoint("Bottom", 0, -4)
			editBox:SetMovable(true)

			editBox:SetFrameStrata("LOW")
			editBox:SetFrameLevel(10)
			editBox:SetFixedFrameStrata(true)

			editBox:SetFontObject("GameFontNormal")
			editBox:SetFont(editBox:GetFont(), 9) --don't want to change font, just size.
			editBox:SetTextColor(1,1,1,1)

			editBox.button = CreateFrame("Button", nil, editBox)
				editBox.button:SetAllPoints(editBox)
				editBox.button:RegisterForClicks("AnyUp")
				editBox.button:SetScript("OnClick", function() editBox:SetFocus() end)

				local BORDER_THICKNESS = 1
				local r, g, b, a = 142/255,105/255,0, 1

				editBox.button.borderTop = editBox.button:CreateTexture(nil, 'HIGHLIGHT', 2)
					editBox.button.borderTop:SetColorTexture(r, g, b, a)
					editBox.button.borderTop:SetPoint("TOPLEFT", editBox.button, -BORDER_THICKNESS, BORDER_THICKNESS)
					editBox.button.borderTop:SetPoint("TOPRIGHT", editBox.button,  BORDER_THICKNESS, BORDER_THICKNESS)
					editBox.button.borderTop:SetHeight(BORDER_THICKNESS)

				editBox.button.borderBottom = editBox.button:CreateTexture(nil, 'HIGHLIGHT', 2)
					editBox.button.borderBottom:SetColorTexture(r, g, b, a)
					editBox.button.borderBottom:SetPoint("BOTTOMLEFT", editBox.button, -BORDER_THICKNESS, -BORDER_THICKNESS)
					editBox.button.borderBottom:SetPoint("BOTTOMRIGHT", editBox.button, BORDER_THICKNESS, -BORDER_THICKNESS)
					editBox.button.borderBottom:SetHeight(BORDER_THICKNESS)

				editBox.button.borderLeft = editBox.button:CreateTexture(nil, 'HIGHLIGHT', 2)
					editBox.button.borderLeft:SetColorTexture(r, g, b, a)
					editBox.button.borderLeft:SetPoint("TOPLEFT", editBox.button.borderTop)
					editBox.button.borderLeft:SetPoint("BOTTOMLEFT", editBox.button.borderBottom)
					editBox.button.borderLeft:SetWidth(BORDER_THICKNESS)

				editBox.button.borderRight = editBox.button:CreateTexture(nil, 'HIGHLIGHT', 2)
					editBox.button.borderRight:SetColorTexture(r, g, b, a)
					editBox.button.borderRight:SetPoint("TOPRIGHT", editBox.button.borderTop)
					editBox.button.borderRight:SetPoint("BOTTOMRIGHT", editBox.button.borderBottom)
					editBox.button.borderRight:SetWidth(BORDER_THICKNESS)

			    editBox.bg = editBox:CreateTexture(nil, 'BACKGROUND', 1)
					editBox.bg:SetPoint('TOPLEFT')
					editBox.bg:SetPoint('BOTTOMRIGHT')
					editBox.bg:SetColorTexture(0,0,0, .65)

			local r, g, b, a = 102/255,65/255,0, 1

			editBox.borderTop = editBox:CreateTexture(nil, 'OVERLAY', 2)
				editBox.borderTop:SetColorTexture(r, g, b, a)
				editBox.borderTop:SetPoint("TOPLEFT", editBox.bg, -BORDER_THICKNESS, BORDER_THICKNESS)
				editBox.borderTop:SetPoint("TOPRIGHT", editBox.bg,  BORDER_THICKNESS, BORDER_THICKNESS)
				editBox.borderTop:SetHeight(BORDER_THICKNESS)

			editBox.borderBottom = editBox:CreateTexture(nil, 'OVERLAY', 2)
				editBox.borderBottom:SetColorTexture(r, g, b, a)
				editBox.borderBottom:SetPoint("BOTTOMLEFT", editBox.bg, -BORDER_THICKNESS, -BORDER_THICKNESS)
				editBox.borderBottom:SetPoint("BOTTOMRIGHT", editBox.bg, BORDER_THICKNESS, -BORDER_THICKNESS)
				editBox.borderBottom:SetHeight(BORDER_THICKNESS)

			editBox.borderLeft = editBox:CreateTexture(nil, 'OVERLAY', 2)
				editBox.borderLeft:SetColorTexture(r, g, b, a)
				editBox.borderLeft:SetPoint("TOPLEFT", editBox.borderTop)
				editBox.borderLeft:SetPoint("BOTTOMLEFT", editBox.borderBottom)
				editBox.borderLeft:SetWidth(BORDER_THICKNESS)

			editBox.borderRight = editBox:CreateTexture(nil, 'OVERLAY', 2)
				editBox.borderRight:SetColorTexture(r, g, b, a)
				editBox.borderRight:SetPoint("TOPRIGHT", editBox.borderTop)
				editBox.borderRight:SetPoint("BOTTOMRIGHT", editBox.borderBottom)
				editBox.borderRight:SetWidth(BORDER_THICKNESS)
				

			return editBox
		end,

		Layout = function(self, sets)
			self:ClearAllPoints()
			if sets.flip == true then
				self:SetPoint("Top", 0, -1)
			else
				self:SetPoint("Bottom", 0, 1)
			end
		end,

		OnLocationUpdate = function(self, oX, oY, oID, dX, dY, dID)
			if oX and oY and self:HasFocus() ~= true then
				self:SetText(floor(oX*10000)/100 ..", "..floor(oY*10000)/100)
			elseif self:HasFocus() ~= true then
				self:SetText("")
			end
		end,
		
		scripts = {
			OnEditFocusLost   = function(self) self.hasFocus = nil self:HighlightText(0,0) end,
			
			OnEditFocusGained = function(self) self.hasFocus = true self:SetText("") end,
			
			OnEscapePressed   = function(self) self:ClearFocus() end,
			
			OnEnterPressed    = function(self)
				self:ClearFocus()
				--set nav point
			end,
		},
})
	
	do--metric indicator

		Questra:AddElement({
			name = "TrackerScrollButton",
			parentElementName = "frame",
			Build = function(parentElement, ...)
				local button = CreateFrame("Button", "Questra_notifyButton", parentElement)
				button:SetPoint("TopLeft", parentElement.pin, "BottomLeft", 0 , 25)
				button:SetPoint("BottomRight", parentElement.pin, 0, 0)

				button:SetHighlightTexture(Questra.textures.NotifyBridgeHighlight)
				button:SetPushedTexture(Questra.textures.NotifyBridgeBackGround)
				button:SetNormalTexture(Questra.textures.NotifyBridgeBackGround)
				button:SetHitRectInsets(15, 15, 0, 0)

				button:SetFrameStrata("LOW")
				button:SetFrameLevel(1)
				button:SetFixedFrameStrata(true)

				button.border = button:CreateTexture(nil, "LOW")
				button.border:SetAllPoints(button)
				button.border:SetTexture(Questra.textures.NotifyBridgeBorder)

				button.AltRouteFlasher = CreateFrame("Frame", nil, button, "Questra_AltRouteFlash")
				button.AltRouteFlasher:SetAllPoints(button.border)
				button.AltRouteFlasher.flash:SetTexture(Questra.textures.MetricFlash)
				
				button.AltRouteFlasher.flashAnimation:Play()
				return button
			end,

			Layout = function(self, sets)
				local l, r, t, b = 0, 1, 0, 1
				local point, relPoint, oPoint = "TopLeft", "BottomLeft", "BottomRight"
				local y = 25
				if sets.flip == true then
					l, r, t, b = 0, 1, 1, 0
					point, relPoint, oPoint = "BottomLeft", "TopLeft", "TopRight"
					y = -25
				end
			
				self:GetNormalTexture():SetTexCoord(l, r, t, b)
				self:GetHighlightTexture():SetTexCoord(l, r, t, b)
				self:GetPushedTexture():SetTexCoord(l, r, t, b)
				self.border:SetTexCoord(l, r, t, b)
				self.AltRouteFlasher.flash:SetTexCoord(l, r, t, b)
					
				self:ClearAllPoints()
				self:SetPoint(point, self:GetParent().pin, relPoint, 0 , y)
				self:SetPoint(oPoint, self:GetParent().pin, 0, 0)
			end,

			scripts = {
				OnMouseWheel = function(self, delta)
					Questra:UpdateDisplayed("Forced")

					Questra:UpdateTracking(delta)

					Questra:CollectUpdate()
					Questra:Update()
					self:GetScript("OnEnter")(self)
				end,
				
				OnEnter = function(self)
					local tracker = Questra:GetTracked()
					if not tracker then return end
					GameTooltip:SetOwner(Questra.TrackerScrollButton, "ANCHOR_LEFT")

					GameTooltip:SetText(tracker.displayText, 1, 1, 1)
					if tracker.metrics and tracker.GetScrollValue() then
						GameTooltip:AddDoubleLine("Displayed:", tracker.GetScrollValue().." / "..#tracker.metrics)
					end
					
					if Questra.possibleWaypont then
						GameTooltip:AddLine("Alternate Route Available")
						GameTooltip:AddLine("Click to take alternate Waypoint")
					
					elseif Questra.portalSense then
						GameTooltip:AddLine("Following Alternate Route")
						GameTooltip:AddLine("Click to clear alternate Waypoint")
					end
										
					if Questra.ignoredTYPES and #Questra.ignoredTYPES >= 1 then
						GameTooltip:AddLine("Ignored Quest Types:")

						for i, b in pairs(Questra.ignoredTYPES) do
							local _ = Questra.questTypes[b] and GameTooltip:AddLine("  -"..Questra.questTypes[b])
						end
					end
					
					GameTooltip_CalculatePadding(GameTooltip) --must be called to resize tooltip while scrolling.
					GameTooltip:Show()
				end,
				
				OnLeave = function(self)
					GameTooltip:Hide()
				end,
				
				OnMouseUp = function(self, btn)
					ObjectiveTracker_ToggleDropDown(self, function(self)
						local info = UIDropDownMenu_CreateInfo()
						info.text = Questra.possibleWaypont and "Follow Alternate Waypoint" or Questra.portalSense and "Clear Waypoint"
						info.notCheckable = 1
						info.func = function()
							Questra.portalSense = not Questra.portalSense and Questra.possibleWaypont or nil
						end
						UIDropDownMenu_AddButton(info, UIDROPDOWN_MENU_LEVEL)
					end)
					local p1, p2 = Questra.GetAnchorsNearestScreenCenter(self)
					DropDownList1:ClearAllPoints()
					DropDownList1:SetPoint(p2, self, p1)
				end
			},
		})
	end
	
	Questra:AddElement({
		name = "distanceText",
		parentElementName = "TrackerScrollButton",
		Build = function(parentElement, ...)
			local fontString = parentElement:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
			fontString:SetPoint("Center", 0, -6)

			local path = fontString:GetFont() -- Return the font path, height, and flags that may be used to construct an identical Font object.
			fontString:SetFont(path, 8) --don't want to change font, just size.
			fontString:SetWordWrap(false)
			fontString:SetText(" ")
			fontString:SetWidth(55)
			
			return fontString
		end,
		OnLocationUpdate = function(self, x, y, mapID, destX, destY, destMapID)
			if mapID and x and y and destMapID and destX and destY then
				local dist = IN_GAME_NAVIGATION_RANGE:format(Round(HBD:GetZoneDistance(mapID, x, y, destMapID, destX, destY)))
				self:SetText((dist and string.split(" ", dist)) ~= "0" and dist or "")
			else
				self:SetText("")
			end
		end
	})	


	do --Map Overlay
		local overlay = {
			name = "MapOverlayFrame",
			parentElementName = "frame",
			displayName = "Map",
		}
		overlay.options = {
			{
				kind = "CheckButton",
				title = "Hide Line",
				key = "hideLine",
				default = false,
				OnClick = function(self)
					overlay.sets.hideLine = not overlay.sets.hideLine
					self:SetChecked(overlay.sets.hideLine)
					
					overlay.Layout(overlay.frame, overlay.sets)	
				end,
				
				OnShow = function(self)
					self:SetChecked(overlay.sets.hideLine)
				end,
			},
		}

		overlay.Layout = function(self, sets)
			if overlay.sets and overlay.sets.hideLine == true then
				self.waypointLine:Hide()
			else
				self.waypointLine:Show()
			end
		end

		overlay.Build = function(parentElement, ...)
			local scrollFrame = CreateFrame("ScrollFrame", nil, WorldMapFrame.ScrollContainer)
			scrollFrame:SetAllPoints(WorldMapFrame.ScrollContainer)
			scrollFrame:SetFrameStrata("HIGH")
			scrollFrame:SetFrameLevel(700)

			local frame = CreateFrame("Frame", nil, scrollFrame)
			frame:SetAllPoints(scrollFrame)
			frame:SetFrameStrata("HIGH")
			frame:SetFrameLevel(700)
			frame:EnableMouse(false)

			scrollFrame:SetScrollChild(frame)

			frame.waypointLocationHandler = CreateFrame("Frame", nil, UIParent)
			frame.playerLocationHandler = CreateFrame("Frame", nil, UIParent)

			frame.waypointLine = frame:CreateLine(nil, "ARTWORK")
			frame.waypointLine:SetColorTexture(1,1,1,1)
			frame.waypointLine:SetThickness(9)

			frame.waypointMarker = frame:CreateTexture(nil, "HIGH")
			--frame.waypointMarker:SetTexture("Interface\\BUTTONS\\UI-StopButton")
			frame.waypointMarker:SetSize(25, 25)
			
			overlay.frame = frame
			
			return frame
		end

		overlay.OnLocationUpdate = function(self, x, y, mapID, destX, destY, destMapID, playerAngle, angle, oID_World)
			if overlay.sets and overlay.sets.hideLine == true then
				self.waypointLine:Hide()
				self.waypointMarker:Hide()
				return
			end
			
			local vID = Questra:GetViewedMapID()
			local _, _, vID_World = HBD:GetWorldCoordinatesFromZone(.21, 1, vID)

			local canvas = _G["WorldMapFrame"]:GetCanvas()
			if ((not canvas) or (not x) or (not y)) or (vID_World ~= oID_World) then
				self.waypointLine:Hide()
				self.waypointMarker:Hide()
				return
			end

			local _x, _y = HBD:TranslateZoneCoordinates(x, y, mapID, vID, true)
			local vX, vY = HBD:TranslateZoneCoordinates(destX, destY, destMapID, vID, true)
			
			if _x and _y then
				--using these cheaters helps to reduce intense maths.
				self.playerLocationHandler:SetPoint("TopLeft", WorldMapFrame)
				self.playerLocationHandler:SetPoint("BottomRight", canvas, _x * canvas:GetWidth(), _y * canvas:GetHeight())
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

			if angle then 
				local a = math.deg(math.rad(90) - angle) * (math.pi/180)

				local pX = ((w * _x)       - (math.cos(a) * dist)) * scale
				local pY = (((1 - _y) * h) - (math.sin(a) * dist)) * scale

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
	
		Questra:AddElement(overlay)	
	end

	local optionsParent

	local optionPanels = {	
	}

	local scrollPanel

	local optionItems = {}
	
	function optionItems.CheckButton(parent, optionDetails)
		local checkButton = CreateFrame("CheckButton", parent:GetName()..optionDetails.title, parent, "UICheckButtonTemplate")
		checkButton.text:SetText(optionDetails.title)
		checkButton:SetScript("OnClick", optionDetails.OnClick)
		checkButton:SetScript("OnShow", optionDetails.OnShow)
		optionDetails.OnShow(checkButton)
	
		return checkButton
	end

	function optionItems.Slider(parent, optionDetails)
		local contain = CreateFrame("Frame", nil, parent)
		contain:SetSize(parent:GetWidth(), 20)

		local slider = CreateFrame("Slider", parent:GetName()..optionDetails.title, contain, "HorizontalSliderTemplate")
		
		slider.Title = slider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		slider.Title:SetPoint("Left", contain, 3, 0)
		slider.Title:SetJustifyH("Left")		
		slider.Title:SetText(optionDetails.title)
		
		slider.Value = slider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		slider.Value:SetPoint("Right", contain, -3, 0)
		slider.Value:SetJustifyH("Right")		
		slider.Value:SetText(" ")
		slider.Value:SetWidth(25)
		
		slider:SetSize(150, 15)
		
		slider:SetPoint("TopLeft", slider.Title, "TopRight", 2, 0)
		slider:SetPoint("TopRight", slider.Value, "TopLeft", -2, 0)
		
		slider:SetMinMaxValues(optionDetails.min or 1, optionDetails.max or 200)
		
		slider:SetScript("OnValueChanged", function(self)
			optionDetails.OnValueChanged(slider)
			slider.Value:SetText(self:GetValue())
		
		end)
		slider:SetScript("OnShow", optionDetails.OnShow)
		
		slider:SetValueStep(optionDetails.step or 1)
		
		slider:SetScript("OnMouseWheel", function(_, delta) slider:SetValue(slider:GetValue() + (delta * slider:GetValueStep())) end)
		
		slider:SetObeyStepOnDrag(true)
		
		optionDetails.OnShow(slider)

	
		return contain
	end

	function optionItems.Button(parent, optionDetails)
		local button = CreateFrame("Button", nil, parent, "UIMenuButtonStretchTemplate")
		button:SetSize(parent:GetWidth(), 25)
		
		button.Text:SetText(optionDetails.title)
		
		button:SetScript("OnClick", optionDetails.OnClick)
	
		return button
	end

	function Questra:NewOptionPanel(optionInfo)
		optionInfo.panel = CreateFrame("Frame", optionsParent:GetName().."_"..optionInfo.name, optionsParent)
	
		optionInfo.panel.bg = optionInfo.panel:CreateTexture(nil, 'BACKGROUND', 2)
		optionInfo.panel.bg:SetColorTexture(0, 0, 0, .5)
		optionInfo.panel.bg:SetAllPoints(optionInfo.panel)
		optionInfo.panel:SetSize(180, 250)
		optionInfo.panel:SetPoint("TopLeft", optionsParent, (#optionPanels == 0) and 0 or (190 *  #optionPanels), -3)
		local yBase, yOffset = optionInfo.panel:GetBottom()
		
		local panelCount = #optionPanels
		
		if optionInfo.options then
			optionInfo.panel.Items = {}
		
			for i, optionDetails in pairs(optionInfo.options) do
				local item = optionItems[optionDetails.kind]
				if item then
					local object = item(optionInfo.panel ,optionDetails)
				
					object:SetPoint("TopLeft", 0, -5 -(#optionInfo.panel.Items * 30) )
					
					yOffset = object:GetBottom()
					
					tinsert(optionInfo.panel.Items, object)
				end
			end

		end
		if #optionPanels < 1 then
			scrollPanel.selector.Text:SetText(optionInfo.name)
		end
	
		tinsert(optionPanels, optionInfo)
		
		if yBase and yOffset and ((yBase - yOffset) > 0) then
			local range = (yBase - yOffset) + 8
		
		
			optionInfo.panel:SetSize(180, 250 + range)
		
		
		
			local scroll = 0
			optionInfo.panel:SetScript("OnMouseWheel", function(_, delta)
				scroll = scroll - (delta*20)
				
				scroll = max(0, min(range, scroll))
				
				
				optionInfo.panel:SetPoint("TopLeft")
			
				optionInfo.panel:SetPoint("TopLeft", optionsParent, (panelCount == 0) and 0 or (190 *  panelCount), (-3) + scroll)
			
			end)
		end
		
		optionsParent.Qty:SetText(1 .."/".. #optionPanels)
	end

	function Questra:ToggleOptions()
		ToggleFrame(_G[AddonName.."_options"])
	end

	Questra:AddElement({
		name = "options",
		parentElementName = "frame",

		Build = function(parentElement)
			local options = CreateFrame("Frame", AddonName.."_options", UIParent, "TooltipBorderedFrameTemplate")
				options:SetFrameStrata("MEDIUM")
				options:SetFixedFrameStrata(true)
				options:Hide()
				options:SetSize(200, 300)
				parentElement.options = options
				options:SetPoint("CENTER")
				
				options.close = CreateFrame("Button", options:GetName().."_closeButton", options, "UIPanelCloseButton")
				options.close:SetPoint("TopRight")
				
				options.Title = options:CreateFontString(nil, "ARTWORK", "GameFontNormal")
				options.Title:SetPoint("TopLeft", options, 10, -10)
				options.Title:SetJustifyH("Left")
				options.Title:SetPoint("TopRight", options.close, "TopLeft")
				options.Title:SetText("Questra")
				
				local h = 23
				
				options.selector = CreateFrame("Frame", nil, options, "TooltipBorderedFrameTemplate")
				options.selector:SetHeight(h)
				options.selector:SetPoint("TopLeft", (h + 2), -27)
				options.selector:SetPoint("TopRight", -(h + 2), -27)
				options.selector.Text = options.selector:CreateFontString(nil, "ARTWORK", "GameFontNormal")
				options.selector.Text:SetPoint("Left", 5, 0)
				
				options.selector.Page = options.selector:CreateFontString(nil, "ARTWORK", "GameFontNormal")
				options.selector.Page:SetPoint("Right", -5, 0)
				options.selector.Text:SetPoint("Right", options.selector.Page, "Left", -3, 0)
				
				options.selector.Text:SetJustifyH("LEFT") 
				
				do
					local button = CreateFrame("Button", nil, options.selector)
					button:SetSize(h-6, h-3)
					button:RegisterForClicks("AnyUp")
					button:SetPoint("Right", options.selector, "Left", 0, 0)
	
					button:SetHitRectInsets(0, -options.selector:GetWidth()/2, -1.5, -1.5)

					button:SetHighlightTexture(Questra.textures.LeftArrowHighlight)
					button:SetPushedTexture(Questra.textures.LeftArrowPushed)
					button:SetNormalTexture(Questra.textures.LeftArrow)
					button:GetHighlightTexture():SetBlendMode("ADD")

					button:GetNormalTexture():SetVertexColor(1,1,1, 1)
					button:GetPushedTexture():SetVertexColor(1,1,1, 1)
					button:GetHighlightTexture():SetVertexColor(1,1,1, 1)
					
					button:SetScript("OnClick", function()
						options.selector:GetScript("OnMouseWheel")(options.selector, 1)
					end)
					button:Hide()
					
					options.selector.left = button
				end
				
				do
					local button = CreateFrame("Button", nil, options.selector)
					button:SetSize(h-6, h-3)
					button:RegisterForClicks("AnyUp")
					button:SetPoint("Left", options.selector, "Right", 0, 0)

					button:SetHitRectInsets(-options.selector:GetWidth()/2, 0, -1.5, -1.5)

					button:SetHighlightTexture(Questra.textures.LeftArrowHighlight)
					button:SetPushedTexture(Questra.textures.LeftArrowPushed)
					button:SetNormalTexture(Questra.textures.LeftArrow)
					button:GetHighlightTexture():SetBlendMode("ADD")
					
					button:GetHighlightTexture():SetTexCoord(1,0,0,1)
					button:GetNormalTexture():SetTexCoord(1,0,0,1)
					button:GetPushedTexture():SetTexCoord(1,0,0,1)

					button:GetHighlightTexture():SetVertexColor(1,1,1, 1)
					button:GetNormalTexture():SetVertexColor(1,1,1, 1)
					button:GetPushedTexture():SetVertexColor(1,1,1, 1)
					
					button:SetScript("OnClick", function()
						options.selector:GetScript("OnMouseWheel")(options.selector, -1)
					end)
					
					options.selector.right = button
				end
	
				options.ScrollPanel = CreateFrame("ScrollFrame", options:GetName().."_ScrollPanel", options)
				options.ScrollPanel:SetPoint("TopLeft", options, 10, -(27+18 +3))
				options.ScrollPanel:SetPoint("BottomRight", options, -10, 10)
				options.child = CreateFrame("Frame", options:GetName().."_Container", options.ScrollPanel)
				options.ScrollPanel:SetScrollChild(options.child)
				options.child:SetPoint("TopLeft")
				options.child:SetSize(180, 300)
				
				optionsParent = options.child
				options.child.Qty = options.selector.Page
				options.selector:EnableMouse(true)
				
				scrollPanel = options.ScrollPanel
				scrollPanel.selector = options.selector
				options.selector:SetScript("OnMouseWheel", function(self,delta)
					local _min = 0
					local  _max = (#optionPanels - 1) * 190
					local val = min(max(_min, options.ScrollPanel:GetHorizontalScroll() - (delta * 190)), _max)
					local panel = floor(val/190) + 1
					options.ScrollPanel.selector.Text:SetText(optionPanels[panel].name)
					options.ScrollPanel:SetHorizontalScroll(val)
					
					if val <= 190 then
						options.selector.left:Hide()
					else
						options.selector.left:Show()
					end
					
					if val >= _max then
						options.selector.right:Hide()
					else
						options.selector.right:Show()
					end
					
					options.selector.Page:SetText(panel .."/".. #optionPanels)
				end)
			return options
		end,

		scripts = {
			OnMouseDown = function(self)
				self:SetMovable(true)
				self:StartMoving()
			end,
			
			OnMouseUp = function(self, button)
				self:StopMovingOrSizing()
			end,
		},
	})

	Questra:AddElement({
		name = "dragFrame",
		parentElementName = 'frame',

		Build = function(parentElement)
			local dragFrame = CreateFrame("Button", AddonName.."_dragFrame", parentElement)
				dragFrame:SetFrameStrata("MEDIUM")
				dragFrame:SetFixedFrameStrata(true)
				dragFrame:SetAllPoints(parentElement)
				dragFrame:Hide()

				dragFrame.texture = dragFrame:CreateTexture(nil, "OVERLAY")
				dragFrame.texture:SetColorTexture(0, 1, 0, .45)
				dragFrame.texture:SetAllPoints(dragFrame)
				
				parentElement.dragFrame = dragFrame
				
				
			return dragFrame
		end,

		scripts = {
			OnClick = function(self)
				
			end,
			
			OnMouseDown = function(self, btn)
				if btn == "LeftButton" then
					self:GetParent():SetMovable(true)
					self:GetParent():StartMoving()
				end
			end,
			
			OnMouseUp = function(self, btn)
				if btn == "RightButton" then
					ToggleFrame(self:GetParent().options)
				else
			
					self:GetParent():StopMovingOrSizing()
					Questra:Stick()
				end
			end,
			
			OnShow = function() end,
		},
	})
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

local editMenu = {}

editMenu.Create = function()
	if editMenu.menu then return editMenu.menu end

	editMenu.menu = CreateFrame("Frame", AddonName.."EditMenu", UIParent, "TooltipBorderedFrameTemplate")
	editMenu.menu:SetSize(400, 150)
	editMenu.menu:SetPoint("Center")

	editMenu.menu.close = CreateFrame("Button", editMenu.menu:GetName().."_closeButton", editMenu.menu, "UIPanelCloseButton")
	editMenu.menu.close:SetPoint("TopRight")

	editMenu.menu.Title = editMenu.menu:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	editMenu.menu.Title:SetPoint("TopLeft", editMenu.menu, 10, -10)
	editMenu.menu.Title:SetJustifyH("Left")
	editMenu.menu.Title:SetPoint("TopRight", editMenu.menu.close, "TopLeft")
	editMenu.menu.Title:SetText("Questra: Edit Waypoint")

	editMenu.menu.DescriptionTitle = editMenu.menu:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	editMenu.menu.DescriptionTitle:SetPoint("TopLeft", editMenu.menu, 10, -35)
	editMenu.menu.DescriptionTitle:SetJustifyH("Left")
	editMenu.menu.DescriptionTitle:SetText("Waypoint Title:")

	

	editMenu.menu.Description = CreateFrame("EditBox", AddonName.."_WaypointEditDesc", editMenu.menu, "Questra_TooltipBorderEditBoxTemplate")
	editMenu.menu.Description:SetPoint("Left", editMenu.menu.DescriptionTitle, "Right", 10,  0)
	editMenu.menu.Description:SetPoint("Right", -10,  0)
	editMenu.menu.Description:SetSize(350, 25)
	editMenu.menu.Description:SetAutoFocus(false)

	

	editMenu.menu.Description.x = 4
	editMenu.menu.Description.y = 2

	editMenu.menu.Description:Hide()
	editMenu.menu.Description:Show()

	editMenu.menu.Description:SetFontObject("GameFontNormal")
	editMenu.menu.Description:SetFont(editMenu.menu.Description:GetFont(), 12) --don't want to change font, just size.
	editMenu.menu.Description:SetTextColor(1,1,1,1)
	
	editMenu.menu.TooltipTitle = editMenu.menu:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	editMenu.menu.TooltipTitle:SetPoint("TopLeft", editMenu.menu.DescriptionTitle, "BottomLeft", 0, -15)
	editMenu.menu.TooltipTitle:SetJustifyH("Left")
	editMenu.menu.TooltipTitle:SetText("Waypoint Tooltip:")

	local scrollFrame = CreateFrame("ScrollFrame", nil, editMenu.menu, "TooltipBorderedFrameTemplate")
	scrollFrame:SetSize(350, 80)

	scrollFrame:SetPoint("TopLeft", editMenu.menu.TooltipTitle, "TopRight")
	scrollFrame:SetPoint("BottomRight", editMenu.menu, -7, 30)

	editMenu.menu.Tooltip = CreateFrame("EditBox", AddonName.."_WaypointEditTooltip", editMenu.menu, "InputBoxScriptTemplate")
	
	editMenu.menu.Description:SetScript("OnEnterPressed", function() editMenu.menu.Tooltip:SetFocus() end)

	editMenu.menu:SetScript("OnShow", function() editMenu.menu.Description:SetFocus() end)
	
	scrollFrame:SetScrollChild(editMenu.menu.Tooltip)
	
	editMenu.menu.Tooltip:SetPoint("TopLeft",7, -7)
	editMenu.menu.Tooltip:SetPoint("BottomRight", -4,  7)
	editMenu.menu.Tooltip:SetAutoFocus(false)
	editMenu.menu.Tooltip:SetMultiLine(true)

	editMenu.menu.Tooltip:SetFontObject("GameFontNormal")
	editMenu.menu.Tooltip:SetFont(editMenu.menu.Tooltip:GetFont(), 12) --don't want to change font, just size.
	editMenu.menu.Tooltip:SetTextColor(1,1,1,1)
		
	editMenu.menu:SetScript("OnMouseDown", function(self)
		self:SetMovable(true)
		self:StartMoving()
	end)

	editMenu.menu:SetScript("OnMouseUp", function(self, button)
		self:StopMovingOrSizing()
	end)

	local button = CreateFrame("Button", nil, editMenu.menu, "UIMenuButtonStretchTemplate")
	button:SetSize(100, 25)
	button.Text:SetText("Save")

	button:SetPoint("BottomRight", -7, 5)

	local buttonb = CreateFrame("Button", nil, editMenu.menu, "UIMenuButtonStretchTemplate")
	buttonb:SetSize(100, 25)
	buttonb.Text:SetText("Cancel")

	buttonb:SetPoint("Right", button, "Left")


	local icon = editMenu.menu:CreateTexture(nil, "ARTWORK", 25)
	icon:SetPoint("TopLeft", editMenu.menu.TooltipTitle, "BottomLeft", 10, -20)
	icon:SetSize(50,50)
	editMenu.menu.icon  = icon

	icon.title = editMenu.menu:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	icon.title:SetPoint("Bottom", icon,"Top", 8, 0)
	icon.title:SetJustifyH("Center")
	icon.title:SetText("Display Icon")

	icon.frame = CreateFrame("Frame", nil, editMenu.menu)
	icon.frame:SetPoint("TopLeft", icon.title)
	icon.frame:SetPoint("Right", icon.title)
	icon.frame:SetPoint("Bottom", icon)
	icon.frame:EnableMouse(true)
	icon.frame:SetScript("OnMouseWheel", function(_, delta)
		if editMenu.menu.icon.scrollIndex then
			editMenu.menu.icon.scrollIndex = max(0, min(#Questra.scrollable, (editMenu.menu.icon.scrollIndex - delta)))
			
			
			local details = Questra.scrollable[editMenu.menu.icon.scrollIndex]
			
			
			if details then
				local name, textureID = unpack(details)
						
				editMenu.menu.iconID = textureID
						
				if type(Questra.iconDisplayInfo[textureID]) == "table" then
					Questra:UpdateEditIcon(editMenu.menu.icon, unpack(Questra.iconDisplayInfo[textureID]))
				else
					Questra:UpdateEditIcon(editMenu.menu.icon, Questra.iconDisplayInfo[textureID]())
				end
			end
		end
	
	
	end)


	button:SetScript("OnClick", function()
		if editMenu.menu.userPoint then
			local t = editMenu.menu.Description:GetText()
			local d = editMenu.menu.Tooltip:GetText()

			if strtrim(t) ~= "" then
				editMenu.menu.userPoint.title = t
			end

			editMenu.menu.userPoint.tooltip = d
			
			editMenu.menu.userPoint.icon = editMenu.menu.iconID or editMenu.menu.userPoint.icon
			Questra:CollectUpdate()
			
			Questra:Update()
		elseif editMenu.menu.toSave then
			local tracking = editMenu.menu.toSave.tracking
			

					local x, y, mapID = unpack(editMenu.menu.toSave.userPoint)
					
					local metric = (x and y and mapID) and  mapID..x..y
					
					
					local position = CreateVector2D(floor(x*10000) / 10000, floor(y*10000) / 10000)
					position.mapID = mapID
					
					
					local details = metric and (tracking.referenceDetails[metric]
					or {
						title = editMenu.menu.Description:GetText(),
						tooltip = editMenu.menu.Tooltip:GetText(),
						x = floor(x*10000) / 10000 ,
						y = floor(y*10000) / 10000 ,
						mapID = mapID,
						position = position,
						icon = editMenu.menu.iconID or "anchor",
						["time"] = GetTime(),
						_time = GetTime(),
						referenceDetailsIndex = metric
					}) or nil
						
					if details and not tracking.referenceDetails[metric] then
						Questra:AddMapPinData(details)
						
						
						tinsert(tracking.metrics, 1, details)
						tracking.referenceDetails[metric] = details
						tracking.scrollValue = 1
						tracking.SetToMetric(1)
						tracking.saved = true
						Questra:SetTrackingByName("way")
						editMenu.menu:Hide()
					end

			editMenu.menu.toSave = nil
		end
	end)

	buttonb:SetScript("OnClick", function()
		editMenu.menu:Hide()
		editMenu.menu.Description:SetText("")
		editMenu.menu.Tooltip:SetText("")
		editMenu.menu.userPoint = nil
		editMenu.menu.toSave = nil
		
	end)

	return editMenu.menu
end

editMenu.CreateNew = function(tracking)
	local userPoint = {}
	local menu = editMenu.Create()

	local save = {}

	local x, y, mapID = Questra.GetPlayerPosition()
	save.userPoint = {x , y , mapID}
		
	local mapInfo = C_Map.GetMapInfoAtPosition(tonumber(mapID), x, y)
	mapInfo = (not mapInfo) and C_Map.GetMapInfo(tonumber(mapID)) or mapInfo
	local title = mapInfo and mapInfo.name
	
	menu.Description:SetText(title ~= "" and title or "Waypoint")
	menu.Tooltip:SetText("")

	menu.icon.scrollIndex = Questra:GetPreviewIconIndex("way")
	Questra:UpdateEditIcon(menu.icon, Questra.iconDisplayInfo["way"]())
	
	menu.iconID = "way"
	
	save.tracking = tracking

	menu.toSave = save
	menu:Show()
end

editMenu.Show = function(userPoint, tracking)
	
	local x, y, mapID = Questra.GetPlayerPosition()

	local metric = (x and y and mapID) and  mapID..x..y

	if metric and tracking and tracking.referenceDetails[metric] then
		return
	end

	if userPoint == true then
		return editMenu.CreateNew(tracking)
	end

	local menu = editMenu.Create()
	menu.Description:SetText(userPoint.title or "")
	menu.Tooltip:SetText(userPoint.tooltip or "")
	
	if userPoint.icon then

		local icon = (userPoint.icon == "raid") and Enum.QuestTagType.Raid
		or (userPoint.icon == "dungeon") and Enum.QuestTagType.Dungeon
		or userPoint.icon
	
		if type(icon) == "table" then
			local i, _, textureIndex = unpack(icon)
		
			if textureIndex then
				icon = textureIndex
			end
		
		end
	
	
		menu.icon.scrollIndex = Questra:GetPreviewIconIndex(icon)
				
		if type(Questra.iconDisplayInfo[icon]) == "table" then
			Questra:UpdateEditIcon(menu.icon, unpack(Questra.iconDisplayInfo[icon]))

		elseif icon then	
			Questra:UpdateEditIcon(menu.icon, Questra.iconDisplayInfo[icon]())
		end
	end
	
	
	menu.userPoint = userPoint
	menu:Show()
end

do --tracking management
	do
		Questra.basicSkin = {
			"CircleMask",
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
			[129] = {"Mobile-FirstAid"      , 0, 1, 0, 1},
			[164] = {"Mobile-Blacksmithing" , 0, 1, 0, 1},
			[165] = {"Mobile-Leatherworking", 0, 1, 0, 1},
			[171] = {"Mobile-Alchemy"       , 0, 1, 0, 1},
			[182] = {"Mobile-Herbalism"     , 0, 1, 0, 1},
			[186] = {"Mobile-Mining"        , 0, 1, 0, 1},
			[202] = {"Mobile-Engineering"   , 0, 1, 0, 1},
			[333] = {"Mobile-Enchanting"    , 0, 1, 0, 1},
			[755] = {"Mobile-Jewelcrafting" , 0, 1, 0, 1},
			[773] = {"Mobile-Inscription"   , 0, 1, 0, 1},
			[794] = {"Mobile-Archeology"    , 0, 1, 0, 1},
			[356] = {"Mobile-Fishing"       , 0, 1, 0, 1},
			[185] = {"Mobile-Cooking"       , 0, 1, 0, 1},
			[197] = {"Mobile-tailoring"     , 0, 1, 0, 1},
			[393] = {"Mobile-Skinning"      , 0, 1, 0, 1},
			--[177] = {"Mobile-Archeology"    , 0, 1, 0, 1},
			[177]                          = function() return "Mobile-Archeology", 0, 1, 0, 1 end,
			["treasure"]                   = function() return "vignetteloot", 0, 1, 0, 1 end,
			["dig"]                        = function() return "Mobile-Archeology", 0, 1, 0, 1 end,
			["way"]                        = function() return "ShipMissionIcon-Bonus-Mission", 0, 1, 0, 1 end,
			["dead"]                       = function() return "poi-graveyard-neutral", 0, 1, 0, 1 end,
			["daily"]                      = function() return "QuestDaily" end,
			["flight"]                     = function() return "Taxi_Frame_Gray" end,
			["normal"]                     = function() return "QuestNormal" end,
			["trivial"]                    = function() return "TrivialQuests" end,
			["campaign"]                   = function() return "Quest-Campaign-Available" end,
			["complete"]                   = function() return "questlog-waypoint-finaldestination-questionmark", -.05, 1.01, .16, .87 end,
			["legendary"]                  = function() return "QuestLegendary" end,
			
			["anchor"]               	   = function() return "ShipMissionIcon-Training-MapBadge" end,

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
				local icon = (faction == "Horde") and ("hordesymbol")
					or (faction == "Alliance") and "alliancesymbol"
					
					if not icon then return "placeholder-icon", .25, .75, .25, .75 end
				
				return icon, .15, .9, .1, .85
			end,


			--[Enum.QuestTagType.Contribution]   = function() return "", 0, 1, 0, 1 end,
			--[Enum.QuestTagType.RatedReward]   = function() return "", 0, 1, 0, 1 end,
			--[Enum.QuestTagType.Normal]   = function() return "", 0, 1, 0, 1 end,
			--[Enum.QuestTagType.Bounty]   = function() return "", 0, 1, 0, 1 end,
			--[Enum.QuestTagType.CovenantCalling]   = function() return "", 0, 1, 0, 1 end,
			--[Enum.QuestTagType.InvasionWrapper]   = function() return "", 0, 1, 0, 1 end,
			
			
			["rare"] = function() return "warfront-neutralhero-silver" end,
			["elite"] = function() return "warfront-neutralhero-gold" end,
			
			
			["innkeeper"] = function() return "innkeeper" end,
			["stable"] = function() return "stablemaster" end,
			["class"] = function() return "class" end,
			["reagents"] = function() return "reagents" end,
			["chatballon"] = function() return "chatballon" end,
			["mailbox"] = function() return "mailbox" end,
			["barbershop"] = function() return "barbershop-32x32" end,
			["auctioneer"] = function() return "auctioneer" end,
			["food"] = function() return "food" end,
			["banker"] = function() return "banker" end,
			["town"] = function() return "poi-town" end,
			["city"] = function() return "poi-majorcity" end,
			["workorders"] = function() return "poi-workorders" end,
			["poisons"] = function() return "poisons" end,
			["profession"] = function() return "profession" end,
			["ferry"] = function() return "flightmasterferry" end,
			
			
			["waypoint"] = function() return "Waypoint-MapPin-Tracked" end,

			["alliancePortal"] = function() return "warlockportalalliance" end,
			["hordePortal"] = function() return "warlockportalhorde" end,
			["portal"] = function() return "teleportationnetwork-32x32" end,
		}

		Questra.scrollable =  {
			{"First Aid", 129},     
			{"Blacksmithing", 164}, 
			{"Leatherworking", 165}, 
			{"Alchemy", 171},        
			{"Herbalism", 182},    
			{"Mining", 186},      
			{"Engineering", 202},   
			{"Enchanting", 333},     
			{"Jewelcrafting", 755},  
			{"Inscription", 773},    
			{"Archaeology", 794},    
			{"Fishing", 356},        
			{"Cooking", 185},     
			{"Tailoring", 197},      
			{"Skinning", 393},       

			{"Treasure", "treasure"},     
			{"Dig Site", "dig"},       
			{"Waypoint", "way"},   
			{"Dead", "dead"},      
			{"Daily Quest", "daily"},       
			{"Flight Point", "flight"},  
			{"Normal Quest", "normal"},      
			{"Trivial Quest", "trivial"},     
			{"Campaign", "campaign"},    
			{"Complete Quest", "complete"},      
			{"Legendary Quest", "legendary"},
			
			{"Anchor", "anchor"}, 

			{"PvP", Enum.QuestTagType.PvP},
			{"Raid", Enum.QuestTagType.Raid}, 
			{"Threat", Enum.QuestTagType.Threat}, 
			{"Islands", Enum.QuestTagType.Islands}, 
			{"Dungeon", Enum.QuestTagType.Dungeon}, 
			{"Invasion", Enum.QuestTagType.Invasion}, 
			{"PetBattle", Enum.QuestTagType.PetBattle}, 
			
			{"Faction", Enum.QuestTagType.FactionAssault},
			
			{"Rare", "rare"},
			{"Elite", "elite"},
			
			{"Stable", "stable"},
			{"Class", "class"},
			{"Reagents", "reagents"},
			{"chatBall", "chatballon"},
			
			{"Innkeeper", "innkeeper"},
			{"Mailbox", "mailbox"},
			{"Barbershop", "barbershop"},
			{"Auctioneer", "auctioneer"},
			
			{"Food", "food"},
			{"Banker", "banker"},
			{"Town", "town"},
			{"City", "city"},
			
			{"Workorders", "workorders"},
			{"Poisons", "poisons"},
			{"Profession", "profession"},
			{"Ferry", "ferry"},
			{"Waypoint", "waypoint"},
			
			{"HordePortal", "hordePortal"},
			{"AlliancePortal", "alliancePortal"},
		}

		function Questra:GetIconFromAtlas(atlasName)
			for i, b in pairs(Questra.iconDisplayInfo) do
				if type(b) == "function" then
					local a, b, c, d, e = b()
					if a == atlasName then
						return i
					end
				elseif type(b) == "table" then
					local a, b, c, d, e = unpack(b)
					if a == atlasName then
						return i
					end
				end
			end
		end

		function Questra:GetIconDetails(title)			
			local t = Questra.iconDisplayInfo[title]
		
			if t then
			
				if type(t) == "table" then
					return unpack(t)
				elseif type(t) == "function" then
					return t()
				end
			end
		
		end

		function Questra:GetPreviewIconIndex(icon)
			for i, b in pairs(Questra.scrollable) do
				if icon == b[2] then
					return i
				end
			end
			return 1
		end
		
		Questra.questQualityBorderTextures = { --NYI: do not delete
			[Enum.WorldQuestQuality.Common] = "auctionhouse-itemicon-border-white",
			[Enum.WorldQuestQuality.Rare] = "auctionhouse-itemicon-border-blue",
			[Enum.WorldQuestQuality.Epic] = "auctionhouse-itemicon-border-purple",
		}

		Questra.questQualityTextures = {
			[Enum.WorldQuestQuality.Epic]   = {"worldquest-questmarker-epic", {1,1,1,1}},
			[Enum.WorldQuestQuality.Rare]   = {"worldquest-questmarker-rare", {1,1,1,1}},
			[Enum.WorldQuestQuality.Common] = {"CircleMask"                 , {168/256,115/256,46/256}},
		}

		Questra.typesIndex = {}
		
		Questra.addedIndex = {}

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
		tinsert(Questra.addedIndex, infoTable.trackingName)
		tinsert(Questra.tracking, infoTable)
		Questra.trackByName[infoTable.trackingName] = infoTable

		if infoTable.options then
			tinsert(infoTable.options, 1, {
				kind = "CheckButton",
				title = "Disable",
				key = "disable",
				default = false,
				OnClick = function(self)
					infoTable.sets.disable = not infoTable.sets.disable
					self:SetChecked(infoTable.sets.disable)
					
					if infoTable.sets.disable == true then
						infoTable.metricUpdate = nil
						infoTable.lastMetric = nil
						Questra.UpdateAutoTracking("FORCED")
					end
					Questra:UpdateTracking(0)
					Questra.UpdateAutoTracking("FORCED")
				end,
				OnShow = function(self)
					self:SetChecked(infoTable.sets.disable)
				end,
			})
		
		end

		if infoTable.events then
			for i, event in pairs(infoTable.events) do
				eventManager[event] = eventManager[event] or {}
				local _ = nil, (not tContains(Questra.Events, event)) and tinsert(Questra.Events, event)
				_ = nil, (not tContains(eventManager[event], infoTable)) and tinsert(eventManager[event], infoTable)
			end
		end

		local _ = nil, (not tContains(eventManager.Forced, infoTable)) and tinsert(eventManager.Forced, infoTable)
	end

	function Questra:LoadTrackingOptions()
	
		for _, track in pairs(Questra.tracking) do
		
			Quest_Compass_DB.widgets[track.trackingName] = Quest_Compass_DB.widgets[track.trackingName] or {}
		
			track.sets = Quest_Compass_DB.widgets[track.trackingName]
		
			if track.OnLoad then
				track.OnLoad()
			end
		
			Questra:NewOptionPanel({
				name = track.displayText,
				options = track.options
			})
		
		end
	
	end

	function Questra:SaveAndRestoreTracking()
		Quest_Compass_DB.Stored = Quest_Compass_DB.Stored or {}
		Quest_Compass_DB.RefStored = Quest_Compass_DB.RefStored or {}
		for _, track in pairs(Questra.tracking) do
			if track.save then
				Quest_Compass_DB.Stored[track.trackingName] = Quest_Compass_DB.Stored[track.trackingName] or {}
				track.metrics = Quest_Compass_DB.Stored[track.trackingName]

				if track.referenceDetails then
					Quest_Compass_DB.RefStored[track.trackingName] = Quest_Compass_DB.RefStored[track.trackingName] or {}
					track.referenceDetails = Quest_Compass_DB.RefStored[track.trackingName]
				end
			end
		end
	end

	--[[
		note: there is no logic for the color 
		used for each tracking type. I chose
		random colors, just to create a quick
		visual reference for which tracking
		type is being shown. ~Goranaws
	--]]

	local function _GetQuestProgressBarPercent(questID)
		local percent = GetQuestProgressBarPercent(questID)
		local have, need = 0, 0
	
		for index = 1, C_QuestLog.GetNumQuestObjectives(questID) do
			local text, objectiveType, finished, fulfilled, required = GetQuestObjectiveInfo(questID, index, false)
			if text then
				have = have + fulfilled
				need = need + required
			end
		end
	
		if have ~= 0 and need ~= 0 then
			percent = percent + ((have/need) * 100)
		end
	
		return percent ~= 0 and percent or nil
	end

	do local track = {trackingName = "dead",       displayText = "Dead",             color = {.5, .5, .5}, metrics = {}, scrollValue = 1, save = true, allowPortals = nil, allowFlights = nil} --the dead can't fly pr portal
		--[[constants: to be used by each tracking type, for consistency!
			track.metrics --what to track ID or Table (prefer ID, less to track)
			track.lastMetric
			track.scrollValue
			...to be continued!
		--]]

		track.options =  {

		}

		track.GetLocation = function(questID)
			return track.metrics[1]
		end

		track.GetMetricInfo = function(playerX, playerY, playerMapID)

		end

		track.OnEvent = function()
			-- if (not track.sets) or (track.sets.disable == true) then
				-- return nil
			-- end
		
		
			if not track.metricUpdate then
				track.metricUpdate = true
				local id = digForWorldMapID(Questra:GetPlayerMapID())
				local userPoint = C_DeathInfo.GetCorpseMapPosition(id)

				if userPoint then
					local id, x, y = id , userPoint.x, userPoint.y
					if id and x and y then
						local stored = track.metrics[1]
						if (not stored)
						or ((x ~= stored.x) or (y ~= stored.y) or (id ~= stored.mapID)) then
							track.metrics[1] =  track.metrics[1] or {}
								track.metrics[1].x = x
								track.metrics[1].y = y
								track.metrics[1].mapID = id
								track.metrics[1].time = GetTime()
							return true
						end
					end
				elseif track.metrics[1] then
					track.metrics[1].x = nil
					track.metrics[1].y = nil
					track.metrics[1].id = nil
					track.metrics[1].time = nil
					

				end
				track.metricUpdate = nil
			end
					Questra:CollectUpdate()
					Questra:Update()
		end

		track.ScrollMetrics = function(delta) end

		track.GetScrollValue = function(delta) end

		track.SetToMetric = function() end

		track.SetTooltip = function()
			local userPoint = track.GetLocation()
			if userPoint then
				local id, x, y = userPoint.mapID , userPoint.x, userPoint.y
				if id and x and y then

					GameTooltip:SetOwner(Questra.pin, "ANCHOR_LEFT")
					GameTooltip:SetText("Dead", 1, 1, 1)
					GameTooltip:AddLine("You have died!", 1, 0, 0)

					if userPoint.time then
						local diff = GetTime() - userPoint.time
						GameTooltip:AddDoubleLine("Time since death:", string.format(SecondsToTime(diff, diff>60)))
					end

					local mapInfo = C_Map.GetMapInfo(tonumber(id))

					local _name = MapUtil.FindBestAreaNameAtMouse(tonumber(id), x, y)


					if _name and _name ~= mapInfo.name then
						_name = mapInfo.name..", ".._name..":"
					else
						_name = mapInfo.name..":"
					end
					
					
					local x = string.format("%.2f" , x*100)
					local y = string.format("%.2f" , y*100)
					
					GameTooltip:AddDoubleLine(_name, x .. ", ".. y)

					GameTooltip_CalculatePadding(GameTooltip) --must be called to resize tooltip while scrolling.
					GameTooltip:Show()
				end
			end
		end

		track.ShouldShow = function()
			if (not track.sets) or (track.sets.disable == true) then
				return nil
			end
		
			local id = digForWorldMapID(Questra:GetPlayerMapID())
			local corpse = C_DeathInfo.GetCorpseMapPosition(id)
			if corpse then
				local id, x, y = id , corpse.x, corpse.y
				if id and x and y then
					return true
				end
			end
		end

		track.ShouldAutoSwap = function(newAutoSwap)		
			-- if (not track.sets) or (track.sets.disable == true) then
				-- return nil
			-- end
			
			local id = digForWorldMapID(Questra:GetPlayerMapID())
			local corpse = C_DeathInfo.GetCorpseMapPosition(id)

			if corpse then
				local metric  = corpse.x .. corpse.y .. id
				if metric and (metric ~= track.lastMetric) then
					track.lastMetric = metric
					return true
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

				local x, y, mapID = userPoint.x, userPoint.y, userPoint.mapID

				Questra:PingAnywhere("chat", x, y, mapID)
			elseif userPoint then
				if userPoint.mapID and userPoint.x and userPoint.y then
					local x, y, mapID = userPoint.x, userPoint.y, userPoint.mapID
					Questra:PingAnywhere("map", x, y, mapID)
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

	do local track = {trackingName = "quest",      displayText = "Quests",           color = {1, 0, 0}, metrics = {}, scrollValue = 1, allowPortals = true, allowFlights = true}

		track.options =  {
			{
				kind = "CheckButton",
				title = "Sort by Distance",
				key = "distSort",
				default = true,
				OnClick = function(self)
					track.sets.distSort = not track.sets.distSort
					self:SetChecked(track.sets.distSort)
					
					track.OnEvent()
					
					Questra:UpdateTracking(0)
					Questra.UpdateAutoTracking("FORCED")
				end,
				OnShow = function(self)
					self:SetChecked(track.sets.distSort)
				end,
			},
		}

		track.GetLocation = function(questID)
			local questID = questID or track.metrics[track.GetScrollValue()]

			local suggestedMap = C_TaskQuest.GetQuestZoneID(questID) or GetQuestUiMapID(questID) or Questra:GetPlayerMapID()
			
			suggestedMap = suggestedMap == 0 and Questra:GetPlayerMapID() or suggestedMap
			
			local x, y, mapID

			local locationX, locationY = C_TaskQuest.GetQuestLocation(questID, suggestedMap)
			if locationX and locationY then
				x, y, mapID = locationX, locationY, suggestedMap
			end

			local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)

			local ids = Questra.GetZoneIDs(suggestedMap)
			for _, oMapID in pairs(ids) do
				local qs = C_QuestLine.GetAvailableQuestLines(oMapID)
				for _, questLineInfo in pairs(qs) do
					if questLineInfo.questID == questID then
						x, y, mapID = questLineInfo.x, questLineInfo.y, oMapID
					end
				end
			end

			do --waypoint check
				local wayID = C_QuestLog.GetNextWaypoint(questID) or suggestedMap --This one can return incorrect x and y coords
				local wayX, wayY = C_QuestLog.GetNextWaypointForMap(questID, wayID) -- Gets accurate x and y coords
				if wayID and wayX and wayY then
					x, y, mapID = wayX, wayY, wayID
				end
			end

			if not (x and y and mapID) then
				--no waypoint found, check world maps
				local mapQuests = suggestedMap and C_QuestLog.GetQuestsOnMap(suggestedMap)
				if mapQuests then
					for i, quest in pairs(mapQuests) do
						if C_QuestLog.GetLogIndexForQuestID(quest.questID) == (questLogIndex) then
							x, y, mapID = quest.x or x, quest.y or y, suggestedMap or mapID
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
							x, y, mapID = b.x or x, b.y or y, pID or mapID
						end
					end
				end
			end

			if (not (x and y and mapID)) then
				--translate any waypoint located inside of a dungeon into the dungeon's entrance
				local mapInfo = suggestedMap and C_Map.GetMapInfo(suggestedMap)
				if mapInfo and (mapInfo.mapType) == 4 then --location is inside a dungeon

					local parentMapDungeons = C_EncounterJournal.GetDungeonEntrancesForMap(mapInfo.parentMapID)

					for i, b in pairs(parentMapDungeons) do
						if  b.name and b.name == mapInfo.name then
							x, y = b.position:GetXY()
							mapID = mapInfo.parentMapID
						end
					end
				end
			end
		
		
			return {x = x, y = y, mapID = mapID or suggestedMap}
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
				info.percent = _GetQuestProgressBarPercent(questID)
				info.tagInfo = C_QuestLog.GetQuestTagInfo(questID)
				info.complete = C_QuestLog.IsComplete(questID)
				info.position = track.GetLocation(questID)

				return info
			end
		end

		local BlockedQuests = {}

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
			
			if track.sets and track.sets.distSort == true then
				table.sort(track.metrics, function(a, b)
					local adist = C_QuestLog.GetDistanceSqToQuest(a)
					local bdist = C_QuestLog.GetDistanceSqToQuest(b)

					return (adist or math.huge) < (bdist or math.huge)
				end)
			end

			for i, questID in pairs(track.metrics) do
				if BlockedQuests[questID] then

					local oldSelectedQuest = C_QuestLog.GetSelectedQuest();
					C_QuestLog.SetSelectedQuest(questID);
					C_QuestLog.SetAbandonQuest();

					C_QuestLog.AbandonQuest();
					if ( QuestLogPopupDetailFrame:IsShown() ) then
						HideUIPanel(QuestLogPopupDetailFrame);
					end

					C_QuestLog.SetSelectedQuest(oldSelectedQuest);
					
					tremove(track.metrics, i)
				end
			end

			local super = (C_SuperTrack.IsSuperTrackingQuest() and not QuestUtils_IsQuestWorldQuest(C_SuperTrack.GetSuperTrackedQuestID())) and C_SuperTrack.GetSuperTrackedQuestID()
			if super then
				if not track.metrics[1] ~= super then
					tremove(track.metrics, tIndexOf(track.metrics, super))
				
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
			if info and info.title then
				GameTooltip:Hide()
				GameTooltip:SetOwner(Questra.pin, "ANCHOR_LEFT")

				GameTooltip:SetText(info.title, info.difficultyColor.r, info.difficultyColor.g, info.difficultyColor.b)

				if info.position.x and info.position.y then

					local mapInfo = info.position.mapID and C_Map.GetMapInfo(info.position.mapID)
					
					local zone, zoneColorR, zoneColorG, zoneColorB = mapInfo and mapInfo.name, 1, 1, 1
					
					local _name = MapUtil.FindBestAreaNameAtMouse(tonumber(info.position.mapID), info.position.x, info.position.y)
					if _name and _name ~= zone then
						_name = zone..", ".._name
					else
						_name = zone
					end
				
				
				
					local x = string.format("%.2f" , info.position.x*100)
					local y = string.format("%.2f" , info.position.y*100)

					GameTooltip:AddDoubleLine(_name..":", x..", "..y, zoneColorR, zoneColorG, zoneColorB)
				else
					GameTooltip:AddLine(_name, zoneColorR, zoneColorG, zoneColorB)

				end
				
				local faction = info.factionName
				
				if faction then
					local numFactions = GetNumFactions()
					local factionIndex = 1
					while (factionIndex <= numFactions) do
						local name, description, standingId, bottomValue, topValue, earnedValue, atWarWith, canToggleAtWar,
							isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canBeLFGBonus = GetFactionInfo(factionIndex)
							
						local label = standingId and _G["FACTION_STANDING_LABEL"..standingId]
							
						if isHeader and isCollapsed then
							ExpandFactionHeader(factionIndex)
							numFactions = GetNumFactions()
						end
						if (hasRep or not isHeader) and faction == name then
							GameTooltip:AddDoubleLine(name..":",  label ..": " .. floor((earnedValue/topValue) * 100).."%")
							break
						end
						factionIndex = factionIndex + 1
					end
				end
				
			
				QuestUtils_AddQuestTypeToTooltip(GameTooltip, info.questID, NORMAL_FONT_COLOR)


				if Questra.portalSense then
						GameTooltip_AddBlankLinesToTooltip(GameTooltip, 1)
					GameTooltip:AddLine("- Take the "..Questra.portalSense.tooltip, nil, nil, nil, true)
						GameTooltip_AddBlankLinesToTooltip(GameTooltip, 1)
				end

				local questLogIndex = C_QuestLog.GetLogIndexForQuestID(info.questID)
				
				local percent = info.percent
				
				if questLogIndex then
					questDescription = GetQuestLogQuestText(questLogIndex)
					if questDescription then
					
						GameTooltip:AddLine(QUEST_DESCRIPTION)
						GameTooltip:AddLine(questDescription, 1, 1, 1, true)
						GameTooltip_AddBlankLinesToTooltip(GameTooltip, 1)
					end
				end



				local _ = info.questDescription and GameTooltip:AddLine(info.questDescription, 1, 1, 1, true)
				local _ = info.questDescription and GameTooltip_AddBlankLinesToTooltip(GameTooltip, 1)

				if #info.objectives > 0 then
					GameTooltip:AddLine(OBJECTIVES_TRACKER_LABEL)
				end

				for i, text in pairs(info.objectives) do
					local text, r, g, b, bool = text, 1, 1, 1, true
					if type(text) == "table" then
						text, r, b, g, bool = unpack(text)
					end

					if text ~= info.questDescription then
						GameTooltip:AddLine(QUEST_DASH..text, r, g, b, bool)
					end
				end

				local _ = ( info.percent and  info.percent ~= 0) and GameTooltip_ShowProgressBar(GameTooltip, 0, 100, info.percent, PERCENTAGE_STRING:format(info.percent))


				Questra:AddRewardsToTooltip(GameTooltip, info.questID)

				GameTooltip_CalculatePadding(GameTooltip) --must be called to resize tooltip while scrolling.
				GameTooltip:Show()
			end
		end

		track.ShouldShow = function()
			if (not track.sets) or (track.sets.disable == true) then return end
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
			local questID = info and info.questID

			if questID then
				local display = info.complete and Questra.iconDisplayInfo["complete"]
					or Questra.iconDisplayInfo[info.tagInfo and Enum.QuestTagType[info.tagInfo.tagName]]
					or Questra.iconDisplayInfo["normal"]

				local icon, l, r, t, b = display(info.tagInfo and info.tagInfo.tagID)

				local backgroundTexture, backgroundColor = unpack(Questra.questQualityTextures[0])

				local skinDetails = {
						backgroundTexture,
						{.09, 1 - .09, .09, 1 - .09},
						{-.09, 1.09, 0 - .09, 1.09},
						{unpack(backgroundColor or {1, 1, 1, 1})},
						{unpack(backgroundColor or {1, 1, 1, 1})},
					}

				return skinDetails, info.position, icon, l or 0, r or 1, t or 0, b or 1, questID
			end
		end

		local abandonQuest, blockQuest
		
		local function BuildItemNames(items)
			if items then
				local itemNames = {};
				local item = Item:CreateFromItemID(0);

				for itemIndex, itemID in ipairs(items) do
					item:SetItemID(itemID);
					local itemName = item:GetItemName();
					if itemName then
						table.insert(itemNames, itemName);
					end
				end

				if #itemNames > 0 then
					return table.concat(itemNames, ", ");
				end
			end

			return nil;
		end
		
		StaticPopupDialogs["QUESTRA_ABANDON_QUEST"] = {
			text = ABANDON_QUEST_CONFIRM,
			button1 = YES,
			button2 = NO,
			OnAccept = function(self)
				C_QuestLog.AbandonQuest();
				if ( QuestLogPopupDetailFrame:IsShown() ) then
					HideUIPanel(QuestLogPopupDetailFrame);
				end
					track.ScrollMetrics(1)

					Questra:UpdateAutoTracking("Forced")
					if #track.metrics == 0 then
						Questra:SetTracking()
					end
					Questra:CollectUpdate()
					Questra:Update()
				
				PlaySound(SOUNDKIT.IG_QUEST_LOG_ABANDON_QUEST);
			end,
			timeout = 0,
			whileDead = 1,
			exclusive = 1,
			hideOnEscape = 1
		};

		StaticPopupDialogs["QUESTRA_ABANDON_QUEST_WITH_ITEMS"] = {
			text = ABANDON_QUEST_CONFIRM_WITH_ITEMS,
			button1 = YES,
			button2 = NO,
			OnAccept = function(self)
				C_QuestLog.AbandonQuest();
				if ( QuestLogPopupDetailFrame:IsShown() ) then
					HideUIPanel(QuestLogPopupDetailFrame);
				end
				

					Questra:UpdateDisplayed("Forced")
					if #track.metrics == 0 then
						Questra:SetTracking()
					end
					Questra:CollectUpdate()
					Questra:Update()
				
				PlaySound(SOUNDKIT.IG_QUEST_LOG_ABANDON_QUEST);
			end,
			timeout = 0,
			whileDead = 1,
			exclusive = 1,
			hideOnEscape = 1
		};

		StaticPopupDialogs["QUESTRA_BLOCK_QUEST"] = {
			text = [[Do you want to silently block this quest from being accepted?
(block is temporary)]],
			button1 = YES,
			button2 = NO,
			OnAccept = function(self)
				BlockedQuests[blockQuest] = true

			end,
			timeout = 0,
			whileDead = 1,
			exclusive = 1,
			hideOnEscape = 1
		};


		local function QuestObjectiveTracker_OnOpenDropDown(self)
			local block = self.activeFrame;

			local info = UIDropDownMenu_CreateInfo();
			info.text = "Quest"
			info.isTitle = 1;
			info.notCheckable = 1;
			UIDropDownMenu_AddButton(info, UIDROPDOWN_MENU_LEVEL);

			info = UIDropDownMenu_CreateInfo();
			info.notCheckable = 1;

			info.text = OBJECTIVES_VIEW_IN_QUESTLOG;
			info.func = QuestObjectiveTracker_OpenQuestDetails;
			info.arg1 = block.id;
			info.noClickSound = 1;
			info.checked = false;
			UIDropDownMenu_AddButton(info, UIDROPDOWN_MENU_LEVEL);

			info.text = OBJECTIVES_STOP_TRACKING;
			info.func = QuestObjectiveTracker_UntrackQuest;
			info.arg1 = block.id;
			info.checked = false;
			UIDropDownMenu_AddButton(info, UIDROPDOWN_MENU_LEVEL);


			info.text = ABANDON_QUEST_ABBREV;
			info.func = function()
				abandonQuest = block.id
			
				QuestMapQuestOptions_AbandonQuest(abandonQuest)



					local oldSelectedQuest = C_QuestLog.GetSelectedQuest();
					C_QuestLog.SetSelectedQuest(abandonQuest);
					C_QuestLog.SetAbandonQuest();

					local items = BuildItemNames(C_QuestLog.GetAbandonQuestItems()) --list of items you'd only have because you were on that quest: to be deleted when quest is abandoned);
					local title = QuestUtils_GetQuestName(abandonQuest);
					if ( items ) then
						StaticPopup_Hide("QUESTRA_ABANDON_QUEST");
						StaticPopup_Show("QUESTRA_ABANDON_QUEST_WITH_ITEMS", title, items);
					else
						StaticPopup_Hide("QUESTRA_ABANDON_QUEST_WITH_ITEMS");
						StaticPopup_Show("QUESTRA_ABANDON_QUEST", title);
					end
					C_QuestLog.SetSelectedQuest(oldSelectedQuest);



			end;
			info.arg1 = block.id;
			info.checked = false;
			UIDropDownMenu_AddButton(info, UIDROPDOWN_MENU_LEVEL);

			info.text = "Block Quest"
			info.func = function()
				blockQuest = block.id
				StaticPopup_Show("QUESTRA_BLOCK_QUEST");
			end;
			info.arg1 = block.id;
			info.checked = false;
			UIDropDownMenu_AddButton(info, UIDROPDOWN_MENU_LEVEL);


			if ( C_QuestLog.IsPushableQuest(block.id) and IsInGroup() ) then
				info.text = SHARE_QUEST;
				info.func = QuestObjectiveTracker_ShareQuest;
				info.arg1 = block.id;
				info.checked = false;
				UIDropDownMenu_AddButton(info, UIDROPDOWN_MENU_LEVEL);
			end

			info.text = OBJECTIVES_SHOW_QUEST_MAP;
			info.func = QuestObjectiveTracker_OpenQuestMap;
			info.arg1 = block.id;
			info.checked = false;
			info.noClickSound = 1;
			UIDropDownMenu_AddButton(info, UIDROPDOWN_MENU_LEVEL);
		end

		track.OnClick = function(btn)
			local info = track.GetMetricInfo()
			local questID = info.questID
			if IsControlKeyDown() then
				if info.position then
					local x, y, mapID = info.position.x, info.position.y, info.position.mapID
					Questra:PingAnywhere("chat", x, y, mapID, questID)
				end
			elseif btn == "LeftButton" then
				if (info and info.isAutoComplete) and  C_QuestLog.IsComplete(questID) then
					AutoQuestPopupTracker_RemovePopUp(questID)
					ShowQuestComplete(questID)
				else
					local loc = questID and track.GetLocation(questID)
					local x, y, mapID = loc.x, loc.y, loc.mapID
					local _ = loc and Questra:PingAnywhere("map", x, y, mapID)
					
					--if loc and loc.mapID and loc.mapID ~= WorldMapFrame:GetMapID() then
						-- local _ = loc.mapID and OpenWorldMap(loc.mapID)
						--QuestMapFrame_OpenToQuestDetails(questID)
					--end

				end
			else
				Questra.pin.id = questID
				ObjectiveTracker_ToggleDropDown(Questra.pin, QuestObjectiveTracker_OnOpenDropDown)
				local p1, p2 = Questra.GetAnchorsNearestScreenCenter(Questra.pin)
				DropDownList1:ClearAllPoints()
				DropDownList1:SetPoint(p1, Questra.pin, p2)
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

	do local track = {trackingName = "worldQuest", displayText = "World Quests",     color = {0, 0, 1}, metrics = {}, scrollValue = 1, allowPortals = true, allowFlights = true}
		
		track.options =  {
			{
				kind = "CheckButton",
				title = "Sort by Distance",
				key = "distSort",
				default = true,
				OnClick = function(self)
					track.sets.distSort = not track.sets.distSort
					self:SetChecked(track.sets.distSort)
					
					track.OnEvent()
					
					Questra:UpdateTracking(0)
					Questra.UpdateAutoTracking("FORCED")
				end,
				OnShow = function(self)
					self:SetChecked(track.sets.distSort)
				end,
			},
			{
				kind = "CheckButton",
				title = "Current Zone Only",
				key = "currentZone",
				default = true,
				OnClick = function(self)
					track.sets.currentZone = not track.sets.currentZone
					self:SetChecked(track.sets.currentZone)
					
					track.OnEvent()
					
					Questra:UpdateTracking(0)
					Questra.UpdateAutoTracking("FORCED")
				end,
				OnShow = function(self)
					self:SetChecked(track.sets.currentZone)
				end,
			},
		}
		
		ignores = {
			--["Tag"] = 0,
			["Profession"] = 1,
			["Normal"] = 2,
			["PvP"] = 3,
			["Pet Battle"] = 4,
			["Bounty"] = 5,
			["Dungeon"] = 6,
			["Invasion"] = 7,
			["Raid"] = 8,
			--["Contribution"] = 9,
			--["Rated Reward"] = 10,
			["Faction Assault"] = 12,
			--["Islands"] = 13,
			["Threat"] = 14,
			["Covenant Calling"] = 15,
		}


		for name, index in pairs(ignores) do
			tinsert(track.options, {
				kind = "CheckButton",
				title = "Ignore "..name.."s",
				key = "ignore"..name,
				default = true,
				OnClick = function(self)
					if not tContains(track.sets.ignoredTypes, index) then
						tinsert(track.sets.ignoredTypes, index)
					else						
						tremove(track.sets.ignoredTypes, tIndexOf(track.sets.ignoredTypes, index))
					end
					
					self:SetChecked(tContains(track.sets.ignoredTypes, index))

					track.OnEvent()
					
					Questra:UpdateTracking(0)
					Questra.UpdateAutoTracking("FORCED")
				end,
				OnShow = function(self)
					self:SetChecked(tContains(track.sets.ignoredTypes, index))
				end,
			})
		
		end
		
		track.OnLoad = function()
			if track.sets then
				track.sets.ignoredTypes = track.sets.ignoredTypes or {}
				track.sets.ignoredIDs = track.sets.ignoredIDs or {}
			end
		end
		
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
						info.percent = _GetQuestProgressBarPercent(questID)
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
		
		local ignoredIDS = Questra.ignoredIDS
		local ignoredTYPES = Questra.ignoredTYPES

		track.OnEvent = function()
			wipe(track.metrics)

			local uiMapID = Questra:GetPlayerMapID()

			if (track.sets and track.sets.currentZone ~= true) then
				uiMapID = digForWorldMapID(uiMapID)
			end
			
			local taskInfo = uiMapID and C_TaskQuest.GetQuestsForPlayerByMapID(uiMapID)
			if taskInfo then
				for i, info in ipairs(taskInfo) do
					local questID = info.questID or info.questId
					if QuestUtils_IsQuestWorldQuest(questID) and HaveQuestData(questID) then
						local _info = C_QuestLog.GetQuestTagInfo(questID)
						local _type = _info and _info.worldQuestType
												
						if not tContains(track.metrics, questID)  and (not track.sets or (not track.sets.ignoredIDs[questID] and (not tContains(track.sets.ignoredTypes, _type)))) then
							tinsert(track.metrics, questID)
						end
					end
				end
			end

			if track.sets and track.sets.distSort == true then
				table.sort(track.metrics, function(a, b)
					local adist = C_QuestLog.GetDistanceSqToQuest(a)
					local bdist = C_QuestLog.GetDistanceSqToQuest(b)

					return (adist or math.huge) < (bdist or math.huge)
				end)
			end


			local super = C_SuperTrack.IsSuperTrackingQuest() and C_SuperTrack.GetSuperTrackedQuestID()
			if super and QuestUtils_IsQuestWorldQuest(super) and not track.metrics[1] ~= super then
				tremove(track.metrics, tIndexOf(track.metrics, super))
				tinsert(track.metrics, 1, super)
			end


			if track.lastSuper ~= super then
				track.scrollValue = 1
			end

			track.lastSuper = super


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
			
		local function AddQuestTagTooltipLine(tooltip, tagID, worldQuestType, lineText, iconWidth, iconHeight, color)
			local tooltipLine
			
			local texCoords = QuestUtils_GetQuestTagTextureCoords(tagID, worldQuestType);

			if texCoords then
				-- Use reasonable defaults if nothing is specified
				iconWidth = iconWidth or 20;
				iconHeight = iconHeight or 20;

				local textureMarkup = CreateTextureMarkup(QUEST_ICONS_FILE, QUEST_ICONS_FILE_WIDTH, QUEST_ICONS_FILE_HEIGHT, iconWidth, iconHeight, unpack(texCoords))
				tooltipLine = string.format("%s %s", textureMarkup, lineText); -- Convert to localized string to handle dynamic icon placement?
			end
			
			
			
			
			if tooltipLine then
				tooltip:AddLine(tooltipLine, color:GetRGB())
			else
				
				local lineText = Questra.questTypes[worldQuestType]
				
				
						
				if lineText then
					tooltip:AddLine(lineText, color:GetRGB())
				end
				
				
				
			
			
			end
		end
			
		track.SetTooltip = function()
			local info = track.GetMetricInfo()
			if info then
				GameTooltip:Hide()--must be called to resize tooltip while scrolling.
				GameTooltip:SetOwner(Questra.pin, "ANCHOR_LEFT")

				local color = WORLD_QUEST_QUALITY_COLORS[info.quality] or {r=1,g=1,b=1}

				if not info.title then return end

				GameTooltip:SetText(info.title, color.r, color.g, color.b)


				local _info = C_QuestLog.GetQuestTagInfo(info.questID)


				AddQuestTagTooltipLine(GameTooltip, _info.tagID, _info.worldQuestType, _info.tagName, _, _, NORMAL_FONT_COLOR)


				local mapInfo = C_Map.GetMapInfo(info.position.mapID)
				local zone, zoneColorR, zoneColorG, zoneColorB = mapInfo.name, 1, 1, 1

				if info.position.mapID ~= Questra:GetPlayerMapID() then
					zoneColorR, zoneColorG, zoneColorB = 1,0,0
				end
				
				local _name = MapUtil.FindBestAreaNameAtMouse(tonumber(info.position.mapID), info.position.x, info.position.y)
				if _name and _name ~= zone then
					_name = zone..", ".._name
				else
					_name = zone
				end

				if info.position.x and info.position.y then
				local x = string.format("%.2f" , info.position.x*100)
				local y = string.format("%.2f" , info.position.y*100)

					GameTooltip:AddDoubleLine(_name..":", x..", "..y, zoneColorR, zoneColorG, zoneColorB)
				else
					GameTooltip:AddLine(_name, zoneColorR, zoneColorG, zoneColorB)

				end
				
				local faction = info.factionName
				
				if faction then
					local numFactions = GetNumFactions()
					local factionIndex = 1
					while (factionIndex <= numFactions) do
						local name, description, standingId, bottomValue, topValue, earnedValue, atWarWith, canToggleAtWar,
							isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canBeLFGBonus = GetFactionInfo(factionIndex)
							
						local label = standingId and _G["FACTION_STANDING_LABEL"..standingId]
							
						if isHeader and isCollapsed then
							ExpandFactionHeader(factionIndex)
							numFactions = GetNumFactions()
						end
						if (hasRep or not isHeader) and faction == name then
							GameTooltip:AddDoubleLine(name..":",  label ..": " .. floor((earnedValue/topValue) * 100).."%")
							break
						end
						factionIndex = factionIndex + 1
					end
				end
				

				local pMap = Questra.professionsMap[info.tagInfo and (info.tagInfo.tradeskillLineID or info.tagInfo.professionIndex)]
				if pMap then
					GameTooltip:AddLine(pMap, 1, 1, 1)
				end

				if Questra.portalSense then
					GameTooltip:AddLine("- Take the "..Questra.portalSense.tooltip, nil, nil, nil, true)
				end

				WorldMap_AddQuestTimeToTooltip(info.questID)

				local _ = info.wayPointText
					and GameTooltip:AddLine("    "..QUEST_DASH .. WAYPOINT_OBJECTIVE_FORMAT_OPTIONAL:format(info.wayPointText), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, true)

				for i, text in pairs(info.objectives) do
					GameTooltip:AddLine(QUEST_DASH..text, 1, 1, 1)
				end

				local _ = ( info.percent)
					and GameTooltip_ShowProgressBar(GameTooltip, 0, 100, info.percent, PERCENTAGE_STRING:format(info.percent))

				Questra:AddRewardsToTooltip(GameTooltip, info.questID)
				
				GameTooltip_CalculatePadding(GameTooltip) --must be called to resize tooltip while scrolling.
				GameTooltip:Show()
			end
		end

		track.ShouldShow = function()
			if (not track.sets) or (track.sets.disable == true) then return end
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

				local backgroundTexture, backgroundColor = unpack(Questra.questQualityTextures[rarity] or Questra.questQualityTextures[0])

				local skinDetails = {
						backgroundTexture,
						{.09, 1 - .09, .09, 1 - .09},
						{-.09, 1.09, 0 - .09, 1.09},
						{unpack(backgroundColor or {1, 1, 1, 1})},
						{unpack(backgroundColor or {1, 1, 1, 1})},
					}

				return skinDetails, info.position, icon, l or 0, r or 1, t or 0, b or 1, questID
			end
		end

		local function BonusObjectiveTracker_OnOpenDropDown(self)
			local block = self.activeFrame;
			local questID = block.id;

			-- Add title
			local info = UIDropDownMenu_CreateInfo();

			info.text = "World Quest"
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

			if ( C_QuestLog.IsPushableQuest(questID) and IsInGroup() ) then
				--share quest
				info = UIDropDownMenu_CreateInfo();
				info.notCheckable = true;
				info.text = SHARE_QUEST_ABBREV;
				info.func = function()
					QuestMapQuestOptions_ShareQuest(questID)
				end
				UIDropDownMenu_AddButton(info, UIDROPDOWN_MENU_LEVEL);
			end

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
				local _ = loc and Questra:PingAnywhere("map", loc.x, loc.y, loc.mapID)
			end
			info.arg1 = id;
			info.checked = false;
			info.noClickSound = 1;
			UIDropDownMenu_AddButton(info, UIDROPDOWN_MENU_LEVEL);
			
			info.text = "Ignore Quest"
			info.func = function()
				if track.sets then  
					track.sets.ignoredIDs[questID] = true
				end
				Questra:UpdateDisplayed("Forced")
				if #track.metrics == 0 then
					Questra:SetTracking()
				end
				Questra:CollectUpdate()
				Questra:Update()
			end;
			info.arg1 = questID;
			info.checked = false;
			UIDropDownMenu_AddButton(info, UIDROPDOWN_MENU_LEVEL);
			
			info.text = "Ignore Quest Type"
			info.func = function()
			
				local _info = C_QuestLog.GetQuestTagInfo(questID)
			
			
				if track.sets then  
					track.sets.ignoredIDs[questID] = true
					if not tContains(track.sets.ignoredTypes, _info.worldQuestType) then
						tinsert(track.sets.ignoredTypes, _info.worldQuestType)
					end
				end
					Questra:UpdateDisplayed("Forced")
					if #track.metrics == 0 then
						Questra:SetTracking()
					end
					Questra:CollectUpdate()
					Questra:Update()
			end;
			info.arg1 = questID;
			info.checked = false;
			UIDropDownMenu_AddButton(info, UIDROPDOWN_MENU_LEVEL);


			
		end

		track.OnClick = function(btn)
			local info = track.GetMetricInfo()
			local questID = info and info.questID

			if IsControlKeyDown() then
				if info.position then
					local x, y, mapID = info.position.x, info.position.y, info.position.mapID
					Questra:PingAnywhere("chat", x, y, mapID, questID)
				end
			elseif btn == "LeftButton" then
				--local quest = QuestCache:Get(questID)
				if (info and info.isAutoComplete) and  C_QuestLog.IsComplete(questID) then
					AutoQuestPopupTracker_RemovePopUp(questID)
					ShowQuestComplete(questID)
				else
					local loc = questID and track.GetLocation(questID)
					if loc and loc.mapID ~= WorldMapFrame:GetMapID() then
						local _ = loc.mapID and OpenWorldMap(loc.mapID)
						QuestMapFrame_OpenToQuestDetails(questID)
					end
					local _ = loc and Questra:PingAnywhere("map", loc.x, loc.y, loc.mapID)
				end
			elseif not C_QuestLog.IsThreatQuest(questID) then
				Questra.pin.id = questID
				ObjectiveTracker_ToggleDropDown(Questra.pin, BonusObjectiveTracker_OnOpenDropDown)

				local p1, p2 = Questra.GetAnchorsNearestScreenCenter(Questra.pin)
				DropDownList1:ClearAllPoints()
				DropDownList1:SetPoint(p1, Questra.pin, p2)
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
	
	do local track = {trackingName = "way",        displayText = "Waypoints",        color = {0, 1, 0}, metrics = {}, referenceDetails = {}, scrollValue = 1, save = true, allowPortals = true, allowFlights = true}
		
		track.options =  {

		}
		
		track.GetLocation = function()
			return track.metrics[track.GetScrollValue()]
		end

		track.GetMetricInfo = function()
			return track.metrics[track.GetScrollValue()]
		end

		track.OnEvent = function(event)
			local wayPoint = C_Map.GetUserWaypoint()
			if wayPoint and wayPoint.position then
				local id, x, y = wayPoint.uiMapID , wayPoint.position.x, wayPoint.position.y
				local metric = id..x..y
				if metric and not track.referenceDetails[metric] then
					local details = {title = "Waypoint", x = floor(x*10000) / 10000 , y = floor(y*10000) / 10000 , mapID = id, icon = "way", _time = GetTime()}

					details.time = GetTime()
					tinsert(track.metrics, 1, details)
					details.referenceDetailsIndex = metric
					track.referenceDetails[metric] = details
				end
			end
		end

		function Questra:SetWayPoint(wayPoint)
			if wayPoint and wayPoint.position then
				local id, x, y = wayPoint.position.mapID or wayPoint.mapID , wayPoint.position.x, wayPoint.position.y
				local metric = id..x..y
				if metric and not track.referenceDetails[metric] then

					local details = {
						time = GetTime(),
						referenceDetailsIndex = metric,
						title = wayPoint.title or wayPoint.name,
						mapID = id,
						x = x,
						y = y,
						--position = {x = x, y = y, mapID = id},
						tooltip = wayPoint.description or wayPoint.tooltip or "",
						icon = wayPoint.icon or Questra:GetIconFromAtlas(wayPoint.atlasName),
					}

					tinsert(track.metrics, 1, details)
					track.referenceDetails[metric] = details

					Questra:UpdateDisplayed("Forced")
					Questra:SetTracking(tIndexOf(Questra.typesIndex, track.trackingName))
					Questra:CollectUpdate()
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

					GameTooltip:SetOwner(Questra.pin, "ANCHOR_LEFT")

					GameTooltip:SetText(userPoint.title or "Waypoint", 1, 1, 1)
					GameTooltip:AddLine(userPoint.tooltip or "Were you going somewhere?")

					if Questra.portalSense then
						GameTooltip:AddLine("- Take the "..Questra.portalSense.tooltip, nil, nil, nil, true)
					end

					if userPoint.time then
						local diff = GetTime() - userPoint.time
						GameTooltip:AddDoubleLine("Created:", string.format(SecondsToTime(diff, diff>60)) .. " ago")
					end

					local mapInfo = C_Map.GetMapInfo(tonumber(id))

					local _name = MapUtil.FindBestAreaNameAtMouse(tonumber(id), x, y)


					if _name and _name ~= mapInfo.name then
						_name = mapInfo.name..", ".._name..":"
					else
						_name = mapInfo.name..":"
					end
					
					GameTooltip:AddDoubleLine(_name, x*100 .. ", ".. y  * 100)

					GameTooltip_CalculatePadding(GameTooltip) --must be called to resize tooltip while scrolling.
					GameTooltip:Show()
				end
			end
		end

		track.ShouldShow = function()
			if (not track.sets) or (track.sets.disable == true) then
				return
			end
			return #track.metrics > 0 or nil
		end

		track.ShouldAutoSwap = function()
			if track.saved then
				track.saved = nil
				return true
			end
		
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
		
		
		
					if type(Questra.iconDisplayInfo[icon]) == "table" then
						return Questra.basicSkin, {x = x, y = y, mapID = id}, unpack(Questra.iconDisplayInfo[icon])
					elseif icon then
						return Questra.basicSkin, {x = x, y = y, mapID = id}, Questra.iconDisplayInfo[icon]()
					end
				end
			end
		end

		track.GetDropdown = function()
			track.dropDownMenu = track.v
			or {
				{
					text = "Waypoint",
					isTitle = true,
					notCheckable = true,
					hasArrow = nil,
				},
				{
					text = "Edit",
					notCheckable = true,
					hasArrow = nil,
					func = function()
						local userPoint = track.metrics[track.dropDown.metric]
						
						
						editMenu.Show(userPoint)
					end,
				},
				{
					text = SHOW_MAP,
					notCheckable = true,
					hasArrow = nil,
					func = function()
						local userPoint = track.GetLocation()
						if userPoint then
							local id, x, y = userPoint.mapID , userPoint.x, userPoint.y
							if id and x and y then
								Questra:PingAnywhere("map", x, y, id)
							end
						end
					end,
				},
				{
					text = OBJECTIVES_STOP_TRACKING,
					notCheckable = true,
					hasArrow = nil,
					func = function()
						local toRemove = track.dropDown.metric
						if track.metrics[toRemove] then
							local wayPoint = C_Map.GetUserWaypoint()
							if wayPoint and wayPoint.position then
								local id, x, y = wayPoint.uiMapID , wayPoint.position.x, wayPoint.position.y
								if (id == track.metrics[toRemove].mapID) or (x == track.metrics[toRemove].x) or (y == track.metrics[toRemove].y) then
									C_Map.ClearUserWaypoint()
								end
							end

							track.referenceDetails[track.metrics[toRemove].referenceDetailsIndex] = nil
							tremove(track.metrics, toRemove)
							if toRemove > #track.metrics then
								local num = #track.metrics > 0 and #track.metrics or 1
								track.SetToMetric(num)
							end

							Questra:UpdateDisplayed("Forced")
							if #track.metrics == 0 then
								Questra:SetTracking()
							end
							Questra:CollectUpdate()
							Questra:Update()
						end
						track.dropDown.metric = nil
					end,
				},
			}

			return track.dropDownMenu
		end

		track.CreateDropDown = function(level, ...)
			for i, entryDetails in pairs(track.GetDropdown()) do
				UIDropDownMenu_AddButton(entryDetails)
			end
		end

		track.OnClick = function(btn)
			if IsControlKeyDown() then
				local userPoint = track.GetLocation()
				if userPoint then
					local x, y, mapID = userPoint.x, userPoint.y, userPoint.mapID
					Questra:PingAnywhere("chat", x, y, mapID)
				end
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
						Questra:PingAnywhere("map", x, y, id)
					end
				end
			else
				local _p1,_frame
				if DropDownList1 then
					_p1,_frame = DropDownList1:GetPoint()
					CloseDropDownMenus()
					DropDownList1:ClearAllPoints()
				end

				if _frame ~= Questra.pin then
					if not track.dropDown then
						track.dropDown = CreateFrame("Frame", "QuestraWayPointDropDown"..track.trackingName, Questra.pin, "UIDropDownMenuTemplate")
						UIDropDownMenu_Initialize( track.dropDown, function(_, level, ...) return track.CreateDropDown(level, ...) end, "MENU")
					end

					track.dropDown.metric = track.GetScrollValue()

					ToggleDropDownMenu(1, 1, track.dropDown, Questra.pin:GetName(), 0, -5)

					local p1, p2 = Questra.GetAnchorsNearestScreenCenter(Questra.pin)
					DropDownList1:ClearAllPoints()
					DropDownList1:SetPoint(p1, Questra.pin, p2)
				end
			end
		end

		track.events = {
			--"WAYPOINT_UPDATE",
			"USER_WAYPOINT_UPDATED",
			"ZONE_CHANGED",
			"ZONE_CHANGED_INDOORS",
		}

		AddTracking(track)
	
		Questra:AddElement({
			name = "anchorButton",
			parentElementName = "frame",

			Build = function(parentElement, ...)
				local button = CreateFrame("Button", AddonName.."_AnchorButton", parentElement)
				button:SetSize(8, 15)
				button:SetPoint("Right", parentElement.coordinateText, "Left", -1, 0)

				button:SetFrameStrata("LOW")
				button:SetFrameLevel(1)
				button:SetFixedFrameStrata(true)

				button:SetHighlightTexture(Questra.textures.LeftArrowHighlight)
				button:SetPushedTexture(Questra.textures.LeftArrowPushed)
				button:SetNormalTexture(Questra.textures.LeftArrow)
				button:GetHighlightTexture():SetBlendMode("ADD")
				button:RegisterForClicks("AnyUp")

				button:GetNormalTexture():SetVertexColor(202/255,165/255,0, 1)
				button:GetPushedTexture():SetVertexColor(202/255,165/255,0, 1)
				button:GetHighlightTexture():SetVertexColor(202/255,165/255,0, 1)
				
				return button
			end,

			scripts = {
				OnMouseUp = function(self)
					local x, y, mapID = Questra.GetPlayerPosition()
					
					local metric = (x and y and mapID) and  mapID..x..y
					
					local details = metric and (track.referenceDetails[metric]
					or {
						title = "Anchor",
						tooltip = "Did you want to return to this spot?",
						x = floor(x*10000) / 10000 ,
						y = floor(y*10000) / 10000 ,
						mapID = mapID,
						icon = "anchor",
						["time"] = GetTime(),
						_time = GetTime(),
						referenceDetailsIndex = metric
					}) or nil
						
					if details and not track.referenceDetails[metric] then
						tinsert(track.metrics, 1, details)
						track.referenceDetails[metric] = details
						track.scrollValue = 1
						track.SetToMetric(1)
						track.saved = true
						Questra:SetTrackingByName("way")
						
					end
				end,
				
				OnLeave = function(self)
					GameTooltip:Hide()
				end,
				
				OnEnter = function(self)
					GameTooltip:SetOwner(self, "ANCHOR_LEFT")
					GameTooltip:SetText("Click to set anchor")

					GameTooltip:Show()
				end,
			},
		})
		
		do
			local element = {
				name = "SaveButton",
				parentElementName = "frame",
			}

			element.Build = function(parentElement, ...)
				local button = CreateFrame("Button", AddonName.."_SaveButton", parentElement)
				button:SetSize(8, 15)
				button:SetPoint("Left", parentElement.coordinateText, "Right", 1, 0)

				button:SetFrameStrata("LOW")
				button:SetFrameLevel(1)
				button:SetFixedFrameStrata(true)

				button:SetHighlightTexture(Questra.textures.LeftArrowHighlight)
				button:SetPushedTexture(Questra.textures.LeftArrowPushed)
				button:SetNormalTexture(Questra.textures.LeftArrow)
				button:GetHighlightTexture():SetTexCoord(1,0,0,1)
				button:GetHighlightTexture():SetBlendMode("ADD")
				button:GetNormalTexture():SetTexCoord(1,0,0,1)
				button:GetPushedTexture():SetTexCoord(1,0,0,1)

				button:GetNormalTexture():SetVertexColor(202/255,165/255,0, 1)
				button:GetPushedTexture():SetVertexColor(202/255,165/255,0, 1)
				button:GetHighlightTexture():SetVertexColor(202/255,165/255,0, 1)
				
				return button
			end

			element.scripts = {
				OnMouseUp = function(self)
					-- local x, y, mapID = Questra.GetPlayerPosition()
						editMenu.Show(true,  track)
					
					-- local track = Questra.trackByName.way
					
					-- if x and y and mapID then
						-- local metric = mapID..x..y
						-- if metric and not track.referenceDetails[metric] then
							-- local details = {title = "Anchor", tooltip = "Did you want to return to this spot?", x = floor(x*10000) / 10000 , y = floor(y*10000) / 10000 , mapID = mapID, icon = "anchor", _time = GetTime()}

							-- details.time = GetTime()
							-- tinsert(track.metrics, 1, details)
							-- details.referenceDetailsIndex = metric
							-- track.referenceDetails[metric] = details
						-- end
					-- end
				end,
				
				OnLeave = function(self)
					GameTooltip:Hide()
				end,
				
				OnEnter = function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
					GameTooltip:SetText("Click to save current location.")
					GameTooltip:Show()
				end,
			}
	
			Questra:AddElement(element)
		end

	end

	do local track = {trackingName = "flight",     displayText = "Flight Masters",   color = {1, 1, 0}, metrics = {}, referenceDetails = {}, scrollValue = 1, save = true, allowPortals = true, allowFlights = true}


		track.options =  {

		}


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

					GameTooltip:SetOwner(Questra.pin, "ANCHOR_LEFT")
					GameTooltip:SetText("Flight Point", 1, 1, 1)

					if Questra.portalSense then
						GameTooltip:AddLine("- Take the "..Questra.portalSense.tooltip, nil, nil, nil, true)
					end


					if userPoint.title then
						GameTooltip:AddDoubleLine(userPoint.title)
					end

					if userPoint.time then
							local diff = GetTime() - userPoint.time
							GameTooltip:AddDoubleLine("Time since selection:", string.format(SecondsToTime(diff, diff>60)))
					end

					local mapInfo = C_Map.GetMapInfo(tonumber(id))

					local _name = MapUtil.FindBestAreaNameAtMouse(tonumber(id), x, y)


					if _name and _name ~= mapInfo.name then
						_name = mapInfo.name..", ".._name..":"
					else
						_name = mapInfo.name..":"
					end
					
					GameTooltip:AddDoubleLine(_name, x*100 .. ", ".. y  * 100)

					GameTooltip_CalculatePadding(GameTooltip) --must be called to resize tooltip while scrolling.
					GameTooltip:Show()
				end
			end
		end

		track.ShouldShow = function()
			if (not track.sets) or (track.sets.disable == true) then return end
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


		track.GetDropdown = function()
			track.dropDownMenu = track.dropDownMenu
			or {
				{
					text = "Flight Point",
					isTitle = true,
					notCheckable = true,
					hasArrow = nil,
				},

				{
					text = SHOW_MAP,
					notCheckable = true,
					hasArrow = nil,
					func = function()
						local userPoint = track.GetLocation()
						if userPoint then
							local id, x, y = userPoint.mapID , userPoint.x, userPoint.y
							if id and x and y then
								Questra:PingAnywhere("map", x, y, id)
							end
						end
					end,
				},
				{
					text = OBJECTIVES_STOP_TRACKING,
					notCheckable = true,
					hasArrow = nil,
					func = function()
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
					end,
				},
			}

			return track.dropDownMenu
		end

		track.CreateDropDown = function(level, ...)
			for i, entryDetails in pairs(track.GetDropdown()) do
				UIDropDownMenu_AddButton(entryDetails)
			end
		end

		track.OnClick = function(btn)
			if IsControlKeyDown() then
				local userPoint = track.GetLocation()
				if userPoint then
					local x, y, mapID = userPoint.x, userPoint.y, userPoint.mapID
					Questra:PingAnywhere("chat", x, y, mapID)
				end
			elseif btn == "LeftButton" then
				local userPoint = track.GetLocation()
				if userPoint then
					local id, x, y = userPoint.mapID , userPoint.x, userPoint.y
					if id and x and y then
						Questra:PingAnywhere("map", x, y, id)
					end
				end
			else
				local _ = (DropDownList1 and DropDownList1:IsVisible()) and (CloseDropDownMenus() and DropDownList1:ClearAllPoints())
				
				if _frame ~= Questra.pin then
					if not track.dropDown then
						track.dropDown = CreateFrame("Frame", "QuestraWayPointDropDown"..track.trackingName, Questra.pin, "UIDropDownMenuTemplate")
						UIDropDownMenu_Initialize( track.dropDown, function(_, level, ...) return track.CreateDropDown(level, ...) end, "MENU")
					end

					track.dropDown.metric = track.GetScrollValue()

					ToggleDropDownMenu(1, 1, track.dropDown, Questra.pin:GetName(), 0, -5)

					local p1, p2 = Questra.GetAnchorsNearestScreenCenter(Questra.pin)
					DropDownList1:ClearAllPoints()
					DropDownList1:SetPoint(p1, Questra.pin, p2)
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
				details.time = GetTime()
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

	do local track = {trackingName = "offer",      displayText = "Available Quests", color = {0, 1, 1}, metrics = {}, referenceDetails = {}, scrollValue = 1, save = true, allowPortals = true, allowFlights = true}


		track.options =  {

		}


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

					GameTooltip:SetOwner(Questra.pin, "ANCHOR_LEFT")
					GameTooltip:SetText(userPoint.title)

					if Questra.portalSense then
						GameTooltip:AddLine("- Take the "..Questra.portalSense.tooltip, nil, nil, nil, true)
					end
					if userPoint.time then
							local diff = GetTime() - userPoint.time
							GameTooltip:AddDoubleLine("Time since selection:", string.format(SecondsToTime(diff, diff>60)))
					end
					if userPoint.tooltip then
						GameTooltip:AddLine(userPoint.tooltip, 1, 1, 1)
					end

					local mapInfo = C_Map.GetMapInfo(tonumber(id))

					local _name = MapUtil.FindBestAreaNameAtMouse(tonumber(id), x, y)


					if _name and _name ~= mapInfo.name then
						_name = mapInfo.name..", ".._name..":"
					else
						_name = mapInfo.name..":"
					end
					
					GameTooltip:AddDoubleLine(_name, x*100 .. ", ".. y  * 100)

					GameTooltip:AddDoubleLine(mapInfo.name..":", x*100 .. ", ".. y  * 100)

					GameTooltip_CalculatePadding(GameTooltip) --must be called to resize tooltip while scrolling.
					GameTooltip:Show()
				end
			end
		end

		track.ShouldShow = function()
			if (not track.sets) or (track.sets.disable == true) then return end
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

		track.GetDropdown = function()
			track.dropDownMenu = track.dropDownMenu
			or {
				{
					text = "Offer",
					isTitle = true,
					notCheckable = true,
					hasArrow = nil,
				},
				{
					text = "Edit",
					notCheckable = true,
					hasArrow = nil,
					func = function()
						local userPoint = track.metrics[track.dropDown.metric]
						
						
						editMenu.Show(userPoint)
					end,
				},
				{
					text = SHOW_MAP,
					notCheckable = true,
					hasArrow = nil,
					func = function()
						local userPoint = track.GetLocation()
						if userPoint then
							local id, x, y = userPoint.mapID , userPoint.x, userPoint.y
							if id and x and y then
								Questra:PingAnywhere("map", x, y, id)
							end
						end
					end,
				},
				{
					text = OBJECTIVES_STOP_TRACKING,
					notCheckable = true,
					hasArrow = nil,
					func = function()
						local toRemove = track.dropDown.metric
						if track.metrics[toRemove] then
							local wayPoint = C_Map.GetUserWaypoint()
							if wayPoint and wayPoint.position then
								local id, x, y = wayPoint.uiMapID , wayPoint.position.x, wayPoint.position.y
								if (id == track.metrics[toRemove].mapID) or (x == track.metrics[toRemove].x) or (y == track.metrics[toRemove].y) then
									C_Map.ClearUserWaypoint()
								end
							end

							track.referenceDetails[track.metrics[toRemove].referenceDetailsIndex] = nil
							tremove(track.metrics, toRemove)
							if toRemove > #track.metrics then
								local num = #track.metrics > 0 and #track.metrics or 1
								track.SetToMetric(num)
							end

							Questra:UpdateDisplayed("Forced")
							if #track.metrics == 0 then
								Questra:SetTracking()
							end
							Questra:CollectUpdate()
							Questra:Update()
						end
						track.dropDown.metric = nil
					end,
				},
			}

			return track.dropDownMenu
		end

		track.CreateDropDown = function(level, ...)
			for i, entryDetails in pairs(track.GetDropdown()) do
				UIDropDownMenu_AddButton(entryDetails)
			end
		end

		track.OnClick = function(btn)
			local info = track.GetMetricInfo()
			local questID = info and info.questID

			if IsControlKeyDown() then
				local userPoint = track.GetLocation()
				if userPoint then
					local x, y, mapID = userPoint.x, userPoint.y, userPoint.mapID
					Questra:PingAnywhere("chat", x, y, mapID, questID)
				end
			elseif btn == "LeftButton" then
				local userPoint = track.GetLocation()
				if userPoint then
					local id, x, y = userPoint.mapID , userPoint.x, userPoint.y
					if id and x and y then
						Questra:PingAnywhere("map", x, y, id)
					end
				end
			else
				local _ = (DropDownList1 and DropDownList1:IsVisible()) and (CloseDropDownMenus() and DropDownList1:ClearAllPoints())
				
				if _frame ~= Questra.pin then
					if not track.dropDown then
						track.dropDown = CreateFrame("Frame", "QuestraWayPointDropDown"..track.trackingName, Questra.pin, "UIDropDownMenuTemplate")
						UIDropDownMenu_Initialize( track.dropDown, function(_, level, ...) return track.CreateDropDown(level, ...) end, "MENU")
					end

					track.dropDown.metric = track.GetScrollValue()

					ToggleDropDownMenu(1, 1, track.dropDown, Questra.pin:GetName(), 0, -5)

					local p1, p2 = Questra.GetAnchorsNearestScreenCenter(Questra.pin)
					DropDownList1:ClearAllPoints()
					DropDownList1:SetPoint(p1, Questra.pin, p2)
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

				local details = {
					x = floor(x*10000) / 10000 ,
					y = floor(y*10000) / 10000 ,
					mapID = id,
					title = name,
					tooltip = description,
					icon = icon,
					_time = GetTime(),
					questID = pin.questID,
					qType = qType
				}

				tinsert(track.metrics, 1, details)
				details.time = GetTime()
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

	do local track = {trackingName = "other",      displayText = "Map Pins",         color = {1, 0, 1}, metrics = {}, referenceDetails = {}, scrollValue = 1, save = true, allowPortals = true, allowFlights = true}
		
		track.options =  {

		}
		
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
						GameTooltip:SetOwner(Questra.pin, "ANCHOR_LEFT")


						local title = info.title or C_QuestLog.GetTitleForQuestID(userPoint.questID)

						GameTooltip:SetText(title or "??", info.difficultyColor.r, info.difficultyColor.g, info.difficultyColor.b)

						if Questra.portalSense then
							GameTooltip:AddLine("- Take the "..Questra.portalSense.tooltip, nil, nil, nil, true)
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

						local _ = ( info.percent) and GameTooltip_ShowProgressBar(GameTooltip, 0, 100, info.percent, PERCENTAGE_STRING:format(info.percent))

						Questra:AddRewardsToTooltip(GameTooltip, info.questID)

						GameTooltip_CalculatePadding(GameTooltip) --must be called to resize tooltip while scrolling.
						GameTooltip:Show()
					--end
				else do

					local id, x, y = userPoint.mapID , userPoint.x, userPoint.y
					if id and x and y then

						GameTooltip:SetOwner(Questra.pin, "ANCHOR_LEFT")

						GameTooltip:SetText(userPoint.title or "")

						if Questra.portalSense then
							GameTooltip:AddLine("- Take the "..Questra.portalSense.tooltip, nil, nil, nil, true)
						end
						if userPoint.tooltip then
							GameTooltip:AddLine(userPoint.tooltip,1,1,1,true)
						end

						if userPoint.time then
							local diff = GetTime() - userPoint.time
							GameTooltip:AddDoubleLine("Time since selection:", string.format(SecondsToTime(diff, diff>60)))
						end

						local mapInfo = C_Map.GetMapInfo(tonumber(id))

						GameTooltip:AddDoubleLine(mapInfo.name..":", x*100 .. ", ".. y  * 100)

						GameTooltip_CalculatePadding(GameTooltip) --must be called to resize tooltip while scrolling.
						GameTooltip:Show()
					end end
				end
			end
		end

		track.ShouldShow = function()
			if (not track.sets) or (track.sets.disable == true) then return end
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

						local backgroundTexture, backgroundColor = unpack(Questra.questQualityTextures[0])

						local skinDetails = {
								backgroundTexture,
								{.09, 1 - .09, .09, 1 - .09},
								{-.09, 1.09, 0 - .09, 1.09},
								{unpack(backgroundColor or {1, 1, 1, 1})},
								{unpack(backgroundColor or {1, 1, 1, 1})},
							}

						return skinDetails, info.position or info, icon, l or 0, r or 1, t or 0, b or 1, questID
					elseif type(icon) ~= "table" and Questra.iconDisplayInfo[icon] then
						if type(Questra.iconDisplayInfo[icon]) == "table" then 
							return Questra.basicSkin, {x = x, y = y, mapID = id}, unpack(Questra.iconDisplayInfo[icon])
						else
							return Questra.basicSkin, {x = x, y = y, mapID = id}, Questra.iconDisplayInfo[icon]()
						end
					else


						local icon, coord, textureIndex = unpack(icon)
						local l, r, t, b
						if coord then
							l, r, t, b = unpack(coord)
						end
						return Questra.basicSkin, {x = x, y = y, mapID = id}, icon, l, r, t, b, textureIndex
					end
				end
			end
		end

		track.GetDropdown = function()
			track.dropDownMenu = track.dropDownMenu
			or {
				{
					text = "Waypoint",
					isTitle = true,
					notCheckable = true,
					hasArrow = nil,
				},
				{
					text = "Edit",
					notCheckable = true,
					hasArrow = nil,
					func = function()
						local userPoint = track.metrics[track.dropDown.metric]
						
						
						editMenu.Show(userPoint)
					end,
				},
				{
					text = SHOW_MAP,
					notCheckable = true,
					hasArrow = nil,
					func = function()
						local userPoint = track.GetLocation()
						if userPoint then
							local id, x, y = userPoint.mapID , userPoint.x, userPoint.y
							if id and x and y then
								Questra:PingAnywhere("map", x, y, id)
							end
						end
					end,
				},
				{
					text = OBJECTIVES_STOP_TRACKING,
					notCheckable = true,
					hasArrow = nil,
					func = function()
						local toRemove = track.dropDown.metric
						if track.metrics[toRemove] then
							local wayPoint = C_Map.GetUserWaypoint()
							if wayPoint and wayPoint.position then
								local id, x, y = wayPoint.uiMapID , wayPoint.position.x, wayPoint.position.y
								if (id == track.metrics[toRemove].mapID) or (x == track.metrics[toRemove].x) or (y == track.metrics[toRemove].y) then
									C_Map.ClearUserWaypoint()
								end
							end

							track.referenceDetails[track.metrics[toRemove].referenceDetailsIndex] = nil
							tremove(track.metrics, toRemove)
							if toRemove > #track.metrics then
								local num = #track.metrics > 0 and #track.metrics or 1
								track.SetToMetric(num)
							end

							Questra:UpdateDisplayed("Forced")
							if #track.metrics == 0 then
								Questra:SetTracking()
							end
							Questra:CollectUpdate()
							Questra:Update()
						end
						track.dropDown.metric = nil
					end,
				},
			}

			return track.dropDownMenu
		end

		track.CreateDropDown = function(level, ...)
			for i, entryDetails in pairs(track.GetDropdown()) do
				UIDropDownMenu_AddButton(entryDetails)
			end
		end

		track.OnClick = function(btn)
			if IsControlKeyDown() then
				local userPoint = track.GetLocation()
				if userPoint then
					local x, y, mapID = userPoint.x, userPoint.y, userPoint.mapID
					Questra:PingAnywhere("chat", x, y, mapID)
				end
			elseif btn == "LeftButton" then
				local userPoint = track.GetLocation()
				if userPoint then
					local id, x, y = userPoint.mapID , userPoint.x, userPoint.y
					if id and x and y then
						Questra:PingAnywhere("map", x, y, id)
					end
				end
			else
				local _ = (DropDownList1 and DropDownList1:IsVisible()) and (CloseDropDownMenus() and DropDownList1:ClearAllPoints())
				
				if _frame ~= Questra.pin then
					if not track.dropDown then
						track.dropDown = CreateFrame("Frame", "QuestraWayPointDropDown"..track.trackingName, Questra.pin, "UIDropDownMenuTemplate")
						UIDropDownMenu_Initialize( track.dropDown, function(_, level, ...) return track.CreateDropDown(level, ...) end, "MENU")
					end

					track.dropDown.metric = track.GetScrollValue()

					ToggleDropDownMenu(1, 1, track.dropDown, Questra.pin:GetName(), 0, -5)

					local p1, p2 = Questra.GetAnchorsNearestScreenCenter(Questra.pin)
					DropDownList1:ClearAllPoints()
					DropDownList1:SetPoint(p1, Questra.pin, p2)
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
			EncounterJournalPinTemplate = Enum.QuestTagType.Dungeon,
		}

		track.SetByPin = function(pin, m, template, pinInfo)
			local id, x, y = pin.owningMap.mapID, pin.normalizedX, pin.normalizedY

			--local _ = pin.displayInfo, pin.instanceID, pin.encounterID --may use later

			local det = pin.__details and unpack(pin.__details)
			local poiInfo = (type(det) == "table") and det or nil

			local pinType = poiInfo and (poiInfo.textureIndex or poiInfo.atlasName) or pin.pinTemplate

			-- do --extract possible tooltip and icon info
				-- for i, b in pairs(pin) do
					-- prin(i,b)
				-- end
				-- if poiInfo then
					-- prin("~~~")
					-- prin("~~~")
					-- prin("~~~")
					-- prin("~~~")
					-- for i, b in pairs(poiInfo) do
						-- prin(i,b)

					-- end
				-- end
			-- end

			local name = pin.name or pin.tooltipTitle or "where?"

			local Desc = pin.tooltipText

			if pin.journalInstanceID then
				local instanceName, description, bgImage, _, loreImage, buttonImage, dungeonAreaMapID = EJ_GetInstanceInfo(pin.journalInstanceID)
				Desc = description
			end

			local textureIndex = poiInfo and poiInfo.textureIndex or pin.textureIndex

			local pinTexture = not textureIndex and templateToTrackingType[pinType]or ((poiInfo and poiInfo.atlasName) and {poiInfo.atlasName, {0, 1, 0 ,1}}) or {textureIndex and "Interface/Minimap/POIIcons" or "map-markeddefeated", {0,1,0,1}, textureIndex}

			local metric = id..x..y
			if metric and not track.referenceDetails[metric] then
				local details = {x = floor(x*10000) / 10000 , y = floor(y*10000) / 10000 , mapID = id, title = name , tooltip = Desc or poiInfo and poiInfo.description, icon = pinTexture, _time = GetTime(), questID = pin.questID}
				local questID = pin.questID or poiInfo and poiInfo.questID

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
					info.percent = _GetQuestProgressBarPercent(questID)
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
				details.time = GetTime()
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

	do local track = {trackingName = "achievement",displayText = "Achievements",     color = {1, 1, 1}, metrics = {}, referenceDetails = {}, scrollValue = 1, allowPortals = true, allowFlights = true}
	
		track.options =  {

		}

		track.GetLocation = function(achievementID)
			-- local categoryID = GetAchievementCategory(achievementID)
		
		
			-- local catTitle = GetCategoryInfo(categoryID)
		
		
			-- prin(catTitle)
		
			-- local questID = questID or track.metrics[track.GetScrollValue()]

			-- local suggestedMap = C_TaskQuest.GetQuestZoneID(questID) or GetQuestUiMapID(questID) or Questra:GetPlayerMapID()
			
			-- suggestedMap = suggestedMap == 0 and Questra:GetPlayerMapID() or suggestedMap
			
			-- local x, y, mapID

			-- local locationX, locationY = C_TaskQuest.GetQuestLocation(questID, suggestedMap)
			-- if locationX and locationY then
				-- x, y, mapID = locationX, locationY, suggestedMap
			-- end

			-- local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)

			-- local ids = Questra.GetZoneIDs(suggestedMap)
			-- for _, oMapID in pairs(ids) do
				-- local qs = C_QuestLine.GetAvailableQuestLines(oMapID)
				-- for _, questLineInfo in pairs(qs) do
					-- if questLineInfo.questID == questID then
						-- x, y, mapID = questLineInfo.x, questLineInfo.y, oMapID
					-- end
				-- end
			-- end

			-- do --waypoint check
				-- local wayID = C_QuestLog.GetNextWaypoint(questID) or suggestedMap --This one can return incorrect x and y coords
				-- local wayX, wayY = C_QuestLog.GetNextWaypointForMap(questID, wayID) -- Gets accurate x and y coords
				-- if wayID and wayX and wayY then
					-- x, y, mapID = wayX, wayY, wayID
				-- end
			-- end

			-- if not (x and y and mapID) then
				-- --no waypoint found, check world maps
				-- local mapQuests = suggestedMap and C_QuestLog.GetQuestsOnMap(suggestedMap)
				-- if mapQuests then
					-- for i, quest in pairs(mapQuests) do
						-- if C_QuestLog.GetLogIndexForQuestID(quest.questID) == (questLogIndex) then
							-- x, y, mapID = quest.x or x, quest.y or y, suggestedMap or mapID
							-- break
						-- end
					-- end
				-- end
			-- end

			-- if (not (x and y)) and QuestHasPOIInfo(questID) and C_QuestLog.IsOnMap(questID) then
				-- local px, py, pID = Questra.GetPlayerPosition()
				-- local nearestDist, nearest = math.huge
				-- local points = QuestPOIGetSecondaryLocations(questID)
				-- if points and #points > 0 then
					-- for i, b in pairs(points) do
						-- local compDist = HBD:GetZoneDistance(pID, b.x, b.y, pID, px, py)
						-- if compDist and compDist < nearestDist then
							-- nearestDist = compDist
							-- x, y, mapID = b.x or x, b.y or y, pID or mapID
						-- end
					-- end
				-- end
			-- end

			-- if (not (x and y and mapID)) then
				-- --translate any waypoint located inside of a dungeon into the dungeon's entrance
				-- local mapInfo = suggestedMap and C_Map.GetMapInfo(suggestedMap)
				-- if mapInfo and (mapInfo.mapType) == 4 then --location is inside a dungeon

					-- local parentMapDungeons = C_EncounterJournal.GetDungeonEntrancesForMap(mapInfo.parentMapID)

					-- for i, b in pairs(parentMapDungeons) do
						-- if  b.name and b.name == mapInfo.name then
							-- x, y = b.position:GetXY()
							-- mapID = mapInfo.parentMapID
						-- end
					-- end
				-- end
			-- end
		
		
			-- return {x = x, y = y, mapID = mapID or suggestedMap}
		end

		track.GetMetricInfo = function()
			local achievementID = track.metrics[track.GetScrollValue()]
			

			return track.referenceDetails[achievementID]
		end

		track.OnEvent = function()
			wipe(track.metrics)

			local _, instanceType = IsInInstance();
			local displayOnlyArena = ArenaEnemyFrames and ArenaEnemyFrames:IsShown() and (instanceType == "arena")
			local trackedAchievements = { GetTrackedAchievements() };

			for i = 1, #trackedAchievements do
				local achievementID = trackedAchievements[i]
				local _, achievementName, _, completed, _, _, _, description, _, icon, _, _, wasEarnedByMe = GetAchievementInfo(achievementID)
			
				local showAchievement = (wasEarnedByMe or (displayOnlyArena and ( GetAchievementCategory(achievementID) ~= ARENA_CATEGORY ))) and false or true
				
				if showAchievement then
					local numCriteria = GetAchievementNumCriteria(achievementID)	
				
					local _ = (not tContains(track.metrics, achievementID)) and tinsert(track.metrics, achievementID)
					track.referenceDetails[achievementID] = {
						title = achievementName,
						tooltip = ((not numCriteria) or (numCriteria > 1)) and description,
						objectives = {},
						icon = {icon, 0, 1, 0, 1, "texture"},
						achievementID = achievementID,
					}

					local objectives = track.referenceDetails[achievementID].objectives				
					if ( numCriteria > 0 ) then
						for criteriaIndex = 1, numCriteria do
							local criteriaString, criteriaType, criteriaCompleted, quantity, _, _, flags, assetID, quantityString, _, eligible = GetAchievementCriteriaInfo(achievementID, criteriaIndex);
							local colorStyle = eligible and OBJECTIVE_TRACKER_COLOR["Normal"] or OBJECTIVE_TRACKER_COLOR["Failed"];
							if not ( criteriaCompleted ) then
								if ( description and bit.band(flags, EVALUATION_TREE_FLAG_PROGRESS_BAR) == EVALUATION_TREE_FLAG_PROGRESS_BAR ) then
									-- progress bar
									if ( string.find(strlower(quantityString), "interface\\moneyframe") ) then	-- no easy way of telling it's a money progress bar
										criteriaString = quantityString.."\n"..description;
									else
										-- remove spaces so it matches the quest look, x/y
										criteriaString = string.gsub(quantityString, " / ", "/").." "..description;
									end
								else
									-- for meta criteria look up the achievement name
									if ( criteriaType == CRITERIA_TYPE_ACHIEVEMENT and assetID ) then
										_, criteriaString = GetAchievementInfo(assetID);
									end
								end
								
								local _ = (criteriaString and (not tContains(objectives, criteriaString))) and tinsert(objectives, criteriaString)
							end
						end
					end
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
			if info and info.title then
				GameTooltip:Hide()
				GameTooltip:SetOwner(Questra.pin, "ANCHOR_LEFT")

				GameTooltip:SetText(info.title)

				local categoryID = info.achievementID and GetAchievementCategory(info.achievementID)
				if categoryID then
					local title, parentCategoryID, flags = GetCategoryInfo(categoryID)

					local parentTitle = parentCategoryID and GetCategoryInfo(parentCategoryID) 
					if not parentTitle then
						GameTooltip:AddLine(title, 1, 1, 1, true)
					else
						GameTooltip:AddDoubleLine(parentTitle ..":", title, 1, 1, 1, 1, 1, 1)
					end
					GameTooltip_AddBlankLinesToTooltip(GameTooltip, 1)
				end

				local _ = info.tooltip and GameTooltip:AddLine(info.tooltip, 1, 1, 1, true)
				for i, text in pairs(info.objectives) do
					local text, r, g, b, bool = text, 1, 1, 1, true
					if type(text) == "table" then
						text, r, b, g, bool = unpack(text)
					end

					if text ~= info.questDescription then
						GameTooltip:AddLine("  "..QUEST_DASH..text, r, g, b, bool)
					end
				end

				GameTooltip_CalculatePadding(GameTooltip) --must be called to resize tooltip while scrolling.
				GameTooltip:Show()
			end
		end

		track.ShouldShow = function()
			if (not track.sets) or (track.sets.disable == true) then return end
			return #track.metrics > 0 or nil
		end

		track.ShouldAutoSwap = function(newAutoSwap)
			return nil
			-- if (not newAutoSwap) then
				-- local metric  = C_SuperTrack.GetSuperTrackedQuestID()
				-- if metric and (metric ~= track.lastMetric) then
					-- track.lastMetric = metric
					-- if (metric ~= 0) and not QuestUtils_IsQuestWorldQuest(metric) then
						-- return tIndexOf(Questra.typesIndex, track.trackingName), metric
					-- end
				-- end
			-- end
		end

		track.GetIconInfo = function()
			local info = track.GetMetricInfo()
			local achievementID = info and info.achievementID

			if achievementID then
				local display = info.icon

				local icon, l, r, t, b  = unpack(info.icon)

				local backgroundTexture, backgroundColor = unpack(Questra.questQualityTextures[0])

				local skinDetails = {
						backgroundTexture,
						{.09, 1 - .09, .09, 1 - .09},
						{-.09, 1.09, 0 - .09, 1.09},
						{unpack(backgroundColor or {1, 1, 1, 1})},
						{unpack(backgroundColor or {1, 1, 1, 1})},
					}

				return skinDetails, info.position, icon, l or 0, r or 1, t or 0, b or 1, "texture"
			end
		end

		track.OnClick = function(btn)
			local info = track.GetMetricInfo()
			local achievementID = info.achievementID
			
			if ( IsModifiedClick("CHATLINK") and ChatEdit_GetActiveWindow() ) then
				local achievementLink = GetAchievementLink(achievementID);
				if ( achievementLink ) then
					ChatEdit_InsertLink(achievementLink);
				end
			elseif ( btn ~= "RightButton" ) then
				CloseDropDownMenus();
				if ( not AchievementFrame ) then
					AchievementFrame_LoadUI();
				end
				if ( not AchievementFrame:IsShown() ) then
					AchievementFrame_ToggleAchievementFrame();
					AchievementFrame_SelectAchievement(achievementID);
				else
					if ( AchievementFrameAchievements.selection ~= achievementID ) then
						AchievementFrame_SelectAchievement(achievementID);
					else
						AchievementFrame_ToggleAchievementFrame();
					end
				end
			else
				Questra.pin.id = achievementID
				ObjectiveTracker_ToggleDropDown(Questra.pin, AchievementObjectiveTracker_OnOpenDropDown);
				local p1, p2 = Questra.GetAnchorsNearestScreenCenter(Questra.pin)
				DropDownList1:ClearAllPoints()
				DropDownList1:SetPoint(p1, Questra.pin, p2)
			end
		end

		track.events = {
			"TRACKED_ACHIEVEMENT_LIST_CHANGED",
			"TRACKED_ACHIEVEMENT_UPDATE",
			"ACHIEVEMENT_EARNED",
			"CRITERIA_COMPLETE",
			"CRITERIA_EARNED",
			"CRITERIA_UPDATE",
		}

		AddTracking(track)
	end
end

do --hook map pins
	--[[
		hack most pins on the world map, to set waypoints on unused clicks (left or right click to st waypoint)
	--]]

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

	local ignored = {
		WorldMapThreatOverlayPinTemplate = true,
		FlightMap_VignettePinTemplate = true,
		ContributionCollectorPinTemplate = true,
		FogOfWarPinTemplate = true,
		MapHighlightPinTemplate = true,
		QuestBlobPinTemplate = true,
		ScenarioBlobPinTemplate = true,
		WorldQuestSpellEffectPinTemplate = true,
		QuestraPinTemplate = true
	}

	function Questra:PinClickSetTracking(pin, pinTemplateName, template)
		if ignored[pinTemplateName] then
			return 
		end
	
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
		-- local map = WorldMapFrame
		-- if not map.oldAcquirePin then
			-- map.oldAcquirePin = map.AcquirePin
			-- function map:AcquirePin(pinTemplateName, ...)
				-- local pin = map:oldAcquirePin(pinTemplateName, ...)
				-- if ignored[pinTemplateName] then return pin end

				-- pin.__details = {...}
				-- local details = pin.__details[1]

				-- local portal = ((details and type(details) == "table") and Questra.Zeppelins[details.name])
				-- if portal then
					-- pin:EnableMouse(true)
					-- --pin:RegisterForClicks("AnyUp")
					-- local function click(self, btn, ...)
						-- local portal = ((details and type(details) == "table") and Questra.Zeppelins[details.name])

						-- if btn == "LeftButton" then
							-- Questra:PingAnywhere("map", portal.destination.x, portal.destination.y, portal.destination.mapID)
							-- PlaySound(SOUNDKIT.IG_QUEST_LOG_OPEN)
						-- else
							-- Questra:PinClickSetTracking(pin, "Other", pinTemplateName)
						-- end						
					-- end
					-- pin:SetScript("OnMouseDown", function(_, btn, ...)
						-- local _ = pin:GetScript("OnMouseUp") ~= click and pin:SetScript("OnMouseUp", click)
					-- end)
				-- elseif pinToTrackingType[pinTemplateName] then
					-- if not pin.Hooked then
						-- pin.Hooked = true
						-- pin.OldClick = pin.OnMouseClickAction
						-- or (pin:HasScript("OnClick") and pin:GetScript("OnClick"))
						-- or (pin:HasScript("OnMouseUp") and pin:GetScript("OnMouseUp"))

						-- local _ = pin:HasScript("OnMouseUp")  and pin:SetScript("OnMouseUp", nil)
						-- local _ = pin:HasScript("OnClick")  and pin:SetScript("OnClick", nil)
						-- pin.OnMouseClickAction = nil
						-- pin:EnableMouse(true)

						-- local function click(self, btn, ...)
							-- local _ = (pin.OldClick and btn == "LeftButton") and pin:OldClick(btn, ...)
								-- or Questra:PinClickSetTracking(pin, pinTemplateName)
						-- end

						-- pin.TempSet = pin:HasScript("OnMouseDown") and pin.HookScript or pin.SetScript
						-- pin:TempSet("OnMouseDown", function(_, btn, ...)
							-- local _ = pin:GetScript("OnMouseUp") ~= click and pin:SetScript("OnMouseUp", click)
						-- end)
					-- end
				-- else
					-- if not pin.Hooked then
						-- pin.Hooked = true
						-- pin.OldClick = pin.OldClick or pin.OnMouseClickAction
						-- or (pin:HasScript("OnClick") and pin:GetScript("OnClick"))
						-- or (pin:HasScript("OnMouseUp") and pin:GetScript("OnMouseUp"))

						-- local _ = pin:HasScript("OnMouseUp")  and pin:SetScript("OnMouseUp", nil)
						-- local _ = pin:HasScript("OnClick")  and pin:SetScript("OnClick", nil)
						-- pin.OnMouseClickAction = nil
						-- pin:EnableMouse(true)

						-- local function click(self, btn, ...)
							-- if (pin.OldClick and btn == "LeftButton") then
								-- pin:OldClick(btn, ...)
							-- else
								-- Questra:PinClickSetTracking(pin, "Other", pinTemplateName)
							-- end
						-- end

						-- pin.TempSet = pin:HasScript("OnMouseDown") and pin.HookScript or pin.SetScript
						-- pin:TempSet("OnMouseDown", function(_, btn, ...)
							-- local _ = pin:GetScript("OnMouseUp") ~= click and pin:SetScript("OnMouseUp", click)
						-- end)
					-- end
				-- end
				-- return pin
			-- end
		-- end
	end
end

do--texture Consolidation
	local texturePath = "Interface\\AddOns\\"..AddonName.."\\artwork\\"
	Questra.textures = {
		Green = texturePath.."Eye\\green",
		RingArrow = texturePath.."RingArrow",
		NotifyBridgeHighlight = texturePath.."NotifyBridgeHighlight",
		NotifyBridgeBackGround = texturePath.."NotifyBridgeBackGround",
		NotifyBridgeBorder = texturePath.."NotifyBridgeBorder",
		LeftArrowHighlight = texturePath.."LeftArrow-Highlight",
		LeftArrowPushed = texturePath.."LeftArrow-Pushed",
		LeftArrow = texturePath.."LeftArrow",
		
		metricDial = texturePath.."MetricIndicator",
		MetricFlash = texturePath.."MetricFlash",
		
		pupil = texturePath.."Eye\\pupil",
		swirl = texturePath.."Eye\\pupilSwirl",
		shine = texturePath.."Eye\\shine",
		
		upper1 =   texturePath.."Eye\\eyelids\\upper1",
		upper2 =   texturePath.."Eye\\eyelids\\upper2",
		upper3 =   texturePath.."Eye\\eyelids\\upper3",
		upper4 =   texturePath.."Eye\\eyelids\\upper4",
		upper5 =   texturePath.."Eye\\eyelids\\upper5",
		upper6 =   texturePath.."Eye\\eyelids\\upper6",
		upper7 =   texturePath.."Eye\\eyelids\\upper7",
		upper8 =   texturePath.."Eye\\eyelids\\upper8",
		upper9 =   texturePath.."Eye\\eyelids\\upper9",
		
		lower1 =   texturePath.."Eye\\eyelids\\lower1",
		lower2 =   texturePath.."Eye\\eyelids\\lower2",
		lower3 =   texturePath.."Eye\\eyelids\\lower3",
		lower4 =   texturePath.."Eye\\eyelids\\lower4",
		lower5 =   texturePath.."Eye\\eyelids\\lower5",
		lower6 =   texturePath.."Eye\\eyelids\\lower6",
		lower7 =   texturePath.."Eye\\eyelids\\lower7",
		lower8 =   texturePath.."Eye\\eyelids\\lower8",
		lower9 =   texturePath.."Eye\\eyelids\\lower9",
	}
end

do --settings functions
	function Questra:EnableFlyPaper()
		FlyPaper.AddFrame(AddonName, "questraFrame", Questra.frame)
	end
	

	--------------------------------------------------------------------------------
	-- Positioning: Borrowed from Dominos
	-- ToDo: Ask Tuller for permission...
	--------------------------------------------------------------------------------

	function Questra:SavePosition(point, relPoint, x, y)
		if point == nil then
			error('Usage: Frame:SavePosition(point, [relPoint, x, y]', 2)
		end

		if relPoint == point then
			relPoint = nil
		end

		if point == 'CENTER' then
			point = nil
		end

		x = tonumber(x) or 0
		if x == 0 then
			x = nil
		end

		y = tonumber(y) or 0
		if y == 0 then
			y = nil
		end

		local sets = Questra.sets
		sets.point = point
		sets.relPoint = relPoint
		sets.x = x
		sets.y = y
	end

	function Questra:GetSavedPosition()
		local sets = Questra.sets
		local point = sets.point or 'CENTER'
		local relPoint = sets.relPoint or point
		local x = sets.x or 0
		local y = sets.y or 0

		return point, relPoint,x, y
	end

	function Questra:SaveRelativePostiion()
		local point, relPoint, x, y = Questra:GetRelativePosition()

		Questra:SavePosition(point, relPoint, x, y)
	end

	function Questra:GetRelativePosition()
		local point, relPoint, x, y = FlyPaper.GetBestAnchorForParent(Questra.frame)
		return point, relPoint, x, y
	end

	function Questra:RestorePosition()
		local point, relPoint, x, y = Questra:GetSavedPosition()
		local scale = Questra:GetFrameScale()

		Questra.frame:ClearAllPoints()
		Questra.frame:SetScale(scale)
		Questra.frame:SetPoint(point, Questra.frame:GetParent() or _G.UIParent, relPoint, x, y)
		return true
	end

	function Questra:GetFrameScale()
		return Questra.sets.scale or 1
	end


	--------------------------------------------------------------------------------
	-- Anchoring
	--------------------------------------------------------------------------------

	function Questra:SaveAnchor(relFrame, point, relPoint, x, y)
		if relFrame == nil or point == nil then
			error('Usage: Frame:SaveAnchor(relFrame, point, [relPoint, x, y]', 2)
		end

		if relFrame == self then
			error('Cannot anchor to self', 2)
		end

		local relFrameGroup, relFrameId = FlyPaper.GetFrameInfo(relFrame)
		if relFrame == nil then
			error('Frame is not registered with FlyPaper', 2)
		end

		local anchor = self.sets.anchor
		if not anchor or type(anchor) == "string" then
			anchor = {}
			self.sets.anchor = anchor
		end

		-- purge defaults
		if relFrameGroup == AddonName then
			relFrameGroup = nil
		end

		if relPoint == point then
			relPoint = nil
		end

		x = tonumber(x) or 0
		if x == 0 then
			x = nil
		end

		y = tonumber(y) or 0
		if y == 0 then
			y = nil
		end

		anchor.point = point
		anchor.relFrame = relFrameId
		anchor.relFrameGroup = relFrameGroup
		anchor.relPoint = relPoint
		anchor.x = x
		anchor.y = y

		if not next(anchor) then
			self.sets.anchor = nil
		end
	end

	function Questra:GetSavedAnchor()
		local anchor = Questra.sets and Questra.sets.anchor
		if type(anchor) == 'table' then
			local point = anchor.point
			local relFrameId = anchor.relFrame
			local relFrameGroup = anchor.relFrameGroup or AddonName
			local relFrame = FlyPaper.GetFrame(relFrameGroup, relFrameId)
			local relPoint = anchor.relPoint or point
			local x = anchor.x or 0
			local y = anchor.y or 0

			return relFrame, point, relPoint, x, y
		end
	end

	function Questra:ClearSavedAnchor()
		Questra.sets.anchor = nil
	end

	function Questra:RestoreAnchor()
		local relFrame, point, relPoint, x, y = Questra:GetSavedAnchor()
		local scale = Questra:GetFrameScale() or 1

		if relFrame then
			Questra.frame:ClearAllPoints()
			Questra.frame:SetScale(scale)
			Questra.frame:SetPoint(point, relFrame, relPoint, x, y)
			return true
		end
	end

	function Questra:IsAnchored()
		if self:GetSavedAnchor() then
			return true
		end
		return false
	end

	function Questra:IsAnchoredToFrame(frame)
		if frame == nil or frame == Questra.frame then
			return false
		end

		for i = 1, Questra.frame:GetNumPoints() do
			local _, relFrame = Questra.frame:GetPoint(i)
			if frame == relFrame then
				return true
			end
		end

		return false
	end



	--------------------------------------------------------------------------------
	-- Sticking/Snapping
	--------------------------------------------------------------------------------

	-- how far away a frame can be from another frame/edge to trigger anchoring
	Questra.stickyTolerance = 8

	function Questra:Stick()
		-- only do sticky code if the alt key is not currently down
		--if Questra:Sticky() and not IsModifiedClick("DOMINOS_IGNORE_STICKY_FRAMES") then
			if Questra:StickToFrame() or Questra:StickToGrid() or Questra:StickToEdge() then
				Questra:SaveRelativePostiion()
				return true
			end
		--end

		Questra:ClearSavedAnchor()
		Questra:SaveRelativePostiion()
		return false
	end

	-- bar anchoring
	function Questra:StickToFrame()
		local point, relFrame, relPoint = FlyPaper.GetBestAnchor(Questra.frame, Questra.stickyTolerance)

		if point then
			Questra.frame:ClearAllPoints()
			Questra.frame:SetPoint(point, relFrame, relPoint)
			Questra:SaveAnchor(relFrame, point, relPoint)
			Questra:SaveRelativePostiion()

			return true
		end

		Questra:ClearSavedAnchor()
		return false
	end

	-- grid anchoring
	function Questra:StickToGrid()
		return false
	end

	-- screen edge and center point anchoring
	function Questra:StickToEdge()
		local point, relPoint, x, y = FlyPaper.GetBestAnchorForParent(Questra.frame)
		local scale = Questra.frame:GetScale()

		if point then
			local stick = false

			if math.abs(x * scale) <= Questra.stickyTolerance then
				x = 0
				stick = true
			end

			if math.abs(y * scale) <= Questra.stickyTolerance then
				y = 0
				stick = true
			end

			if stick then
				Questra.frame:ClearAllPoints()
				Questra.frame:SetPoint(point, Questra.frame:GetParent(), relPoint, x, y)

				Questra:SaveRelativePostiion()
				return true
			end
		end

		return false
	end


end