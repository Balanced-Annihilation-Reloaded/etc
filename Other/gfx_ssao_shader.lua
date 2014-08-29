--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GetInfo()
  return {
    name      = "SSAO shader widget",
    version   = 3,
    desc      = "Draws nice SSAO",
    author    = "beherith",
    date      = "2014 feb",
    license   = "CC BY ND",
    layer     = 1,
    enabled   = false
  }
end


enabled = true

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Config



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

local debugGfx  =false --or true
local GLSLRenderer = true
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local gnd_min, gnd_max = Spring.GetGroundExtremes()
if (gnd_min < 0) then gnd_min = 0 end
if (gnd_max < 0) then gnd_max = 0 end
local vsx, vsy
local mx =math.pow(2, math.ceil(math.log(Game.mapSizeX)/math.log(2)))-- Game.mapSizeX
local mz =math.pow(2, math.ceil(math.log(Game.mapSizeZ)/math.log(2)))-- Game.mapSizeZ

local ssaoShader


local uniformEyePos
local uniformViewPrjInv
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:ViewResize()
	-- vsx, vsy = gl.GetViewSizes()
	if (Spring.GetMiniMapDualScreen()=='left') then
		vsx=vsx/2;
	end
	if (Spring.GetMiniMapDualScreen()=='right') then
		vsx=vsx/2
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
 
uniform sampler2D modeldepthtex;
uniform sampler2D mapdepthtex;
uniform sampler2D modelnormaltex;
uniform sampler2D mapnormaltex;
 
uniform mat4 viewProjectionInv;
 
uniform float distanceThreshold;
uniform vec2 filterRadius;
#define sample_count 16
uniform vec2 poisson16[sample_count] = vec2[sample_count](    // These are the Poisson Disk Samples
                                vec2( -0.94201624,  -0.39906216 ),
                                vec2(  0.94558609,  -0.76890725 ),
                                vec2( -0.094184101, -0.92938870 ),
                                vec2(  0.34495938,   0.29387760 ),
                                vec2( -0.91588581,   0.45771432 ),
                                vec2( -0.81544232,  -0.87912464 ),
                                vec2( -0.38277543,   0.27676845 ),
                                vec2(  0.97484398,   0.75648379 ),
                                vec2(  0.44323325,  -0.97511554 ),
                                vec2(  0.53742981,  -0.47373420 ),
                                vec2( -0.26496911,  -0.41893023 ),
                                vec2(  0.79197514,   0.19090188 ),
                                vec2( -0.24188840,   0.99706507 ),
                                vec2( -0.81409955,   0.91437590 ),
                                vec2(  0.19984126,   0.78641367 ),
                                vec2(  0.14383161,  -0.14100790 )
                               );
 
//vec3 decodeNormal(in vec2 normal)
//{
    // restore normal

//    return restoredNormal;
//}
 
vec3 calculatePosition(in vec4 map_pos)
{
    // restore position

    vec4 calc_map_pos=viewProjectionInv * map_pos;
	calc_map_pos.xyz = calc_map_pos.xyz / calc_map_pos.w;
	
    return calc_map_pos.xyz;
}
 
