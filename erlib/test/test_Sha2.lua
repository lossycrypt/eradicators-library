--[[ lossycrypt, 2020

    Source:
      sha2_test.lua from https://github.com/Egor-Skriptunoff/pure_lua_SHA
  
    Changes:
      + removed everything unrelated to sha256
      + removed chunk-stream mode tests
      + wrapped remaining tests into a simple function

  ]]

-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,err,elreq,flag = table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local sha256 = elreq('erlib/lua/Coding/Sha2')()

-- -------------------------------------------------------------------------- --
-- Tests                                                                      --
-- -------------------------------------------------------------------------- --

local function Test()

-- -----------------------------------------------------------------------------
-- sha2_test.lua
-- -----------------------------------------------------------------------------
  local function sha2_test()
    -- some test strings
    assert(sha256("abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    assert(sha256("123456") == "8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92")
    assert(sha256("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq") == "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1")
    assert(sha256("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu") == "cf5b16a778af8380036ce59e7b0492370b249b11e8f07a51afac45037afee9d1")
    assert(sha256("The quick brown fox jumps over the lazy dog") == "d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592")
    assert(sha256("The quick brown fox jumps over the lazy cog") == "e4c4d8f3bf76b692de791a173e05321150f7a345b46484fe427f6acc7ecc81be")

    -- empty string
    assert(sha256("") == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
    -- assert(sha256()() == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")

    -- "00...0\n"
    for i, dgst in pairs{  -- from 50 to 70 zeroes
       [50] = "9660acb8046abf46cf27280e61abd174ebac98ad6855e093772b78df85523129",
       [51] = "31e1c552b357ace9bcb924691799a3c0d3aa10d8b428d9de28a278e3c79ecb7b",
       [52] = "0be5c4bcb6f47e30c13515594dbef4faa3a6485af67c177179fee8b33cd4f2a0",
       [53] = "d368c7f6038c1743bdbfe6a9c3a72d4e6916aa219ed8d559766c9e8f9845f3b8",
       [54] = "7080a4aa6ff030ae152fe610a62ee29464f92afeb176474551a69d35aab154a0",
       [55] = "149c1cda81fa9359c0c2a5e405ca972986f1d53e05f6282871dd1581046b3f44",
       [56] = "eb2d4d41948ce546c8adff07ee97342070c5b89789f616a33efe52c7d3ec73d4",
       [57] = "c831db596ccbbf248023461b1c05d3ae084bcc79bcb2626c5ec179fb34371f2a",
       [58] = "1345b8a930737b1069bbf9b891ce095850f6cdba6e25874ea526a2ccb611fe46",
       [59] = "380ad21e466885fae080ceeada75ac04944687e626e161c0b24e91af3eec2def",
       [60] = "b9ab06fa30ef8531c5eee11651aa86f8279a245e0a3c29bf6228c59475cc610a",
       [61] = "bcc187de6605d9e11a0cc6edf02b67fb651fe1779ec59438788093d8e376c07c",
       [62] = "ae0b3681157b83b34de8591d2453915e40c3105ae79434e241d82d4035218e01",
       [63] = "68a27b4735f6806fb5983c1805a23797aa93ea06e0ebcb6daada2ea1ab5a05af",
       [64] = "827d096d92f3deeaa0e8070d79f45beb176768e57a958a1cd325f5f4b754b048",
       [65] = "6c7bd8ec0fe9b4e05a2d27dd5e41a8687a9716a2e8926bdfa141266b12942ec1",
       [66] = "2f4b4c41017a2ddd1cc8cd75478a82e9452e445d4242f09782535376d6f4ba50",
       [67] = "b777b86e005807a446ead00986fcbf3bdd6c022524deabf017eeb3f0c30b6eed",
       [68] = "777da331f60c793f582e4ca33223778218ddfd241981f15be5886171fb8301b5",
       [69] = "06ed0c4cbf7d2b38de5f01eab2d2cd552d9cb87f97b714b96bb7a9d1b6117c6d",
       [70] = "e82223344d5f3c024514cfbe6d478b5df98bb878f34d7a07e7b064fa7fa91946"
    } do
       assert(sha256(("0"):rep(i).."\n") == dgst)
    end

    -- "aa...a"
    assert(sha256(("a"):rep(55)) == "9f4390f8d30c2dd92ec9f095b65e2b9ae9b0a925a5258e241c9f1e910f734318")
    assert(sha256(("a"):rep(56)) == "b35439a4ac6f0948b6d6f9e3c6af0f5f590ce20f1bde7090ef7970686ec6738a")

    -- negative byte values
    assert(sha256(("\255"):rep(1e3)) == "b4f73dff046400b76728ab32619e3d89e00132653725f660c62ab9fca975b372")

    -- "aa...a\n" in "whole-string" mode
    assert(sha256(("a"):rep(65).."\n") == "574883a9977284a46845620eaa55c3fa8209eaa3ebffe44774b6eb2dba2cb325")
    end
-- -----------------------------------------------------------------------------
-- end of sha2_test.lua
-- -----------------------------------------------------------------------------

  sha2_test()

  say('  TESTR  @  erlib.Sha2 → Ok')

  end


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.test_Sha2') end
return function() return Test, {'lua','settings','data_final_fixes','control'} end
