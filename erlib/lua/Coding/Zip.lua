--[[ (c) lossycrypt, 2020

  A simple single-return value wrapper to LibDeflate.
  
--]]


-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Zip = {}


-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- -------------------------------------------------------------------------- --

local LibDeflate = require (elroot.. 'erlib/lua/Coding/LibDeflate')
-- Zip._LibDeflate = LibDeflate --Debug: expose table

local config = {level=9,strategy= nil          }
-- local config = {level=9,strategy='fixed'       }
-- local config = {level=9,strategy='dynamic'     }
-- local config = {level=9,strategy='huffman_only'}

-- copy (paranoia mode, untested if this is required)
local function c(t,r) r={} for k,v in pairs(t) do r[k]=v end return r end

-- only pass data if there were no extra-data / extra-padding
local function only_if_perfect(data,extra)
  if (data~=nil) and (extra==0) then return data end
  end

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
  
-- returns data if encode worked perfectly, or nil otherwise
-- @treturn data|nil
Zip.encode = function(data)
  -- Zlib formatted compressed data never has padding bits at the end.
  return only_if_perfect(LibDeflate:CompressZlib(data,c(config)))
  end

-- returns data if decode worked perfectly, or nil otherwise  
-- @treturn data|nil
Zip.decode = function(data)
  --Well-formed input data never has extra bytes.
  return only_if_perfect(LibDeflate:DecompressZlib(data))
  end


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --


--return
do (STDOUT or log or print)('  Loaded → erlib.Coding.Zip') end
return function() return Zip,nil,nil end