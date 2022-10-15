; spacegame for kim-1, by g.dandridge
;
; vim syntax asm_ca65 (https://github.com/maxbane/vim-asm_ca65)
; for vasm6502_oldstyle assembler (http://sun.hasenbraten.de/vasm/)
;

; setup pointers to kim routines and registers

keyin		= $1F40		; key read call address in kim-1 monitor
getkey 		= $1F6A		; get key, call address in kim-1 monitor
sad		= $1740		; 6530-002, side b data, used to set segments on hex display char's
padd		= $1741		; 6530-002, port a data direction, 8 bits, 1=output, 0=input
sbd		= $1742         ; 6530-002, side a data, used to locate char on hex disp ($08,$0A,$0C,$0E,$10,$12)
pbdd		= $1743		; 6530-002, port b data direction, 8 bits, 1-output, 0=input (not used in this code)

; setup zero page pointers

display_bottom	= $10		; bottom of diplay ram location
display_top	= $16		; top of display ram+1 location
delay_disp	= $17		; display delay variable 
game_speed	= $18		; game speed variable
player_pos	= $19		; player position variable
map_loc		= $1A		; map location offset variable
enemy_pos	= $1B		; enemy position variable
enemy_char	= $1C		; enemy char variable
map		= $100		; start location of map in ram

  .org $0200

  cld				; clear decimal mode, required for getkey kim-1 routine
  ldx #$FA			; load -6 in x, used as offset pointer for display ram

seed:
  lda #$00			; load accumulator with zero
  sta display_top,x		; store it in display ram, 6 addresses via loop
  inx				; increment the x pointer for next memory address
  bmi seed			; is the pointer 0, no loop back to seed
  lda #$40
  sta $10
  lda #$FF			; load $ff into accumulator
  sta delay_disp		; and store it in the display_delay variable, used to slow execution in show loop
  lda #$02			; load $02 into the accumulator
  sta $19			; and store in the player_pos variable, default player position (1=top, 2=middle, 3=bottom)
  lda #$00			; load $00 into accumulator
  sta $1A			; and store in map_loc variable, map location offset
  lda #$05			; load $05 into accumulator
  sta $1B			; and store it in the enemy_pos variable, enemy position (5=rightmost, 0=leftmost)

speed:
  lda  #$0A			; load game speed into accumulator, default $0A, make smaller for faster
  sta game_speed		; store in game speed variable

light:
  lda #%01111111		; load bits to control data direction of port B on 6530-002
  sta padd			; store in data direction register, allows output of hex display char data
  ldy #$08			; load y with $08 to select char's position on hex display
  ldx #$FA			; load -6 in x, used as offset pointer for display ram 

show:
  lda display_top,x		; load content of display ram, using x as pointer, into accumulator
  sta sad			; write it to the 6530-002 side a data, set the char's display segments to be displayed
  sty sbd			; place the char's position storedin x in side b data, selects char's position

wait:
  dec delay_disp		; decrement the display delay variable
  bne wait			; is the display delay variable zero, no then loop back to wait
  iny				; increment y
  iny				; and increment y again, moving it to point to next char's on hex display
  inx				; incement x, offset point for display ram, to next char in ram
  bmi show			; is x zero (end of display ram), no so go back and display next char
  dec game_speed		; decrement the speed variable
  bne light			; did it reach zero, no loop back to light and redraw display all over again
  jsr keyin			; open keyboard input channel by calling keyin from the kim-1 monitor rom
  jsr getkey			; get key being pressed by calling getkey from the kim-1 monitor rom
  cmp #03			; compare with key 3
  bne key			; if it's not key 3, then jump to key
  jmp down			; jump to down

key:		
  cmp #07			; compare with key 7
  bne clear			; if it's not key 7, then jump to clear
  jmp up			; jump to up

clear:
  ldx #$FA			; load -6 in x, used as offset pointer for display ram

cloop:
  lda #$00			; load zero into the accumulator
  sta display_top,x		; fill the display ram with zeros, 6 addresses via loop
  inx				; increment the x pointer for next memory address 
  bmi cloop			; is the pointer 0, no loop back to cloop

pos1:
  lda player_pos		; load player position variable into accumulator
  cmp #01			; check if it's a 1
  bne pos2			; it's not 1, so jump to pos2
  lda #$01			; load accumulator with a $01, to select top line of hex display
  sta display_bottom		; and store it in the bottom of display ram, leftmost position 
  jmp enemy			; jump to enemy

pos2:
  lda player_pos		; load player position variable into accumulator
  cmp #$02			; check if it's a 2
  bne pos3			; it's not 2, so jump to pos3
  lda #$40			; load accumulator with a $40, to select middle line of hex display
  sta display_bottom		; and store it in the bottom of display ram, leftmost position
  jmp enemy			; jump to enemy

pos3:
  lda #$08			; load accumulator with $08, to select bottom line of hex display
  sta display_bottom		; and store it in the bottom of display ram, leftmost position

enemy:
  lda enemy_pos			; load enemy position variable into accumulator
  cmp #$05			; compare it with $05
  bne endraw			; it's not 5, so jump to endraw
  ldx map_loc			; load map location offset variable x register
  lda map,x			; load accumulator with map char stored in map ram, offset by x register
  sta enemy_char		; and store it in enemy char variable

endraw:
  ldx enemy_pos			; load the enemy position variable into accumulator			
  lda enemy_char		; load the enemy character variable into the accumulator
  eor display_bottom,x		; overlay against display ram using eor
  sta display_bottom,x		; store the result in the display ram

enmove:
  dec enemy_pos			; decrement the enemy position variable
  bmi enrst			; is it negative, yes so jump to enrst
  jmp speed			; loop back for next round, jump to speed

enrst:
  jsr chkhit			; jump to chkhit subroutine
  lda #$05			; load $05 into accumulator
  sta enemy_pos			; store into enemy position variable, puts enemy back to the rightmost position
  inc map_loc			; increment map location offset variable, move forward in the map 
  ldx map_loc			; load map location offset variable x register
  lda map,x			; load accumulator with map char stored in map ram, offset by x register
  cmp #$FF			; compare it with $FF, checking for end of map marker
  bne norst			; it's not $FF, we're not at the end of the map, jump to norst
  lda #$00			; load $00 into accumulator
  sta map_loc			; store it into map location offset variable, restart the map

norst:
  jmp speed			; loop back for next round, jump to speed

up:
  lda player_pos		; load player position variable into accumulator
  cmp #$01			; compare it with $01, top position
  beq clear			; is it a 1, yes we're at the top, can't go up so jump back to clear
  dec player_pos		; decrement the player position variable, move up
  jmp clear			; jump back to clear

down:
  lda player_pos		; load player position variable into accumulator
  cmp #$03			; compare it with $03, bottom position
  beq clear			; is it a 3, yes we're at the bottom, can't go down so jump back to clear
  inc player_pos		; increment player position variable, move down
  jmp clear			; jump back to clear

chkhit:
  lda display_bottom		; load the contents of the bottom of diplay ram into accumulator
  cmp #$00			; is it zero, will be so if enemy characher and player position has eor'ed to zero
  beq dead			; yes it's zero, player is dead, jump to dead
  rts				; exit chkhit

dead:
  jmp dead			; player is dead, halt

