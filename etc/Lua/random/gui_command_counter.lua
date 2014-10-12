function widget:GetInfo()
   return {
      name      = "Command Counter",
      desc      = "Shows commands given by allies",
      author    = "",
      date      = "July 2014",
      license   = "GNU GPL, v2 or later",
      layer     = 2,
      enabled   = true,
   }
end

local cmds = {}
local names = {}
local sumCmds = {}
local frame

function widget:UnitCommand(unitID, unitDefID, teamID, cmdID, _, _)
    if not teamID then return end
    if not cmds[teamID] then
        local pl = Spring.GetPlayerList(teamID)
        local name,_ = Spring.GetPlayerInfo(pl[1])
        names[teamID] = name
        cmds[teamID] = 0
        sumCmds[teamID] = 0
    end
    cmds[teamID] = cmds[teamID] + 1
end


function widget:GameFrame(n)
    frame = n
    -- enable this for regular reports
    --[[
    if frame%(30*60)==0 then
        local total = 0
        for k,v in pairs(cmds) do
            if v>0 then
                total = total + v
                Spring.Echo("Team " .. k .. " had " .. v .. " commands (" .. names[k] .. ")") 
                sumCmds[k] = sumCmds[k] + cmds[k]
                cmds[k] = 0
            end
        end
    end
    ]]
end

function widget:GameOver()
    for k,v in pairs(sumCmds) do
        if v>0 then
            total = total + v
            Spring.Echo("Team " .. k .. " had total of " .. v .. " commands (" .. names[k] .. ")") 
        end
    end
end

