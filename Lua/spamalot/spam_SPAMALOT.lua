--Gadget for stress/unitscript testing, made by Bluestone
--code deliberately not optimized!

--TLDRSPAM:
--Set enabled to true and go

--INSTRUCTIONSPAM:
--Set max units to at least 2000
--Set game-end mode to continue even if all coms/etc are dead
--Make sure you have moduictrl on
--Remove or turn off all game end gadgetry 
--Remove any unsynced lua that (without any user input) creates keyboard/mouse input, destroys units/features and/or gives orders to units
--(0) Set mode (fight=true/false) below
--(1) Load game, force start with alt+f (no need to ready)
--(2) DONT TOUCH ANYTHINGSPAM!
--(3) Game will run for 3.00 minutes of ingame time
--(4) Once game is over, stats are printed to chat/infolog

function gadget:GetInfo()
	return {
		name      = "SPAMSPAMSPAM",
		desc      = "SHUT THAT BLOODY BOUZOUKI UP!",
		author    = "Camembert, perhaps?",
		date      = "SPAM/SPAM/SPAM/LOVELYSPAM",
		version   = "v0.1.ham.and.jam.and...",
		license   = "GPL spam v3.0 or later",
		layer     = -1, 
		enabled   = true,
		spam 	  = spam,
	}
end


if gadgetHandler:IsSyncedCode() then
-------------------------------------
----------------SYNCED---------------

--mode
--fight=false simulates unit movement only, fight=true simulates a full battle 
local fight = true


--vars
--some of these are duplicated in unsynced
local unitSpamD = 2  --initial unit density (units per map square)
local uSD = unitSpamD
local runSteps = 2 
local testTime = 1 --minutes each step of settings is run for
local numX = Game.mapX-1
local numZ = Game.mapY-1
local mapX = 512*numX
local mapZ = 512*numZ
local orderRate = 20 --average time an order is kept before being replaced
local pAirUnit = 0.0 --proportion of aircraft
local cmdTable = {CMD.MOVE, CMD.FIGHT, CMD.PATROL} 
local over = false
local unitDefIDTable = {}
local maxUnitDefIDs


--------------------------------------
----------------Funcs-----------------

function FillUnitDefTable()
	local m = 0
	for	k,_ in pairs(UnitDefs) do
		m = m + 1
		unitDefIDTable[m] = k
	end
	maxUnitDefIDs = m
end

function RandomCoord()
	local x = math.random() * mapX
	local z = math.random() * mapZ
	return x,z
end

function RandomSquare()
	local x = math.random(numX)
	local z = math.random(numY)
	return x,z
end

function RandomCoordInSquare(sx,sz)
	local x = 512 * sx + math.random(512)
	local z = 512 * sz + math.random(512)
	return x,z
end

function RandomOrder()
	local n = math.random(3)
	return cmdTable[n]
end

function RandomOrderToUnit(unitID)
	local x,z = RandomCoord()
	local id = RandomOrder()
	if Spring.ValidUnitID(unitID) then
		y = Spring.GetGroundHeight(x,z)
		Spring.GiveOrderToUnit(unitID,id,{x,y,z},{"meta"})
	end
end

function PickUnitDefID(x,z)
	local unitDefID	
	local unitDef
	local unitDefIDbackup				
	local isWet = (Spring.GetGroundHeight(x,z) < -15)
	local needAirUnit = (math.random() < pAirUnit)
	local isAirUnit, airTest, isWaterUnit, waterTest, moveTest
	local testNum = math.random(maxUnitDefIDs)
	--choose random unitDef
	for try = 0,500 do
		testNum = testNum + 1
		if testNum >= maxUnitDefIDs then
			testNum = 1
		end
		unitDef = UnitDefs[unitDefIDTable[testNum]]
		--test to see if its suitable
		--Spring.Echo(testNum, unitDefIDTable[testNum], maxUnitDefIDs)
		if (not unitDef.isFactory) then
			isAirUnit = unitDef.canFly  
			airTest = (not needAirUnit) or (needAirUnit and isAirUnit)
			isWaterUnit = (unitDef.minWaterDepth and unitDef.minWaterDepth >= 10) 
			waterTest = ((not isWet) and (not isWaterUnit)) or (isWet and isWaterUnit) or isAirUnit
			moveTest = fight or (unitDef.speed and unitDef.speed > 0)
			--Spring.Echo(airTest, waterTest, moveTest)
			if airTest and waterTest and moveTest then
				unitDefID = unitDef.id
				break --suitable
			else
				if not unitDefIDbackup then
					unitDefIDbackup = unitDef.id
				end
			end
		end
	end
	--failsafe
	if not unitDefID then
		Spring.Echo("WARNING: uDID sampling failed!")
		unitDefID = unitDefIDbackup
	end 
	return unitDefID
end

function SpawnUnitInSquare(i,j)
	--choose where to spawn & what team
	local x,z = RandomCoordInSquare(i,j)
	local team 
	if fight then
		team = math.random(2) - 1 --team 0 or team 1
	else
		team = 0 --gaia only
	end

	--pick suitable random unitDefID
	local unitDefID = PickUnitDefID(x,z)

	--spawn
	if unitDefID then
		local y = math.max(Spring.GetGroundHeight(x,z),0)
		local face = RandomFacing()
		Spring.CreateUnit(unitDefID,x,y+1,z,face,team)
		--can't give order until next frame
	end
end

function RandomFacing()
	local n = math.random(4)
	if n==1 then return "north" end
	if n==2 then return "east" end
	if n==3 then return "west" end
	if n==4 then return "south" end
end

function GiveOrdersToAll()
	local units = Spring.GetAllUnits()
	for _,unitID in pairs(units) do
		RandomOrderToUnit(unitID)
	end
