        export RestoreRectsASM
        export _RestoreRectsASM
        export PrepareRestoreRectsASM
        export _PrepareRestoreRectsASM
        export RestorePreparedASM
        export _RestorePreparedASM

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
        move.w  (a0)+,d1
        lsr.w   #1,d1
        move.w  (a0)+,d0
        add.w   d0,d0
        add.w   RestoreLineOffsets(pc,d0.w),d1
        movea.l a2,a4
        adda.w  d1,a4
        move.l  a4,4(a1)
        movea.l a3,a4
        adda.w  d1,a4
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
        move.b  #$c0,28(a1)
.busy:
        btst    #7,28(a1)
        bne.s   .busy
        dbra    d2,.rect
.done:
        movem.l (sp)+,d2-d3/a2-a4
        rts

; Clipped screen offsets fit signed words (maximum 31992 bytes).
; Assemble once: no multiplication in the rectangle loop.
RestoreLineOffsets:
lineOffset set 0
        rept 200
        dc.w lineOffset
lineOffset set lineOffset+160
        endr

; cdecl: src,dst,rects,count,cache. Cache: src/dst base (8 bytes), then
; 22-byte entries: original rectangle (8), src (4), dst (4), Yinc/Xcount/Ycount.
; Rebuild only changed entries; a base-address change invalidates all entries.
PrepareRestoreRectsASM:
_PrepareRestoreRectsASM:
        movem.l d2-d4/a2-a5,-(sp)
        movea.l 32(sp),a2
        movea.l 36(sp),a3
        movea.l 40(sp),a0
        move.l  44(sp),d2
        beq.s   .done
        movea.l 48(sp),a1
        moveq   #0,d3
        cmpa.l  (a1),a2
        bne.s   .basesChanged
        cmpa.l  4(a1),a3
        beq.s   .basesReady
.basesChanged:
        moveq   #1,d3
.basesReady:
        move.l  a2,(a1)+
        move.l  a3,(a1)+
        lea     RestoreLineOffsets(pc),a5
        subq.w  #1,d2
.rect:
        tst.w   d3
        bne.s   .prepare
        move.l  (a0),d0
        cmp.l   (a1),d0
        bne.s   .prepare
        move.l  4(a0),d0
        cmp.l   4(a1),d0
        bne.s   .prepare
        addq.l  #8,a0
        lea     22(a1),a1
        bra.s   .next
.prepare:
        move.l  (a0)+,(a1)+
        move.l  (a0)+,(a1)+
        move.w  -8(a1),d1
        lsr.w   #1,d1
        move.w  -6(a1),d0
        add.w   d0,d0
        add.w   (a5,d0.w),d1
        move.w  -4(a1),d4
        move.w  -2(a1),d0
        movea.l a2,a4
        adda.w  d1,a4
        move.l  a4,(a1)+
        movea.l a3,a4
        adda.w  d1,a4
        move.l  a4,(a1)+
        lsr.w   #1,d4
        move.w  #162,d1
        sub.w   d4,d1
        move.w  d1,(a1)+
        lsr.w   #1,d4
        move.w  d4,(a1)+
        move.w  d0,(a1)+
.next:
        dbra    d2,.rect
.done:
        movem.l (sp)+,d2-d4/a2-a5
        rts

; cdecl: entries,count. The blit loop only loads precomputed register values.
RestorePreparedASM:
_RestorePreparedASM:
        move.l  d2,-(sp)
        movea.l 8(sp),a0
        move.l  12(sp),d2
        beq.s   .done
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
        addq.l  #8,a0
        move.l  (a0)+,4(a1)
        move.l  (a0)+,18(a1)
        move.w  (a0)+,d0
        move.w  d0,2(a1)
        move.w  d0,16(a1)
        move.w  (a0)+,22(a1)
        move.w  (a0)+,24(a1)
        move.b  #$c0,28(a1)
.busy:
        btst    #7,28(a1)
        bne.s   .busy
        dbra    d2,.rect
.done:
        move.l  (sp)+,d2
        rts
