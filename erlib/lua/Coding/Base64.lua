
--[[ lossycrypt, 2020

    Source:
      https://github.com/DaveMcW/blueprint-string/blob/master/blueprintstring/base64.lua
      https://forums.factorio.com/viewtopic.php?p=467035#p467035
  
    Changes:
      + wrapped the original file in a "do end" block
      + changed return value to erlib-style funtion

  ]]
  
-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- -------------------------------------------------------------------------- --

local _base64_lua --temporary reference
  
-- -------------------------------------------------------------------------- --
-- base64.lua                                                                 --
-- -------------------------------------------------------------------------- --
do
  -- Lua 5.1+ base64 v3.0 (c) 2009 by Alex Kloss <alexthkloss@web.de>
  -- licensed under the terms of the LGPL2
  
  -- character table string
  local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  local M = {}

  -- encoding
  M.enc = function(data)
      return ((data:gsub('.', function(x) 
          local r,b='',x:byte()
          for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
          return r;
      end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
          if (#x < 6) then return '' end
          local c=0
          for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
          return b:sub(c+1,c+1)
      end)..({ '', '==', '=' })[#data%3+1])
  end

  -- decoding
  M.dec = function(data)
      data = string.gsub(data, '[^'..b..'=]', '')
      return (data:gsub('.', function(x)
          if (x == '=') then return '' end
          local r,f='',(b:find(x)-1)
          for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
          return r;
      end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
          if (#x ~= 8) then return '' end
          local c=0
          for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
          return string.char(c)
      end))
  end

  -- return M
  _base64_lua = M
  end
  
-- -------------------------------------------------------------------------- --
-- end of base64.lua                                                          --
-- -------------------------------------------------------------------------- --


--[[lossycrypt: erlib style function return]]
local Base64 = {
  encode = _base64_lua.enc,
  decode = _base64_lua.dec,
  }
--cleanup
_base64_lua = nil 
--end
return function() return Base64, nil, nil end