
--[[ Usage example: 
  
    do local _ = '__00-universal-locale__/remote'
    if remote.interfaces[_] then require(_)('file_name', ulocale) end end

--]]

-- This is the function that other mods require() to register
-- their locales with universal-locale. As it is executed
-- inside the *remote* mod it needs to be careful.
return function (file_name, ulocale)
  local mod_name = debug.getinfo(2,'S').source:match('^@__(.+)__/?')
  -- checking is done on this side to get an error with a meaningful stacktrace
  assert(mod_name ,'[ER Universal Locale] Modname detection failed.' )
  assert(file_name,'[ER Universal Locale] Missing file name.'        )
  assert(ulocale  ,'[ER Universal Locale] Missing locale table.'     )
  assert(file_name ~= 'file_name', '[ER Universal Locale] Please change the default file name ;).')
  assert(file_name ~= 'template' , '[ER Universal Locale] Please change the default file name ;).')
  
  local interface_name
  local i=0; repeat i = i + 1 --find the next free name
    interface_name = ('er:ulocale-remote@<%s-%s>'):format(mod_name, i)
    until remote.interfaces[interface_name] == nil
  
  remote.add_interface(interface_name, {
    get_universal_locale = function()
      remote.remove_interface(interface_name) -- garbage collection ;)
      return {mod_name = mod_name, file_name = file_name, ulocale = ulocale}
      end,
    })

  end