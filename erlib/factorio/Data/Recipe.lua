-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------
-- Description
--
-- @{Introduction.DevelopmentStatus|Module Status}: Work in progress.
--
-- @module Data
-- @usage
--  local Recipe = require('__eradicators-library__/erlib/factorio/Data/Recipe')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
-- local log         = elreq('erlib/lua/Log'          )().Logger  'DataRecipe'
local stop        = elreq('erlib/lua/Error'        )().Stopper 'DataRecipe'

local Verificate  = elreq('erlib/lua/Verificate'   )()
local isType      = Verificate.isType
local verify      = Verificate.verify
local assertify   = elreq('erlib/lua/Error'        )().Asserter(stop)

local Table       = elreq('erlib/lua/Table'        )()
local ntuples     = elreq('erlib/lua/Iter/ntuples' )()
local fpairs2     = elreq('erlib/lua/Iter/fpairs2' )()

local Prototype   = elreq('erlib/factorio/Data/Prototype')()


-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Recipe,_Recipe = {},{}


--------------------------------------------------------------------------------
-- Recipe.
-- @usage
--  local Recipe = require('__eradicators-library__/erlib/factorio/Data/Recipe')()
-- @section
--------------------------------------------------------------------------------

----------
-- Copies the unlock conditions of one recipe to another.
-- This includes the recipe.enabled parameter for all defined difficulties
-- as well as the technology unlocks if there are any.
-- 
-- __Note:__ All recipe prototypes invloved must exist before calling this.
-- 
-- @tparam string source_name
-- @tparam string|DenseArray target_names
-- 
function Recipe.copy_unlock_condition(source_name, target_names)
  verify(source_name, 'NonEmptyString', 'Missing source_name.')
  target_names = Table.plural(target_names)
  verify(target_names, 'NonEmptyArrayOfNonEmptyString', 'Missing target_names.')
  --
  -- Inherit no-research unlock status.
  local normal, expensive
      = Prototype.get_enabled(Prototype.get('recipe', source_name))
  for _, name in ipairs(target_names) do
    Prototype.set_enabled( Prototype.get('recipe', name), normal, expensive)
    end
  --
  local function find_unlock(tech)
    for i, effect in ntuples(2, tech.effects) do
      if effect.type == 'unlock-recipe'
      and effect.recipe == source_name
      then return i + 1, tech.effects end
      end
    end
  --
  local function add_unlocks(tbl, key)
    if isType.table(tbl[key]) then
      local i, effect = find_unlock(tbl[key])
      if i then
        for j, name in ipairs(target_names) do
          table.insert(effect, i + (j-1), {
            type   = 'unlock-recipe',
            recipe =  name,
            })
          end
        end
      end
    end
  -- Why do technologies have difficulty garbage?!
  for name, tech in pairs(data.raw.technology) do
    add_unlocks(data.raw.technology, name)
    add_unlocks(tech, 'normal')
    add_unlocks(tech, 'expensive')
    end
  end

  
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Recipe') end
return function() return Recipe,_Recipe end
