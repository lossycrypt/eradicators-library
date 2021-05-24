﻿-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable
-- -------------------------------------------------------------------------- --

--[[ Keep it simple:

  Babelfish does the heavy lifting regarding translation. But the
  search function should only supply a minimal interface to build mods on.
  
  ]]

--[[ Won't implement:
  
  Mods can combine search results as they see fit. Babelfish wont
  do specific combinations like "search recipe and ingredients and products".
  
  ]]


--[[ Future Possibilities:

  + Cache find resulsts instead of "lower" strings
    to reduce global data at cost of local data?
  
  ]]

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
local assertify   = elreq('erlib/lua/Error'     )().Asserter(stop)
                                                
local String      = elreq('erlib/lua/String'    )()
local Class       = elreq('erlib/lua/Class'     )()
local Filter      = elreq('erlib/lua/Filter'    )()

local Table       = elreq('erlib/lua/Table'     )()
local Array       = elreq('erlib/lua/Array'     )()

local Replicate   = elreq('erlib/lua/Replicate' )()

local ntuples     = elreq('erlib/lua/Iter/ntuples')()

local pairs, ipairs
    = pairs, ipairs

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
local import = PluginManager.make_relative_require'babelfish'
local const  = import '/const'
local ident  = serpent.line

local AllowedTypes = (function(r,t)
  for i=1, #t do r[t[i]..'_name'] = true r[t[i]..'_description'] = true end
  return r end)({}, const.allowed_translation_types)
  
local index = {
  localised = 1,
  lower     = 2,
  }
  
-- -------------------------------------------------------------------------- --
-- Blank Dictionary                                                           --
-- -------------------------------------------------------------------------- --

local function make_new_dictionary (language_code)
  assert(const.native_language_name[language_code] ~= nil, 'Invalid language_code')
  --
  local new = {
    language_code        = language_code,
    native_language_name = const.native_language_name[language_code],
    
    -- A dense array of currently open requests.
    requests = {
      max = 0, -- The total number of requests made. For statistics.
      n   = 0, -- The currently open number of requests (also the last index).
      --[[
      [1] = {
        lstring = {'item-name.iron-plate'}, -- real localised string
        i = 1, -- array index for faster removal
        next_request_tick = game.tick + 60, -- delay between requests
        bytes = 15, -- length of the ident string
        entries = {
          [1] = {
            type = 'item_name',
            name = 'iron-plate',
            },
          },
        }
      ]]},

    -- Stores references to request tables.
    lookup = {--[[
      "ident(ironplate.name)" = self.requests[1],
      ]]},

    -- For early partial searching.
    open_requests = {
      -- item_name = 100
      },

    --[[
    -- Per-type subtables store the translation results
    item_name = { 
      ['iron-plate'] = {
        lower  = 'iron plate', -- lower-case for user search
        localised = boolean  , -- false if "unknown key:"
        },
      },]]
    }
  --
  local function get_request_index()
    new.requests.max = new.requests.max + 1
    new.requests.n   = new.requests.n   + 1
    return new.requests.n end
  local function request(type, name, lstring)
    local id = ident(lstring)
    local r = new.lookup[id] or {
      i       = get_request_index(),
      lstring = lstring,
      bytes   = #id,
      entries = {},
      next_request_tick = 0,
      }
    table.insert(r.entries, {
      type = type,
      name = name,
      })
    --
    new.requests[r.i] = r
    new.lookup  [id ] = r
    end
  -- inverse ipairs()
  local function sriapi(arr)
    local i = #arr + 1
    return function() i = i - 1 return arr[i], i end
    end
  --
  for type in sriapi(const.allowed_translation_types) do
    local type_name = type..'_name'        -- 'item_name'
    local type_desc = type..'_description' -- 'item_description'
    --
    for name, prot in pairs(game[type..'_prototypes']) do
      request(type_name, prot.name, prot.localised_name)
      request(type_desc, prot.name, prot.localised_description)
      end
    --
    local max = #game[type..'_prototypes']
    new.open_requests[type_name], new[type_name] = max, {}
    new.open_requests[type_desc], new[type_desc] = max, {}
    end
  --
  return new end
  
-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
local Dictionary = Class.SimpleClass(make_new_dictionary)

-- -------------------------------------------------------------------------- --
-- Status                                                                     --
-- -------------------------------------------------------------------------- --

-- If the dictionary has anything left to request.
function Dictionary:needs_translation()
  return (self.requests.n > 0) end
  
-- How much is translated yet. For informing the player.
function Dictionary:get_percentage()
  return math.floor(
    100 * (self.requests.max - self.requests.n)
    / self.requests.max )
  end

