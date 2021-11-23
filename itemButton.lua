local AddonName, Questra = ...
local itemButton = {name = "itemButton", parentElementName = "frame"}

function itemButton:Build(...)
	local button = CreateFrame("Button", AddonName.."_ItemButton", self, "QuestraItemButtonTemplate")
	button:EnableMouse(true)
	button:SetFrameStrata("BACKGROUND")
	button.Cooldown:SetAllPoints(button.icon)
	button:SetPoint("Right", self, "Right", 7, -25)
	button:SetSize(35, 35)
	button.width, button.height = button:GetSize()
		
	return button
end

function itemButton:OnQuestUpdate(currentQuestID)
	currentQuestID = (currentQuestID and type(currentQuestID) == "number") and currentQuestID or nil
	local items = self.items

	wipe(items)

	for i = 1, C_QuestLog.GetNumQuestWatches() do --quest log
		local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
		if questID then
			local questLogIndex = questID and C_QuestLog.GetLogIndexForQuestID(questID)
						
			if questLogIndex then
				local link, item, charges, showItemWhenComplete = GetQuestLogSpecialItemInfo(questLogIndex)
				if link then 
					if not tContains(items, questID) then
						if currentQuestID == questID then
							tinsert(items, 1, questID)
						else
							tinsert(items, questID)
						end
					end
				end
			end
		end
	end	
	
	local uiMapID = Questra:GetPlayerMapID()
	local taskInfo = uiMapID and C_TaskQuest.GetQuestsForPlayerByMapID(uiMapID)
	if taskInfo then --world quests in current zone
		for i, info in ipairs(taskInfo) do
			local questID = info.questID or info.questId
			local questLogIndex = questID and C_QuestLog.GetLogIndexForQuestID(questID)
						
			if questLogIndex then
				local link, item, charges, showItemWhenComplete = GetQuestLogSpecialItemInfo(questLogIndex)
				if link then 
					if not tContains(items, questID) then
						if currentQuestID == questID then
							tinsert(items, 1, questID)
						else
							tinsert(items, questID)
						end
					end
				end
			end
		end
	end

	local num = #items
	
	local displayedQuestID = currentQuestID
	
	if num > 0 then
		self.scroll = (self.scroll and (self.scroll > num) and 1) or (self.scroll and (self.scroll < 1) and num) or self.scroll or 1
		displayedQuestID = items[self.scroll]
	end
		
	if not InCombatLockdown() then
		if displayedQuestID then
			local displayedQuestLogIndex = C_QuestLog.GetLogIndexForQuestID(displayedQuestID)
			if displayedQuestLogIndex then
				local link, item, charges = GetQuestLogSpecialItemInfo(displayedQuestLogIndex)
			
				if link then
					local itemID = GetItemInfoInstant(link)

					if IsItemInRange(itemID, "target") == true or IsItemInRange(itemID, "mouseover") == true then
						self.Normal:SetVertexColor(1,1,1,1)
					else
						self.Normal:SetVertexColor(1,0,0,1)
					end

					local itemID = GetItemInfoInstant(link)
					self.charges = charges
					self.rangeTimer = -1
					SetItemButtonTexture(self, item)
					SetItemButtonCount(self, GetItemCount(link))

					self.Count:SetText(GetItemCount(link))

					if not InCombatLockdown() then
						self:SetAttribute('type', 'macro')
						self:SetAttribute('macrotext', '/use ' .. GetItemInfo(itemID))
						self:SetID(itemID)
						self.QuestID = itemID
					end
					SetPortraitToTexture(self.icon, self.icon:GetTexture())

					if not InCombatLockdown() and not self:IsShown() then
						self:Show()
					end
				end
			end
		else
			if self and not InCombatLockdown() and self:IsShown() then
				self:Hide()
			end
		end
	end
end

function itemButton:OnUpdate()
	if self:IsVisible() and self.QuestID then
		local start, duration, enable = GetItemCooldown(self.QuestID)
		if ( start ) then
			CooldownFrame_Set(self.Cooldown, start, duration, enable)
			if ( duration > 0 and enable == 0 ) then
				SetItemButtonTextureVertexColor(self, 0.4, 0.4, 0.4)
			else
				SetItemButtonTextureVertexColor(self, 1, 1, 1)
			end
		end
	end
end

itemButton.scripts = {
	OnLoad = function(self)
		self.items = self.items or {}
	end,
	OnMouseWheel = function(self, delta)
		self.scroll = self.scroll and self.scroll + delta or 1
		self:OnQuestUpdate()
	end,
	OnEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetItemByID(self.QuestID)
		self:OnQuestUpdate()
	end,
}

Questra:AddElement(itemButton)	
