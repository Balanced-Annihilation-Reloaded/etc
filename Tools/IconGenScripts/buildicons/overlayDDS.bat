set black=%~dp0Black__128x128\
set white=%~dp0White__128x128\
set overlay=%~dp0Overlays\
set units=%~dp0Units\
for %%a in ("%black%"*) do (
convert "%%a" "%white%%%~nxa" -compose difference -composite -background white -alpha shape -flip "%overlay%%%~na.dds"
convert "%%a" -flip "%units%%%~na.dds"
)
PAUSE