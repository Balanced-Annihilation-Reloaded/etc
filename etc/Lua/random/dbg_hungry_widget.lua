function widget:GetInfo()
	return {
		name		= "Hungry Widget",
		desc		= "I eat your FPS and I like it",
		author		= "",
		date		= "",
		license		= "",
		layer		= 0,
		enabled		= true
	}
end

local iter = 1000

function widget:DrawScreen()
    for i = 1,iter do
        local tableCreationSucks = {"HELLO"}
    end
end

function widget:GameFrame(n)
    for i = 1,iter do
        local tableCreationSucks = {"HELLO AGAIN"}
    end
end

