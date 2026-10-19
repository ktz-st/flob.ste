        export CopyDataCPU
        export ClearDataCPU
        export CopyRowsCPU
        export CopyFlipRowsCPU
        export MirrorPlayfieldCPU
        export ClearRowsCPU
        export RestoreRectsCPU
        export DrawSpriteCPU
        export BuildFlobOpacityCPU
        export QueueSlimesCPU

; A0: packed slime queue descriptor (six pointers, five words, two bytes).
; Return appended count in D0. Active collision frames update even if clipped
; or the queue is full; unused queue fields retain QueueGeneratedSprite semantics.
QueueSlimesCPU:
        movem.l d2-d7/a2-a6,-(sp)
        move.l  (a0),a1
        move.l  4(a0),a2
        move.l  8(a0),a3
        move.l  12(a0),a4
        move.l  16(a0),a5
        move.w  24(a0),d5
        move.w  30(a0),d3
        move.w  32(a0),d4
        moveq   #0,d0
        moveq   #0,d2
.loop:
        moveq   #0,d1
        move.b  (a1)+,d1
        beq.s   .next
        move.l  a4,a6
        move.b  34(a0),d6
        btst    #0,d2
        beq.s   .frame
        move.l  a5,a6
        move.b  35(a0),d6
.frame:
        move.b  d6,(a2)
        tst.w   d5
        beq.s   .next
        ; All current assets use 2x logical X; retain the descriptor contract.
        cmpi.w  #2,26(a0)
        bne.s   .scale
        add.w   d1,d1
        bra.s   .position
.scale:
        mulu.w  26(a0),d1
.position:
        add.w   28(a0),d1
        bmi.s   .next
        tst.w   d3
        bmi.s   .next
        move.w  d1,(a3)
        move.w  d3,2(a3)
        move.l  (a6),4(a3)
        move.l  a6,8(a3)
        move.l  20(a0),12(a3)
        move.b  d2,21(a3)
        lea     32(a3),a3
        subq.w  #1,d5
        addq.l  #1,d0
.next:
        addq.l  #1,a2
        add.w   d4,d3
        addq.w  #1,d2
        cmpi.w  #20,d2
        bne.s   .loop
        movem.l (sp)+,d2-d7/a2-a6
        rts

; FPC register ABI: pointers A0/A1, integer D0/D1.
; CPU-only kernels. MOVEM block transfers follow the GodLib/AGT approach;
; adapters use Flob's explicit masks, 160-byte stride and dirty rectangles.

; A0=source, A1=destination, D0=byte count; non-overlapping, even addresses.
CopyDataCPU:
        movem.l d2-d7,-(sp)
        move.l  d0,d7
        lsr.l   #5,d7
        beq.s   .tail
        subq.l  #1,d7
.block:
        movem.l (a0)+,d1-d6
        movem.l d1-d6,(a1)
        lea     24(a1),a1
        move.l  (a0)+,(a1)+
        move.l  (a0)+,(a1)+
        dbra    d7,.block
.tail:
        andi.l  #31,d0
        move.l  d0,d7
        lsr.w   #2,d7
        beq.s   .bytes
        subq.w  #1,d7
.long:
        move.l  (a0)+,(a1)+
        dbra    d7,.long
.bytes:
        andi.w  #3,d0
        beq.s   .done
        subq.w  #1,d0
.byte:
        move.b  (a0)+,(a1)+
        dbra    d0,.byte
.done:
        movem.l (sp)+,d2-d7
        rts

; A0=destination, D0=byte count; even address.
ClearDataCPU:
        movem.l d2-d7/a1-a2,-(sp)
        moveq   #0,d1
        moveq   #0,d2
        moveq   #0,d3
        moveq   #0,d4
        moveq   #0,d5
        moveq   #0,d6
        movea.l d1,a1
        movea.l d1,a2
        move.l  d0,d7
        adda.l  d0,a0
        btst    #0,d0
        beq.s   .aligned
        clr.b   -(a0)
        subq.l  #1,d0
.aligned:
        move.l  d0,d7
        lsr.l   #5,d7
        beq.s   .tail
        subq.l  #1,d7
