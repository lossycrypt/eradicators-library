-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Produces auto-formatting auto-serializing errors handlers.
--
-- @{Introduction.DevelopmentStatus|Module Status}: Experimental 2020-10-31.
--
-- @module Error
--
-- @usage
--   local Error = require('__eradicators-library__/erlib/factorio/Error')()
-- @usage 
--   Error.Error('MyModName','MyErrorName',"Sorry, i can't do that Dave!",nil,nil,
--   nil,'shit',{'is','hitting',{'the','fence!'}},{'near','the','fox'}, nil,nil,nil )
-- @usage
--   > ##### [MyModName : MyErrorName] #####
--   > I suspected this might happen. Please tell me how you got here.
--   > 
--   > Sorry, i can't do that Dave!
--   > shit
--   > {"is", "hitting", {"the", "fence!"}}
--   > {"near", "the", "fox"}
--   > 
--   > (6 nil values removed.)
--   > control.lua:18 > some_module.lua:67
--   > ############################

-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- -------------------------------------------------------------------------- --

local Stacktrace = require(elroot.. 'erlib/factorio/Stacktrace')()
local Hydra      = require(elroot.. 'erlib/lua/Coding/Hydra'   )()

local table,type,pairs,tostring
    = table,type,pairs,tostring

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Error,_Error,_uLocale = {},{},{}

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- -------------------------------------------------------------------------- --
-- The Error module is a cornerstone of the framework and thus
-- it can not rely on Array or Table. So it uses some small customized
-- local formatting functions.


-- the error message
local template

if flag.IS_FACTORIO then
  template = {
    "  [color=default]                                                 ",
    "  ##### [%s : %s] #####                                           ",
    "  I suspected this might happen. Please tell me how you got here. ",
    "                                                                  ",
    "  [color=red]%s[/color]                                           ",
    "                                                                  ",
    "  [color=green](%s nil values removed.)[/color]                   ",
    "  [color=green]%s > %s[/color]                                    ",
    "  ############################                                    ",
    "  [/color]                                                        ",
    }
else
  template = {
    "  ##### [%s : %s] #####                                           ",
    "  Error.                                                          ",
    "                                                                  ",
    "  %s                                                              ",
    "                                                                  ",
    "  (%s nil values removed.)                                        ",
    "  %s > %s                                                         ",
    "  ############################                                    ",
    }
  end
  
-- remove extra whitespace (from indented code representation)
for i,l in pairs(template) do template[i]=l:match' *(.-) *$' end
-- finalize into one string
template = table.concat(template,'\n')

-- Removes all nil values from an Array.
-- @varargs AnyValue ...
local function to_dense_array(...)
  local args = table.pack(...) --contains n=
  local r = {}
  -- local n = 0; for i in pairs(arr) do if i>n then n=i end end
  for i=1,args.n do r[#r+1] = args[i] end 
  return r
  end
  

-- Replaces all values given with a string representation.
-- @tparam Table tbl, containing AnyValue
-- @treturn an Array of strings
local simplify; do

  -- Copied code: String.to_string, Log._to_table_of_strings, Error.simplify
  local _simplify = {
    ['nil'     ] = function( ) return '<nil>'      end,
    ['boolean' ] = tostring                           ,
    ['number'  ] = tostring                           ,
    ['string'  ] = function(x)
      if x ~= '' then return x
      else return '<empty string>' end end,
    ['thread'  ] = function( ) return '<thread>'   end,
    ['function'] = function( ) return '<function>' end,
    ['userdata'] = function( ) return '<userdata>' end,
    ['table'   ] = function(x) return Hydra.line(x,{nocode=true,showref=true}) end,
    }
  function simplify(tbl)
    for k,v in pairs(tbl) do
      tbl[k] = _simplify[type(v)](v)
      end
    return tbl
    end
  end

  
-- Cut each string in arr down to at most length n. This is an in-place
-- operation but arr is returned for convenience.
-- @tparam Array arr an Array of strings
-- @tparam NaturalNumber n the maximum length
-- @treturn Array
local function shorten(arr,n)
  for i=1,#arr do arr[i] = arr[i]:sub(1,n) end
  return arr
  end

      
-- -------------------------------------------------------------------------- --
-- Functions                                                                  --
-- -------------------------------------------------------------------------- --

--The standard error handler used for all error raising.
--Can be called with any number of arguments and attempts to print them sufficiently nice.
--Example: Error('ALERT!','shit',{'is','hitting',{'the','fence!'}},{'near','the','fox'})
      
----------
-- The raw error handler called by all Error instances.
-- Will print an error message as shown above. All varargs will be serialized
-- if required and printed one per line.
--
-- @tparam[opt] AnyValue prefix the prefix part of the error message header.
-- This should usually be the erroring mods name.
-- @tparam[opt] AnyValue postfix the name of the module that caused the error.
-- @tparam[opt] AnyValue ... all the AnyValue you want in the message.
--
-- @function Error.Error
--
local _error = function(prefix,postfix,...)

  --table.concat does not work on sparse arrays so nil values must be stripped
  --this is also nice becaues it removes empty args generated by Closurize()
  local args = shorten(simplify(to_dense_array(prefix,postfix,...)),100)

  local err = template:format(
    args[1],
    args[2],
    -- table.concat({table.unpack(args,3)},'\n'), -- don't impose any formatting
    table.concat({table.unpack(args,3)},''),
    select('#',...) - #args + 2,
    Stacktrace.get_pos(4) or '?',--? == probably already at bottom of stack
    Stacktrace.get_pos(3) or '?' --this must be *exactly* 2 above the outside caller
    )

  error(err,0) -- without built-in level info
  end
  

-- Ensure fixed stack offset for all Error functions! (doc -> local Error)
Error.Error = function(prefix,postfix,...)
  _error(prefix,postfix,...)
  end
      
----------
-- Fabricates a customized @{Error.ErrorRaiser|ErrorRaiser}
-- with closurized prefix and postfix.
--
-- @usage
--   local MyError = Error.Stopper('MyModName','MyErrorName')
--   if not is_everything_ok then
--     MyError('something is broken!')
--     end
--
-- @usage
--   local MyError = Error.Stopper('MyErrorName')
--   if not is_everything_ok then
--     MyError('something is broken!')
--     end
-- 
-- @tparam[opt="YourModName"] AnyValue prefix 
-- @tparam AnyValue postfix
--
-- @raise CustomError
-- 
-- @treturn ErrorRaiser
-- 
Error.Stopper = function(prefix,postfix)
  if postfix == nil then
    postfix = prefix
    prefix  = Stacktrace.get_mod_name(2)
    end
  return function(...) _error(prefix,postfix,...) end
  end

--------------------------------------------------------------------------------
-- ErrorRaiser
-- @section
--------------------------------------------------------------------------------
  
----------
-- Raises an error with the given message and the closurized pre- and postfix.
--
-- @tparam[opt] AnyValue ... Arbitrary values to be displayed in the error message.
--
-- @raise CustomError
--
-- @function ErrorRaiser
  
  
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Error') end
return function() return Error,_Error,_uLocale end