end

-----------------------------------------------
-----------------Calls-------------------------

function gadget:GameStart()

	FillUnitDefTable()

	Spring.SendCommands("cheat")
	Spring.SendCommands("globallos")
	Spring.SendCommands("resign")
	Spring.Echo("SHUT THAT BLOODY BOUZOUKI UP!")

	if Game.maxUnits < 2000 then
		Spring.Echo("Error: maxUnits is too low for spam_SPAMALOT, please raise to >2000")
		Spring.GameOver()
	end
	
	for i=0,numX do
	for j=0,numZ do
		for k=1,uSD do
			SpawnUnitInSquare(i,j)
		end
	end
	end
	
end

function Over()
	over = true
	
	--remove all units
	local units = Spring.GetAllUnits()
	for _,unitID in pairs(units) do
		Spring.DestroyUnit(unitID, false, true)
	end

	SendToUnsynced("PrintInfo")
	Spring.GameOver({})	
end
	

local i,j = 0,0
	
function gadget:GameFrame(n)

	--end
	if n==(30*testTime*60*runSteps) then
		Over()
	end

	--don't run if game is over
	if over then return end

	--give orders to all units on frame 1
	if n==1 then
		GiveOrdersToAll()
	end
		
	--increase spam every minute
	if n%(30*testTime*60)==0 and n<(30*testTime*60*runSteps) then 
		if n>0 then
			uSD = uSD + 1
			if not fight then 
				uSD = uSD + 1 --twice as much stuff if no fighting
			end
		end
		Spring.Echo("Spam density " .. uSD)
	end
	
	
	--update
	--current square is (i,j)
	local units = Spring.GetUnitsInRectangle(i*512,j*512,(i+1)*512,(j+1)*512)
	
	--decide how many units to kill
	local toDestroy
	if #units > uSD + 1 then
		toDestroy = #units - uSD
	else
		toDestroy = 0
	end
	
	--decide how many units to spawn
	local toSpawn 
	if #units <= uSD then
		toSpawn = uSD - #units 
	else
		toSpawn = 0
	end
	
	--spawn units
	for k=1,toSpawn do
		SpawnUnitInSquare(i,j)
	end
	
	
		--killing & orders
	for _,unitID in pairs(units) do
		--orders
		if Spring.GetCommandQueue(unitID, -1, false) == 0 then --no queue
			RandomOrderToUnit(unitID)
		else
			local ranA = math.random(orderRate)
			if ranA == 1 then --issue a new order to unit on average once every 20 secs
				RandomOrderToUnit(unitID)
			end
		end
		
		--killing
		local p = math.random()
		local pDie = 0.25
		if p < pDie and Spring.ValidUnitID(unitID) and toDestroy > 0 then
			Spring.DestroyUnit(unitID, false, true) 
			toDestroy = toDestroy - 1
		end
	end
	

	--increment square
	i=i+1
	if i>numX then 
		i=0 
		j=j+1
	end
	if j>numZ then j=0 end
	
end	
	
	
	
function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
	if UnitDefs[unitDefID].customParams.iscommander == "1" then 
		return 0 --coms cant be killed (prevents game end)
	end
end	
	
	
	
	
	
	
	
else
-------------------------------------
--------------UNSYNCED---------------

local camMoveTime = 4 -- in seconds
local moved = false
local prevCamFrame = 0
local prevFpsFrame = 0
local sumSpeed = 0
local numSum = 0
local sumFPS = 0
local over = false
local fpsSamples = {}

local runSteps = 3 
local testTime = 1
local numX = Game.mapX-1
local numZ = Game.mapY-1
local mapX = 512*numX
local mapZ = 512*numZ

function RandomCoord()
	local x = math.random() * mapX
	local z = math.random() * mapZ
	return x,z
end

function gadget:Initialize()
	gadgetHandler:AddSyncAction("PrintInfo", PrintInfo)
end

function PrintInfo()
	over = true
	
	--gamespeed
	local avSpeed = sumSpeed / numSum
	local version = Game.version
	local buildFlags = Game.buildFlags
	Spring.Echo("Spam complete")
	Spring.Echo("Spring version is " .. Game.version .. "(" .. buildFlags .. ")")
	Spring.Echo("Average running speed was " .. avSpeed)
	
	--fps
	local tot = 0
	for _,val in pairs(fpsSamples) do
		tot = tot + val
	end
	local avFPS = tot/(testTime*runSteps*60)
	Spring.Echo("Average FPS was ".. avFPS)
	
end


function gadget:DrawScreen()

	--do camera movement
	local frame = Spring.GetGameFrame()
	
	if not frame or frame < 1 then return end
	if over then return end
	
	--attempt to take one sample per second
	if frame >= 30 + prevFpsFrame and frame >= 1 then
		--fps
		local fps = Spring.GetFPS()
		fpsSamples[frame] = fps
		prevFpsFrame = frame
		--gamespeed
		local _,curSpeed = Spring.GetGameSpeed()
		sumSpeed = sumSpeed + curSpeed
		numSum = numSum + 1
	end
	
		

		
	--timer for move camera
	if moved and frame >= prevCamFrame + 30*camMoveTime then
		moved = false
		prevCamFrame = frame
	end
	
	--move camera
	if (not moved) then
		local camState = Spring.GetCameraState()
		camState.mode = 1 --overhead camera
		if camState.height ~= 2000 then
			camState.height = 2000
		else
			camState.height = 8000
		end
		local x,z = RandomCoord()
		camState.px = x
		camState.pz = z
		local moveTime = math.random() * (camMoveTime/2) --in seconds
		Spring.SetCameraState(camState,moveTime)
		moved = true
	end

end
	

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
end



