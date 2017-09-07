; 16-bit x 16-bit Division Subroutine
;
; This subroutine divides the 16-bit quantity in register
; pair DE by the 16-bit quantity in register pair BC.
; The result will be stored in register pair DE and the
; remainder in register pair BC.

dv1616:
	ld	hl,temp		;load hl with symbolic address
	ld	(hl),c		;save the LS byte of the divisor
	inc	hl
	ld	(hl),b		;save the MS byte of the divisor
	inc	hl
	ld	(hl),17		;save the divisors bit count (decimal 17)
	ld	bc,0		;BC will store the partial dividend
 nxtbit:
	ld	hl,count	;Load hl with address of bit count (dec 17)
	ld	a,e		;get the LS byte of the divisor
	rla			;rotate the MSB into carry
	ld	e,a
	mov	a,d		;get the MS byte of the divisor
	rla			;rotate the MSB into carry
	mov	d,a
	dec	(hl)		;decrement the bit count
	ret	z		;return if zero
	ld	a,c		;rotate the MSB of the dividend
	rla			; into the partial dividend
	ld	c,a		;  stored in BC
	ld	a,b
	rla
	ld	b,a
	dec	hl		;point HL to divisor in memory
	dec	hl
	ld	a,c		;get the LS byte of partial dividend
	sub	(hl)		;subtract the LS byte of the divisor
	ld	c,a
	inc	hl
	ld	a,b		;get the MS byte of partial dividend
	sbc	(hl)		;subtract with borrow the divisor
	ld	b,a
	jp	nc,noadd	;if carry=0, do not add divisor to
				; the result of previous subtraction
	dec	hl
	ld	a,c		;The divisor is larger than the partial
	add	(hl)		; dividend, so the divisor must be
	ld	c,a		;  added to the result of the subtraction
	inc	hl		;   so that the previous value of the
	ld	a,b		;    partial dividend is re-established.
	adc	(hl)
	ld	b,a
noadd:
	ccf			;complement the carry
	jp	nxtbit

; * Ram memory variables *

temp:
	dw	0
count:
	db	0