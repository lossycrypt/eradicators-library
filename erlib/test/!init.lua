-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

-- -----------------------------------------------
-- Runs all available tests. (Don't forget to re-generate the test list.)
--
-- @module TestInit
-- @usage
--  local TestInit = require('__eradicators-library__/erlib/test/TestInit')()

-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- -------------------------------------------------------------------------- --
local Stacktrace = elreq('erlib/factorio/Stacktrace')()

local Tests = elreq('erlib/test/!list')

local phase = flag.IS_FACTORIO and Stacktrace.get_load_phase().name or 'lua'

local toset = function(arr) local r = {} for _,v in pairs(arr) do r[v]=true end return r end

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

-- The log is easier to read if "Loaded" and "Test ok" messages
-- are in seperate blocks. To achieve this the Test list is iterated
-- once for loading and once for testing.

say('  Test   → Init.')

-- Factorio does not allow require() at runtime. So to run tests with
-- LuaGameScript available they have to be loaded before any events.
local function TestPreload()
  -- load all test files
  local n = #Tests
  for i=1,n do
    -- does not preserve import order (and that should be ok)
    -- Tests[Tests[i]] = {elreq('erlib/test/'..Tests[i])()}
    Tests[i] = {elreq('erlib/test/'..Tests[i])()}
    end
  end

TestPreload() --right now before it's too late! ;)
  
local function TestRun()
  -- execute all test files
  for i,this in ipairs(Tests) do
    if toset(this[2])[phase] then this[1]() end
    end
  say('  TESTR  → All green!')
  end

  
  
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.TestInit') end
return function() return TestRun end
