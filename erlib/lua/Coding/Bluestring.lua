-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Description
--
-- @module Bluestring
-- @usage
--  local Bluestring = require('__eradicators-library__/erlib/factorio/Bluestring')()
  
-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'

--bluestring version
local VERSION_BYTE = {
  [0] = '0' --up to 1.0.0 (as of 2020-09)
  }

local Zip    = (require(elroot.. 'erlib/lua/Coding/Zip'   ))()
local Base64 = (require(elroot.. 'erlib/lua/Coding/Base64'))()
local Json   = (require(elroot.. 'erlib/lua/Coding/Json'  ))()
-- local Hydra  = (require(elroot.. 'erlib/lua/Coding/Hydra' ))()
  
  
--[==[
  
-- todo: metatable cache game functions
  
-- local _serializer = {
  -- json    = Json .encode,
  -- serpent = serpent.dump, --don't use Hydra, built-in version might change
  -- }
-- local _deserializer = {
  -- json    = Json .decode,
  -- serpent = serpent.load,
  -- }

local _tostring   = function(data) return Base64.encode(Zip.encode(data)) end
local _fromstring = function(data) return Zip.decode(Base64.decode(data)) end
  
  
-- a simple auto-cache factory
local makemt = function() return {
  __index = function(self,key)
    self[key] = (game or {})[key]
    return rawget(self,key)
    end} end
    
local encoders = setmetatable({
  json    = Json .encode,
  serpent = serpent.dump, --don't use Hydra, built-in version might change
  },makemt(_tostring))
  
local decoders = setmetatable({
  json    = Json .decode,
  serpent = serpent.load,
  },makemt(_fromstring))
  
  

  
-- local magic = {
  
  -- encode = {
    -- table = {
      -- [true ] = {
        -- encode table at runtime
        -- json    = function(data) return game.encode_string(game.table_to_json(data)) end,
        -- serpent = function(data) return game.encode_string(serpent.dump      (data)) end,
        -- },
      -- [false] = {
        -- encode table at startup
        -- json    = function(data) return Base64.encode(Zip.encode(Json.encode (data))) end,
        -- serpent = function(data) return Base64.encode(Zip.encode(serpent.dump(data))) end,
        -- },
      -- },
      
    -- string = {
      -- encode string at runtime
      -- [true ] = function(data) return game.encode_string(data) end
      -- encode string at startup
      -- [false] = function(data) return 
      -- },
    -- }
  
  -- }
  
local function any_other_key (tbl,value)
  return setmetatable(tbl or {},{__index=function() return value end})
  end
  
  
-- Table <-> Serialized Table
local magic1 = {
  encode = {
    table = {
      json    = function(data) return (game and game.table_to_json or Json.encode)(data) end,
      serpent = function(data) return serpent                                     (data) end,
      },
    string = 
      --string does not need serilization
      any_other_key ( function(data) return data end )
      -- json    = function(data) return data end,
      -- serpent = function(data) return data end,
      -- },
    },
  decode = any_other_key({
    json    = function(data) return (game and game.json_to_table or Json.decode)(data) end,
    serpent = function(data) return serpent.load                                (data) end,
    },
             function(data) return data end -- user wants to deserialize themselfs
    )
  }

-- Base64 <-> Serialized Table
local magic2 = {
  encode = {
    [true ] = function(data) return game.encode_string      (data)  end, --runtime
    [false] = function(data) return Base64.encode(Zip.encode(data)) end,
    },
  decode = {
    [true ] = function(data) return game.decode_string      (data)  end, --runtime
    [false] = function(data) return Zip.decode(Base64.decode(data)) end,
    }
  }
  
 ]==]
  
