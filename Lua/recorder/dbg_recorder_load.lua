function gadget:GetInfo()
  return {
    name      = "Recorder (Load)",
    desc      = "Plays back a minute of a game",
    author    = "Bluestone",
    date      = "June 2014",
    license   = "GNU GPL, v3 or later",
    layer     = 1,  
    enabled   = true  
  }
end

if gadgetHandler:IsSyncedCode() then
-------------------------------------
----------------SYNCED---------------

UNIT_FILENAME = "REC_unit.lua"
ORDER_Q_FILENAME = "REC_order_q.lua" 
FACTORY_Q_FILENAME = "REC_factory_q.lua"
ORDER_FILENAME = "REC_order.lua"

local unit_table = VFS.Include("luarules/configs/" .. UNIT_FILENAME)
local order_q_table = VFS.Include("luarules/configs/" .. ORDER_Q_FILENAME)
local factory_q_table = VFS.Include("luarules/configs/" .. FACTORY_Q_FILENAME)
local order_table = VFS.Include("luarules/configs/" .. ORDER_FILENAME)

local t1ID = Spring.GetGaiaTeamID()
local allyTeamList = Spring.GetAllyTeamList()
local aTeamList = Spring.GetTeamList(allyTeamList[1])
local t2ID = aTeamList[1] -- some teamID that isn't Gaia

local startFrame
local playOrders = false
local orderCount 
local playStartFrame
local nOrders = #order_table

local PFSwait = 20 --in seconds

local white = "\255\255\255\255"

function gadget:Initialize()
	gadgetHandler:AddChatAction('saveunits', SaveUnits, "")
	gadgetHandler:AddChatAction('loadunits', LoadUnits, "")
	gadgetHandler:AddChatAction('placeunits', PlaceUnits, "")
	gadgetHandler:AddChatAction('playorders', PlayOrders, "")
	gadgetHandler:AddChatAction('cleanunits', CleanUnits, "")
end

function gadget:ShutDown()
	gadgetHandler:RemoveChatAction('saveunits')
	gadgetHandler:RemoveChatAction('loadunits')
	gadgetHandler:RemoveChatAction('placeunits')
	gadgetHandler:RemoveChatAction('cleanunits')
end

function SaveUnits()
    SendToUnsynced("SaveUnits")
end

function LoadUnits()
    if playOrders then 
        Spring.Echo("ERROR: Already in progress")
        return 
    end 

    local m = #(Spring.GetAllUnits())
    if m>0 then
        CleanUnits()
        startFrame = Spring.GetGameFrame() + 30 -- we need the unitIDs of cleaned units to be available
    else
        startFrame = Spring.GetGameFrame() + 1
    end
end

function PlaceUnits()
    if t1ID==t2ID or t2ID==nil then
        Spring.Echo("ERROR: Need at least two ally teams")
        return
    end

    for _,u in ipairs(unit_table) do
        tID = (u.aID==1) and t1ID or t2ID
        local uDID = UnitDefNames[u.name].id
        local unitID = Spring.CreateUnit(uDID,u.x,u.y,u.z,u.f,tID,false,false,u.uID)
        if unitID ~= u.uID then
            unitID = unitID or "nil"
            Spring.Echo("ERROR: Failed to create unit or unitID, likely reached unit limit (" .. unitID .. "," .. u.uID .. ")") 
        end
        Spring.SetUnitMaxHealth(u.uID,u.mh)
        Spring.SetUnitHealth(u.uID,u.h,0,0,u.b)
    end
end

function LoadUnitsNow()
    Spring.Echo(white .. "Loaded units, order queue starts in " .. PFSwait .. " seconds")
    CleanUnits()
    PlaceUnits()
    return true
end

function PlayOrders()
    if playOrders then
        Spring.Echo(white .. "ERROR: Already in progress")
        return
    end

    GiveInitialOrders()
    Spring.Echo(white .. "Playing order queue")
    SendToUnsynced("Started")
    playOrders = true
    playStartFrame = Spring.GetGameFrame()
    orderCount = 1
end

