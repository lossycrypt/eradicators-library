-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------------------------------------
-- Babelfish.
-- @module Babelfish


--[[ Keep it simple:

  Babelfish does the heavy lifting regarding translation. But the
  search function should only supply a minimal interface to build mods on.
  
  ]]
  

--[[ Won't implement:
  
  Mods can combine search results as they see fit. Babelfish wont
  do specific combinations like "search recipe and ingredients and products".
  
  Babelfish only filters names, not prototype properties.
  Hidden/Void/etc items/recipes must be filtered by the mod.
  => Might have to filter for performance after all.
  
  ]]
  
--[[ Future Possibilities:

  + Cache find resulsts instead of "lower" strings
    to reduce global data at cost of local data?
    1000 copies of vanilla search result for "i" take about 100MB (~2500 entries).
    retrieving cache is about ~30 times faster IF the result
    does not need to be deep-copied. Dcopy() makes it SLOWER than without cache.
    Cache must be very careful about desyncs so it's only allow
    on fully translated dictionaries. Cache must be keyed to:
    language, match mode, word. If any options are present ignore cache.
  
  + Custom utf8:lower() string functions.
    Nichtmal ('Ä'):lower() funktioniert! Also müssen quasi alle
    nicht-englischen sprachen auf Unicode umgestellt werden.
    => Für Performance kann man Englisch als einziges lua-nativ lassen?
       Aber nur bei der Suche. Beim Speichern kann mans alles richtig machen.
       => Wer sagt denn dass in der englischen Locale keine Umlaute drin sind?
  
  ]]
  
--[[ Related Forum Theads:
    
  + Bug Report ("Won't Fix")
    https://forums.factorio.com/98704
    Unicode search is case-sensitive in Russian
    => Consider finding a unicode-capable lua library.
    => As the main usecase is string.lower() it would be sufficent
       to grab a bunch of mapping tables and implement it myself.
    
  + Interface Request ("Very unlikely")
    https://forums.factorio.com/98680
    Read access to interface setting "Fuzzy search"
    
  ]]
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local stop        = elreq('erlib/lua/Error'        )().Stopper 'babelfish'
local assertify   = elreq('erlib/lua/Error'        )().Asserter(stop)

local Verificate  = elreq('erlib/lua/Verificate')()
local verify      = Verificate.verify

local String      = elreq('erlib/lua/String'       )()
local Filter      = elreq('erlib/lua/Filter'       )()
local Memoize     = elreq('erlib/lua/Meta/Memoize')()

local string_find
    = string.find

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
local import = PluginManager.make_relative_require 'babelfish'
local const  = import '/const'

local eindex = const.index.entry

local SearchTypes      = import '/control/SearchTypes'
local Utf8             = import '/control/Utf8Dummy'
local Local            = import '/locallib'
local RawEntries       = import '/control/RawEntries'

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
local Dictionary       = import '/control/Dictionary'


-- -------------------------------------------------------------------------- --
-- Local Library                                                              --
-- -------------------------------------------------------------------------- --
  
-- Language agnostic.
-- Pre-processes translated strings into an easy-to-compare form.
-- User-input should not be cached to prevent high memory usage or exploits.
--
local normalized_word = Memoize(function(word)
  return Utf8.lower(Utf8.remove_rich_text_tags(word))
  -- return utf8(word):remove_rich_text_tags():lower():tostring()
  end) 

-- Some malformed patterns do not fail if they
-- don't actually have any matches in the input string.
-- (This very likely still has false positives.)
local ascii_array = (function(r)
  for i=1, 255 do r[i] = string.char(i) end
  return table.concat(r) end){}
local function is_well_formed_pattern(word)
  if word:sub(-1) ~= '%' then
    return (pcall(string_find, ascii_array, word))
  else return false end end
  
-- Replaces all space by ascii space, then splits.
local function split_by_space(ustr)
  for _, space in pairs(String.UNICODE_SPACE) do
    ustr = ustr:gsub(space,' ')
    end
  return String.split(ustr, '%s+') end

