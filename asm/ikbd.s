               export RawIkbdHandler
               export _RawIkbdHandler
               export RawIkbdJoyStatus
               export RawIkbdJoy0Status
               export RawIkbdState
               export RawIkbdKeyStates
               export RawIkbdKeyEventHead
               export RawIkbdKeyEventRing

; Lightweight AGT-style IKBD service for gameplay.
; It keeps instantaneous state for all 128 keys, records make/break events in
; a 256-byte ring, and parses joystick $FE/$FF packets without BIOS polling.

               section text

RawIkbdHandler:
_RawIkbdHandler:
	movem.l	d0-d1/a0,-(sp)
	btst	#0,$fffffc00
	beq.w	.ack
	moveq	#0,d0
	move.b	$fffffc02,d0

	cmp.b	#1,RawIkbdState
	beq.s	.store_joy0
	cmp.b	#2,RawIkbdState
	beq.s	.store_joy1
	cmp.b	#$fe,d0
	beq.s	.joy0_packet
	cmp.b	#$ff,d0
	beq.s	.joy1_packet

; Keyboard make/break code. Record every event, then update key_states[code].
	moveq	#0,d1
	move.b	RawIkbdKeyEventHead,d1
	lea	RawIkbdKeyEventRing,a0
	move.b	d0,(a0,d1.w)
	addq.b	#1,RawIkbdKeyEventHead

	move.w	d0,d1
	andi.w	#$007f,d1
	lea	RawIkbdKeyStates,a0
	btst	#7,d0
	bne.s	.key_release
	st	(a0,d1.w)
	bra.s	.ack

.key_release:
	clr.b	(a0,d1.w)
	bra.s	.ack

.joy0_packet:
	move.b	#1,RawIkbdState
	bra.s	.ack

.joy1_packet:
	move.b	#2,RawIkbdState
	bra.s	.ack

.store_joy0:
	move.b	d0,RawIkbdJoy0Status
	clr.b	RawIkbdState
	bra.s	.ack

.store_joy1:
	move.b	d0,RawIkbdJoyStatus
	clr.b	RawIkbdState

.ack:
	move.b	#$bf,$fffffa11
	movem.l	(sp)+,d0-d1/a0
	rte

               section data

RawIkbdJoy0Status:
	dc.b	0
RawIkbdJoyStatus:
	dc.b	0
RawIkbdState:
	dc.b	0
RawIkbdKeyEventHead:
	dc.b	0
	even

               section bss

RawIkbdKeyStates:
	ds.b	128
RawIkbdKeyEventRing:
	ds.b	256
	even
