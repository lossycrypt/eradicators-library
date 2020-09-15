--erlib.Debug, (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Automatic mod-name and load-stage/phase detection.
--
-- @module Debug
-- @usage local Debug = require('__eradicators-library__/erlib/factorio/Debug')()
--
-- @usage
--  An example stack. l=level, o=inverse level offset
--   l  o
--   0 -3 erlib/factorio/Debug.lua                -- top    (called last )
--   1 -2 core/lualib/util.lua (table.deepcopy)   --
--   2 -1 prototypes/entity/my-modded-entity.lua  --
--   3  0 data.lua                                -- bottom (called first)
  
  

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Debug = {}



-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- -------------------------------------------------------------------------- --

local debug_getinfo = _ENV .debug .getinfo


--@tparam string msg the message
local function _error(msg)
  error('[ER Library][Debug] '..msg)
  end

 
--------------------------------------------------------------------------------
-- Raw stack trace information.
-- You shouldn't be using these unless you *really* know what you're doing.
-- @section 2
--------------------------------------------------------------------------------

-- ! IMPORTANT !
-- To make *the calling file* appear as level 0 on the stack all 
-- functions have to adjust the level to hide themselfs below 0.

----------
-- Retrieves debug info from the top of the stack or at the given level.
-- l=0 the last file on the stack (the file containing this function).
--
-- @tparam[opt=bottom] integer l The stack level at which to get the source.
-- @treturn {short_src=,...} The output of debug.getinfo at the given level.
--
function Debug.get_info(l)
  local i=0; if not l then repeat i=i+1 until not debug_getinfo(i,'S') end
  if l then
    return debug_getinfo(l+1,'Sl') or nil --compensate one call inside Debug
  else
    return debug_getinfo(i-1,'Sl') or nil --bottom-most
    end
  end
  

-- Nothing to do here. The non-reverse level does not need a function.
function Debug.get_level(l)
  return l
  end
  
----------
-- Retrieves the height of the stack o levels above the bottom.
-- l=0 is the first file on the stack.
--
-- @tparam[opt=0] NegativeInteger o, the offset from the bottom
-- @treturn NaturalNumber l, the level
--
function Debug.inverse_get_level(o)
  local i=0; repeat i=i+1 until not debug_getinfo(i)
  -- return (i-1) + (o or 0) --inverse does not need to compensate
  return (i-1) + (o and (o-1) or -1) --inverse does not need to compensate
  end


----------
-- Gets the file:line spec at the given stack level l.
--
-- @tparam integer l
-- @treturn string "path:number"
--
function Debug.get_pos(l)
  -- l = l and (l+2) or 2
  local x = Debug.get_info(l and (l+2) or 2) --compensate two calls inside Debug
  return x and (x.short_src:match'[^/]+$':sub(1,50) ..':'.. x.currentline)
  end

  
----------
-- Gets the file:line spec at the given inverse offset o.
--
-- @tparam NegativeInteger o
-- @treturn string "path:number"
--
function Debug.inverse_get_pos(o) -- <file:line>
  return Debug.get_pos(Debug.inverse_get_level(o)-1)
  end
  
----------
-- Retrieves info for the whole stack.
-- @treturn Array debug_getinfo for each level of the stack. Starting at 0.
function Debug.get_stack_info()
  local i,stack = -1,{}
  repeat i=i+1
    stack[i] = debug_getinfo(i,'Sl')
    until stack[i] == nil
  return stack
  end

  
--------------------------------------------------------------------------------
-- Factorio paths.
-- @section 3
--------------------------------------------------------------------------------

----------
--@tparam[opt=0] integer l
--@treturn string file path at level l
local function get_src (l)
  return Debug.get_info(l and (l+2) or 2).short_src or '?'
  end

----------
--@tparam[opt=0] integer l
--@treturn string name of the current mod: "my-mod"
function Debug.get_mod_name (l)
  return get_src(l and (l+3) or 3):match('^__(.+)__/?')
  end

----------
--@tparam[opt=0] integer l
--@treturn string "__my-mod__" root of the mod at level l
function Debug.get_mod_root (l)
  return get_src(l and (l+3) or 3):match('^(__.+__)/?')
  end

----------
--@tparam[opt=0] integer l
--@treturn string "__my-mod__/sub/folder" directory of the mod at level l
function Debug.get_cur_dir (l)
  return get_src(l and (l+3) or 3):match('^(.*)/')
  end

----------
--@string path "__my-mod__/sub/folder" any path
--@treturn string "my-mod" the undecorated name of the mod
function Debug.path2name(path)
  return path:match'^__([^_]+)__' -- probably has false negatives
  end

----------
--@string name "my-mod" the undecorated name of a mod
--@treturn string "__my-mod__" the absolute root of the mod
function Debug.name2root(name)
  return '__'..name..'__'
  end



-- -------------------------------------------------------------------------- --
-- Factorio stage + phase (dynamic)                                           --
-- -------------------------------------------------------------------------- --

--phase with *underscores*: "settings_updates", "data_final_fixes", etc...
function Debug._get_raw_load_phase ( )
  return (get_src( ):match('([^/]+)%.lua$') or '?'):gsub('-','_')
  end

--stage: "settings", "data" or "control"
function Debug._get_raw_load_stage ( )
  return Debug._get_raw_load_phase():gsub('_.*$','')
  end



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
-- @{Debug.get_load_stage} or @{Debug.get_load_phase} is undesired.
--
-- @usage local stage,phase = Debug.unsafe_stage_and_phase()
-- @treturn LoadStageName|nil
-- @treturn LoadPhaseName|nil
--
function Debug.unsafe_stage_and_phase()

    local _stage = Debug._get_raw_load_stage()
    local _phase = Debug._get_raw_load_phase()
  
    if phases[_stage] and phases[_phase]then
      return _stage, _phase
      end
  
  end
  

-- Load Stage/Phase can not change during runtime so it's cheaper to cache the
-- result. but it's safer if returned tables are unique per call anyway
local _load_stage, _load_phase = Debug. unsafe_stage_and_phase()

--------------------------------------------------------------------------------
-- Main.
-- @section 1
--------------------------------------------------------------------------------

----------
-- Gets the current @{LoadStageName}. The stage is internally cached so these
-- are quite fast.
-- @raise It is an error if the stage could not be detected. I.e. when calling
--        from inside a scenario or a data stage metatable.
--
function Debug.get_load_stage()
  if not _load_stage then _error('Load stage detection failed.') end
  return {[_load_stage] = true, name = _load_stage, any = true}
  end

----------
-- Gets the current @{LoadPhaseTable}. The phase is internally cached so these
-- are quite fast.
-- @raise It is an error if the phase could not be detected. I.e. when calling
--        from inside a scenario or a data stage metatable.
--
function Debug.get_load_phase()
  if not _load_phase then _error('Load phase detection failed.') end
  return {[_load_phase] = true, name = _load_phase, any = true}
  end



-- Easier to index?
-- @name Loading.is_phase.control
-- do
--   local ok = {name=true,any=true}
--   local magic = function(typ,f) return {__index=function(_,key)
--   if phases[key] or ok[key] then return f()
--   else _error(('Not a valid %s key:'):format(typ),key) end
--   end } end  
--   Debug.is_stage = setmetatable({},magic('StageNameTable',Debug.get_load_stage))
--   Debug.is_phase = setmetatable({},magic('PhaseNameTable',Debug.get_load_phase))
--   end

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --

return function() return Debug,nil,nil end
