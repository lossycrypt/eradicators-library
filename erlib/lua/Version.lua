-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------
-- Comparison of "Major.Minor.Patch" triplets.
--
-- @{Introduction.DevelopmentStatus|Module Status}: Experimental 2020-10-31.
--
-- @module Version
-- @usage
--  local Version = require('__eradicators-library__/erlib/factorio/Version')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

local stop = elreq('erlib/lua/Error')().Stopper('Version')

local function parse_version(vstr) -- string "Major.Minor.Patch"
  -- V1 Three-in-one -> vtr:match'^(%d+)%.(%d+)%.(%d+)$'
  local major = tonumber(vstr:match'^(%d+)%.?%d*%.?%d*$'      ) --'1'     -> (1,_,_)
  local minor = tonumber(vstr:match'^%d+%.(%d+)%.?%d*$' or '0') --'x.1'   -> (_,1,_)
  local patch = tonumber(vstr:match'^%d+%.%d+%.(%d+)$'  or '0') --'x.x.1' -> (_,_,1)

  if not major then stop('Invalid Version String: <'..vstr..'>') end
  return major,minor,patch end

local function gtr(verA,verB)
  local a,b,c = parse_version(verA)
  local x,y,z = parse_version(verB)
  return (a>x) or (a==x and b>y) or (a==x and b==y and c>z)
  end

local ops = {}
  ops['>' ] = gtr                                                     
  ops['>='] = function(A,B) return not  gtr(B,A)                   end
  ops['=='] = function(A,B) return not (gtr(A,B) or      gtr(B,A)) end
  ops['~='] = function(A,B) return     (gtr(A,B) or      gtr(B,A)) end
  ops['<='] = function(A,B) return not  gtr(A,B)                   end
  ops['<' ] = function(A,B) return      gtr(B,A)                   end
  ops['!='] = ops['~=']

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Version,_Version,_uLocale = {},{},{}

----------
-- Compares two version strings directly. If minor or patch are blank they
-- are assumed to be 0.
-- 
-- @tparam string versionA
-- @tparam string operator  One of >, >=, ==, !=, ~=, <=, <
-- @tparam string versionB 
-- @treturn boolean
-- 
-- @usage
--   print(Version.compare('1','==','1.0.0'))
--   > true
-- 
--   print(Version.compare('2.3.5','>','2.0'))
--   > true
--
--   print(Version.compare('2.3.5','>','2.3.5'))
--   > false
-- 
--   print(Version.compare('555','~=','555.0.0'))
--   > false
-- 
-- @function Version.compare

function Version.compare(verA,operator,verB)
  return ops[operator](verA,verB)
  end


----------
-- Converts a version string to three @{int} values.
--
-- @tparam string versionA
--
-- @treturn uint major
-- @treturn uint minor
-- @treturn uint patch
--
function Version.parse(versionA)
  return parse_version(versionA)
  end
  
  
-- -------------------------------------------------------------------------- --
-- Experiment                                                                 --
-- -------------------------------------------------------------------------- --

-- Can this be inlined with metatables?
-- Would've been nice to be able to do: Version('1.1') == '1.1.0'
--
-- Conclusion: NOPE!
--   Lua does NEVER call the __eq method unless both 
--   operands are already of the same type! __le does
--   work, but it's really bad trap if == always returns false.
--
-- local mt = {
--   __eq = function(A,B)
--     A, B = A[1] or A, B[1] or B -- Lua string indexing returns nil. Weird!
--     return ops['=='](A,B) end,
--   __lt = function(A,B)
--     -- Lua is smart and deduces <, <=, >, >= from a single "less than" function.
--     A, B = A[1] or A, B[1] or B
--     return ops['<'](A,B) end
--     }
-- setmetatable(Version, {__call=function(_,str) return setmetatable({str},mt) end})
  
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Version') end
return function() return Version,_Version,_uLocale end
