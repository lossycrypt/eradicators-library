-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

local Table       = elreq('erlib/lua/Table'     )()


-- -------------------------------------------------------------------------- --
-- Blank Dictionary                                                           --
-- -------------------------------------------------------------------------- --

-- inverse ipairs()
local function sriapi(arr)
  local i = #arr + 1
  return function() i = i - 1 return arr[i] and i, arr[i] end
  end

local function push(stack, value)
  local n = stack.n + 1
  stack.n = n
  stack[n] = value
  return value end

local new; local function fill(); new = {--[[
  requests = { -- first-in-first-out stack
    [1] = {'item-name.iron-plate'}, -- real localised string
    n = 1,
    max = 100, -- for how-much-done-yet statistics
    },
  lookup = {
    "serpent.line(ironplate.name)" = {
      request_index = 1, --faster removal
      path = {'item_name','iron-plate'}
      },
  dict = {
    'item_name' = {
      ['iron-plate'] = 'ìSî¬èƒÇ´ÇæÇ∆ÅHÅI',
      }
    }
    }
  ]]}
  
  -- Need to seperate requests by category to be able to seperately
  -- detect completition (and also cheaper array removal)
  
  -- needs to make a seperate sub-dictionary per category
  -- that stores requests + flags + etc
  
  new.requests = {n=0}
  new.lookup   = {}
  new.dict     = {}
  new.valid = false
  for _, type in sriapi(game.mod_setting_prototypes
  [const.setting.auto_translate_categories].allowed_values) do
    new.dict[type..'_name'] = {}
    new.dict[type..'_description'] = {}
    new.lookup = {}
    --
    for name, prot in pairs(game[type..'_prototypes']) do
      new.lookup[push(new.requests, ident(prot.localised_name))]
        = {request_index = new.requests.n, path = {type..'_name', prot.name}}
      new.lookup[push(new.requests, ident(prot.localised_description))]
        = {request_index = new.requests.n, path = {type..'_description', prot.name}}
      end
    --
    end
  return new end

    
    
    
-- -------------------------------------------------------------------------- --
return function() return Table.dcopy(new or fill()) end
  