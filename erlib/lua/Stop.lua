-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Produces nicely formatted errors.
--
-- @module Stop
-- @usage
--  local Stop = require('__eradicators-library__/erlib/factorio/Stop')()
--
-- @usage Stop.Error('MyModName','MyScript',"Sorry, i can't do that Dave!")
-- 
--  > ##### [MyModName : MyScript] #####
--  > I suspected this might happen. Please tell me how you got here.
--  > 
--  > Sorry, i can't do that Dave!
--  > 
--  > (0 nil values removed.)
--  > Debug.lua:45 > Debug.lua:60
--  > ############################

-- -------------------------------------------------------------------------- --
-- Import                                                                     --
-- -------------------------------------------------------------------------- --

local Debug = require('erlib/factorio/Debug')()

local table,type,pairs = table,type,pairs

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Stop,_Stop,_uLocale = {},{},{}

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- -------------------------------------------------------------------------- --
-- The Stop module is a cornerstone of the framework and thus
-- it can not rely on Array or Table. So it uses some small customized
-- local formatting functions.


-- the error message
local template  = {
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
  
  
-- Replaces all values given that are not natively stringifiable with a 
-- serpent.line representation.
-- @tparam Table tbl, containing AnyValue
-- @treturn an Array of strings and numbers
local simplify; do
  local keep  = {['string']=true,['number']=true}
  local sline = serpent.line
  function simplify(tbl)
    for k,v in pairs(tbl) do
      if not keep[type(v)] then
        tbl[k] = sline(v,{nocode=true})
          --make serpent function serialization nicer
          :gsub('function%(%) %-%-%[%[..skipped..%]%] end','<function>')
        end
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
--Example: Stop('ALERT!','shit',{'is','hitting',{'the','fence!'}},{'near','the','fox'})
      
----------
-- The raw error handler called by all Stop instances.
-- Will print an error message as shown above. All varargs will be serialized
-- if required and printed one per line.
--
-- @tparam AnyValue prefix, the prefix part of the error message header.
--         This should usually be the erroring mods name.
-- @tparam AnyValue name, the name of the module that caused the error.
-- @tparam AnyValue ..., all the AnyValue you want in the message.
--
-- @name Stop.Error
local Error = function(prefix,name,...)

  --table.concat does not work on sparse arrays so nil values must be stripped
  --this is also nice becaues it removes empty args generated by Closurize()
  local args = shorten(simplify(to_dense_array(prefix,name,...)),100)

  local err = template:format(
    args[1],
    args[2],
    table.concat({table.unpack(args,3)},'\n'),
    select('#',...) - #args + 2,
    Debug.get_pos(4),
    Debug.get_pos(3) --this must be *exactly* 2 above the outside caller
    )

  print(serpent.line('debugtest')               )
  local stack = Debug.get_info_stack()
  for i=#stack,0,-1 do
    print('Stack',i,serpent.line(stack[i]))
    end
  print(serpent.line(Debug.get_info())          )
  print(serpent.line(Debug.get_info(0))         )
  print(serpent.line(Debug.get_info(-1))        )
  print(serpent.line(Debug.get_pos(1))          )
  print(serpent.line(Debug.get_pos(-1))          )
  print(serpent.line((Debug.get_mod_name(0)) )    )
  print(serpent.line((Debug.get_mod_name( )) )    )
  print(serpent.line((Debug.get_mod_root(0)) )    )
  print(serpent.line((Debug.get_cur_dir (1)) )     ) --bugged no dir
  --asdf


  error(err,0) -- without built-in level info
  end
  

-- Ensure fixed stack offset for all Error functions!
Stop.Error = function(prefix,name,...)
  Error(prefix,name,...)
  end
      
Stop.Stopper = function(prefix,name)
  return function(...) Error(prefix,name,...) end
  end
  
Stop.SimpleStopper = function(name)
  local prefix = Debug.get_mod_name( )
  return function(...) Error(prefix,name,...) end
  end

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
return function() return Stop,_Stop,_uLocale end