.block:
        movem.l d1-d6/a1-a2,-(a0)
        dbra    d7,.block
.tail:
        andi.l  #31,d0
        move.l  d0,d7
        lsr.w   #2,d7
        beq.s   .bytes
        subq.w  #1,d7
.long:
        move.l  d1,-(a0)
        dbra    d7,.long
.bytes:
        andi.w  #3,d0
        beq.s   .done
        subq.w  #1,d0
.byte:
        move.b  d1,-(a0)
        dbra    d0,.byte
.done:
        movem.l (sp)+,d2-d7/a1-a2
        rts

; A0=TCpuRows; fixed 160-byte rows, contiguous destination, variable source stride.
CopyFlipRowsCPU:
        movem.l d2-d7/a2-a3,-(sp)
        moveq   #0,d0
        move.w  10(a0),d0
        beq.s   .done
        movea.l d0,a2
        moveq   #0,d0
        move.w  12(a0),d0
        subi.w  #160,d0
        movea.l d0,a3
        movea.l 4(a0),a1
        movea.l (a0),a0
.row:
        rept    5
        movem.l (a0)+,d0-d7
        movem.l d0-d7,(a1)
        lea     32(a1),a1
        endr
        adda.l  a3,a0
        subq.l  #1,a2
        move.l  a2,d0
        bne.s   .row
.done:
        movem.l (sp)+,d2-d7/a2-a3
        rts

; A0=top row, A1=bottom row, D0=pair count; exchange whole 160-byte rows.
MirrorPlayfieldCPU:
        movem.l d2-d7/a2,-(sp)
        tst.l   d0
        beq     .done
        movea.l d0,a2
.pair:
        rept    10
        movem.l (a0)+,d0-d3
        movem.l (a1)+,d4-d7
        movem.l d4-d7,-16(a0)
        movem.l d0-d3,-16(a1)
        endr
        lea     -320(a1),a1
        subq.l  #1,a2
        move.l  a2,d0
        bne     .pair
.done:
        movem.l (sp)+,d2-d7/a2
        rts

; A0=TCpuRows: src.l,dst.l,rowBytes.w,height.w,srcStride.w,dstStride.w.
; Row sizes are multiples of 8 bytes (16 screen pixels).
CopyRowsCPU:
        movem.l d2-d7/a2-a4,-(sp)
        movea.l 4(a0),a2
        move.w  8(a0),d2
        move.w  10(a0),d3
        move.w  12(a0),d4
        move.w  14(a0),d5
        movea.l (a0),a1
        sub.w   d2,d4
        sub.w   d2,d5
        bsr.s   CopyRowsCore
        movem.l (sp)+,d2-d7/a2-a4
        rts

; A1=source,A2=destination,D2=rowBytes,D3=height,D4/D5=line skips.
CopyRowsCore:
        tst.w   d2
        beq.s   .done
        tst.w   d3
        beq.s   .done
        subq.w  #1,d3
.row:
        move.w  d2,d6
        lsr.w   #4,d6
        beq.s   .tail
        subq.w  #1,d6
.block:
        movem.l (a1)+,d0-d1/a3-a4
        movem.l d0-d1/a3-a4,(a2)
        lea     16(a2),a2
        dbra    d6,.block
.tail:
        btst    #3,d2
        beq.s   .next
        move.l  (a1)+,(a2)+
        move.l  (a1)+,(a2)+
.next:
        adda.w  d4,a1
        adda.w  d5,a2
        dbra    d3,.row
.done:
        rts

; Same descriptor; only dst,rowBytes,height,dstStride used.
ClearRowsCPU:
        movem.l d2-d4/a2,-(sp)
        movea.l 4(a0),a1
        move.w  8(a0),d2
        move.w  10(a0),d3
        move.w  14(a0),d4
        sub.w   d2,d4
        tst.w   d2
        beq.s   .done
        tst.w   d3
        beq.s   .done
        moveq   #0,d0
        moveq   #0,d1
        movea.l d0,a2
        subq.w  #1,d3
.row:
        move.w  d2,d1
        lsr.w   #3,d1
        subq.w  #1,d1
