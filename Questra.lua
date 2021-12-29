local AddonName, Addon = ...
local Questra = _G.LibStub("AceAddon-3.0"):NewAddon(Addon, AddonName, 'AceEvent-3.0', 'AceConsole-3.0')
Questra.callbacks = LibStub('CallbackHandler-1.0'):New(Questra)
--Questra.localize = LibStub('AceLocale-3.0'):GetLocale(AddonName)
Questra.FlyPaper = LibStub('LibFlyPaper-2.0')
Questra.CTL = assert(ChatThrottleLib, "Questra requires ChatThrottleLib.")

Questra.offset = 1

local HBD = LibStub:GetLibrary("HereBeDragons-2.0", true)

Questra.HBD = HBD

do
	Questra.Elements = {}
	
	local elementOptions = {}

	function Questra:AddElement(elementDetails)
		tinsert(Questra.Elements, elementDetails)
	end

	function Questra:BuildElements()
		for i, elementDetails in pairs(Questra.Elements) do
			local parentElement = Questra[elementDetails.parentElementName]
			Questra[elementDetails.name] = Questra[elementDetails.name] or elementDetails.Build(parentElement)
			local element = Questra[elementDetails.name]
			
			tinsert(elementOptions, elementDetails)
			
			if elementDetails.Layout then
				tinsert(Questra.layoutUpdates, function(sets)
					if  sets then
						elementDetails.Layout(element, sets)
					end
				end)
			end
			if parentElement then
				parentElement[elementDetails.name] = parentElement[elementDetails.name] or element
			end
			elementDetails.element = element
		end
	end

	function Questra:AddElementOptions()
		for _, track in pairs(elementOptions) do
		
			Quest_Compass_DB.widgets[track.name] = Quest_Compass_DB.widgets[track.name] or {}
		
			track.sets = Quest_Compass_DB.widgets[track.name]
		
		
			if track.options then
				for i, optionDetails in pairs(track.options) do
					if optionDetails.key then
						track.sets[optionDetails.key] = track.sets[optionDetails.key] or optionDetails.default
					end
				end
				Questra:NewOptionPanel({
					name = track.displayName,
					options = track.options
				})
			end
		end
	end

	function Questra:EnableElementScripts()
		for i, elementDetails in pairs(Questra.Elements) do
			local element = elementDetails.element
			if elementDetails.scripts then
				for scriptName, script in pairs(elementDetails.scripts) do
					if scriptName == "OnLoad" then
						element.OnLoad = script
						element:OnLoad()
					else
						element:SetScript(scriptName, script)
					end
				end
			end
		end
	end

	function Questra:UpdateElements()
		for i, elementDetails in pairs(Questra.Elements) do
			local element = elementDetails.element
			if element and elementDetails.OnUpdate then
				element.OnUpdate = element.OnUpdate or elementDetails.OnUpdate
				element:OnUpdate()
			end
		end
	end

	function Questra:OnPostLoad()
		for i, elementDetails in pairs(Questra.Elements) do
			local element = elementDetails.element
			if element and elementDetails.OnPostLoad then
				element.OnPostLoad = element.OnPostLoad or elementDetails.OnPostLoad
				element:OnPostLoad()
			end
		end
	end

	function Questra:OnLocationUpdate(x, y, mapID, destX, destY, destMapID, playerAngle, angle, oID_World)
		for i, elementDetails in pairs(Questra.Elements) do
			local element = elementDetails.element
			if element and elementDetails.OnLocationUpdate then
				element.OnLocationUpdate = element.OnLocationUpdate or elementDetails.OnLocationUpdate
				element:OnLocationUpdate(x, y, mapID, destX, destY, destMapID, playerAngle, angle, oID_World)
			end
		end
	end

	function Questra:OnPostLocationUpdate(x, y, mapID, destX, destY, destMapID, icon, L, R, T, B, skinDetails, textureIndex)
		for i, elementDetails in pairs(Questra.Elements) do
			local element = elementDetails.element
			if element and elementDetails.OnPostLocationUpdate then
				element.OnPostLocationUpdate = element.OnPostLocationUpdate or elementDetails.OnPostLocationUpdate
				element:OnPostLocationUpdate(x, y, mapID, destX, destY, destMapID, icon, L, R, T, B, skinDetails, textureIndex)
			end
		end
	end

	function Questra:OnQuestUpdate(questID)
		for i, elementDetails in pairs(Questra.Elements) do
			local element = elementDetails.element
			if element and elementDetails.OnQuestUpdate then
				element.OnQuestUpdate = element.OnQuestUpdate or elementDetails.OnQuestUpdate
				element:OnQuestUpdate(questID)
			end
		end
	end
