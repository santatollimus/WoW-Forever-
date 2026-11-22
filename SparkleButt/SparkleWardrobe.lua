-- SparkleButt wardrobe: experimental display IDs gathered from WoW reference data.
-- Actual rendering and animation in WoW Forever require in-game verification.
-- Color is a tint for SparkleButt's existing halo/sparkles, NOT a recolor of the 3D model.
local APPEARANCES = {
    {key="emerald", name="Emerald Whelp",  display=6291,  tint={0.12,1,0.22}},
    {key="crimson", name="Crimson Whelp",  display=6290,  tint={0.816,0.169,0.173}, glowTint={1.000,0.110,0.130}},
    {key="azure",   name="Azure Whelp",    display=6293,  tint={0.435,0.812,0.945}, glowTint={0.08,0.34,1.00}}, -- Saturated azure-blue aura; selector swatch unchanged
    {key="dark",    name="Dark Whelp",     display=6288,  tint={0.204,0.180,0.157}, glowTint={1.000,0.420,0.060}},
    {key="bronze",  name="Bronze Whelp",   display=6292,  tint={0.659,0.361,0.141}, glowTint={1.000,0.850,0.340}},
    {key="wisp",    name="Wisp",           display=10045, tint={0.761,0.973,1.000}}, -- Wisp first swatch
    {key="sprite",  name="Sprite Darter",  display=6294,  tint={0.941,0.525,0.604}}, -- Sprite middle swatch
}
local wardrobe
local previewModel, previewHalo, previewSparks, previewTitle, previewHint
local function PreviewAppearance(item)
    if not wardrobe or not previewModel or not item then return end
    previewTitle:SetText(item.name)
    previewHint:SetText("Front view | Full glow preview")
    if type(previewModel.SetDisplayInfo)=="function" then
        local ok=pcall(previewModel.SetDisplayInfo,previewModel,item.display)
        if ok then
            if type(previewModel.SetFacing)=="function" then pcall(previewModel.SetFacing,previewModel,0) end
            if type(previewModel.SetAnimation)=="function" then pcall(previewModel.SetAnimation,previewModel,0) end
            previewModel:Show()
        else
            previewModel:Hide()
            previewHint:SetText("Model preview unavailable")
        end
    else
        previewModel:Hide()
        previewHint:SetText("Model API unavailable")
    end
    local tint=item.glowTint or item.tint
    local visible=item.key~="wisp"
    previewHalo:SetVertexColor(tint[1],tint[2],tint[3])
    previewHalo:SetAlpha(visible and 0.85 or 0)
    for _,spark in ipairs(previewSparks) do
        spark:SetVertexColor(tint[1],tint[2],tint[3])
        spark:SetAlpha(visible and 0.72 or 0)
    end
end
-- The quick-cycle dot and /sb wardrobe share one ordered appearance list.
function SparkleButtWardrobeGetCurrent()
    local key=SparkleButtDB and SparkleButtDB.appearance or "emerald"
    for _,item in ipairs(APPEARANCES) do
        if item.key==key then return item.key, item.name, item.tint end
    end
    return APPEARANCES[1].key, APPEARANCES[1].name, APPEARANCES[1].tint
