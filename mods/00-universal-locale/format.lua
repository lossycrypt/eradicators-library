
local string_find, string_match, string_gsub
    = string.find, string.match, string.gsub
-- -------------------------------------------------------------------------- --


local apply_formatting --scoping

local String = require('__eradicators-library__/erlib/lua/String')()

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
    en = 'Multiplayer-only setting. Has no effect in Singleplayer.',
    de = 'Mehrspielereinstellung. Hat keinen Effekt im Einzelspieler.',
    ja = 'マルチプレイ専用設定。\\n    シングルプレイに影響はありません。',
    },
    
  }
  
local function is_description(entry)
  return entry.header:match('%-?([^%-]+)%]$') == 'description'
  end
  
local function get_description_header(entry)
  return entry.header:gsub('%-name%]',']'):gsub('%]','-description]')
  end
  
local function find_description(entry, db)
  -- [controls] and [controls-description] but
  -- [mod-setting-name] and [mod-setting-description]
  local desc_header = get_description_header(entry)
  --
  for _, dbentry in pairs(db) do
    if  (dbentry.header   == desc_header   )
    and (dbentry.key      == entry.key     )
    and (dbentry.language == entry.language)
    then return dbentry end end
  end
  
-- Takes a string and puts it into the description of the corresponding
-- entry. Generates a new description if there was none.
local function add_description_header(entry, db, msg)
  --
  
  -- V1:
  local x; entry.value, x = entry.value:gsub('_UL:NOAUTODESCRIPTION_','')
  -- if x > 0 then return false end
  
  -- V2: Now that default values have a seperate info icon color
  --     it's no longer nessecary to prevent dev-setting descriptions.
  --     (Still need to remove the tag from old translations.)
  
  --
  local desc = find_description(entry, db)
  --
  if desc then
  
    local desc_value = String.split(desc.value, '_UL:ENDOFHEADER_')
    assert(#desc_value <= 2, 'Too many headers?!')
    assert(#desc_value >  0, 'No string content?')
    
    -- insert as second-last
    table.insert(desc_value, #desc_value, msg)
    table.insert(desc_value, #desc_value, '_UL:ENDOFHEADER_')
    desc.value = table.concat(desc_value, '')
  
  else
    -- don't forget to format newly generated entries!
    db[#db+1] = apply_formatting({
      header    = get_description_header(entry),
      mod_name  = entry.mod_name ,
      file_name = entry.file_name,
      language  = entry.language ,
      key       = entry.key      ,
      value     = msg .. '_UL:ENDOFHEADER_'
      }, db)
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
      local prot = assert(game.mod_setting_prototypes[entry.key],
        'Can not add default value for non-existant settings prototype: '
        ..entry.key)
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
      if add_description_header(entry, db, 
        '_UL:ICON_TTIP_DEFAULT_VALUE_'..
        ("[color=orange] %s[/color] [color=acid]%s[/color]\\n")
        :format( lt.default_value[entry.language], default_value )
        )
      then
        if not has_icon(entry, '_UL:ICON_TOOLTIP_') then
          append_icon_once(entry, '_UL:ICON_TTIP_DEFAULT_VALUE_')
          end
        end
      end
    end,

  -- _UL:MultiPlayerSetting_
  function(entry, db)
    local count
    entry.value, count = entry.value:gsub('%s*_UL:MultiPlayerSetting_%s*','')
    if count > 0 then
      assert(not is_description(entry), 'Multiplayer flag must be in name not description')
      append_icon_once(entry, '_UL:ICON_TTIP_MULTIPLAYER_')
      add_description_header(entry, db,
         '_UL:ICON_TTIP_MULTIPLAYER_[color=purple] '
        .. assert(lt.multiplayer_setting_description_header[entry.language])
        ..'[/color]\\n')
      end
    end,


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

  
  -- _UL:PowerUserSetting_
  function(entry, db)
  
    local count
    entry.value, count = entry.value:gsub('%s*_UL:PowerUserSetting_%s*','')
    if count > 0 then
      --
      assert(not is_description(entry), 'Power user flag must be in name not description')
      -- Put an icon at the end of the name.
      -- append_icon_once(entry, '_UL:ICON_TOOLTIP_')
      append_icon_once(entry, '_UL:ICON_DEV_')
      
      -- Put a warning at the beginning of the description.
      add_description_header(entry, db,
         '_UL:ICON_DEV_[color=blue] '
        .. assert(lt.power_user_setting_description_header[entry.language])
        ..'[/color]\\n')
      
      end
    end,
    
    
  -- FINAL FIXES
  
  
  -- Fix missing newline escapes.
  -- Remove space at the start of text blocks. (Allows using real [[]] blocks.)
  function(entry, db)
    -- Future: Auto-detect width of space at beginning of [[block]].
    entry.value = entry.value
      :gsub('^%s*' ,''   ) -- left-trim
      :gsub('\n%s*','\\n') -- escape newlines
    end,

-- -------------------------------------------------------------------------- --
-- !FINAL FIXES!
    
  -- Remove trailing newlines.
  function(entry, db)
    entry.value = entry.value:gsub('_UL:ENDOFHEADER_$',''):gsub('\\n+$','')
    end,
    
  }
  
  
  
local pattern_strings = {

  {'_UL:ICON_DEV_ ?'    , '[img=developer]'},
  {'_UL:ICON_TOOLTIP_ ?', '[img=info]'     },
  
  {'_UL:ICON_TTIP_DEFAULT_VALUE_ ?', '[img=ul:info-default]'   },
  {'_UL:ICON_TTIP_MULTIPLAYER_ ?'  , '[img=ul:info-purple]'},

  
  --hackfix
  {'_UL:0SPACE_', ''},
  {'_UL:1SPACE_', ' '},
  {'_UL:2SPACE_', '  '},
  
  --internal use
  {'_UL:ENDOFHEADER_','\\n'},
  
  }


function apply_formatting(entry, db)
  for j=1, #pattern_functions do
    -- Functions may create new locale entries!
    pattern_functions[j](entry, db)
    end
  for j=1, #pattern_strings do
    entry.value = entry.value:gsub(table.unpack(pattern_strings[j]))
    end
  return entry end
  
  
-- All manipulation is in-place.
return function(db)
  
  for i=1, #db do
    apply_formatting(db[i], db)
    end
  
  end