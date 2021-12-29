local AddonName, Questra = ...

--group button
local oldold = C_LFGList.CanCreateQuestGroup

local function CanCreateQuestGroup(questID, ...)
	if not questID or questID == 0 or (type(questID) ~= "number")then return end
	local o = oldold(questID, ...)
	if o then
		return o
	end
	
	local info = questID and C_QuestLog.GetQuestTagInfo(questID)

	if info and info.worldQuestType == 6 then
		return true, true
	end
end

local op = {
	Left = "Right",
	Right = "Left",
	Bottom = "Top",
	Top = "Bottom",
}


local function QuickJoinToastMixin_OnEnter(button, questID, queued)
	if not questID then
		return --print(button, questID)
	end
	local canMake = CanCreateQuestGroup(questID)

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

	local focus = focus ~= Questra.frame and DoesAncestryInclude(Questra.frame, focus) == true or nil

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
	local texture = self.pupil
	local _time = secs()
	local seconds = _time - cTime
	if seconds - lastElapsed  <= updateInterval then return end
	lastElapsed = seconds
	
	update = update < actionStep and update + 1 or 1
	--only update if enough time has passed
	if update < 1 then return else update = 0 end 

	local self = self.pupil:GetParent()

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
		texture = coords.rotate and Questra.textures.swirl or Questra.textures.pupil

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
	
	self.upper:SetTexture(Questra.textures["upper"..up])
	self.lower:SetTexture(Questra.textures["lower"..low])
	
	self.upper:SetVertexColor(255/255,215/255,0)
	self.lower:SetVertexColor(255/255,215/255,0)
	
	--self.green:SetVertexColor(0,1,0)
	-- local inGroup = IsInGroup()
	-- if inGroup then
		-- self.green:SetVertexColor(0, 1, 0, 1)
	-- else
		-- self.green:SetVertexColor(.3, .53, 1)
	-- end
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
	eye.pupil:SetTexture(Questra.textures.pupil)
	eye.upper:SetTexture(Questra.textures.upper1)
	eye.lower:SetTexture(Questra.textures.lower1)
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

local function GetAnchorsNearestScreenCenter(self)
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
Questra.GetAnchorsNearestScreenCenter = GetAnchorsNearestScreenCenter


local GFB = {
	name = "groupButton",
	displayName = "Group Finder",
	parentElementName = "frame",
	Build = function(parentElement, ...)
		local button = CreateFrame("Button", "Questra-GroupFinder", parentElement, "Questra_GroupFinderButton")
		button:ClearAllPoints()
		button:SetFrameStrata("BACKGROUND")
		button:SetPoint("Left", parentElement, "Left", -7, -25)

		button:SetSize(35, 35)

		button.green:SetTexture("Interface\\AddOns\\"..AddonName.."\\artwork\\".."Eye\\green")
		button.pupil:SetTexture(Questra.textures.pupil)
		button.shine:SetTexture("Interface\\AddOns\\"..AddonName.."\\artwork\\".."Eye\\shine")

		button.yAnchor = -25
		button.xAnchor = -7

		button:RegisterForClicks("AnyUp")
	
		return button
	end,
}
	GFB.OnQuestUpdate = function(_, questID)
		local showGroup, shouldAnimate, isQueued = shouldShowAndOrAnimate()

		canCreateGroup[questID or 0] = questID and canCreateGroup[questID] or questID and CanCreateQuestGroup(questID) or false
		local state = UnitInAnyGroup("player") == true and true or showGroup or canCreateGroup[questID]
		
		local alwaysShow = GFB.sets.alwaysShow == true
		
		local groupButton = Questra.groupButton
		
		if GFB.sets.alwaysShow == true then
			groupButton = Questra.groupButton
		
		elseif not state then
			if groupButton and groupButton:IsShown() then
				groupButton:Hide()
			end
			groupButton = nil
			return
		end
		
		
		if groupButton then
			groupButton.isQueued = isQueued
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
			GFB.questID = questID
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
		
		
			if groupButton:IsShown() and GFB.sets.hideDefault == true then
				QueueStatusMinimapButton:Hide()
			end
		
			return d
		end
	end
	
	
	GFB.Layout = function(self, sets)
		self:ClearAllPoints()
		if sets.flip == true then
			self:SetPoint("Left", self:GetParent(), "Left", -7, 22)
			self.yAnchor = 22
			self.ybump = -1
		else
			self:SetPoint("Left", self:GetParent(), "Left", -7, -25)
			self.yAnchor = -25
			self.ybump = 1
		end
	end
	GFB.scripts = {
		OnClick = function(self, btn, ...)
			self.DropDown = self.DropDown or QueueStatusMinimapButton.DropDown
			if (not InCombatLockdown()) then

				local show, animate, isQueued = shouldShowAndOrAnimate()
				
				local lfgListActiveEntry = C_LFGList.HasActiveEntryInfo()
				
				if btn == "RightButton" then
					do
						local inBattlefield, showScoreboard = QueueStatus_InActiveBattlefield()
						if isQueued then
						--user is searching for group
						self.DropDown.id = self.questID
						QueueStatusDropDown_Show(self.DropDown, self:GetName())
						local p1, p2 = Questra.GetAnchorsNearestScreenCenter(self)
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
							local p1, p2 = Questra.GetAnchorsNearestScreenCenter(self)
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
						local p1, p2 = Questra.GetAnchorsNearestScreenCenter(self)
						DropDownList1:ClearAllPoints()
						DropDownList1:SetPoint(p2, self, p1)
						return
					else
						if self.questID then
							local title =  C_TaskQuest.GetQuestInfoByQuestID(self.questID) or C_QuestLog.GetTitleForQuestID(self.questID) or nil

							local x,y, zoneID = Questra:GetQuestLocation(self.questID, true)
							local name = title and string.split(":", title)
							local dungeonID = zoneID and GetInstanceIDByName(zoneID, name)
						
						
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
					end
				
					PVEFrame_ToggleFrame("GroupFinderFrame", "LFDParentFrame")
				end
			end
		end,
		OnMouseDown = function(self)
			self:SetSize(30, 40)
			self:SetPoint("Left", self:GetParent(), "Left", -3, self.yAnchor + self.ybump)
		end,
		OnMouseUp = function(self)
			self:SetSize(35, 35)
			self:SetPoint("Left", self:GetParent(), "Left", -7, self.yAnchor)
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


GFB.options = {
		{
			kind = "CheckButton",
			title = "Always Show",
			key = "alwaysShow",
			default = false,
			OnClick = function(self)
				GFB.sets.alwaysShow = not GFB.sets.alwaysShow
				self:SetChecked(GFB.sets.alwaysShow)
				
				GFB.OnQuestUpdate(nil, GFB.questID)	
			end,
			OnShow = function(self)
				self:SetChecked(GFB.sets.alwaysShow)
			end,
		},
		{
			kind = "CheckButton",
			title = "Hide Default Group Button",
			key = "hideDefault",
			default = false,
			OnClick = function(self)
				GFB.sets.hideDefault = not GFB.sets.hideDefault
				self:SetChecked(GFB.sets.hideDefault)
				
				GFB.OnQuestUpdate(nil, GFB.questID)	
			end,
			OnShow = function(self)
				self:SetChecked(GFB.sets.hideDefault)
			end,
		},
	}
	


Questra:AddElement(GFB)	
