-- SparkleRadar v0.3.4: player menus and full-name whispers; creature labels are plain text.
-- Formerly standalone SparkleRadar v0.1.1; no protected tooltip access.
local addon = CreateFrame("Frame")
local enabled = true
SparkleButtRadarIsEnabled = function() return enabled end
local lastGUID = nil
local lastIdentity = nil
local lastAt = 0
local elapsed = 0
local seen = {}
local announceWindow = 20 -- suppress same GUID within this many seconds
local lastObjectText = nil
local lastObjectAt = 0

local function clock()
  if type(GetTime) == "function" then return GetTime() end
  return 0
end
local function chat(message)
  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage("|cff52d875SparkleRadar|r: " .. message)
  end
end
local function colorize(message, hex)
  return "|cff" .. hex .. message .. "|r"
end
-- Native WoW player hyperlinks support the game chat interaction behavior:
-- left-click usually whispers, right-click usually opens the player menu.
-- WoW Forever may use multiword player names. Prefer the complete name
-- verified by the current unit tooltip when it extends UnitName().
local function playerChatLink(targetName, shownName, hex)
  if type(targetName) ~= "string" or targetName == "" then
    return colorize(shownName, hex)
  end
  -- Keep chat link control characters out of untrusted names/tooltip labels.
  local target = targetName:gsub("[|%[%]\r\n]", "")
  local label = shownName:gsub("[|\r\n]", "")
  if target == "" then return colorize(shownName, hex) end
  return "|cff" .. hex .. "|Hplayer:" .. target .. "|h[" .. label .. "]|h|r"
end
local classColors = {
  WARRIOR="C79C6E", PALADIN="F58CBA", HUNTER="ABD473", ROGUE="FFF569",
  PRIEST="FFFFFF", SHAMAN="0070DE", MAGE="69CCF0", WARLOCK="9482C9",
  DRUID="FF7D0A", DEATHKNIGHT="C41F3B"
}
local function reactionColor(unit)
  if type(UnitReaction) == "function" then
    local ok, value = pcall(UnitReaction, unit, "player")
    if ok and type(value) == "number" then
      if value <= 3 then return "FF4D4D" end
      if value == 4 then return "FFD35B" end
      return "69D875"
    end
  end
  if type(UnitCanAttack) == "function" then
    local ok, result = pcall(UnitCanAttack, "player", unit)
    if ok and result then return "FF4D4D" end
  end
  return "DFDFDF"
end
local function safe(f, ...)
  if type(f) ~= "function" then return nil end
  local ok, v = pcall(f, ...)
  if ok then return v end
  return nil
end
-- World-object tooltip scanning disabled: caused duplicate NPC reports and noisy chat.
-- SparkleRadar currently reports actual mouseover units only.

-- Prefer an explicitly displayed full unit name when the tooltip belongs to
-- the same GUID. Player realm names are provided as a fallback where supported.
-- Do not assume a surname exists when none is exposed by the client.
local function displayedUnitName(unit, baseName, guid, isPlayer)
  local full = baseName
  if isPlayer then
    if type(GetUnitName) == "function" then
      local value = safe(GetUnitName, unit, true)
      if type(value) == "string" and value ~= "" then full = value end
    end
    if full == baseName and type(UnitFullName) == "function" then
      local ok, playerName, realm = pcall(UnitFullName, unit)
      if ok and type(playerName) == "string" and playerName ~= "" then
        full = playerName
        if type(realm) == "string" and realm ~= "" then full = full .. "-" .. realm end
      end
    end
  end
  if not (GameTooltip and safe(GameTooltip.IsShown, GameTooltip)) then return full end
  if type(GameTooltip.GetUnit) ~= "function" then return full end
  local ok, _, tooltipUnit = pcall(GameTooltip.GetUnit, GameTooltip)
  if not ok or type(tooltipUnit) ~= "string" or tooltipUnit == "" then return full end
  local tooltipGUID = safe(UnitGUID, tooltipUnit)
  if not guid or tooltipGUID ~= guid then return full end
  local line = _G.GameTooltipTextLeft1
  local text = line and safe(line.GetText, line)
  if type(text) ~= "string" or text == "" or text == "<secret>" then return full end
  -- A visible unit tooltip is the source for its presentation name, including
  -- surnames supplied by the game or an active roleplay display addon.
  return text
end

