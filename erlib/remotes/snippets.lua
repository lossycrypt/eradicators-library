-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------
-- Random junk.
--
-- @{Introduction.DevelopmentStatus|Module Status}: Work in progress forever.
--
-- @module snippet
-- @usage
--  local snippet = require('__eradicators-library__/erlib/factorio/snippet')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

local Compare = elreq('erlib/lua/Compare')()

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local snippet,_snippet,_uLocale = {},{},{}


--------------------------------------------------------------------------------
-- Section.
-- @section
--------------------------------------------------------------------------------


----------
-- Compresses an array of random strings to fit into as fewest lines of 
-- as code possible. Does not respect element order obviouly. Used to better
-- encode long lists of stuff.
-- 
-- @tparam DenseArray arr
-- @tparam NaturalNumber target_length
-- 
-- @treturn string
--
-- @usage
--   local r={}; for i=1,10 do r[#r+1] = ('0'):rep(i) end
--   print(snippet.compact_repr_arr_of_string(r,22))
--
--   > {
--   "0000000000","000000",
--   "000000000","0000000",
--   "00000000","00000",
--   "0000","000","00","0",
--   }
function snippet.compact_repr_arr_of_string(arr, target_length)
  local arr = Table.dcopy(arr)
  table.sort(arr, Compare.STRING_SHORTER)
    
  local target_length = target_length or 78
  local overhead = 3 -- two quotes and one comma
  local r, line_length = '{\n', 0
    
  local stalled = false -- When there are no strings left to fill the gaps
  while #arr > 0 do
    local str
    for i=#arr, 1, -1 do
      if target_length >= (line_length + overhead + #arr[i]) then
        str = table.remove(arr,i)
        stalled = false
        break
        end
      end
    if str or stalled then
      str = str or table.remove(arr,1)
      r = r..('"%s",'):format(str)
      line_length = line_length + overhead + #str
    else
      r = r.. '\n'
      line_length = 0
      stalled = true
      end
    end
  return r..'\n}'
  end




----------
-- Nothing.
-- @within Todo
-- @field todo1

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.snippet') end
return function() return snippet,_snippet,_uLocale end