function Dictionary:can_translate(type)
  assertify(AllowedTypes[type], 'Babelfish: Invalid translation type: ', type)
  return self.open_requests[type] == 0 end
  
-- -------------------------------------------------------------------------- --
-- Network                                                                    --
-- -------------------------------------------------------------------------- --
  
-- Store the result of an on_string_translated event
-- into the dictionary. When other mods also send requests
-- unwanted garbage must be filtered out.
function Dictionary:push_translation(lstring, translation)
  local id = ident(lstring)
  local request = self.lookup[id]
  if request then
    self.lookup[id] = nil
    -- Unsorted remove. If package loss is high this might
    -- disturb the translation type order, but it's significantly
    -- faster than iterating the whole array all the time.
    self.requests[request.i] = self.requests[self.requests.n]
    self.requests[self.requests.n] = nil
    self.requests.n = self.requests.n - 1
    --
    for _, entry in pairs(request.entries) do
      self.open_requests[entry.type] = self.open_requests[entry.type] - 1
      local localised = not not translation
      if translation == false then
        translation = 'unknown string:'..id
      else
        translation = String.remove_rich_text_tags(translation)
        end
      self[entry.type][entry.name] = {
        [index.localised] = localised,
        [index.lower    ] = translation:lower(),
        }
      end
    end
  end
  
function Dictionary:dispatch_requests(p, max_bytes)
  -- At least one request has to be sent even if it goes
  -- over the max_bytes limit. Otherwise a too low limit
  -- could cause eternal stalling.
  local tick = game.tick
  local i, bytes = self.requests.n + 1, 0
  repeat i = i - 1
    local request = self.requests[i]
    if request and (request.next_request_tick < tick) then
      bytes = bytes + request.bytes
      p.request_translation(request.lstring)
      request.next_request_tick = tick + const.network.rerequest_delay
      end
    until (bytes >= max_bytes) or (i == 0)
  return bytes end
  
  
-- -------------------------------------------------------------------------- --
-- Find + Search                                                              --
-- -------------------------------------------------------------------------- --

--[[ Notes on wont-implement option ideas:

  + Array result format is not faster than set to construct because
    to construct an array of *unique* entries a set would be required anyway.
    And an array with duplicate entries isn't useful.

  + Merging result types is not useful because it would only produce
    meaningful results for pairs of name+desc types, and complete
    garbage when used with anything else.
    
  ]]
  
local find, pcall = string.find, pcall
local matchers = {}
function matchers.plain (t,ws)
    for i=1,#ws do if not find(t,ws[i],1,true) then return false end end
    return true end
-- local function And (a,b) return a and b and true end
-- function matchers.fuzzy(t,w) return And(pcall(find,t,w,1,false)) end
-- matchers.lua = matchers.fuzzy
  
-- @tparams types DenseArray {'item_name', 'recipe_name',...}
-- @tparams string word The search term.
-- @params table opt Options
-- 
-- @treturn boolean This only returns true if translation is incomplete.
-- @treturn table|nil 
--
function Dictionary:find(types, word, opt)
  verify(types    , 'table' , 'Babelfish: Invalid "types" format.'   )
  verify(word     , 'string', 'Babelfish: Invalid "word" format.'    )
  verify(opt      , 'table' , 'Babelfish: Invalid "options" format.' )
  verify(opt.limit, 'nil|Integer', 'Babelfish: Invalid limit.' )
  --
  local n = opt.limit and opt.limit or math.huge
  local include_unknown = (opt.include_unknown == true) -- default false
  local r = {}
  --
  -- fuzzy + lua modes can crash with "weird" user input.
  -- But this needs to fail independantly of self.open_requests.
  local matcher
  if opt.mode == 'lua' then
    matcher = (pcall(find,'',word)) and find or Filter.False
  elseif opt.mode == 'fuzzy' then
    word = String.splice(word, '.', '.*'):lower():gsub('%s+','')
    matcher = (pcall(find,'',word)) and find or Filter.False
  else
    matcher = matchers.plain
    word = String.split(word:lower(), '%s+')
    end
  --
  for i=1, #types do
    local type = types[i]
    assertify(AllowedTypes[type], 'Babelfish: Invalid translation type: ', type)
    if self.open_requests[type] ~= 0 then return false, nil end
    local this = {}; r[type] = this
    for name, translation in pairs(self[type]) do
      if (n > 0) and (translation[index.localised] or include_unknown) then
        if matcher(translation[index.lower], word) then
          this[name], n = true, n - 1
          end
        end
      end
    end
  -- Pssst! ;)
  if ((word[1] or word) == 'dolphin')
  and r.item_name
  and game.item_prototypes['raw-fish']
  then r.item_name['raw-fish'] = true end
  --
  return true, r end

  
return Dictionary