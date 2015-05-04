function gadget:GetInfo()
  return {
    name      = "Prevent Mass Self-D",
    desc      = "Prevents too many units self destructing together",
    author    = "Bluestone",
    date      = "Feb 2015",
    license   = "Bunnies",
    layer     = 0,
    enabled   = true  
  }
end

-- the logic of this gadget relies on self d orders being cancelled when units are transferred between teams (unit_prevent_share_self_d)

if (gadgetHandler:IsSyncedCode()) then

local CMD_SELFD = CMD.SELFD
local CMD_STOP = CMD.STOP

local newbieSelfD = {} -- newbieSelfD[teamID] = unitID
local toCheck = {} -- toCheck[gameFrame] = {teamID=teamID,unitID=unitID}
local toWarn -- toWarn = nil or table, toWarn[n] = teamID
local toRemove -- toRemove = nil or table, toRemove[n] = {teamID=teamID,unitID=unitID}

local newbieTeams = {}
function isNewbie(teamID)
    if newbieTeams[teamID] then
        return newbieTeams[teamID]
    end
    newbieTeams[teamID] = (Spring.GetTeamRulesParam(teamID, 'isNewbie') == 1)
    return newbieTeams[teamID] 
end

function AddCheck(teamID, unitID, unitDefID)
    local curFrame = Spring.GetGameFrame()
    local selfDTime = (UnitDefs[unitDefID].selfDCountdown or 10) + 1 -- +1 since it takes slightly longer than UnitDefs[unitDefID].selfDCountdown
    local selfDFrame = curFrame + 30*selfDTime + 5
    if not toCheck[selfDFrame] then toCheck[selfDFrame] = {} end
    toCheck[selfDFrame][#toCheck[selfDFrame]+1] = {teamID=teamID,unitID=unitID}
end

function UpdateCheck(curFrame, teamID, unitID)
    local selfDTime = Spring.GetUnitSelfDTime(unitID) 
    local selfDFrame = curFrame + 30*selfDTime + 5
    if not toCheck[selfDFrame] then toCheck[selfDFrame] = {} end
    toCheck[selfDFrame][#toCheck[selfDFrame]+1] = {teamID=teamID,unitID=unitID}
end

 
function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions, cmdTag, synced)
    if cmdID~=CMD_SELFD and (cmdID~=CMD_INSERT or cmdParams[2]~=CMD_SELFD) then return true end
    if not teamID or not unitID or not unitDefID then return true end

    -- only affect newbies
    --if not isNewbie(teamID) then return true end
    
    -- don't affect units (crawling bombs, mines) that self d instantly
    if (UnitDefs[unitDefID].selfDCountdown or 10) < 0.1 then return true end
    
    -- if unit is already marked, unmark it
    if newbieSelfD[teamID] == unitID then 
        if not toRemove then toRemove = {} end
        toRemove[#toRemove+1] = {teamID=teamID,unitID=unitID} -- we cache this and execute in GameFrame, otherwise the effect of a self d order given to multiple units (some of which could be already self d'ing) is not controllable 
        return true
    end
    
    -- if unit is not marked, but we already have a self d order, mark it
    if newbieSelfD[teamID] and newbieSelfD[teamID] ~= unitID then
        if not toWarn then toWarn = {} end
        toWarn[#toWarn+1] = teamID -- we cache this in case of repeated orders
        return false
    end
    
    -- allow the self d
    newbieSelfD[teamID] = unitID
    AddCheck(teamID, unitID, unitDefID)
    
    return true
end

function gadget:GameFrame(f)
    if toCheck[f] then
        for _,v in ipairs(toCheck[f]) do
            -- check if this unitID should be kept in the list or not 
            local unitID = v.unitID
            local teamID = v.teamID
            if newbieSelfD[teamID] and Spring.ValidUnitID(unitID) and (Spring.GetUnitSelfDTime(unitID) or  0) > 0 then
                -- keep unitID 
                newbieSelfD[teamID] = unitID
                UpdateCheck(f, teamID, unitID)
            elseif newbieSelfD[teamID] == unitID then
                -- remove unitID (needed in case the unitID has already been re-used for another unit)
                newbieSelfD[teamID] = nil
            end
        end
        toCheck[f] = nil
    end
    if toWarn then
        local warned = {}
        for _,teamID in ipairs(toWarn) do
            if not warned[teamID] then
                SendToUnsynced("NewbieSelfDLimitWarning", teamID)
                warned[teamID] = true
            end
        end
        toWarn = nil
    end
    if toRemove then
        for _,v in ipairs(toRemove) do
            newbieSelfD[v.teamID] = nil
        end
        toRemove = nil
    end
end

function gadget:unitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeam)
    if newbieSelfD[teamID] == unitID then 
        newbieSelfD[teamID] = nil
    end
end


----------------------
else -- unsynced -----
----------------------

function gadget:Initialize()
    gadgetHandler:AddSyncAction("NewbieSelfDLimitWarning", NewbieSelfDLimitWarning)
end

function gadget:ShutDown()
    gadgetHandler:RemoveSyncAction("NewbieSelfDLimitWarning")
end

function NewbieSelfDLimitWarning(_,teamID)
    local spec,_ = Spring.GetSpectatingState()
    if Spring.GetMyTeamID() == teamID and not spec then
        Spring.Echo("Sorry, newbies can only self destruct one unit at a time!")
    end
end



end