end
function SparkleButtWardrobeCycle()
    local key=SparkleButtDB and SparkleButtDB.appearance or "emerald"
    local current=1
    for i,item in ipairs(APPEARANCES) do
        if item.key==key then current=i; break end
    end
    local nextItem=APPEARANCES[current % #APPEARANCES + 1]
    SparkleButtWardrobeSelect(nextItem.key)
end
-- Restore the new glow on reload without changing the dot color or saved model.
function SparkleButtWardrobeSyncGlow()
    if not SparkleButtDB then return end
    for _,item in ipairs(APPEARANCES) do
        if item.key==SparkleButtDB.appearance then
            SparkleButtDB.appearanceTint={unpack(item.glowTint or item.tint)}
            return
        end
    end
end
local function Announce(line)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff6cff70SparkleButt|r "..line) end
end
local function RefreshButtons()
    if not wardrobe or not wardrobe.rows then return end
    local key=SparkleButtDB and SparkleButtDB.appearance or "emerald"
    local activeItem=APPEARANCES[1]
    for i,row in ipairs(wardrobe.rows) do
        if APPEARANCES[i].key==key then
            activeItem=APPEARANCES[i]
            row.text:SetText("|cffffe890> "..APPEARANCES[i].name.."|r")
        else
            row.text:SetText(APPEARANCES[i].name)
        end
    end
    PreviewAppearance(activeItem)
end
function SparkleButtWardrobeSelect(key)
    key=string.lower(key or "")
    if key=="darter" then key="sprite" end
    if key=="black" then key="dark" end
    local selected
    for _,item in ipairs(APPEARANCES) do
        if item.key==key then selected=item; break end
    end
    if not selected then
        Announce("Unknown appearance. Try /sb wardrobe or /sb look emerald|crimson|azure|dark|bronze|wisp|sprite")
        return
    end
    if not SparkleButtDB then
        Announce("Wardrobe not ready yet; try again after login.")
        return
    end
    -- Saved model is already honored by SparkleButt's existing SetModel routine.
    SparkleButtDB.displayID=selected.display
    SparkleButtDB.appearance=selected.key
    SparkleButtDB.appearanceTint={unpack(selected.glowTint or selected.tint)}
    SparkleButtDB.mode="3d"
    if type(SparkleButtRefreshModel)=="function" then SparkleButtRefreshModel() end
    local model=_G.SparkleButtWhelpModel
    if model and type(model.SetDisplayInfo)=="function" then
        local ok,err=pcall(model.SetDisplayInfo,model,selected.display)
        if not ok then
            Announce("Model "..selected.display.." could not load: "..tostring(err))
        else
            model:Show()
        end
    end
    RefreshButtons()
    if type(SparkleButtRefreshSelector)=="function" then SparkleButtRefreshSelector() end
    Announce(selected.name.." selected (display "..selected.display.."). Glow tint updated. Check that the model looks right.")
end
local function CreateWardrobe()
    if wardrobe then return end
    local f=CreateFrame("Frame","SparkleButtWardrobeFrame",UIParent)
    f:SetSize(555,334)
    f:SetPoint("CENTER",UIParent,"CENTER",0,0)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function(self) self:StartMoving() end)
    f:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
    local bg=f:CreateTexture(nil,"BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(0.05,0.09,0.13,0.96)
    local title=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    title:SetPoint("TOPLEFT",f,"TOPLEFT",16,-15)
    title:SetText("SparkleButt Wardrobe")
    local subtitle=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT",f,"TOPLEFT",16,-40)
    subtitle:SetText("Select a companion and see its glow")
    local close=CreateFrame("Button",nil,f,"UIPanelCloseButton")
    close:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,0)
    f.rows={}
    for i,item in ipairs(APPEARANCES) do
        local row=CreateFrame("Button",nil,f)
        row:SetSize(275,30)
        row:SetPoint("TOPLEFT",f,"TOPLEFT",16,-63-(i-1)*31)
        row:RegisterForClicks("LeftButtonUp")
        local bgRow=row:CreateTexture(nil,"BACKGROUND")
        bgRow:SetAllPoints()
        bgRow:SetTexture("Interface\\Buttons\\WHITE8X8")
        bgRow:SetVertexColor(0.12,0.18,0.23,0.7)
        local dot=row:CreateTexture(nil,"ARTWORK")
        dot:SetTexture("Interface\\AddOns\\SparkleButt\\Media\\mode_circle.tga")
        dot:SetSize(16,16)
        dot:SetPoint("LEFT",row,"LEFT",9,0)
        dot:SetVertexColor(unpack(item.tint))
        local text=row:CreateFontString(nil,"OVERLAY","GameFontHighlight")
        text:SetPoint("LEFT",row,"LEFT",35,0)
        text:SetJustifyH("LEFT")
        text:SetText(item.name)
        row.text=text
        row:SetScript("OnClick",function() SparkleButtWardrobeSelect(item.key) end)
        row:SetScript("OnEnter",function(self)
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            GameTooltip:SetText(item.name,1,1,1)
            GameTooltip:AddLine("Display ID "..item.display.."; glow color changes, model skin does not.",0.8,0.8,0.8,true)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave",function() GameTooltip:Hide() end)
        f.rows[i]=row
    end
    -- Standalone, live 3D front-view preview, independent of navigation.
    local pane=CreateFrame("Frame",nil,f)
    pane:SetSize(230,252)
    pane:SetPoint("TOPRIGHT",f,"TOPRIGHT",-14,-56)
    local paneBg=pane:CreateTexture(nil,"BACKGROUND")
    paneBg:SetAllPoints()
    paneBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    paneBg:SetVertexColor(0.015,0.035,0.065,0.95)
    local paneLabel=pane:CreateFontString(nil,"OVERLAY","GameFontNormal")
    paneLabel:SetPoint("TOP",pane,"TOP",0,-12)
    paneLabel:SetText("Companion Preview")
    previewTitle=pane:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    previewTitle:SetPoint("BOTTOM",pane,"BOTTOM",0,31)
    previewHint=pane:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    previewHint:SetPoint("BOTTOM",pane,"BOTTOM",0,12)
    previewHalo=pane:CreateTexture(nil,"ARTWORK")
    previewHalo:SetTexture("Interface\\AddOns\\SparkleButt\\Media\\glow.tga")
    previewHalo:SetBlendMode("ADD")
    previewHalo:SetSize(186,186)
    previewHalo:SetPoint("CENTER",pane,"CENTER",0,0)
    previewSparks={}
    for i=1,6 do
        local spark=pane:CreateTexture(nil,"ARTWORK")
        spark:SetTexture("Interface\\AddOns\\SparkleButt\\Media\\glow.tga")
        spark:SetBlendMode("ADD")
        spark:SetSize(14,14)
        local angle=(i-1)*math.pi/3
        spark:SetPoint("CENTER",pane,"CENTER",math.cos(angle)*46,math.sin(angle)*45)
        previewSparks[i]=spark
    end
    previewModel=CreateFrame("PlayerModel",nil,pane)
    previewModel:SetSize(215,210)
    previewModel:SetPoint("CENTER",pane,"CENTER",0,0)
    previewModel:EnableMouse(false)
    if type(previewModel.SetCamera)=="function" then pcall(previewModel.SetCamera,previewModel,0) end
    local note=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    note:SetPoint("BOTTOM",f,"BOTTOM",0,12)
    note:SetText("Selection saved | Preview glow may differ slightly in-world")
    wardrobe=f
    RefreshButtons()
end
function SparkleButtWardrobeOpen()
    CreateWardrobe()
    if wardrobe:IsShown() then wardrobe:Hide() else RefreshButtons(); wardrobe:Show() end
end
