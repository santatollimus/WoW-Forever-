-- Optional SparkleButt bridge for Starfall Trail 1.2.0.
-- Loaded INSIDE StarfallTrail, so its private namespace is legitimately available.
-- Reads the route even when ground particles are disabled.
local _, ns = ...
local Bridge = { arrived=false }
StarfallTrailSparkleButtBridge = Bridge

-- Starfall calls SetQuiet with the same arrival state that fades its ground trail.
if ns.Trail and ns.Trail.SetQuiet and hooksecurefunc then
    hooksecurefunc(ns.Trail, "SetQuiet", function(arrived)
        Bridge.arrived = arrived and true or false
    end)
end

function Bridge.Read()
    if not ns.Trail or not ns.HBD then return nil,"map not ready" end
    if Bridge.arrived then return nil,"arrived" end
    local wx, wy = ns.Trail.Lookahead()
    if not wx or not wy then return nil,"waiting for ground route" end
    local px, py, instance = ns.HBD:GetPlayerWorldPosition()
    if not px or not py then return nil,"player position unavailable" end
    local facing = ns.Trail.CameraHeading() or GetPlayerFacing()
    if not facing or (issecretvalue and issecretvalue(facing)) then
        return nil,"camera heading unavailable"
    end
    local angle = ns.HBD:GetWorldVector(instance,px,py,wx,wy)
    if not angle then return nil,"route bearing unavailable" end
    local relative = angle - facing
    -- The returned angle has the same sign convention as Starfall's own arrow.
    return (relative + math.pi) % (math.pi * 2) - math.pi, "tracking trail"
end

-- Optional world-to-screen chase projection from Starfall's live route and terrain grid.
function Bridge.ReadProjected(ahead, lift)
    if Bridge.arrived then return nil,nil,nil,"arrived" end
    if not ns.Trail or type(ns.Trail.ProjectWhelp) ~= "function" then
        return nil,nil,nil,"projection API unavailable"
    end
    return ns.Trail.ProjectWhelp(ahead,lift)
end
