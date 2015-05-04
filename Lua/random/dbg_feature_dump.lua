function widget:GetInfo()
  return {
    name      = "Feature dumper v1",
    desc      = "dumps features",
    author    = "Beherith - mysterme@gmail.com",
    date      = "9/15/2008",
    license   = "GNU GPL, v2 or later",
    layer     = 5,
    enabled   = false  --  loaded by default?
  }
end

function widget:Initialize()
	features=Spring.GetAllFeatures()
	for k,v in pairs(features) do
		local featureName = (FeatureDefs[Spring.GetFeatureDefID(v)].name or "nil")
		x,y,z= Spring.GetFeaturePosition(v)
		r=Spring.GetFeatureHeading(v)
		Spring.Echo(string.format("{ name = \'%s\', x = %d, z = %d, rot = \"%d\"}",featureName,x,z,r)) --{ name = 'ad0_aleppo_2', x = 2900, z = 52, rot = "-1" },
	end
	widgetHandler:RemoveWidget()
end


