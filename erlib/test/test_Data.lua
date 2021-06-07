-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable


-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local Stacktrace = elreq('erlib/factorio/Stacktrace')()
local stage,phase= Stacktrace.get_load_stage(), Stacktrace.get_load_phase()

local Sprite = elreq('erlib/factorio/Data/Sprite')()

-- -------------------------------------------------------------------------- --
-- Tests                                                                      --
-- -------------------------------------------------------------------------- --

local function Test()

  -- Data.Sprite.format_icon
  do
    local f = function(size, mipcount,name)
      local icon = Sprite.format_icon(name)
      assert(icon.icon_size    == size    )
      assert(icon.icon_mipmaps == mipcount)
      end
    f( 32, nil, "dummy-icon-2_32².png"           )
    f(280, nil, "stockpile_280x280_stonewall.png")
    f(256,   4, "babelfish-256-mip4.png"         )
    f(128, nil, "solid_transparency_128.png"     )
    f( 64,  12, "mip12-foobar-3_64².png"         )
    f( 42,   7, "mip12--3-mip7_64²-42.png"       )
    say('  TESTR  @  erlib.Data.Sprite → Ok')
    end
    



  say('  TESTR  @  erlib.Template → No tests implemented.')
  -- say('  TESTR  @  erlib.Template → Ok')
  end


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.test_Data') end
return function() return Test, {'lua','settings','data_final_fixes','control'} end