-- Quest tooltip text can contain both incomplete and completed quest sections.
-- Treat progress as relevant only in a non-completed quest section.  For
-- example, [14] Patrolling Westfall (Complete) followed by 8/8 Gnoll Paw
-- must NOT mark another gnoll as a current quest target.
local function questTooltipEvidence(guid)
  if not (GameTooltip and safe(GameTooltip.IsShown, GameTooltip)) then return false, "tooltip-hidden" end
  if type(GameTooltip.GetUnit) ~= "function" then return false, "no-tooltip-unit-api" end
  local ok, _, tooltipUnit = pcall(GameTooltip.GetUnit, GameTooltip)
  if not ok or type(tooltipUnit) ~= "string" or tooltipUnit == "" then return false, "tooltip-not-unit" end
  if not guid or safe(UnitGUID, tooltipUnit) ~= guid then return false, "tooltip-other-unit" end
  local count = safe(GameTooltip.NumLines, GameTooltip) or 0
  local hasQuestSection, sectionComplete = false, false
  for i = 2, math.min(count, 18) do
    local region = _G["GameTooltipTextLeft" .. i]
    local value = region and safe(region.GetText, region)
    if type(value) == "string" and value ~= "" and value ~= "<secret>" then
      local plain = value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
      -- Quest headers are displayed as [14] Quest Name or similar.
      if plain:match("^%s*%[%d+%]") then
        hasQuestSection = true
        sectionComplete = plain:lower():find("complete", 1, true) ~= nil
      elseif hasQuestSection and not sectionComplete then
        local current, required, label = plain:match("^%s*(%d+)%s*/%s*(%d+)%s+(.+)")
        if current and required and label and tonumber(required) and tonumber(required) > 0
           and tonumber(current) and tonumber(current) < tonumber(required) then
          return true, "unfinished-objective-line-" .. i
        end
      end
    end
  end
  return false, "no-unfinished-quest-objective"
end