local magic4 = {
  --encode
  runtime_json_table_to_zip    = function(data) return game.encode_string(game.table_to_json(data) ) end,
  runtime_serpent_table_to_zip = function(data) return game.encode_string(serpent.dump      (data) ) end,
  runtime_string_to_zip        = function(data) return game.encode_string(                   data  ) end,
  startup_json_table_to_zip    = function(data) return Base64.encode(Zip.encode(Encode.json (data))) end,
  startup_serpent_table_to_zip = function(data) return Base64.encode(Zip.encode(serpent.dump(data))) end,
  startup_string_to_zip        = function(data) return Base64.encode(Zip.encode(             data )) end,
  --decode
  runtime_zip_to_json_table    = function(data) return game.json_to_table(game.decode_string(data))  end,
  runtime_zip_to_serpent_table = function(data) return serpent.load      (game.decode_string(data))  end,
  runtime_zip_to_string        = function(data) return                    game.decode_string(data)   end,
  startup_zip_to_json_table    = function(data) return Json.decode (Zip.decode(Base64.decode(data))) end,
  startup_zip_to_serpent_table = function(data) return serpent.load(Zip.decode(Base64.decode(data))) end,
  startup_zip_to_string        = function(data) return              Zip.decode(Base64.decode(data))  end,
  }
---
-- @tparam string mode, 'encode' or 'decode'
-- @tparam[opt] table|string data, not needed for decode
-- @tparam[opt='json'] string serializer, 'serpent' or 'json'
-- @treturn string magic_name
local function selector(mode,data,serializer)
  local sname = (serializer == 'serpent') and '_serpent' or '_json'
  if serializer == false then sname = nil end -- user request: don't deserialize!
  if mode == 'encode' then
    local is_string = (type(data) == 'string')
    if not (is_string or sname) then return nil end
    return 
        ((game) and 'runtime' or 'startup')
      ..(is_string and '_string' or sname..'_table')
      ..'_to_zip'
  elseif mode == 'decode' then
    return 
        ((game) and 'runtime' or 'startup')
      ..'_zip_to'
      ..((not sname) and '_string' or sname..'_table')
    end
  end
  
--Dev-Test function to print all paths
--for _,mode in pairs{'encode','decode'} do for _,data in pairs{'str',{}} do for _,serializer in pairs{'json','serpent',false} do print(mode,data,serializer,selector(mode,data,serializer)) end end end
  
  
  
-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Bluestring,_Bluestring,_uLocale = {},{},{}


--------------------------------------------------------------------------------
-- Section
-- @section
--------------------------------------------------------------------------------

