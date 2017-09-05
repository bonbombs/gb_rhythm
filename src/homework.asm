; 
; based on tutorials by Luigi Guatieri and David Pello

; Homework assignment for Game Boy Programming class

; hardware definitions
INCLUDE "gbhw.inc"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Constants

; Bitflags for dpad directions
_PAD_B			EQU		%00000001
_PAD_A			EQU		%00000010
_PAD_RIGHT		EQU		%00010000
_PAD_LEFT		EQU		%00100000
_PAD_UP			EQU		%01000000
_PAD_DOWN		EQU		%10000000

_RHYTHM_OFFSET	EQU		%00001000	; 8 frames of rhythm offset

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; OAM Memory locations

;Sprite 0
_SPR0_Y		EQU			_OAMRAM   	; y position
_SPR0_X		EQU			_OAMRAM+1	; x position
_SPR0_NUM	EQU			_OAMRAM+2	; tile number
_SPR0_ATT	EQU			_OAMRAM+3	; sprite atttributes

; TODO: Sprites [1-39] go here as needed

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RAM Memory locations

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; BLOCK 0: Global data used across the application
_RAM_BLOCK_0	EQU		_RAM	;RAM is 8K without bank switching

padInput		EQU		_RAM_BLOCK_0		;Read input into here
player0X		EQU		_RAM_BLOCK_0+1		;player 0's world x pos
player0Y		EQU		_RAM_BLOCK_0+2		;player 0's world y pos
screenX			EQU		_RAM_BLOCK_0+3		;camera x
screenY			EQU		_RAM_BLOCK_0+4		;camera y
timer			EQU		_RAM_BLOCK_0+5		;global timer
padTime			EQU		_RAM_BLOCK_0+6		;time at which padInput happened
score			EQU		_RAM_BLOCK_0+7		;player score

; TODO: Additional variables

_RAM_BLOCK_1	EQU		_RAM+128

startScreenToggle	EQU	_RAM_BLOCK_1

_RAM_BLOCK_2	EQU		_RAM+256

; TODO: Additional RAM blocks as needed

; NOTE: RAM Blocks don't need to be defined as such, but make it
; 		much easier for several people to work without merge conflicts.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;CARTRIDGE HEADER

; Program Begins
SECTION "start", HOME[$0100]	; location to begin memory (< $0100 is saved for interupts)
								; HOME is memory bank 0
	nop							; no operation
	jp		start

; ROM Header (Macro defined in gbhw.inc)
; defines ROM without mapper, 32K without RAM, the basics (like Tetris)
	ROM_HEADER ROM_NOMBC, ROM_SIZE_32KBYTE, RAM_SIZE_0KBYTE

; Our program begins
start:
	nop
	di					; disable interupts
	ld		sp, $FFFF	; load stack pointer into highest ram location

	call	StopLCD 	; Kill LCD immediately

; initialization
; load pallets for sprites, windows and backgrounds here
; load map location and scroll variables
; remember to stop LCD before copying tiles to memory
.Init:
	
	; palletes
	ld		a, %11100100	; pallete colors, darkest to lightest
	ld		[rBGP], a		; load colors into contents of pallete register
	ld		[rOBP0], a		; load contents of pallete into sprite pallete
	ld		[rOBP1], a		; load contents of pallete into sprite pallete
		
	ld		a, 0			; load start screen toggle value
	ld		[startScreenToggle], a
	
	; Load the tiles
	ld	hl, Tiles	; HL loaded with sprite data
	ld	de, _VRAM	; address for video memory into de
	ld	bc, EndTiles-Tiles	; number of bytes to copy
	call CopyMemory
	
	; Load the tile map
	ld	hl, Map
	ld	de, _SCRN0		; map 0 loaction
	ld	bc, 32*32		; 32 by 32 tiles
	call	CopyMemory
	
	; Load the window tile map
	ld		hl, WindowLabel
	ld		de, _SCRN1		; map 1 location
	ld		bc, 32*32		; screen size
	call 	CopyMemory
	
	; erase sprite memory
	ld	de, _OAMRAM		; Sprite memory
	ld	bc, 40*4		; 40 sprites, 4 bytes each
	ld	l, 0			; put everything to zero
	call	FillMemory	; Unused sprites remain off-screen
	
	; Now we wil create the sprites
	ld	a, 64
	ld	[player0Y], a
	ld	[_SPR0_Y], a	; y position of sprite
	ld	a, 64
	ld	[player0X], a
	ld	[_SPR0_X], a	; x position of sprite
	ld	a, 1			; select sprite 1 (smiley)
	ld	[_SPR0_NUM], a	; load a into contents of _SPR0_NUM
	ld	a, 16
	ld	[_SPR0_ATT], a	; special attribute, pallet 1
	
	; Configure the screen
	ld 	a, 64
	ld [screenX], a
	ld [rSCX], a
	
	ld	a, 64
	ld	[screenY], a
	ld [rSCY], a
	
	; configure and activate LCD (see gbhw.inc line 70-85)
	ld		a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON|LCDCF_WIN9C00
	ld		[rLCDC], a

	; zero timer
	ld	a, 0
	ld	[timer], a
	ld	a, 0
	ld	[padTime], a
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Gameplay loop
.GameLoop

	call	StartScreen
	call	ReadPad
	;call	UpdatePadTime
	call 	UpdateTimer
	call	HandleTimer
	call 	Movement
	;call	Collision
	;call	DoMovement
	
	; Wait until we are in VBlank
