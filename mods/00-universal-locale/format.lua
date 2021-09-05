
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --

local log  = elreq('erlib/lua/Log'  )().Logger ('ULocale')

local string_find, string_match, string_gsub
    = string.find, string.match, string.gsub
-- -------------------------------------------------------------------------- --


local apply_formatting --scoping

local String = require('__eradicators-library__/erlib/lua/String')()
local Locale = require('__eradicators-library__/erlib/factorio/Locale')()

-- localised templates
local lt = {
   
  power_user_setting_description_header = {
    en = 'This is an advanced setting. Be careful when changing it.',
    de = 'Dies ist eine Power-User Einstellung. Vorsicht beim Ändern.',
    ja = 'こちらはヘビーユーザー専用の設定です。\\n    変更時はご注意ください。',
    },

  default_value = {
    en = 'Default Value:',
    de = 'Standardwert:',
    ja = 'デフォルト値→',
    },

  multiplayer_setting_description_header = {
    en = 'Network setting. Has no effect in Singleplayer.',
    de = 'Netzwerkeinstellung. Hat keinen Effekt im Einzelspieler.',
    ja = 'ネットワーク設定。\\n    シングルプレイに影響はありません。',
    },
    
  dev_mode_setting_description_header = {
    en = 'Dev-Mode-only setting. Is hidden to normal players.',
    de = 'Entwicklereinstellung. Für normale Spieler nicht sichtbar.',
    ja = '開発者専用設定。通常プレイヤーには見えません。',
    },
    
  }
  
local function is_description(entry)
  return entry.header:match('%-?([^%-]+)%]$') == 'description'
  end
  
local function get_description_header(entry)
  return entry.header:gsub('%-name%]',']'):gsub('%]','-description]')
  end
  
local function find_description(entry, db)
  return entry.description or (function()
    -- [controls] and [controls-description] but
    -- [mod-setting-name] and [mod-setting-description]
    local desc_header = get_description_header(entry)
    --
    for i=1, #db do; local dbentry = db[i]
    -- for _, dbentry in pairs(db) do
      if  (dbentry.header   == desc_header   )
      and (dbentry.key      == entry.key     )
      and (dbentry.language == entry.language)
      then
        entry.description = dbentry
        return dbentry end
        end
      end)()
  end
  
  
