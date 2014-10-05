function widget:GetInfo()
	return {
		name		= "Print Startpoints to File",
		desc		= "For use with FFA Startpouints; for map devs",
		author		= "",
		date		= "",
		license		= "",
		layer		= 0,
		enabled		= true
	}
end

local startpoints = {}

function widget:UnitCreated(uID)
    local x,y,z = Spring.GetUnitPosition(uID)
    startpoints[#startpoints+1] = {x=x,z=z}
end

function widget:GameFrame(n)
    -- save table to file 
    if n==30 then
        table.save(startpoints,"startpoints_"..Game.mapName..".lua","--"..Game.mapName)
    end
end

function widget:DrawScreen()
    --- displays numbers on screen to take a screenshot of
    for n,p in ipairs(startpoints) do
        local x,y = Spring.WorldToScreenCoords(p.x,Spring.GetGroundHeight(p.x,p.z),p.z)
        gl.Text(n,x,y,30)
    end
end