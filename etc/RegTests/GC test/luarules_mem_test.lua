function gadget:GetInfo()
  return {
    name      = "Lua Mem Test",
    desc      = "",
    author    = "",
    date      = "",
    license   = "",
    layer     = 0,
    enabled   = false
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- as written this only tests mem alloced from synced luarule; but its easily modified to test the other luastates too

if (not gadgetHandler:IsSyncedCode()) then
  return
end

function gadget:GameStart()
    Spring.SendCommands("cheat")
    Spring.SendCommands("debug")

    -- this allocs about 120mb of lua mem
    for i=1,3000000 do
        local a={"string"}
    end
end

function gadget:GameFrame(n)
    if n==2 then
        for i=1,200 do
            local x = 100 + i*20
            local z = 100
            Spring.CreateUnit("corraid", x, Spring.GetGroundHeight(x,z), z, "n", 0)
        end
    end

    -- enough allocs to cause a slow increase in lua mem if GC does not clean it up
    local a = Spring.GetAllUnits()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
