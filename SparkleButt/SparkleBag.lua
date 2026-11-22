-- SparkleBag v0.5 - automatic sequential matching deposits
-- One click queues verified one-stack operations. Only items originally in the bank qualify.
local B = CreateFrame("Frame", "SparkleBagController")
local BANK = BANK_CONTAINER or -1
local CARRIED = NUM_BAG_SLOTS or 4
local BANKBAGS = NUM_BANKBAGSLOTS or 7
local C = C_Container
local busy = false
local timer = 0
local before = nil
local selectedID = nil
local matched = nil
local movedStacks = 0
local attempts = 0
local cooldown = 0
local MAX_ATTEMPTS = 200
local function Say(s)
    DEFAULT_CHAT_FRAME:AddMessage("|cffc9d6e8SparkleBag:|r " .. s)
end
local function NumSlots(bag)
    local f = GetContainerNumSlots or (C and C.GetContainerNumSlots)
    if type(f) ~= "function" then return 0 end
    return f(bag) or 0
end
local function ItemLink(bag,slot)
    local f = GetContainerItemLink or (C and C.GetContainerItemLink)
    if type(f) == "function" then return f(bag,slot) end
end
local function ItemID(bag,slot)
    local f = GetContainerItemID or (C and C.GetContainerItemID)
    if type(f) == "function" then return f(bag,slot) end
    local link = ItemLink(bag,slot)
    if link then return tonumber(string.match(link,"item:(%d+)")) end
end
local function StackCount(bag,slot)
    if type(GetContainerItemInfo) == "function" then
        local _,count = GetContainerItemInfo(bag,slot)
        return count or 0
    end
    if C and type(C.GetContainerItemInfo) == "function" then
        local info = C.GetContainerItemInfo(bag,slot)
        if type(info)=="table" then return info.stackCount or info.count or 0 end
    end
    return 0
end
local function BankBags()
    local result={BANK}
    for bag=CARRIED+1,CARRIED+BANKBAGS do
        if NumSlots(bag)>0 then result[#result+1]=bag end
    end
    return result
end
local function CountIn(bags,id)
    local total=0
    for _,bag in ipairs(bags) do
        for slot=1,NumSlots(bag) do
            if ItemID(bag,slot)==id then total=total+StackCount(bag,slot) end
        end
    end
    return total
end
local function InventoryBags()
    local bags={}
    for bag=0,CARRIED do bags[#bags+1]=bag end
    return bags
end
local function HasBankRoom(id)
    local max=1
    if type(GetItemInfo)=="function" then
        for _,bag in ipairs(BankBags()) do
            for slot=1,NumSlots(bag) do
                if ItemID(bag,slot)==id then
                    local link=ItemLink(bag,slot)
                    if link then
                        local m=select(8,GetItemInfo(link))
                        if type(m)=="number" and m>0 then max=m end
                    end
                end
            end
        end
    end
    for _,bag in ipairs(BankBags()) do
        for slot=1,NumSlots(bag) do
            local dest=ItemID(bag,slot)
            if not dest or (dest==id and StackCount(bag,slot)<max) then return true end
        end
    end
    return false
end
local function Reset()
    busy=false
    before=nil
    selectedID=nil
    matched=nil
    movedStacks=0
    attempts=0
    timer=0
    cooldown=0
    B:SetScript("OnUpdate",nil)
end

local function FindNextMatch()
    -- The eligible IDs are captured once, before any transfers take place.
    -- Never expand this set based on items newly deposited by SparkleBag.
    for bag=0,CARRIED do
        for slot=1,NumSlots(bag) do
            local id=ItemID(bag,slot)
            if id and matched[id] and HasBankRoom(id) then
                return bag,slot,id
            end
        end
    end
end

local function Finish(reason)
    if reason then Say(reason) end
    Reset()
end

local function AttemptNext()
    if not busy or not B.bankOpen then
        Reset()
        return
    end
    if CursorHasItem and CursorHasItem() then
        Finish("Stopped: put down the cursor item before depositing.")
        return
    end
    if attempts >= MAX_ATTEMPTS then
        Finish("Stopped at the safety limit. Click again if more deposits are needed.")
        return
    end
    local bag,slot,id=FindNextMatch()
    if not bag then
        -- Nothing left to transfer. Quiet completion: no message spam.
        Reset()
        return
    end
    local use=UseContainerItem or (C and C.UseContainerItem)
    if type(use)~="function" then
        Finish("UseContainerItem is not exposed by this client.")
        return
    end
    selectedID=id
    before=CountIn(InventoryBags(),id)
    timer=0
    cooldown=0
    attempts=attempts+1
    local ok,err=pcall(use,bag,slot)
    if not ok then
        Finish("Deposit stopped: "..tostring(err))
    end
end

function SparkleBagToggle()
    if busy then return end
    if not B.bankOpen then Say("Open your personal bank first.") return end
    if CursorHasItem and CursorHasItem() then Say("Put down the cursor item before depositing.") return end
    local use=UseContainerItem or (C and C.UseContainerItem)
    if type(use)~="function" then Say("UseContainerItem is not exposed by this client.") return end
    matched={}
    for _,bag in ipairs(BankBags()) do
        for slot=1,NumSlots(bag) do
            local id=ItemID(bag,slot)
            if id then matched[id]=true end
        end
    end
    movedStacks=0
    attempts=0
    busy=true
    AttemptNext()
    if not busy then return end
    B:SetScript("OnUpdate",function(self,elapsed)
        if not busy then return end
        if not B.bankOpen then Reset() return end
        if before then
            timer=timer+elapsed
            local remaining=CountIn(InventoryBags(),selectedID)
            if remaining<before then
                -- Confirmed inventory decrease: wait briefly for bank updates
                -- before beginning the next, individually checked deposit.
                movedStacks=movedStacks+1
                before=nil
                cooldown=0.35
            elseif timer>=3 then
                Finish("Stopped: no inventory movement detected. Deposited "..movedStacks.." stack(s).")
                return
            end
        else
            cooldown=cooldown-elapsed
            if cooldown<=0 then AttemptNext() end
        end
    end)
end
B:RegisterEvent("BANKFRAME_OPENED")
B:RegisterEvent("BANKFRAME_CLOSED")
B:SetScript("OnEvent",function(self,event)
    if event=="BANKFRAME_OPENED" then B.bankOpen=true
    elseif event=="BANKFRAME_CLOSED" then
        B.bankOpen=false
        if busy then Reset() end
    end
end)