local function inspectUnit()
  if not enabled then return end
  if not safe(UnitExists, "mouseover") then
    lastGUID = nil
    lastIdentity = nil
    return
  end
  lastObjectText = nil
  local name = safe(UnitName, "mouseover")
  if type(name) ~= "string" or name == "" then return end
  local guid = safe(UnitGUID, "mouseover")
  local level = safe(UnitLevel, "mouseover")
  local className, classToken
  if type(UnitClass) == "function" then
    local ok, n, t = pcall(UnitClass, "mouseover")
    if ok then className, classToken = n, t end
  end
  local isPlayer = safe(UnitIsPlayer, "mouseover")
  local classification = safe(UnitClassification, "mouseover")
  local creatureType = safe(UnitCreatureType, "mouseover")
  local dead = safe(UnitIsDeadOrGhost, "mouseover")
  local shownName = displayedUnitName("mouseover", name, guid, isPlayer)
  local questRelevant = questTooltipEvidence(guid)
  local identity = guid or (name .. ":" .. tostring(level) .. ":" .. tostring(classification))
  if identity == lastIdentity then return end
  lastIdentity = identity
  lastGUID = guid
  local now = clock()
  if guid and seen[guid] and now-seen[guid] < announceWindow then return end
  if guid then seen[guid] = now end

  local isRare = classification == "rare" or classification == "rareelite"
  local isElite = classification == "elite" or classification == "rareelite" or classification == "worldboss"
  local hex = reactionColor("mouseover")
  if isPlayer and classToken then hex = classColors[classToken] or hex end
  local levelText = (type(level) == "number" and level > 0) and ("Lv " .. tostring(level)) or "Lv ?"
  local descriptor = (isPlayer and (className or "Player")) or (creatureType or "NPC")
  local kind = (isRare and "RARE" or (isElite and "ELITE" or nil))
  -- WoW Forever may display a character's full name (including spaces) in
  -- the unit tooltip while UnitName() returns only its first token. The
  -- shorter token cannot reliably address that character for whispers.
  -- When the tooltip extends the base name, preserve the full visible name
  -- in the native player hyperlink payload as well as the chat label.
  local linkName = name
  if isPlayer and type(shownName) == "string" and shownName ~= "" then
    local cleanShown = shownName:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    cleanShown = cleanShown:match("^%s*(.-)%s*$") or cleanShown
    if cleanShown == name or cleanShown:sub(1, #name + 1) == name .. " " then
      linkName = cleanShown
    end
  end
  local displayName = isPlayer and playerChatLink(linkName, shownName, hex) or colorize(shownName, hex)
  local output = (questRelevant and colorize("● ", "FFD100") or "") .. displayName .. " - " .. levelText .. " " .. descriptor
  if kind then
    local alertColor = isRare and "FFD166" or "FF9B46"
    local title = isRare and "RARE SPOTTED" or "ELITE"
    output = colorize("✨ " .. title .. " ", alertColor) .. output .. colorize(" 🐉", alertColor)
  end
  if dead then output = output .. " (dead)" end
  chat(output)
end
addon:RegisterEvent("ADDON_LOADED")
addon:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
addon:SetScript("OnEvent", function(self, event, arg1)
  if event == "ADDON_LOADED" and arg1 == "SparkleButt" then
    if type(SparkleButtDB) ~= "table" then SparkleButtDB = {} end
    if SparkleButtDB.radarEnabled == false then enabled = false end
    chat("integrated v0.3.4: player menus and full-name whispers active")
  elseif event == "UPDATE_MOUSEOVER_UNIT" then
    inspectUnit()
  end
end)
addon:SetScript("OnUpdate", function(self, dt)
  elapsed = elapsed + (dt or 0)
  if elapsed < 0.15 then return end
  elapsed = 0
  inspectUnit()
end)

local function RadarCommand(input)
  local cmd = string.lower((input or ""):match("^%s*(%S+)") or "status")
  if cmd == "on" then
    enabled = true
    if type(SparkleButtDB) ~= "table" then SparkleButtDB = {} end
    SparkleButtDB.radarEnabled = true
    chat("ON. Hover over players and creatures; no targeting required.")
    if type(SparkleButtRefreshSelector)=="function" then SparkleButtRefreshSelector() end
  elseif cmd == "off" then
    enabled = false
    if type(SparkleButtDB) ~= "table" then SparkleButtDB = {} end
    SparkleButtDB.radarEnabled = false
    chat("OFF")
    if type(SparkleButtRefreshSelector)=="function" then SparkleButtRefreshSelector() end
  elseif cmd == "questprobe" then
    local guid = safe(UnitGUID, "mouseover")
    local yes, why = questTooltipEvidence(guid)
    chat("QUEST probe: unit=" .. tostring(safe(UnitName, "mouseover")) .. " flag=" .. tostring(yes) .. " reason=" .. tostring(why))
    if GameTooltip and safe(GameTooltip.IsShown, GameTooltip) then
      local count = math.min(safe(GameTooltip.NumLines, GameTooltip) or 0, 12)
      for i=1,count do
        local line = _G["GameTooltipTextLeft" .. i]
        local value = line and safe(line.GetText, line)
        if type(value) == "string" and value ~= "" then
          chat("QUEST line " .. i .. ": " .. (value == "<secret>" and "<protected>" or value:sub(1, 100)))
        end
      end
    end
  elseif cmd == "probe" then
    local focus = safe(GetMouseFocus)
    local owner = GameTooltip and safe(GameTooltip.GetOwner, GameTooltip)
    local shown = GameTooltip and safe(GameTooltip.IsShown, GameTooltip)
    local first = _G.GameTooltipTextLeft1
    local name = first and safe(first.GetText, first)
    local function frameName(f)
      if not f then return "nil" end
      if f == WorldFrame then return "WorldFrame" end
      if f == UIParent then return "UIParent" end
      return tostring(safe(f.GetName, f) or "unnamed-frame")
    end
    chat("PROBE focus=" .. frameName(focus) .. " owner=" .. frameName(owner) .. " tooltip=" .. tostring(shown) .. " mouseover=" .. tostring(safe(UnitExists, "mouseover")))
    chat("PROBE text=" .. ((type(name) == "string" and name ~= "" and name ~= "<secret>") and name or "unavailable/protected"))
  elseif cmd == "reset" then
    seen = {}
    lastIdentity = nil
    lastObjectText = nil
    chat("Radar history cleared.")
  elseif cmd == "status" or cmd == "help" then
    chat((enabled and "ON" or "OFF") .. " - /sb radar on | off | reset | probe | questprobe; right-click a player name in chat for the native menu")
  else
    chat("Unknown command; use /sb radar help")
  end
end

SparkleButtRadarCommand = RadarCommand
-- Retain the standalone probe command as a convenience, but no separate addon folder.
SLASH_SPARKLERADAR1 = "/sr"
SlashCmdList.SPARKLERADAR = RadarCommand
