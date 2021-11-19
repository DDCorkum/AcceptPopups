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

1.2 (2021-11-19) by Dahk Celes
- Blocklist improvements
- No action on normal clicks (bugfix)

1.1 (2021-11-17) by Dahk Celes
- Prepopulated blocklist
- Error detection for auto-blocklist

1.0 (2021-11-11) by Dahk Celes
- Initial version

--]]

local BLOCKLIST = -1

AcceptPopupsUntil = {}	-- saved variable

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

local function onUpdate(self)
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

local function onEnter(self)
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

local function onLeave(self)
	GameTooltip:Hide()
end

local function onShow(self)
	self:SetScript("OnUpdate", onUpdate) -- delays until the next frame
	self:HookScript("OnEnter", onEnter)
	self:HookScript("OnLeave", onLeave)
end

local function onHide(self)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)
end

local function preClick(self, button)
	local which = self:GetParent().which
	if isEligibleDialog(which) and button ~= "Button30" and IsModifierKeyDown() then
		AcceptPopupsUntil[which] = time() + (IsShiftKeyDown() and 86400 or IsControlKeyDown() and 604800 or 259200)
	end
end

StaticPopup1Button1:HookScript("OnShow", onShow)
StaticPopup1Button1:HookScript("OnHide", onHide)
StaticPopup1Button1:HookScript("PreClick", preClick)

StaticPopup2Button1:HookScript("OnShow", onShow)
StaticPopup2Button1:HookScript("OnHide", onHide)
StaticPopup2Button1:HookScript("PreClick", preClick)

StaticPopup3Button1:HookScript("OnShow", onShow)
StaticPopup2Button1:HookScript("OnHide", onHide)
StaticPopup3Button1:HookScript("PreClick", preClick)