.wait
	ld a, [rSTAT]
	and %00000011
	cp 1 
	jr nz, .wait
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Render code (1140 clock cycles)
.Render

	;Update the player x and y position in OAM
	ld 	a, [player0X]
	ld 	[_SPR0_X], a
	
	ld 	a, [player0Y]
	ld 	[_SPR0_Y], a
	
	ld	a, [screenX]
	ld [rSCX], a
	
	ld	a, [screenY]
	ld [rSCY], a
	
	; a small delay to guarantee we're out of VBlank
	ld		bc, 1200
	call	Delay
	
	jp .GameLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; End of main program
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Subroutines 
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Read the D-Pad input
ReadPad:
	; check the d-pad
	ld	a, %00100000	; bit 4 to 0, 5 to 1 (Activate d-pad, not buttons)
	ld	[rP1], a		; button register
	
	; now we read the state of the d-pad, and avoid bouncing
	ld	a, [rP1]
	ld	a, [rP1]
	ld	a, [rP1]
	ld	a, [rP1]
	
	and	$0F		; only care about the lower 4 bits
	swap a		; lower and upper combined
	ld	b, a	; save state in b
	
	; check buttons
	ld	a, %00010000	; bit 4 to 1, 5 to 0 (activated buttons, no d-pad)
	ld	[rP1], a
	
	; read several times to avoid bouncing
	ld	a, [rP1]
	ld	a, [rP1]
	ld	a, [rP1]
	ld	a, [rP1]
	
	; check A against buttons
	and $0F	; only care about bottom 4 bits
	or b	; or with b to 'meter' the d-pad status
	
	; now we have in A the state of all buttons, compliment and store variable
	cpl
	ld	[padInput], a
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
; Show the window
StartScreen:
	ld		a, [startScreenToggle]
	cp		0
	ret 	nz

	ld		a, 8
	ld		[rWX], a	; window x location

	ld		a, 0
	ld		[rWY], a	; window y location

	; activate windows and deactivate sprites
	ld		a, [rLCDC]	; load LCD control contents
	or		LCDCF_WINON	; check if window is on
	res		1, a		; bit 1 to 0
	ld		[rLCDC], a

.CheckExit
	call	ReadPad
	and		%00001000	; start button
	jr		z, .CheckExit

.CloseWindow
	; turn off start screen toggle
	ld		a, 5
	ld		[startScreenToggle], a

	; deactivate the window and activate the sprites
	ld		a, [rLCDC]
	res		5, a			; reset window sprites to 0
	or		LCDCF_OBJON		; turn on objects
	ld		[rLCDC], a		; apply changes
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Move the player position based on pad input
Movement:
	ld		a, [padInput]	; load status of pad
	ld		b, a			; Save in b so we can reset easily

	cp		0				; Return if we have no input
	jr		nz, .CheckMovement
	ret

.CheckMovement

	ld 		a, b
	cp 		a,0
	and		_PAD_RIGHT
	call	nz, MoveRight

	ld		a, b
	and		_PAD_LEFT
	call	nz, MoveLeft

	ld		a, b
	and		_PAD_UP
	call	nz, MoveUp

	ld		a, b
	and		_PAD_DOWN
	call	nz, MoveDown
	ret

