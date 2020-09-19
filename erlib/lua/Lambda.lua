-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Short in-line definition of functions. Similar to Python.
--
-- @module Lambda
-- @usage
--  local Lambda = require('__eradicators-library__/erlib/factorio/Lambda')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,err,elreq,flag = table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local Hydra = elreq('erlib/lua/Coding/Hydra')()

local Lambda,_Lambda,_uLocale = {},{},{}

local upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
local lower = 'abcdefghijklmnopqrstuvwxyz' --not used


-- Pre-generate all 26 possible upvalue headers and put them
-- into a table indexed by upvalue count.
-- [1] = "local A=...;"
-- [2] = "local A,B=...;"
-- [3] = "local A,B,C=...;"
local upvalue_strings = {[0]=''} -- No Upvalues No String.
do setmetatable(upvalue_strings,{
  __index=function(_,key) return 'Too many upvalues! ' end
  }) end
do (function(l,r)
  for i=1,#l do
    r[i] = ('local %s=...;'):format(
      l:sub(1,i)       --partial string
      :gsub('.','%1,') --comma seperate
      :sub(1,-2)       --no comma after last
      )
    end
    return r end)(upper,upvalue_strings)
  end


-- Throws formatted errors.
local function lambda_err(msg,spec,...)
  ---@todo use erlib.Logger
  local template = '%s\n  Function: %s \n  Upvalues: %s.'
  error(template:format(msg,Hydra.line(spec),Hydra.lines{...}))
  end
  
  
-- Converts a LambdaFunctionSpecification into a lodable string
-- Example 1: L('v,k,tbl:tbl[v]=true') → "return function(v,k,tbl) tbl[v]=true end"
-- Example 2: L('a,b -> a+2*b')        →　"return function(a,b) return a+2*b end"
-- @tparam string spec LFS
-- @treturn string
local function parse_spec(spec)
  -- split by (:|->) colon or arrow 
  local f_tbl = {spec:match('(.-)%s*(-?[>:])%s*(.*)')}
  -- at least one colon or arrow is mandatory!
  if #f_tbl ~= 3 then return nil end
  -- colon splits, arrow splits and returns
  if f_tbl[2] == '->' then f_tbl[3] = 'return '..f_tbl[3] end
  -- double arrow will treat everything after it as a nested Lambda call (experimental)
  f_tbl[3] = (f_tbl[3]:gsub('=>(.*)',' return Lambda(%1)'))
  -- a loadable string that when called will return the Lambda function.
  return ('return function(%s) %s end'):format(f_tbl[1],f_tbl[3]) --head+body
  end
  
-- Converts a LambdaFunctionSpecification into a LambdaLoader. The Loader
-- produces the actual function when called with the upvalues.
-- @tparam string spec LFS
-- @tparam AnyValue ... varargs are only used for errors and upvalue counting
-- @tparam function the *loader* is not the actual function yet
local make_loader; function make_loader(spec,...)
  local f_str = parse_spec(spec)
  if f_str == nil then lambda_err('Invalid Lambda head or body',spec,...) end
  local n = select('#',...)
  -- Produce a human-readable representation for error messages.
  local repr = f_str:gsub('^return function','Lambda <f')..'>'
  if n > 0 then repr = repr:gsub('^Lambda','Lambda (%%s upvalues)'):format(n) end
  if (n > 26) then lambda_err('Too many Lambda upvalues. (Max 26)',repr,...) end
  f_str = upvalue_strings[n]..f_str
  -- Empty environment except for recursive-lambda support
  local f_loader,err = load(f_str,repr,'t',{Lambda=Lambda}) -- chunk,name_on_stack,text_mode,env
  if (f_loader==nil) or (err~=nil) then lambda_err('Error:'..err,repr,...) end
  return f_loader
  end

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

---@todo implement proper Memoize and apply to upvalued loaders?
---      upvalued loaders need to be cached on the user side anyway though.

local Lambda_mt = {}
setmetatable(Lambda,Lambda_mt)


--Variants with upvalues are *never* memoized. Too many possible variants.
function Lambda_mt. __call(self,spec,...)
  return (make_loader(spec,...)(...))
  end


--Index implies the function does not yet exist
function Lambda_mt. __index(self,spec)
  print('created',spec)
  self[spec] = make_loader(spec)() --memoize with zero upvalues
  return self[spec]
  end

--------------------------------------------------------------------------------
-- Section
-- @section
--------------------------------------------------------------------------------
L = Lambda --debug
----------
-- Foo
-- @table Foo
-- @usage

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Lambda') end
return function() return Lambda,_Lambda,_uLocale end