.block:
        move.l  d0,(a1)+
        move.l  d0,(a1)+
        dbra    d1,.block
        adda.w  d4,a1
        dbra    d3,.row
.done:
        movem.l (sp)+,d2-d4/a2
        rts

; A0=TCpuRestore: src.l,dst.l,rects.l,count.w.
; Existing 8-byte x,y,w,h records, clipped and aligned to 16px.
RestoreRectsCPU:
        movem.l d2-d7/a2-a6,-(sp)
        movea.l a0,a6
        movea.l 8(a6),a5
        move.w  12(a6),d7
        beq.s   .done
        subq.w  #1,d7
.rect:
        move.w  (a5)+,d0
        lsr.w   #1,d0
        move.w  (a5)+,d1
        add.w   d1,d1
        add.w   CpuLineOffsets(pc,d1.w),d0
        movea.l (a6),a1
        adda.w  d0,a1
        movea.l 4(a6),a2
        adda.w  d0,a2
        move.w  (a5)+,d2
        lsr.w   #1,d2
        move.w  (a5)+,d3
        move.w  #160,d4
        sub.w   d2,d4
        move.w  d4,d5
        bsr     CopyRowsCore
        dbra    d7,.rect
.done:
        movem.l (sp)+,d2-d7/a2-a6
        rts

CpuLineOffsets:
lineOffset set 0
        rept 200
        dc.w lineOffset
lineOffset set lineOffset+160
        endr

; A0=destination,A1=TCpuSprite:
; gfx.l,mask.l,opacity.l,height.w,srcWords.w,dstWords.w,shift.w.
; mask uses 1=transparent; optional opacity is already shifted, two words/row.
; Like AGT SVMC, shift during drawing. Unlike auto-key masking, explicit masks
; also support opaque zero and Flob's foreground occlusion.
DrawSpriteCPU:
        cmpi.w  #1,14(a1)
        beq     DrawNarrowSpriteCPU
        movem.l d2-d7/a2-a6,-(sp)
        movea.l a1,a6
        movea.l a0,a5
        movea.l (a6),a2
        movea.l 4(a6),a3
        movea.l 8(a6),a4
        move.w  12(a6),d7
        beq     .done
        subq.w  #1,d7
        move.w  18(a6),d4
.row:
        moveq   #0,d6
.group:
        cmpa.l  #0,a4
        beq.s   .mask
        move.w  d6,d0
        add.w   d0,d0
        move.w  (a4,d0.w),d5
        bra.s   .opacityReady
.mask:
        moveq   #0,d5
        cmp.w   14(a6),d6
        bcc.s   .maskPrev
        move.w  d6,d0
        add.w   d0,d0
        move.w  (a3,d0.w),d5
        not.w   d5
.maskPrev:
        tst.w   d6
        beq.s   .maskShift
        move.w  d6,d0
        subq.w  #1,d0
        cmp.w   14(a6),d0
        bcc.s   .maskShift
        add.w   d0,d0
        moveq   #0,d1
        move.w  (a3,d0.w),d1
        not.w   d1
        swap    d1
        or.l    d1,d5
.maskShift:
        lsr.l   d4,d5
.opacityReady:
        move.w  d6,d2
        lsl.w   #3,d2
        move.w  d5,d0
        not.w   d0
        ; Duplicate the opacity over each pair of planes.
        move.w  d0,d1
        swap    d0
        move.w  d1,d0
        and.l   d0,(a5)
        and.l   d0,4(a5)
        moveq   #3,d3
.plane:
        moveq   #0,d0
        cmp.w   14(a6),d6
        bcc.s   .gfxPrev
        move.w  (a2,d2.w),d0
.gfxPrev:
        tst.w   d6
        beq.s   .gfxShift
        move.w  d6,d1
        subq.w  #1,d1
        cmp.w   14(a6),d1
        bcc.s   .gfxShift
        moveq   #0,d1
        move.w  -8(a2,d2.w),d1
        swap    d1
        or.l    d1,d0
