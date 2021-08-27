-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable
-- -------------------------------------------------------------------------- --

--[[ Notes:
  ]]

--[[ Annecdotes:
  ]]

--[[ Future:
  ]]
  
--[[ Todo:
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
-- local log         = elreq('erlib/lua/Log'          )().Logger  'babelfish'
-- local stop        = elreq('erlib/lua/Error'        )().Stopper 'babelfish'
-- local assertify   = elreq('erlib/lua/Error'        )().Asserter(stop)

-- local Verificate  = elreq('erlib/lua/Verificate'   )()
-- local verify      = Verificate.verify
-- local isType      = Verificate.isType

-- local Table       = elreq('erlib/lua/Table'        )()
-- local Array       = elreq('erlib/lua/Array'        )()
-- local Set         = elreq('erlib/lua/Set'          )()
-- local Filter      = elreq('erlib/lua/Filter'       )()
-- local Vector      = elreq('erlib/lua/Vector'       )()

-- local ntuples     = elreq('erlib/lua/Iter/ntuples' )()
-- local dpairs      = elreq('erlib/lua/Iter/dpairs'  )()
-- local sriapi      = elreq('erlib/lua/Iter/sriapi'  )()

-- local Setting     = elreq('erlib/factorio/Setting'   )()
-- local Player      = elreq('erlib/factorio/Player'    )()
-- local getp        = Player.get_event_player

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
-- local script = EventManager .get_managed_script    'babelfish'
local import = PluginManager.make_relative_require 'babelfish'
local const  = import '/const'

local Dictionary       = import '/control/Dictionary'
local SearchTypes      = import '/control/SearchTypes'
 
-- -------------------------------------------------------------------------- --
-- Dictionary                                                                 --
-- -------------------------------------------------------------------------- --

function Dictionary:dump_statistics_to_console()
  if not flag.IS_DEV_MODE then
    print('Dev mode is required for correct statistics!')
  else
    assert(flag.IS_DEV_MODE)
    print( ('-'):rep(80) )
    print( 'Dictionary Statistics:' )
    print( ('Language: %s'):format(self.language_code) )
    print( ('Total requests: %s'):format(self.request_uids.max) )
    if (self.request_uids.n ~= 0) then
      print(('Dictionary has %s untranslated packets. Skipped.'):format(self.request_uids.n))
      return end
    print()
    print('Translated String Statistics:')
    -- print('Type | Longest | Shortest | Avearage | Mean | Unknown Key %')
    print('Type                         | Longest  | Shortest | Average  | Median   | Unk. Key')
    print()
    
    local function longest(arr)
      local n = 0
      for _, x in ipairs(arr) do n = (x > n) and x or n end
      return n end
      
    local function shortest(arr)
      local n = math.huge
      for _, x in ipairs(arr) do n = (x < n) and x or n end
      return n end
    
    local function average(arr)
      local r = 0
      for _, x in ipairs(arr) do r = r + x end
      return r/#arr end
      
    local function median(numlist)
      -- https://rosettacode.org/wiki/Averages/Median#Lua
      if type(numlist) ~= 'table' then return numlist end
      if #numlist == 0 then return 0/0 end
      table.sort(numlist)
      if #numlist %2 == 0 then return (numlist[#numlist/2] + numlist[#numlist/2+1]) / 2 end
      return numlist[math.ceil(#numlist/2)]
      end
    
    for _, type in SearchTypes.requested_ipairs() do
      local lengths = {}
      local untranslated = 0
      if not self[type] then
        game.print('Missing type. Use /babelfish update first.')
        return end
      for _, entry in ipairs(self[type]) do
        local lower = Utf8.lower(entry[eindex.word])
        table.insert(lengths, #lower)
        if Utf8.find(lower, 'unknown key') or (lower:gsub('%s+','') == '') then
          untranslated = untranslated + 1
          end
        end
      print( ('[%-26s] | %8s | %8s | %8.2f | %8.2f | %8.2f%%') :format(
        type,
        longest(lengths), shortest(lengths), average(lengths), median(lengths),
        100 * (untranslated / #lengths)
        ) )
      end
    end
  end
  