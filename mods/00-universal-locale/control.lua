-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--[[ Why?

  Because managing 3+ different languages of 10+ mods is a pain
  when factorio .cfg syntax doesn't even allow readable indentation.
  Let alone automatic formatting...
  
  ]]

-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

local log   = elreq('erlib/lua/Log'  )().Logger  'UniversalLocale'
local stop  = elreq('erlib/lua/Error')().Stopper 'UniversalLocale'

local Verificate = elreq('erlib/lua/Verificate')()
local verify     = Verificate.verify
local Data       = elreq('erlib/factorio/Data/!init'      )()

local assertify  = elreq('erlib/lua/Error')().Asserter(stop)

local Table      = elreq('erlib/lua/Table'     )()
-- local Array      = elreq('erlib/lua/Array'     )()
-- local Set        = elreq('erlib/lua/Set'       )()

local ntuples    = elreq('erlib/lua/Iter/ntuples')() -- yay!



-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
local This  = {}
local const = {interface_name = '__00-universal-locale__/remote'}

-- -------------------------------------------------------------------------- --
-- Interface                                                                  --
-- -------------------------------------------------------------------------- --
-- A dummy interface to remotely detect if this mod is active or not.
-- Load-order sensitive!
remote.add_interface(const.interface_name, {})

-- -------------------------------------------------------------------------- --
-- One-Time-Event                                                             --
-- -------------------------------------------------------------------------- --
-- A one-time-only event hack to dump locales to disk on load.
-- Totally not desync safe, but remote.call isn't available in on_load.
script.on_nth_tick(10,function() script.on_nth_tick(10, nil)
  local db = This.convert_locales(This.collect_locales())
  This.format_locales(db)
  This.write_locales_to_disk(db)
  --
  remote.remove_interface(const.interface_name) -- remove after use :)
  game.print(('[ER uLocale] %s locales have been written to disk.'):format(#db))
  end)

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

-- Imports data from other mods remote interfaces.
function This.collect_locales()
  local uLocales = {}
  for name, methods in pairs(remote.interfaces) do
    if methods.get_universal_locale then
      local r  = remote.call(name, 'get_universal_locale')
      local ul = Table.sget(uLocales, {r.mod_name}, {})
      assert(ul[r.file_name] == nil, 'Duplicate file name: '..r.file_name)
      uLocales[r.mod_name][r.file_name] = r.ulocale
      log:info(('Found ulocale %s/%s'):format(r.mod_name, r.file_name))
      end
    end
  return uLocales end

  
-- -------------------------------------------------------------------------- --

-- This might need a more specific solution later to allow
-- for special whitespace to purposely overwrite keys.
local function isEmptyValue(value)
  return Verificate.isType.WhiteSpaceString(value)
  end

-- Converts nested table to array of self-aware locale entries.
function This.convert_locales(ulocales)
  local db, i = {}, 0
  --
  for mod_name, file_name, header, key, language, value in ntuples(6, ulocales) do
    --
    assertify('' == header:gsub('%[.*%]',''), 'Header missing brackets?\n',
      '\nheader: "', header, '"\n\nmod_name: ', mod_name, '\nfile_name: ', file_name)
    --
    if not isEmptyValue(value) then
      i = i + 1
      db[i] = {
        mod_name = mod_name, file_name = file_name,
        header   = header  , language  = language ,
        key      = key     , value     = value    ,
        }
      end
    end
  return db end

-- -------------------------------------------------------------------------- --

-- Applies substring replacements, etc..
This.format_locales = require 'format'


-- -------------------------------------------------------------------------- --
function This.write_locales_to_disk(db)
  log:info('Starting to write locales to disk...')
  -- Reorder
  local data = {}
  for i=1, #db do
    local e = db[i]
    Table.set(data, {e.mod_name,e.language,e.file_name,e.header,e.key}, e.value)
    end
  
  for mod_name, language, file_name, _ in ntuples(4, data) do
    local file_path = Data.Path.join(
      'ulocale', mod_name, 'locale', language,
      ('ulocale.%s.%s.cfg'):format(language, file_name))
    say('\n'..('―'):rep(50)..'\n('..file_path..')')
    local function write_line(line, start_new_file)
      -- (filename, data, append, for_player)
      game.write_file(file_path, line ..'\n', start_new_file ~= true)
      say(line) end
    --
    write_line(';This file was automatically generated by eradicators-universal-locale.', true)
    --
    for header, _ in ntuples(2,_) do
      write_line('\n'..header:gsub('_','-'))
      for key, value in ntuples(2,_) do
        value = This.postprocess(value)
        if value then
          if key:sub(1,1) == ';' then write_line(';'..value) -- in-line comment
          else write_line(key ..'='..value) end
          end
        end
      end
    end
  end
  
-- -------------------------------------------------------------------------- --
-- Postprocess                                                                --
-- -------------------------------------------------------------------------- --

local filters = {
  -- array of anonymous functions
  -- Can't use bablefish input because other mods might've changed it.
  
  function(language, header, key, name, uLocales) -- Bablefish input?
    end,

  }



  

function This.postprocess(value)
  if not isEmptyValue(value) then 
    return value
    end
  end