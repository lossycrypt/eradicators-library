-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Reusable class creation patterns.
--
-- @module Class
-- @usage
--  local Class = require('__eradicators-library__/erlib/lua/Class')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local stop = elreq('erlib/lua/Error')().Stopper('Class')

local SwitchCase = elreq('erlib/lua/Meta/SwitchCase')()

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Class,_Class,_uLocale = {},{},{}



--------------------------------------------------------------------------------
-- @section end
--------------------------------------------------------------------------------

----------
-- Creates a new simple class with build in initialization-by-call.
-- Can be easily extended after creation.
--
--
-- @tparam function initializer When a SimpleClass(...) is called directly
-- then all arguments are passed to the initializer(...). The expected output
-- is an instantiated ClassObject__Without__Metatable or @{nil}. If an object
-- was return then the classes metatable will be automatically attached.
--
-- @tparam[opt] function finalizer If a finalizer is given and the initializer
-- did not return nil, then the finalizer will be called called with the
-- ClassObject__With__Metatable that was produced by the
-- initializer. The return value of the finalizer is irrelevant.
--
-- @usage
--    -- First define a new class.
--    local MyClass = Class.SimpleClass(
--      -- The initializer must return a table.
--      function(number,name)
--        return {value = number, name = name}
--        end,
--      -- The finalizer can access all class methods.
--      -- Even if they're defined later!
--      function(object)
--        if object.value < 5 then
--          object:add(5)
--          end
--        end)
--
--    -- Now you should add some methods to the class.
--    function MyClass:add (x)
--      self.value = self.value + x
--      end
--    function MyClass:show()
--      print(('You have %s %s.'):format(self.value,self.name))
--      end
--
--    -- And instantiate objects
--    local fruits = MyClass(42,'bananas')
--    fruits:show()
--    > You have 42 bananas.
--
--    -- Notice how the finalizer will call :add()
--    local vegetables = MyClass(1,'tomatos')
--    vegetables:show()
--    > You have 6 tomatos.
--
-- @within Class Creation
-- @function Class.SimpleClass

_Class.SimpleClass = {
  [1] = 'function',
  [2] = 'function',
  }
function Class.SimpleClass(initializer,finalizer)
  local class, class_mt = {}, {}
  local object_mt = {__index=class}
    
  ------------------------------------------------------------------------------
  -- SimpleClass built-in methods.
  -- @section
  ------------------------------------------------------------------------------
    
  ----------
  -- Instantiates a new object of the class by passing it 
  -- through the initializer and the finalizer. Finally it
  -- returns the object.
  -- @tparam AnyValue ... Any data needed to initialize a ClassObject.
  -- @treturn ClassObjectWithMetatable
  -- @function MySimpleClass
  class_mt .__call = function(self,...)
      local object, extra = initializer(...)
      if extra ~= nil then
        stop('SimpleClass','Normalizer returned unexpected extra data:\n',extra)
        end
      if object ~= nil then
        --@todo measure performance impact of this check
        if type(object) ~= 'table' then
          stop('SimpleClass','Normalizer did not return a table:\n',object)
          end
        setmetatable(object,object_mt)
        if finalizer then finalizer(object) end
        return object
        end
      end
      

  ----------
  -- Unconditionally attaches this classes metatable to an object.
  -- Allows you to skip the normalization process if you already
  -- know that the object is a valid member of this class.
  --
  -- @tparam table object A ClassObject that has lost it's metatable.
  -- @treturn ClassObjectWithMetatable
  --
  -- @function MySimpleClass.reclassify
  class .reclassify = function(object)
      return setmetatable(object,object_mt)
      end

      
  return setmetatable(class,class_mt)
  end

--------------------------------------------------------------------------------
-- @section end
--------------------------------------------------------------------------------


----------
-- A class initializer based on a @{Meta.SwitchCase}.
--
-- __Note:__ If the case function returns a ClassObject__With__Metatable then
-- the metatable for this class will __not__ be attached. A possible usecase
-- for this is for example an "invalid" case that returns an object that
-- doesn't instantly crash class methods but is still not a full member.
--
-- @tparam function analyzer 
-- @tparam table cases
--
-- @within Class Creation
-- @function Class.SwitchCaseClass
-- 
-- @usage
--    local MyClass = Class.SwitchCaseClass(
--      function(input)
--        if type(input) == 'table' then
--          return 'invalid'
--          end
--        return type(input)
--        end,
--      {
--        string  = function(x) return {value = tostring(x),source = 'string '} end,
--        number  = function(x) return {value =          x ,source = 'number '} end,
--        default = function(x) return {value =          0 ,source = 'default'} end,
--        invalid = function(x) return setmetatable(
--          {valid=false},
--          {__index = function()
--            error('Error! Reading data from an invalid object is not allowed!')
--            end }
--          ) end
--      })
--
--    function MyClass:show()
--      print(('This was a %s and now has value %s.'):format(self.source,self.value))
--      end
-- 
--    local MyObjectA = MyClass('42')
--    MyObjectA:show()
--    > This was a string  and now has value 42.
-- 
--    local MyObjectB = MyClass(24)
--    MyObjectB:show()
--    > This was a number  and now has value 24.
-- 
--    local MyObjectC = MyClass(true)
--    MyObjectC:show()
--    > This was a default and now has value 0.
-- 
--    local MyObjectD = MyClass.reclassify {value = 17, source = 'secret operation'}
--    MyObjectD:show()
--    > This was a secret operation and now has value 17.
--
--    local MyObjectE = MyClass({dummy=0})
--    MyObjectE:show()
--    > Error! Reading data from an invalid object is not allowed!
--
function Class.SwitchCaseClass(analyzer,cases)
  local class, class_mt = {}, {}
  local object_mt = {__index=class}

  local switch = SwitchCase(analyzer,cases)
  
  ------------------------------------------------------------------------------
  -- SwitchCaseClass built-in methods.
  -- @section
  ------------------------------------------------------------------------------
  
  ----------
  -- Instantiates a new object of the class by calling the
  -- appropriate case function. Finally it returns the object.
  --
  -- @tparam AnyValue ... Any data needed to initialize a ClassObject.
  -- @treturn ClassObjectWithMetatable
  -- @function MySwitchCaseClass
  --
  function class_mt .__call (self,...)
      local object, extra = switch(...)
      if extra ~= nil then
        stop('SwitchCaseClass','SwitchCase returned unexpected extra data:\n',extra)
        end
      if object ~= nil then
        if type(object) ~= 'table' then
          stop('SwitchCaseClass','SwitchCase did not return a table:\n',object)
          end
        if not getmetatable(object) then -- do not overwrite if initializer added custom meta?
          --- @fixme Maybe there are better solutions.
          -- Router uses a custom "invalid" default object but 
          -- that can't be used with cases.default if the meta
          -- is overwritten.
          setmetatable(object,object_mt)
        else
          print('had metatable')
          end
        return object
        end
      end

  ----------
  -- metatable compatiblity @ Belt Router
  -- @within TODO TOMORROW
  -- @field Check
    
  ----------
  -- Unconditionally attaches this classes metatable to an object.
  -- Allows you to skip the normalization process if you already
  -- know that the object is a valid member of this class.
  --
  -- @tparam table object A ClassObject that has lost it's metatable.
  -- @treturn ClassObjectWithMetatable
  --
  -- @function MySwitchCaseClass.reclassify
  function class .reclassify (object)
      return setmetatable(object,object_mt)
      end
  
  
  return setmetatable(class,class_mt)
  end



-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Class') end
return function() return Class,_Class,_uLocale end
