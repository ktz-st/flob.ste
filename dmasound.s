	export	DmaSoundInit
	export	DmaSoundDone
	export	DmaSoundStop
	export	DmaPlayLoop

	TEXT

DmaSoundInit:
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	move.b	$ffff8901.w,sDmaControl
	move.b	$ffff8921.w,sDmaMode
	clr.b	$ffff8901.w
	move.w	(sp)+,sr
	rts

DmaSoundDone:
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	clr.b	$ffff8901.w
	move.b	sDmaMode,$ffff8921.w
	move.b	sDmaControl,$ffff8901.w
	move.w	(sp)+,sr
	rts

DmaSoundStop:
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	clr.b	$ffff8901.w
	move.w	(sp)+,sr
	rts

DmaPlayLoop:
	movem.l	d1/a0,-(sp)
	move.l	a0,d1
	beq.s	.loopDone
	tst.l	d0
	beq.s	.loopDone

	move.w	sr,-(sp)
	ori.w	#$0700,sr
	clr.b	$ffff8901.w

	move.b	d1,$ffff8907.w
	lsr.l	#8,d1
	move.b	d1,$ffff8905.w
	lsr.l	#8,d1
	move.b	d1,$ffff8903.w

	move.l	a0,d1
	add.l	d0,d1
	move.b	d1,$ffff8913.w
	lsr.l	#8,d1
	move.b	d1,$ffff8911.w
	lsr.l	#8,d1
	move.b	d1,$ffff890f.w

	move.b	#$81,$ffff8921.w		; 12517 Hz, 8-bit, mono
	move.b	#3,$ffff8901.w		; play with looping enabled

	move.w	(sp)+,sr
.loopDone:
	movem.l	(sp)+,d1/a0
	rts

sDmaControl:
	dc.b	0
sDmaMode:
	dc.b	0
	even

	END
