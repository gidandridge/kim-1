; rotate display demo for kim-1, by g.dandridge
;
; vim syntax asm_ca65 (https://github.com/maxbane/vim-asm_ca65)
; for vasm6502_oldstyle assembler (http://sun.hasenbraten.de/vasm/)
;
; simple demo that places rotating segments on the 7 segment display

; setup pointers to kim-1 routines and registers

sad             = $1740         ; 6530-002, side b data, used to set segments on 7 segment display
padd            = $1741         ; 6530-002, port a data direction, 8 bits, 1=output, 0=input
sbd             = $1742         ; 6530-002, side a data, used to locate character position on 7 segment display

; setup zero page pointers

display_top     = $16           ; top of display ram+1 location
delay_disp      = $17           ; display delay variable
display_speed   = $18           ; display speed variable

  .org $0200

  ldx #$FA                      ; load -6 in x, used as offset pointer for display ram

seed:
  lda #$01			; load accumulator with $01, will be to used to select top line on 7 segment display
  sta display_top,x		; store it in display ram, 6 addresses zeroed via loop
  inx				; increment the x pointer for next memory address
  bmi seed			; is the pointer 0, no loop back to seed
  lda #$FF			; load accumulator with $FF
  sta delay_disp		; and store it in the delay display variable, used to slow execution in wait loop

start:
  lda #$10			; load accumulator with $10, smaller=faster, larger=slower
  sta display_speed		; store it in display speed variable, controls update speed of display
  lda #%01111111		; load bits to control data direction of port B on 6530-002, 0=input, 1=output
  sta padd			; store in port a data direction register, allows output to 7 segment display

light:
  ldy #$8			; load y with $08 to select leftmost character position 7 segment display
  ldx #$FA			; load -6 in x, used as offset pointer for display ram

show:
  lda display_top,x		; load content of display ram, using x as pointer, into accumulator
  sta sad			; write it to the 6530-002 side a data, set the 7 segment display components to be displayed
  sty sbd			; place the characters position stored in x in side b data, selects characters position

wait:
  dec delay_disp		; decrement the display delay variable
  bne wait			; is the display delay variable zero, no then loop back to wait
  iny				; increment y
  iny				; and increment y again, moving it to point to next characters position on 7 segment display
  inx				; increment x, offset pointer for display ram, to next character in display ram
  bmi show			; is x zero (end of display ram), no so go back and display next character
  dec display_speed		; decrement the display speed variable
  bne light			; did it reach zero, no loop back to light and redraw display all over again
  ldx #$FA			; load -6 in x, used as offset pointer for display ram

roll:
  clc				; clear the carry bit, don't want to roll any carry bits
  rol display_top,x		; rotate left contents of display top, offset by x, 6 addresses rotated  via loop
  lda display_top,x		; load the contents of display top, offset by x, into accumulator
  cmp #$40			; check to see if contents of display top are $40, the last segment in the loop
  bne next			; no, it is not $40, so just jump to next
  lda #$01			; load accumulator with $01, used to reset back to first segment
  sta display_top,x		; store into display ram  offset by x, setting display back to first segment

next:
  inx				; increment x, move to next location in display ram
  bmi roll			; is x still negative, yes so loop back to roll, next display ram location
  jmp start			; all parts of display ram rotated, so start over
