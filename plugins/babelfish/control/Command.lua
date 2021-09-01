-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------------------------------------
-- Babelfish.
-- @module Babelfish

-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local stop        = elreq('erlib/lua/Error'        )().Stopper 'babelfish'
local assertify   = elreq('erlib/lua/Error'        )().Asserter(stop)

local Verificate  = elreq('erlib/lua/Verificate'   )()
local verify      = Verificate.verify

local Table       = elreq('erlib/lua/Table'        )()
local ntuples     = elreq('erlib/lua/Iter/ntuples' )()

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
        Babelfish.force_update()
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
        Babelfish.force_update(true)
        return true end
      end,
      
    ----------
    -- `/babelfish demo` Opens a rudimentary demonstration GUI. Just type
    -- in the upper box to start searching. The gui is not optimized so the
    -- generation of the result icons is a bit slow for large modpacks.
    -- The search may also appear slow if many SearchTypes are activated
    -- because it searches them all at once.
    -- The sidepanel dynamically shows in red/green which SearchTypes
    -- are currently fully translated.
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
    -- This is meant for library authors and is not useful to players or mod authors.
    -- @table dump
    dump = function(e, pdata, p)
      if not flag.IS_DEV_MODE then
        p.print('Dev mode is required for correct statistics!')
      elseif game.is_multiplayer() and not p.admin then
        p.print {'babelfish.command-only-by-admin'}
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
    test = (not flag.IS_DEV_MODE) and ercfg.SKIP or function(e, pdata, p)
      for k, v in pairs(pdata.dict) do
        if type(v) == 'table' then
          local holes = 0
          for i=1, v.max do 
            if v[i] == nil then holes = holes + 1 end
            end
          print(('%s had %s holes'):format(k, holes))
          end
        end
      return true end,
      
    }
  end
  
  
return Command