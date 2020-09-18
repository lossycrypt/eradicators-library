-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable


-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,err,elreq,flag = table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- -------------------------------------------------------------------------- --
local Stacktrace = elreq('erlib/factorio/Stacktrace')()

-- -------------------------------------------------------------------------- --
-- Tests                                                                      --
-- -------------------------------------------------------------------------- --

local function Test()
  
 
  local Coding = elreq('erlib/lua/Coding/!init')()

  -- A blueprint spelling the word "OK"
  local OKBP = [[0eNql2O2OoyAUBuB74bdOFAXUW9lMNtohHRKLRuhmmon3vtrux2S3r3jkV2NTnnLwPYp+sq6/6nEy1rPmkznbjqkf0vNk3tbjD9bkVcJuywefE9Z2buivXqfr70Zjz6zx01UnzJwG61jzbRHM2bb9OtbfRs0aZry+sITZ9rIetc7pS9cvQ9NLe3o3VqcFW2Rj3/T6Z3MSJPTHOGnnUj+11o3D5NNO9/4LwufXhGnrjTf6Man7we27vV46PS3/sj2dhI2DWwYP9tcSlC/isQYvYl4n+A/HQ1P7D8yzbbGgi/m2WP4Rnde6T0/v2j1j1DYjdjJym5HEE/C7uPI5p4ic2uaq4+eTPxfr42LxXMyz4xFBZH6cBHXnfGdeRMApiA4qcW8blAFHENsJ1SWJ/YQcRXRQXRHRB82UR2RfgOttRPYRGZF9UDjfm30emNre7BcBpyQ6qC5BrAs5ktjTyFHEnkZOdfCmpIBXH7wrAa+ISD0i8+O9iciIzZAEZMRuCJF/e8FYpye/fIkbASGCgqD1knsQHkAUBUHlVHuQMjCT+ujWOgP71ojUV4CMuNbXgIxIPSKL4yQqnJR6hAhKTFBxu1IvAoiiIKgcUuoRUu9B5HY5Iot4jESPaxFRhyaPMEGXi4iwQ7OkxAMqgnJq4ZrtyrsKKYqkoIoqUkV35TV5vINpvrwtStgPPbn7EF7lpSprJVWeSSHn+SejFvx7]]
  -- Just a random non-blueprint string
  local TEST = Coding.Hydra.encode(_ENV)

  -- print(Hydra.lines(Coding.Bluestring.decode(OKBP)))
  
-- -------------------------------------------------------------------------- --
-- Bluestring                                                                 --
-- -------------------------------------------------------------------------- --

  -- if game is running then the Lua implementation can't be tested! :/
  -- because game will be used instead!
  
  local recompress = Coding.Bluestring.encode(Coding.Bluestring.decode(OKBP))
  assert(#recompress > 100) --not a nil value
  
  assert( recompress == 
  Coding.Bluestring.encode(Coding.Bluestring.decode(
  Coding.Bluestring.encode(Coding.Bluestring.decode(
  recompress)))) )
  
  
  -- recompress = Coding.Bluestring.encode(Coding.Bluestring.decode(recompress)) print(recompress) print(Coding.Hydra.line(Coding.Bluestring.decode(recompress)))
  -- recompress = Coding.Bluestring.encode(Coding.Bluestring.decode(recompress)) print(recompress) print(Coding.Hydra.line(Coding.Bluestring.decode(recompress)))
  -- recompress = Coding.Bluestring.encode(Coding.Bluestring.decode(recompress)) print(recompress) print(Coding.Hydra.line(Coding.Bluestring.decode(recompress)))
  -- recompress = Coding.Bluestring.encode(Coding.Bluestring.decode(recompress)) print(recompress) print(Coding.Hydra.line(Coding.Bluestring.decode(recompress)))
  -- recompress = Coding.Bluestring.encode(Coding.Bluestring.decode(recompress)) print(recompress) print(Coding.Hydra.line(Coding.Bluestring.decode(recompress)))
  -- recompress = Coding.Bluestring.encode(Coding.Bluestring.decode(recompress)) print(recompress) print(Coding.Hydra.line(Coding.Bluestring.decode(recompress)))
  
  
  -- alter test: deflate ist nicht stabil in np++
  -- assert( Coding.Bluestring.encode(Coding.Bluestring.decode(OKBP))
    -- ==    OKBP )
    
  say('  TESTR  @　erlib.Bluestring → Ok (needs more tests)')
    
-- -------------------------------------------------------------------------- --
-- Zip                                                                        --
-- -------------------------------------------------------------------------- --

  -- need a running game for this test!
  if not (flag.IS_FACTORIO and _ENV.game) then
    say('  TESTR  @　erlib.Zip → Skipped (no game).')
  else
    assert(not not game,'LuaGameScript not found for erlib.Coding Test.')
    
    -- Is game encode compatible with erlib encode?
    -- (The output of zlib-deflate isn't deterministic so
    --  comparing the compressed string doesn't work.)
    assert( Coding.Zip.decode(Coding.Base64.decode(game.encode_string(TEST)))
      ==    game.decode_string(Coding.Base64.encode(Coding.Zip.encode(TEST))) )  
      
    say('  TESTR  @　erlib.Zip → Ok')
    end
    
  end


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.test_Coding') end
return function() return Test, {'lua','settings','data_final_fixes','control'} end

