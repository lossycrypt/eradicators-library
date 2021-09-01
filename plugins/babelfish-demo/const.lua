-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable
-- -------------------------------------------------------------------------- --

local const = {}

const.name = {
  gui = {
    anchor            = 'er:babelfish-demo-gui-anchor',
    input1            = 'er:babelfish-demo-input1'    ,
    output_serpent    = 'er:babelfish-demo-output2'   ,
    output_table_pane = 'er:babelfish-demo-output1-scroll-pane',
    profiler_label    = 'er:babelfish-demo-profiler-label',
    }
  }
  
const.gui = {
  width  = 1600 + 12, -- +12 fits one more icon
  height =  680,
  sidebar_width = 200,
  }

const.tags = {
  is_sidebar = 'er:babelfish-demo-gui-is-sidebar',
  }
  
return const