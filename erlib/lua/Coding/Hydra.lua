--[[ lossycrypt, 2020

    Modified to work with factorio and erlib.

    Source:
      https://github.com/pkulchenko/serpent     
  
    Changes:
      + wrapped the original file in a "do end" block
      + shortend string representation of skipped functions (too cluttery to read)
      + new option: "indentlevel", changes how many subtables are indented
        for pretty-printing
      + new preset: "serpent.lines", includes {indentlevel=1,nocode=true}
      + removed looking at _G first (_ENV may be meta-locked)
      + removed setfenv check (_ENV may be meta-locked, factorio has no setfenv)
      + change placeholder for redundant tables from nil to 0 to fix determinism
        (https://factorio.com/blog/post/fff-340)
      + new option: "showref", adds comments to otherwise skipped self-references
      + renamed to "Hydra" to avoid confusion with factorio built-in "serpent"
      + added Hydra.encode and Hydra.decode single-return function
      + changed module return value to be erlib compatible
      + added factorio userdata class awareness using object.object_name
      
      local test_input = {
        x = { x = { x = { x = { x = { x = { 'a' }}}}}},
        y = { x = { x = { x = { x = { x = { 'b' }}}}}},
        }
        
  ]]
  

-- (c) Paul Kulchenko, 2012-2018, MIT License

do
  local n, v = "serpent", "0.302" -- (C) 2012-18 Paul Kulchenko; MIT License
  local c, d = "Paul Kulchenko", "Lua serializer and pretty printer"
  local snum = {[tostring(1/0)]='1/0 --[[math.huge]]',[tostring(-1/0)]='-1/0 --[[-math.huge]]',[tostring(0/0)]='0/0'}
  local badtype = {thread = true, userdata = true, cdata = true}
  local getmetatable = debug and debug.getmetatable or getmetatable
  local pairs = function(t) return next, t end -- avoid using __pairs in Lua 5.2+
  
  --[[lossycrypt: remove _G]]
  -- local keyword, globals, G = {}, {}, (_G or _ENV)
  local keyword, globals, G = {}, {}, (_ENV)
  for _,k in ipairs({'and', 'break', 'do', 'else', 'elseif', 'end', 'false',
    'for', 'function', 'goto', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat',
    'return', 'then', 'true', 'until', 'while'}) do keyword[k] = true end
  for k,v in pairs(G) do globals[v] = k end -- build func to name mapping
  
  --[[lossycrypt: remove non-deterministic modules @factorio]]
  -- for _,g in ipairs({'coroutine', 'debug', 'io', 'math', 'string', 'table', 'os'}) do
  for _,g in ipairs({'debug', 'math', 'string', 'table'}) do
    for k,v in pairs(type(G[g]) == 'table' and G[g] or {}) do globals[v] = g..'.'..k end end

  local function s(t, opts)
    local name, indent, fatal, maxnum = opts.name, opts.indent, opts.fatal, opts.maxnum
    local sparse, custom, huge = opts.sparse, opts.custom, not opts.nohuge
    local space, maxl = (opts.compact and '' or ' '), (opts.maxlevel or math.huge)
    local maxlen, metatostring = tonumber(opts.maxlength), opts.metatostring
    local iname, comm = '_'..(name or ''), opts.comment and (tonumber(opts.comment) or math.huge)
    local numformat = opts.numformat or "%.17g"
    local seen, sref, syms, symn = {}, {'local '..iname..'={}'}, {}, 0
    local function gensym(val) return '_'..(tostring(tostring(val)):gsub("[^%w]",""):gsub("(%d%w+)",
      -- tostring(val) is needed because __tostring may return a non-string value
      function(s) if not syms[s] then symn = symn+1; syms[s] = symn end return tostring(syms[s]) end)) end
    local function safestr(s) return type(s) == "number" and tostring(huge and snum[tostring(s)] or numformat:format(s))
      or type(s) ~= "string" and tostring(s) -- escape NEWLINE/010 and EOF/026
      or ("%q"):format(s):gsub("\010","n"):gsub("\026","\\026") end
    local function comment(s,l) return comm and (l or 0) < comm and ' --[['..select(2, pcall(tostring, s))..']]' or '' end

    --[[lossycrypt: add self-reference comment option]]
    --gsub replaces empty table name [""] (empty string) with the word "self"
    local function addref(str) return opts.showref and ' --[[ '..(str:gsub('^%[""%]','self'))..' ]]' or '' end

    local function globerr(s,l) return globals[s] and globals[s]..comment(s,l) or not fatal
      and safestr(select(2, pcall(tostring, s))) or error("Can't serialize "..tostring(s)) end
    local function safename(path, name) -- generates foo.bar, foo[3], or foo['b a r']
      local n = name == nil and '' or name
      local plain = type(n) == "string" and n:match("^[%l%u_][%w_]*$") and not keyword[n]
      local safe = plain and n or '['..safestr(n)..']'
      return (path or '')..(plain and path and '.' or '')..safe, safe end
    local alphanumsort = type(opts.sortkeys) == 'function' and opts.sortkeys or function(k, o, n) -- k=keys, o=originaltable, n=padding
      local maxn, to = tonumber(n) or 12, {number = 'a', string = 'b'}
      local function padnum(d) return ("%0"..tostring(maxn).."d"):format(tonumber(d)) end
      table.sort(k, function(a,b)
        -- sort numeric keys first: k[key] is not nil for numerical keys
        return (k[a] ~= nil and 0 or to[type(a)] or 'z')..(tostring(a):gsub("%d+",padnum))
             < (k[b] ~= nil and 0 or to[type(b)] or 'z')..(tostring(b):gsub("%d+",padnum)) end) end
    local function val2str(t, name, indent, insref, path, plainindex, level)
      local ttype, level, mt = type(t), (level or 0), getmetatable(t)

      --[[lossycrypt: add new option indentlevel]]
      if opts.indentlevel and level >= opts.indentlevel then indent = nil end
      
      local spath, sname = safename(path, name)
      local tag = plainindex and
        ((type(name) == "number") and '' or name..space..'='..space) or
        (name ~= nil and sname..space..'='..space or '')
      if seen[t] then -- already seen this element
        sref[#sref+1] = spath..space..'='..space..seen[t]
                
        --[[lossycrypt: make placeholder factorio deterministic according to FFF-340]]
        -- return tag..'nil'..comment('ref', level) end --original
        -- return tag..'0'..comment('ref', level) end --factorio

        --[[lossycrypt: add self-reference comment option]]
        return tag..'0'..addref(seen[t])..comment('ref', level) end --factorio+selfref
        
      -- protect from those cases where __tostring may fail
      if type(mt) == 'table' and metatostring ~= false then
        local to, tr = pcall(function() return mt.__tostring(t) end)
        local so, sr = pcall(function() return mt.__serialize(t) end)
        if (to or so) then -- knows how to serialize itself
          seen[t] = insref or spath
          t = so and sr or tr
          ttype = type(t)
        end -- new value falls through to be serialized
      end
      if ttype == "table" then
        if level >= maxl then return tag..'{}'..comment('maxlvl', level) end
        seen[t] = insref or spath
        if next(t) == nil then return tag..'{}'..comment(t, level) end -- table empty
        if maxlen and maxlen < 0 then return tag..'{}'..comment('maxlen', level) end
        local maxn, o, out = math.min(#t, maxnum or #t), {}, {}
        for key = 1, maxn do o[key] = key end
        if not maxnum or #o < maxnum then
          local n = #o -- n = n + 1; o[n] is much faster than o[#o+1] on large tables
          for key in pairs(t) do if o[key] ~= key then n = n + 1; o[n] = key end end end
        if maxnum and #o > maxnum then o[maxnum+1] = nil end
        if opts.sortkeys and #o > maxn then alphanumsort(o, t, opts.sortkeys) end
        local sparse = sparse and #o > maxn -- disable sparsness if only numeric keys (shorter output)
        for n, key in ipairs(o) do
          local value, ktype, plainindex = t[key], type(key), n <= maxn and not sparse

          -- [[lossycrypt: factorio userdata class awareness]]
          -- [[LuaPlayer, LuaGameScript, LuaEntity, etcpp...]]
          -- [1] https://lua-api.factorio.com/latest/Common.html#Common.object_name
          if key == '__self' and type(value) == 'userdata' then
            value = t.object_name or value
            end

          if opts.valignore and opts.valignore[value] -- skip ignored values; do nothing
          or opts.keyallow and not opts.keyallow[key]
          or opts.keyignore and opts.keyignore[key]
          or opts.valtypeignore and opts.valtypeignore[type(value)] -- skipping ignored value types
          or sparse and value == nil then -- skipping nils; do nothing
          elseif ktype == 'table' or ktype == 'function' or badtype[ktype] then
            if not seen[key] and not globals[key] then
              sref[#sref+1] = 'placeholder'
              local sname = safename(iname, gensym(key)) -- iname is table for local variables
              sref[#sref] = val2str(key,sname,indent,sname,iname,true) end
            sref[#sref+1] = 'placeholder'
            local path = seen[t]..'['..tostring(seen[key] or globals[key] or gensym(key))..']'
            sref[#sref] = path..space..'='..space..tostring(seen[value] or val2str(value,nil,indent,path))
          else
            out[#out+1] = val2str(value,key,indent,nil,seen[t],plainindex,level+1)
            if maxlen then
              maxlen = maxlen - #out[#out]
              if maxlen < 0 then break end
            end
          end
        end
        local prefix = string.rep(indent or '', level)
        local head = indent and '{\n'..prefix..indent or '{'
        local body = table.concat(out, ','..(indent and '\n'..prefix..indent or space))
        local tail = indent and "\n"..prefix..'}' or '}'
        return (custom and custom(tag,head,body,tail,level) or tag..head..body..tail)..comment(t, level)
      elseif badtype[ttype] then
        seen[t] = insref or spath
        return tag..globerr(t, level)
      elseif ttype == 'function' then
        seen[t] = insref or spath

        --[[lossycrypt: less garbage text]]
        -- if opts.nocode then return tag.."function() --[[..skipped..]] end"..comment(t, level) end
        if opts.nocode then return tag.."function()end"..comment(t, level) end

        local ok, res = pcall(string.dump, t)
        local func = ok and "((loadstring or load)("..safestr(res)..",'@serialized'))"..comment(t, level)
        return tag..(func or globerr(t, level))
      else return tag..safestr(t) end -- handle all other types
    end
    local sepr = indent and "\n" or ";"..space
    local body = val2str(t, name, indent) -- this call also populates sref
    local tail = #sref>1 and table.concat(sref, sepr)..sepr or ''
    local warn = opts.comment and #sref>1 and space.."--[[incomplete output with shared/self-references skipped]]" or ''
    return not name and body..warn or "do local "..body..sepr..tail.."return "..name..sepr.."end"
  end

  local function deserialize(data, opts)
    local env = (opts and opts.safe == false) and G
      or setmetatable({}, {
          __index = function(t,k) return t end,
          __call = function(t,...) error("cannot call functions") end
        })
    local f, res = (loadstring or load)('return '..data, nil, nil, env)
    if not f then f, res = (loadstring or load)(data, nil, nil, env) end
    if not f then return f, res end
    
    --[lossycrypt: factorio doesn't allow setfenv]
    -- if setfenv then setfenv(f, env) end
    return pcall(f)
  end

  local function merge(a, b) if b then for k,v in pairs(b) do a[k] = v end end; return a; end
  local Hydra = { _NAME = n, _COPYRIGHT = c, _DESCRIPTION = d, _VERSION = v,
    serialize = s      ,
    load  = deserialize,
    
    --[[lossycrypt: disable all comments by default to prevent factorio desync]]
    dump  = function(a, opts) return s(a, merge({name = '_', compact = true, sparse = true}, opts)) end,
    line  = function(a, opts) return s(a, merge({sortkeys = true, comment = false}, opts)) end,
    block = function(a, opts) return s(a, merge({indent = '  ', sortkeys = true, comment = false}, opts)) end,
    
    --[[lossycrypt: add new options indentlevel, showref]]
    --[[lossycrypt: add new preset "lines"]]
    lines = function(a, opts) return s(a, merge({
      indent = '  ', sortkeys = true, comment = false,
      indentlevel = 1, nocode = true, showref = true,
      -- name = 'self'
      -- the existance of "name" triggers the (too verbose) self-ref section
      -- output, so addref() force-gsub's in the name "self" for unnamed tables.
      }, opts)) end,
    }
  
  --[[lossycrypt: erlib Coding.Bluestring compatible aliases]]
  Hydra.encode = Hydra.dump
  -- Hydra.decode = Hydra.load
  
  --[[lossycrypt: Bluestring compatible (nil or data) return loader]]
  -- does not allow disabling safety like raw Hydra.load
  Hydra.decode = function(data)
    local ok, obj = Hydra.load(data)
    if ok == true then return obj end
    end

  --[[lossycrypt: erlib expects a function to be returned]]
  do (STDOUT or log or print)('  Loaded → erlib.Coding.Hydra') end
  return function() return Hydra,nil,nil end
  end