-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable



-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local Crc32 = elreq('erlib/lua/Coding/Crc32')()

-- -------------------------------------------------------------------------- --
-- Tests                                                                      --
-- -------------------------------------------------------------------------- --

local function Test()

  --empty string is zero
  assert(Crc32.encode(""                                 ) ==          0)
  
  -- A bunch of known-to-be-good values generated with python zlib.crc32.
  -- [1] https://stackoverflow.com/questions/2257441/random-string-generation-with-upper-case-letters-and-digits/2257449#2257449
  -- 
  -- import random,string,zlib
  -- def make_test(count,length):
  --   for _ in range(count):
  --     n = random.randint(int(length/2),length)
  --     msg = ''.join(random.SystemRandom().choice(string.ascii_uppercase + string.digits) for _ in range(n))
  --     print((r'assert(Crc32.encode("{}"{}) == {:10})').format(msg,' '*(length-n),zlib.crc32(msg.encode('UTF-8'))))
  -- make_test(20,32)
  -- 
  assert(Crc32.encode("4QL74H22K4I81O5DGT62K6Q7"         ) == 3905615675)
  assert(Crc32.encode("NFX1M4U0KOF0OPV9GCD8X91KEE0L"     ) == 3146108539)
  assert(Crc32.encode("DG9KEORHLKUCNQWCYPTBJ0"           ) == 3557661628)
  assert(Crc32.encode("BHWAL3HC0M8D02T4EYW8CSROIWRDSE"   ) == 3035435457)
  assert(Crc32.encode("J534BSNSJXKTYNWL1AFI5B7ILH"       ) == 2829217316)
  assert(Crc32.encode("DJLXVKW2UVJ2QUEN"                 ) == 3551056169)
  assert(Crc32.encode("215HEJCGUJXH4ZSOM8DDVQSX4L"       ) == 4206390195)
  assert(Crc32.encode("ZUIJRYAR7J6PPKIVM7VO749IM8X424K"  ) == 2512795773)
  assert(Crc32.encode("RWYDNRZYSXWML7CNAFNTA3I"          ) ==  139741875)
  assert(Crc32.encode("QGW50XG1TMKGMB22XLXYDX9MSH0H"     ) == 4047267191)
  assert(Crc32.encode("APGXZI0SEI2P5YCRJRAUOG4HE8OBO"    ) == 2365380869)
  assert(Crc32.encode("LA49TP1UEM1UIP9U"                 ) ==  941092535)
  assert(Crc32.encode("PPP59HEP7BCZWJTSDUW9TUFPV1YQ7"    ) == 3191439428)
  assert(Crc32.encode("RTX0FFFX98ZUNL2KBBV0ZADTC7"       ) == 3907276552)
  assert(Crc32.encode("PB4YKKRIYMA9MCIBZ0SG0"            ) ==  696369499)
  assert(Crc32.encode("A28K7NLGVYF9OGIUM"                ) == 1215417840)
  assert(Crc32.encode("HXWBG0WSBQNYG83QN38YMWM241AW"     ) ==  252680802)
  assert(Crc32.encode("V2J7AGOI1A4VM80WO12RHF2RWEPN"     ) == 3487909792)
  assert(Crc32.encode("11U3TDGQ6FB7H7H17O"               ) == 2802121171)
  assert(Crc32.encode("WS7SGCE4CK4UHWIDP95I3ZFNKI3"      ) ==  426660167)
  assert(Crc32.encode("6UFZXOP9RT42YCSC3KUXEE"           ) == 3976693420)
  assert(Crc32.encode("EZ6AFJDRT894MLSEHK"               ) ==  117064015)
  assert(Crc32.encode("T03M1W5HARYW4BUV8432NP6KK"        ) == 3752632285)
  assert(Crc32.encode("5CJUYXQQ6WI4L533XM91PGSRQH4IW9XS" ) ==   67859827)
  assert(Crc32.encode("1KNJ3BB0QOUC3BIG3J2T1"            ) == 2442347278)
  assert(Crc32.encode("SPLVTVC174EUQX87Q"                ) ==  913080267)
  assert(Crc32.encode("MPHZ8XWVH4S53GFRI7V5AJH8"         ) == 2983563121)
  assert(Crc32.encode("IW93R1PPBK5FA3P54U"               ) == 2711300594)
  assert(Crc32.encode("VJADJLLRGOM3NV9WQMS74HG8IE3"      ) == 1134422260)
  assert(Crc32.encode("C6901EHNFOZTUFG5TOFJMG9618N"      ) == 4209372342)
  assert(Crc32.encode("P920IJ7M9PFQXCWU1NV"              ) ==  281661578)
  assert(Crc32.encode("GPKO06Z6X144FYLBNOKQJ2FRHN2N8"    ) == 1608779635)
  assert(Crc32.encode("GIVXFMYXLXRTE6JK3CQP57YLICAWWPVN" ) == 2356969769)
  assert(Crc32.encode("MVQZFGJJJIQ38XRSTT"               ) == 2101672909)
  assert(Crc32.encode("0CJ8AK8RPJ6IOG0WI3UBG4OKZF45"     ) == 1105102325)
  assert(Crc32.encode("4ZVDRG1YWFOO1OOQWCTHTP"           ) == 1064683997)
  assert(Crc32.encode("AH5K80J9GHX4IJIA5T55RLKJKYLP"     ) == 1888435608)
  assert(Crc32.encode("4QVI4ZWW4RVK90PAHK7Z"             ) == 3549622540)
  assert(Crc32.encode("T901Q1640Y4UJTD26X6Y3PNK4BP8SL5M8") == 2541348071)
  assert(Crc32.encode("6WTKDF0BEDJD9SB4LBZV117OT0LM0M95" ) == 1888090962)


  say('  TESTR  @  erlib.Crc32 → Ok')
  end


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.test_Crc32') end
return function() return Test, {'lua','settings','data_final_fixes','control'} end
