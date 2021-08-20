local _ = '__00-universal-locale__/remote' if remote.interfaces[_] then

local import = PluginManager.make_relative_require 'dummy-items'
local const  = import '/const'

-- -------------------------------------------------------------------------- --
require(_)('dummy-items', {

  ['[item-name]'] = {

    [const.name.item.unobtanium] = {
      en = 'Unobtanium',
      de = 'Hättstegernium',
      ja = 'テニハイラナイ鉱石',      
      },

    [const.name.item.obtanium] = {
      en = 'Obtanium',
      de = 'Hasteschonium',
      ja = 'テニハイル鉱石',      
      },
      
    [const.name.item.bpglue] = {
      en = 'Mod data (do not remove!)',
      de = 'Mod Daten (nicht entfernen!)',
      ja = 'モッドデータ　（消去しないでください！）',
      },
    },

  }) end