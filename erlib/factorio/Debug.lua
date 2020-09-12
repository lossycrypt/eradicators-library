--erlib.Debug, (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Does automatic mod-name and load-stage/phase detection.
--
-- @module Debug
-- @usage local Debug = require('__eradicators-library_/erlib/factorio/Debug')()
--
  
  

-- ---------------------------------------------------------------------------- --
-- Module                                                                       --
-- ---------------------------------------------------------------------------- --

local Debug = {}



-- ---------------------------------------------------------------------------- --
-- Locals / Init                                                                --
-- ---------------------------------------------------------------------------- --

local debug_getinfo = _ENV .debug .get_info


--@tparam string msg the message
local function _error(msg)
  error('[ER Library][Debug] '..msg)
  end

 
---------------------------------------------------------------------------------
-- Raw stack trace information.
-- You shouldn't be using these unless you *really* know what you're doing.
-- @section
---------------------------------------------------------------------------------

----------
-- Retrieves debug info from the top of the stack or at the given level.
-- @tparam integer j The stack level at which to get the source. (default: max level)
-- @treturn {short_src=,...} The output of debug.getinfo at the given level.
function Debug.get_info(j)
  local i=0; if not j then repeat i=i+1 until not debug_getinfo(i,'S') end
  return debug_getinfo(j or i-1,'Sl') or {} end
  
----------
-- Retrieves debug info from j levels below the top of the stack.
-- @tparam integer j
-- @treturn {short_src=,...}
function Debug.get_level(j) -- takes a negative level offset to go "up" from the caller
  local i=0; repeat i=i+1 until not debug_getinfo(i)
  return i-1-1-(j or 0) end --why is this minus *two*...
  
----------
-- Gets the file:line spec at the given stack level.
-- @tparam integer j
-- @return string "path:number"
function Debug.get_pos(j)
  local x = Debug.get_info(j)
  return x and (x.short_src:match'[^/]+$':sub(1,50) ..':'.. x.currentline) end
  
----------
-- Gets the file:line spec at @{Debug.get_level}(j)-1.
-- @tparam integer j
-- @return string "path:number"
--
function Debug.get_rel_pos(j) -- <file:line>
  return Debug.get_pos(Debug.get_level(j)-1) end

  
  
---------------------------------------------------------------------------------
-- Factorio paths.
-- @section
---------------------------------------------------------------------------------

----------
--@tparam integer j
--@treturn string file path at level j
local function get_src (j) return Debug.get_info(j).short_src or '?' end

----------
--@tparam integer j
--@treturn string name of the current mod: "my-mod"
function Debug.get_mod_name   (j) return get_src(j):match('^__(.+)__/?')                 end

----------
--@tparam integer j
--@treturn string "__my-mod__" root of the mod at level j
function Debug.get_mod_root   (j) return get_src(j):match('^(__.+__)/?')                 end

----------
--@tparam integer j
--@treturn string "__my-mod__/sub/folder" directory of the mod at level j
function Debug.get_cur_dir    (j) return get_src(j):match('^(.*)/')                      end

----------
--@string path "__my-mod__/sub/folder" any path
--@treturn string "my-mod" the undecorated name of the mod
function Debug.path2name(path) return path:match'^__([^_]+)__' end -- probably has false negatives

----------
--@string name "my-mod" the undecorated name of a mod
--@treturn string "__my-mod__" the absolute root of the mod
function Debug.name2root(name) return '__'..name..'__'  end



-- --------------------------------------------------------------------------- --
-- Factorio stage + phase (dynamic)                                            --
-- --------------------------------------------------------------------------- --

--phase with *underscores*: "settings_updates", "data_final_fixes", etc...
function Debug._get_raw_load_phase ( ) return (get_src( ):match('([^/]+)%.lua$') or '?'):gsub('-','_') end

--stage: "settings", "data" or "control"
function Debug._get_raw_load_stage ( ) return Debug .get_load_phase():gsub('_.*$','')         end



-- --------------------------------------------------------------------------- --
-- Factorio stage + phase (pre-calculate + closurize)                          --
-- --------------------------------------------------------------------------- --

----------
-- Retrieves the current load stage and phase from the filenames on the stack.
-- In some situations like scenarios, cross loading, or metatable methods
-- the stage/phase can not be correctly determined. In these cases nil,nil
-- is returned. Be aware that the returned strings use _ underscore instead
-- of - dash.
-- 
-- Should only be used when the error throwing behavior of @{Debug.get_load_stage}
-- or @{Debug.get_load_phase} is undesired.
--
-- @usage local stage,phase = Debug.unsafe_stage_and_phase()
-- @treturn LoadStageName|nil
-- @treturn LoadPhaseName|nil
--
function Debug.unsafe_stage_and_phase()
  local phases = {
    settings             = true, data             = true, control             = true ,
    settings_updates     = true, data_updates     = true, control_updates     = false,
    settings_final_fixes = true, data_final_fixes = true, control_final_fixes = false,
    }

    local _stage = Debug._get_raw_load_stage()
    local _phase = Debug._get_raw_load_phase()
  
    if phases[_stage] and phases[_phase]then
      return _stage, _phase
      end
  
  end
  

--Load Stage/Phase can not change during runtime so it's cheaper to cache the result.
--but it's safer if returned tables are unique per call anyway
local _load_stage, _load_phase = Debug. unsafe_stage_and_phase()

---------------------------------------------------------------------------------
-- Main.
-- @section
---------------------------------------------------------------------------------

----------
-- Gets the current @{LoadStageName}. The stage is internally cached so these
-- are quite fast.
-- @raise It is an error if the stage could not be detected. I.e. when calling from
--        inside a scenario or a data stage metatable.
--
function Debug.get_load_stage()
  if not _load_stage then _error('Load stage detection failed.') end
  return {[_load_stage] = true, name = _load_stage, any = true}
  end

----------
-- Gets the current @{LoadPhaseTable}. The phase is internally cached so these
-- are quite fast.
-- @raise It is an error if the phase could not be detected. I.e. when calling from
--        inside a scenario or a data stage metatable.
--
function Debug.get_load_phase()
  if not _load_phase then _error('Load phase detection failed.') end
  return {[_load_phase] = true, name = _load_phase, any = true}
  end


  
-- --------------------------------------------------------------------------- --
-- End                                                                         --
-- --------------------------------------------------------------------------- --

return function() return Debug,nil,nil end
