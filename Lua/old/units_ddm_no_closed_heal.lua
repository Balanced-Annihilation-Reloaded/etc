--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "DDM no closed heal",
    desc      = "Prevents closed cordoom from being healed",
    author    = "Bluestone", 
    date      = "06/11/2013",
    license   = "GNU GPL, v3 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--SYNCED
if gadgetHandler:IsSyncedCode() then

local spGetUnitStates = Spring.GetUnitStates
local spGetUnitIsActive = Spring.GetUnitIsActive
local spGetUnitDefID = Spring.GetUnitDefID
local spValidUnitID = Spring.ValidUnitID
local CORDOOM = UnitDefNames["cordoom"].id
local REPAIR = CMD.REPAIR


-- don't allow closed ddm to be healed
function gadget:AllowUnitBuildStep(builderID, builderTeamID, uID, uDefID, step)
	if uDefID ~= CORDOOM then return true end
	local active = spGetUnitIsActive(uID)
	if not active then 
		--Spring.Echo("Denied heal: ddm closed")
		return false 
	end
	return true
end

-- don't allow repair commands to be given to closed ddm (just in case)
function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, synced)
	if cmdID ~= REPAIR then return true end
	if not cmdParams then return true end
	if not cmdParams[1] then return true end
	local targetID = cmdParams[1]
	if not spValidUnitID(targetID) then return true end
	local targetDefID = spGetUnitDefID(targetID)
	if targetDefID ~= CORDOOM then return true end
	local active = spGetUnitIsActive(targetID)
	if not active then 
		--Spring.Echo("Denied command; ddm closed")
		return false 
	end
	return true
end





--UNSYNCED
else


local CORDOOM = UnitDefNames["cordoom"].id
local GUARD = CMD.GUARD
local spGetMouseState = Spring.GetMouseState
local spTraceScreenRay = Spring.TraceScreenRay
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitIsActive = Spring.GetUnitIsActive

local mx,my,s,uID,sDefID,active
local changeCMD

-- keep track of if mouse is hovering over a closed ddm (for perf reasons; Update is called much less than DefaultCommand)
function gadget:Update()
	mx,my = spGetMouseState()
	s,uID = spTraceScreenRay(mx,my)
	if s ~= "unit" then return end
	sDefID = spGetUnitDefID(uID)
	if sDefID ~= CORDOOM then return end
	active = spGetUnitIsActive(uID)
	if not active then 
		changeCMD = true
	else
		changeCMD = false
	end
end

-- change default command on mouseover closed ddm to guard (would normally be repair)
function gadget:DefaultCommand()
	if changeCMD then 
		--Spring.Echo("Denied default command; DDM closed")
		return GUARD 
	end
	return
end








end

