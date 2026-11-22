-- SparkleButt v0.6.12 Treasure highlight test: arrival glow for Pet/Auto and varied snack personality.
-- Reads the route through an opt-in bridge; never inspects arrow artwork.
local ADDON = ...
local MEDIA = "Interface\\AddOns\\SparkleButt\\Media\\"
local WHELP_DISPLAY = 6291
local PI2 = math.pi * 2
local floor, abs, min, max = math.floor, math.abs, math.min, math.max
local sin, cos, exp = math.sin, math.cos, math.exp
local defaults = { enabled=true, mode="3d", scale=1, displayID=WHELP_DISPLAY,
    compass=true, chase=true, ahead=12, lift=3, reverse=false, test=false, x=0, y=-110, burst=true, smooth=5, chaseSmooth=7, selectorX=-18, selectorY=-145, selectorVisible=true, faceTurns=true, faceFlip=false, faceEase=7, petSide="right", autoMode=false, textPosition="off" }
local db, holder, sprite, model, sparks, burstSparks, emeraldHalo, driver
local clock, ticker, bearingX, lastSide = 0, 0, 0, 1
local alignedFor, wasAligned, lastBurst, burstStarted = 0, false, -20, -20
local previewUntil = -1
local alignmentGlow=0
local chaseX, chaseY, chaseTargetX, chaseTargetY
local modelFacing=math.pi -- forward, away from the viewer
local lateralVelocity=0
local previousChaseX=nil
local lastStatus="no frame"
local autoAtDestination=false -- session state, never inferred from screen position
local autoRouteSeenFor=0 -- debounce reactivation after arrival
local flightTransition=nil -- purely visual, never used as arrival detection
local corpseRun=false -- temporary visual-only suspension; never changes saved navigation mode
local selector, modeButtons, distanceLabel, textButton
local UpdateTextUI
local snack=nil -- temporary, visual-only interaction; navigation mode is preserved
local snackHearts, snackTreat
-- Celebration state is based on confirmed Starfall arrival, never screen visibility.
-- Keep it while beside Santa Nicholas until a NEW navigable route appears.
local arrivalGlowHeld=false
local snackCount=0
local lastSnackClock=-1000
local snackLastLine={}
local Say
local snackLines={
    arrival={
        eager={"Snack time! Sparklebutt is coming over!", "Sparklebutt swoops in for a treat!", "Sparklebutt heard the snack call!", "Sparklebutt flutters over, eyes bright."},
        spoiled={"Sparklebutt arrives with professional snack expectations.", "Sparklebutt seems to know exactly who carries the treats.", "Sparklebutt circles back for just one more!"},
        stuffed={"Sparklebutt drifts over with a suspiciously full belly.", "Sparklebutt comes over... but he's taking his time.", "Sparklebutt returns for another snack. Really?"},
    },
    nibble={
        eager={"Sparklebutt nibbles happily. Hearts everywhere!", "Sparklebutt chirps and munches with delight!", "A happy little dragon enjoys his snack."},
        spoiled={"Sparklebutt seems very pleased with this arrangement.", "Sparklebutt acts like snacks are part of his contract.", "Sparklebutt crunches contentedly and waits for praise."},
        stuffed={"Sparklebutt pats his tiny belly. Still room for a crumb!", "Critical snack saturation! Sparklebutt munches anyway.", "Sparklebutt may be getting spoiled beyond repair."},
    },
    departure={
        eager={"Snack accepted! Back to adventuring!", "Sparklebutt flutters back to guiding duty.", "Sparklebutt zips away, thoroughly delighted."},
        spoiled={"Sparklebutt reluctantly returns to work.", "Sparklebutt flies off, already planning his next snack.", "Sparklebutt resumes guiding... probably."},
        stuffed={"Sparklebutt suggests we complete a quest between snacks.", "Sparklebutt returns to duty, slightly rounder in spirit.", "The quest awaits! Sparklebutt takes a very full-bellied bow."},
    }
}
local function SnackMood()
    if snackCount<=2 then return "eager" end
    if snackCount<=5 then return "spoiled" end
    return "stuffed"