--[==[

_Bluestring.encode = function(data,serializer,prefix)
  Verify.is_string_or_table(data)
  Verify.is_nil_or_choice({'json','serpent'},serializer)
  Verify.is_nil_or_bool(plain)
  return true end

Bluestring.encode = function(data,serializer,prefix)
  return (prefix or '0') .. magic2.encode[not not game] (
    magic1.encode[type(data)][serializer or 'json'](data)
    )
  end

Bluestring.decode = function(data,serializer,prefix)
  prefix = prefix or '0'
  local n = #prefix
  if data:sub(n,n) ~= prefix then return nil end

  data = magic1.decode[serializer or 'json'] (
    magic2.decode[not not game](data:sub(n))
    )
  end

  
local function _addprefix(prefix,data)
  if data then
    return prefix..data
    end
  end
local function _removeprefix(prefix,data)
  if data and (data:sub(#prefix,#prefix) == prefix) then
    return data:sub(#prefix)
    end
  end
local function _serialize(mode,data)
  if type(data) == 'string' then
    return data
  else
    return (
      (mode=='serpent')
      and serpent.dump
      or (game and game.table_to_json or Json.encode)
      )(data)
    end
  end
local function _deserialize(mode,data)
  
  return (
    (mode=='serpent')
    and serpent.load
    or (game and game.json_to_table or Json.decode)
    )(data)
  end
  
 ]==]
  
  
Bluestring.encode4 = function(data,serializer,prefix)
  prefix = prefix or '0'
  local f = magic4[selector('encode',data,serializer or nil)] -- "false" is not valid for encoding
  if not f then return nil end
  return prefix .. f(data)
  end
  
Bluestring.decode4 = function(data,serializer,prefix)
  prefix = prefix or '0'
  local n = #prefix
  if not prefix == data:sub(n,n) then return nil end
  local f = magic4[selector('decode',nil,serializer)]
  if f then return f(data:sub(n+1)) end
  end
  
  
-- /sudo erlib.Coding.Bluestring.encode4(erlib.Coding.Bluestring.decode4("0eNql2NFuozAQBdB/8TNUGGMM/MqqWpGs1VoCB2F31Sji35ekUrfaza09mUeQOJnBd8DhIg7Tm11W56MYLsIdTz6I4cdFBPfix+l6Lp4XKwbhop1FIfw4X4/GEOx8mJx/Kefx+Oq8LZXYCuH8L/suBrkVScK+L6sNoYzr6MNyWmN5sFP8gtTbcyGsjy46+1HU7eD807/NB7vuv/J9OYVYTmG/+OSvNexg2T/pQpx3WT7p7VriP2CdKu5/UiVIRSfrBNl8kiFaO5XHVxvuOKnKdB6TqqalLoL8FJv7oqGKbQLsGMta3yd7Bqnuk7JiRAWZkmGC1mWdFxyZchTRQT1mzkOVcjRxrlBfLXGwkGOIDuqLE38wUZKTfw0evpz8I5OTf9B7nZn/UqaKyxyAskpBDRVCrWlqawhqibONHEOcbeR0j7+lDCD7h19TQFScAUCmZAwqMjnbpBaYnH0SMv+OhfPBrnE/+c1MIEWTFHTP2hxFphRDUlBHXYaSbKh/dPOtKrCt5cS/Aybn+d8DkxN/ZCqGiXqnxR8pmhIW1F5O+mUKMRQEtUPKPkL6DCQVI109vuQK/aVjxB2aNcMEo64ZcYdmQ4gHRDRhZeEdy0l7cikNBUHtdJR2bshz8fGZZvjyYagQv+0ablfUnWxM05vWyKrV7bb9AQb58Ds="))
  
--[==[
  
-- Bluestring.encode3 = function(data)
  
  -- return (prefix or '0') ..
    -- _tostream(
      -- _tostr(data,serializer or 'json')
      -- )
    
  -- end
  
-- Bluestring.decode3 = function(data)

  -- string2table(_stream2string(data),serializer or 'json')

  -- end
  

  
  
Bluestring.encode1 = function(data,serializer,prefix)
  
  
  
  if type(data) == 'table' then 
    -- local serializer = game and game.table_to_json or _serializers[serializer or 'json']
    data = _serializer[serializer or 'json'](data)
    end
  
  -- is encode_string really ZLIB deflate or just DEFLATE? (BP needs ZLIB?)
  -- local encoder = game and game.encode_string or _tostring
  local encoder = _tostring

  -- return (plain and '' or VERSION_BYTE[0]) .. encoder(data)
  return (prefix or '0') .. encoder(data)
  
  end



Bluestring.decode = function(data,deserializer,prefix)
  prefix = prefix or '0'
  local n = #prefix
  -- fail on incorrect/missing version byte
  if data:sub(1,1) ~= VERSION_BYTE[0] then return nil end
  data = data:sub(2) --everything after the version byte
  
  -- local decoder = game and game.decode_string or _fromstring
  local decoder =  _fromstring
  
  -- data = decoder(data)
  -- data  = _deserializer[deserializer or 'json'](data)
  
  data  = _deserializer[deserializer or 'json'](decoder(data))
  
  return data
  -- game.decode_string
  
  end

]==]
  
-- Bluestring.examplebp = [[0eNqVmN1qg0AYRN/lu94Ed90f9VVKKUm6tEKyCbopDcF3r9qbQjPGuVTiyRlwcPQu++M1Xro2ZWnu0h7OqZfm5S59+5F2x+lcvl2iNNLmeBIlaXeajvoc43Fz+Ix9lkFJm97jtzR6eFUSU25zG38x88HtLV1P+9iNP3gIUHI59+M15zT938jZ6GLrlNykqbZuGNQ/jmE59WNOuZajl30sywE+biWnWtbxJAbYhJWYetmmIjHApl6J8cs2uiA5QEevvZfDEx9DcpDP2nvZPfGxJAf5OLajUzkekjzbLkgKtFMBSBXthEg1WVYUzhRkzyBIs0YgmjGsEQKVZGdhNEuWDYIca4SiedYIgQLZWxitYkHIqKbbVoLHdEG3DZHoBaINIBnaCZFKtm8onGX7hkDsDoHRPGuEQIHtG4pWsX1DIHaPoGi2YI0QSLPFBdGsYUHIqKTb5gCJXtiQxO8SC0j8LkGkwPYNhWO3NgTRqwREc/QqQSDN9g1Ec+zghiB6laBo9CpBIMcWF0XzLGg2Gt/+588EzZ+vCkq+YtfPl5hK22Dr4IMuvPPD8APPu0JQ]]
-- Bluestring.example   =  [[eNqVmN1qg0AYRN/lu94Ed90f9VVKKUm6tEKyCbopDcF3r9qbQjPGuVTiyRlwcPQu++M1Xro2ZWnu0h7OqZfm5S59+5F2x+lcvl2iNNLmeBIlaXeajvoc43Fz+Ix9lkFJm97jtzR6eFUSU25zG38x88HtLV1P+9iNP3gIUHI59+M15zT938jZ6GLrlNykqbZuGNQ/jmE59WNOuZajl30sywE+biWnWtbxJAbYhJWYetmmIjHApl6J8cs2uiA5QEevvZfDEx9DcpDP2nvZPfGxJAf5OLajUzkekjzbLkgKtFMBSBXthEg1WVYUzhRkzyBIs0YgmjGsEQKVZGdhNEuWDYIca4SiedYIgQLZWxitYkHIqKbbVoLHdEG3DZHoBaINIBnaCZFKtm8onGX7hkDsDoHRPGuEQIHtG4pWsX1DIHaPoGi2YI0QSLPFBdGsYUHIqKTb5gCJXtiQxO8SC0j8LkGkwPYNhWO3NgTRqwREc/QqQSDN9g1Ec+zghiB6laBo9CpBIMcWF0XzLGg2Gt/+588EzZ+vCkq+YtfPl5hK22Dr4IMuvPPD8APPu0JQ]]
  
Bluestring.examplebp =  '0eNqVkc0KgzAQhN9lzlFM629epZSidmkDuoqJpSJ590Z7KVRKPc6y8+0wO6NqRuoHzRZqhq47NlCnGUbfuGyWmZ16goK21EKAy3ZRxhI1QX0nY+EENF/pCSXdWYDYaqvpjVnFdOGxrWjwC5sAgb4z3tPxcs9zAhmFicAElYeJc+KLc9jLKbY5x3858neeeC9nzePLWltVH08QeNBgVsshl3EWF1mayShNUudeOwqKiA=='
Bluestring.example   =   'eNqVkc0KgzAQhN9lzlFM629epZSidmkDuoqJpSJ590Z7KVRKPc6y8+0wO6NqRuoHzRZqhq47NlCnGUbfuGyWmZ16goK21EKAy3ZRxhI1QX0nY+EENF/pCSXdWYDYaqvpjVnFdOGxrWjwC5sAgb4z3tPxcs9zAhmFicAElYeJc+KLc9jLKbY5x3858neeeC9nzePLWltVH08QeNBgVsshl3EWF1mayShNUudeOwqKiA=='

  
----------
-- Foo
-- @table Foo
-- @usage

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
return function() return Bluestring,_Bluestring,_uLocale end
