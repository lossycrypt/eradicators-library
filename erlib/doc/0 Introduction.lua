-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--[[------------------------------------------------

  Eradicator's Library or "ErLib" is a pure-lua library for @{Factorio}
  that can also survive in non-factorio environments.
 
  Architecture:
     + ErLib is fully self contained inside it's subfolder.
     + ErLib knows which mod it is loaded from and when.
     + ErLib uses local files if remote files can't be found. (not per-file)
     + ErLib is built to be scenario compatible. Though some features
       like the default linked hotkeys can not be used in that mode.
     + The Core is completely passive by default.
     + Normal modules on require return a function that when called returns
       *up to* three objects: ModuleTable, StrictWrapper, uLocale.
     + Test modules return exactly two objects: TestFunction, PhaseTable
     + Except for Core no module ever changes _ENV.
       And even Core only does so on request.
     + All modules are stand-alone. (requirements will be auto-loaded)
 
  Features:
     + ErLib can be used in a non-factorio environment for testing. Obviously
       factorio features don't work in that mode (they will throw errors).
     + ErLib has several advanced features like the EventManager,
       PluginManager, HotkeyManager and more that automate common tasks
       at a much higher level than other factorio libraries do.
 
  Todo:
     + More control flow logging
     + Port and document all old modules
     + Core loads all modules outside of Core Function so the output can
       dynamically be rebuilt.
     + Add global flags (devmode, strictmode, etc)
     + use Sha2.lua instead of Sha256.lua?
     + Remove unused functions from LibDeflate
 
  Future:
     + Runtime dis/enable of STRICT_MODE
 
  @file Introduction
  @author lossycrypt (factorio: eradicator)
  @copyright Eradicators Library, lossycrypt, 2017-2020
  @license CC Attribution-NoDerivatives 4.0 International

]]


----------
-- How stable an Erlib module is.
-- 
-- This is intended as an indicator for mod developers who are unsure
-- if they have to expect sudden api changes.
-- 
--   * __Work in progress__: The module is new or undergoing refractoring.
--   Major api changes will happen frequently and unannouncedly.
--
--   * __Polishing__: All current module methods are feature complete but may
--   still need performance optimizations. New methods might be added.
--   Some tweaks to old methods might also happen.
--
--   * __Experimental__: The module is feature-frozen, only bugfixes are
--   expected. Minor changes are unlikely, but if they happen they will
--   be announced via the changelog. The latest date of change will be documented.
--   This is the best time to give feedback.
--
--   * __Stable__: The module has been unchanged and without bug-reports
--   for at least 4 weeks. Bugfixes or optimizations will result in a
--   status downgrade to Experimental.
-- 
-- @within Information about this Library
-- @table DevelopmentStatus
