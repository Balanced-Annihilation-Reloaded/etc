function gadget:GetInfo()
  return {
    name      = "Prevent Mass Self-D",
    desc      = "Prevents too many units self destructing together",
    author    = "Bluestone",
    date      = "Feb 2015",
    license   = "Happy Bunnies",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

-- this gadget is unfinished, but still worth keeping

if (gadgetHandler:IsSyncedCode()) then

local selfDUnits = {} 
--selfDCount[teamID][unitID] = game frame of most recent self d order
--selfDCount[teamID].n = number of unitIDs in selfDCount[teamID]

local timeOut = 10*30
local maxSelfD = 10
local maxNewbieSelfD = 1

local toCheck = {} -- toCheck[gameFrame] = {teamID=teamID,unitID=unitID}
local sendWarning = {} --send a warning to teamID on this gameframe

local newbieTeams = {}
function isNewbie(teamID)
    if newbieTeams[teamID] then
        return newbieTeams[teamID]
    end
    newbieTeams[teamID] = (Spring.GetTeamRulesParam(teamID, 'isNewbie') == 1)
    return newbieTeams[teamID] 
end

function selfDLimit(teamID)
    return isNewbie(teamID) and maxNewbieSelfD or maxSelfD
end

function AddCheck(teamID, unitID)
    if not toCheck[frame] then toCheck[frame] = {} end
    toCheck[frame][#toCheck[frame]+1] = {teamID=teamID,unitID=unitID}
end

 
function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions, cmdTag, synced)
    if cmdID~=CMD.SELFD and (cmdID~=CMD.INSERT or cmdParams[2]~=CMD.SELFD) then return true end
    
    if not selfDUnits[teamID] then 
        selfDUnits[teamID] = {} 
        selfDUnits[teamID].n = 0
    end
    
    local f = Spring.GetGameFrame()
    
    -- if unit is already marked, keep it marked in case player wants to give it a new self d order 
    if selfDUnits[teamID][unitID] then 
        selfDUnits[teamID][unitID] = f+timeOut
        AddCheck(teamID, unitID)
        Spring.Echo("SelfD repeat",unitID)    
        return true
    end
    
    -- unit is not marked, check if we have room for another self d order
    if selfDUnits[teamID].n >= selfDLimit(teamID) then
        sendWarning[#sendWarning+1] = teamID
        Spring.Echo("Denied")
        return false
    end
    
    -- allow the self d
    selfDUnits[teamID][unitID] = f+timeOut
    selfDUnits[teamID].n = selfDUnits[teamID].n + 1
    
    AddCheck(f+timeOut, teamID, unitID)
    
    Spring.Echo("SelfD",unitID)    
    
    return true
end

function gadget:GameFrame(f)
    if toCheck[f] then
        for _,v in ipairs(toCheck[f]) do
            -- check if this unitID should be kept in the list or not
            local unitID = v.unitID
            local teamID = v.teamID
            Spring.Echo("Checking", unitID)
            if selfDUnits[teamID][unitID] then
                if Spring.ValidUnitID(unitID) and (Spring.GetUnitSelfDTime(unitID) or  0) > 0 then
                    -- keep unitID in list
                    selfDUnits[teamID][unitID] = f+timeOut
                    AddCheck(teamID, unitID)
                    Spring.Echo("Check keep",unitID)
                else
                    -- remove unitID from list (needed in case the unitID has already been re-used for another unit)
                    selfDUnits[teamID].n = selfDUnits[teamID].n - 1
                    selfDUnits[teamID][unitID] = nil
                    Spring.Echo("Check remove",unitID)
                end
            end
        end
        toCheck[f] = nil
    end
    if #sendWarning>0 then
        local sentWarning = {} -- dedupe
        for _,tID in ipairs(sendWarning)
            if not sentWarning[teamID] then 
                -- TODO: send warning
                sentWarning[teamID] = true            
            end
        end
        sendWarning = {}
    end
end

function gadget:unitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeam)
    if not selfDUnits[teamID] then 
        selfDUnits[teamID] = {} 
        selfDUnits[teamID].n = 0
    end
    if selfDUnits[teamID][unitID] then 
        selfDUnits[teamID].n = selfDUnits[teamID].n - 1
        selfDUnits[teamID][unitID] = nil
        Spring.Echo("Dead removed", unitID)
    end
end


----------------------
else -- unsynced -----
----------------------

end