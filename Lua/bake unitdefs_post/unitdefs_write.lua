function widget:GetInfo()
	return {
		name      = "Write ud.customparam.__ud to files",
		desc      = "Bluestone",
		author    = "Robert De Bruce",
		date      = "-1",
		license   = "Those stupid trees",
		layer     = 0,
		enabled   = false  --  loaded by default?
	}
end


function widget:Initialize()
    local had_failed = true
    for k,v in pairs(UnitDefs) do
        if not v.customParams or not v.customParams.__ud then
            Spring.Echo("Could not find ud.customparams.__ud, check that you ran unitdefs_post_save_to_customparams")
            had_failed = nil
            widgetHandler:RemoveWidget(self)
            break
        end
        local ud_string = v.customParams.__ud --from table.tostring in unitdefs_post 
        ud_string = "return { " .. v.name .. " = " .. ud_string .. "}" 
        local f = loadstring(ud_string)
        if f then
            local ud_table = f()
            table.save(ud_table, v.name .. ".lua","")
        else
            had_failed = true
            Spring.Echo("FAILED: " .. v.name, ud_string)
        end
    end
    if had_failed==true then
        Spring.Echo("Some ud_string failed to convert to table. Maybe check that your table keys do not contain lua keywords?")
    elseif had_failed==false then
        Spring.Echo("Wrote all ud_string to files")
    end
    widgetHandler:RemoveWidget(self)
end