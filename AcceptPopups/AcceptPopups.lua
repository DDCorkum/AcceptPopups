--[[

## Title: AcceptPopups
## Notes: Accepts a dialog for a day, week or month
## Author: Dahk Celes (DDCorkum)
## X-License: All rights reserved

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

1.3 (2021-12-08) by Dahk Celes
- Rudimentary options menu
- 30 day duration with alt (bugfix)

1.2 (2021-11-19) by Dahk Celes
- Blocklist improvements
- No action on normal clicks (bugfix)

1.1 (2021-11-17) by Dahk Celes
- Prepopulated blocklist
- Error detection for auto-blocklist

1.0 (2021-11-11) by Dahk Celes
- Initial version

--]]


-------------------------
-- Constants

local BLOCKLIST = -1

local neverAcceptPopups =
{
	-- Protected
	["ADD_FRIEND"] = BLOCKLIST,							-- C_FriendList.AddFriend()
	["BID_AUCTION"] = BLOCKLIST,						-- C_AuctionHouse.PlaceBid()
	["BID_BLACKMARKET"] = BLOCKLIST,					-- C_BlackMarket.ItemPlaceBid()
	["BUYOUT_AUCTION"] = BLOCKLIST,						-- C_AuctionHouse.PlaceBid()
	["CANCEL_AUCTION"] = BLOCKLIST,						-- C_AuctionHouse.CancelAuction()
	["DIALOG_REPLACE_MOUNT_EQUIPMENT"] = BLOCKLIST,		-- C_MountJournal.ApplyMountEquipment()
	["DANGEROUS_SCRIPTS_WARNING"] = BLOCKLIST,			-- SetAllowDangerousScripts()
	["QUIT"] = BLOCKLIST,								-- ForceQuit()
		
	-- Requires user input
	["BATTLE_PET_RENAME"] = BLOCKLIST,
	["NAME_CHAT"] = BLOCKLIST,
	["RENAME_GUILD"] = BLOCKLIST,
	["RENAME_PET"] = BLOCKLIST,
}


-------------------------
-- Saved Variables

AcceptPopupsUntil = {}


-------------------------
-- Popup Automation

do
	local function isEligibleDialog(which)
		dialog = StaticPopupDialogs[which]
		return
			not neverAcceptPopups[which]
			and AcceptPopupsUntil[which] ~= BLOCKLIST
			and dialog.hasMoneyInputFrame ~= 1
			and (dialog.button2 or dialog.button3 or dialog.button4)	-- rules out dialogs with only a single button, such as StaticPopupDialogs.CAMP
	end

	local listener = CreateFrame("Frame")
	listener:RegisterEvent("ADDON_ACTION_FORBIDDEN")
	listener:RegisterEvent("ADDON_ACTION_BLOCKED")
	listener:SetScript("OnEvent", function()
		if listener.listenFor then
			print("AcceptPopups detected an error so it will no longer try to automate " .. listener.listenFor .. " popups.")
			listener.listenFor = nil
		end
	end)

	local function popupOnUpdate(self)
		self:SetScript("OnUpdate", nil)
		local which = self:GetParent().which
		if AcceptPopupsUntil[which] and isEligibleDialog(which) and AcceptPopupsUntil[which] > time() then
			listener.listenFor = which
			self:Enable()
			local expiry = AcceptPopupsUntil[which]
			AcceptPopupsUntil[which] = BLOCKLIST
			self:Click("Button30")
			C_Timer.After(0.2, function()
				if listener.listenFor then
					listener.listenFor = nil
					AcceptPopupsUntil[which] = expiry
				end
			end)
		end	
	end

	local function popupOnEnter(self)
		local which = self:GetParent().which
		if isEligibleDialog(which) then
			if GameTooltip:GetOwner() ~= self then
				GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
			end
			GameTooltip:AddLine("AcceptPopups")
			GameTooltip:AddLine("|cffccccff" .. SHIFT_KEY_TEXT .. "|r|cff999999 - 1 " .. DAYS)
			GameTooltip:AddLine("|cffccccff" .. CTRL_KEY_TEXT .. "|r|cff999999 - 7 " .. DAYS)
			GameTooltip:AddLine("|cffccccff" .. ALT_KEY_TEXT .. "|r|cff999999 - 30 " .. DAYS)
			GameTooltip:Show()
		end

	end

	local function popupOnLeave(self)
		GameTooltip:Hide()
	end

	local function popupOnShow(self)
		self:SetScript("OnUpdate", popupOnUpdate) -- delays until the next frame
		self:HookScript("OnEnter", popupOnEnter)
		self:HookScript("OnLeave", popupOnLeave)
	end

	local function popupOnHide(self)
		self:SetScript("OnEnter", nil)
		self:SetScript("OnLeave", nil)
	end

	local function popupPreClick(self, button)
		local which = self:GetParent().which
		if isEligibleDialog(which) and button ~= "Button30" and IsModifierKeyDown() then
			AcceptPopupsUntil[which] = time() + (IsShiftKeyDown() and 86400 or IsControlKeyDown() and 604800 or 2592000)
		end
	end

	StaticPopup1Button1:HookScript("OnShow", popupOnShow)
	StaticPopup1Button1:HookScript("OnHide", popupOnHide)
	StaticPopup1Button1:HookScript("PreClick", popupPreClick)

	StaticPopup2Button1:HookScript("OnShow", popupOnShow)
	StaticPopup2Button1:HookScript("OnHide", popupOnHide)
	StaticPopup2Button1:HookScript("PreClick", popupPreClick)

	StaticPopup3Button1:HookScript("OnShow", popupOnShow)
	StaticPopup2Button1:HookScript("OnHide", popupOnHide)
	StaticPopup3Button1:HookScript("PreClick", popupPreClick)