.gfxShift:
        lsr.l   d4,d0
        and.w   d5,d0
        or.w    d0,(a5)+
        addq.w  #2,d2
        dbra    d3,.plane
        addq.w  #1,d6
        cmp.w   16(a6),d6
        bcs     .group
        move.w  16(a6),d0
        lsl.w   #3,d0
        neg.w   d0
        add.w   #160,d0
        adda.w  d0,a5
        move.w  14(a6),d0
        add.w   d0,d0
        adda.w  d0,a3
        lsl.w   #2,d0
        adda.w  d0,a2
        cmpa.l  #0,a4
        beq.s   .next
        addq.l  #4,a4
.next:
        dbra    d7,.row
.done:
        movem.l (sp)+,d2-d7/a2-a6
        rts

; One source word: rotate once per plane to obtain both destination words.
; D5 has left opacity in its low word, right opacity in its high word.
DrawNarrowSpriteCPU:
        movem.l d2-d7/a2-a5,-(sp)
        movea.l a0,a5
        movea.l (a1),a2
        movea.l 4(a1),a3
        movea.l 8(a1),a4
        move.w  12(a1),d7
        beq     .done
        subq.w  #1,d7
        move.w  16(a1),d6
        move.w  18(a1),d4
.row:
        cmpa.l  #0,a4
        beq.s   .mask
        move.l  (a4)+,d5
        swap    d5
        bra.s   .ready
.mask:
        moveq   #0,d5
        move.w  (a3),d5
        not.w   d5
        ror.l   d4,d5
.ready:
        tst.l   d5
        beq     .next
        move.w  d5,d0
        not.w   d0
        move.w  d0,d1
        swap    d0
        move.w  d1,d0
        and.l   d0,(a5)
        and.l   d0,4(a5)
        cmpi.w  #1,d6
        beq.s   .one
        move.l  d5,d0
        swap    d0
        not.w   d0
        move.w  d0,d1
        swap    d0
        move.w  d1,d0
        and.l   d0,8(a5)
        and.l   d0,12(a5)
planeOffset set 0
        rept 4
        moveq   #0,d0
        move.w  planeOffset(a2),d0
        ror.l   d4,d0
        and.l   d5,d0
        or.w    d0,planeOffset(a5)
        swap    d0
        or.w    d0,planeOffset+8(a5)
planeOffset set planeOffset+2
        endr
        bra.s   .next
.one:
planeOffset set 0
        rept 4
        move.w  planeOffset(a2),d0
        lsr.w   d4,d0
        and.w   d5,d0
        or.w    d0,planeOffset(a5)
planeOffset set planeOffset+2
        endr
.next:
        addq.l  #8,a2
        addq.l  #2,a3
        lea     160(a5),a5
        dbra    d7,.row
.done:
        movem.l (sp)+,d2-d7/a2-a5
        rts

; A0=TCpuOcclusion: source/destination/background pointers, then words
; height, destination words (1/2), first visible row, end visible row.
; Preserve both EMS words; clip only where the row intersects the playfield.
BuildFlobOpacityCPU:
        movem.l d2-d6/a2,-(sp)
        movea.l 4(a0),a1
        movea.l 8(a0),a2
        move.w  12(a0),d2
        beq     .done
        move.w  14(a0),d3
        move.w  16(a0),d4
        move.w  18(a0),d5
        movea.l (a0),a0
        moveq   #0,d6
        subq.w  #1,d2
.row:
        move.l  (a0)+,(a1)
        cmp.w   d4,d6
        bcs.s   .next
        cmp.w   d5,d6
        bcc.s   .next
        move.w  (a2),d0
        move.w  2(a2),d1
        eor.w   d1,d0
        move.w  4(a2),d1
        or.w    6(a2),d1
        not.w   d1
        and.w   d1,d0
        not.w   d0
        and.w   d0,(a1)
        cmpi.w  #1,d3
        beq.s   .next
        move.w  8(a2),d0
        move.w  10(a2),d1
        eor.w   d1,d0
        move.w  12(a2),d1
        or.w    14(a2),d1
        not.w   d1
        and.w   d1,d0
        not.w   d0
        and.w   d0,2(a1)
.next:
        addq.l  #4,a1
        lea     160(a2),a2
        addq.w  #1,d6
        dbra    d2,.row
.done:
        movem.l (sp)+,d2-d6/a2
        rts
