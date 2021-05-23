

-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))
-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local log         = elreq('erlib/lua/Log'       )().Logger  'BabelfishDictionary'
local stop        = elreq('erlib/lua/Error'     )().Stopper 'BabelfishDictionary'

local Verificate  = elreq('erlib/lua/Verificate')()
local verify      = Verificate.verify

local assertify  = elreq('erlib/lua/Error')().Asserter(stop)


local Class = elreq('erlib/lua/Class')()

local Table       = elreq('erlib/lua/Table'     )()

local pairs, ipairs
    = pairs, ipairs

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
local import = PluginManager.make_relative_require'babelfish'

local const  = import '/const'
local ident  = serpent.line

local ntuples = elreq('erlib/lua/Iter/ntuples')()

local AllowedTypes = (function(r,t)
  for i=1, #t do r[t[i]..'_name'] = true r[t[i]..'_description'] = true end
  return r end)({}, const.allowed_translation_types)

-- -------------------------------------------------------------------------- --
-- Blank Dictionary                                                           --
-- -------------------------------------------------------------------------- --

local make_new_dictionary; do 

  -- inverse ipairs()
  local function sriapi(arr)
    local i = #arr + 1
    return function() i = i - 1 return arr[i] and i, arr[i] end
    end



  local new
  
  local function fill(); new = {--[[
    requests = { 
      -- first-in-first-out stack SPARSE array with extra data.
      max = 100 -- maximum size for statistics
      n   = 1   -- number of open requests
      [1] = {
        type = 'item_name',
        name = 'iron-plate',
        lstring = {'item-name.iron-plate'}, -- real localised string
        i = 1, -- request index for faster removal
        next_request_tick = game.tick + 60, -- delay between requests
        bytes = 15, -- length of the ident string
        },
      },
      
    lookup = {
      "ident(ironplate.name)" = self.requests[1] -- table reference
      },
      
    language_code = 'en',
    
    -- can't keep the sizes inside the categories because there
    -- might be name conflicts.
    status = {
      item_name = { n = 1, max = 100},
      }
    
    item_name = {
      ['iron-plate'] = '鉄板焼きだと？！',
      },
      
    ]]}
    
    -- Need to seperate requests by category to be able to seperately
    -- detect completition (and also cheaper array removal)
    
    -- needs to make a seperate sub-dictionary per category
    -- that stores requests + flags + etc
    
    new.requests = {n = 0, max = 0}
    new.lookup   = {}
    new.status   = {}
    
    local function request(type, name, lstring)
      new.requests.max = new.requests.max + 1
      new.requests.n   = new.requests.n   + 1
      --
      local id = ident(lstring)
      local x = {
        type = type,
        name = name,
        lstring = lstring,
        next_request_tick = 0,
        bytes = #id,
        i = new.requests.n
        }
      --
      new.requests[new.requests.n] = x
      Table.sget(new.lookup, {id}, {}):insert(x)
      end
    
    for _, type in sriapi(game.mod_setting_prototypes
    [const.setting.auto_translate_categories].allowed_values) do
      local type_name = type..'_name'        -- 'item_name'
      local type_desc = type..'_description' -- 'item_description'
      --
      local max = 0
      for name, prot in pairs(game[type..'_prototypes']) do
        max = max + 1
        request(type_name, prot.name, prot.localised_name)
        request(type_desc, prot.name, prot.localised_description)
        end
      --
      new.status[type_name] = { n = 0 , max = max }
      new.status[type_desc] = { n = 0 , max = max }
      new[type_name] = {}
      new[type_desc] = {}
      end
    return new end


  make_new_dictionary = function(language_code)
    assert(const.native_language_name[language_code] ~= nil, 'Invalid language_code')
    local dict = Table.dcopy(new or fill())
    dict.language_code = language_code
    dict.native_language_name = const.native_language_name[language_code]
    return dict
    end
  end
  

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --


local Dictionary = Class.SimpleClass(make_new_dictionary)


function Dictionary:needs_translation()
  return (self.requests.n > 0) end
  
function Dictionary:get_percentage()
  local n, m = 0, 0
  for _, s in pairs(self.status) do
    n, m = n + s.n, m + s.max
    end
  return math.floor(100 * n / m) end
  
  
function Dictionary:push_translation(lstring, translation)
  -- log:say(lstring, translation)
  local id = ident(lstring)
  for _, request in ntuples(2, self.lookup[id]) do
    self.lookup[id] = nil
    self.requests[request.i] = nil
    
    self.requests.n = self.requests.n - 1
    self.status[request.type].n = self.status[request.type].n + 1
    if translation == false then
      self[request.type][request.name] = 
        -- Block from normal search results?
        -- Or allow search by internal name? (Usecase?)
        'Unlocalised String: ' .. request.type ..' of '..request.name
    else
      -- Hardcode ok? Convert to lower case for later searching.
      self[request.type][request.name] = translation:lower()
      end
    end
  end
  
function Dictionary:dispatch_requests(p, max_bytes)
  -- At least one request has to be sent even if it goes
  -- over the max_bytes limit. Otherwise a too low limit
  -- could cause eternal stalling.
  local tick = game.tick
  local i, bytes = self.requests.max + 1, 0
  repeat i = i - 1
    local request = self.requests[i]
    if request and (request.next_request_tick < tick) then
      bytes = bytes + request.bytes
      p.request_translation(request.lstring)
      request.next_request_tick = tick + const.network.rerequest_delay
      end
    until (bytes >= max_bytes) or (i == 0)
  return bytes end
  
-- function Dictionary:compress_requests()
  -- Array.compress(self.requests, nil, 1, self.requests.max)
  -- end
  
-- @tparam types DenseArray Enforces concious decision by user
--
function Dictionary:find(types, word)
  local codes = {} --temp
  -- stop(types, word)
  local status = 0
  if self:needs_translation() then return codes.not_ready, nil end
  if verify(word , 'str|nil') == nil then return codes.no_word, nil end
  word = word:lower()
  local r = {}
  for _, type in ipairs(Table.plural(verify(types, 'str|tbl|nil'))) do
    assertify(AllowedTypes[type], 'Invalid translation type: ', type)
    local this = {}
    r[type] = this
    local find = string.find
    for name, translation in pairs(self[type]) do
      if find(translation, word, 1, true) then -- PLAIN text!
        -- this[name] = true -- what's a better return Set or Array?
        this[name] = translation -- what's a better return Set or Array?
        end
      end
    log:debug('dictionary found ', #this, ' ', type, ' for word "', word, '"')
    end
  return status, r end
  
  
return Dictionary