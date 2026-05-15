               export RawIkbdHandler
               export _RawIkbdHandler
               export RawIkbdJoyStatus
               export RawIkbdState

; Raw IKBD/ACIA handler for gameplay joystick mode.
; It recognizes joystick packets $FE/$FF and stores port 1 state.

               section text

RawIkbdHandler:
_RawIkbdHandler:
	movem.l	d0/a0,-(sp)
	btst	#0,$fffffc00
	beq.s	.ack
	move.b	$fffffc02,d0
	cmp.b	#$fe,d0
	beq.s	.joy0_packet
	cmp.b	#$ff,d0
	beq.s	.joy1_packet
	cmp.b	#1,RawIkbdState
	beq.s	.store_joy0
	cmp.b	#2,RawIkbdState
	beq.s	.store_joy1
	bra.s	.ack

.joy0_packet:
	move.b	#1,RawIkbdState
	bra.s	.ack

.joy1_packet:
	move.b	#2,RawIkbdState
	bra.s	.ack

.store_joy0:
	clr.b	RawIkbdState
	bra.s	.ack

.store_joy1:
	move.b	d0,RawIkbdJoyStatus
	clr.b	RawIkbdState

.ack:
	move.b	#$bf,$fffffa11
	movem.l	(sp)+,d0/a0
	rte

               section data

RawIkbdJoyStatus:
	dc.b	0
RawIkbdState:
	dc.b	0
	even