-- -------------------------------------------------------------------------- --
-- Matchers                                                                   --
-- -------------------------------------------------------------------------- --

local matchers = {}

function matchers.plain (t,ws)
    for i=1, #ws do
      if not Utf8.find(t, ws[i], 1, true) then return false end
      end
    return true end
  
-- -------------------------------------------------------------------------- --
-- Find                                                                       --
-- -------------------------------------------------------------------------- --
  
-- @tparams types DenseArray {'item_name', 'recipe_name',...}
-- @tparams string word The search term.
-- @params table opt Options
-- 
-- @treturn boolean This only returns true if translation is incomplete.
-- @treturn table|nil 
--
function Dictionary:find(types, word, opt)
  verify(types    , 'table' , 'Babelfish: Invalid "types" format.'   )
  verify(word     , 'string', 'Babelfish: Invalid "word" format.'    )
  verify(opt      , 'table' , 'Babelfish: Invalid "options" format.' )
  verify(opt.limit, 'nil|Integer', 'Babelfish: Invalid limit.' )
  --
  local limit = opt.limit or math.huge
  local r = {}
  local exact_word = word
  local status = true
  --
  local eindex_name = eindex.name
  local eindex_word = eindex.word -- future: user option "internal name search"
  --
  local matcher
  if opt.mode == 'lua' then
    -- Lua mode can fail with "weird" user input.
    -- But that case needs to behave like a search without results.
    matcher = is_well_formed_pattern(word) and string_find or Filter.FALSE
  elseif opt.mode == 'fuzzy' then
    matcher = Utf8.find_fuzzy
    -- word = String.to_array(String.remove_whitespace(word:lower()))
    word = Utf8.to_array(Utf8.remove_whitespace(Utf8.lower(word)))
  else
    matcher = matchers.plain
    -- word = split_by_space(word:lower())
    word = split_by_space(Utf8.lower(word))
    end
  --
  for i=1, #types do
    local type = types[i]
    SearchTypes.assert(type)
    assert(not SearchTypes.is_description(type)
      , 'Descriptions can not be searched.')
    -- This will only fail on new maps or after an :update()
    -- added new prototypes.
    if not self:is_type_fully_populated(type) then status = false end
    -- subtables are created regardless of limit
    local this = {}; r[type] = this
    local entries = self[type]
    for i = 1, entries.max do
      if limit <= 0 then break end
      local entry = entries[i]
      if entry then -- self[type] is sparse after :update()
        local name = entry[eindex_name]
        if (exact_word == name) -- verbatim internal name match
        or matcher(normalized_word[entry[eindex_word]], word) then
          limit = limit - 1
          this[name] = (not flag.IS_DEV_MODE) or entry[eindex_word]
          end
        end
      end
    end
  -- Pssst! ;)
  -- if (exact_word:lower() == 'dolphin')
  if (Utf8.lower(exact_word) == 'dolphin')
  and r.item_name
  and game.item_prototypes['raw-fish']
  then r.item_name['raw-fish'] = true end
  --
  -- if flag.IS_DEV_MODE then
    -- log:debug('Cache size: ', table_size(normalized_word))
    -- end
  --
  return status, r end

-- -------------------------------------------------------------------------- --
-- Translate                                                                  --
-- -------------------------------------------------------------------------- --
  
-- Only translates one name at a time to discourage
-- authors from mass-caching the results!
--
function Dictionary:translate_name(type, name)
  SearchTypes.assert(type)
  verify(name, 'str', 'Babelfish: Invalid name.')
  
  -- V1
  -- local this = self[type]
  -- for i = 1, self[type].max do
  --   if this[i] and (this[i][eindex.name] == name) then
  --     return this[i][eindex.word]
  --     end
  --   end
  
  -- V2: New structure allows direct lookup
  local entry = RawEntries.by_name[type][name]
  assertify(entry, 'Babelfish: Invalid name: ', name)
  return self[type][entry[eindex.index]][eindex.word]
  end
  