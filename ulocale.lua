--[[

  This file should when required automatically collect all 
  universal locale tables from this mod and return them at the end.

  ]]



local flag = pcall(require,'__zz-toggle-to-enable-dev-mode__/empty')

local erlib = require '__eradicators-library__/erlib/library.lua' (_ENV,{
  is_dev_build = flag,
  debug_mode   = flag,
  strict_mode  = flag,
  verbose      = flag,
  load_locale  = true,
  })


--Pseudocode
local ulocale = {}
for k,v in pairs(erlib) do
  erlib.Table.deep_merge(ulocale,v.__locale)
  end
return ulocale