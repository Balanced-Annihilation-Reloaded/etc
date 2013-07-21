--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GetInfo()
  return {
    name      = "Deferred rendering",
    version   = 3,
    desc      = "Deferred rendering widget",
    author    = "beherith",
    date      = "2013 july",
    license   = "GNU GPL, v2 or later",
    layer     = -1000000000,
    enabled   = true
  }
end


enabled = true

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Automatically generated local definitions

local GL_MODELVIEW           = GL.MODELVIEW
local GL_NEAREST             = GL.NEAREST
local GL_ONE                 = GL.ONE
local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA
local GL_PROJECTION          = GL.PROJECTION
local GL_QUADS               = GL.QUADS
local GL_SRC_ALPHA           = GL.SRC_ALPHA
local glBeginEnd             = gl.BeginEnd
local glBlending             = gl.Blending
local glCallList             = gl.CallList
local glColor                = gl.Color
local glColorMask            = gl.ColorMask
local glCopyToTexture        = gl.CopyToTexture
local glCreateList           = gl.CreateList
local glCreateShader         = gl.CreateShader
local glCreateTexture        = gl.CreateTexture
local glDeleteShader         = gl.DeleteShader
local glDeleteTexture        = gl.DeleteTexture
local glDepthMask            = gl.DepthMask
local glDepthTest            = gl.DepthTest
local glGetMatrixData        = gl.GetMatrixData
local glGetShaderLog         = gl.GetShaderLog
local glGetUniformLocation   = gl.GetUniformLocation
local glGetViewSizes         = gl.GetViewSizes
local glLoadIdentity         = gl.LoadIdentity
local glLoadMatrix           = gl.LoadMatrix
local glMatrixMode           = gl.MatrixMode
local glMultiTexCoord        = gl.MultiTexCoord
local glPopMatrix            = gl.PopMatrix
local glPushMatrix           = gl.PushMatrix
local glResetMatrices        = gl.ResetMatrices
local glTexCoord             = gl.TexCoord
local glTexture              = gl.Texture
local glRect                 = gl.Rect
local glUniform              = gl.Uniform
local glUniformMatrix        = gl.UniformMatrix
local glUseShader            = gl.UseShader
local glVertex               = gl.Vertex
local glTranslate            = gl.Translate
local spEcho                 = Spring.Echo
local spGetCameraPosition    = Spring.GetCameraPosition
local spGetCameraVectors     = Spring.GetCameraVectors
local spGetDrawFrame         = Spring.GetDrawFrame

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Extra GL constants
--

local GL_DEPTH_BITS = 0x0D56

local GL_DEPTH_COMPONENT   = 0x1902
local GL_DEPTH_COMPONENT16 = 0x81A5
local GL_DEPTH_COMPONENT24 = 0x81A6
local GL_DEPTH_COMPONENT32 = 0x81A7


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Config

local fogHeight    = 1500
local fogColor  = { 0.8, 0.8, 0.9 }
local fogAtten  = 0.002 --0.08
local fr,fg,fb     = unpack(fogColor)

local debugGfx  =false --or true

local GLSLRenderer = true




--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local gnd_min, gnd_max = Spring.GetGroundExtremes()
if (gnd_min < 0) then gnd_min = 0 end
if (gnd_max < 0) then gnd_max = 0 end
local vsx, vsy
local ivsx = 1.0 
local ivsy = 1.0 
local mx = Game.mapSizeX
local mz = Game.mapSizeZ
local fog

local depthShader
local depthTexture

local invrxloc = nil
local invryloc = nil
local lightposloc = nil
local uniformEyePos
local uniformViewPrjInv
local uniformViewPrj
local lights = {}
-- parameters for each light:
-- RGBA: strength in each color channel, radius in elmos.
-- pos: xyz positions

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- fog rendering



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--Light falloff functions: http://gamedev.stackexchange.com/questions/56897/glsl-light-attenuation-color-and-intensity-formula

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:ViewResize()
	vsx, vsy = gl.GetViewSizes()
	ivsx = 1.0 / vsx --we can do /n here!
	ivsy = 1.0 / vsy
	if (Spring.GetMiniMapDualScreen()=='left') then
		vsx=vsx/2;
	end
	if (Spring.GetMiniMapDualScreen()=='right') then
		vsx=vsx/2
	end

	if (depthTexture) then
		glDeleteTexture(depthTexture)
	end

	depthTexture = glCreateTexture(vsx, vsy, {
		format = GL_DEPTH_COMPONENT24,
		min_filter = GL_NEAREST,
		mag_filter = GL_NEAREST,
	})

	if (depthTexture == nil) then
		spEcho("Removing fog widget, bad depth texture")
		widgetHandler:Removewidget()
	end
end

widget:ViewResize()


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local vertSrc = [[

  void main(void)
  {
    gl_TexCoord[0] = gl_MultiTexCoord0;
    gl_Position    = gl_Vertex;
  }
]]

