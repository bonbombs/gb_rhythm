1. Extract the archive. Your directory should look like this:
	/bgb
	/Documentation
	/inc
	/Map Editor
	/obj
	/src
	/Tile Designer
	RGBASM95.EXE
	RGBFIX95.EXE
	XLIB95.EXE
	XLINK95.EXE
	Map.gbm
	Window.gbm
	tiles.gbr
	assemble.sh
   assignment.txt
   readme.txt
	assemble.bat
	makelnk.bat
   
2. The .gbr and .gbm files have directory information baked into the file, so open them up in a text editor and replace those directory paths with ones that match your computer. Then you can open the files for edit.

	a. Tiles should be exported with the following options (except for how many tiles you use):
	
	; Info:
	;   Section              : TileSection
	;   Bank                 : 0
	;   Form                 : All tiles as one unit.
	;   Format               : Gameboy 4 color.
	;   Compression          : None.
	;   Counter              : None.
	;   Tile size            : 8 x 8
	;   Tiles                : 0 to 31
	;
	;   Palette colors       : None.
	;   SGB Palette          : None.
	;   CGB Palette          : None.
	;
	;   Convert to metatiles : No.
	
	b. Maps should be exported with the following options
	
	; Info:
	;   Section       : MapSection
	;   Bank          : 0
	;   Map size      : 32 x 32
	;   Tile set      : C:\gameboy\GameBoy\tiles.gbr
	;   Plane count   : 1 plane (8 bits)
	;   Plane order   : Tiles are continues
	;   Tile offset   : 0
	;   Split data    : No
	
	For Location format, you'll want to add [Tile Number], 7 bits, make sure you have Rows, 1 plane (8 bits), tiles are continuous and offset = 0.
	
	c. I recommend testing that it's correct by exporting the unchanged files, making sure they run correctly, and only then making your own changes.
	
3. Open a command window in the GameBoy directory and run `assemble.bat <project_name>`, so if you have myGame.asm in /src, you'd run `assemble.bat myGame`. Linux users run the .sh file instead.

4. In the /obj folder you will see that there are several files, including a .gb file, which is the compiled binary. Run this in BGB.