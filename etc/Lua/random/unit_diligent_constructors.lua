
function widget:GetInfo()
	return {
		name        = "Diligent Constructors",
		desc        = "Makes idle constuction units repair and reclaim any unresurrectable features, resurrect units if possible.",
		author        = "Beherith",
		date        = "March 20, 2016",
		license        = "GNU GPL, v2 or later",
		layer        = 0,
		enabled        = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local CMD_PASSIVE            = 34571
local CMD_MOVE_STATE        = CMD.MOVE_STATE
local CMD_REPEAT            = CMD.REPEAT
local CMD_PATROL            = CMD.PATROL
local CMD_FIGHT                = CMD.FIGHT
local CMD_STOP                = CMD.STOP
local CMD_RECLAIM                = CMD.RECLAIM
local CMD_REPAIR               = CMD.REPAIR
local CMD_RESURRECT             = CMD.RESURRECT
local CMD_WAIT           = CMD.WAIT
local spGetGameFrame        = Spring.GetGameFrame
local spGetMyTeamID            = Spring.GetMyTeamID
local spGetTeamUnits        = Spring.GetTeamUnits
local spGetUnitCommands        = Spring.GetUnitCommands
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetUnitPosition        = Spring.GetUnitPosition
local spGiveOrderToUnit        = Spring.GiveOrderToUnit
local spGetSpectatingState    = Spring.GetSpectatingState
local spGetUnitPosition    = Spring.GetUnitPosition
local spGetFeaturesInSphere = Spring.GetFeaturesInSphere
local spGetFeatureResurrect = Spring.GetFeatureResurrect
local spGetFeatureDefID = Spring.GetFeatureDefID
local spGetUnitTeam = Spring.GetUnitTeam
local spGetUnitHealth = Spring.GetUnitHealth


local hmsx = Game.mapSizeX/2
local hmsz = Game.mapSizeZ/2

local myTeamID = spGetMyTeamID()
local myAllyTeamID = Spring.GetMyAllyTeamID()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local watchedUnits={}

local function IsMobileBuilder(ud)
	return ud and ud.isBuilder and ud.canMove
end


function widget:PlayerChanged()
	if spGetSpectatingState() then
		widgetHandler:RemoveWidget()
	end
end

function widget:Initialize()
	if spGetSpectatingState() then
		widgetHandler:RemoveWidget()
	end
end


-- function widget:UnitCreated(unitID, unitDefID, unitTeam)
	-- if unitTeam ~= myTeamID then
		-- return
	-- end
-- end

-- function widget:UnitGiven(unitID, unitDefID, unitTeam)
	-- widget:UnitCreated(unitID, unitDefID, unitTeam)
-- end

function ReclaimRepairResurrect(unitID, unitDefID, unitTeam)
	-- Spring.Echo('widget:ReclaimRepairResurrect',unitID, unitDefID, unitTeam)
	local x,y,z = spGetUnitPosition(unitID)
	local buildDistance = UnitDefs[unitDefID].buildDistance 
	local closeFeatures = spGetFeaturesInSphere(x,y,z,buildDistance)
	if closeFeatures ~= nil then
		for i, closeFeatureID in ipairs(closeFeatures) do
			 -- Spring.Echo('closeFeatureID',closeFeatureID,FeatureDefs[Spring.GetFeatureDefID(closeFeatureID)].resurrectable,Spring.GetFeatureResurrect(closeFeatureID))
			local featureResID = spGetFeatureResurrect(closeFeatureID)
			if FeatureDefs[spGetFeatureDefID(closeFeatureID)].resurrectable ~= 1  and ( featureResID == nil or featureResID == "") then
				spGiveOrderToUnit(unitID, CMD_RECLAIM,  { Game.maxUnits + closeFeatureID} , {})
				return
			end
		end
	end
	
	local closeUnits = Spring.GetUnitsInSphere(x,y,z,buildDistance)
	if closeUnits ~= nil then
		for i, closeUnitID in ipairs(closeUnits) do
			if closeUnitID ~= unitID and spGetUnitTeam(closeUnitID) == myTeamID then
				local health, maxHealth = spGetUnitHealth(closeUnitID)
				if health and health < maxHealth then
				-- Spring.Echo('REPAIR')
					spGiveOrderToUnit(unitID, CMD_REPAIR,  { closeUnitID} , {})
					return
				end
			end
		end
	end
	
	if closeFeatures ~= nil and UnitDefs[unitDefID].canResurrect then
		for i, closeFeatureID in ipairs(closeFeatures) do
			local featureResID = spGetFeatureResurrect(closeFeatureID)
			if  featureResID ~= nil and featureResID ~= ""  then
			-- Spring.Echo('RESURRECT')
				spGiveOrderToUnit(unitID, CMD_RESURRECT,  { Game.maxUnits + closeFeatureID} , {})
				return
			end
		end
	end
end

function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOpts, cmdTag)
	-- Spring.Echo(Spring.GetGameFrame(),"widget:UnitCommand",unitID, unitDefID, unitTeam,CMD[cmdID], cmdParams, cmdOpts, cmdTag)
	if unitTeam == myTeamID and watchedUnits[unitID]~=nil and cmdID ~= CMD_WAIT then -- this ignores the WAIT WAIT (will probably screw stuff up, but hey :p)
		-- Spring.Echo('UnitCommand clearing unit',unitID)
		watchedUnits[unitID]= nil
	end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
	if watchedUnits[unitID] ~= nil then
		watchedUnits[unitID] = nil
	end
end

function widget:GameFrame(n)
	for unitID, watchstate in pairs(watchedUnits) do
		if (watchstate.lastupdate + watchstate.delay )<=n then
			-- Spring.Echo("slacker is:",unitID,watchstate.lastupdate, watchstate.delay)
			watchedUnits[unitID].lastupdate = n
			watchedUnits[unitID].delay = watchstate.delay+3
			ReclaimRepairResurrect(unitID, watchstate.udID, watchstate.ut)
		end
	end
end
function widget:UnitIdle(unitID, unitDefID, unitTeam)
    if unitTeam ~= myTeamID then
        return
    end
	-- Spring.Echo('widget:UnitIdle',unitID, unitDefID, unitTeam)
	if IsMobileBuilder(UnitDefs[unitDefID]) then
		watchedUnits[unitID]={lastupdate = spGetGameFrame(), delay = 5, udID = unitDefID, ut= unitTeam}
		ReclaimRepairResurrect(unitID, unitDefID, unitTeam)
    end
end
