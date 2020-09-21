-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

-- -----------------------------------------------
-- Description
--
-- @module Bluestring
-- @usage
--  local Bluestring = require('__eradicators-library__/erlib/factorio/Bluestring')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))
  
-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- -------------------------------------------------------------------------- --

-- Hydra might become outdated if built-in serpent changes but
-- i need the Hydra.decode single-return-value interface.
local Base64 = (require(elroot.. 'erlib/lua/Coding/Base64'))()
local Hydra  = (require(elroot.. 'erlib/lua/Coding/Hydra' ))()
local Json   = (require(elroot.. 'erlib/lua/Coding/Json'  ))()
local Zip    = (require(elroot.. 'erlib/lua/Coding/Zip'   ))()

--blueprint exchange string version byte
local VERSION_BYTE = {
  [0] = '0' --up to 1.0.0 (as of 2020-09)
  }

-- switches to faster C-functions when they are available
local cases = {
  --encode
  runtime_json_table_to_zip    = function(data) return game.encode_string(game.table_to_json(data) ) end,
  runtime_serpent_table_to_zip = function(data) return game.encode_string(Hydra.encode      (data) ) end,
  runtime_string_to_zip        = function(data) return game.encode_string(                   data  ) end,
  startup_json_table_to_zip    = function(data) return Base64.encode(Zip.encode(Json.encode (data))) end,
  startup_serpent_table_to_zip = function(data) return Base64.encode(Zip.encode(Hydra.encode(data))) end,
  startup_string_to_zip        = function(data) return Base64.encode(Zip.encode(             data )) end,
  --decode
  runtime_zip_to_json_table    = function(data) return game.json_to_table(game.decode_string(data))  end,
  runtime_zip_to_serpent_table = function(data) return Hydra.decode      (game.decode_string(data))  end,
  runtime_zip_to_string        = function(data) return                    game.decode_string(data)   end,
  startup_zip_to_json_table    = function(data) return Json.decode (Zip.decode(Base64.decode(data))) end,
  startup_zip_to_serpent_table = function(data) return Hydra.decode(Zip.decode(Base64.decode(data))) end,
  startup_zip_to_string        = function(data) return              Zip.decode(Base64.decode(data))  end,
  }
-- @tparam string mode, 'encode' or 'decode'
-- @tparam[opt] table|string data, not needed for decode
-- @tparam[opt='json'] string serializer, 'serpent' or 'json'
-- @treturn string case_name
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
  


-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Bluestring,_Bluestring,_uLocale = {},{},{}


--Dev-Test function to print all paths
--for _,mode in pairs{'encode','decode'} do for _,data in pairs{'str',{}} do for _,serializer in pairs{'json','serpent',false} do print(mode,data,serializer,selector(mode,data,serializer)) end end end

--Dev-Test function to test de-/encode cycle
-- /sudo erlib.Coding.Bluestring.encode(erlib.Coding.Bluestring.decode("0eNql2NFuozAQBdB/8TNUGGMM/MqqWpGs1VoCB2F31Sji35ekUrfaza09mUeQOJnBd8DhIg7Tm11W56MYLsIdTz6I4cdFBPfix+l6Lp4XKwbhop1FIfw4X4/GEOx8mJx/Kefx+Oq8LZXYCuH8L/suBrkVScK+L6sNoYzr6MNyWmN5sFP8gtTbcyGsjy46+1HU7eD807/NB7vuv/J9OYVYTmG/+OSvNexg2T/pQpx3WT7p7VriP2CdKu5/UiVIRSfrBNl8kiFaO5XHVxvuOKnKdB6TqqalLoL8FJv7oqGKbQLsGMta3yd7Bqnuk7JiRAWZkmGC1mWdFxyZchTRQT1mzkOVcjRxrlBfLXGwkGOIDuqLE38wUZKTfw0evpz8I5OTf9B7nZn/UqaKyxyAskpBDRVCrWlqawhqibONHEOcbeR0j7+lDCD7h19TQFScAUCmZAwqMjnbpBaYnH0SMv+OhfPBrnE/+c1MIEWTFHTP2hxFphRDUlBHXYaSbKh/dPOtKrCt5cS/Aybn+d8DkxN/ZCqGiXqnxR8pmhIW1F5O+mUKMRQEtUPKPkL6DCQVI109vuQK/aVjxB2aNcMEo64ZcYdmQ4gHRDRhZeEdy0l7cikNBUHtdJR2bshz8fGZZvjyYagQv+0ablfUnWxM05vWyKrV7bb9AQb58Ds="))