end

Questra.MapPins = {}

local registered = {}

function Questra:AddMapPinData(userPoint)
	Quest_Compass_DB.savePins = Quest_Compass_DB.savePins or {}
	
	Quest_Compass_DB.savePins[userPoint.mapID] = Quest_Compass_DB.savePins[userPoint.mapID] or {}
	if userPoint.mapID ~= 946 then
		tinsert(Quest_Compass_DB.savePins[userPoint.mapID], {
			name = userPoint.title,
			description = userPoint.tooltip,
			atlasName = userPoint.atlasName or Questra:GetIconDetails(userPoint.icon) or "Waypoint-MapPin-Tracked",
			position = {x = userPoint.x, y = userPoint.y, mapID = userPoint.mapID},
			metric = userPoint.x .. userPoint.y .. userPoint.mapID
		})
	end
	
	for _, mapID in pairs(Questra.GetZoneIDs(userPoint.mapID)) do
		if mapID ~= 946 and mapID ~= userPoint.mapID then
			local tX, tY = HBD:TranslateZoneCoordinates(userPoint.x, userPoint.y, userPoint.mapID, mapID)
			if tX and tY then
				Quest_Compass_DB.savePins[mapID] = Quest_Compass_DB.savePins[mapID] or {}
				tinsert(Quest_Compass_DB.savePins[mapID], {
					name = userPoint.title,
					description = userPoint.tooltip,
					atlasName = userPoint.atlasName or Questra:GetIconDetails(userPoint.icon) or "Waypoint-MapPin-Tracked",
					position = {x = tX, y = tY, mapID = mapID},
					metric = userPoint.x .. userPoint.y .. userPoint.mapID --always base off of original
				})
			end
		end
	end
	Questra.MapPinHandler:RefreshAllData()
end

