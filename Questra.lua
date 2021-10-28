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
	
	function Questra:AddElement(elementDetails)
		tinsert(Questra.Elements, elementDetails)
	end

	function Questra:BuildElements()
		for i, elementDetails in pairs(Questra.Elements) do
			local parentElement = Questra[elementDetails.parentElementName]
			Questra[elementDetails.name] = Questra[elementDetails.name] or elementDetails.Build(parentElement)
			local element = Questra[elementDetails.name]
			
			if parentElement then
				parentElement[elementDetails.name] = parentElement[elementDetails.name] or element
			end
			elementDetails.element = element
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

do --custom pins
	QuestraDataProviderMixin = CreateFromMixins(MapCanvasDataProviderMixin);

	local pins = {}

	function QuestraDataProviderMixin:RemoveAllData()
		self:GetMap():RemoveAllPinsByTemplate("QuestraPinTemplate");
	end

	function QuestraDataProviderMixin:RefreshAllData(fromOnShow)
		self:RemoveAllData();

		local mapID = self:GetMap():GetMapID();

		local portalNodes = Questra.portalPins[mapID]

		if portalNodes and #portalNodes > 0 then
			local factionGroup = UnitFactionGroup("player");
			for i, portalNodeInfo in ipairs(portalNodes) do
				if portalNodeInfo.hidden ~= true then
				--if self:ShouldShowTaxiNode(factionGroup, portalNodeInfo) then
					local pin = pins[portalNodeInfo.nodeID] or self:GetMap():AcquirePin("QuestraPinTemplate", portalNodeInfo)
					pin:EnableMouse(true)

					pin:SetScript("OnMouseUp", QuestraPinMixin.OnMouseClickAction)

					pin.portal = portalNodeInfo.portal
					local _ = pin and pin:OnAcquired(portalNodeInfo)
				end
			end
		end
	end

	function QuestraDataProviderMixin:ShouldShowTaxiNode(factionGroup, portalNodeInfo)
		if taxiNodeInfo.faction == Enum.FlightPathFaction.Horde then
			return factionGroup == "Horde";
		end

		if taxiNodeInfo.faction == Enum.FlightPathFaction.Alliance then
			return factionGroup == "Alliance";
		end
		
		return true;
	end

	--[[ Pin ]]--
	QuestraPinMixin = BaseMapPoiPinMixin:CreateSubPin("PIN_FRAME_LEVEL_FLIGHT_POINT");

	function QuestraPinMixin:OnAcquired(portalNodeInfo)
		BaseMapPoiPinMixin.OnAcquired(self, portalNodeInfo);

		self:ClearNudgeSettings();

		self:SetNudgeTargetFactor(0.015);
		self:SetNudgeZoomedOutFactor(1.25);
		self:SetNudgeZoomedInFactor(1);
		
		self.linkedUiMapID = portalNodeInfo.portal.destination.mapID;
		self.linkedUiCoords = portalNodeInfo.destination
		self.nodeID = portalNodeInfo.portal.index
		
		self.portal = portalNodeInfo.portal
	end

	function QuestraPinMixin:OnMouseClickAction(btn)
		if btn == "LeftButton" then
			Questra:PingAnywhere("map", self.portal.destination.x, self.portal.destination.y, self.portal.destination.mapID)
			PlaySound(SOUNDKIT.IG_QUEST_LOG_OPEN);
		else
			Questra:PinClickSetTracking(self, "Other", "QuestraPinTemplate")
		end	
	end

	function QuestraPinMixin:SetTexture(portalNodeInfo)
		BaseMapPoiPinMixin.SetTexture(self, portalNodeInfo);
	end
end