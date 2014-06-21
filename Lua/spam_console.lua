function widget:GetInfo()
	return {
		name      = "Console spammer",
		desc      = "Spams console",
		author    = "Bluestone",
		date      = "Horses",
		license   = "",
		layer     = math.pi,
		enabled   = true
	}
end


function widget:DrawWorld()
    n = math.random(1,4)
    if n==1 then
        Spring.Echo("Lovely spam!")
    elseif n==2 then
        Spring.Echo("Wonderful spam")
    elseif n==1 then
        Spring.Echo("Glorious spam")
    else
        Spring.Echo("spam")
    end
end

