-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Description
--
-- @module Lock
-- @usage
--  local Lock = require('__eradicators-library__/erlib/factorio/Lock')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local String = elreq('erlib/lua/String')()
local Hydra  = elreq('erlib/lua/Coding/Hydra')()
local stop   = elreq('erlib/lua/Error')().Stopper('Auto-Lock Table')

local function Locked(name,mode)
  return function (self,key,value) return stop( --tail call to reduce stack level for correct error level?
    ('"%s" is [color=red]*%s*[/color] locked.'):format(name,mode),
    '',
    ('key    = %s'):format(String.tostring(key)),
    (mode == 'read') and '' or 
    ('value  = %s'):format(String.tostring(value))
  ) end end
  
-- Debug Test Call: Locked('bla','write')(nil,'foo',table)

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Lock,_Lock,_uLocale = {},{},{}


----------
-- Prevents accidential writing to tables. Intended mainly to detect leaking
-- global access when you forgot to type "local" again. It is called "Auto"-Lock
-- because it re-locks any key as soon as it becomes nil, even if it had a
-- value before.
--
-- __Note:__ You have to manually remove this after your done if you use it in
-- any of the shared loading stages (data, settings).
--
-- @tparam table tbl The table to apply the lock to.
-- @tparam string name The table's name. Used for error messages.
-- @tparam[opt] string passphrase → usage examples are below.
-- @tparam[opt] function err_write A custom error handler. f(tbl,key,value)
-- @tparam[opt] function err_read A custom error handler. f(tbl,key)
-- 
-- @usage
--   -- Apply the lock to any table.
--   -- For this example we'll apply it to the global environment.
--   AutoLockTable(_ENV,'Global Environment','MyPassword')
--   
--   -- Accidential writing of ney keys will fail.
--   _ENV.A_New_Key = 'A new value!'
--   > Error! Global Environment is write locked!
-- 
--   -- Accidential read will also fail.
--   if _ENV.A_New_Key then print('not ok') end
--   > Error! Global Environment is read locked!
--   
--   -- Use __has_key instead.
--   if not _ENV.__has_key('A_New_Key') then print('ok') end
--   > ok
--   
--   -- The passphrase function allows you to explicitly circumvent the lock.
--   MyPassword('A_New_Key','A new value!')
--   print(_ENV.A_New_Key)
--   > A new value!
--   
--   -- Keys that become nil will become locked again.
--   _ENV.A_New_Key = nil
--   if _ENV.A_New_Key then print('not ok') end
--   > Error! Global Environment is read locked!
--   
--   -- You can declare a key global without assigning a value.
--   MyPassword('Another_New_Key')
--   if not Another_New_Key then print('ok this time!') end
--   > ok this time!
--   
--   -- It'll have the default value of boolean false.
--   if (Another_New_Key == false) then print('i got it') end
--   > i got it
--   
function Lock.AutoLock (tbl,name,passphrase,err_write,err_read)

  --already locked?
  if debug.getmetatable(tbl) then
    stop(('Can not lock "%s".'):format(name),'It already has another metatable.')
    end
    
  if type(name) ~= 'string' then
    stop('Missing table name.')
    end
  
  err_write = err_write or Locked(name,'write')
  err_read  = err_read  or Locked(name,'read' )
    
  local mt = {}; setmetatable(tbl,mt)

  mt .is_erlib_locked = true  -- to distinguish the mt from others 
  mt .name       = name
  mt .passphrase = passphrase -- for debugging make it readable
  mt .__metatable = false     -- don't allow accidentially overwriting the lock
  mt .__newindex  = err_write
  
  local idx = {
    __has_key        = function(key) return (rawget(tbl,key) ~= nil)        end,
    }
  if passphrase then
    -- "false" value is used when the key should only be declared "allowed"
    -- without actually assigning it a meaningful value yet.
    idx[passphrase] = function(key,value)   rawset(tbl,key,value or false) end
    end
  mt. __index = setmetatable(idx,{
      __index = function(_,key) err_read(tbl,key) end,
    })
    
  end
  
  
----------
-- Removes any locks created by this module. Will error if you try to remove
-- any other kind of lock or metatable.
-- @tparam table tbl
function Lock.RemoveLock(tbl)
  local mt = debug.getmetatable(tbl)
  if mt ~= nil then
    if mt.is_erlib_locked then
      debug.setmetatable(tbl,nil)
    else
      Stop('Can not remove metatable of unknown origin.')
      end
    end
  end

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Lock') end
return function() return Lock,_Lock,_uLocale end
