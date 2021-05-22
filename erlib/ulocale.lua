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
require(_)('dontpanic', { 
  ['[er:dont-panic]'] = {
    ['calming-words'] = { 
      en = "[color=default]eradicator: Calm down please! "
        .. "It's ok now. I fixed the [color=blue]__1__[/color].[/color]",
      }
    },
  })
  
  
-- -------------------------------------------------------------------------- --
require(_)('interact-button', { 
  ['[controls]'] = {
    ['er:interact-button'] = { 
      en = "Interact with object",
      de = "Mit Object interagieren",
      ja = "操作する",
      }
    },
  ['[controls-description]'] = {
    ['er:interact-button'] = { 
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
      en = 'Remove the "Elapsed:" and "Duration:" prefix when printing a LuaProfiler.'
      },
    ['elapsed'] = { 
      en = "__1__ms",
      },
    ['duration'] = { 
      en = "__1__ms",
      },
    },
  })

  
-- -------------------------------------------------------------------------- --
-- Old liblocale.logger strings.

--[==[

if false then require(_)('file_name', {
  
  ['[mod-setting-name]'] = {
    ['erlib:logging-level'] = { 
      en = "Logging Level [img=info] [img=developer]",
      de = "",
      ja = "",
      }
    },
    
  ['[mod-setting-description]'] = {
    ['erlib:logging-level'] = { 
      en = "[img=developer] [color=blue]This is an advanced setting. "
        .. "Be careful when changing it.[/color]\n\nHow detailed the "
        .. "information printed to the log will be. If you encounter "
        .. "a *reproducible* bug it would help if you set the level to "
        .. '"Everything" before sending me the log.]]',
      de = "",
      ja = "",
      }
    },
    
  ['[string-mod-setting]'] = {
    ['erlib:logging-level@eradicators-library-Everything'] = { 
      en = "BUG REPORT",
      de = "",
      ja = "",
      }
    },
  
  }) end
  
  Log.locale = {
    mod_setting_name = {
      [loglevel_setting_name_prefix] = {
        -- en = '[font=default-bold][Debug] Logging Level[/font]',
        en = '__ADVANCED__ Logging Level',
        -- de = '[Debug] Welche Logeintrage?',
        de = '__ADVANCED__ Welche Logeintrage?',
        -- ja = '【デバッグ】 何をログに記録しますか？',
        ja = '__ADVANCED__ 何をログに記録しますか？',
        },
      },
    mod_setting_description = {
      [loglevel_setting_name_prefix] = {
        en = [[How detailed the information printed to the log will be. If you encounter a *reproducible* bug it would help if you set the level to "Everything" before sending me the log.]],
        de = [[Wie detailiert die Logeinträge sein sollen.]],
        ja = [[ログ記録の精度。]],
        },
      },
    string_mod_setting = {
      [loglevel_setting_name..'-Errors'] = {
        -- en = 'Only Errors',
        de = 'Fehler',
        ja = 'エラーのみ',
        },
      [loglevel_setting_name..'-Warnings'] = {
        -- en = 'Also Warnings',
        de = 'Warnungen',
        ja = '警告も',
        },
      [loglevel_setting_name..'-Information'] = {
        -- en = 'Also Information',
        de = 'Informationen',
        ja = '通知も',
        },
      [loglevel_setting_name..'-Everything'] = {
        en = 'BUG REPORT',
        -- de = nil,
        ja = '何もかも',
        },
      },
    }
--]==]

-- -------------------------------------------------------------------------- --
end