void main(void)
{
	distanceThreshold=10;
	filterRadius=vec2(0.02,0.02);
    // reconstruct position from depth, USE YOUR CODE HERE
	
	vec4 mappos4 =vec4(vec3(gl_TexCoord[0].st, texture2D( mapdepthtex,gl_TexCoord[0].st ).x) * 2.0 - 1.0 ,1.0);
	vec4 modelpos4 =vec4(vec3(gl_TexCoord[0].st, texture2D( modeldepthtex,gl_TexCoord[0].st ).x) * 2.0 - 1.0 ,1.0);
	
	
    // get the view space normal, USE YOUR CODE HERE
	vec4 map_normals4= texture2D( mapnormaltex,gl_TexCoord[0].st ) *2.0 -1.0;
	vec4 model_normals4= texture2D( modelnormaltex,gl_TexCoord[0].st ) *2.0 -1.0;
	
	float mapfragment=1.0;
	if ((mappos4.z-modelpos4.z)> 0.0) { // this means we are processing a model fragment, not a map fragment
		mappos4 = modelpos4;
		map_normals4=model_normals4;
		mapfragment=0.0;
	}

	vec3 viewPos = calculatePosition(mappos4);
	
	//time to convert normal to screen-space normal:
	
	//map_normals4=mix(map_normals4, model_normals4, 1.0-mapfragment);
	//map_normals4=vec4(0,0,1,1);
	
    //vec2 normalXY = texture(normalTexture, gl_TexCoord[0].st).xy * 2.0 - 1.0;
    //vec3 viewNormal = decodeNormal(normalXY);
	
	
	//WORLDPOS debugging output, displays a 100 elmo grid on the world pos
	//gl_FragColor = vec4(fract(viewPos.x*0.01),fract(viewPos.y*0.01),fract(viewPos.z*0.01),1);
	
	
	//World-space normals debugging output:
	gl_FragColor = vec4(map_normals4.xyz,1);
	return;
	
    float ambientOcclusion = 0;
    // perform AO
    for (int i = 0; i < 16; ++i)
    {
        // sample at an offset specified by the current Poisson-Disk sample and scale it by a radius (has to be in Texture-Space)
        //vec2 sampleTexCoord = gl_TexCoord[0].st + (poisson16[i] * (filterRadius));
        //float sampleDepth = texture(depthTexture, sampleTexCoord).r;
        //vec3 samplePos = calculatePosition(sampleTexCoord, sampleDepth * 2 - 1);
		
		vec2 sampleTexCoord = gl_TexCoord[0].st + (poisson16[i] * (filterRadius));
		vec4 sample_mappos4 =vec4(vec3(gl_TexCoord[0].st, texture2D( mapdepthtex,sampleTexCoord ).x) * 2.0 - 1.0 ,1.0);
		vec4 sample_modelpos4 =vec4(vec3(gl_TexCoord[0].st, texture2D( modeldepthtex,sampleTexCoord ).x) * 2.0 - 1.0 ,1.0);
		float sample_mapfragment=1.0;
		if ((sample_mappos4.z-sample_modelpos4.z)> 0.0) { // this means we are processing a model fragment, not a map fragment
			sample_mappos4 = sample_modelpos4;
			sample_mapfragment=0.0;
		}
		vec3 samplePos = calculatePosition(sample_mappos4);
		
		
		
        vec3 sampleDir = normalize(samplePos - viewPos);
 
        // angle between SURFACE-NORMAL and SAMPLE-DIRECTION (vector from SURFACE-POSITION to SAMPLE-POSITION)
        float NdotS = max(dot(map_normals4.xyz, sampleDir), 0);
        // distance between SURFACE-POSITION and SAMPLE-POSITION
        float VPdistSP = distance(viewPos, samplePos);
 
        // a = distance function
        float a = 1.0 - smoothstep(distanceThreshold, distanceThreshold * 2, VPdistSP);
        // b = dot-Product
        float b = NdotS;
 
        ambientOcclusion += (a * b);
    }
	ambientOcclusion =ambientOcclusion / sample_count;
    gl_FragColor = vec4(ambientOcclusion,0,ambientOcclusion,0.5);
    gl_FragColor = vec4(0,0,0, 1.0 - (ambientOcclusion));
  }
]]):format(mx,mz)



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
				ssaoShader = glCreateShader({
					vertex = vertSrc,
					fragment = fragSrc,
					uniformInt = {
						modeldepthtex = 0,
						mapdepthtex = 1,
						modelnormaltex = 2, 
						mapnormaltex = 3,
					},
				})

				if (not ssaoShader) then
					spEcho(glGetShaderLog())
					spEcho("Bad shader, reverting to non-GLSL widget.")
					GLSLRenderer = false
				else
					uniformViewPrjInv   = glGetUniformLocation(ssaoShader, 'viewProjectionInv')
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

	Spring.Echo('Turning off SSAO widget')

	if (glDeleteShader) then
		glDeleteShader(ssaoShader)
	end

end

local dl

local function DrawLOS()
	--//FIXME handle dualscreen correctly!
	-- copy the depth buffer
	gl.Color(1,1,1,1)
	--glCopyToTexture(depthTexture, 0, 0, 0, 0, vsx, vsy ) --FIXME scale down?
	
	-- setup the shader and its uniform values
	glUseShader(ssaoShader)

	-- set uniforms
	glUniformMatrix(uniformViewPrjInv,  "viewprojectioninverse")

	if (not dl) then
		Spring.Echo('Creating SSAO display list')
		dl = gl.CreateList(function()
			-- render a full screen quad
			
			glTexture(0 , "$model_gbuffer_zvaltex")
			glTexture(1 , "$map_gbuffer_zvaltex")
			glTexture(2 , "$model_gbuffer_normtex")
			glTexture(3 , "$map_gbuffer_normtex")
			
			gl.TexRect(-1, -1, 1, 1, 0, 0, 1, 1)

			--// finished
			glUseShader(0)
		end)
	end
	glCallList(dl)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local status = true

function widget:DrawWorld()
	gf=Spring.GetGameFrame()
	--Spring.Echo(status,GLSLRenderer)
	if status then
		if (GLSLRenderer) then
			DrawLOS()
		else
			--Spring.Echo('failed to use GLSL shader')
		end
	end
end



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
--Spring.SetLosViewColors (needs ModUICtrl)
-- ( table reds = { number always, number LOS, number radar, number jam }, 
-- table greens = { number always, number LOS, number radar, number jam },
-- table blues = { number always, number LOS, number radar, number jam } ) -> nil

--Spring.GetMapDrawMode
-- ( ) -> nil | "normal" | "height" | "metal" | "pathTraversability" | "los"


--default loscolors:
-- los+radar should sum up to 0.5, but its only .45, note the darkening when los is on :)
-- we need to hack it so that there is only a bit of difference in each channel, and exploit that shader side
-- also, we need to hope that it will be detectable shader side 
-- 1/256=0.00390625
	-- jamColor[0] = (int)(losColorScale * 0.25f);
	-- jamColor[1] = (int)(losColorScale * 0.0f);
	-- jamColor[2] = (int)(losColorScale * 0.0f);

	-- losColor[0] = (int)(losColorScale * 0.15f);
	-- losColor[1] = (int)(losColorScale * 0.05f);
	-- losColor[2] = (int)(losColorScale * 0.40f);

	-- radarColor[0] = (int)(losColorScale *  0.05f);
	-- radarColor[1] = (int)(losColorScale *  0.15f);
	-- radarColor[2] = (int)(losColorScale * -0.20f);

	-- alwaysColor[0] = (int)(losColorScale * 0.25f);
	-- alwaysColor[1] = (int)(losColorScale * 0.25f);
	-- alwaysColor[2] = (int)(losColorScale * 0.25f);

--------------------------------------------------------------------------------
