function widget:GetInfo()
  return {
    name      = "Frame jitter",
    desc      = "logs frame jitter to file",
    author    = "Beherith - mysterme@gmail.com",
    date      = "2013 may",
    license   = "GNU GPL, v2 or later",
    layer     = 1000000, --last widget loaded
    enabled   = true  --  loaded by default?
  }
end

local timerold =0
local oldframe = 0
local badframes = 0
local startframe = 0

function widget:Initialize()
	startframe = Spring.GetGameFrame()
	oldframe = startframe
end

function widget:GameFrame(n)
	if n>oldframe then
		oldframe=n
	else
		return
	end
	if timerold==0 then
		timerold=Spring.GetTimer()
	end
	local timernew=Spring.GetTimer()
	local deltat=Spring.DiffTimers(timernew,timerold)
	if deltat <0.015 then
		badframes=badframes+1
		Spring.Echo(string.format('frame:%i 15ms > deltaT = %.1fms bad= %.2f',n,1000*deltat, (badframes*100)/(n - startframe) ))
	end
	if deltat > 0.05 then
		badframes=badframes+1
		Spring.Echo(string.format('frame:%i 50ms > deltaT = %.1fms bad= %.2f',n,1000*deltat, (badframes*100)/(n - startframe) ))
	end
	timerold=timernew
end