local fragSrc = ([[
  const float fogAtten  = %f;
  const float fogHeight = %f;
  const vec3 fogColor   = vec3(%f, %f, %f);

  uniform float inverseRX;
  uniform float inverseRY;
  uniform sampler2D tex0;
  //uniform sampler2D lighttex;
  uniform vec3 eyePos;
  uniform vec4 lightpos;
  uniform vec4 lightcolor;
  uniform mat4 viewProjectionInv;
  uniform mat4 viewProjection;

  void main(void)
  {
    //http://stackoverflow.com/questions/5281261/generating-a-normal-map-from-a-height-map
    // float up    = texture2D( tex0, gl_TexCoord[0].st + vec2(0 , inverseRY) ).x;
    // float down  = texture2D( tex0, gl_TexCoord[0].st + vec2(0 ,-inverseRY) ).x;
    // float left  = texture2D( tex0, gl_TexCoord[0].st + vec2(inverseRX , 0) ).x;
    // float right = texture2D( tex0, gl_TexCoord[0].st + vec2(-inverseRX, 0) ).x;
	// float z     = texture2D( tex0, gl_TexCoord[0].st ).x;
	// float y = up - down;
	// float x = left - right;
	vec2 up2	= gl_TexCoord[0].st + vec2(0 , inverseRY);
	vec4 up4	= vec4(vec3(up2.xy, texture2D( tex0,up2 ).x) * 2.0 - 1.0 ,1.0);
	up4 = viewProjectionInv * up4;
	up4.xyz = up4.xyz / up4.w;
	
	vec2 right2	= gl_TexCoord[0].st + vec2(inverseRY , 0);
	vec4 right4	= vec4(vec3(right2.xy, texture2D( tex0,right2 ).x) * 2.0 - 1.0 ,1.0);
	right4 = viewProjectionInv * right4;
	right4.xyz = right4.xyz / right4.w;
	
	vec4 here4	= vec4(vec3(gl_TexCoord[0].st, texture2D( tex0,gl_TexCoord[0].st ).x) * 2.0 - 1.0 ,1.0);
	here4 = viewProjectionInv * here4;
	here4.xyz = here4.xyz / here4.w;
	
	//up4.xyz = up4.xyz -here4.xyz;
	//right4.xyz = right4.xyz -here4.xyz;
	
	vec4 herenormal4;
	herenormal4.xyz = -1.0*normalize(cross( up4.xyz - here4.xyz, right4.xyz - here4.xyz));
	float dist_light_here = length(lightpos.xyz - here4.xyz);
	float cosphi = max(0.0 , dot (herenormal4.xyz, lightpos.xyz - here4.xyz) / dist_light_here);
	//float attentuation = 1.0 / ( 1.0 + 1.0*dist + 1.0 *dist*dist); // alternative attentuation function
	float attentuation =  saturate( ( 1.0 - (dist_light_here*dist_light_here)/(lightpos.w*lightpos.w)) );
	attentuation *=attentuation;
	// vec4 eyenormal=vec4((normalize(vec3(x,y,(inverseRX+inverseRY)*0.25)))*0.5+vec3(0.5,0.5,0.5),0.9); //eye space normals suck!
	// vec4 worldnormal4 = viewProjectionInv * eyenormal;
	// vec3 worldnormal3 = worldnormal4.xyz / worldnormal4.w;
	
	//gl_FragColor=vec4(normalize(herenormal4.xyz), cosphi*(lightpos.w/(dist_light_here*dist_light_here)));
	gl_FragColor=vec4(lightcolor.rgb, cosphi*attentuation);
	//gl_FragColor=vec4(abs(herenormal4.x),abs(herenormal4.y),abs(herenormal4.z), 0.8);
	
	//gl_FragColor = vec4(fract(here4.x/50),fract(here4.y/50),fract(here4.z/50), 0.5);
	return;
	
	
	/*vec4 ppos;
	ppos.a=1;
	ppos.xyz = vec3(gl_TexCoord[0].st,0 )* 2.0 - 1; //point pos in eye space
	vec4 worldPos4 = viewProjectionInv * ppos; // position of the point in the world
	 vec3 worldPos  = worldPos4.xyz / worldPos4.w; 
	//EYE SPACE it gones from [-1,1] in all axes+
	
	
	
	
	
	gl_FragColor=vec4(fract(worldPos.x/50),fract(worldPos.y/50),worldPos.z, 0.9);;
	//gl_FragColor=vec4(fract(z),z*z*z,0, 0.8);
	//gl_FragColor=vec4(ppos);
	
	return;
	vec4 lighteye4 = viewProjection * lightpos;
	vec3 lighteye  = lighteye4.xyz / lighteye4.w; //div by weight, dunno if needed?
	
	
	//vec4 worldPos4 = viewProjectionInv * ppos; // position of the point in the world
   // vec3 worldPos  = worldPos4.xyz / worldPos4.w; //div by weight, true world pos
	
	
	eyenormal=viewProjectionInv*eyenormal;
	eyenormal.xyz=(eyenormal.xyz/eyenormal.w);
	float coslight=dot(eyenormal.xyz, lightpos.xyz-worldPos.xyz)/(length(lightpos.xyz-worldPos.xyz));
	coslight=max(0,coslight);
	
	
	float lightintens=100/length(worldPos.xyz-lightpos.xyz);

	
	gl_FragColor=vec4(1,1,1,coslight);
	//gl_FragColor=vec4(1,1,1,coslight);
	//gl_FragColor=(worldPos.xyz,1);
	//gl_FragColor = vec4(fract(worldPos.x/50),fract(worldPos.y/50),fract(worldPos.z/50), 0.5);
	//gl_FragColor = vec4(fract(lightpos.x/50),fract(lightpos.y/50),fract(lightpos.z/50), 0.5);
	return;
	

  
  
    z = texture2D(tex0, gl_TexCoord[0].st).x; //returns depth buffer in eye space

    //ppos.xyz = vec3(gl_TexCoord[0].st, z) * 2. - 1.; //point pos in eye space
    ppos.xyz = vec3(gl_TexCoord[0].st, z)* 2.0 - 1; //point pos in eye space
    ppos.a   = 1.;

    //vec4 worldPos4 = viewProjectionInv * ppos; // position of the point in the world

//    vec3 worldPos  = worldPos4.xyz / worldPos4.w; //div by weight, true world pos
    vec3 toPoint   = worldPos - eyePos; //vector pointing from eye to world coord

    vec3 debugColor =worldPos4.xyz;
    gl_FragColor = vec4(fract(worldPos.x/50),fract(worldPos.y/50),fract(worldPos.z/50), 0.5);
    return; // BAIL
	*/
  }
]]):format(fogAtten, fogHeight, fogColor[1], fogColor[2], fogColor[3])



