-----------------------------------------------------------------------
-----------------------------------------------------------------------
--
--  Icon Generator Config File
--

--// Info
if (info) then
  local ratios      = {[""]=(1/1)} -- {["16to10"]=(10/16), ["1to1"]=(1/1), ["5to4"]=(4/5)} --, ["4to3"]=(3/4)}
  local resolutions = {{128,128}} -- {{128,128},{64,64}}
  local schemes     = {"Black", "White"}

  return schemes,resolutions,ratios
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------

--// filename ext
imageExt = ".png"

--// render into a fbo in 4x size
renderScale = 4

--// faction colors (check (and needs) LuaRules/factions.lua)
factionTeams = {
  arm     = 1,   --// arm
  core    = 1,   --// core
  chicken = 2,   --// chicken
  unknown = 2,   --// unknown
}

-- Gets scheme from gadget when this is included
factionColors = function(faction)

	color = {
		arm     = {0, 0, 0},   --// arm
		core    = {0, 0, 0},   --// core
		chicken = {1.0,0.8,0.2},   --// chicken
		unknown = {0, 0, 0},   --// unknown
		Black   = {0,0,0},
		White   = {1,1,1}
	}
	
	

	if color[scheme] then
		return color[scheme]
	else
		return colors[faction]
	end

end

-----------------------------------------------------------------------
-----------------------------------------------------------------------

local IconConfig = {
	[1] = {
		--// render options textured
		textured     = true,
		lightAmbient = {1,1,1},
		lightDiffuse = {0,0,0},
		lightPos     = {-0.2,0.4,0.5},
		
		--// Ambient Occlusion & Outline settings
		aoPower     =  3,
		aoContrast  =  3,
		aoTolerance =  0,
		olContrast  =  0,
		olTolerance =  0,
		
		halo = false,
	},
	[2] = {
		textured     = true,
		lightAmbient = {1,1,1},
		lightDiffuse = {0,0,0},
		lightPos     = {-0.2,0.4,0.5},
		aoPower      =  3,
		aoContrast   =  3,
		aoTolerance  =  0,
		olContrast   =  0,
		olTolerance  =  0,
		halo         = false,
	},
}

local selConfig = 1

textured     = IconConfig[selConfig].textured     
lightAmbient = IconConfig[selConfig].lightAmbient 
lightDiffuse = IconConfig[selConfig].lightDiffuse 
lightPos     = IconConfig[selConfig].lightPos     
aoPower      = IconConfig[selConfig].aoPower     
aoContrast   = IconConfig[selConfig].aoContrast  
aoTolerance  = IconConfig[selConfig].aoTolerance 
olContrast   = IconConfig[selConfig].olContrast  
olTolerance  = IconConfig[selConfig].olTolerance 
halo         = IconConfig[selConfig].halo


-----------------------------------------------------------------------
-----------------------------------------------------------------------

--// backgrounds
background = true
local water = "LuaRules/Images/IconGenBkgs/bg_water.png"

local function Greater30(a)     return a>30;  end
local function GreaterEq15(a)   return a>=15; end
local function GreaterZero(a)   return a>0;   end
local function GreaterEqZero(a) return a>=0;  end
local function GreaterFour(a)   return a>4;   end
local function LessEqZero(a)    return a<=0;  end

backgrounds = {
  {check={waterline=GreaterEq15,minWaterDepth=GreaterZero},texture=water},
  {check={floatOnWater=false,minWaterDepth=GreaterFour},texture=water},
  {check={floatOnWater=true,minWaterDepth=GreaterZero},texture=water},
}


-----------------------------------------------------------------------
-----------------------------------------------------------------------
local Default = {
	--  default settings for rendering
	-- zoom   := used to make all model icons same in size (DON'T USE, it is just for auto-configuration!)
	-- offset := used to center the model in the fbo (not in the final icon!) (DON'T USE, it is just for auto-configuration!)
	-- rot    := facing direction
	-- angle  := topdown angle of the camera (0 degree = frontal, 90 degree = topdown)
	-- clamp  := clip everything beneath it (hide underground stuff)
	-- scale  := render the model x times as large and then scale down, to replaces missing AA support of FBOs (and fix rendering of very tine structures like antennas etc.))
	-- unfold := unit needs cob to unfolds
	-- move   := send moving cob events (works only with unfold)
	-- attack := send attack cob events (works only with unfold)
	-- shotangle := vertical aiming, useful for arties etc. (works only with unfold+attack)
	-- wait   := wait that time in gameframes before taking the screenshot (default 300) (works only with unfold)
	-- border := free space around the final icon (in percent/100)
	-- empty  := empty model (used for fake units in CA)
	-- attempts := number of tries to scale the model to fit in the icon

	[1]	= {
		border   = 0.05,
		angle    = 26,
		rot      = "right",
		clamp    = 0,
		scale    = 1.5,
		empty    = false,
		attempts = 2,
		wait     = 300,
		zoom     = 1.0,
		offset   = {0,0,0},
	},
	
	[2] = {
		border   = 0,
		angle    = 26,
		rot      = "right",
		clamp    = 0,
		scale    = 1.5,
		empty    = false,
		attempts = 2,
		wait     = 300,
		zoom     = 1.0,
		offset   = {0,0,0},
	},
	[3] = {},
	[4] = {},

}

defaults = Default[1]


-----------------------------------------------------------------------
-----------------------------------------------------------------------

--// per unitdef settings
unitConfigs = {
  
  
  [UnitDefNames.cormex.id] = {
    clamp  = 0,
    unfold = true,
    wait   = 600,
  },
  [UnitDefNames.cordoom.id] = {
    unfold = true,
  },


}

for i=1,#UnitDefs do
  if (UnitDefs[i].canFly) then
    if (unitConfigs[i]) then
      if (unitConfigs[i].unfold ~= false) then
        unitConfigs[i].unfold = true
        unitConfigs[i].move   = true
      end
    else
      unitConfigs[i] = {unfold = true, move = true}
    end
    
  -- give ticks etc.. larger padding
  elseif (UnitDefs[i].canKamikaze) then
    if (unitConfigs[i]) then
      if (not unitConfigs[i].border) then
        unitConfigs[i].border = 0.156
      end
    else
      unitConfigs[i] = {border = 0.156}
    end
  end
end