end


-------------------------
-- Options Menu

do
	local panel = CreateFrame("Frame")
	panel.name = "AcceptPopups"
	panel:Hide()
	InterfaceOptions_AddCategory(panel)

	local title = panel:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
	title:SetText("AcceptPopups")
	title:SetPoint("TOP", 0, -5)

	local subtitle = panel:CreateFontString("ARTWORK", nil, "GameFontNormal")
	subtitle:SetText("Accepts a dialog for a day, week or month")
	subtitle:SetPoint("TOP", title, "BOTTOM", 0, -2)

	local fontStrings = CreateFontStringPool(panel, "ARTWORK", 0, "GameFontNormal")
	local buttons = CreateObjectPool(
		function(self)
			local button = CreateFrame("Button", nil, panel, "UIPanelButtonNoTooltipTemplate")
			button:SetSize(14,14)
			button:SetText("?")
			button:SetScript("OnClick", function()
				if IsModifierKeyDown() then
					AcceptPopupsUntil[button.key] = time() + (IsShiftKeyDown() and 86400 or IsControlKeyDown() and 604800 or 2592000)
				else
					AcceptPopupsUntil[button.key] = 1
				end
				panel:Hide()
				panel:Show()
			end)
			button:SetScript("OnEnter", function()
				GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
				GameTooltip:AddLine("AcceptPopups")
				GameTooltip:AddLine("|cffccccff" .. SHIFT_KEY_TEXT .. "|r|cff999999 - 1 " .. DAYS)
				GameTooltip:AddLine("|cffccccff" .. CTRL_KEY_TEXT .. "|r|cff999999 - 7 " .. DAYS)
				GameTooltip:AddLine("|cffccccff" .. ALT_KEY_TEXT .. "|r|cff999999 - 30 " .. DAYS)
				if AcceptPopupsUntil[button.key] > time() then
					GameTooltip:AddLine("|cffccccff" .. NONE .. "|r|cffff6666 " .. CANCEL)
				end
				GameTooltip:Show()
			end)
			button:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)
			return button
		end,
		FramePool_HideAndClearAnchors
	)
	

	local function panelOnShow(self)
		local y = -50
		for key, date in pairs(AcceptPopupsUntil) do
			if (date > 0) then
				local duration = date - time()
				local fontString = fontStrings:Acquire()
				if duration > 86400 then
					fontString:SetText(key .. " |cff999999" .. SPELL_DURATION_DAYS:format(duration/86400))
				elseif duration > 0 then
					fontString:SetText(key .. " |cff999999" .. SPELL_DURATION_HOURS:format(duration/3600))
				else
					fontString:SetText(key .. " |cff996666" .. LFG_LIST_APP_TIMED_OUT)
				end
				fontString:SetPoint("LEFT", panel, "TOPLEFT", 30, y)
				fontString:Show()
				local button = buttons:Acquire()
				button:SetPoint("LEFT", panel, "TOPLEFT", 15, y)
				button.key = key
				button:Show()
				y = y - 15
			end
		end
	end

	local function panelOnHide(self)
		fontStrings:ReleaseAll()
		buttons:ReleaseAll()
	end

	panel:SetScript("OnShow", panelOnShow)
	panel:SetScript("OnHide", panelOnHide)

	SlashCmdList.ACCEPTPOPUPS = function() InterfaceOptionsFrame_OpenToCategory(panel) end
	SLASH_ACCEPTPOPUPS1 = "/acceptpopups"
end