function GiveInitialOrders()
   for _,o in ipairs(order_q_table) do
        o.options.shift = true 
        o.params = {o.params[1],o.params[2],o.params[3],o.params[4],o.params[5],o.params[6]} --otherwise the params table is loaded in the wrong order (i bet it's luas crappy type conversion)
        if Spring.ValidUnitID(o.uID) then
            Spring.GiveOrderToUnit(o.uID,o.cmdID,o.params,o.options.coded)
        end
    end
    
    for _,o in ipairs(factory_q_table) do
        o.options.shift = true 
        o.params = {o.params[1],o.params[2],o.params[3],o.params[4],o.params[5],o.params[6]} 
        if Spring.ValidUnitID(o.uID) then
            Spring.GiveOrderToUnit(o.uID,CMD.REPEAT,{1},{})
            Spring.GiveOrderToUnit(o.uID,o.cmdID,o.params,o.options.coded)
        end
    end
end

function gadget:GameFrame(n)
    if n-30==startFrame then
        LoadUnitsNow()    
    end

    if n-30*PFSwait==startFrame then
        PlayOrders()
    end 

    if playOrders then
        while order_table[orderCount].f<=n-playStartFrame do
            local o = order_table[orderCount]
            o.params = {o.params[1],o.params[2],o.params[3],o.params[4],o.params[5],o.params[6]} 
            local cmdID = CMD[o.cmdName] or o.cmdID -- engines commands are best stored by name, but custom commands can have (?) to be stored by ID
            if Spring.ValidUnitID(o.uID) then
                Spring.GiveOrderToUnit(o.uID,cmdID,o.params,o.options.coded)
            end
            orderCount = orderCount + 1
            if orderCount==nOrders then
                playOrders = false
                Spring.Echo(white .. "Finished order queue")
                SendToUnsynced("Finished")
                return
            end
        end
    end
end

function CleanUnits()
    local units = Spring.GetAllUnits()
    for _,unitID in ipairs(units) do
        Spring.DestroyUnit(unitID, false, true) 
    end
    local features = Spring.GetAllFeatures()
    for _,featureID in ipairs(features) do
        Spring.DestroyFeature(featureID, false, true) 
    end
    playOrders = false
    Spring.Echo(white .. "Cleaned map")
    SendToUnsynced("Interrupt")
    return true
end


else
-------------------------------------
--------------UNSYNCED---------------

local white = "\255\255\255\255"

function round(val, decimal)
    return decimal and math.floor((val * 10^decimal) + 0.5) / (10^decimal) or math.floor(val+0.5)
end

function gadget:Initialize()
    gadgetHandler:AddSyncAction("SaveUnits", SaveUnits)
    gadgetHandler:AddSyncAction("Started", Started)
    gadgetHandler:AddSyncAction("Finished", Finished)
    gadgetHandler:AddSyncAction("Interrupt", Interrupt)
end
function SaveUnits()
    Script.LuaUI.SaveUnits() 
end

local profile = false
local fpsSamples = {}
local simSamples = {}
local prevSampleFrame = 0
local startedFrame = 0

function Started()
    profile = true
    startedFrame = Spring.GetGameFrame()
end

function gadget:DrawScreen()
    local frame = Spring.GetGameFrame()
    if profile and frame >= 15 + prevSampleFrame and frame >= startedFrame + 30*10 then --sample approx twice per second, give Spring 10 sec to cache at start
        prevSampleFrame = frame
        local fps = Spring.GetFPS()
        fpsSamples[frame] = fps
        local _,curSpeed = Spring.GetGameSpeed()
        simSamples[frame] = curSpeed
    end
end

function Finished()
    local version = Game.version 
    local buildFlags = Game.buildFlags or ""
    local gameName = Game.gameName
    local gameVersion = Game.gameVersion
    Spring.Echo(white .. "Spring " .. version .. " (" .. buildFlags .. ")")
    Spring.Echo(white .. gameName .. " " .. gameVersion)
    
    local tot = 0
    local samples = 0
    local totSqr = 0
    for _,val in pairs(simSamples) do
        tot = tot + val
        totSqr = totSqr + val*val
        samples = samples + 1
    end
	local avSIM = tot/samples
    local sdvSIM = math.sqrt(totSqr/samples - avSIM*avSIM)
    Spring.Echo(white .. "Average sim speed was " .. round(avSIM,2) .. ", std dev " .. round(sdvSIM,2))
    
    tot = 0
    samples = 0
    totSqr = 0
    for _,val in pairs(fpsSamples) do
        tot = tot + val
        totSqr = totSqr + val*val
        samples = samples + 1
    end
    local avFPS = tot/samples
    local sdvFPS = math.sqrt(totSqr/samples - avFPS*avFPS)
    Spring.Echo(white .. "Average FPS was ".. round(avFPS,2) .. ", std dev " .. round(sdvFPS,2))
    Spring.Echo(white .. "Used " .. samples .. " samples")
    
    CleanSamples()
end

function Interrupt()
    profile = false
    CleanSamples()
end

function CleanSamples()
    for k,_ in pairs(simSamples) do
        simSamples[k] = nil
    end
    for k,_ in pairs(fpsSamples) do
        fpsSamples[k] = nil
    end
end

-------------------------------------
end