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

-- second half of a tool for baking unitdefs_post into unitdef files, see readme.txt

function widget:Initialize()
    local had_failed = false
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
            for k,_ in pairs(ud_table) do
                if #ud_table[k].customparams==0 then ud_table[k].customparams=nil end
            end
            table.save2(ud_table, v.name .. ".lua")
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


-- Modified version of table.save, which rounds numbers to avoid lua stupidity 0=0.00000000234876

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    savetable.lua
--  brief:   a human friendly table writer
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
-----

local indentString = '\t'

local savedTables = {}

-- setup a lua keyword map
local keyWords = {
 "and", "break", "do", "else", "elseif", "end", "false", "for", "function",
 "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true",
 "until", "while"
}
local keyWordSet = {}
for _,w in ipairs(keyWords) do
  keyWordSet[w] = true
end
keyWords = nil  -- don't need the array anymore

local function encloseStr(s)
  return string.format('%q', s)
end


local function encloseKey(s)
  local wrap = not (string.find(s, '^%a[_%a%d]*$'))
  if (not wrap) then
    if (string.len(s) <= 0) then wrap = true end
  end
  if (not wrap) then
    if (keyWordSet[s]) then wrap = true end
  end

  if (wrap) then
    return string.format('[%q]', s)
  else
    return s
  end
end


local keyTypes = {
  ['string']  = true,
  ['number']  = true,
  ['boolean'] = true,
}

local valueTypes = {
  ['string']  = true,
  ['number']  = true,
  ['boolean'] = true,
  ['table']   = true,
}


local function CompareKeys(kv1, kv2)
  local k1, v1 = kv1[1], kv1[2]
  local k2, v2 = kv2[1], kv2[2]

  local ktype1 = type(k1)
  local ktype2 = type(k2)
  if (ktype1 ~= ktype2) then
    return (ktype1 > ktype2)
  end

  local vtype1 = type(v1)
  local vtype2 = type(v2)
  if ((vtype1 == 'table') and (vtype2 ~= 'table')) then
    return false
  end
  if ((vtype1 ~= 'table') and (vtype2 == 'table')) then
    return true
  end

  return (k1 < k2)
end


local function MakeSortedTable(t)
  local st = {}
  for k,v in pairs(t) do
    if (keyTypes[type(k)] and valueTypes[type(v)]) then
      table.insert(st, { k, v })
    end
  end
  table.sort(st, CompareKeys)
  return st
end


local function SaveTable(t, file, indent)
  local indent = indent .. indentString

  local st = MakeSortedTable(t)

  for _,kv in ipairs(st) do
    local k, v = kv[1], kv[2]
    local ktype = type(k)
    local vtype = type(v)
    -- output the key
    if (ktype == 'string') then
      file:write(indent..encloseKey(k)..' = ')
    else
      file:write(indent..'['..tostring(k)..'] = ')
    end
    -- output the value
    if (vtype == 'string') then
      file:write(encloseStr(v)..',\n')
    elseif (vtype == 'number') then
      if (v == math.huge) then
        file:write('math.huge,\n')
      elseif (v == -math.huge) then
        file:write('-math.huge,\n')
      else
        -- round to 5dp, convert to string, then remove trailing 0s after decimal point        
        v = string.format("%.5f", v) 
        local a,b = string.find(v,".")
        if a~= nil then
            v = string.reverse(v)
            while (string.sub(v,1,1)=="0") do
                v = string.sub(v,2)
            end
            if string.sub(v,1,1)=="." then v = string.sub(v,2) end --remove the decimal point, if needed
            v = string.reverse(v)
        end
        file:write(tostring(v)..',\n')
      end
    elseif (vtype == 'boolean') then
      file:write(tostring(v)..',\n')
    elseif (vtype == 'table') then
      if (savedTables[v]) then
        error("table.save() does not support recursive tables")
      end
      if (next(v)) then
        savedTables[t] = true
	file:write('{\n')
        SaveTable(v, file, indent)
        file:write(indent..'},\n')
        savedTables[t] = nil
      else
        file:write('{},\n') -- empty table
      end
    end
  end
end


function table.save2(t, filename, header)
  local file = io.open(filename, 'w')
  if (file == nil) then
    return
  end
  if (header) then
    file:write(header..'\n')
  end
  file:write('return {\n')
  if (type(t)=="table")or(type(t)=="metatable") then SaveTable(t, file, '') end
  file:write('}\n')
  file:close()
  for k,v in pairs(savedTables) do
    savedTables[k] = nil
  end
end