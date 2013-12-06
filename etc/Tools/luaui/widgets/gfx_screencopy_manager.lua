function widget:GetInfo()
  return {
    name      = "Screencopy Manager",
    desc      = "Makes a copy of the screen to a texture to share to bloom, los and distortionfbo",
    author    = "Beherith",
    date      = "Nov 2013",
    license   = "GNU GPL, v2 or later",
    layer     = -1000000000,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local screenTexture = nil
local vsx =0 
local vsy =0
local lastupdate = 0


local glCopyToTexture = gl.CopyToTexture
local glCreateTexture = gl.CreateTexture
local glDeleteTexture = gl.DeleteTexture
local spGetDrawFrame  = Spring.GetDrawFrame


function widget:Initialize()
	Spring.Echo('Welcome to the fx_screencopy_manager!')
	if glCopyToTexture == nil then
		Spring.Echo('Sorry you are screwed with no glCopyToTexture support')
		return
	end
	screenTexture = gl.CreateTexture(vsx,vsy, {
		min_filter = GL.LINEAR,
		mag_filter = GL.LINEAR,
		wrap_s   = GL.CLAMP_TO_EDGE,
		wrap_t   = GL.CLAMP_TO_EDGE,
		})
	vsx,vsy,_,_=Spring.GetViewGeometry()
	widget:ViewResize(vsx,vsy)
	WG['screencopy_manager'] = {}
	WG['screencopy_manager'].GetScreenCopy = function(who)
		local df=Spring.GetDrawFrame()
		if screenTexture == nil then
			Spring.Echo('Creating new screenTexture')
			widget:ViewResize(vsx,vsy)
		end
		if lastupdate < spGetDrawFrame() then
			lastupdate=spGetDrawFrame() 
			glCopyToTexture(screenTexture, 0, 0, 0, 0, vsx, vsy, nil,0)
			Spring.Echo('gfx_screencopy_manager updated screencopy for',who)
		end
		Spring.Echo('returning',screenTexture,' for ', who,df) 
		return screenTexture
	end
end

function widget:ViewResize(viewSizeX, viewSizeY)
	Spring.Echo('fx_screencopy_manager:viewresize')
	vsx = viewSizeX
	vsy = viewSizeY
	if screenTexture then
		glDeleteTexture(screenTexture)
	end
	screenTexture = gl.CreateTexture(vsx,vsy, {
		min_filter = GL.LINEAR,
		mag_filter = GL.LINEAR,
		wrap_s   = GL.CLAMP_TO_EDGE,
		wrap_t   = GL.CLAMP_TO_EDGE,
		})
end

function widget:GameFrame(n)
	if n%30==0 then
		Spring.Echo('gfx_screencopy_manager widget:GameFrame')
	end
	if n>lastupdate+30 and screenTexture  then
		glDeleteTexture(screenTexture)
		Spring.Echo('Deleting Screencopy to free GPU ram',screenTexture)
		screenTexture = nil
	end
end



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
