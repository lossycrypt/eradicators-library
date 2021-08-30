local _ = '__00-universal-locale__/remote' if remote.interfaces[_] then

-- -------------------------------------------------------------------------- --
-- require(_)('file_name', {
--   ['[header]'] = {
--     ['key'] = { 
--       en = "",
--       de = "",
--       ja = "",
--       }
--     },
--   })

  
-- -------------------------------------------------------------------------- --
require(_)('interact-button', { 
  ['[controls]'] = {
    ['er:interact'] = { 
      en = "Interact with object",
      de = "Mit Object interagieren",
      ja = "操作する",
      }
    },
  ['[controls-description]'] = {
    ['er:interact'] = { 
      en = "A generic tertiary interact button for mods to use alongside "
        .. "mine and build.",
      de = 'Ein unspetifischer dritter Interactionsknopf für Mods.',
      ja = '採掘と設置の延長線にある第三種の汎用ボタン。モッドによって様々な操作が可能になる。'
        .. '色んな物をクリックしてみましょう！',
      }
    },
  })
  

-- -------------------------------------------------------------------------- --
require(_)('profiler-override', {
  ['[lua-profiler]'] = {
    [';1'] = { -- supports multiple comments with numbers
      en = 'Remove the "Elapsed:" and "Duration:" prefix when printing a LuaProfiler.',
      de = 'Remove the "Elapsed:" and "Duration:" prefix when printing a LuaProfiler.',
      ja = 'Remove the "Elapsed:" and "Duration:" prefix when printing a LuaProfiler.',
      },
    ['elapsed'] = { 
      en = "__1__ms",
      de = "__1__ms",
      ja = "__1__ms",
      },
    ['duration'] = { 
      en = "__1__ms",
      de = "__1__ms",
      ja = "__1__ms",
      },
    },
  })
  
-- -------------------------------------------------------------------------- --
-- require(_)('generic-translations', {
  -- ['[erlib]'] = {
    -- ['passive-provider'] = {
      -- en = 'passive provider
      -- }
    
    -- },
  -- })

  

-- -------------------------------------------------------------------------- --
end