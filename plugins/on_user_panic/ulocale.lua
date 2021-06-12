local _ = '__00-universal-locale__/remote' if remote.interfaces[_] then

-- local import = PluginManager.make_relative_require 'on_user_panic'
-- local const  = import '/const'

-- -------------------------------------------------------------------------- --
require(_)('on_user_panic', {

  ['[er]'] = {
    ['dont-panic-calming-words'] = { 
      en = "[color=default]eradicator: Calm down please! "
        .. "It's ok now. I fixed the [color=acid]__1__[/color].[/color]",
      }
    },

  }) end