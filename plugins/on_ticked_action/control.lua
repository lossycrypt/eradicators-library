-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------
-- Description
--
-- @module EventManagerLite

-- -------------------------------------------------------------------------- --

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
local log         = elreq('erlib/lua/Log'          )().Logger  'on_ticked_action'

local Verificate  = elreq('erlib/lua/Verificate'   )()
local verify      = Verificate.verify

local Table       = elreq('erlib/lua/Table'        )()
local sriapi      = elreq('erlib/lua/Iter/sriapi'  )()

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
local script = EventManager .get_managed_script    'on_ticked_action'
local import = PluginManager.make_relative_require 'on_ticked_action'
local const  = import '/const'

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
-- local This = {}
local TickedAction = {}
local Private = {}

remote.add_interface(const.name.remote.interface, TickedAction)
local on_ticked_action = script.generate_event_name('on_ticked_action')

-- -------------------------------------------------------------------------- --
-- Savedata                                                                   --
-- -------------------------------------------------------------------------- --
local Savedata
local SavedataDefaults = {queue = {}}
PluginManager.manage_savedata  ('on_ticked_action', function(_) Savedata = _ end, SavedataDefaults)
-- PluginManager.manage_garbage   ('on_ticked_action')

-- -------------------------------------------------------------------------- --
-- Local                                                                      --
-- -------------------------------------------------------------------------- --

local function garbage_collect_queue()
  local tick = game.tick
  for action, i in sriapi(Savedata.queue) do
    if (action.tick <= tick) then
      table.remove(Savedata.queue, i) -- preserve order
      end
    end
  end
  
local function update_next_tick()
  local nt
  for _, action in ipairs(Savedata.queue) do
    if assert(action.tick, 'Handler had no tick') < (nt or math.huge) then
      nt = action.tick
      end
    end
  --
  Savedata.next_tick = nt
  if nt == nil then
    assert(#Savedata.queue == 0)
    Private.update_handlers()
  else
    assert(nt > game.tick, 'next_tick was in the past (update_next_tick)')
    end
  end

local function dequeue(module_name, method_name, tick)
  local all = (tick == nil)
  for i, action in ipairs(Savedata.queue) do
    if  action.module_name == module_name
    and action.method_name == method_name
    and (all or (action.tick == tick)) then
      action.tick = -1 -- don't change the queue yet!
      log:debug('dequeue action → ', action)
      end
    end
  end

local function enqueue(module_name, method_name, tick, parameter)
  local action = {
    -- this is the event table for script.raise_event()
    module_name = module_name,
    method_name = method_name,
    tick        = tick,
    parameter   = parameter,
    }
  log:debug('enqueue action → ', action)
  table.insert(Savedata.queue, action)
  end
  

--------------------------------------------------------------------------------
-- TickedAction.
-- @section
--
-- @usage
--  -- settings.lua
--  erlib_enable_plugin('on_ticked_action')
--
--  -- control.lua
--  local Action = Remote.get_interface('erlib:on_ticked_action')
--  
--  local my_actions = {
--    doit = function(name)
--      print(name .. ' did it !')
--      end
--    }
--  
--  script.on_event(EventManagerLite.events.on_ticked_action, function(e)
--    if e.module_name == 'my-module' then
--      if e.method_name == 'doit' then
--        my_actions.doit(e.parameter.name)
--        end
--      end
--    end)
--    
--  script.on_event(defines.events.on_something_happend, function(e)
--    Action.enqueue('my-module', 'doit', 60*5, {name = 'The gardener'})
--    end)
--  
--  -- 5 seconds later
--  > The gardener did it!
--
--------------------------------------------------------------------------------
  
-- -------------------------------------------------------------------------- --
-- Remote Interface                                                           --
-- -------------------------------------------------------------------------- --

----------
-- Called when an action should happen. Events with the same tick are
-- raised in the order they were enqueued in.
--
-- See also @{EventManagerLite.events}
--
-- @field module_name @{string} The name you chose.
-- @field method_name @{string} The name you chose.
-- @field parameter @{AnyValue} The data you gave.
--
-- @table on_ticked_action
do end

----------
-- Plans a future action.
--
-- @tparam string module_name A name to identify your event later.
-- @tparam string method_name A name to identify your event later.
-- @tparam NaturalNumber|DenseArray offsets How many ticks from now
-- you want the action to happen. You can plan several ticks at once.
-- @tparam[opt] string|boolean|table|number parameter You can
-- store data here to retrieve it in the event later. The data
-- must survive a remote call, global Savedata save/load cycles
-- and script.raise\_event, so it's best to keep it simple. 
--
function TickedAction.enqueue(module_name, method_name, offsets, parameter)
  verify(module_name, 'NonEmptyString', 'Invalid module_name')
  verify(method_name, 'NonEmptyString', 'Invalid method_name')
  offsets = Table.plural(offsets)
  verify(offsets, 'NonEmptyDenseArrayOfNaturalNumber', 'Invalid offsets')
  -- <function> values do not survive the save/load cycle in Savedata, 
  -- and cause desyncs, but deep parsing a complex parameter table
  -- isn't worth the performance penalty.
  verify(parameter, 'nil|str|bool|tbl|num', 'Invalid parameter type')
  --
  for _, offset in ipairs(offsets) do
    enqueue(module_name, method_name, game.tick + offset, parameter)
    end
  --
  if Savedata.next_tick == nil then
    assert(#Savedata.queue == #offsets)
    end
  --
  update_next_tick()
  Private.update_handlers()
  end

----------
-- Cancels a future action before it happens.
--
-- @tparam string module_name
-- @tparam string method_name
-- @tparam[opt] NaturalNumber|DenseArray ticks You can either unplan
-- all actions with matching names, or only actions that were planned
-- for the given ticks.
--
function TickedAction.dequeue(module_name, method_name, ticks)
  verify(module_name, 'NonEmptyString', 'Invalid module_name')
  verify(method_name, 'NonEmptyString', 'Invalid method_name')
  verify(ticks, 'nil|NaturalNumber|NonEmptyDenseArrayOfNaturalNumber', 'Invalid ticks')
  --
  if ticks == nil then
    dequeue(module_name, method_name)
  else
    for _, tick in ipairs(Table.plural(ticks)) do
      dequeue(module_name, method_name, tick)
      end
    end
  end
  
  
-- -------------------------------------------------------------------------- --
-- Private Events                                                             --
-- -------------------------------------------------------------------------- --

Private.update_handlers = script.on_load(function()
  if Savedata then
    if Savedata.next_tick == nil then
      assert(#Savedata.queue == 0)
      script.on_event(defines.events.on_tick, nil)
    else
      assert(#Savedata.queue  > 0)
      script.on_event(defines.events.on_tick, Private.on_tick)
      end
    end
  end)

function Private.on_tick(e)
  local nt = assert(Savedata.next_tick, 'Missing next_tick')
  assert(nt >= e.tick, 'next_tick was in the past (on_tick)')
  --
  if nt == e.tick then
    for i=1, #Savedata.queue do
      local action = Savedata.queue[i]
      if action.tick == e.tick then
        log:debug('raise action → ', action)
        script.raise_event(on_ticked_action, action)
        end
      end
    --
    garbage_collect_queue()
    update_next_tick()
    end
  end
