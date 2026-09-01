	export	PsgSoundInit
	export	_PsgSoundInit
	export	PsgSoundDone
	export	_PsgSoundDone
	export	PsgSoundStop
	export	_PsgSoundStop
	export	PsgSoundPlay
	export	_PsgSoundPlay

PSG_SELECT	equ	$ffff8800
PSG_DATA	equ	$ffff8802
SYS_NVBL	equ	$00000454
SYS_VBLQUEUE	equ	$00000456

	section	text

; Installs a tiny callback in the TOS VBL queue and preserves PSG channel C.
PsgSoundInit:
_PsgSoundInit:
	movem.l	d2/a2,-(sp)
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	tst.b	PsgInstalled
	bne.w	.initDone

	move.b	#4,PSG_SELECT.w
	move.b	PSG_SELECT.w,PsgOldToneLow
	move.b	#5,PSG_SELECT.w
	move.b	PSG_SELECT.w,PsgOldToneHigh
	move.b	#6,PSG_SELECT.w
	move.b	PSG_SELECT.w,PsgOldNoise
	move.b	#7,PSG_SELECT.w
	move.b	PSG_SELECT.w,PsgOldMixer
	move.b	#10,PSG_SELECT.w
	move.b	PSG_SELECT.w,PsgOldVolume

	moveq	#0,d0
	move.w	SYS_NVBL.w,d0
	movea.l	SYS_VBLQUEUE.w,a0
	moveq	#0,d1
.findSlot:
	tst.l	(a0)
	beq.s	.installSlot
	addq.l	#4,a0
	addq.w	#1,d1
	cmp.w	d0,d1
	blo.s	.findSlot
	bra.s	.initDone
.installSlot:
	move.l	#PsgVblHandler,(a0)
	move.l	a0,PsgQueueSlot
	move.b	#1,PsgInstalled
.initDone:
	move.w	(sp)+,sr
	movem.l	(sp)+,d2/a2
	rts

PsgSoundDone:
_PsgSoundDone:
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	clr.b	PsgActive
	tst.b	PsgInstalled
	beq.s	.doneRestoreSr

	movea.l	PsgQueueSlot,a0
	cmpi.l	#PsgVblHandler,(a0)
	bne.s	.noRemove
	clr.l	(a0)
.noRemove:
	move.b	#4,PSG_SELECT.w
	move.b	PsgOldToneLow,PSG_DATA.w
	move.b	#5,PSG_SELECT.w
	move.b	PsgOldToneHigh,PSG_DATA.w
	move.b	#6,PSG_SELECT.w
	move.b	PsgOldNoise,PSG_DATA.w
	move.b	#7,PSG_SELECT.w
	move.b	PsgOldMixer,PSG_DATA.w
	move.b	#10,PSG_SELECT.w
	move.b	PsgOldVolume,PSG_DATA.w
	clr.b	PsgInstalled
.doneRestoreSr:
	move.w	(sp)+,sr
	rts

PsgSoundStop:
_PsgSoundStop:
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	clr.b	PsgActive
	clr.b	PsgRunFrames
	move.b	#10,PSG_SELECT.w
	clr.b	PSG_DATA.w
	move.w	(sp)+,sr
	rts

; void PsgSoundPlay(const uint8_t *data, uint32_t size)
PsgSoundPlay:
_PsgSoundPlay:
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	movea.l	6(sp),a0
	move.l	10(sp),d0
	move.l	a0,d1
	tst.l	d1
	beq.s	.playStop
	cmpi.l	#3,d0
	blo.s	.playStop
	move.l	a0,PsgData
	adda.l	d0,a0
	move.l	a0,PsgEnd
	clr.b	PsgRunFrames
	move.b	#1,PsgActive
	bra.s	.playDone
.playStop:
	clr.b	PsgActive
	move.b	#10,PSG_SELECT.w
	clr.b	PSG_DATA.w
.playDone:
	move.w	(sp)+,sr
	rts

; TOS calls VBL queue entries with JSR, so this callback ends with RTS.
PsgVblHandler:
	movem.l	d0-d2/a0,-(sp)
	tst.b	PsgActive
	beq.w	.vblDone
	tst.b	PsgRunFrames
	beq.s	.loadRecord
	subq.b	#1,PsgRunFrames
	bra.w	.vblDone

.loadRecord:
	movea.l	PsgData,a0
	move.l	a0,d0
	addq.l	#3,d0
	cmp.l	PsgEnd,d0
	bhi.w	.endEffect
	move.b	(a0)+,d0
	beq.w	.endEffect
	subq.b	#1,d0
	move.b	d0,PsgRunFrames
	moveq	#0,d1
	move.b	(a0)+,d1		; AUDF
	moveq	#0,d2
	move.b	(a0)+,d2		; AUDC
	move.l	a0,PsgData

; POKEY pure-tone frequency maps closely to YM period 4*(AUDF+1).
	addq.w	#1,d1
	lsl.w	#2,d1
	move.b	#4,PSG_SELECT.w
	move.b	d1,PSG_DATA.w
	move.w	d1,d0
	lsr.w	#8,d0
	andi.b	#$0f,d0
	move.b	#5,PSG_SELECT.w
	move.b	d0,PSG_DATA.w

; PSG noise has only 31 periods.  Spread the full AUDF range over them.
	move.w	d1,d0
	lsr.w	#5,d0			; (4*(AUDF+1))/32
	bne.s	.noiseNonZero
	moveq	#1,d0
.noiseNonZero:
	cmpi.w	#31,d0
	bls.s	.noiseReady
	moveq	#31,d0
.noiseReady:
	move.b	#6,PSG_SELECT.w
	move.b	d0,PSG_DATA.w

; Preserve every mixer bit except channel C tone/noise disables (bits 2 and 5).
	move.b	PsgOldMixer,d0
	andi.b	#$db,d0
	move.b	d2,d1
	andi.b	#$e0,d1
	cmpi.b	#$a0,d1
	beq.s	.toneOnly
	cmpi.b	#$20,d1
	beq.s	.toneAndNoise
	ori.b	#$04,d0			; poly/noise modes: noise only
	bra.s	.writeMixer
.toneOnly:
	ori.b	#$20,d0
.toneAndNoise:
.writeMixer:
	move.b	#7,PSG_SELECT.w
	move.b	d0,PSG_DATA.w
	andi.b	#$0f,d2
	lea	PsgVolumeMap,a0
	move.b	0(a0,d2.w),d2
	move.b	#10,PSG_SELECT.w
	move.b	d2,PSG_DATA.w
	bra.s	.vblDone

.endEffect:
	clr.b	PsgActive
	move.b	#10,PSG_SELECT.w
	clr.b	PSG_DATA.w
.vblDone:
	movem.l	(sp)+,d0-d2/a0
	rts

	section	data
; POKEY's volume nibble is much closer to linear amplitude than the logarithmic
; YM2149 levels.  This keeps quiet envelopes audible without flattening peaks.
PsgVolumeMap:
	dc.b	0,7,9,10,11,12,12,13,13,14,14,14,15,15,15,15
	even

	section	bss
PsgData:	ds.l	1
PsgEnd:	ds.l	1
PsgQueueSlot:	ds.l	1
PsgRunFrames:	ds.b	1
PsgActive:	ds.b	1
PsgInstalled:	ds.b	1
PsgOldToneLow:	ds.b	1
PsgOldToneHigh:	ds.b	1
PsgOldNoise:	ds.b	1
PsgOldMixer:	ds.b	1
PsgOldVolume:	ds.b	1
	even

	END
