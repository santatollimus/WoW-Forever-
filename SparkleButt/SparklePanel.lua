-- SparkleButt Combat Panel v0.6.57 nameplate-first deduplication
-- Display-only, movable, non-secure frame. Does not call targeting functions.
-- The WoW client exposes nameplate units only when their nameplates are present;
-- this is NOT a radar for enemies outside the client's exposed unit set.
local panel, rows
local positioning = false
local testMode = false -- manually toggled, never saved
local elapsed = 0
local MAX_ROWS = 12
local WIDTH, HEIGHT, GAP = 128, 28, 4

local function DB()
    SparkleButtDB = SparkleButtDB or {}
    local db = SparkleButtDB
    if db.panelEnabled == nil then db.panelEnabled = false end -- explicit opt-in
    if type(db.panelX) ~= "number" then db.panelX = -270 end
    if type(db.panelY) ~= "number" then db.panelY = -210 end
    return db
end
local function Say(s)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffbd565cSparkleButt Panel|r " .. s)
    end
end
local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    if ok then return value end
    return nil
end
-- WoW 12.x may return secret combat values. A secret is not safe for
-- Lua comparison, arithmetic, concatenation, sorting, or table keys.
local function IsSecret(value)
    return type(issecretvalue) == "function" and issecretvalue(value) or false
end
local function Plain(value)
    if IsSecret(value) then return nil end
    return value
end
local function Combat()
    return SafeCall(UnitAffectingCombat, "player") or (type(InCombatLockdown)=="function" and InCombatLockdown()) or false
end
local function SetAnchor()
    if not panel then return end
    local db=DB()
    panel:ClearAllPoints()
    panel:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", db.panelX, db.panelY)
end
local function StoreAnchor()
    if not panel then return end
    local right, top=panel:GetRight(), panel:GetTop()
    if right and top then
        local db=DB()
        db.panelX=right-UIParent:GetRight()
        db.panelY=top-UIParent:GetTop()
        SetAnchor()
    end
