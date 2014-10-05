-- format is ffaStartPoints[numAllyTeamIDs][startPointNum] = {x,z}
-- initial_spawn will take care of where to place teamIDs about the allyTeamID start point
-- initial_spawn will count how many allyTeamIDs are going spawn units 
-- and will randomly assign each allyTeamID to one of the startpoints in ffaStartPoints[numAllyTeamIDs]

-- see also /luarules/configs/ffa_startpoints for examples of files that produce random configurations
-- see the map Emereld v1 for a map where the mexes are placed via lua to match a randomized startpoint configs

ffaStartPoints = {

	[1] = {
		[1] = {
			-- where to put first allyTeamID if there is one allyTeamID 
			x = 500,
			z = 500,
		},	
	},

	[2] = {
		[1] = {
			-- where to put first allyTeamID if there are two allyTeamIDs
			x = 5000,
			z = 5000,
		},
		[2] = {
			-- where to put second allyTeamID if there are two allyTeamIDs, etc etc
			x = 4000,
			z = 3000,
		},
	},

}