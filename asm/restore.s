        export RestoreRectsASM
        export _RestoreRectsASM

; cdecl: src, dst, rects, count (four 32-bit arguments).
; Rects: four words x,y,width,height, already clipped to 320x200,
; x/width aligned to 16px. Source and destination have 160-byte stride.
RestoreRectsASM:
_RestoreRectsASM:
        movem.l d2-d3/a2-a4,-(sp)
        movea.l 24(sp),a2
        movea.l 28(sp),a3
        movea.l 32(sp),a0
        move.l  36(sp),d2
        beq     .done
        lea     $ffff8a20.w,a1
.wait:
        btst    #7,28(a1)
        bne.s   .wait
        move.w  #2,(a1)
        move.w  #2,14(a1)
        move.w  #$0203,26(a1)
        clr.b   29(a1)
        moveq   #-1,d0
        move.l  d0,8(a1)
        move.w  d0,12(a1)
        subq.w  #1,d2
.rect:
        moveq   #0,d1
        move.w  (a0)+,d1
        lsr.w   #1,d1
        move.w  (a0)+,d0
        mulu.w  #160,d0
        add.l   d1,d0
        movea.l a2,a4
        adda.l  d0,a4
        move.l  a4,4(a1)
        movea.l a3,a4
        adda.l  d0,a4
        move.l  a4,18(a1)
        move.w  (a0)+,d1
        lsr.w   #1,d1
        move.w  #162,d3
        sub.w   d1,d3
        move.w  d3,2(a1)
        move.w  d3,16(a1)
        lsr.w   #1,d1
        move.w  d1,22(a1)
        move.w  (a0)+,24(a1)
        move.b  #$80,28(a1)
.busy:
        btst    #7,28(a1)
        bne.s   .busy
        dbra    d2,.rect
.done:
        movem.l (sp)+,d2-d3/a2-a4
        rts
