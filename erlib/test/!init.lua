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
local say,err,elreq,flag = table.unpack(require(elroot..'erlib/shared'))

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

-- load all test files
local n = #Tests
for i=1,n do
  -- does not preserve import order (and that's ok)
  Tests[Tests[i]] = {elreq('erlib/test/'..Tests[i])()}
  Tests[i] = nil
  end

-- execute all test files
for name,this in pairs(Tests) do
  if toset(this[2])[phase] then this[1]() end
  end
  
  
  
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.TestInit') end
return function() return TestInit,_TestInit,_uLocale end
