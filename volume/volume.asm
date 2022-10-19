; volume display demo for kim-1, by g.dandridge
;
; vim syntax asm_ca65 (https://github.com/maxbane/vim-asm_ca65)
; for vasm6502_oldstyle assembler (http://sun.hasenbraten.de/vasm/)
;
; simple demo of a volume meter display, outputs to 7 segment display
; press key 3 to increase display
; press key 0 to decrease display

; setup pointers to kim-1 routines and registers

getkey          = $1F6A         ; getkey, address to scan key routine in kim-1 monitor
sad             = $1740         ; 6530-002, side b data, used to set segments on 7 segment display
padd            = $1741         ; 6530-002, port a data direction, 8 bits, 1=output, 0=input
sbd             = $1742         ; 6530-002, side a data, used to locate character position on 7 segment display

; setup zero page pointers

display_top	= $16		; top of display ram+1 location
display_bottom  = $0F		; bottom of display ram-1 location
delay_disp	= $17		; display delay variable
display_speed	= $18		; display speed variable
volume_level	= $19		; volume level variable

  .org $0200

  cld				; clear decimal mode, required for getkey kim-1 routine
  ldx #$FA			; load -6 in x, used as offset pointer for display ram

seed:
  lda #$00			; load accumulator with zero
  sta display_top,x		; store it in display ram, 6 addresses zeroed via loop
  inx				; increment the x pointer for next memory address
  bmi seed			; is the pointer 0, no loop back to seed

start:
  lda #$00			; load accumulator with zero
  sta volume_level		; store it in volume level variable, set initial level to zero
  lda #$FF			; load accumulator with $FF
  sta delay_disp		; and store it in the delay display variable, used to slow execution in wait loop

slow:
  lda #$09			; load accumulator with $09, smaller=faster, larger=slower
  sta display_speed		; store it in display speed variable, controls update speed of display

light:
  lda #%01111111		; load bits to control data direction of port B on 6530-002, 0=input, 1=output
  sta padd			; store in port a data direction register, allows output to 7 segment display
  ldy #$08			; load y with $08 to select leftmost character position 7 segment display
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
  lda #%00000000		; load zero into accumulator, for port a direction data, 0=input
  sta padd			; and store into port a data direction register, set all lines to inputs
  jsr getkey			; get the key being pressed by calling getkey from the kim-1 monitor rom
  cmp #$00			; compare with key 0
  beq down			; yes is key 0, down pressed, jump to down
  cmp #$03			; compare with key 3
  beq up			; yes is key 3, up pressed, jump to up
  jmp slow			; no key pressed, so loop back and redraw display all over

up:
  inc volume_level		; increment the volume level variable
  lda volume_level		; and load it into the accumulator
  cmp #$07			; compare the volume level with 7
  bne set			; no it not 7, so branch to set, set volume level into display ram
  lda #$06			; yes it was 7, prevent overflow and put it back to 6
  sta volume_level		; store 6 into volume level variable
  jmp set			; jump to set, set volume level into display ram

down:
  dec volume_level		; decrement the volume level variable
  bpl set			; is it positive, yes so branch to set, set volume level into display ram
  lda #$00			; no it was negative, prevent underflow and put it back to zero
  sta volume_level		; store zero into volume level variable

set:
  ldx #$FA			; load -6 in x, used as offset pointer for display ram

loop1:
  lda #$00			; load accumulator with zero
  sta display_top,x		; store it in display ram, 6 addresses zeroed via loop
  inx				; increment the x pointer for next memory address
  bmi loop1			; is the pointer 0, no loop back to loop1
  ldx volume_level		; load x register with value of volume level, used as offset to set volume in display ram

loop2:
  cpx #$00			; is the volume offset zero yet
  beq slow			; yes, so just go back and redraw the display
  lda #$40			; load accumulator with $40, will be used to light middle segment on 7 segment display
  sta display_bottom,x		; store into display ram offset by x, volume level offset
  dex				; decrement x register, reduce the volume level offset
  jmp loop2			; jump back to loop2, keep filling display ram
