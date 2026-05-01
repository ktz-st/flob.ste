               export DrawChar
               export _DrawChar
               export FlobFont

; void DrawChar(uint8_t *screen, uint8_t *font,
;     uint32_t x, uint32_t y, uint32_t ch, uint32_t fg, uint32_t bg)
;
; 28(sp) = screen, 32 = font, 36 = x, 40 = y,
; 44 = ch, 48 = fg, 52 = bg

DrawChar:
_DrawChar:
	movem.l	d2-d7,-(sp)

	movea.l	28(sp),a0
	movea.l	32(sp),a1

	move.l	40(sp),d0
	mulu.w	#160,d0
	move.l	36(sp),d1
	move.w	d1,d2
	lsr.w	#4,d2
	lsl.w	#3,d2
	add.w	d2,d0
	ext.l	d0
	adda.l	d0,a0

	move.l	44(sp),d0
	lsl.l	#3,d0
	adda.l	d0,a1

	andi.w	#8,d1
	lsr.w	#3,d1
	ext.l	d1
	move.l	d1,d5

	move.l	48(sp),d2
	move.l	52(sp),d3

	moveq	#7,d7

font_row:
	move.b	(a1)+,d0
	move.b	d0,d6
	not.b	d6

	moveq	#0,d4
	btst	#0,d2
	beq.s	font_p0_fg_done
	move.b	d0,d4
font_p0_fg_done:
	btst	#0,d3
	beq.s	font_p0_bg_done
	or.b	d6,d4
font_p0_bg_done:
	move.b	d4,0(a0,d5.w)

	moveq	#0,d4
	btst	#1,d2
	beq.s	font_p1_fg_done
	move.b	d0,d4
font_p1_fg_done:
	btst	#1,d3
	beq.s	font_p1_bg_done
	or.b	d6,d4
font_p1_bg_done:
	move.b	d4,2(a0,d5.w)

	moveq	#0,d4
	btst	#2,d2
	beq.s	font_p2_fg_done
	move.b	d0,d4
font_p2_fg_done:
	btst	#2,d3
	beq.s	font_p2_bg_done
	or.b	d6,d4
font_p2_bg_done:
	move.b	d4,4(a0,d5.w)

	moveq	#0,d4
	btst	#3,d2
	beq.s	font_p3_fg_done
	move.b	d0,d4
font_p3_fg_done:
	btst	#3,d3
	beq.s	font_p3_bg_done
	or.b	d6,d4
font_p3_bg_done:
	move.b	d4,6(a0,d5.w)

	lea	160(a0),a0
	dbra	d7,font_row

	movem.l	(sp)+,d2-d7
	rts

	section data
FlobFont:
	incbin	"font/flob.fnt"
