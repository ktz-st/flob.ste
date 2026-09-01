	export	PsgSoundInit
	export	_PsgSoundInit
	export	PsgSoundDone
	export	_PsgSoundDone
	export	PsgSoundStop
	export	_PsgSoundStop
	export	PsgSoundPlay
	export	_PsgSoundPlay
	export	PsgMusicPlay
	export	_PsgMusicPlay
	export	PsgMusicStop
	export	_PsgMusicStop

PSG_SELECT	equ	$ffff8800
PSG_DATA	equ	$ffff8802
SYS_NVBL	equ	$00000454
SYS_VBLQUEUE	equ	$00000456
MUSIC_REG_COUNT	equ	11

	section	text

; Installs one callback shared by FYM music and channel-C sound effects.
PsgSoundInit:
_PsgSoundInit:
	movem.l	d2/a2,-(sp)
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	tst.b	PsgInstalled
	bne.w	.initDone

	lea	PsgOldRegs,a2
	moveq	#0,d2
.saveRegs:
	move.b	d2,PSG_SELECT.w
	move.b	PSG_SELECT.w,(a2)+
	addq.w	#1,d2
	cmpi.w	#MUSIC_REG_COUNT,d2
	blo.s	.saveRegs

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
	clr.b	MusicActive
	tst.b	PsgInstalled
	beq.s	.doneRestoreSr

	movea.l	PsgQueueSlot,a0
	cmpi.l	#PsgVblHandler,(a0)
	bne.s	.noRemove
	clr.l	(a0)
.noRemove:
	lea	PsgOldRegs,a0
	moveq	#0,d0
.restoreRegs:
	move.b	d0,PSG_SELECT.w
	move.b	(a0)+,PSG_DATA.w
	addq.w	#1,d0
	cmpi.w	#MUSIC_REG_COUNT,d0
	blo.s	.restoreRegs
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
	bsr.w	RestoreMusicChannelC
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
	bsr.w	RestoreMusicChannelC
.playDone:
	move.w	(sp)+,sr
	rts

; void PsgMusicPlay(const uint8_t *fym)
PsgMusicPlay:
_PsgMusicPlay:
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	movea.l	6(sp),a0
	move.l	a0,d0
	beq.s	.musicPlayStop
	cmpi.b	#$46,(a0)		; "FYM1"
	bne.s	.musicPlayStop
	cmpi.b	#$59,1(a0)
	bne.s	.musicPlayStop
	cmpi.b	#$4d,2(a0)
	bne.s	.musicPlayStop
	cmpi.b	#$31,3(a0)
	bne.s	.musicPlayStop
	moveq	#0,d0
	move.b	4(a0),d0
	lsl.w	#8,d0
	move.b	5(a0),d0
	move.w	d0,MusicFrameCount
	beq.s	.musicPlayStop
	moveq	#0,d0
	move.b	6(a0),d0
	lsl.w	#8,d0
	move.b	7(a0),d0
	move.w	d0,MusicLoopFrame
	lea	16(a0),a0
	move.l	a0,MusicBody
	move.l	a0,MusicData
	clr.w	MusicFrame
	clr.b	PsgActive
	clr.b	PsgRunFrames
	move.b	#1,MusicActive
	bra.s	.musicPlayDone
.musicPlayStop:
	clr.b	MusicActive
.musicPlayDone:
	move.w	(sp)+,sr
	rts

PsgMusicStop:
_PsgMusicStop:
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	clr.b	MusicActive
	clr.b	MusicRegs+8
	clr.b	MusicRegs+9
	move.b	#8,PSG_SELECT.w
	clr.b	PSG_DATA.w
	move.b	#9,PSG_SELECT.w
	clr.b	PSG_DATA.w
	tst.b	PsgActive
	bne.s	.musicStopDone
	clr.b	MusicRegs+10
	move.b	#10,PSG_SELECT.w
	clr.b	PSG_DATA.w
.musicStopDone:
	move.w	(sp)+,sr
	rts

