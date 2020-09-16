-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Automatic mod-name and load-stage/phase detection.
--
-- Level  0 is any Stacktrace.* function.
-- Level  1 is the function that called any public Stacktrace.* function.
-- Level -1 is the bottom of the stack.
--
-- @module Stacktrace
-- @usage local Stacktrace = require('__eradicators-library__/erlib/factorio/Stacktrace')()
-- @usage
--  An example stack. l=level
--   l  l
--   0 -4 erlib/factorio/Stacktrace.lua                -- top    (called last )
--   1 -3 core/lualib/util.lua (table.deepcopy)   --
--   2 -2 prototypes/entity/my-modded-entity.lua  --
--   3 -1 data.lua                                -- bottom (called first)


-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Stacktrace = {}


-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- -------------------------------------------------------------------------- --

local debug_getinfo = _ENV .debug .getinfo


--@tparam string msg the message
local function _error(msg)
  error('[ER Library][Stacktrace] '..msg)
  end

 
--------------------------------------------------------------------------------
-- raw.
-- You shouldn't be using these unless you *really* know what you're doing.
-- @section 2
--------------------------------------------------------------------------------

-- Behavior of Lua:
-- level  0 is debug.getinfo itself, the top of the stack
-- level  1 is the function that called debug.getinfo
--
-- Behavior of _get_info:
-- level  0 is any Stacktrace.* function
-- level  1 is the function that called any public Stacktrace.* function
-- level -1 is the bottom of the stack
--
-- _get_info is *never* in the info that it returns
--
-- _get_info must be called only and directly by each function in Stacktrace
-- to ensure an exact additional stack height of +1 from calling it.
--
local function _get_info(l)
  local i,r = 1,{}
  repeat
    i=i+1 --starts at 2!
    r[i-2] = debug_getinfo(i,'Sl') -- 0-indexed array!
    until r[i-2] == nil
  --
  if     l ==  nil  then return r[1]
  elseif l == 'all' then return r
  elseif l >=  0    then return r[l]
  -- minus 1 is the first element from the back of the Array
  elseif l <   0    then return r[(#r+1)+l]
  else _error('Invalid _get_info level.')
    end
  end

  
----------
-- Gets debug info of the function at stack level l.
-- l=0 the last file on the stack (the file containing this function).
--
-- @tparam[opt=1] integer l The stack level at which to get the info.
-- @treturn {short_src=,...} The output of @{debug.getinfo} at the given level.
--
function Stacktrace.get_info(l)
  local info = _get_info(l) -- tail-call would alter the stack height!
  return info -- wrapping ensures correct stack level!
  end
  
----------
-- Retrieves info for the whole stack.
--
-- @treturn Array info for each level of the stack. Starting at 0.
--
function Stacktrace.get_all_info()
  local info = _get_info('all') -- tail-call would alter the stack height!
  return info -- wrapping ensures correct stack level!
  end
  
----------
-- Gets file:line at stack level l.
--
-- @tparam[opt=1] integer l
-- @treturn string "filename:number"
--
function Stacktrace.get_pos(l)
  local info = _get_info(l)
  if info then
    return info.short_src:match'[^/]+$':sub(1,50)
      ..':' .. info.currentline
    end
  end

  
----------
-- Prints a stacktrace directly to @{erlib stdout}, starting at level l.
--
-- @tparam[opt=1] integer l
--
function Stacktrace.print_info(l)
  (STDOUT or log or print)(debug.traceback(l and (l+1) or 2))
  end

--------------------------------------------------------------------------------
-- factorio.
-- @section 3
--------------------------------------------------------------------------------

--debug.getinfo can actually see the full path to the scenario (engine bug).
--But scenario detection isn't implemented.
--"/temp/currently-playing/control.lua"

-- @tparam string pattern what to look for in short_src
-- @tparam string fallback what to return if the pattern returned nil
-- @tparam Array substitutes {pattern,replace} groups gsub'ed before return
local function _src_getter(pattern,fallback,substitutes)
  return function(l)
    local info,r = _get_info(l),nil
    if info then
      r = info.short_src:match(pattern)
      end
    --no info *or* pattern mis-match
    if not r then return fallback, false
    else
      for _,s in ipairs(substitutes or {}) do
        r = r:gsub(s[1],s[2])
        end
      return r, true
      end
    end
  end

----------
-- →　"my-mod-name"
--
-- @tparam[opt=1] integer l
-- @treturn string name of the mod at level l: "my-mod-name"
--                or "unknown/scenario" if the check failed.
-- @treturn boolean if the name was found.
--
-- @function Stacktrace.get_mod_name
--
Stacktrace.get_mod_name = _src_getter('^__(.+)__/?','unknown/scenario')


----------
-- →　"__my-mod-name__"
--
-- @tparam[opt=1] integer l
-- @treturn string "__my-mod-name__" root of the mod at level l
--                or "__unknown/scenario__" if the check failed.
-- @treturn boolean if the root was found.
--
-- @function Stacktrace.get_mod_root
--
Stacktrace.get_mod_root = _src_getter('^(__.+__)/?','__unknown/scenario__')


----------
-- →　"__my-mod-name__/sub/directory"
--
-- @tparam[opt=1] integer l
-- @treturn string "__my-mod-name__/sub/directory" directory of the mod at level l
--                or "__unknown/scenario__" if the check failed.
-- @treturn boolean if the root was found.
--
-- @function Stacktrace.get_cur_dir
--
Stacktrace.get_cur_dir  = _src_getter('^(.*)/','__unknown/scenario__')


----------
-- "__my-mod-name__/sub/directory" →　"my-mod"
--
-- @string path "__my-mod-name__/sub/directory" any path
-- @treturn string "my-mod" the undecorated name of the mod
--
function Stacktrace.path2name(path)
  return path:match'^__([^_]+)__' -- probably has false negatives
  end

----------
-- "my-mod-name" → "__my-mod-name__"
--
-- @string name "my-mod-name" the undecorated name of a mod
-- @treturn string "__my-mod-name__" the absolute root of the mod
--
function Stacktrace.name2root(name)
  return '__'..name..'__'
  end



-- -------------------------------------------------------------------------- --
-- Factorio stage + phase (dynamic)                                           --
-- -------------------------------------------------------------------------- --

--stage: "settings", "data" or "control"
Stacktrace._get_raw_load_stage = 
  _src_getter('([^/]+)%.lua$','?',{{'-','_'},{'_.*$',''}})

--phase with *underscores*: "settings_updates", "data_final_fixes", etc...
Stacktrace._get_raw_load_phase = 
  _src_getter('([^/]+)%.lua$','?',{{'-','_'}})


-- -------------------------------------------------------------------------- --
-- Factorio stage + phase (pre-calculate + closurize)                         --
-- -------------------------------------------------------------------------- --

local phases = {
  settings             = true, data             = true, control             = true ,
  settings_updates     = true, data_updates     = true, control_updates     = false,
  settings_final_fixes = true, data_final_fixes = true, control_final_fixes = false,
  }

----------
-- Retrieves the current load stage and phase from the filenames on the stack.
-- In some situations like scenarios, cross loading, or metatable methods
-- the stage/phase can not be correctly determined. In these cases nil,nil
-- is returned. Be aware that the returned strings use _ underscore instead
-- of - dash.
-- 
-- Should only be used when the error throwing behavior of
-- @{Stacktrace.get_load_stage} or @{Stacktrace.get_load_phase} is undesired.
--
-- @usage local stage,phase = Stacktrace.unsafe_get_stage_and_phase()
--
-- @treturn LoadStageName|nil
-- @treturn LoadPhaseName|nil
--
function Stacktrace.unsafe_get_stage_and_phase()

    local _stage = Stacktrace._get_raw_load_stage(-1)
    local _phase = Stacktrace._get_raw_load_phase(-1)
  
    if phases[_stage] and phases[_phase]then
      return _stage, _phase
      end
  
  end
  

-- Load Stage/Phase can not change during runtime so it's cheaper to cache the
-- result. but it's safer if returned tables are unique per call anyway
local _load_stage, _load_phase = Stacktrace. unsafe_get_stage_and_phase()

--------------------------------------------------------------------------------
-- !Main.
-- @section 1
--------------------------------------------------------------------------------

----------
-- Gets the current @{LoadStageName}. The stage is internally cached so these
-- are quite fast.
--
-- @raise It is an error if the stage could not be detected. I.e. when calling
--        from inside a scenario or a data stage metatable.
--
function Stacktrace.get_load_stage()
  if not _load_stage then _error('Load stage detection failed.') end
  return {[_load_stage] = true, name = _load_stage, any = true}
  end

----------
-- Gets the current @{LoadPhaseTable}. The phase is internally cached so these
-- are quite fast.
--
-- @raise It is an error if the phase could not be detected. I.e. when calling
--        from inside a scenario or a data stage metatable.
--
function Stacktrace.get_load_phase()
  if not _load_phase then _error('Load phase detection failed.') end
  return {[_load_phase] = true, name = _load_phase, any = true}
  end



-- Easier to index? -> but "different syntax for same thing"
-- @name Loading.is_phase.control
-- do
--   local ok = {name=true,any=true}
--   local magic = function(typ,f) return {__index=function(_,key)
--   if phases[key] or ok[key] then return f()
--   else _error(('Not a valid %s key:'):format(typ),key) end
--   end } end  
--   Stacktrace.is_stage = setmetatable({},magic('StageNameTable',Stacktrace.get_load_stage))
--   Stacktrace.is_phase = setmetatable({},magic('PhaseNameTable',Stacktrace.get_load_phase))
--   end


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --

return function() return Stacktrace,nil,nil end