do --custom pins
	QuestraDataProviderMixin = CreateFromMixins(MapCanvasDataProviderMixin);

	local pins = {}

	function QuestraDataProviderMixin:RemoveAllData()
		self:GetMap():RemoveAllPinsByTemplate("QuestraPinTemplate");
	end

	local function AddPins(self, nodes, addInternalID)
		if nodes then
			for i, userPoint in ipairs(nodes) do
				if userPoint.hidden ~= true then
					if not tContains(registered, userPoint.metric) then
						tinsert(registered, userPoint.metric)
						
						local pin = self:GetMap():AcquirePin("QuestraPinTemplate", userPoint)
						pin:EnableMouse(true)

						pin:SetScript("OnMouseUp", QuestraPinMixin.OnMouseClickAction)
						
						pin.InternalID = addInternalID and i

						local _ = pin and pin:OnAcquired(userPoint)
					end
				end
			end
		end
	end

	function QuestraDataProviderMixin:RefreshAllData()
		wipe(registered)
	
		self:RemoveAllData();
		local noPins = 0
		
		local currentMap = self:GetMap():GetMapID()
		local portals = Questra.portalPins[currentMap]
		local _ = portals and AddPins(self, portals)
			
		
		Quest_Compass_DB.savePins = Quest_Compass_DB.savePins or {}

	
		local wayPoints = Quest_Compass_DB.savePins and Quest_Compass_DB.savePins[currentMap]

		local pinsToAdd = {}
		
		for i, mapID in pairs(Questra.GetZoneIDs(currentMap)) do
			local points = Quest_Compass_DB.savePins and Quest_Compass_DB.savePins[mapID]
			if points then
				for i, point in pairs(points) do
					tinsert(pinsToAdd, point)
				end
			end
		end
	
		local adding = {}
	
		for index, wayPoint in pairs(pinsToAdd) do
			if wayPoint.position.mapID ~= currentMap then
				--translate higher pins, down to the local map.
				local tX, tY = HBD:TranslateZoneCoordinates(wayPoint.position.x, wayPoint.position.y, wayPoint.position.mapID, currentMap)
				if tX and tY then
					tinsert(adding, {
						name = wayPoint.name,
						description = wayPoint.description,
						atlasName = wayPoint.atlasName or Questra:GetIconDetails(wayPoint.icon) or "Waypoint-MapPin-Tracked",
						position = {x = tX, y = tY, mapID = mapID},
						metric = wayPoint.metric--always base off of original
					})
				end

			else
				tinsert(adding, wayPoint)
			end
		end
	
	
		local _ = pinsToAdd and AddPins(self, adding, true)
	end

	function QuestraDataProviderMixin:ShouldShowTaxiNode(factionGroup, userPoint)
		if userPoint.faction == Enum.FlightPathFaction.Horde then
			return factionGroup == "Horde";
		end

		if userPoint.faction == Enum.FlightPathFaction.Alliance then
			return factionGroup == "Alliance";
		end
		
		return true;
	end

	--[[ Pin ]]--
	QuestraPinMixin = BaseMapPoiPinMixin:CreateSubPin("PIN_FRAME_LEVEL_FLIGHT_POINT");

	function QuestraPinMixin:OnAcquired(userPoint)
		self.userPoint = userPoint
		
		self:SetTexture(userPoint);

		self.name = userPoint.title or userPoint.name;
		self.description = userPoint.description or userPoint.faction;

		self:SetPosition(userPoint.position.x, userPoint.position.y);
		
		self:ClearNudgeSettings();

		self:SetNudgeTargetFactor(0.015);
		self:SetNudgeZoomedOutFactor(1.25);
		self:SetNudgeZoomedInFactor(1);
		
		self.atlasName = userPoint.atlasName or Questra:GetIconDetails(userPoint.icon)
		
		if userPoint.portal then
			self.linkedUiMapID = userPoint.destination.mapID;
			self.linkedUiCoords = userPoint.destination			
			self.portal = userPoint.portal
		else
			self.linkedUiMapID = nil
			self.linkedUiCoords = nil
			self.portal = nil
		end
	end

	function QuestraPinMixin:OnMouseClickAction(btn)
		if btn == "LeftButton" and self.portal then
			Questra:PingAnywhere("map", self.portal.destination.x, self.portal.destination.y, self.portal.destination.mapID)
			PlaySound(SOUNDKIT.IG_QUEST_LOG_OPEN);
		elseif IsControlKeyDown() and self.userPoint.metric then
			for mapID, pins in pairs(Quest_Compass_DB.savePins) do
				for i, savedPin in pairs(pins) do
					if savedPin.metric == self.userPoint.metric then
						tremove(pins, i)
					end
				end
			end
			
			self:Hide()
		else
			Questra:SetWayPoint(self.userPoint)
		end	
	end

	local ATLAS_WITH_TEXTURE_KIT_PREFIX = "%s-%s";

	function QuestraPinMixin:SetTexture(poiInfo)
		local atlasName = poiInfo.atlasName;
		if atlasName then
			if poiInfo.textureKit then
				atlasName = ATLAS_WITH_TEXTURE_KIT_PREFIX:format(poiInfo.textureKit, atlasName);
			end

			self.Texture:SetAtlas(atlasName);
			if self.HighlightTexture then
				self.HighlightTexture:SetAtlas(atlasName);
			end

			local sizeX, sizeY = 32, 32
			if self.HighlightTexture then
				self.HighlightTexture:SetSize(sizeX, sizeY);
			end
			self:SetSize(sizeX, sizeY);
			self.Texture:SetSize(sizeX * .8, sizeY * .8);

			self.Texture:SetTexCoord(0, 1, 0, 1);
			if self.HighlightTexture then
				self.HighlightTexture:SetTexCoord(0, 1, 0, 1);
			end
		else
			self:SetSize(32, 32);
			self.Texture:SetWidth(16);
			self.Texture:SetHeight(16);
			self.Texture:SetTexture("Interface/Minimap/POIIcons");
			if self.HighlightTexture then
				self.HighlightTexture:SetTexture("Interface/Minimap/POIIcons");
			end

			local x1, x2, y1, y2 = GetPOITextureCoords(poiInfo.textureIndex);
			self.Texture:SetTexCoord(x1, x2, y1, y2);
			if self.HighlightTexture then
				self.HighlightTexture:SetTexCoord(x1, x2, y1, y2);
			end
		end
	end
end