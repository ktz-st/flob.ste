        export DrawSpriteIMS
        export _DrawSpriteIMS

; cdecl, all arguments 32-bit:
; mask, gfx, dst, height, countX, skew, endmask1, endmask2, endmask3.
; Uses the existing separate mask / interleaved four-plane colour layout.
DrawSpriteIMS:
_DrawSpriteIMS:
        movem.l d2-d5/a2-a4,-(sp)
        movea.l 32(sp),a0
        movea.l 36(sp),a1
        movea.l 40(sp),a2
        move.l  44(sp),d2
        move.l  48(sp),d3
        move.l  52(sp),d0
        move.l  56(sp),d4
        move.l  60(sp),d5
        move.l  64(sp),d1
        lea     $ffff8a20.w,a3
.wait:
        btst    #7,28(a3)
        bne.s   .wait
        move.w  d3,22(a3)
        lsl.w   #3,d3
        neg.w   d3
        add.w   #168,d3
        move.w  #8,14(a3)
        move.w  d3,16(a3)
        move.w  d4,8(a3)
        move.w  d5,10(a3)
        move.w  d1,12(a3)
        move.b  d0,29(a3)
        move.w  #$0201,26(a3)
        move.w  #2,(a3)
        move.w  #2,2(a3)
        moveq   #3,d4
        move.b  #$c0,d5
        movea.l a2,a4
.mask:
        move.l  a0,4(a3)
        move.l  a4,18(a3)
        move.w  d2,24(a3)
        move.b  d5,28(a3)
.maskwait:
        btst    #7,28(a3)
        bne.s   .maskwait
        addq.l  #2,a4
        dbra    d4,.mask
        move.b  #7,27(a3)
        move.w  #8,(a3)
        move.w  #8,2(a3)
        moveq   #3,d4
.gfx:
        move.l  a1,4(a3)
        move.l  a2,18(a3)
        move.w  d2,24(a3)
        move.b  d5,28(a3)
.gfxwait:
        btst    #7,28(a3)
        bne.s   .gfxwait
        addq.l  #2,a1
        addq.l  #2,a2
        dbra    d4,.gfx
        movem.l (sp)+,d2-d5/a2-a4
        rts
