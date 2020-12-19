-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Description
--
-- @{Introduction.DevelopmentStatus|Module Status}: Work in progress.
--
-- @module Train
-- @usage
--  local Train = require('__eradicators-library__/erlib/factorio/Train')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

local Array = elreq('erlib/lua/Array')()

local L = elreq('erlib/lua/Lambda')()

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Train,_Train,_uLocale = {},{},{}

Train.Schedule = {}

-- -------
-- Nothing.
-- @within Todo
-- @field todo1

--------------------------------------------------------------------------------
-- LuaTrain.
-- @section
--------------------------------------------------------------------------------

----------
-- @tparam LuaTrain train
-- @treturn LuaEntity
function Train.get_first_locomotive(train)
  -- Every train has at least one front mover.
  return train.locomotives.front_movers[1]
  end
  
----------
-- @tparam LuaTrain train
-- @treturn LuaForce The force of the first locomotive.
function Train.get_force(train)
  return Train.get_first_locomotive(train).force
  end

  
----------
-- @tparam LuaTrain train
-- @treturn LuaPosition The position of the first locomotive.
function Train.get_position(train)
  return Train.get_first_locomotive(train).position
  end
  
  
--------------------------------------------------------------------------------
-- TrainSchedule.
-- __Important Note:__ Lua `nil` is a valid TrainSchedule, it represents a
-- schedule without any stations.  
--
-- @section
--------------------------------------------------------------------------------


-- Factorio expects a completely empty schedule to be primary "nil",
-- which is annoying when trying to deal with it as a table.
--
-- So these two functions allow an intermediate state where a
-- table represents the empty schedule.

-- if nil -> fake table
--
-- @tparam table|nil train_schedule
-- @treturn table
local function normalize_input_schedule(train_schedule)
  return train_schedule or { current = 0, records = {} }
  end

-- if fake table -> nil
--
-- @tparam table train_schedule
-- @treturn table|nil
local function normalize_output_schedule(train_schedule)
  local n = #train_schedule.records
  -- empty?
  if (n < 1) then
    return nil
  -- invalid current index?
  elseif (train_schedule.current < 1) or (train_schedule.current > n) then
    train_schedule.current = 1
    end
  --
  return train_schedule
  end
  

----------
-- @tparam TrainSchedule|nil train_schedule
-- @tparam NaturalNumber|string index Accepts string `"current"` instead of a number.
--
-- @treturn TrainSchedule|nil
--
function Train.Schedule.remove_record(train_schedule, index)
  train_schedule = normalize_input_schedule(train_schedule)

  if index == 'current' then index = train_schedule.current end
  
  table.remove(train_schedule.records, index)
  if train_schedule.current < index then
    train_schedule.current = train_schedule.current - 1
    end
    
  return normalize_output_schedule(train_schedule)
  end
  
  
----------
-- @tparam TrainSchedule|nil train_schedule
-- @tparam[opt] NaturalNumber|string index Adds at end if not given, or
-- at current position if string `"current"`.
-- @tparam TrainScheduleRecord record
--
-- @treturn TrainSchedule|nil
--
function Train.Schedule.add_record(train_schedule, index, record)
  train_schedule = normalize_input_schedule(train_schedule)
  
  if index == 'current' then index =  train_schedule.current   end
  if index == nil       then index = #train_schedule.records+1 end
  if index == 0         then index =  1                        end
  table.insert(train_schedule.records, index, record)
  
  return normalize_output_schedule(train_schedule)
  end


----------
-- @tparam TrainSchedule|nil train_schedule
--
-- @treturn TrainSchedule|nil
--
function Train.Schedule.remove_all_temporary_stops(train_schedule)
  train_schedule = normalize_input_schedule(train_schedule)

  -- Fix current index if any to-be-removed temporary records are *before* it.
  for i=1, train_schedule.current-1 do
    if train_schedule.records[i].temporary then
      train_schedule.current = train_schedule.current - 1
      end
    end

  -- Remove all temporary stops.
  Array.filter(train_schedule.records, L['x->not x.temporary']); 

  return normalize_output_schedule(train_schedule)
  end
  
  
  
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Train') end
return function() return Train,_Train,_uLocale end
