function widget:GetInfo()
	return {
		name      = "Display aim pos",
		desc      = "Display aim pos",
		author    = "BD",
		date      = "-",
		license   = "WTFPL",
		layer     = 0,
		enabled   = false  --  loaded by default?
	}
end



function widget:DrawWorld()
	for _,unitID in pairs(Spring.GetAllUnits()) do
	local _,_,_,_,_,_,x,y,z = Spring.GetUnitPosition(unitID,true,true)
	 gl.PushMatrix()
		 gl.Translate(x,y,z)
		 gl.Billboard()
		 gl.Color(1,0,0)
		 gl.Rect(-1,-1,1,1)
	 gl.PopMatrix()
	end
end