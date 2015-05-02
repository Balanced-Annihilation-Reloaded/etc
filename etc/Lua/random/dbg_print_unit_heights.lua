function widget:GetInfo()
	return {
		name      = "Print Unit Heights",
		desc      = "",
		author    = "",
		date      = "",
		license   = "",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end


function widget:GameFrame(n)
	if (n%30==0) then
        local units = Spring.GetAllUnits()
        for _,uID in pairs(units) do
            local uDID = Spring.GetUnitDefID(uID)
            local name = UnitDefs[uDID].name
            local x,y,z = Spring.GetUnitPosition(uID)
            local gy = Spring.GetGroundHeight(x,z)
            Spring.Echo(name, y-gy)
        end
	end
end