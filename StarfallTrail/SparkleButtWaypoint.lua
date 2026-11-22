-- SparkleButt custom destinations for Starfall Trail 1.2.0, experimental.
-- Loaded in Starfall Trail's namespace; uses the same world-coordinate library.
local _, ns = ...
local W = { selected = nil }
ns.SparkleWaypoint = W
_G.SparkleButtWaypoint = W

-- A map-visible confirmation toast. The world map covers chat on this client.
-- Draw above the fullscreen map, but don't intercept mouse clicks.
local toast, toastElapsed
local function ShowToast(message, errorMessage)
    if not toast then
        toast = CreateFrame('Frame', nil, UIParent)
        toast:SetSize(475, 52)
        toast:SetPoint('TOP', UIParent, 'TOP', 0, -105)
        toast:SetFrameStrata('TOOLTIP')
        toast:SetFrameLevel(100)
        toast:EnableMouse(false)
        local bg = toast:CreateTexture(nil, 'BACKGROUND')
        bg:SetAllPoints(toast)
        bg:SetColorTexture(0.015, 0.09, 0.055, 0.88)
        toast.bg = bg
        local text = toast:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
        text:SetPoint('CENTER', toast, 'CENTER', 0, 0)
        text:SetWidth(455)
        text:SetJustifyH('CENTER')
        toast.text = text
        toast:SetScript('OnUpdate', function(self, dt)
            toastElapsed = toastElapsed + dt
            if toastElapsed >= 3.2 then
                self:Hide()
            elseif toastElapsed > 2.5 then
                self:SetAlpha((3.2 - toastElapsed) / 0.7)
            end
        end)
    end
    toastElapsed = 0
    toast:SetAlpha(1)
    if errorMessage then
        toast.bg:SetColorTexture(0.22, 0.065, 0.045, 0.9)
        toast.text:SetText('|cffffb39aSparkleButt:|r '..message)
    else
        toast.bg:SetColorTexture(0.015, 0.09, 0.055, 0.88)
        toast.text:SetText('|cff78ff94SparkleButt:|r '..message)
    end
    toast:Show()
end

local function Notify(message, errorMessage)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage('|cff6cff70SparkleButt|r '..message) end
    ShowToast(message, errorMessage)
end

local function Nice(n) return string.format('%.1f', n * 100) end

function W.Set(uiMapId, x, y, label)
    uiMapId, x, y = tonumber(uiMapId), tonumber(x), tonumber(y)
    if not (uiMapId and x and y and x >= 0 and x <= 1 and y >= 0 and y <= 1) then
        return false, 'Invalid map ID or map coordinates (expected 0-100%).'
    end
    local hbd = ns.HBD
    if not (hbd and hbd.GetWorldCoordinatesFromZone) then
        return false, 'Map coordinates are not ready; try again after entering the world.'
    end
    local wx, wy, instance = hbd:GetWorldCoordinatesFromZone(x, y, uiMapId)
    if not (wx and wy and instance) then
        return false, 'That map location cannot be converted to world coordinates.'
    end
    local px, py, playerInstance = hbd:GetPlayerWorldPosition()
    if playerInstance and playerInstance ~= instance then
        return false, 'Destination is on another continent/instance; Starfall cannot route there directly.'
    end
    W.selected = {
        key = 'sparklebutt:custom', x = wx, y = wy, instance = instance,
        name = label or 'Custom waypoint', quest = 'SparkleButt waypoint',
        todo = label or 'Custom waypoint', waypoint = true,
        uiMapId = uiMapId, mapX = x, mapY = y
    }
    Notify(string.format('Waypoint set! Map %d: %s, %s. Follow Sparklebutt!', uiMapId, Nice(x), Nice(y)))
    return true
end
function W.Get() return W.selected end
function W.Clear(quiet)
    if not W.selected then
        if not quiet then Notify('No custom waypoint is active.') end
        return
    end
    W.selected = nil
    if not quiet then Notify('Custom waypoint cleared. Returning to quest navigation.') end
end
function W.Arrived()
    if W.selected then
        Notify('Destination reached! Returning to quest navigation.')
        W.Clear(true)
    end
end
function W.FromCursor()
    local map = WorldMapFrame
    if not (map and map.GetMapID and map.GetNormalizedCursorPosition) then
        return false, 'World map API unavailable.'
    end
    local mapId = map:GetMapID()
    local x, y = map:GetNormalizedCursorPosition()
    if not (mapId and x and y and x >= 0 and x <= 1 and y >= 0 and y <= 1) then
        return false, 'Click a point inside a zone map, then try again.'
    end
    return W.Set(mapId, x, y)
end

-- The canvas click handler is the supported path for a zoomed/panned modern map.
-- Alternate HookScript fallback supports clients without AddCanvasClickHandler.
local installed = false
local function OnMapClick(self, button)
    if button ~= 'LeftButton' or not (IsAltKeyDown and IsAltKeyDown()) then return false end
    local ok, err = W.FromCursor()
    if not ok then Notify(err, true) end
    return ok
end
local function TryInstallMapHandler()
    if installed or not WorldMapFrame then return end
    local map = WorldMapFrame
    if map.AddCanvasClickHandler then
        map:AddCanvasClickHandler(OnMapClick, 15)
        installed = true
    elseif map.ScrollContainer and map.ScrollContainer.HookScript then
        map.ScrollContainer:HookScript('OnMouseUp', function(_, button)
            OnMapClick(map, button)
        end)
        installed = true
    end
end
local watch = CreateFrame('Frame')
local elapsed = 0
watch:SetScript('OnUpdate', function(self, dt)
    elapsed = elapsed + dt
    if elapsed < 1 then return end
    elapsed = 0
    TryInstallMapHandler()
    if installed then self:SetScript('OnUpdate', nil) end
end)
TryInstallMapHandler()
