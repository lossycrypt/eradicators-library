"Hooks" are plugins that work around *HARD* factorio API limitations.
They are so expensive or intrusive to run that they should never be run
more than once. So to make them usable to more than one mod they
run inside the library lua sandbox, and they only run when explicitly requested.
All interaction with hacks is therefore remote.interface or event based.