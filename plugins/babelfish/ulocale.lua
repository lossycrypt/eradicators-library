
local _ = '__00-universal-locale__/remote'; if remote.interfaces[_] then
  local const = require 'plugins/babelfish/const'
  
  
  local template = {
    status_indicator = {
      en = 'While Babelfish is translating, a small '
        .. '[img=er:babelfish-icon-default] '
        .. 'icon will appear in the upper right corner of your screen. '
        .. 'You can hover it to see progress information. '
        ,
      de = 'Während Babelfisch übersetzt erscheint in der oberen rechten '
        .. 'Ecke deines Bildschirms ein '
        .. '[img=er:babelfish-icon-default] '
        .. 'Symbol. Wenn du mit der Maus darüberfährst werden weitere '
        .. 'Informationen eingeblendet. '
        ,
      ja = ''
        .. '[img=er:babelfish-icon-default]' -- no way to prevent forced line break?
        .. '翻訳中は画面の右上に'
        .. 'このアイコンが現れます'
        .. '。'
        .. 'マウスで触れると進行情況が表示されます。'
        ,
      },
      
    supported_mods = {
      en = ''
        .. "_UL:2SPACE_ Factory Planner (by Therenas) (soon™)\\n"
        -- .. "_UL:2SPACE_ Eradicator's Belt Builder (by eradicator)\\n"
      }
    }
  
  
  require(_)('babelfish', {

  ['[mod-setting-name]'] = {
    -- map
    [const.setting_name.network_rate] = {
      en = '_UL:MultiPlayerSetting_ _UL:PowerUserSetting_ Babelfish: Maximum Upload Speed (KiB/s)',
      de = '_UL:MultiPlayerSetting_ _UL:PowerUserSetting_ Babelfisch: Maximale Uploadgeschwindigkeit (KiB/s)',
      ja = '_UL:MultiPlayerSetting_ _UL:PowerUserSetting_ バベルフィッシュ： 最大アップロード速度 （ＫｉＢ／秒）',
      },
    [const.setting_name.enable_packaging] = {
      en = '_UL:DevModeSetting_ _UL:MultiPlayerSetting_ _UL:PowerUserSetting_'
        .. 'Babelfish: Use large packets',
      },
    [const.setting_name.sp_instant_translation] = {
      en = '_UL:DevModeSetting_ Babelfish: Singleplayer Instant Translation',
      },
    -- player
    [const.setting_name.string_match_type] = {
      en = 'Babelfish: Search Mode',
      de = 'Babelfisch: Suchmodus',
      ja = 'バベルフィッシュ：: 検索モード',
      },
    -- startup
    [const.setting_name.search_types] = {
      en = '_UL:DevModeSetting_ Babelfish: Search Types',
      },
    },

  ['[string-mod-setting]'] = {
    [const.setting_name.string_match_type..'-'..'plain'] = {
      en = 'Default',
      de = 'Standard',
      ja = 'デフォルト',
      },
    [const.setting_name.string_match_type..'-'..'fuzzy'] = {
      -- from core locale "fuzzy-search-enabled"
      en = 'Fuzzy',
      de = 'Unscharf',
      en = '曖昧',
      },
    [const.setting_name.string_match_type..'-'..'lua'] = {
      en = '_UL:PowerUserSetting_ Lua pattern',
      de = '_UL:PowerUserSetting_ Lua Zeichenkettenmuster',
      ja = '_UL:PowerUserSetting_ Lua パターン',
      },    
    },

  ['[string-mod-setting-description]'] = {
    [const.setting_name.string_match_type..'-'..'plain'] = {
      en = 'Plain text search like in vanilla Factorio.',
      de = 'Klartextsuche wie im Hauptspiel.',
      ja = '本編と同じ普通の検索です。',
      },
    [const.setting_name.string_match_type..'-'..'fuzzy'] = {
      en = 'Searches for each letter seperately. '
        .. [[Works like Factorio's "Fuzzy search" interface option.]],
      de = 'Sucht jeden Buchstaben einzeln. '
        .. [[Funktioniert wie Factorios Benutzeroberflächeneinstellung "Unscharfe Suche".]],
      ja = '一文字ずつ検索します。 '
        .. [[本編のインターフェース設定「あいまい検索」と同じです。]],
      },
    [const.setting_name.string_match_type..'-'..'lua'] = {
      en = 'Raw lua pattern input. Not RegEx.'
        .. '\nFor hoopy froods who know where their towel is.'
        ,
      de = 'Direkte Eingabe von Lua Zeichenkettenmustern. Nicht RegEx.'
        .. '\nFür hoopy Froods die wirklich wissen wo Ihr Handtuch ist.'
        ,
      -- https://shinoddddd.tumblr.com/post/31196859068/%E9%8A%80%E6%B2%B3%E3%83%92%E3%83%83%E3%83%81%E3%83%8F%E3%82%A4%E3%82%AF%E3%82%AC%E3%82%A4%E3%83%89%E3%81%AB%E3%81%AF%E3%82%BF%E3%82%AA%E3%83%AB%E3%81%AB%E9%96%A2%E3%81%97%E3%81%A6%E3%81%8B%E3%81%AA%E3%82%8A%E3%81%8F%E3%82%8F%E3%81%97%E3%81%84%E8%A8%98%E8%BC%89%E3%81%8C%E3%81%82%E3%82%8B
      ja = 'ＬＵＡパターン直入力。正規表現にあらず。'
        .. '\n自分のタオルの在りかがちゃんと解かっているフーピイなフルードの為の設定です。'
        ,
      },    
    },

  ['[mod-setting-description]'] = {
    [const.setting_name.network_rate] = {
      en = 'Higher values increase translation speed, but '
        .. 'players with slow internet may have trouble joining '
        .. 'servers with a too high setting.'
        .. '\\n\\n'
        .. template.status_indicator.en
        .. '\\n\\n'
        .. 'No bandwidth is used once translation is complete. '
         ,
      -- STUB!
      de = 'Ein hoher Wert beschleunigt die Übersetzung, aber '
        .. 'kann zu Verbindungsproblemen bei Spielern mit '
        .. 'langsamem Internet führen.'
        .. '\\n\\n'
        .. template.status_indicator.de
        .. '\\n\\n'
        .. 'Nach Fertigstellung der Übersetzung wird keine '
        .. 'weitere Bandbreite verbraucht.'
        ,
      ja = '設定が高いほど翻訳速度も上がりますが、高すぎれば回線の遅いプレイヤー'
        .. 'が接続困難になる場合があります。'
        .. '\\n\\n'
        .. template.status_indicator.ja
        .. '\\n\\n'
        .. '翻訳終了後は回線を使用しません。'
        ,
      },
    [const.setting_name.enable_packaging] = {
      -- STUB: dev-only
      en = 'Instead of sending each translation request seperately, Babelfish '
        .. 'will bundle them together. Reduces cpu '
        .. 'cost, but may sometimes use slightly more than the maximum upload speed.'
        ,
      },
    [const.setting_name.string_match_type] = {
      en = 'How text you enter into the search fields of '
        .. 'supported mods is processed. All search modes are '
        .. 'case-insensitive.'
        ,
      de = 'Wie eingegebene Suchworte von unterstützen '
        .. 'Mods verarbeitet werden. Alle Eingaben sind '
        .. 'Klein- und Großschreibungsunabhängig.'
        ,
      ja = '対応モッドにて入力した文字列の処理方法です。'
        .. '入力されたローマ字の小・大文字に意味の違いはありませんが、'
        .. '現在平仮名と片仮名は別文字扱いになっています。'
      },
    },

  ['[babelfish]'] = {
    
    ['babelfish'] = {
      en = 'Babelfish',
      de = 'Babelfisch',
      ja = 'バベルフィッシュ',
      },

    -- ['status-indicator-tooltip-header'] = {
    ['translation-in-progress'] = {
      en = 'The Babelfish is currently translating your mods.',
      de = 'Der Babelfisch übersetzt gerade deine Mods.',
      ja = 'バベルフィッシュさんが只今モッドの翻訳に勤しんでいます。',
      },

    ['command-only-in-singleplayer'] = {
      en = 'This command can only be used in singleplayer.',
      de = 'Dieser Befehl funktioniert nur im Einzelspielermodus.',
      ja = 'そのコマンドはシングルプレイ専用です。',
      },
      
    ['command-only-by-admin'] = {
      en = 'This command can only be used by admins.',
      de = 'Dieser Befehl kann nur von Administratoren benutzt werden.',
      en = 'そのコマンドは管理者専用です。',
      },

    ['unknown-command'] = {
      en = 'Unknown command.',
      de = 'Unbekannter Befehl.',
      en = '不明のコマンドです。',
      },
      
    ['command-confirm'] = {
      en = 'Ok!',
      de = 'Ok!',
      ja = '了解！',
      },
      
    ['test-string'] = {
      en = 'This is a test. '
        .. 'Button: __CONTROL__mine__. '
        .. 'Complex Button: __ALT_CONTROL__1__build__'
        .. 'Parameters: __2__ __3__. '
        .. 'Item Name: __ITEM__iron-plate__. '
        .. 'Plural: __4__ __plural_for_parameter_4_{1=day|rest=days}__'
      },
      
    language_code = (function(r)
      for code, name in pairs(const.native_language_name) do r[code] = code end
      return r end){},
    
    native_language_name = (function(r)
      for code, name in pairs(const.native_language_name) do r[code] = name end
      return r end){},

    },
    
  -- Replaced by {'babelfish.babelfish'} in prototype.
  --
  -- ['[tips-and-tricks-item-name]'] = {
    -- [const.name.tip_1] = { 
      -- en = "Babelfish",
      -- de = "",
      -- ja = "",
      -- }
    -- },
    
  ['[tips-and-tricks-item-description]'] = {
    [const.name.tip_1] = { 
      en = 'Babelfish helps mods to interact with you in your '
        .. 'own language. '
        .. template.status_indicator.en
        .. '\\n\\n'
        .. 'Mods known to support Babelfish:\\n'
        .. template.supported_mods.en
         ,
      de = 'Babelfisch erlaubt es Mods in deiner eigenen Sprache '
        .. 'mit dir zu interagieren. '
        .. template.status_indicator.de
        .. '\\n\\n'
        .. 'Mods die offiziell Babelfish unterstützen:\\n'
        .. template.supported_mods.en
        ,
      ja = 'バベルフィッシュはモッドにもプレイヤー言語での検索を可能にします。'
        .. template.status_indicator.ja
        .. '\\n\\n'
        .. '現在公式にバベルフィッシュに対応しているモッド：\\n'
        .. template.supported_mods.en
        ,
      }
    },

  }) end