MoveLeft:
	ld		a, [player0X]
	cp		a, 32
	jp		z, .LeftScreen
.LeftPlayer:
	dec		a
	ld		[player0X], a
	ret
.LeftScreen:
	;Move the screen instead of the player
	ld 		a, [screenX]
	dec		a
	ld		[screenX], a
	ret

MoveRight:
	ld		a, [player0X]
	cp		a, 136
	jp		z, .RightScreen
.RightPlayer:
	inc		a
	ld		[player0X], a
	ret
.RightScreen:
	;Move the screen instead of the player
	ld 		a, [screenX]
	inc		a
	ld		[screenX], a
	ret

MoveUp:
	ld		a, [player0Y]
	cp		a, 32
	jp		z, .UpScreen
.UpPlayer:
	dec		a
	ld		[player0Y], a
	ret
.UpScreen:
	;Move the screen instead of the player
	ld 		a, [screenY]
	dec		a
	ld		[screenY], a
	ret

MoveDown:
	ld		a, [player0Y]
	cp		a, 136
	jp		z, .DownScreen
.DownPlayer:
	inc		a
	ld		[player0Y], a
	ret
.DownScreen:
	;Move the screen instead of the player
	ld 		a, [screenY]
	inc		a
	ld		[screenY], a
	ret

UpdatePadTime:
	ld		a, [timer]	; padTimer = timer
	ld		[padTime], a
	; ld		a,	60
	; ld		b, [padTimer]
	; sub		b					; Find difference between timer and when pad input was done
	; and		%01111111, b		; Change sign bit to positive
	; ld		a, b				; Load the result into A
	; cp		_RHYTHM_OFFSET		; Do a compare
	; jp		z, .HandleScore		; If difference = _RHYTHM_OFFSET, set perfect score
	; jp		c, .HandleScoreSub	; If difference < _RHYTHM_OFFSET, set suboptimal score
	; jp		.HandleScoreBad		; Else we did a goof ):
	ret							

UpdateTimer:
	ld		a, [timer]
	inc		a
	ld		[timer], a
	ret

HandleTimer:
	ld		a, [timer]
	cp		60
	jp		z, .HandleBeat
	ret

.HandleBeat:
	ld		a, 0
	ld		[timer], a
	;call	functions here
	call	MoveLeft
	;call	.MetronomeBeat
	ret

.MetronomeBeat:
	; do sound stuff here
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Wait until end of frame, then stop the LCD
StopLCD:
	ld	a,[rLCDC]				; Get the LCD status value
	rlca						; rotate high bit into the carry
	ret	nc						; If the screen is already off, return

	call WaitForVBlank
	
	ld	a, [rLCDC]				; Get the LCD status value
	res	7, a					; Set bit 7 to 0
	ld	[rLCDC], a				; Turn off the LCD
	
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
; Wait until we are in VBlank and can write to OEM
WaitForVBlank
	ld a, [rSTAT]
	and %00000011
	cp 1 
	jr nz, WaitForVBlank
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

; Fill a destination address (de) of length (bc) with value (l)
; Ex. de = 0, bc = 16, l = 0 will clear the first 16 bytes of RAM.
FillMemory:
	ld	a, 1
	ld	[de], a	; puts data in destination
	dec	bc	; next fill
	
	ld	a, c
	or b
	ret	z	; return if zero
	inc	de	; keep going
	jr	FillMemory
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

; Copy a destination address (de) with (bc) bytes from source address (hl)
CopyMemory:
	ld	a, [hl]	; load data to be copied in a
	ld	[de], a	; load copied to data to new address
	dec	bc	; moving to next copy
	; check if bc is zero
	ld	a, c
	or	b
	ret	z ; if zero, return
	; no? continue
	inc hl
	inc de
	jr	CopyMemory

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

; Delay for (bc) number of rotations
Delay:
.Slow:
	dec	bc ; decrement the iteration count

	; Check if bc is zero
	ld	a, b
	or	c
	jr	z, .EndDelay ; if so, we're done.

	nop
	jr	.Slow

.EndDelay:
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Included tiles, maps and windows

Tiles:
INCLUDE "Tiles.z80"
EndTiles:

; screen size 20x17
Map:
INCLUDE"Map.z80"
EndMap:

Window:
INCLUDE "Window.z80"
EndWindow: