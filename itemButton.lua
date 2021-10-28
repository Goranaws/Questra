local AddonName, Questra = ...
--item button

local  questItems = {}
local itemScroll = 1
local lastItemQuestID
function Questra:ShowItemButton(itemQuestID)
	itemQuestID = (itemQuestID and type(itemQuestID) == "number") and itemQuestID or nil

	wipe(questItems)

	local hasItem

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
	if index and index ~= 0 then
		local link, item, charges, showItemWhenComplete = GetQuestLogSpecialItemInfo(index)
		if link then
			tinsert(questItems, 1, itemQuestID)
			itemScroll = 1
		end	
	end
	
	
	local num = #questItems
			
	if num > 0 then
		itemScroll = ((itemScroll > num) and 1) or ((itemScroll < 1) and num) or itemScroll or 1
		itemQuestID = questItems[itemScroll]
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

Questra:AddElement({
	name = "itemButton",
	parentElementName = "frame",
	OnQuestUpdate = function(self, questID)
		Questra:ShowItemButton(questID)
	end,
	Build = function(parentElement, ...)
		local button = CreateFrame("Button", AddonName.."_ItemButton", parentElement, "QuestraItemButtonTemplate")
		button:EnableMouse(true)
		button:SetFrameStrata("BACKGROUND")
		button.Cooldown:SetAllPoints(button.icon)
		button:SetPoint("Right", parentElement, "Right", 7, -25)
		
		
		button:SetSize(35, 35)
		
		return button
	end,
	OnUpdate = function(self)
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
	end,
	scripts = {
		OnMouseWheel = function(self, delta)
			self.scroll = self.scroll and self.scroll + delta or 1
			Questra:ShowItemButton()
		end,
		OnEnter = function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetItemByID(self:GetID())
			Questra:ShowItemButton(self:GetID()) --update on enter, in case combat has ended
		end,
		OnLeave = function(self)
			GameTooltip:Hide()
		end,
		OnMouseDown = function(self)
			self.textureHandler:SetSize(40, 32)
			self.icon:SetSize(37, 25)
			self.textureHandler:SetPoint("Center", self, 0, -2)
		end,
		OnMouseUp = function(self)
			self.textureHandler:SetSize(35, 35)
			self.icon:SetSize(30,30)
			self.textureHandler:SetPoint("Center", self)
		end,
	},
})	
