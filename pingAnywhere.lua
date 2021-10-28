--handy tools derived from: "Interface\AddOns\Blizzard_SharedMapDataProviders\WorldQuestDataProvider.lua"
local _, Questra = ...
local pingAnywhere  = {lastFlight = nil, lastMap = nil}

local HBD = Questra.HBD

function pingAnywhere.chat(x, y, mapID, questID)
	--chat-link function created from scratch!
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

function pingAnywhere.map(x, y, wayMapID)
	if wayMapID == 0 then
		return
	end
	OpenWorldMap(wayMapID)

	WorldMapFrame:SetMapID(wayMapID);

	pingAnywhere.mapPin = pingAnywhere.mapPin or WorldMapFrame:AcquirePin("QuestraPingPinTemplate")

	if x and y then
		--safety precaution
		while x > 1 do
			x = x / 10
		end
		while y > 1 do
			y = y / 10
		end
		if (not pingAnywhere.mapPin.DriverAnimation:IsPlaying()) or pingAnywhere.lastMap ~= x..y..wayMapID then
			pingAnywhere.mapPin:Show()
			pingAnywhere.mapPin:GetMap():SetPinPosition(pingAnywhere.mapPin, x, y)
			pingAnywhere.mapPin.DriverAnimation:Play()
			pingAnywhere.lastMap = x..y..wayMapID
		end
	else
		pingAnywhere.mapPin.DriverAnimation:Stop()
		pingAnywhere.mapPin:Hide()
	end
end

function pingAnywhere.flight(x, y, wayMapID)
	pingAnywhere.flightPin = pingAnywhere.flightPin or FlightMapFrame:AcquirePin("QuestraPingPinTemplate")
	
	pingAnywhere.flightPin.DriverAnimation:Stop()
	pingAnywhere.flightPin:Hide()

	if wayMapID and x and y then
		do --override display, if ping point isn't displayed at current zoom level and position
			local x, y = HBD:TranslateZoneCoordinates(.5, .5, wayMapID, FlightMapFrame.mapID, true)					
			FlightMapFrame:InstantPanAndZoom(FlightMapFrame:GetScaleForMaxZoom(), x, y, true);
		end
		local x, y = HBD:TranslateZoneCoordinates(x, y, wayMapID, FlightMapFrame.mapID, true)

		if (not pingAnywhere.flightPin.DriverAnimation:IsPlaying()) or pingAnywhere.lastFlight ~= x..y..wayMapID then
			pingAnywhere.flightPin:Show()
			FlightMapFrame:SetPinPosition(pingAnywhere.flightPin, x, y)
			pingAnywhere.flightPin.DriverAnimation:Play()
			pingAnywhere.lastFlight = x..y..wayMapID
		end
	else
		pingAnywhere.flightPin.DriverAnimation:Stop()
		pingAnywhere.flightPin:Hide()
	end
end

function Questra:PingAnywhere(where, x, y, mapID, questID)
	local where = string.lower(where)
	local _ = where and pingAnywhere[where] and pingAnywhere[where](x, y, mapID, questID)
end