	export	SfxRenderBlockAsm
	export	_SfxRenderBlockAsm

SFX_POKEY_CLOCK	equ	1773447

; void SfxRenderBlockAsm(uint8_t *dst, uint32_t count, TSfxSynthAsmState *state)
;
; Packed state layout: phase.l, threshold.l, noise.l, poly4Pos.w,
; poly5Pos.w, stride4.w, stride5.w, positive.b, negative.b, flags.b, output.b.
; flags: bit 0 = poly5 gate, bit 1 = pure, bit 2 = poly4, bit 3 = noise.

	section	text

SfxRenderBlockAsm:
_SfxRenderBlockAsm:
	movem.l	d2-d7/a2-a3,-(sp)
	movea.l	36(sp),a0
	move.l	40(sp),d7
	movea.l	44(sp),a1
	tst.l	d7
	beq.w	.done
	subq.w	#1,d7

	move.l	0(a1),d0
	move.l	4(a1),d1
	move.l	8(a1),d2
	moveq	#0,d3
	move.w	12(a1),d3
	moveq	#0,d4
	move.w	14(a1),d4
	moveq	#0,d5
	move.w	16(a1),d5
	moveq	#0,d6
	move.w	18(a1),d6

.sampleLoop:
	add.l	#SFX_POKEY_CLOCK,d0
.eventLoop:
	cmp.l	d1,d0
	blo.w	.writeSample
	sub.l	d1,d0

	btst	#2,22(a1)
	beq.s	.noPoly4Step
	add.w	d5,d3
	cmpi.w	#15,d3
	blo.s	.noPoly4Step
	subi.w	#15,d3
.noPoly4Step:
	btst	#0,22(a1)
	beq.s	.noPoly5Step
	add.w	d6,d4
	cmpi.w	#31,d4
	blo.s	.noPoly5Step
	subi.w	#31,d4
.noPoly5Step:

	btst	#3,22(a1)
	beq.s	.noNoiseStep
	move.l	d2,d5
	lsl.l	#1,d5
	eor.l	d5,d2
	move.l	d2,d5
	lsr.l	#5,d5
	eor.l	d5,d2
	move.l	d2,d5
	lsl.l	#8,d5
	lsl.l	#8,d5
	eor.l	d5,d2
.noNoiseStep:

; A closed poly5 gate leaves the previous output unchanged.
	btst	#0,22(a1)
	beq.s	.updateOutput
	lea	Poly5,a2
	movea.w	d4,a3
	tst.b	0(a2,a3.w)
	beq.w	.eventLoop

.updateOutput:
	btst	#1,22(a1)
	beq.s	.notPure
	eori.b	#1,23(a1)
	bra.w	.eventLoop
.notPure:
	btst	#2,22(a1)
	beq.s	.fromNoise
	lea	Poly4,a2
	movea.w	d3,a3
	move.b	0(a2,a3.w),23(a1)
	bra.w	.eventLoop
.fromNoise:
	move.b	d2,23(a1)
	andi.b	#1,23(a1)
	bra.w	.eventLoop

.writeSample:
	tst.b	23(a1)
	beq.s	.negative
	move.b	20(a1),(a0)+
	bra.s	.nextSample
.negative:
	move.b	21(a1),(a0)+
.nextSample:
	dbra	d7,.sampleLoop

	move.l	d0,0(a1)
	move.l	d2,8(a1)
	move.w	d3,12(a1)
	move.w	d4,14(a1)
.done:
	movem.l	(sp)+,d2-d7/a2-a3
	rts

	section	data
Poly4:
	dc.b	1,1,1,1,0,0,0,1,0,0,1,1,0,1,0
Poly5:
	dc.b	1,1,1,1,0,1,1,0,1,0,0,1,1,0,0,0
	dc.b	0,0,1,1,1,0,0,1,0,0,0,1,0,1,0
	even

	END
