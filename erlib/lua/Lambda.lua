-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Short in-line definition of functions, similar to Python.
-- 
-- @module Lambda
-- @usage
--  local Lambda = require('__eradicators-library__/erlib/lua/Lambda')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

local Hydra = elreq('erlib/lua/Coding/Hydra')()

local Lambda,_Lambda,_uLocale = {},{},{}

local select, rawget, load, setmetatable = select, rawget, load, setmetatable


-- This will catch the upvalues of a Lambda function. Because functions do not
-- "see" upvalues they do not use this can be used for all functions regardless
-- of actual upvalue count without any performance cost.
-- Thus the same specification can always use the same loader even if 
-- the actual instance of the loaded function has varying upvalues.
local upstr = 'local A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z=...; '


-- For meaningful caching all Lambda functions of the same spec implicitly 
-- run inside the same environment. At that point i might aswell make all
-- Lambdas run in the same environment and just block using it. This'll saves
-- a few bytes for empty tables while at it and allow precise control over
-- what functions will be available.
--
-- Sure, someone could still smuggle in arbitrary functions as upvalues,
-- but i don't care if they want to shoot themselfs into the feet.
--
local LambdaEnv = setmetatable({
  Lambda = Lambda, -- for recursive lambda
  pairs  = pairs , -- the basics
  },{
  __index    = function(_,key)
    error(("A lambda function attempted to read a global value ('%s')"):format(key))
    end,
  __newindex = function(_,k,v)
    error(("A lambda function attempted to write a global value ('%s':'%s')"):format(k,v))
    end,
  })
  

-- Throws formatted errors.
local function lambda_err(msg,spec)
  --@todo use erlib.Logger
  local template = '%s\n  Function: %s.'
  error(template:format(msg,Hydra.line(spec)))
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
local get_loader = setmetatable({},{
  __index = function(self,spec)
    local f_str = parse_spec(spec)
    if f_str == nil then lambda_err('Invalid Lambda head or body',spec) end
    -- Produce a human-readable representation for error messages.
    local repr = f_str:gsub('^return function','Lambda <f')..'>'
    -- Empty environment except for recursive-lambda support
    local f_loader,err = load(upstr..f_str,repr,'t',LambdaEnv) -- chunk,name_on_stack,text_mode,env
    if (f_loader==nil) or (err~=nil) then lambda_err('Error:'..err,repr) end
    ---@todo implement multi-argument say()
    say('  Lambda loader cached: '..repr)
    self[spec] = f_loader
    return f_loader
    end})

 
 
-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local cache_size = 0 ---@todo implmenent and use Memoize for get_loader and __index

setmetatable(Lambda,{

  -- Memoize the actual upvalue-free function.
  __index = function(self,spec)
    cache_size = cache_size + 1
    if cache_size > 9000 then
      warn('  Lambda cache was OVER NINE THOUSAND! Wiping cache.')
      for k in pairs(self) do self[k] = nil end
      end
    self[spec] = get_loader[spec]() 
    return self[spec]
    end,

  -- Never memoize function instances with upvalues.
  -- There's just too many ways that could go wrong.
  __call= function(self,spec,...)
    local n = select('#',...)    
    if     n == 0 then
      return self[spec]
    elseif n > 26 then
      lambda_err('Too many Lambda upvalues. (Max 26)',spec)
    elseif rawget(self,spec) ~= nil then
      -- This is unlikely to actually happen because an LFS that actually
      -- uses upvalues would inheritely look different from one that doesn't.
      -- But it can't be allowed because it messes up the memoization of 
      -- upvalue-free variants.
      lambda_err(
        'Attempt to use Lambda function with upvalues,'..
        'but the same Lambda function is already cached without upvalues.'
        ,spec)
    else
      return get_loader[spec](...)
      end
    end,

  })



--------------------------------------------------------------------------------
-- Lambda
-- @section
--------------------------------------------------------------------------------

-- (documentation only section)

-----------
-- The only function of Lambda is itself. Calling it will generate the 
-- specified function. If any upvalues are given they will be available
-- from within the lambda function via the capital letter A,B,..,Z in 
-- the order they were given. No other functions or values are otherwise
-- usable from within a Lambda function.
--
-- Lambda function __without__ upvalues are only generated __once__ for every
-- @{Lambda.LambdaFunctionSpecification|LambdaFunctionSpecification}
-- after which the result is cached forever. You can directly call the
-- cached function by indexing Lambda instead of calling it. It will be 
-- transparently generated if it's the first time you call it. This is 
-- the fastest and most readable way to use Lambda functions, but you can
-- not supply custom upvalues this way.
--
-- If you want to use a Lambda function __with__ upvalues you should store
-- it somewhere. Lambda does cache some intermediate generation steps but
-- the final resulting closure is unique for each call.
--
--
-- @usage
--   -- Let's say you want to multiply a number.
--   local f = function(x) return 2*x end
--   -- You can now write that shorter.
--   local f = Lambda('x: return 2*x')
--   -- And shorter.
--   local f = Lambda['x->2*x']
-- @usage
--   -- You can use multiple arguments.
--   local f = Lambda['x,y,z->2*x+y*z']
-- @usage
--   -- Or fixed upvalues.
--   local f = Lambda('str->str..A..B','wordA','wordB')
--   local s = f('wordC')
--   print(s)
--   > wordCwordAwordB
-- @usage
--   -- Use it when you don't want to store the function.
--   print(Lambda'x->x..x'('once'))
--   > onceonce
--
--
-- @tparam LambdaFunctionSpecification spec
-- @tparam[opt] AnyValue ... Upvalues. Accessible as A,B,...,Z
-- @function Lambda


-----------
-- A @{string} that @{Lambda} parses into a function. It consists of 
-- three parts.
--
--
-- @field head A comma seperated list of arguments that the Lambda should take.
--
-- @field divider A ":" colon marking the end of the list of arguments or a
-- "->" single arrow marking the end of arguments and simultaenously the
-- beginning of the return values.
--
-- @field body Everything after the divider. If the body contains a "=>"
-- double arrow then everything after that arrow is considered to be
-- *another* Lambda function call.
--
-- __Note__: Lambda-nesting with "=>" is an experimental feature subject to change.
--
-- @table Lambda.LambdaFunctionSpecification
-- 
-- @usage
--   -- When you make a call...
--   Lambda('head: return body+A+B',UpValA,UpValB)
--   Lambda('head->       body+A+B',UpValA,UpValB)
--   -- ...this is the closure that Lambda will return to you.
--   local A,B = UpValA,UpValB
--   return function(head)
--      return body+A+B
--      end
--
-- @usage
--   -- Nested Lambdas are a bit more complicated...
--   Lambda('head: head = head+1 => "hair -> hair + A ",UpValA2',UpValB)
--   -- ...and produce this:
--   local A = UpValB
--   return function(head)
--     head=head+1
--     return Lambda("hair -> hair + A",UpValA2)
--     end
--   -- Beware that the second Lambda function will *never* see
--   -- the upvalues of the first one. Even if it has no upvalues itself.
--   -- You must pass them on manually.



-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Lambda') end
return function() return Lambda,_Lambda,_uLocale end
