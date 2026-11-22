-- SparkleWand v0.1 TEST for WoW Forever (Interface 16001).
-- Standalone, integrated toggle; experimental secure right-click Shoot binding.
-- Disable AutoWand or any competing BUTTON2 interception addon before testing.
local frame = CreateFrame("Frame")
local secureButton, driver, bound = nil, nil, false
local ready, enabled = false, true
local spellId = 5019
local function Log(msg)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffaf72d8SparkleWand:|r "..msg) end
end
local function HasWand()
    local slot = INVSLOT_RANGED or 18
    local itemId = GetInventoryItemID("player",slot)
    if not itemId then return false end
    if C_Item and C_Item.GetItemInfoInstant then
        local _,_,_,equipLoc,_,classId,subClassId=C_Item.GetItemInfoInstant(itemId)
        return (classId==2 and subClassId==19) or equipLoc=="INVTYPE_RANGEDRIGHT"
    end
    return false
end
local function Refresh()
    if not ready or InCombatLockdown() then return end
    -- A secure state driver updates its binding as the mouseover changes,
    -- including during combat. We never edit protected attributes in combat.
    local shouldBind = enabled and HasWand() and (not IsPlayerSpell or IsPlayerSpell(spellId))
    if shouldBind and not bound then
        RegisterStateDriver(driver,"sparklehover","[@mouseover,harm,nodead] wand; off")
        bound=true
    elseif not shouldBind and bound then
        UnregisterStateDriver(driver,"sparklehover")
        driver:Execute("self:ClearBindings()")
        bound=false
    end
end
function SparkleWandIsEnabled() return enabled end
function SparkleWandToggle()
    enabled=not enabled
    if SparkleButtDB then SparkleButtDB.sparkleWandEnabled=enabled end
    if InCombatLockdown() then
        Log((enabled and "ON" or "OFF").." requested; right-click binding updates when combat ends.")
    else
        Refresh()
        Log(enabled and "ON" or "OFF")
    end
    if type(SparkleButtRefreshSelector)=="function" then SparkleButtRefreshSelector() end
end
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame:RegisterEvent("SPELLS_CHANGED")
frame:SetScript("OnEvent",function(_,event)
    if event=="PLAYER_LOGIN" then
        if SparkleButtDB and SparkleButtDB.sparkleWandEnabled~=nil then
            enabled=SparkleButtDB.sparkleWandEnabled
        end
        local _,class=UnitClass("player")
        if class~="MAGE" and class~="PRIEST" and class~="WARLOCK" then
            enabled=false
        end
        secureButton=CreateFrame("Button","SparkleWandShootSecureButton",UIParent,"SecureActionButtonTemplate")
        secureButton:RegisterForClicks("AnyUp")
        secureButton:SetAttribute("useOnKeyDown",false)
        secureButton:SetAttribute("type","macro")
        local name=(C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellId)) or (GetSpellInfo and GetSpellInfo(spellId)) or "Shoot"
        secureButton:SetAttribute("macrotext","/target [@mouseover,harm,nodead]\n/stopattack\n/cast !"..name)
        secureButton:Hide()
        driver=CreateFrame("Frame","SparkleWandSecureDriver",UIParent,"SecureHandlerStateTemplate")
        driver:SetAttribute("_onstate-sparklehover",[[
            if newstate == "wand" then
                self:SetBindingClick(true,"BUTTON2","SparkleWandShootSecureButton")
            else
                self:ClearBindings()
            end
        ]])
        ready=true
    end
    Refresh()
end)
