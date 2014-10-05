-- this is a template ffa_startpoints.lua file that returna a randomized startpoint table, read code & example1 for more info

-- to add a ffa startpoint config inside game:
-- (1) fill in this template file as appropriate and rename it to <mapname>.lua, put this file in /luarules/configs/ffa_startpoints
-- (2) add the filename/mapname to the table of known maps in the ffa_startpoints.lua file in the same dir

local startpoints = { --locations of the startpoints
	[1] = {
        x = 0,
        z = 0,
	},
    
	[2] = {
	},
    
	[3] = {
	},
    
	[4] = {
	},
    
	[5] = {
	},

	[6] = {
	},

	[7] = {
	},

	[8] = {
	},

	[9] = {
	},

	[10] = {
	},

	[11] = {
	},

	[12] = {
	},

	[13] = {
	},

	[14] = {
	},

	[15] = {
	},

	[16] = {
	},
}


local ffaStartPointsAll = { --ffaStartPointsAll[#allyteams][id] = {table of keys of startpoints table}
	[1] = {
		{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11},{12},{13},{14},{15},{16},
	},
	
	[2] = {
	},

	[3] = {
	},

	[4] = {
	},
	
	[5] = {
	},
	
	[6] = {
	},
	
	[7] = {

	},

	[8] = {
	},
	
	[9] = {
	},
	
	[10] = {
	},
	
	[11] = {
	},
	
	[12] = {
	},
	
	[13] = {
	},
	
	[14] = {
	},
	
	[15] = {
	},
	
	[16] = {
		{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16},
	},
}

-- check that each of the above entries has the right length table
--[[
for i=1,16 do
	for j,v in pairs(ffaStartPointsAll[i]) do
		if #v ~= i then
			Spring.Echo("Error:", i,j)
		end
	end
end
]]

-- now construct (in global namespace) the ffa startpoints by randomly picking one element from each of the subtables of ffaStartPointsAll
-- and mapping that to a set of startpoints using the startpoints table
ffaStartPoints  = {}

for i=1,16 do
	local n = math.random(#(ffaStartPointsAll[i]))
	ffaStartPoints[i] = {}
	for j = 1,i do
		--Spring.Echo(i,n,j)
		local id = ffaStartPointsAll[i][n][j] 
		local sx = startpoints[id].x
		local sz = startpoints[id].z
		--Spring.Echo(sx,sz)
		ffaStartPoints[i][j] = {x=sx,z=sz} 
	end
end