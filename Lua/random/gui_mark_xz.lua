function widget:GetInfo()
    return {
        name      = "Mark XZ",
        version   = "0",
        desc      = "Press m to place a marker on the map at current mouse pos with x,z coords",
        author    = "Pope Brian IX",
        date      = "2000 BC",
        license   = "Je suis une pamplemousse",
        layer     = 0,
        enabled   = true
	}
end 

include('keysym.h.lua')

function widget:KeyPress(key,_,_)
    if key==KEYSYMS.M then
        local mx,my,_,_,_ = Spring.GetMouseState()
        local t,l = Spring.TraceScreenRay(mx,my,false,false,false,true)
        if t=="ground" then
            Spring.MarkerAddPoint(l[1],l[2],l[3],tostring(math.floor(l[1]))..", "..tostring(math.floor(l[3])))
        end
    end
end


