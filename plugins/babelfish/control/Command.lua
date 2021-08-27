-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------------------------------------
-- Babelfish.
-- @module Babelfish



--[[ Notes:
  ]]

--[[ Annecdotes:
  ]]

--[[ Future:
  ]]
  
--[[ Todo:
  ]]
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
-- local log         = elreq('erlib/lua/Log'          )().Logger  'babelfish'
local stop        = elreq('erlib/lua/Error'        )().Stopper 'babelfish'
local assertify   = elreq('erlib/lua/Error'        )().Asserter(stop)

local Verificate  = elreq('erlib/lua/Verificate'   )()
local verify      = Verificate.verify
-- local isType      = Verificate.isType

local Table       = elreq('erlib/lua/Table'        )()
-- local Array       = elreq('erlib/lua/Array'        )()
-- local Set         = elreq('erlib/lua/Set'          )()
-- local Filter      = elreq('erlib/lua/Filter'       )()
-- local Vector      = elreq('erlib/lua/Vector'       )()

local ntuples     = elreq('erlib/lua/Iter/ntuples' )()
-- local dpairs      = elreq('erlib/lua/Iter/dpairs'  )()
-- local sriapi      = elreq('erlib/lua/Iter/sriapi'  )()

-- local Setting     = elreq('erlib/factorio/Setting'   )()
-- local Player      = elreq('erlib/factorio/Player'    )()
-- local getp        = Player.get_event_player

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
local script = EventManager .get_managed_script    'babelfish'
local import = PluginManager.make_relative_require 'babelfish'
local const  = import '/const'

local Babelfish        = import '/control/Babelfish'

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Command = {}


-- -------------------------------------------------------------------------- --
-- Savedata                                                                   --
-- -------------------------------------------------------------------------- --
local Savedata
PluginManager.manage_savedata  ('babelfish', function(_) Savedata = _ end)

-- -------------------------------------------------------------------------- --
-- Local Library                                                              --
-- -------------------------------------------------------------------------- --
local Deprecated = {} -- disabled Remote methods

  
-- -------
-- Retrieves the LanguageCode of a player.
-- 
-- @tparam NaturalNumber pindex A @{FOBJ LuaPlayer.index}.
-- @return (@{Babelfish.LanguageCode|LanguageCode} or @{nil}).
--
-- @function Babelfish.get_player_language_code
function Deprecated.get_player_language_code(pindex)
  verify(pindex, 'NaturalNumber', 'Babelfish: Invalid player index.')
  assertify(game.players[pindex], 'No player with given index: ', pindex)
  local dict = Savedata:sget_pdata(nil, pindex).dict
  return (dict and dict.language_code) or nil end
  
  
-- -------
-- Retrieves all translation percentages.
-- This is the same data that the built-in status indicator uses.
-- Includes only languages that have been seen on this map at least once.
-- 
-- This is the total percentage intended for GUI visualization only.
-- Use @{Babelfish.can_find_prototype_names} to get the proper per-SearchType status.
-- 
-- @treturn table A mapping (@{Babelfish.LanguageCode|LanguageCode} → @{NaturalNumber})
-- where the number is between 0 and 100 inclusive.
-- 
-- @function Babelfish.get_translation_percentages
function Deprecated.get_translation_percentages()
  local r = {}
  for code, dict in ntuples(2, Savedata.dicts) do
    r[code] = dict:get_percentage()
    end
  return r end

  
-- -------
-- Triggers an internal update.
--
-- This is meant to be used to circumvent the hard engine limitation of
-- no events being raised in Singleplayer when the locale changes but
-- nothing else changed.
--
-- This can also be triggered by the commands `'/babelfish update'`
-- (singleplayer only) and `'/babelfish reset'` (admin only) respectively.
--
-- @tparam[opt=false] boolean reset Completely resets all translations
-- instead of just performing a normal update.
--
-- @function Babelfish.force_update
function Deprecated.force_update(force)
  -- @future: This can be included in the eventual mini-gui.
  if (force == true) then
    -- Has to fix completely broken Savedata/Dictionary state!
    Savedata:reset_to_default()
    end
  script.get_event_handler('on_configuration_changed')()
  end


--------------------------------------------------------------------------------
-- Commands.  
-- @section
--------------------------------------------------------------------------------

do
  local subcommands
  
  Command.on_console_command = function(e)
    if (e.command == 'babelfish') and e.player_index then
      local pdata, p = Savedata:sget_pdata(e)
      local f = subcommands[e.parameters]
      if f then
        if f(e, pdata, p) then
          p.print{'babelfish.command-confirm'}
          end
      else
        p.print{'babelfish.unknown-command'}
        end
      end
    end
    
  Command.on_user_panic = function(e)
    local pdata, p = Savedata:sget_pdata(e)
    if subcommands.reset(nil, pdata, p) then
      p.print{e.calming_words, {'babelfish.babelfish'}}
      end
    end
    
  --
  subcommands = {
    ----------
    -- `/babelfish update` Updates Singleplayer language when detection failed.
    -- @table update
    update = function(e, pdata, p)
      if game.is_multiplayer() then
        p.print {'babelfish.command-only-in-singleplayer'}
      else
        Deprecated.force_update()
        return true end
      end,
      
    ----------
    -- `/babelfish reset` Deletes all translations and starts from scratch.
    -- Use only when everything else failed.
    -- @table reset
    reset = function(e, pdata, p)
      if game.is_multiplayer() and not p.admin then
        p.print {'babelfish.command-only-by-admin'}
      else
        Deprecated.force_update(true)
        return true end
      end,
      
    ----------
    -- `/babelfish demo` Opens a rudimentary demonstration GUI. Just type
    -- in the upper box to start searching. The gui is not optimized so the
    -- generation of the result icons is a bit slow for large modpacks.
    -- The sidepanel dynamically shows in red/green which SearchTypes
    -- are fully translated.
    --
    -- See also: @{Babelfish.HowToActivateBabelfish|HowToActivateBabelfish}.
    --
    -- @table demo
    demo = function(e, pdata, p)
      if game.is_multiplayer() and not p.admin then
        p.print {'babelfish.command-only-by-admin'}
      else
        -- Don't want to create a global just for this...
        local Demo = _ENV.package.loaded["plugins/babelfish-demo/control"]
        if Demo then
          Demo(p):toggle_gui()
        else
          p.print('Demo is not activated.')
          end
        end
      end,
      
    ----------
    -- `/babelfish dump` Prints internal statistics to the attached terminal.
    -- @table dump
    dump = function(e, pdata, p)
      if game.is_multiplayer() and not p.admin then
        p.print {'babelfish.command-only-by-admin'}
      elseif not flag.IS_DEV_MODE then
        p.print('Dev mode is required for correct statistics!')
      else
        print('############ DUMP ############')
        for _, lcode in ipairs{'en', 'de', 'ja'} do
          local dict = Savedata.dicts[lcode]
          if dict then dict:dump_statistics_to_console()
          else print('No dictionary with language_code: '.. lcode) end
          end
        return true end
      end,

    -- -------
    --
    test = function(e, pdata, p)
      if p.name == 'eradicator' then
        --
        for k, v in pairs(pdata.dict) do
          if type(v) == 'table' then
            local holes = 0
            for i=1, v.max do 
              if v[i] == nil then holes = holes + 1 end
              end
            print(('%s had %s holes'):format(k, holes))
            end
          end
        return true end
      end,
      
    }
  end
  
  
return Command