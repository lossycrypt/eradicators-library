-- (c) eradicator a.k.a lossycrypt, 2021, not seperately licensable
--------------------------------------------------------------------------------

--[[
  This file must be a simple list. No functions allowed!
  ]]
  
--------------------------------------------------------------------------------
local s1, d1, c1,   s2, d2, c2,   s3, d3, c3,   ul =
  'settings'            ,'data'            ,'control'            ,
  'settings-updates'    ,'data-updates'    ,'control-updates'    ,
  'settings-final-fixes','data-final-fixes','control-final-fixes',
  'ulocale'

--------------------------------------------------------------------------------

local plugin_array = {
  
  -- "dev"
  -- {'dev-tweaks'                 , {    d1,         dev_only = true}},
  
  -- "ulocale only"
  {'!init'                      , {            ul, enabled = true}},
                  
  -- "framework"
  {'tips-group'                 , {    d3,     ul, enabled = true}},
                
  -- "event"
  {'on_entity_created'          , {        c1,   }},
  {'on_player_changed_chunk'    , {        c1,   }},
  {'on_ticked_action'           , {        c1,   }},
  {'on_user_panic'              , {        c1,   }},
  
  -- "magic"
  {'babelfish'                  , {s3, d3, c1, ul}},
  {'babelfish-demo'             , {        c1,   }},
  {'gui-auto-styler'            , {        c1,   }},
  {'cursor-tracker'             , {              }},
  {'zoom-tracker'               , {              }},
  
  }

return plugin_array