; Apply one FYM register-delta frame. While an SFX is active, channel C and
; its noise/mixer registers are updated only in the music shadow state.
MusicVblUpdate:
	tst.b	MusicActive
	beq.w	.musicDone
	move.w	MusicFrame,d0
	cmp.w	MusicFrameCount,d0
	blo.s	.musicHaveFrame
	cmpi.w	#$ffff,MusicLoopFrame
	beq.s	.musicEnd
	tst.w	MusicLoopFrame
	bne.s	.musicEnd		; FYM1 currently indexes only loop frame zero
	clr.w	MusicFrame
	move.l	MusicBody,MusicData
.musicHaveFrame:
	movea.l	MusicData,a0
	moveq	#0,d0
	move.b	(a0)+,d0
	lsl.w	#8,d0
	move.b	(a0)+,d0
	moveq	#0,d1
	lea	MusicRegs,a1
.musicRegLoop:
	btst	d1,d0
	beq.s	.musicNextReg
	move.b	(a0)+,(a1)
	tst.b	PsgActive
	beq.s	.musicWriteReg
	cmpi.w	#4,d1
	blo.s	.musicWriteReg
	cmpi.w	#7,d1
	bls.s	.musicNextReg
	cmpi.w	#10,d1
	beq.s	.musicNextReg
.musicWriteReg:
	move.b	d1,PSG_SELECT.w
	move.b	(a1),PSG_DATA.w
.musicNextReg:
	addq.l	#1,a1
	addq.w	#1,d1
	cmpi.w	#MUSIC_REG_COUNT,d1
	blo.s	.musicRegLoop
	move.l	a0,MusicData
	addq.w	#1,MusicFrame
.musicDone:
	rts

.musicEnd:
	clr.b	MusicActive
	clr.b	MusicRegs+8
	clr.b	MusicRegs+9
	clr.b	MusicRegs+10
	move.b	#8,PSG_SELECT.w
	clr.b	PSG_DATA.w
	move.b	#9,PSG_SELECT.w
	clr.b	PSG_DATA.w
	tst.b	PsgActive
	bne.s	.musicDone
	move.b	#10,PSG_SELECT.w
	clr.b	PSG_DATA.w
	bra.s	.musicDone

RestoreMusicChannelC:
	tst.b	MusicActive
	beq.s	.noMusicC
	move.b	#4,PSG_SELECT.w
	move.b	MusicRegs+4,PSG_DATA.w
	move.b	#5,PSG_SELECT.w
	move.b	MusicRegs+5,PSG_DATA.w
	move.b	#6,PSG_SELECT.w
	move.b	MusicRegs+6,PSG_DATA.w
	move.b	#7,PSG_SELECT.w
	move.b	MusicRegs+7,PSG_DATA.w
	move.b	#10,PSG_SELECT.w
	move.b	MusicRegs+10,PSG_DATA.w
	rts
.noMusicC:
	move.b	#10,PSG_SELECT.w
	clr.b	PSG_DATA.w
	rts

; TOS calls VBL queue entries with JSR, so this callback ends with RTS.
PsgVblHandler:
	movem.l	d0-d2/a0-a1,-(sp)
	bsr.w	MusicVblUpdate
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

; Preserve music A/B mixer state while the effect owns channel C.
	tst.b	MusicActive
	beq.s	.useOldMixer
	move.b	MusicRegs+7,d0
	bra.s	.haveMixer
.useOldMixer:
	move.b	PsgOldRegs+7,d0
.haveMixer:
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
	bsr.w	RestoreMusicChannelC
.vblDone:
	movem.l	(sp)+,d0-d2/a0-a1
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
MusicBody:	ds.l	1
MusicData:	ds.l	1
MusicFrameCount:	ds.w	1
MusicLoopFrame:	ds.w	1
MusicFrame:	ds.w	1
PsgRunFrames:	ds.b	1
PsgActive:	ds.b	1
MusicActive:	ds.b	1
PsgInstalled:	ds.b	1
MusicRegs:	ds.b	MUSIC_REG_COUNT
PsgOldRegs:	ds.b	MUSIC_REG_COUNT
	even

	END
