Copy ./luarules to game dir
Copy ./buildicons to spring dir

Load spring with BAR, and type /luarules buildiconslow to build all icons at a rate of 1 per minute.
Type /luarules buildicon armcom to build just one unit

Icon generator creates two folders in /SpringDir/buildicons

After creating icons in spring run either overlayPNG.bat or overlayDDS.bat (BAR widgets are set to use DDS). Double check the .bat file for the correct resolution paths[

Copy newly created "Overlays" and "Units" to /gameDir/luaui/images/buildIcons/

Done