end
local function SnackSay(phase,mood)
    local pool=snackLines[phase] and snackLines[phase][mood]
    if not pool or #pool==0 then return end
    local pick=math.random(1,#pool)
    if #pool>1 and snackLastLine[phase]==pick then pick=pick%#pool+1 end
    snackLastLine[phase]=pick
    Say(pool[pick])
end
local UpdateModeUI

Say=function(msg)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff6cff70SparkleButt|r "..msg) end
end
-- The client does not expose exact enemy distance on every map/client.
-- Read exact yards only when the API validates them; otherwise report a
-- bounded spell/interact range rather than pretending we have a precise value.
local function SafeRange(func, ...)
    if type(func)~="function" then return nil end
    local ok,val=pcall(func,...)
    if not ok or val==nil then return nil end
    if type(val)=="boolean" then return val end
    if type(val)=="number" then return val~=0 end
    return nil
end
-- A range band is NOT an exact measurement. Only the validated distance
-- API may produce an integer; spell tests produce labelled limits.
local function SampleTargetRange()
    if not UnitExists or not UnitExists("target") or
       (UnitIsDeadOrGhost and UnitIsDeadOrGhost("player")) or
       not UnitCanAttack or not UnitCanAttack("player","target") then
        return "",1,1,1,"no hostile target"
    end
    if type(UnitDistanceSquared)=="function" then
        local ok,squared,valid=pcall(UnitDistanceSquared,"target")
        if ok and valid==true and type(squared)=="number" and squared>=0 then
            local yards=math.sqrt(squared)
            local r,g,b=1,0.30,0.30
            -- Only used on verified, numeric distances; NOT claimed spell caps.
            if yards<10 then r,g,b=.63,1,.64
            elseif yards<20 then r,g,b=.22,.78,.35
            elseif yards<30 then r,g,b=1,.84,.22
            elseif yards<40 then r,g,b=1,.52,.17 end
            return string.format("%d yd",floor(yards+.5)),r,g,b,"exact API"
        end
    end
    local function SpellRange(name)
        if C_Spell and type(C_Spell.IsSpellInRange)=="function" then
            local v=SafeRange(C_Spell.IsSpellInRange,name,"target")
            if v~=nil then return v end
        end
        return SafeRange(IsSpellInRange,name,"target")
    end
    local interact=SafeRange(CheckInteractDistance,"target",3)
    if interact==true then return "10 yd",.63,1,.64,"interact <=10" end
    local blast=SpellRange("Fire Blast")
    if blast==true then return "20 yd",.22,.78,.35,"Fire Blast in" end
    local frost=SpellRange("Frostbolt")
    if frost==true then return "30 yd",1,.84,.22,"Frostbolt in" end
    if frost==false then return "> 30 yd",1,.30,.30,"Frostbolt out" end
    return "? yd",.7,.7,.7,"range unavailable"
end
local function TargetDistanceText()
    local value=SampleTargetRange()
    return value
end
-- A single on-demand diagnostic; no inaccessible or secret values are coerced.
local lastBand=nil
local collecting=false
local collected=0
local nextSampleAt=0
local function LogBand(force)
    local value,r,g,b,source=SampleTargetRange()
    if value=="" then
        if force then Say("range: no hostile target") end
        lastBand=nil
        return
    end
    local key=value.." / "..source
    if force or key~=lastBand then
        Say("range "..value.." ["..source.."]"..(collecting and " sample="..collected or ""))
        lastBand=key
    end
end
local function DebugDistance()
    local function describe(v)
        if v==nil then return "nil" end
        if type(v)=="number" or type(v)=="boolean" or type(v)=="string" then return tostring(v) end
        return "("..type(v)..")"
    end
    local function probe(label,fn,...)
        if type(fn)~="function" then Say(label.." unavailable"); return end
        local ok,a,b,c=pcall(fn,...)
        if not ok then Say(label.." error/protected"); return end
        Say(label.." = "..describe(a)..", "..describe(b)..", "..describe(c))
    end
    Say("text="..tostring(db and db.textPosition).." target="..tostring(UnitExists and UnitExists("target")))
    if not (UnitExists and UnitExists("target")) then return end
    Say("detected range label: "..TargetDistanceText())
    probe("UnitDistanceSquared", UnitDistanceSquared,"target")
    probe("UnitPosition target", UnitPosition,"target")
    probe("UnitPosition player", UnitPosition,"player")
    probe("UnitDistance", UnitDistance,"target")
    probe("CheckInteractDistance(3)", CheckInteractDistance,"target",3)
    if C_Spell and type(C_Spell.IsSpellInRange)=="function" then
        probe("C_Spell Frostbolt", C_Spell.IsSpellInRange,"Frostbolt","target")
    end
    probe("IsSpellInRange Frostbolt", IsSpellInRange,"Frostbolt","target")
end
local function RefreshDistanceLabel()
    if not distanceLabel or not db then return end
    if not db.enabled or db.textPosition=="off" then
        distanceLabel:Hide(); return
    end
    -- Target range belongs to the nearby companion, not to the navigation
    -- guide. Do not show the label in Chase or while in-flight to Pet.
    -- A corpse run also suspends navigation, but is not a range-display state.
    if (db.chase or db.compass) or flightTransition or corpseRun then
        distanceLabel:Hide(); return
    end
    local value,r,g,b=SampleTargetRange()
    if value=="" then distanceLabel:Hide(); return end
    distanceLabel:SetText(value)
    distanceLabel:SetTextColor(r,g,b,1)
    distanceLabel:Show()
end
local function SetTextPosition(pos)
    if not db or not holder then return end
    db.textPosition=pos
    if distanceLabel then
        distanceLabel:ClearAllPoints()
        if pos=="above" then
            distanceLabel:SetPoint("BOTTOM",holder,"TOP",0,0)
        else
            distanceLabel:SetPoint("TOP",holder,"BOTTOM",0,0)
        end
    end
    RefreshDistanceLabel()
    if UpdateTextUI then UpdateTextUI() end
end
local function CycleTextPosition()
    if db.textPosition=="above" then SetTextPosition("below")
    elseif db.textPosition=="below" then SetTextPosition("off")
    else SetTextPosition("above") end
    Say("Target text "..db.textPosition.." (/sb text cycles above/below/off)")
end

local function InitDB()
    SparkleButtDB = SparkleButtDB or {}
    db = SparkleButtDB
    for k,v in pairs(defaults) do if db[k]==nil then db[k]=v end end
    if not db.range067Initialized then db.textPosition="above"; db.range067Initialized=true end
    -- One-time migration: retired Compass mode becomes Chase.
    -- Preserve Pet, Off, the selected Pet side and all custom settings.
    if not db.threeModeRelease then
        if db.compass and not db.chase then db.chase=true end
        db.threeModeRelease=true
    end
    -- Auto is opt-in. Existing saved Chase/Pet/Off selections are unchanged.
end
-- Bridge is loaded in Starfall Trail's own namespace, with its private route API.
-- The bridge returns nil when there is no active ground route or the player arrived.
local function ReadStarfall()
    local bridge = StarfallTrailSparkleButtBridge
    if not bridge or type(bridge.Read) ~= "function" then
        return nil,"bridge missing"
    end
    local ok, angle, status = pcall(bridge.Read)
    if not ok then return nil,"bridge error: "..tostring(angle) end
    return angle,status or "no route"
end

local function ReadProjected()
    local bridge=StarfallTrailSparkleButtBridge
    if not bridge or type(bridge.ReadProjected)~="function" then
        return nil,nil,nil,"projection bridge missing"
    end
    local ok,x,y,depth,status=pcall(bridge.ReadProjected,db.ahead,db.lift)
    if not ok then return nil,nil,nil,"projection error: "..tostring(x) end
    return x,y,depth,status
end

local function SetModel()
    if not holder then return end
    if db.mode=="3d" and model.SetDisplayInfo then
        sprite:Hide()
        model:Show()
        model:SetDisplayInfo(db.displayID)
        if model.SetFacing then model:SetFacing(modelFacing) end
    else
        if db.mode=="3d" then db.mode="2d"; Say("3D model API unavailable; using 2D.") end
        model:Hide(); sprite:Show()
    end
end
local function Move(x)
    if not holder then return end
    holder:ClearAllPoints()
    if db.compass then holder:SetPoint("TOP",UIParent,"TOP",x,db.y)
    else holder:SetPoint("CENTER",UIParent,"CENTER",db.petSide=="left" and -180 or 180,-90) end
    holder:SetScale(db.scale)
end

-- Projected point uses UIParent bottom-left coordinates, rather than screen-top compass offset.
local function MoveProjected(x,y)
    holder:ClearAllPoints()
    holder:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x,y)
    holder:SetScale(db.scale)
end

-- Flights interpolate real screen-space coordinates for Auto AND manual
-- role switches. They do not change Starfall route or arrival detection.
local function StartAutoFlight(kind, targetX, targetY)
    if not holder then return end
    local x,y=holder:GetCenter()
    if not x or not y then
        x=UIParent:GetWidth()/2
        y=UIParent:GetHeight()/2
    end
    -- A dragon behind the camera can be far outside the screen. Start his
    -- return flight at the nearest viewport edge rather than teleporting.
    x=max(-120,min(UIParent:GetWidth()+120,x))
    y=max(-120,min(UIParent:GetHeight()+120,y))
    flightTransition={kind=kind,x0=x,y0=y,x1=targetX,y1=targetY,elapsed=0,
                      duration=kind=="pet" and 0.90 or 1.10}
    holder:SetAlpha(1)
    holder:Show()
    MoveProjected(x,y)
end

local function PetScreenPosition()
    return UIParent:GetWidth()/2+(db.petSide=="left" and -180 or 180),
           UIParent:GetHeight()/2-90
end

-- Optional treat interaction: approach the player, face the camera, nibble,
-- release hearts and return to whichever mode was active. Never alters route.
local function StartSnack()
    if not db or not db.enabled then Say("Turn SparkleButt on before offering a snack."); return end
    if snack then Say("Sparklebutt is already enjoying his snack!"); return end
    if not holder then return end
    local x,y=holder:GetCenter()
    if not x or not y then x,y=PetScreenPosition() end
    local tx=UIParent:GetWidth()/2 + (db.petSide=="left" and -112 or 112)
    local ty=UIParent:GetHeight()/2-83
    -- A missing/offscreen projection should not force a long flight across the HUD.
    x=max(-80,min(UIParent:GetWidth()+80,x))
    y=max(-80,min(UIParent:GetHeight()+80,y))
    -- Reset feeding streak after ten minutes without snacks.
    if clock-lastSnackClock>600 then snackCount=0 end
    snackCount=snackCount+1
    lastSnackClock=clock
    local mood=SnackMood()
    snack={phase="approach",elapsed=0,x0=x,y0=y,tx=tx,ty=ty,
           fromX=x,fromY=y,animationAttempted=false,animationPlayed=false,
           mood=mood}
    flightTransition=nil
    holder:SetAlpha(1)
    holder:Show()
    if snackHearts then for _,t in ipairs(snackHearts) do t:SetAlpha(0) end end
    if snackTreat then snackTreat:SetAlpha(0) end
    SnackSay("arrival",mood)
