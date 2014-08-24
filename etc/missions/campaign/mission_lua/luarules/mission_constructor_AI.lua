function gadget:GetInfo()
    return {
        name      = 'Mission Constructor AI',
        desc      = 'Makes constructors wander around doing faintly sensible things',
        author    = 'Bluestone',
        version   = '',
        date      = 'August 2014',
        license   = 'GPL v3 or later',
        layer     = math.huge,
        enabled   = true
    }
end

-- SYNCED --
if (gadgetHandler:IsSyncedCode()) then


local cons = {}

local nCons = 5 --number of cons per AI team, not replaced when they die
local conTeams = {}

local to_reclaim = {}
local to_repair = {}
local to_rebuild = {}



-- SPAWNING --

local armConNames  = {
    "armck",
    "armack",
    "armcv",
    "armacv",
    "armca",
    "armaca",
    "armcs",
    "armacsub",
    "armch",
    "consul",
}

local corConNames = {
    "corck",
    "corack",
    "corcv",
    "coracv",
    "corca",
    "coraca",
    "corcs",
    "coracsub",
    "corch",
    "corfast",
}

function PickSpawnType(faction, x,y,z)
    -- pick a random unitDefID of a constructor of faction suitable for ground at x,y,z
    local conTable
    if faction=="arm" then
        conTable = armConNames
    else
        conTable = corConNames
    end

    local n = #conTable
    local i = math.random(1,n)
    local j = 1
    while (j<=n) do
        local name = conTable[i]
        local uDef = UnitDefNames[name]
        -- test if its viable to place this unitDef at x,y,z
        if (y<-10 and uDef.minWaterDepth and uDef.minWaterDepth>10) or (y>=0 and ((not uDef.minWaterDepth) or uDef.minWaterDepth<=0)) then
            return uDef.id
        end
       
        i = i + 1
        if i>n then i=1 end
        j = j + 1
    end
    
    return false
end

