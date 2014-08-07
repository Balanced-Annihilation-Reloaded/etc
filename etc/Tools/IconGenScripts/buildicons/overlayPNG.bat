md %~dp0Units\
md %~dp0Overlays\
set black=%~dp0Black__128x128\
set white=%~dp0White__128x128\
set overlay=%~dp0Overlays\
set units=%~dp0Units\
for %%a in ("%black%"*) do (
convert "%%a" "%white%%%~nxa" -compose difference -composite -background white -alpha shape "PNG00:%overlay%%%~nxa"
echo f | xcopy "%%a" /y "%units%%%~nxa"
)
PAUSE