if (debugGfx) then
  fragSrc = '#define DEBUG_GFX\n' .. fragSrc
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	if (enabled) then
		if ((not forceNonGLSL) and Spring.GetMiniMapDualScreen()~='left') then --FIXME dualscreen
			if (not glCreateShader) then
				spEcho("Shaders not found, reverting to non-GLSL widget")
				GLSLRenderer = false
			else
				depthShader = glCreateShader({
					vertex = vertSrc,
					fragment = fragSrc,
					uniformInt = {
						tex0 = 0,
						uniformFloat = {inverseRX},
						uniformFloat = {inverseRY},
					},
				})

				if (not depthShader) then
					spEcho(glGetShaderLog())
					spEcho("Bad shader, reverting to non-GLSL widget.")
					GLSLRenderer = false
				else
				
					invrxloc=glGetUniformLocation(depthShader, "inverseRX")
					invryloc=glGetUniformLocation(depthShader, "inverseRY")
					lightposloc=glGetUniformLocation(depthShader, "lightpos")
					lightcolorloc=glGetUniformLocation(depthShader, "lightcolor")
					uniformEyePos       = glGetUniformLocation(depthShader, 'eyePos')
					uniformViewPrjInv   = glGetUniformLocation(depthShader, 'viewProjectionInv')
					uniformViewPrj   = glGetUniformLocation(depthShader, 'viewProjection')
				end
			end
		else
			GLSLRenderer = false
		end
	else
		widgetHandler:Removewidget()
	end
end


function widget:Shutdown()
  if (GLSLRenderer) then
    glDeleteTexture(depthTexture)
    if (glDeleteShader) then
      glDeleteShader(depthShader)
    end
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local dl

local function DrawFogNew()
	--//FIXME handle dualscreen correctly!
	-- copy the depth buffer

	--glCopyToTexture(depthTexture, 0, 0, 0, 0, vsx/2, vsy/2 ) --FIXME scale down?
	glCopyToTexture(depthTexture, 0, 0, 0, 0, vsx, vsy ) --FIXME scale down?
	
	-- setup the shader and its uniform values
	glBlending("alpha_add")
	glUseShader(depthShader)

	-- set uniforms
	local cpx, cpy, cpz = spGetCameraPosition()
	glUniform(uniformEyePos, cpx, cpy, cpz)
	glUniform(invrxloc, ivsx)
	glUniform(invryloc, ivsy)
	-- glUniform(lightposloc, 500,200,500,1) --IN world space
	f= Spring.GetGameFrame()
	f=f/50
	glUniform(lightposloc, 500+300*math.sin(f),150,500+300*math.cos(f),500.0) --IN world space
	glUniform(lightcolorloc, 1,1,1,1) --IN world space

	glUniformMatrix(uniformViewPrjInv,  "viewprojectioninverse")
	glUniformMatrix(uniformViewPrj,  "viewprojection")

	glTexture(0, depthTexture)
	glTexture(0, false)
	gl.TexRect(-1, -1, 1, 1, 0, 0, 1, 1) -- screen size go from -1,-1 to 1,1; uvs go from 0,0 to 1,1
	
	--gl.TexRect(0.5,0.5, 1, 1, 0.5, 0.5, 1, 1)

	--// finished
	glUseShader(0)

	glBlending(false)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:DrawWorld()
	if (GLSLRenderer) then
		--if (debugGfx) then glBlending(GL_SRC_ALPHA, GL_ONE) end
		DrawFogNew()
		--if (debugGfx) then glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA) end
	else
		--Spring.Echo('failed to use GLSL shader')
	end
end



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