end
local function UpdateSnack(dt)
    local a=snack
    if not a or not holder then return false end
    a.elapsed=a.elapsed+dt
    local x,y=a.tx,a.ty
    if a.phase=="approach" then
        local p=min(1,a.elapsed/0.90)
        local e=p*p*(3-2*p)
        x=a.x0+(a.tx-a.x0)*e
        y=a.y0+(a.ty-a.y0)*e+19*sin(p*math.pi)
        if p>=1 then a.phase="eat"; a.elapsed=0; SnackSay("nibble",a.mood) end
    elseif a.phase=="eat" then
        -- Gentle nibble/bounce even when this whelp lacks an eat sequence.
        y=y+3*sin(a.elapsed*13)
        if not a.animationAttempted then
            a.animationAttempted=true
            if model and model.SetAnimation then
                local can=false
                if model.HasAnimation then
                    local ok,v=pcall(model.HasAnimation,model,61)
                    can=ok and v
                end
                if can then
                    a.animationPlayed=pcall(model.SetAnimation,model,61)
                end
            end
        end
        if a.elapsed>=2.55 then
            a.phase="return"; a.elapsed=0
            SnackSay("departure",a.mood)
            if a.animationPlayed and model and model.SetAnimation then
                -- Restore default idle; native idle may vary with the model.
                pcall(model.SetAnimation,model,0)
            end
        end
    elseif a.phase=="return" then
        local gx,gy
        if db.compass and db.chase then
            gx,gy=ReadProjected()
        end
        if not gx or not gy then gx,gy=PetScreenPosition() end
        local p=min(1,a.elapsed/0.90)
        local e=p*p*(3-2*p)
        x=a.tx+(gx-a.tx)*e
        y=a.ty+(gy-a.ty)*e+15*sin(p*math.pi)
        if p>=1 then
            snack=nil
            if db.chase and gx and gy then
                chaseX,chaseY=gx,gy
                chaseTargetX,chaseTargetY=gx,gy
                MoveProjected(gx,gy)
            else
                Move(0)
            end
            if snackHearts then for _,t in ipairs(snackHearts) do t:SetAlpha(0) end end
            if snackTreat then snackTreat:SetAlpha(0) end
            return false
        end
    end
    holder:Show()
    holder:SetAlpha(1)
    MoveProjected(x,y)
    local desired=0 -- face the player for the treat
    if a.phase=="approach" then
        local k=min(1,a.elapsed/0.90)
        desired=math.pi*(1-k)
    elseif a.phase=="return" then
        desired=math.pi*min(1,a.elapsed/0.90)
    end
    local diff=(desired-modelFacing+math.pi)%(PI2)-math.pi
    modelFacing=modelFacing+diff*(1-exp(-10*dt))
    if model and model.SetFacing then model:SetFacing(modelFacing) end
    if snackTreat then
        if a.phase=="eat" then
            snackTreat:SetAlpha(0.78)
            snackTreat:ClearAllPoints()
            snackTreat:SetPoint("CENTER",holder,"CENTER",0,-15+2*sin(a.elapsed*12))
        else snackTreat:SetAlpha(0) end
    end
    if snackHearts then
        for i,t in ipairs(snackHearts) do
            local phase=a.elapsed-((i-1)*0.31)
            if a.phase=="eat" and phase>=0 and phase<1.1 then
                local q=phase/1.1
                t:SetAlpha(0.90*(1-q))
                t:SetSize(11+9*q,11+9*q)
                t:ClearAllPoints()
                t:SetPoint("CENTER",holder,"CENTER",(i-3)*15+7*sin(q*4+i),17+52*q)
            else t:SetAlpha(0) end
        end
    end
    return true
end

