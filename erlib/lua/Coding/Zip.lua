--[[ (c) lossycrypt, 2020


  
--]]


-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
-- if not bit32 then error('Zip requires Lua 5.2 bit32 module.') return end

local Zip = {}

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- -------------------------------------------------------------------------- --

local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'

-- local Base64 = (require(elroot ..'erlib/lua/Coding/Base64'))()
-- package.loaded['base64.lua'] = _base64lua

local path = elroot.. 'erlib/lua/Coding/LibDeflate'
local LibDeflate = require (path)
package.loaded[path] = nil --don't keep unused references

LibDeflate = { --throw away more unused references
  CompressZlib   = LibDeflate.CompressZlib   ,
  DecompressZlib = LibDeflate.DecompressZlib ,
  }

local config = {level=9,strategy= nil          }
-- local config = {level=9,strategy='fixed'       }
-- local config = {level=9,strategy='dynamic'     }
-- local config = {level=9,strategy='huffman_only'}

local function c(t,r) r={} for k,v in pairs(t) do r[k]=v end return r end

local function check(data,extra) -- only if data has no extra bytes/padding
  if (data~=nil) and (extra==0) then
    return data
    end
  end


Zip.encode = function(data)

  return check(LibDeflate:CompressZlib(data,c(config)))

  -- local _data,extra = LibDeflate:CompressZlib(data,c(config))
  -- if (_data~=nil) and (extra==0) then
    -- return _data
    -- end  

    -- [string] The compressed data.
    -- [integer] The number of bits padded at the end of output. Should always be 0. Zlib formatted compressed data never has padding bits at the end.


  -- return LibDeflate:CompressZlib(data,c(config))
  end
  
Zip.decode = function(data)
  --well-formed input data never has extra bytes!
  
  return check(LibDeflate:DecompressZlib(data))
  
  -- local _data,extra = LibDeflate:DecompressZlib(data)
  -- if (_data~=nil) and (extra==0) then
    -- return _data
    -- end
  end

  
Zip._LibDeflate = LibDeflate

-- package.loaded['bit32'] = bit32

-- local _zipdeflatelua
-- local _deflatelua
-- local _crc32lua




-- -------------------------------------------------------------------------- --
-- Wrapper (lossycrypt)                                                       --
-- -------------------------------------------------------------------------- --

  
Zip.examplebp = [[0eNqVmN1qg0AYRN/lu94Ed90f9VVKKUm6tEKyCbopDcF3r9qbQjPGuVTiyRlwcPQu++M1Xro2ZWnu0h7OqZfm5S59+5F2x+lcvl2iNNLmeBIlaXeajvoc43Fz+Ix9lkFJm97jtzR6eFUSU25zG38x88HtLV1P+9iNP3gIUHI59+M15zT938jZ6GLrlNykqbZuGNQ/jmE59WNOuZajl30sywE+biWnWtbxJAbYhJWYetmmIjHApl6J8cs2uiA5QEevvZfDEx9DcpDP2nvZPfGxJAf5OLajUzkekjzbLkgKtFMBSBXthEg1WVYUzhRkzyBIs0YgmjGsEQKVZGdhNEuWDYIca4SiedYIgQLZWxitYkHIqKbbVoLHdEG3DZHoBaINIBnaCZFKtm8onGX7hkDsDoHRPGuEQIHtG4pWsX1DIHaPoGi2YI0QSLPFBdGsYUHIqKTb5gCJXtiQxO8SC0j8LkGkwPYNhWO3NgTRqwREc/QqQSDN9g1Ec+zghiB6laBo9CpBIMcWF0XzLGg2Gt/+588EzZ+vCkq+YtfPl5hK22Dr4IMuvPPD8APPu0JQ]]
Zip.example   =  [[eNqVmN1qg0AYRN/lu94Ed90f9VVKKUm6tEKyCbopDcF3r9qbQjPGuVTiyRlwcPQu++M1Xro2ZWnu0h7OqZfm5S59+5F2x+lcvl2iNNLmeBIlaXeajvoc43Fz+Ix9lkFJm97jtzR6eFUSU25zG38x88HtLV1P+9iNP3gIUHI59+M15zT938jZ6GLrlNykqbZuGNQ/jmE59WNOuZajl30sywE+biWnWtbxJAbYhJWYetmmIjHApl6J8cs2uiA5QEevvZfDEx9DcpDP2nvZPfGxJAf5OLajUzkekjzbLkgKtFMBSBXthEg1WVYUzhRkzyBIs0YgmjGsEQKVZGdhNEuWDYIca4SiedYIgQLZWxitYkHIqKbbVoLHdEG3DZHoBaINIBnaCZFKtm8onGX7hkDsDoHRPGuEQIHtG4pWsX1DIHaPoGi2YI0QSLPFBdGsYUHIqKTb5gCJXtiQxO8SC0j8LkGkwPYNhWO3NgTRqwREc/QqQSDN9g1Ec+zghiB6laBo9CpBIMcWF0XzLGg2Gt/+588EzZ+vCkq+YtfPl5hK22Dr4IMuvPPD8APPu0JQ]]
  
Zip.examplebp =  '0eNqVkc0KgzAQhN9lzlFM629epZSidmkDuoqJpSJ590Z7KVRKPc6y8+0wO6NqRuoHzRZqhq47NlCnGUbfuGyWmZ16goK21EKAy3ZRxhI1QX0nY+EENF/pCSXdWYDYaqvpjVnFdOGxrWjwC5sAgb4z3tPxcs9zAhmFicAElYeJc+KLc9jLKbY5x3858neeeC9nzePLWltVH08QeNBgVsshl3EWF1mayShNUudeOwqKiA=='
Zip.example   =   'eNqVkc0KgzAQhN9lzlFM629epZSidmkDuoqJpSJ590Z7KVRKPc6y8+0wO6NqRuoHzRZqhq47NlCnGUbfuGyWmZ16goK21EKAy3ZRxhI1QX0nY+EENF/pCSXdWYDYaqvpjVnFdOGxrWjwC5sAgb4z3tPxcs9zAhmFicAElYeJc+KLc9jLKbY5x3858neeeC9nzePLWltVH08QeNBgVsshl3EWF1mayShNUudeOwqKiA=='
  
--[[
/sudo Z.decode(B.decode(Z.example)) == game.decode_string(Z.example)
> true

it works! profit!

/sudo for i=1,1000 do local x,y = debug.getupvalue(Z.encode,i) if x==nil then break end print(x,y) end

/sudo
C=erlib.Coding
Z=C.Zip
H=C.Hydra
B=C.Base64
E=Z.example

for i=1,1000 do local x,y = debug.getupvalue(Z._LibDeflate.CompressZlib,i) if x==nil then break end print(x,y) end
  
  ]]
  
  
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --


--cleanup
-- _base64lua     = nil
-- _zipdeflatelua = nil
-- _deflatelua    = nil
-- _crc32lua      = nil


-- package.loaded['base64.lua'] = _base64lua
-- package.loaded['bit32'] = nil
-- package.loaded['crc32lua'] = nil
-- package.loaded['deflatelua'] = nil
-- package.loaded['zip-deflate'] = nil

--return
print('loaded zip')
return function() return Zip,nil,nil end