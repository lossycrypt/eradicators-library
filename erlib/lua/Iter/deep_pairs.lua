--------------------------------------------------------------------------------
-- RECURSIVE PAIRS (tested and confirmed WORKING!)                            --
--------------------------------------------------------------------------------

---recursive_pairs implements a for-loop compatible depth-first STATEFUL iterator.
---The iterator does not take any input and always returns the next items.
---Key finding uses next(). When a loop is encoutered with verbose_loop_logging != nil
---then any later found entrance points to the loop will be ignored.

---LUA MANUAL on next():
---  The behavior of next is undefined if, during the traversal, you assign any value
---  to a non-existent field in the table. You may however modify existing fields. In
---  particular, you may clear existing fields.

--@opt.max_recursion_depth         = 10000
--@opt.verbose_loop_logging        = nil:error,true:logging,false:silent
--@opt.include_subtables_in_output = false
--@opt.return_path                 = false (include copy of path table in output? slower.)

local function recursive_pairs(tbl,opt) -- no actual recursion involved!
  --sanitize
  if type(tbl) ~= 'table' then error('Recursive pairs: first argument must be a table') end
  if type(opt) ~= 'table' then opt = {} end
  --helper functions
  local function array_copy(arr); local r = {}; for i=1,#arr do r[#r+1] = arr[i]  end; return r end
  --stateful data
  local current_path_keys = {   }  --table of last seen key for each depth
  local current_path_tbls = {tbl}  --ordered parents
  local current_parents   = {   }  --parent -> truth mapping (same content as current_path_tbls)
  --iterator
  local function _iter()
    while #current_path_tbls ~= 0 do
      local depth = #current_path_tbls
      if depth > (opt.max_recursion_depth or 10000) then
        error('Recursive pairs: too deep recursion at: '..table.concat(current_path_keys,'.'))
        end
      local tbl = current_path_tbls[depth]
      local key,value = next(tbl,current_path_keys[depth])
      current_path_keys[depth] = key
      if key ~= nil then
        local RETURN = false
        -- local value_is_table = (type(value) == 'table')
        if type(value) ~= 'table' then
          RETURN = true
        else
          if current_parents[value] then --is value in it's own path?
            if opt.verbose_loop_logging ~= false then
              if opt.verbose_loop_logging == true then
                -- the first key from inside the loop is already on the stack!
                print('Recursive pairs: Ignoring loop at:'..
                  '__self__.'..table.concat(current_path_keys,'.')..' -> '..
                  table.concat({'__self__',unpack(current_parents[value])},'.',1,#current_parents[value]))
              else
                error('Recursive pairs: Loop at: __self__.'..table.concat(current_path_keys,'.'))
                end
              end
          else
            --go into the sub-table
            current_path_tbls[depth+1] = value
            current_parents  [tbl    ] = true --faster to not store path
            if opt.verbose_loop_logging then
              current_parents[tbl] = array_copy(current_path_keys) -- store path for debugging
              end
            if opt.include_subtables_in_output then
              RETURN = true
              end
            end
          end --value != table
        if RETURN then
          if not opt.return_path then
            return key,value,tbl
          else
            return key,value,tbl,array_copy(current_path_keys)
            end
          end
      else
        current_path_keys[depth] = nil --cleanup
        current_path_tbls[depth] = nil --go one table up
        current_parents  [tbl  ] = nil
        end -- key ~= nil
      end -- while depth ~= 0
    end -- _iter
  --stateful iterator. does use external state keeping.
  return _iter,nil,nil
  end

--------------------------------------------------------------------------------
-- Drafts                                                                     --
--------------------------------------------------------------------------------



-- local function recursive_pairs_early_draft(tbl,opt)
-- 
--   local function array_copy(arr); local r = {}; for i=1,#arr do r[#r+1] = arr[i]  end; return r end
-- 
--   local current_path_keys = {   }
--   local current_path_tbls = {tbl}  --ordered parents
--   local current_parents   = {   }  --parent -> truth mapping
-- 
--   local function _iter()
--     while #current_path_tbls ~= 0 do
--       local depth = #current_path_tbls
--       local tbl = current_path_tbls[depth]
--       local key = current_path_keys[depth]
--       key,value = next(tbl,key)
--       current_path_keys[depth] = key
--       if key == nil then
--         current_path_tbls[depth] = nil --go one table up
--         current_parents  [tbl  ] = nil
--       else
--         local value_is_table = (type(value) == 'table')
--         if not value_is_table then
--           --output current state to outside for-loop
--           return {key,value,tbl,array_copy(current_path_keys)}
--         else
--           if not current_parents[tbl] then
--             --recurse down if not looped
--             current_path_tbls[depth+1] = value
--             current_parents  [tbl    ] = true
--             end
--           end
--         end
--       end
--     end
-- 
--   return _iter end
  

return recursive_pairs