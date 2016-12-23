function widget:GetInfo()
    return {
        name      = "Metal Spot Table Maker",
        desc      = "",
        author    = "Tarquin Fin-tim-lin-bin-whin-bim-lim-bus-stop-F'tang-F'tang-Olé-Biscuitbarrel",
        date      = "",
        license   = "GPL v2+",
        layer     = 0,
        enabled   = false
    }
end

local m = 2.5

function widget:Initialize()
    local units = Spring.GetAllUnits()
    local spots = {}
    for _,unitID in ipairs(units) do
        local x,_,z = Spring.GetUnitPosition(unitID)
        table.insert(spots, {x=x,z=z,metal=m})
    end   
    table.save(spots, "metal_spots.lua")
end