--C.Bluestring.decode(C.Bluestring.encode('return 1,2',nil,'er:'),'serpent')
--C.Hydra.lines({C.Hydra.decode(C.Bluestring.decode(C.Bluestring.encode('return 1,1',nil,'er:'),'serpent','er:'))})


Bluestring._testbp  = [[0eNql2O2OoyAUBuB74bdOFAXUW9lMNtohHRKLRuhmmon3vtrux2S3r3jkV2NTnnLwPYp+sq6/6nEy1rPmkznbjqkf0vNk3tbjD9bkVcJuywefE9Z2buivXqfr70Zjz6zx01UnzJwG61jzbRHM2bb9OtbfRs0aZry+sITZ9rIetc7pS9cvQ9NLe3o3VqcFW2Rj3/T6Z3MSJPTHOGnnUj+11o3D5NNO9/4LwufXhGnrjTf6Man7we27vV46PS3/sj2dhI2DWwYP9tcSlC/isQYvYl4n+A/HQ1P7D8yzbbGgi/m2WP4Rnde6T0/v2j1j1DYjdjJym5HEE/C7uPI5p4ic2uaq4+eTPxfr42LxXMyz4xFBZH6cBHXnfGdeRMApiA4qcW8blAFHENsJ1SWJ/YQcRXRQXRHRB82UR2RfgOttRPYRGZF9UDjfm30emNre7BcBpyQ6qC5BrAs5ktjTyFHEnkZOdfCmpIBXH7wrAa+ISD0i8+O9iciIzZAEZMRuCJF/e8FYpye/fIkbASGCgqD1knsQHkAUBUHlVHuQMjCT+ujWOgP71ojUV4CMuNbXgIxIPSKL4yQqnJR6hAhKTFBxu1IvAoiiIKgcUuoRUu9B5HY5Iot4jESPaxFRhyaPMEGXi4iwQ7OkxAMqgnJq4ZrtyrsKKYqkoIoqUkV35TV5vINpvrwtStgPPbn7EF7lpSprJVWeSSHn+SejFvx7]]
Bluestring._teststr = [[{blueprint={["absolute-snapping"]=true,entities={{entity_number=1,name="assembling-machine-3",position={x=4.5,y=1.5}},{entity_number=2,name="express-transport-belt",position={x=10.5,y=1.5}},{entity_number=3,name="express-transport-belt",position={x=11.5,y=1.5}},{entity_number=4,name="steel-chest",position={x=17.5,y=1.5}},{entity_number=5,name="steel-chest",position={x=16.5,y=1.5}},{entity_number=6,name="assembling-machine-3",position={x=1.5,y=4.5}},{entity_number=7,name="assembling-machine-3",position={x=7.5,y=4.5}},{entity_number=8,name="express-transport-belt",position={x=10.5,y=2.5}},{entity_number=9,name="express-transport-belt",position={x=10.5,y=3.5}},{entity_number=10,name="express-transport-belt",position={x=11.5,y=3.5}},{entity_number=11,name="express-transport-belt",position={x=11.5,y=2.5}},{entity_number=12,name="steel-chest",position={x=15.5,y=2.5}},{entity_number=13,name="steel-chest",position={x=15.5,y=3.5}},{entity_number=14,name="steel-chest",position={x=14.5,y=3.5}},{entity_number=15,name="steel-chest",position={x=17.5,y=2.5}},{entity_number=16,name="steel-chest",position={x=16.5,y=2.5}},{entity_number=17,name="steel-chest",position={x=16.5,y=3.5}},{entity_number=18,name="express-transport-belt",position={x=10.5,y=4.5}},{entity_number=19,name="express-transport-belt",position={x=10.5,y=5.5}},{entity_number=20,name="express-transport-belt",position={x=11.5,y=5.5}},{entity_number=21,name="express-transport-belt",position={x=11.5,y=4.5}},{entity_number=22,name="steel-chest",position={x=12.5,y=5.5}},{entity_number=23,name="steel-chest",position={x=13.5,y=5.5}},{entity_number=24,name="steel-chest",position={x=13.5,y=4.5}},{entity_number=25,name="steel-chest",position={x=12.5,y=4.5}},{entity_number=26,name="steel-chest",position={x=15.5,y=4.5}},{entity_number=27,name="steel-chest",position={x=14.5,y=4.5}},{entity_number=28,name="assembling-machine-3",position={x=1.5,y=7.5}},{entity_number=29,name="assembling-machine-3",position={x=7.5,y=7.5}},{entity_number=30,name="express-transport-belt",position={x=11.5,y=7.5}},{entity_number=31,name="express-transport-belt",position={x=10.5,y=7.5}},{entity_number=32,name="express-transport-belt",position={x=10.5,y=6.5}},{entity_number=33,name="express-transport-belt",position={x=11.5,y=6.5}},{entity_number=34,name="inserter",position={x=13.5,y=6.5}},{entity_number=35,name="inserter",position={x=13.5,y=7.5}},{entity_number=36,name="inserter",position={x=12.5,y=7.5}},{entity_number=37,name="inserter",position={x=12.5,y=6.5}},{entity_number=38,name="inserter",position={x=14.5,y=7.5}},{entity_number=39,name="assembling-machine-3",position={x=4.5,y=10.5}},{entity_number=40,name="express-transport-belt",position={x=11.5,y=8.5}},{entity_number=41,name="express-transport-belt",position={x=11.5,y=9.5}},{entity_number=42,name="express-transport-belt",position={x=10.5,y=9.5}},{entity_number=43,name="express-transport-belt",position={x=10.5,y=8.5}},{entity_number=44,name="inserter",position={x=13.5,y=8.5}},{entity_number=45,name="inserter",position={x=14.5,y=9.5}},{entity_number=46,name="inserter",position={x=15.5,y=9.5}},{entity_number=47,name="inserter",position={x=15.5,y=8.5}},{entity_number=48,name="inserter",position={x=14.5,y=8.5}},{entity_number=49,name="inserter",position={x=16.5,y=9.5}},{entity_number=50,name="express-transport-belt",position={x=10.5,y=11.5}},{entity_number=51,name="express-transport-belt",position={x=11.5,y=11.5}},{entity_number=52,name="express-transport-belt",position={x=11.5,y=10.5}},{entity_number=53,name="express-transport-belt",position={x=10.5,y=10.5}},{entity_number=54,name="inserter",position={x=15.5,y=10.5}},{entity_number=55,name="inserter",position={x=16.5,y=11.5}},{entity_number=56,name="inserter",position={x=17.5,y=11.5}},{entity_number=57,name="inserter",position={x=17.5,y=10.5}},{entity_number=58,name="inserter",position={x=16.5,y=10.5}}},icons={{index=1,signal={name="assembling-machine-3",type="item"}},{index=2,signal={name="express-transport-belt",type="item"}}},item="blueprint",["snap-to-grid"]={x=18,y=12},version=281474976710656}}]]

  
Bluestring.encode = function(data,serializer,prefix)
  prefix = prefix or '0'
  local f = cases[selector('encode',data,serializer or nil)] -- "false" is not valid for encoding
  if not f then return nil end
  return prefix .. f(data)
  end
  
  
Bluestring.decode = function(data,serializer,prefix)
  prefix = prefix or '0'
  local n = #prefix
  if not prefix == data:sub(n,n) then return nil end
  local f = cases[selector('decode',nil,serializer)]
  if f then return f(data:sub(n+1)) end
  end
  
  


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Coding.Bluestring') end
return function() return Bluestring,_Bluestring,_uLocale end