local function Build()
    if holder then return end
    holder=CreateFrame("Frame","SparkleButtCompanion",UIParent)
    holder:SetSize(128,128)
    holder:SetFrameStrata("HIGH")
    holder:EnableMouse(false)
    sprite=holder:CreateTexture(nil,"ARTWORK")
    sprite:SetTexture(MEDIA.."dragon.tga")
    sprite:SetSize(112,112)
    sprite:SetPoint("CENTER")
    model=CreateFrame("PlayerModel","SparkleButtWhelpModel",holder)
    model:SetSize(160,160)
    model:SetPoint("CENTER")
    model:EnableMouse(false)
    sparks={}
    for i=1,5 do
        local t=holder:CreateTexture(nil,"OVERLAY")
        t:SetTexture(MEDIA.."glow.tga")
        t:SetBlendMode("ADD")
        t:SetSize(12,12)
        sparks[i]=t
    end
    burstSparks={}
    for i=1,10 do
        local t=holder:CreateTexture(nil,"OVERLAY")
        t:SetTexture(MEDIA.."glow.tga")
        t:SetBlendMode("ADD")
        t:SetSize(10,10)
        t:SetAlpha(0)
        burstSparks[i]=t
    end
    -- A diffuse emerald aura behind the whelp. No text or UI prompt.
    emeraldHalo=holder:CreateTexture(nil,"BACKGROUND")
    emeraldHalo:SetTexture(MEDIA.."glow.tga")
    emeraldHalo:SetBlendMode("ADD")
    emeraldHalo:SetVertexColor(0.12,1,0.22)
    emeraldHalo:SetPoint("CENTER",holder,"CENTER",0,5)
    emeraldHalo:SetSize(145,145)
    emeraldHalo:SetAlpha(0)
    snackHearts={}
    for i=1,5 do
        local h=holder:CreateTexture(nil,"OVERLAY")
        h:SetTexture(MEDIA.."heart.tga")
        h:SetBlendMode("BLEND")
        h:SetSize(15,15)
        h:SetPoint("CENTER",holder,"CENTER",0,20)
        h:SetAlpha(0)
        snackHearts[i]=h
    end
    snackTreat=holder:CreateTexture(nil,"OVERLAY")
    snackTreat:SetTexture(MEDIA.."glow.tga")
    snackTreat:SetBlendMode("ADD")
    snackTreat:SetVertexColor(1,0.70,0.20)
    snackTreat:SetSize(12,12)
    snackTreat:SetPoint("CENTER")
    snackTreat:SetAlpha(0)
    distanceLabel=holder:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    distanceLabel:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",15,"OUTLINE")
    distanceLabel:SetTextColor(1,0.94,0.38,1)
    distanceLabel:SetShadowOffset(1,-1)
    distanceLabel:SetShadowColor(0,0,0,0.9)
    distanceLabel:SetSize(140,24)
    distanceLabel:Hide()
    SetTextPosition(db.textPosition)
    SetModel()
    Move(0)
    -- Independent always-visible updater: hiding the dragon must not stop polling for new quests.
    driver=CreateFrame("Frame",nil,UIParent)
    driver:SetScript("OnUpdate",function(_,dt)
        local self=holder
        dt=min(dt,0.1)
        clock=clock+dt
        if collecting and clock>=nextSampleAt then
            nextSampleAt=clock+0.5
            collected=collected+1
            LogBand(false)
        end
        -- Label update independent of the animation/early returns below.
        if clock >= (self.nextTextTick or 0) then
            self.nextTextTick=clock+0.12
            RefreshDistanceLabel()
        end
        -- A corpse run is not a navigation route. Suspend every chase/auto
        -- update until resurrection, but preserve the selected navigation mode.
        -- Only enter/leave this state on actual player life-state transitions.
        local dead=UnitIsDeadOrGhost and UnitIsDeadOrGhost("player")
        if dead and not corpseRun then
            corpseRun=true
            snack=nil
            flightTransition=nil
            chaseTargetX=nil; chaseTargetY=nil; chaseX=nil; chaseY=nil
            autoRouteSeenFor=0
            alignmentGlow=0
            if db and db.enabled then
                local px,py=PetScreenPosition()
                StartAutoFlight("pet",px,py)
            end
        elseif not dead and corpseRun then
            corpseRun=false
            flightTransition=nil
            chaseTargetX=nil; chaseTargetY=nil; chaseX=nil; chaseY=nil
            autoRouteSeenFor=0
            arrivalGlowHeld=false
            if db and db.enabled then
                if db.autoMode then
                    local angle,status=ReadStarfall()
                    autoAtDestination=(status=="arrived" or not angle)
                    db.chase=not autoAtDestination
                    db.compass=db.chase
                end
                if db.chase and db.compass then
                    local x,y=ReadProjected()
                    if x and y then StartAutoFlight("chase",x,y) end
                else
                    local x,y=PetScreenPosition()
                    StartAutoFlight("pet",x,y)
                end
            end
        end
        -- Snack takes temporary priority over chase, auto transitions and
        -- model turning. No route data or saved mode is modified.
        if snack then
            if UpdateSnack(dt) then return end
        end
        -- Animate Auto mode changes every render frame. This overlays the usual
        -- chase smoothing only for the brief flight between roles.
        if flightTransition then
            local t=flightTransition
            t.elapsed=min(t.duration,t.elapsed+dt)
            local p=t.elapsed/t.duration
            local eased=p*p*(3-2*p)
            MoveProjected(t.x0+(t.x1-t.x0)*eased,t.y0+(t.y1-t.y0)*eased)
            if t.elapsed>=t.duration then
                flightTransition=nil
                if t.kind=="pet" then
                    Move(0) -- identical destination, restores Pet anchoring
                else
                    chaseX,chaseY=t.x1,t.y1
                    chaseTargetX,chaseTargetY=t.x1,t.y1
                end
            end
        end
        -- While dead, only finish the one-time return to Pet. Ignore changing
        -- world routes, projections, arrival notices, and quest retargeting.
        if corpseRun then
            if not flightTransition and holder and db and db.enabled then
                holder:Show()
            end
            return
        end
        -- Interpolate the 20Hz route samples at the actual render frame rate.
        -- The exponential response is frame-rate independent and removes hard
        -- SetPoint jumps caused by Starfall route point / camera quantization.
        if db and db.enabled and db.chase and not db.test and chaseTargetX and not flightTransition then
            local oldX=chaseX
            local k=1-exp(-db.chaseSmooth*dt)
            chaseX=chaseX+(chaseTargetX-chaseX)*k
            chaseY=chaseY+(chaseTargetY-chaseY)*k
            MoveProjected(chaseX,chaseY)
            -- Screen-space motion indicates a pan/turn. Filter it to avoid
            -- twitching from Starfall's small projection quantization steps.
            if oldX and dt>0.0001 then
                local dxPerSecond=max(-900,min(900,(chaseX-oldX)/dt))
                lateralVelocity=lateralVelocity+(dxPerSecond-lateralVelocity)*(1-exp(-5*dt))
            end
        else
            lateralVelocity=lateralVelocity*(1-exp(-7*dt))
        end
        -- Rotate the actual native 3D whelp; no texture swapping.
        -- Compass shares Chase's ability to fly offscreen. Its only constraint
        -- is a fixed Y position at the top of the HUD. Never dim Chase/Pet.
        if holder and db and db.enabled and db.compass and not db.chase and not db.test then
            -- Bearing visibility wins over smoothing: NEVER show a compass
            -- dragon when the quest lies behind or outside the forward view.
            -- Position smoothing can still complete offscreen unnoticed.
            local angle=ReadStarfall()
            if not angle then
                holder:SetAlpha(0)
            else
                if db.reverse then angle=-angle end
                local deviation=abs(angle)
                if cos(angle)<=0 or deviation>=1.45 then
                    holder:SetAlpha(0)
                else
                    -- Feather the last ~15 degrees before the view edge.
                    holder:SetAlpha(max(0,min(1,(1.45-deviation)/0.26)))
                end
            end
        elseif holder then
            holder:SetAlpha(1)
        end
        -- Forward = facing away; lateral motion turns him to face his flight.
        -- No route/waypoint logic is altered by this visual-only feature.
        if model and model.SetFacing and db then
            local desired=math.pi
            if db.faceTurns and db.chase and db.enabled and not db.test then
                local magnitude=abs(lateralVelocity)
                local weight=max(0,min(1,(magnitude-20)/90))
                if weight>0 then
                    local direction=lateralVelocity>0 and -1 or 1
                    if db.faceFlip then direction=-direction end
                    desired=math.pi+direction*(math.pi/2)*weight
                end
            elseif not db.faceTurns then
                desired=0 -- restore original camera-facing orientation
            end
            local diff=(desired-modelFacing+math.pi)%(PI2)-math.pi
            modelFacing=modelFacing+diff*(1-exp(-db.faceEase*dt))
            model:SetFacing(modelFacing)
        end
        local bob=5*sin(clock*2.2)
        sprite:ClearAllPoints(); sprite:SetPoint("CENTER",self,"CENTER",0,bob)
        model:ClearAllPoints(); model:SetPoint("CENTER",self,"CENTER",0,bob)
        for i,t in ipairs(sparks) do
            local p=(clock*0.4+i/#sparks)%1
            t:ClearAllPoints()
            t:SetPoint("CENTER",self,"CENTER",-34-50*p,-10-18*p+6*sin(clock*3+i*1.7))
            t:SetAlpha((1-p)*0.75)
            local s=5+10*(1-p); t:SetSize(s,s)
        end
        -- The green grows stronger as you align to the route, fading gently
        -- when you turn away. This is decorative only: Starfall owns navigation.
        local shown=holder:IsShown() and db.enabled and (db.compass or not db.chase)
        local strength=shown and alignmentGlow or 0
        if emeraldHalo then
            emeraldHalo:SetAlpha(db.burst and strength*0.72 or 0)
            local sz=132+18*strength+7*sin(clock*3)
            emeraldHalo:SetSize(sz,sz)
        end
        for i,t in ipairs(sparks) do
            t:SetVertexColor(0.4+0.18*strength,0.9+0.1*strength,0.42+0.1*strength)
            if db.burst then
                local p=(clock*0.4+i/#sparks)%1
                t:SetAlpha((1-p)*(0.25+0.75*strength))
            end
        end
        local age=clock-burstStarted
        for i,t in ipairs(burstSparks) do
            if age>=0 and age<0.85 and db.burst and holder:IsShown() then
                local spread=age/0.85
                local a=(i-1)*(PI2/#burstSparks)
                local radius=14+56*spread
                t:ClearAllPoints()
                t:SetPoint("CENTER",self,"CENTER",radius*cos(a),radius*sin(a)+5)
                t:SetVertexColor(0.35,1,0.35)
                t:SetAlpha((1-spread)*0.75)
                t:SetSize(4+10*(1-spread),4+10*(1-spread))
            else
                t:SetAlpha(0)
            end
        end
        ticker=ticker+dt
        if ticker<0.05 then return end
        local step=ticker; ticker=0
        if UpdateModeUI then UpdateModeUI() end
        if not db.enabled then self:Hide(); chaseTargetX=nil; chaseTargetY=nil; chaseX=nil; chaseY=nil; alignmentGlow=0; wasAligned=false; alignedFor=0; return end
        -- Auto state machine is driven ONLY by Starfall's arrival and route state.
        -- Offscreen dragon, missing projection, and camera rotation are NOT arrivals.
        if db.autoMode and not db.test then
            local liveAngle, liveStatus=ReadStarfall()
            if not autoAtDestination and liveStatus=="arrived" then
                arrivalGlowHeld=true
                autoAtDestination=true
                autoRouteSeenFor=0
                db.chase=false; db.compass=false
                chaseTargetX=nil; chaseTargetY=nil; chaseX=nil; chaseY=nil
                local tx,ty=PetScreenPosition()
                StartAutoFlight("pet",tx,ty)
            elseif autoAtDestination then
                -- Wait for a stable, actual route before returning to Chase.
                -- Brief route gaps and camera loss leave the whelp in Pet.
                if liveAngle and liveStatus=="tracking trail" then
                    autoRouteSeenFor=autoRouteSeenFor+step
                    if autoRouteSeenFor>=0.8 then
                        -- Wait until the projected route point really exists.
                        -- This prevents a visible snap or blink into Chase.
                        local px,py=ReadProjected()
                        if px and py then
                            autoAtDestination=false
                            arrivalGlowHeld=false
                            autoRouteSeenFor=0
                            db.chase=true; db.compass=true
                            chaseTargetX=nil; chaseTargetY=nil; chaseX=nil; chaseY=nil
                            StartAutoFlight("chase",px,py)
                        end
                    end
                else
                    autoRouteSeenFor=0
                end
            end
        end
        if not db.compass then
            -- Pet stays alongside the character but listens to the same
            -- direction signal as Chase for its green alignment glow.
            self:Show()
            chaseTargetX=nil; chaseTargetY=nil; chaseX=nil; chaseY=nil
            local petAngle,petStatus=ReadStarfall()
            lastStatus=petStatus
            if petStatus=="arrived" then
                if not arrivalGlowHeld then
                    burstStarted=clock
                    lastBurst=clock
                end
                arrivalGlowHeld=true
            elseif petAngle and petStatus=="tracking trail" and not autoAtDestination then
                -- An actual new route ends the arrival celebration.
                arrivalGlowHeld=false
            end
            local targetGlow=0
            local aligned=false
            if petAngle then
                if db.reverse then petAngle=-petAngle end
                local deviation=abs(petAngle)
                if cos(petAngle)>0 and deviation<0.80 then
                    targetGlow=max(0,min(1,(0.80-deviation)/0.69))
                    targetGlow=targetGlow*targetGlow*(3-2*targetGlow)
                end
                aligned=cos(petAngle)>0 and deviation<0.10
            end
            -- Arrival means mission accomplished even if we turn to face away.
            -- Pet keeps its original directional glow when still navigating.
            if arrivalGlowHeld then targetGlow=1 end
            alignmentGlow=alignmentGlow+(targetGlow-alignmentGlow)*(1-exp(-4*step))
            if aligned then alignedFor=alignedFor+step else alignedFor=0 end
            if aligned and not wasAligned and alignedFor>=0.20 and clock-lastBurst>4 then
                lastBurst=clock; burstStarted=clock; wasAligned=true
            elseif not aligned then
                wasAligned=false
            end
            return
        end
        local angle,status
        if db.test then
            angle=sin(clock*0.7)*2.9; status="test"
        else
            angle,status=ReadStarfall()
        end
        lastStatus=status
        if angle and status=="tracking trail" and not autoAtDestination then
            arrivalGlowHeld=false
        end
        if not angle then
            if flightTransition and flightTransition.kind=="chase" then return end
            if clock<previewUntil then self:Show() else self:Hide() end
            local goal=(clock<previewUntil) and 1 or 0
            alignmentGlow=alignmentGlow+(goal-alignmentGlow)*(1-exp(-5*step))
            chaseTargetX=nil; chaseTargetY=nil; chaseX=nil; chaseY=nil
            wasAligned=false; alignedFor=0; return
        end
        -- Chase mode uses the projected 3D route spot rather than a HUD bearing offset.
        -- Keep compass/bearing calculations intact for glow and for easy fallback.
        if db.chase and not db.test then
            local x,y,depth,projectStatus=ReadProjected()
            lastStatus=projectStatus
            if not x then
                if flightTransition then return end
                self:Hide(); chaseTargetX=nil; chaseTargetY=nil
                chaseX=nil; chaseY=nil
                alignmentGlow=0; wasAligned=false; alignedFor=0; return
            end
            self:Show()
            chaseTargetX, chaseTargetY=x,y
            if flightTransition and flightTransition.kind=="chase" then
                -- Retarget gently if the projected destination moves during flight.
                flightTransition.x1=x; flightTransition.y1=y
            elseif not chaseX then
                -- First acquisition: start at the real projected spot, not
                -- at (0,0). Subsequent samples glide smoothly from here.
                chaseX,chaseY=x,y
                MoveProjected(x,y)
            end
        else
            self:Show()
            chaseTargetX=nil; chaseTargetY=nil; chaseX=nil; chaseY=nil
        end
        if db.reverse then angle=-angle end
        -- Center when facing the target. Slide toward edges as the bearing turns.
        -- A target directly BEHIND the camera must not misleadingly appear centered.
        local s=sin(angle)
        if abs(s)>0.08 then lastSide=s>0 and 1 or -1 end
        -- Compass uses screen width rather than a fixed +/-440px limit.
        -- Its whelp travels entirely offscreen when looking away from a target.
        -- Keep Chase's projected position independent of this calculation.
        local halfWidth=UIParent:GetWidth()/2
        local offscreen=halfWidth+180
        local want
        if cos(angle)>0 then
            -- +/- ~80 degrees carries him completely past the screen edge.
            want=max(-offscreen,min(offscreen,(angle/1.35)*offscreen))
        else
            -- Behind the viewer: remember which edge he exited by.
            -- Do not jump back across the screen when angle wraps at pi.
            want=lastSide*offscreen
        end
        -- Time-based steering damping: smooth across different frame rates.
        bearingX=bearingX+(want-bearingX)*(1-exp(-db.smooth*step))
        if not db.chase or db.test then Move(bearingX+db.x) end
        -- Begin glowing inside a roughly 45-degree cone and brighten to full
        -- intensity within 6 degrees. Behind the player never counts as aligned.
        local deviation=abs(angle)
        local targetGlow=0
        if cos(angle)>0 and deviation<0.80 then
            targetGlow=max(0,min(1,(0.80-deviation)/0.69))
            targetGlow=targetGlow*targetGlow*(3-2*targetGlow)
        end
        alignmentGlow=alignmentGlow+(targetGlow-alignmentGlow)*(1-exp(-4*step))
        -- Trigger only on a real turn INTO alignment, not continuously while facing forward.
        local aligned=cos(angle)>0 and abs(angle)<0.10
        if aligned then alignedFor=alignedFor+step else alignedFor=0 end
        if aligned and not wasAligned and alignedFor>=0.20 and clock-lastBurst>4 then
            lastBurst=clock
            burstStarted=clock
            wasAligned=true
        elseif not aligned then
            wasAligned=false
        end
    end)
end


-- Seven-position selector: Auto, Chase, Pet, Target Range, Radar, Off, SparkleBag.
-- Its position and selected mode are saved in SparkleButtDB.
local buttonDefinitions = {
    { key="auto",    label="Auto",    rgb={0.18,0.44,0.82} },
    { key="chase",   label="Chase",   rgb={0.18,0.85,0.38} },
    { key="pet",     label="Pet",     rgb={0.98,0.76,0.18} },
    { key="radar", label="SparkleRadar (click to toggle on/off)", rgb={1.00,0.46,0.06} },
    { key="off",     label="Off",     rgb={0.94,0.24,0.26} },
    { key="bag",     label="SparkleBag: deposit inventory items already in your bank (requires open bank)", rgb={0.80,0.84,0.90} },
}
local function CurrentMode()
    if not db or not db.enabled then return "off" end
    if db.autoMode then return "auto" end
    if db.chase then return "chase" end
    return "pet"
end
-- Off is a global shutdown: stop Radar as well as dragon navigation.
-- Leave Radar independent when selecting Auto, Chase or Pet.
local function DisableRadarForOff()
    if type(SparkleButtRadarCommand)=="function" then
        local active=type(SparkleButtRadarIsEnabled)=="function" and SparkleButtRadarIsEnabled()
        if active then SparkleButtRadarCommand("off") end
    end
end
local function ApplyMode(key)
    -- Preserve the visible starting position before changing any mode flags.
    -- Manual mode switches should share Auto's existing flight animator.
    local wasEnabled=db.enabled
    local wasChasing=db.chase and db.compass
    local oldMode=CurrentMode()
    local oldX,oldY
    if holder and wasEnabled and holder:IsShown() then
        oldX,oldY=holder:GetCenter()
    end
    -- SparkleBag is an independent bank action, not a navigation mode.
    if key=="bag" then
        if type(SparkleBagToggle)=="function" then SparkleBagToggle()
        else Say("SparkleBag module unavailable. Check SparkleBag.lua.") end
        return
    end
    -- SparkleRadar is independent from the dragon's navigation mode.
    -- Toggle before touching snack, flight, or mode state.
    if key=="radar" then
        if type(SparkleButtRadarCommand)=="function" then
            local active = type(SparkleButtRadarIsEnabled)=="function" and SparkleButtRadarIsEnabled()
            SparkleButtRadarCommand(active and "off" or "on")
        else
            Say("SparkleRadar module unavailable. Check SparkleRadar.lua.")
        end
        if UpdateModeUI then UpdateModeUI() end
        return
    end
    snack=nil
    if snackHearts then for _,t in ipairs(snackHearts) do t:SetAlpha(0) end end
    if snackTreat then snackTreat:SetAlpha(0) end
    if key=="off" then
        DisableRadarForOff()
        db.enabled=false; db.autoMode=false
    elseif key=="auto" then
        db.enabled=true; db.autoMode=true; db.test=false
        autoRouteSeenFor=0
        -- Enter Chase when there is a route; otherwise wait alongside as Pet.
        local a,st=ReadStarfall()
        autoAtDestination=(st=="arrived" or not a)
        if st=="arrived" then arrivalGlowHeld=true end
        db.chase=not autoAtDestination; db.compass=db.chase
    elseif key=="chase" then db.enabled=true; db.autoMode=false; db.chase=true; db.compass=true; db.test=false
    elseif key=="pet" then
        if oldMode=="pet" then
            db.petSide=(db.petSide=="left") and "right" or "left"
        end
        db.enabled=true; db.autoMode=false; db.chase=false; db.compass=false; db.test=false
    else return end

    flightTransition=nil
    chaseTargetX=nil; chaseTargetY=nil; chaseX=nil; chaseY=nil
    if holder then
        holder:SetAlpha(1)
        if not db.enabled then
            holder:Hide()
        else
            local nowChasing=db.chase and db.compass
            -- Animate manual Chase/Pet switches, Auto entry from the other
            -- role, and a Pet-side switch. Never invent an absent projection.
            local canFly=wasEnabled and holder:IsShown()
            local needsFlight=(wasChasing~=nowChasing) or (key=="pet" and oldMode=="pet")
            if canFly and needsFlight then
                if nowChasing then
                    local x,y=ReadProjected()
                    if x and y then StartAutoFlight("chase",x,y) end
                    -- No projected target: keep the existing position. The
                    -- regular Chase updater will acquire/hide as appropriate.
                else
                    local x,y=PetScreenPosition()
                    StartAutoFlight("pet",x,y)
                end
            elseif not nowChasing then
                Move(0)
                holder:Show()
            else
                -- Chase-to-Chase must continue smoothing from its current
                -- visible location, even when switching Auto <-> Chase.
                local x,y=ReadProjected()
                if wasEnabled and oldX and oldY then
                    chaseX,chaseY=oldX,oldY
                elseif x and y then
                    MoveProjected(x,y)
                    chaseX,chaseY=x,y
                end
                holder:Show()
            end
        end
    end
    if UpdateModeUI then UpdateModeUI() end
end
local function BuildSelector()
    if selector then return end
    selector=CreateFrame("Frame","SparkleButtModeSelector",UIParent)
    selector:SetSize(20,155)
    selector:SetFrameStrata("DIALOG")
    selector:SetClampedToScreen(true)
    selector:SetMovable(true)
    selector:EnableMouse(true)
    selector:RegisterForDrag("LeftButton")
    selector:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",db.selectorX,db.selectorY)
    -- No tray or rectangular backing: seven circular controls render.
    selector:SetScript("OnDragStart",function(self) self:StartMoving() end)
    local function SavePosition(self)
        self:StopMovingOrSizing()
        local right=self:GetRight()
        local top=self:GetTop()
        if right and top then
            db.selectorX=right-UIParent:GetRight()
            db.selectorY=top-UIParent:GetTop()
            self:ClearAllPoints()
            self:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",db.selectorX,db.selectorY)
        end
    end
    selector:SetScript("OnDragStop",SavePosition)
    modeButtons={}
    for i,def in ipairs(buttonDefinitions) do
        local button=CreateFrame("Button",nil,selector)
        button:SetSize(18,18) -- Invisible 18px click target; visual circle is 9px (75% smaller).
        -- Slot 4 is reserved for the independent target-range control.
        local slot=(i<=3) and i or (i+1)
        button:SetPoint("TOP",selector,"TOP",0,-7-(slot-1)*21)
        button:RegisterForClicks("LeftButtonUp")
        button:RegisterForDrag("LeftButton", "RightButton")
        button:SetScript("OnMouseDown",function(self) self.didDrag=false end)
        button:SetScript("OnDragStart",function(self) self.didDrag=true; selector:StartMoving() end)
        button:SetScript("OnDragStop",function() SavePosition(selector) end)
        button:SetScript("OnClick",function(self)
            if self.didDrag then self.didDrag=false; return end
            ApplyMode(def.key)
        end)
        button:SetScript("OnEnter",function(self)
            GameTooltip:SetOwner(self,"ANCHOR_LEFT")
            GameTooltip:SetText(def.label,1,1,1)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave",function() GameTooltip:Hide() end)
        -- Borderless 9px dot. The larger button remains an invisible hit target.
        local disc=button:CreateTexture(nil,"ARTWORK")
        disc:SetSize(9,9)
        disc:SetPoint("CENTER")
        disc:SetTexture("Interface\\AddOns\\SparkleButt\\Media\\mode_circle.tga")
        button.disc=disc
        if def.key=="pet" then
            -- One half of the original circular texture; no extra assets.
            local half=button:CreateTexture(nil,"OVERLAY")
            half:SetTexture("Interface\\AddOns\\SparkleButt\\Media\\mode_circle.tga")
            half:SetSize(4.5,9)
            half:Hide()
            button.petHalf=half
        end
        modeButtons[i]=button
    end
    textButton=CreateFrame("Button",nil,selector)
    textButton:SetSize(18,18)
    textButton:SetPoint("TOP",selector,"TOP",0,-7-3*21)
    textButton:RegisterForClicks("LeftButtonUp")
    textButton:RegisterForDrag("LeftButton","RightButton")
    textButton:SetScript("OnMouseDown",function(self) self.didDrag=false end)
    textButton:SetScript("OnDragStart",function(self) self.didDrag=true; selector:StartMoving() end)
    textButton:SetScript("OnDragStop",function() SavePosition(selector) end)
    textButton:SetScript("OnClick",function(self)
        if self.didDrag then self.didDrag=false; return end
        CycleTextPosition()
    end)
    textButton:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_LEFT")
        GameTooltip:SetText("Target range: "..(db.textPosition or "off").." (click: above / below / off)",1,1,1)
        GameTooltip:Show()
    end)
    textButton:SetScript("OnLeave",function() GameTooltip:Hide() end)
    textButton.disc=textButton:CreateTexture(nil,"ARTWORK")
    textButton.disc:SetSize(9,9)
    textButton.disc:SetPoint("CENTER")
    textButton.disc:SetTexture(MEDIA.."mode_circle.tga")
    textButton.top=textButton:CreateTexture(nil,"OVERLAY")
    textButton.top:SetSize(9,4.5)
    textButton.top:SetTexture(MEDIA.."mode_circle.tga")
    textButton.bottom=textButton:CreateTexture(nil,"OVERLAY")
    textButton.bottom:SetSize(9,4.5)
    textButton.bottom:SetTexture(MEDIA.."mode_circle.tga")
    UpdateModeUI()
end
UpdateModeUI=function()
    if not modeButtons then return end
    local mode=CurrentMode()
    for i,def in ipairs(buttonDefinitions) do
        local b=modeButtons[i]
        local active=(mode==def.key)
        if def.key=="bag" then
            -- Always silver: bank transfers are actions, never navigation modes.
            b.disc:SetVertexColor(unpack(def.rgb))
        elseif def.key=="radar" then
            -- Radar is a separate toggle, not a navigation mode.
            local radarOn = type(SparkleButtRadarIsEnabled)=="function" and SparkleButtRadarIsEnabled()
            if radarOn then b.disc:SetVertexColor(unpack(def.rgb))
            else b.disc:SetVertexColor(0.27,0.31,0.36,1) end
        elseif def.key=="pet" and active then
            b.disc:SetVertexColor(0.27,0.31,0.36,1)
            b.petHalf:ClearAllPoints()
            if db.petSide=="left" then
                b.petHalf:SetPoint("LEFT",b.disc,"LEFT")
                b.petHalf:SetTexCoord(0,0.5,0,1)
            else
                b.petHalf:SetPoint("RIGHT",b.disc,"RIGHT")
                b.petHalf:SetTexCoord(0.5,1,0,1)
            end
            b.petHalf:SetVertexColor(unpack(def.rgb))
            b.petHalf:Show()
        else
            if b.petHalf then b.petHalf:Hide() end
            if active then b.disc:SetVertexColor(unpack(def.rgb))
            else b.disc:SetVertexColor(0.27,0.31,0.36,1) end
        end
    end
    if UpdateTextUI then UpdateTextUI() end
end
SparkleButtRefreshSelector=function() if UpdateModeUI then UpdateModeUI() end end
UpdateTextUI=function()
    if not textButton or not db then return end
    local pos=db.textPosition or "off"
    textButton.disc:SetVertexColor(0.27,0.31,0.36,1)
    textButton.top:Hide(); textButton.bottom:Hide()
    if pos=="above" then
        textButton.top:ClearAllPoints()
        textButton.top:SetPoint("TOP",textButton.disc,"TOP")
        textButton.top:SetTexCoord(0,1,0,0.5)
        textButton.top:SetVertexColor(1,0.82,0.22)
        textButton.top:Show()
    elseif pos=="below" then
        textButton.bottom:ClearAllPoints()
        textButton.bottom:SetPoint("BOTTOM",textButton.disc,"BOTTOM")
        textButton.bottom:SetTexCoord(0,1,0.5,1)
        textButton.bottom:SetVertexColor(1,0.82,0.22)
        textButton.bottom:Show()
    end
end

local events=CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent",function(_,event,name)
    if event=="ADDON_LOADED" and name==ADDON then InitDB() end
    if event=="PLAYER_LOGIN" then
        if not db then InitDB() end
        Build()
        BuildSelector()
        -- Auto resumes in its saved mode; reconcile to live route on login.
        if db.autoMode then
            local a,st=ReadStarfall()
            autoAtDestination=(st=="arrived" or not a)
            if st=="arrived" then arrivalGlowHeld=true end
            db.chase=not autoAtDestination; db.compass=db.chase
            autoRouteSeenFor=0
            if not db.chase then Move(0) end
        end
        Say("v0.6.37 ready - SparkleBag quiet one-stack deposits; radar remains independent.")
    end
end)

SLASH_SPARKLEBUTT1="/sb"
SLASH_SPARKLEBUTT2="/sparklebutt"
SlashCmdList.SPARKLEBUTT=function(input)
    if not db then InitDB() end
    local cmd,arg=(input or ""):lower():match("^(%S*)%s*(.-)%s*$")
    if cmd=="radar" then
        if type(SparkleButtRadarCommand)=="function" then
            SparkleButtRadarCommand(arg)
        else
            Say("SparkleRadar module unavailable. Check the addon files.")
        end
        return
    end
    if cmd=="sample" then
        LogBand(true)
        return
    end
    if cmd=="calibrate" then
        collecting=not collecting
        if collecting then
            collected=0; lastBand=nil; nextSampleAt=0
            Say("sampling ON: walk toward/away from the SAME enemy, then /sb calibrate to stop")
        else
            Say("sampling OFF: "..collected.." readings; chat logs band changes only")
        end
        return
    end
    if cmd=="rangecheck" then
        DebugDistance()
        return
    end
    if cmd=="text" then
        Build()
        if arg=="above" or arg=="below" or arg=="off" then
            SetTextPosition(arg); Say("Target text "..arg)
        else
            CycleTextPosition()
        end
        return
    end
    if cmd=="snack" then
        Build()
        StartSnack()
        return
    end
    if cmd=="on" then db.enabled=true
    elseif cmd=="off" then DisableRadarForOff(); db.enabled=false; db.autoMode=false
    elseif cmd=="auto" then ApplyMode("auto"); return
    elseif cmd=="3d" or cmd=="model" then db.mode="3d"; db.enabled=true
    elseif cmd=="2d" or cmd=="sprite" then db.mode="2d"; db.enabled=true
    elseif cmd=="compass" or cmd=="top" then
        -- Compatibility alias for old macros; Compass UI is retired.
        db.chase=true; db.compass=true; db.enabled=true; db.autoMode=false; db.test=false
        Say("Compass retired; using Chase instead.")
    elseif cmd=="chase" then db.chase=true; db.compass=true; db.enabled=true; db.autoMode=false; db.test=false
    elseif cmd=="clear" or cmd=="cancel" then
        if SparkleButtWaypoint and SparkleButtWaypoint.Clear then
            SparkleButtWaypoint.Clear()
        else Say("Waypoint bridge not loaded; install the included Starfall patch.") end
        return
    elseif cmd=="waypoint" or cmd=="goto" then
        if not (SparkleButtWaypoint and SparkleButtWaypoint.Set) then
            Say("Waypoint bridge not loaded; install the included Starfall patch."); return
        end
        local a,b,c = arg:match("^(%d+)%s+([%d%.]+)%s+([%d%.]+)$")
        if not a then Say("Usage: /sb waypoint MAPID X Y  (e.g. /sb waypoint 37 42.5 65.0)"); return end
        b,c=tonumber(b),tonumber(c)
        if not (b and c and b>=0 and b<=100 and c>=0 and c<=100) then
            Say("X and Y must be map percentages between 0 and 100."); return
        end
        local ok,err=SparkleButtWaypoint.Set(tonumber(a),b/100,c/100)
        if not ok then Say(err) end
        return
    elseif cmd=="ahead" then
        local n=tonumber(arg); if not n then Say("Usage: /sb ahead 12 (2-45 yards)"); return end
        db.ahead=max(2,min(45,n))
    elseif cmd=="lift" then
        local n=tonumber(arg); if not n then Say("Usage: /sb lift 3 (0-12 yards)"); return end
        db.lift=max(0,min(12,n))
    elseif cmd=="pet" or cmd=="center" then db.chase=false; db.compass=false; db.enabled=true; db.autoMode=false
    elseif cmd=="petside" then
        if arg~="left" and arg~="right" then Say("Usage: /sb petside left | right"); return end
        db.petSide=arg; db.chase=false; db.compass=false; db.enabled=true; db.autoMode=false
    elseif cmd=="test" then db.test=not db.test; db.enabled=true; db.autoMode=false; db.compass=true; if db.test then db.chase=false end
    elseif cmd=="flip" then db.reverse=not db.reverse
    elseif cmd=="y" or cmd=="height" then
        local n=tonumber(arg)
        if not n then Say("Usage: /sb height -110 (range -400 to -20; closer to 0 is higher)"); return end
        db.y=max(-400,min(-20,n))
    elseif cmd=="glow" or cmd=="preview" or cmd=="yes" then
        -- Preview only. Does not change navigation, test mode, or route state.
        db.enabled=true
        db.burst=true
        Build()
        holder:Show()
        lastBurst=clock
        burstStarted=clock
        previewUntil=clock+2.5
        alignmentGlow=1
        Say("Emerald glow preview (no text).")
        return
    elseif cmd=="sparkles" or cmd=="burst" then
        if arg=="on" then db.burst=true
        elseif arg=="off" then db.burst=false
        else db.burst=not db.burst end
    elseif cmd=="face" then
        if arg=="on" then db.faceTurns=true
        elseif arg=="off" then db.faceTurns=false
        else Say("Usage: /sb face on | off"); return end
        Say("Directional facing "..(db.faceTurns and "enabled" or "disabled"))
        return
    elseif cmd=="faceflip" then
        db.faceFlip=not db.faceFlip
        Say("Side-facing direction "..(db.faceFlip and "reversed" or "normal"))
        return
    elseif cmd=="faceease" then
        local n=tonumber(arg)
        if not n then Say("Usage: /sb faceease 7 (1-20; larger turns faster)"); return end
        db.faceEase=max(1,min(20,n))
        Say("Facing turn speed "..db.faceEase)
        return
    elseif cmd=="chaseease" then
        local n=tonumber(arg)
        if not n then Say("Usage: /sb chaseease 7 (1-20; lower = softer, more lag; higher = faster)"); return end
        db.chaseSmooth=max(1,min(20,n))
        Say("Chase smoothing "..db.chaseSmooth.." (lower=softer, higher=faster)")
        return
    elseif cmd=="smooth" then
        local n=tonumber(arg)
        if not n then Say("Usage: /sb smooth 5 (range 1-15; smaller glides more)"); return end
        db.smooth=max(1,min(15,n))
    elseif cmd=="x" then db.x=max(-300,min(300,tonumber(arg) or db.x))
    elseif cmd=="scale" then
        local n=tonumber(arg); if not n then Say("Usage: /sb scale 0.5-2") return end
        db.scale=max(0.5,min(2,n))
    elseif cmd=="id" then
        local n=tonumber(arg)
        if not n or n<1 or n>1000000 then Say("Usage: /sb id 6291") return end
        db.displayID=floor(n); db.mode="3d"; db.enabled=true
    elseif cmd=="reset" then
        for k,v in pairs(defaults) do db[k]=v end
    elseif cmd=="status" then
        local angle,status=ReadStarfall()
        Say("pet side="..tostring(db.petSide).." target text="..tostring(db.textPosition).." arrival glow="..tostring(arrivalGlowHeld).." snacks="..tostring(snackCount))
        Say("model="..db.mode.." navigation="..(not db.enabled and "off" or db.autoMode and (autoAtDestination and "auto:pet" or "auto:chase") or db.chase and "chase" or "pet").." chaseease="..tostring(db.chaseSmooth).." facing="..tostring(db.faceTurns).." state="..tostring(lastStatus).." heading="..(angle and string.format("%.1f",angle*180/math.pi) or "none"))
        if model and model.GetDisplayInfo then Say("model display="..tostring(model:GetDisplayInfo())) end
        return
    else
        Say("Alt+left-click the world map to set a destination; /sb clear to cancel; /sb waypoint MAPID X Y manually.")
        Say("/sb radar on|off|status|reset | /sb text [above/below/off] | snack | auto | chase | pet | petside left/right | status | off")
        return
    end
    snack=nil
    Build(); SetModel()
    if UpdateModeUI then UpdateModeUI() end
    flightTransition=nil
    chaseTargetX=nil; chaseTargetY=nil; chaseX=nil; chaseY=nil
    if not db.chase then Move(bearingX+db.x) end
    if db.enabled then holder:Show() else holder:Hide() end
    Say("mode="..db.mode.."; chase="..tostring(db.chase).."; compass="..tostring(db.compass).."; test="..tostring(db.test))
end
