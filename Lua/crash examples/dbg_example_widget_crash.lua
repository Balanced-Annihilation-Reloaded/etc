function widget:GetInfo()
	return {
		name    = 'Example widget crash',
		desc    = 'Crashes',
		author  = 'Bluestone',
		date    = '',
		license = 'Horses',
		layer   = 0,
		enabled = false,
	}
end

local initTime 
function widget:Initialize()
    initTime = Spring.GetTimer()
end

function widget:Update()
    local curTime = Spring.GetTimer()
    if Spring.DiffTimers(curTime, initTime) > 0.5 then
        local crashMe = 0 + ZOMGIMNOTANUMBER
    end
end