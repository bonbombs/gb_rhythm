;A - Accumulator (Math is done here)

;B, C, D, E, H, L
;BC, DE, HL

;add 2 and 2

ld a, 2
adc 2
; 4 in a

ld 0, a

; compare w/ Accumulator but doesn't destroy it
ld a, (playerX)
cp 5
jp z, .Label

; other code here

.Label

; shifting labels left/right mutliplies it by 2