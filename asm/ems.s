        export DrawSpriteEMS
        export _DrawSpriteEMS

; EndMask sprite, <=16 source pixels, four interleaved planes.
; cdecl: gfx, dst, preshifted mask pairs, height, destination words, skew.
; All arguments are 32 bits. No generated/preshifted colour data required.
; X traverses words of one plane, Y traverses the four planes of one row.
DrawSpriteEMS:
_DrawSpriteEMS:
        movem.l d2-d4/a2-a3,-(sp)
        movea.l 24(sp),a0
        movea.l 28(sp),a1
        movea.l 32(sp),a2
        move.l  36(sp),d2
        move.l  40(sp),d3
        move.l  44(sp),d0
        lea     $ffff8a20.w,a3
.wait:
        btst    #7,28(a3)
        bne.s   .wait
        move.w  #8,(a3)
        move.w  #2,2(a3)
        move.l  a0,4(a3)
        move.w  #$ffff,10(a3)
        move.w  #8,14(a3)
        move.w  d3,22(a3)
        subq.w  #1,d3
        lsl.w   #3,d3
        neg.w   d3
        addq.w  #2,d3
        move.w  d3,16(a3)
        move.w  #$0203,26(a3)
        move.b  d0,29(a3)
        moveq   #4,d4
        subq.w  #1,d2
.row:
        move.w  (a2)+,8(a3)
        move.w  (a2)+,12(a3)
        move.l  a1,18(a3)
        move.w  d4,24(a3)
        move.b  #$c0,28(a3)
.busy:
        btst    #7,28(a3)
        bne.s   .busy
        lea     160(a1),a1
        dbra    d2,.row
        movem.l (sp)+,d2-d4/a2-a3
        rts
