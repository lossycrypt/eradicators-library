
rem Deadlocks python script is at https://forums.factorio.com/viewtopic.php?p=539964

::generic 4-level mipmap generator for square images
::handles one input file at a time

for /f %%x in ('identify -format "%%w" "%1"') do set _width=%%x
set _copy= ^( +clone -resize 50%% +repage -geometry +%_width%+0 ^) -composite
convert "%1" -background transparent -extent 187.5%%x100%% %_copy% %_copy% %_copy% "%~n1-%_width%-mip4%~x1"