--[[

## Title: AcceptPopups
## Notes: Accepts a dialog for a day, week or month
## Author: Dahk Celes (DDCorkum)
## X-License: All rights reserved
## Version: 1.0

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

1.0 (2021-11-11) by Dahk Celes
- Initial version

--]]

local BLOCKLIST = -1

AcceptPopupsUntil = {}

local function onUpdate(self)
	self:SetScript("OnUpdate", nil)
	local which = self:GetParent().which
	if AcceptPopupsUntil[which] and AcceptPopupsUntil[which] > time() then
		self:Enable()
		if not pcall(self.Click, self, "Button30") then
			AcceptPopupsUntil[which] = BLOCKLIST
		end
	end	
end

local function onEnter(self)
	local which = self:GetParent().which
	if (GameTooltip:GetOwner() ~= self) then
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
	end
	GameTooltip:AddLine("AcceptPopups")
	if AcceptPopupsUntil[which] ~= BLOCKLIST then
		GameTooltip:AddLine("|cffccccff" .. SHIFT_KEY_TEXT .. "|r|cff999999 - 1 " .. DAYS)
		GameTooltip:AddLine("|cffccccff" .. CTRL_KEY_TEXT .. "|r|cff999999 - 7 " .. DAYS)
		GameTooltip:AddLine("|cffccccff" .. ALT_KEY_TEXT .. "|r|cff999999 - 30 " .. DAYS)
	else
		GameTooltip:AddLine("|cff999999Unavailable for this message type.")
	end
	GameTooltip:Show()
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

local function onClick(self, button)
	local which = self:GetParent().which
	if AcceptPopupsUntil[which] ~= BLOCKLIST and button ~= "Button30" then
		if IsShiftKeyDown() then
			AcceptPopupsUntil[which] = time() + 86400
		elseif IsControlKeyDown() then
			AcceptPopupsUntil[which] = time() + 604800
		elseif IsAltKeyDown() then
			AcceptPopupsUntil[which] = time() + 2592000
		end
	end
end

StaticPopup1Button1:HookScript("OnShow", onShow)
StaticPopup1Button1:HookScript("OnHide", onHide)
StaticPopup1Button1:HookScript("OnClick", onClick)

StaticPopup2Button1:HookScript("OnShow", onShow)
StaticPopup2Button1:HookScript("OnHide", onHide)
StaticPopup2Button1:HookScript("OnClick", onClick)

StaticPopup3Button1:HookScript("OnShow", onShow)
StaticPopup2Button1:HookScript("OnHide", onHide)
StaticPopup3Button1:HookScript("OnClick", onClick)