function PickSpawn(tID, faction)
    -- pick a spot near to a random other unit 
    local units = Spring.GetTeamUnits(tID)
    if #units==0 then return end
    local x,y,z,unitDefID
    for i=1,50 do
        local n = math.random(1,#units)
        local theta = math.random(1,360) / 360 * (2*math.pi)
        local r = math.random(300,600) -- must be at least 300 away or TestMoveOrder fails
        local cx,cy,cz = Spring.GetUnitPosition(units[n])
        x, z = cx+r*math.sin(theta), cz+r*math.cos(theta)
        y = Spring.GetGroundHeight(x,z)
        unitDefID = PickSpawnType(faction, x,y,z)
        if unitDefID then 
            local canMove = Spring.TestMoveOrder(unitDefID, cx,cy,cz, 0,1,0, true,true,false)
            if canMove then
                break 
            end
        end
    end
    
    return x,y,z, unitDefID
end

local function RandomFacing()
    return math.random(1,4)
end

-- ACTIONS --

function CheckCons()
    for cID,_ in pairs(cons) do
        if not Spring.ValidUnitID(cID) then
            cons[cID] = nil
        end
    end
end

function CheckRebuilds()
    local frame = Spring.GetGameFrame()
    for i,a in ipairs(to_rebuild) do
        if frame - a.deadFrame >= 120*30 then --remove after 2 minutes
            table.remove(to_rebuild,i)
        end
    end
end

function CheckRepairs()
    for uID,_ in pairs(to_repair) do
        if Spring.ValidUnitID(uID) then
            local h,mh = Spring.GetUnitHealth(uID)
            if (h/mh)>0.7 then
                to_repair[uID] = nil
            end
        else
            to_repair[uID] = nil
        end
    end
end

function CheckReclaims()
    for fID,_ in pairs(to_reclaim) do
        if Spring.ValidFeatureID(fID) then
            local m,_,e,_,_ = Spring.GetFeatureResources(fID)
            if m<100 and e<500 then
                to_reclaim[fID] = nil
            end
        else
            to_reclaim[fID] = nil
        end
    end
end

function CheckActions()
    -- remove no-longer useful actions, re-evaluate urgency of all actions
    CheckRebuilds()
    CheckRepairs()
    CheckReclaims()    
end

function DoAction(cID)    
    -- do an action
    -- order of priority (1) rebuilding (2) repairing (3) reclaiming (4) procrastinating
    local n,j
    
    -- (1)
    n = #to_rebuild
    j = 1
    while (j<=n) do
        i = math.random(1,n)
        local a = to_rebuild[i]
        if a.tID==cons[cID] and UnitDefs[Spring.GetUnitDefID(cID)].buildOrders[a.unitDefID] then
            Spring.GiveOrderToUnit(cID, -a.uDefID, {a.x,a.y,a.z}, {}) 
            return
        end    
        i = i + 1
        if i>n then i=1 end
        j = j + 1
    end

    -- (2)
    local nearestRepair = {uID=nil, dist=math.huge}
    local cx,cy,cz = Spring.GetUnitPosition(cID)
    for uID,_ in pairs(to_repair) do
        Spring.Echo(uID, Spring.ValidUnitID(uID))
        local x,y,z = Spring.GetUnitPosition(uID)
        local r = math.sqrt((x-cx)^2+(y-cy)^2+(z-cz)^2)
        if r<=nearestRepair.dist and r<=1024 and Spring.GetUnitTeam(uID)==cons[cID] then
            nearestRepair = {uID=uID, dist=r}
        end
    end
    if nearestRepair.uID then
        Spring.GiveOrderToUnit(cID, CMD.REPAIR, {nearestRepair.uID}, {})
        return
    end
    
    -- (3)
    local nearestReclaim = {fID=nil, dist=math.huge}
    local cx,cy,cz = Spring.GetUnitPosition(cID)
    for fID,_ in pairs(to_reclaim) do
        local x,y,z = Spring.GetFeaturePosition(fID)
        local r = math.sqrt((x-cx)^2+(y-cy)^2+(z-cz)^2)
        if r<=nearestReclaim.dist and r<=1024 then
            nearestReclaim = {fID=fID, dist=r}
        end
    end
    if nearestReclaim.fID then
        Spring.GiveOrderToUnit(cID, CMD.RECLAIM, {nearestRepair.fID}, {})
        return
    end
    
    -- (4)
    Procrastinate(cID)
end

-- RETREATING --

function RunAway(cID)
    -- find the nearest nano on my team and move towards it; if none are found just run away
    local units = Spring.GetTeamUnits(cons[cID])
    local nanos = {}
    for uID,_ in ipairs(units) do
        local uDefID = Spring.GetUnitDefID(uID)
        if uDefID and (uDefID==ARM_NANO or uDefID==COR_NANO) then
            nanos[#nanos+1] = uID
        end    
    end
    
    if #nanos==0 then
        local eID = Spring.GetUnitNearestEnemy(cID)
        if eID then
            local cx,cy,cz = Spring.GetUnitPosition(cID)
            local x,y,z = Spring.GetUnitPosition(eID)
            local r = math.sqrt((x-cx)^2+(y-cy)^2+(z-cz)^2)
            local nx, ny, nz = (cx-x)/r, (cy-y)/r, (cz-z)/r --unit normal vector in perpendicular direction to eID
            local px, py, pz = nx*512, ny*512, nz*512
            Spring.GiveOrderToUnit(cID, CMD.MOVE, {px,py,pz}, {})
        end
        return
    end
    
    local closestNano = {uID=nil, dist=math.huge}
    for _,nanoID in ipairs(nanos) do
        local cx,cy,cz = Spring.GetUnitPosition(cID)
        local x,y,z = Spring.GetUnitPosition(nanoID)
        local r = math.sqrt((cx-x)^2+(cy-y)^2+(cz-z)^2)
        if r<=closetsNano.dist then
            closestNano = {uID=nano.uID, dist=r} 
        end   
    end
    if closestNano.uID then
        local x,_,z = Spring.GetUnitPosition(closestNano.uID)
        x = x + 50*math.random()
        z = z + 50*math.random()
        y = Spring.GetGroundHeight(x,z)
        Spring.GiveOrdeToUnit(cID, CMD.MOVE, {x,y,z}, {})
    end   
    
end

-- PROCRASTINATION --

function Procrastinate(cID)
    if math.random()<0.5 then
        BuildRandomThing(cID)
    else
        GoForAWalk(cID)
    end
end

function BuildRandomThing(cID)
    -- build something random & probably useless
    local uDefID = Spring.GetUnitDefID(cID)
    local buildOptions = UnitDefs[uDefID].buildOptions
    local id = math.random(1,#buildOptions)
    local x,y,z = Spring.GetUnitPosition(cID)
    local f = RandomFacing()
    local blocking = Spring.TestBuildOrder(buildOptions[id], x,y,z, f)
    if blocking ~= 0 and not UnitDefs[uDefID].isFactory then
        Spring.GiveOrderToUnit(cID, -buildOptions[id], {x,y,z,f}, {})
    end    
end

function GoForAWalk(cID)
    local x,y,z = Spring.GetUnitPosition(cID)
    local theta = math.random(1,360) / 360 * (2*math.pi)
    local dx, dz = 512*math.sin(theta), 512*math.cos(theta)
    local nx, ny, nz = x+dx, Spring.GetGroundHeight(x+dx,z+dz), z+dz
    Spring.GiveOrderToUnit(cID, CMD.MOVE, {nx,ny,nz}, {})    
end




-- MAIN --

function CreateCons()
    -- work out which are the "AI" teams in the mission
    local allyTeams = Spring.GetAllyTeamList()
    for _,aID in ipairs(allyTeams) do
        local teamList = Spring.GetTeamList(aID)
        local tID = teamList[1]
        local _, _, _, isAITeam, _, _ = Spring.GetTeamInfo(tID)
        if isAITeam then
            -- guess faction based on spawned units
            local units = Spring.GetTeamUnits(tID)
            local arm,core = 0,0
            
            local faction = "core" --TODO
            -- record that this team has cons for us to control
            conTeams[tID] = faction
        end
    end
    
    -- (try to) spawn the cons
    for tID,faction in pairs(conTeams) do
    for i=1,nCons do
        local x,y,z, unitDefID = PickSpawn(tID, faction)
        if unitDefID then
            local unitID = Spring.CreateUnit(unitDefID, x,y,z, RandomFacing(), tID) 
            cons[unitID] = tID
        end
    end
    end
end


function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
    -- check if it was one of our cons
    if cons[unitID] and Spring.ValidUnitID(unitID) then
        RunAway(unitID)
        return
    end

    --add damaged unitID into the table to repair
    local h,mh = Spring.GetUnitHealth(unitID)
    if mh>100 and (h/mh)>0.1 and (h/mh)<0.7 then
        to_repair[unitID] = true
    end
    
end

function UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
    -- check if it was on the same team as one of our cons
    if not conTeams[unitTeam] then return end
    
    -- don't try to repair it now
    to_repair[unitID] = nil
    
    --add unitDefID into the table to rebuild
    if conTeams[unitTeam] and UnitDefs[unitDefID].isBuilding then
        local x,y,z = Spring.GetUnitPosition(unitID)
        local f = Spring.GetUnitFacing()
        to_rebuild[#torebuild+1] = {uDefID=unitDefID, x=x,y=y,z=z, f=f, tID=unitTeam, deadFrame=Spring.GetGameFrame()}        
    end

end

function gadget:FeatureCreated(featureID, allyTeamID)
    -- add feature into the table to reclaim, if it's worth it
    local m,_,e,_,_ = Spring.GetFeatureResources(featureID)
    if m>100 or e>500 then
        to_reclaim[featureID] = true
    end
end

function gadget:FeatureDestroyed(featureID, allyTeamID)
    to_reclaim[featureID] = nil
end


function gadget:GameFrame(n)
    if n==2 then 
        CreateCons() 
        return
    end
    if (n%30)~=0 then return end

    -- prune invalid actions & cons
    CheckCons()
    CheckActions()
   
    -- give idle cons that are close to enemies los something to do
    -- only rarely give the others something to do very rarely
    for cID,_ in pairs(cons) do
        local eID = Spring.GetUnitNearestEnemy(cID, 1024, true)
        if eID then
            local x,y,z = Spring.GetUnitPosition(eID)
            local cx,cy,cz = Spring.GetUnitPosition(cID)
            if (x-cx)^2+(y-cy)^2+(z-cz)^2 <= 512^2 and math.random() < 0.5 and Spring.GetCommandQueue(cID, -1, false)==0 then
                DoAction(cID)
            end
        else
            if math.random() < (1/60) then
                Procrastinate(cID)
            end
        end
    end

end


-- UNSYNCED --
else
    return false
end


