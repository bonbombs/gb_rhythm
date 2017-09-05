; 
; based on tutorials by Luigi Guatieri and David Pello's

; A blank file. Shows the Nintendo logo and runs forever


; hardware definitions
INCLUDE "gbhw.inc"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Constants

_LCD_ON_SETTINGS EQU	LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON|LCDCF_WIN9C00

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

; TODO: Additional variables

_RAM_BLOCK_1	EQU		_RAM+128

_RAM_BLOCK_2	EQU		_RAM+256

; TODO: Additional RAM blocks as needed

; NOTE: RAM Blocks don't need to be defined as such, but make it
; 		much easier for several people to work without merge conflicts.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;CARTRIDGE HEADER

; Program Begins
SECTION "Start",HOME[$0100] ; location to begin memory (< $0100 is saved for interupts)
	;HOME is memory bank 0 
	
	nop	; no operation
	jp	Start
	
; ROM Header (Macro defined in gbhw.inc)
; defines ROM without mapper, 32K without RAM, the basics
;(like Tetris)
	ROM_HEADER ROM_NOMBC, ROM_SIZE_32KBYTE, RAM_SIZE_0KBYTE

; Our program begins
Start:
	nop
	di				; disable interupts
	ld	sp, $ffff	; load stack pointer into highest ram location
	call StopLCD

; initialization
; load pallets for sprites, windows and backgrounds here
; load map location and scroll variables
; remember to stop LCD before copying tiles to memory
.Init:
	; initialize pallette
	ld	a, %00100111 	; Window palette colors, from darkest to lightest
	ld	[rBGP], a		; CLEAR THE SCREEN

	ld	a,0			; SET SCREEN TO TO UPPER RIGHT HAND CORNER
	ld	[rSCX], a
	ld	[rSCY], a
	
	; erase sprite memory
	ld	de, _OAMRAM		; Sprite attribut memory
	ld	bc, 40*4		; 40 sprites, 4 bytes each
	ld	l, 0			; put everything to zero
	call	FillMemory	; Unused sprites remain off-screen

	; configure and activate LCD (see gbhw.inc line 70-85)
	ld	a, _LCD_ON_SETTINGS
	ld	[rLCDC], a
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Gameplay loop
.GameLoop

; TODO: Gameplay code
	ld a, %11011110
	ld b, %10101101

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Render code (1140 clock cycles)
.Render

; TODO: Rendering code
.wait
	ld a, [rSTAT]
	and %00000011
	cp 1 
	jr nz, .wait
	
	; a small delay
	ld		bc, 1200
	call	Delay
	
	jp .GameLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; End of main program
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Subroutines 
	
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