-- Takes a string and puts it into the description of the corresponding
-- entry. Generates a new description if there was none.
local function add_description_header(entry, db, msg)
  --
  
  -- V1:
  -- local x; entry.value, x = entry.value:gsub('_UL:NOAUTODESCRIPTION_','')
  -- if x > 0 then return false end
  
  -- V2: Now that default values have a seperate info icon color
  --     it's no longer nessecary to prevent dev-setting descriptions.
  --     (Still need to remove the tag from old translations.)

  -- To ensure it always splits into exactly two parts
  local one_space = ' '
  local end_of_header = '_UL:ENDOFHEADER_'
  --
  local desc = find_description(entry, db)
  --
  if desc then
  
    if not desc.value:find(end_of_header, 1, true) then
      desc.value = end_of_header .. desc.value
      end
  
    local desc_value = String.split(desc.value, end_of_header)
    assert(#desc_value == 2, 'Incorrect split length.')
    
    -- insert as second-last
    desc.value =
      desc_value[1]            -- previous header tags
      .. msg                   -- new headder tag
      .. end_of_header
      ..(desc_value[2] or one_space) -- description if any
  
  else
    db[#db+1] = {
      header    = get_description_header(entry),
      mod_name  = entry.mod_name ,
      file_name = entry.file_name,
      language  = entry.language ,
      key       = entry.key      ,
      value     = msg .. end_of_header .. one_space,
      }
    end  
  return true end
  
local function has_icon(entry, icon)
  return not not string_find(entry.value, icon, 1, true)
  end
  
local function append_icon_once(entry, icon)
  if not has_icon(entry, icon) then
    entry.value = entry.value .. ' ' .. icon
    end
  end
  
local function remove_icon(entry, icon)
  entry.value = string_gsub(entry.value, icon .. ' ?', '')
  end
    
local function make_mod_setting_tagger(
  external_tag, internal_tag, color, template_name
  )
  return function(entry, db)
    local count
    entry.value, count = entry.value:gsub('%s*'..external_tag..'%s*','')
    if count > 0 then
      assert(not is_description(entry)
        , external_tag..' must be in name not description.')
      append_icon_once(entry, internal_tag)
      add_description_header(entry, db,
        internal_tag .. '[color='..color..'] '
        .. assert(lt[template_name][entry.language])
        ..'[/color]\\n')
      end
    end
  end
  
  
local pattern_functions = {
  -- Array of *ordered* patterns. Can influence each other.

  -- (MUST BE FIRST)
  -- Remember if a non-generated description existed.
  function(entry, db)
    entry.has_real_description = not not find_description(entry, db)
    end,
    
    
  -- Inject mod setting default value description.
  function(entry, db)
    if entry.header == '[mod-setting-name]' then
      -- V1
      -- local prot = assert(game.mod_setting_prototypes[entry.key],
        -- 'Can not add default value for non-existant settings prototype: '
        -- ..entry.key)
      -- V2 (dynamically generated settings)
      local prot = game.mod_setting_prototypes[entry.key]
      if not prot then
        for _, this in pairs(game.mod_setting_prototypes) do 
          if Locale.nlstring_is_equal({entry.key}, this.localised_name) then
            prot = this
            break end
          end
        if not prot then
          log:say('Ulocale: No default value found for mod-setting:'
            , entry.language, entry.key)
          return end
        end
      --
      local default_value = prot.default_value
      if type(default_value) == 'string' then
        -- Drop-Down Items can be localised. But UL does not have
        -- access to all locales so it can't correctly handle this.
        if prot.allowed_values then
          local localised_default 
          for _, dbentry in pairs(db) do
            if  (dbentry.header   == '[string-mod-setting]')
            and (dbentry.language == entry.language        )
            and (dbentry.key      == entry.key..'-'..default_value  )
            then 
              default_value = dbentry.value
              end
            end
          end
        -- default_value = '"'..default_value..'"' -- Quotes are not for end-users.
      elseif type(default_value) == 'boolean' then
        default_value = default_value
          and '☑' -- U+2611 ☑ BALLOT BOX WITH CHECK
           or '☐' -- U+2610 ☐ BALLOT BOX
        end
      --
      if add_description_header(entry, db, 
        '_UL:ICON_TTIP_DEFAULT_VALUE_'..
        ("[color=orange] %s[/color] [color=acid]%s[/color]\\n")
        :format( lt.default_value[entry.language], default_value )
        )
      then
        append_icon_once(entry, '_UL:ICON_TTIP_DEFAULT_VALUE_')
        end
      end
    end,


  -- _UL:DevSetting_
  make_mod_setting_tagger(
    '_UL:DevSetting_',
    '_UL:ICON_TTIP_DEV_MODE_',
    'pink',
    'dev_mode_setting_description_header'
    ),
    
  -- _UL:NetworkSetting_
  make_mod_setting_tagger(
    '_UL:NetworkSetting_',
    '_UL:ICON_TTIP_NETWORK_',
    'purple',
    'multiplayer_setting_description_header'
    ),

  -- Add Info Icon to all settings with description.
  function(entry, db)
    local no_header_icon = {
      -- Reason: Can't hover.
      ['[tips-and-tricks-item-description]'] = true,
      ['[map-gen-preset-description]'      ] = true,
      ['[technology-description]'          ] = true,
      ['[mod-description]'                 ] = true,
      ['[item-description]'                ] = true,
      ['[entity-description]'              ] = true,
      -- Reason: Automatically added by engine! Wtf!
      ['[controls-description]'] = true,
      }
    if entry.has_real_description then
      local desc = find_description(entry, db)
      if no_header_icon[desc.header] then return end
      append_icon_once(entry, '_UL:ICON_TOOLTIP_')
      end
    end,

  -- _UL:AdvancedSetting_
  make_mod_setting_tagger(
    '_UL:AdvancedSetting_',
    '_UL:ICON_TTIP_ADVANCED_',
    'blue',
    'power_user_setting_description_header'
    ),
    
  
-- -------------------------------------------------------------------------- --
-- !FINAL FIXES!
  
  -- Fix missing newline escapes.
  -- Remove space at the start of text blocks. (Allows using real [[]] blocks.)
  function(entry, db)
    -- Future: Auto-detect width of space at beginning of [[block]].
    entry.value = entry.value
      :gsub('^%s*' ,''   ) -- left-trim
      :gsub('\n%s*','\\n') -- escape newlines
    end,
    
  }
  
  
local pattern_strings = {

  -- colored (i) tags.
  {'_UL:ICON_TOOLTIP_ ?'           , '[img=ul:info-white]'  },
  {'_UL:ICON_TTIP_ADVANCED_ ?'     , '[img=developer]'      },
  {'_UL:ICON_TTIP_DEFAULT_VALUE_ ?', '[img=ul:info-default]'},
  {'_UL:ICON_TTIP_NETWORK_ ?'      , '[img=ul:info-purple]' },
  {'_UL:ICON_TTIP_DEV_MODE_ ?'     , '[img=ul:info-pink]'   },
  
  --hackfix
  {'_UL:0SPACE_', ''},
  {'_UL:1SPACE_', ' '},
  {'_UL:2SPACE_', '  '},
  
  --internal use
  {'_UL:ENDOFHEADER_','\\n'},
  
  }

local function remove_trailing_whitespace(entry)
  local arr = {'\\n$','\n+$','%s+$'} -- lua does not have real regex :|
  repeat
    local count = 0
    for i=1, #arr do
      local c
      entry.value, c = entry.value:gsub(arr[i], '')
      count = count + c
      end
    until count == 0
  end
  
function apply_formatting(entry, db)
  for j=1, #pattern_functions do
    -- Functions may create new locale entries!
    pattern_functions[j](entry, db)
    end
  for j=1, #pattern_strings do
    entry.value = entry.value:gsub(table.unpack(pattern_strings[j]))
    end
  if entry.value:find('_UL:', 1, true) then
    error('Entry has unknown UL tags:\n' .. serpent.block(entry))
    end
  return entry end
  
  
-- All manipulation is in-place.
return function(db)
  
  -- V1
  -- for i=1, #db do
  --   apply_formatting(db[i], db)
  --   end
    
  -- V2
  -- Don't forget to format newly generated entries
  -- created while parsing old ones!
  local i = 0
  while true do
    i = i + 1
    if db[i] then
      apply_formatting(db[i], db)
      remove_trailing_whitespace(db[i])
    else
      break
      end
    end
  
  end