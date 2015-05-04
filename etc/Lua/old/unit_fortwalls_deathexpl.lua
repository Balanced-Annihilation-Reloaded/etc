--features don't have death explosions but arm/corfort (which are units with isFeature=true) should have one
--so we spawn a mine and instantly self destruct it

function gadget:GetInfo()
  return {
    name      = "Fortification Wall Explosions",
    desc      = "creates an explosion when a fortification wall dies",
    author    = "Bluestone",
    date      = "Nov 2013",
    license   = "horse has fallen over",
    layer     = 0,
    enabled   = true
  }
end

if (not gadgetHandler:IsSyncedCode()) then return end

local armFortWallDefID = FeatureDefNames["armfort_fortification"].id
local coreFortWallDefID = FeatureDefNames["corfort_fortification_core"].id 
--the prefix to the feature names is because cor/armfort units instantly die when built and are replaced by a feature that's given these names

local explUnitDefID = UnitDefNames["armmine2"].id --we spawn a mine and then have it self d'ed on the next frame
local gaiaTeamID = Spring.GetGaiaTeamID()

local toKill = {}

function gadget:FeatureDestroyed(featureID, allyTeamID)
	local featureDefID = Spring.GetFeatureDefID(featureID)

	if featureDefID == armFortWallDefID or featureDefID == coreFortWallDefID then
		local x,y,z = Spring.GetFeaturePosition(featureID)
		local explUnitID = Spring.CreateUnit(explUnitDefID,x,y,z,"n",gaiaTeamID)
		--we can't use Spring.DestroyUnit here because 'recursion' is not allowed in FeatureDestroyed
		local frame = Spring.GetGameFrame() + 1
		if toKill[frame] == nil then toKill[frame] = {} end
		toKill[frame][#(toKill[frame])+1] = explUnitID
		--Spring.Echo("will kill " .. explUnitID) 
	end
end


function gadget:GameFrame(frame)
	if toKill[frame] then
		for _,unitID in pairs(toKill[frame]) do
			if Spring.ValidUnitID(unitID) then
				--Spring.Echo("killing " .. unitID)
				Spring.DestroyUnit(unitID, true, false)
			end
		end
	end
end



	


