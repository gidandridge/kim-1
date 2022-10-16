; volume display demo for kim-1, by g.dandridge
;
; vim syntax asm_ca65 (https://github.com/maxbane/vim-asm_ca65)
; for vasm6502_oldstyle assembler (http://sun.hasenbraten.de/vasm/)
;

; setup pointers to kim routines and registers

keyin		= $1F40		;
getkey		= $1F6A		;


; setup zero page pointers

  .org $0200

  ldx #$FA

seed:
  lda #$00
  sta $16,X
  inx
  bmi seed

start:
  lda #$00
  sta $19

slow:
  lda #$09
  sta $18

light:
  lda #$7F
  sta $1741
  ldy #$9
  ldx #$FA

show:
  lda $16,X
  sta $1740
  sty $1742

wait:
  dec $17
  bne wait
  iny
  iny
  inx
  bmi show
  dec $18
  bne light
  jsr keyin
  jsr getkey
  cmp #$00
  beq down
  cmp #$03
  beq up
  jmp slow

up:
  inc $19
  lda $19
  cmp #$07
  bne set
  lda #$06
  sta $19
  jmp set

down:
  dec $19
  bpl set
  lda #$00
  sta $19

set:
  ldx #$FA

loop1:
  lda #$00
  sta $16,X
  inx
  bmi loop1
  ldx $19

loop2:
  cpx #$00
  beq slow
  lda #$40
  sta $0F,X
  dex
  jmp loop2