end
local function MakeRow(parent, index)
    local row=CreateFrame("Frame",nil,parent)
    row:SetSize(WIDTH,HEIGHT)
    row:SetPoint("TOPLEFT",parent,"TOPLEFT",0,-(index-1)*(HEIGHT+GAP))
    local bg=row:CreateTexture(nil,"BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.075,0.065,0.075,0.77)
    local border=row:CreateTexture(nil,"BORDER")
    border:SetPoint("TOPLEFT",row,"TOPLEFT",0,0)
    border:SetPoint("TOPRIGHT",row,"TOPRIGHT",0,0)
    border:SetHeight(1)
    border:SetColorTexture(0.48,0.20,0.23,0.8)
    local name=row:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    name:SetPoint("TOPLEFT",row,"TOPLEFT",5,-2)
    name:SetWidth(104)
    name:SetHeight(14)
    name:SetJustifyH("LEFT")
    name:SetTextColor(1,0.85,0.79)
    local level=row:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    level:SetPoint("TOPRIGHT",row,"TOPRIGHT",-4,-2)
    level:SetJustifyH("RIGHT")
    level:SetTextColor(0.82,0.73,0.69)
    local barBg=row:CreateTexture(nil,"ARTWORK")
    barBg:SetPoint("BOTTOMLEFT",row,"BOTTOMLEFT",5,4)
    barBg:SetSize(WIDTH-10,9)
    barBg:SetColorTexture(0.26,0.10,0.11,0.95)
    -- Native StatusBar accepts secret health values without Lua arithmetic.
    local bar=CreateFrame("StatusBar",nil,row)
    bar:SetAllPoints(barBg)
    bar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    bar:SetStatusBarColor(0.72,0.19,0.22,0.95)
    bar:SetMinMaxValues(0,100)
    bar:SetValue(100)
    -- A display-only target indicator; never calls TargetUnit or creates secure actions.
    row.targetEdge={}
    for _,spec in ipairs({{"TOPLEFT","TOPRIGHT",2}, {"BOTTOMLEFT","BOTTOMRIGHT",2}}) do
        local edge=row:CreateTexture(nil,"OVERLAY")
        edge:SetPoint(spec[1],row,spec[1],0,0)
        edge:SetPoint(spec[2],row,spec[2],0,0)
        edge:SetHeight(spec[3])
        edge:SetColorTexture(1,0.79,0.14,1)
        edge:Hide()
        row.targetEdge[#row.targetEdge+1]=edge
    end
    for _,side in ipairs({"left","right"}) do
        local edge=row:CreateTexture(nil,"OVERLAY")
        edge:SetPoint(side=="left" and "TOPLEFT" or "TOPRIGHT",row,side=="left" and "TOPLEFT" or "TOPRIGHT",0,0)
        edge:SetPoint(side=="left" and "BOTTOMLEFT" or "BOTTOMRIGHT",row,side=="left" and "BOTTOMLEFT" or "BOTTOMRIGHT",0,0)
        edge:SetWidth(2)
        edge:SetColorTexture(1,0.79,0.14,1)
        edge:Hide()
        row.targetEdge[#row.targetEdge+1]=edge
    end
    row.name, row.level, row.bar=name,level,bar
    row:Hide()
    return row
end
local function Build()
    if panel then return end
    panel=CreateFrame("Frame","SparkleButtCombatPanel",UIParent)
    panel:SetSize(WIDTH,MAX_ROWS*(HEIGHT+GAP))
    panel:SetFrameStrata("HIGH")
    panel:SetClampedToScreen(true)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart",function(self) self:StartMoving() end)
    panel:SetScript("OnDragStop",function(self)
        self:StopMovingOrSizing()
        StoreAnchor()
    end)
    SetAnchor()
    rows={}
    for i=1,MAX_ROWS do rows[i]=MakeRow(panel,i) end
    panel.title=panel:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    panel.title:SetPoint("TOPLEFT",panel,"TOPLEFT",5,1)
    panel.title:SetTextColor(1,0.65,0.65)
    panel.title:SetText("Panel positioning - drag to move")
    panel.title:Hide()
    panel.placeholder=panel:CreateTexture(nil,"BACKGROUND")
    panel.placeholder:SetPoint("TOPLEFT",panel,"TOPLEFT",0,16)
    panel.placeholder:SetSize(WIDTH,45)
    panel.placeholder:SetColorTexture(0.28,0.10,0.12,0.72)
    panel.placeholder:Hide()
    -- The panel is normally hidden; hidden frames do not run OnUpdate.
    -- Keep polling on the always-visible event watcher below instead.
    panel:Hide()
end
local function Eligible(unit)
    local exists=Plain(SafeCall(UnitExists,unit))
    if not exists then return false end
    local dead=Plain(SafeCall(UnitIsDeadOrGhost,unit))
    if dead then return false end
    local attack=Plain(SafeCall(UnitCanAttack,"player",unit))
    if not attack then return false end
    -- Only branch on non-secret booleans and non-secret threat values.
    local engaged=Plain(SafeCall(UnitAffectingCombat,unit))
    if not engaged and unit=="target" and Combat() then engaged=true end
    local targetsPlayer=Plain(SafeCall(UnitIsUnit,unit.."target","player"))
    if not engaged and targetsPlayer then engaged=true end
    if not engaged then
        local group=Plain(SafeCall(GetNumGroupMembers)) or 0
        for i=1,group do
            local party=Plain(SafeCall(UnitIsUnit,unit.."target","party"..i))
            local raid=Plain(SafeCall(UnitIsUnit,unit.."target","raid"..i))
            if party or raid then engaged=true; break end
        end
    end
    if not engaged then
        local threat=Plain(SafeCall(UnitThreatSituation,"player",unit))
        engaged=type(threat)=="number" and threat>=0
    end
    return engaged and true or false
end
-- UnitGUID and UnitIsUnit may be protected/secret on some maps.
-- Compare only values that the current client explicitly makes accessible.
-- Do not silently merge enemies on their shared display name.
local function SameUnit(a,b,guidA,guidB)
    if a==b then return true end -- addon-authored unit tokens are ordinary strings
    if guidA and guidB and guidA==guidB then return true end
    local same=Plain(SafeCall(UnitIsUnit,a,b))
    return same==true
end
-- Nameplates are the authoritative source of distinct enemies. Mixing them
-- with target/party-target unit tokens can multiply one creature whenever
-- UnitGUID and UnitIsUnit return secret values in combat.
-- When no visible nameplate qualifies, show only one conservative fallback:
-- our target, or the first eligible party/raid target. We intentionally
-- sacrifice completeness rather than invent multiple identities.
local function GetEntries()
    local collected,seenTokens,seenGUID={},{},{}
    local targetGUID=Plain(SafeCall(UnitGUID,"target"))
    local function add(unit)
        if type(unit)~="string" or seenTokens[unit] then return end
        seenTokens[unit]=true
        if not Eligible(unit) then return end
        local guid=Plain(SafeCall(UnitGUID,unit))
        if guid and seenGUID[guid] then return end
        for _,prior in ipairs(collected) do
            if SameUnit(unit,prior.unit,guid,prior.guid) then return end
        end
        local name=SafeCall(UnitName,unit)
        if not name then return end
        if not IsSecret(name) and name=="" then return end
        local isTarget=(unit=="target") or SameUnit(unit,"target",guid,targetGUID)
        collected[#collected+1]={unit=unit,guid=guid,isTarget=isTarget,
            name=name,level=SafeCall(UnitLevel,unit),
            hp=SafeCall(UnitHealth,unit),hpMax=SafeCall(UnitHealthMax,unit)}
        if guid then seenGUID[guid]=true end
    end
    if C_NamePlate and type(C_NamePlate.GetNamePlates)=="function" then
        local plates=SafeCall(C_NamePlate.GetNamePlates)
        if type(plates)=="table" then
            for _,plate in ipairs(plates) do
                add(plate.namePlateUnitToken or plate.unitToken)
            end
        end
    end
    if #collected==0 then
        add("target")
        if #collected==0 and Plain(SafeCall(IsInGroup)) then
            for i=1,4 do
                if #collected>0 then break end
                add("party"..i.."target")
            end
            if #collected==0 and Plain(SafeCall(IsInRaid)) then
                for i=1,40 do
                    if #collected>0 then break end
                    add("raid"..i.."target")
                end
            end
        end
    end
    return collected
end

function SparkleButtPanelRefresh()
    if not panel then return end
    local db=DB()
    local inCombat=Combat()
    local showRows=db.panelEnabled and inCombat
    local entries=showRows and GetEntries() or {}
    if testMode then
        -- Synthetic data to verify drawing independent of combat and nameplate APIs.
        entries={
            {name="TEST Highwayman",level=17,hp=73,hpMax=100,isTarget=true},
            {name="TEST Pathstalker",level=16,hp=45,hpMax=100},
            {name="TEST Knuckleduster",level=17,hp=100,hpMax=100},
        }
    end
    for i=1,MAX_ROWS do
        local row=rows[i]
        local data=entries[i]
        if data then
            row.name:SetText(data.name)
            local level=Plain(data.level)
            row.level:SetText(type(level)=="number" and level>0 and tostring(level) or "?")
            -- Pass secret values straight to allowed native widget setters.
            -- Never compare or calculate with raw UnitHealth values here.
            if data.hp and data.hpMax then
                row.bar:SetMinMaxValues(0,data.hpMax)
                row.bar:SetValue(data.hp)
                row.bar:SetAlpha(1)
            else
                row.bar:SetMinMaxValues(0,100)
                row.bar:SetValue(100)
                row.bar:SetAlpha(0.25)
            end
            for _,edge in ipairs(row.targetEdge) do edge:SetShown(data.isTarget==true) end
            row:Show()
        else
            for _,edge in ipairs(row.targetEdge) do edge:Hide() end
            row:Hide()
        end
    end
    panel.title:SetShown(positioning or testMode)
    panel.placeholder:SetShown(positioning and #entries==0 and not testMode)
    if testMode then
        panel.title:SetText("TEST ONLY - synthetic enemies - drag to move")
    elseif positioning then
        panel.title:SetText(db.panelEnabled and "Panel positioning - drag to move" or "Panel disabled - positioning preview")
    end
    if positioning or testMode or (showRows and #entries>0) then panel:Show() else panel:Hide() end
end
function SparkleButtPanelIsEnabled() return DB().panelEnabled end
function SparkleButtPanelDiagnostic(command)
    Build()
    command=(command or "status"):lower()
    if command=="test" then
        testMode=not testMode
        SparkleButtPanelRefresh()
        Say("TEST "..(testMode and "ON: 3 synthetic rows should appear and be draggable." or "OFF: normal display resumed."))
        return
    end
    local db=DB()
    local combat=Combat()
    local entries=GetEntries()
    local target=Plain(SafeCall(UnitName,"target")) or "[protected or unavailable]"
    local targetExists=SafeCall(UnitExists,"target") and "yes" or "no"
    Say("v0.6.57 status: enabled="..tostring(db.panelEnabled)..", combat="..tostring(combat)..", positioning="..tostring(positioning)..", test="..tostring(testMode))
    Say("target="..tostring(target).." (exists="..targetExists.."), eligible enemies="..tostring(#entries)..", panel visible="..tostring(panel:IsShown()))
    Say("panel anchor: x="..tostring(math.floor(db.panelX)).." y="..tostring(math.floor(db.panelY))..". Use /sb panel test for 3 fake rows.")
end
function SparkleButtPanelToggle()
    local db=DB()
    db.panelEnabled=not db.panelEnabled
    Say(db.panelEnabled and "ON - engaged enemies displayed during combat." or "OFF - combat bars disabled.")
    SparkleButtPanelRefresh()
    return db.panelEnabled
end
function SparkleButtPanelPositionToggle()
    Build()
    positioning=not positioning
    SparkleButtPanelRefresh()
    Say(positioning and "Positioning ON: drag the panel; /sb panel to finish." or "Positioning OFF: normal combat display restored.")
end
local events=CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
events:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
events:SetScript("OnEvent",function(_,event)
    if event=="PLAYER_LOGIN" then DB(); Build() end
    if panel then SparkleButtPanelRefresh() end
end)
-- Keep the watcher shown even when the combat display is hidden.
-- Otherwise it can never recover after the initial empty combat scan.
events:SetScript("OnUpdate",function(_,dt)
    elapsed=elapsed+dt
    if elapsed<0.17 then return end
    elapsed=0
    if panel and (DB().panelEnabled or positioning or testMode) then
        SparkleButtPanelRefresh()
    end
end)
