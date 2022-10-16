; spacegame for kim-1, by g.dandridge
;
; vim syntax asm_ca65 (https://github.com/maxbane/vim-asm_ca65)
; for vasm6502_oldstyle assembler (http://sun.hasenbraten.de/vasm/)
;
; this game is a horizontal scroller that uses kim-1's inbuilt 7 segment display
; fly your spaceship while avoiding the oncoming asteroids 
; key 3 for down, key 7 for up
; game halts if you die, reset to restart
;
; requires a map to be loaded into zero page, see gamemap.asm
;

; setup pointers to kim routines and registers

getkey 		= $1F6A		; getkey, address to scan key routine in kim-1 monitor
sad		= $1740		; 6530-002, side b data, used to set segments on 7 segment display
padd		= $1741		; 6530-002, port a data direction, 8 bits, 1=output, 0=input
sbd		= $1742         ; 6530-002, side a data, used to locate character position on 7 segment display

; setup zero page pointers

display_bottom	= $10		; bottom of display ram location
display_top	= $16		; top of display ram+1 location
delay_disp	= $17		; display delay variable 
game_speed	= $18		; game speed variable
player_pos	= $19		; player position variable
map_loc		= $1A		; map location offset variable
enemy_pos	= $1B		; enemy position variable
enemy_char	= $1C		; enemy character variable
map		= $100		; start location of map in ram

  .org $0200

  cld				; clear decimal mode, required for getkey kim-1 routine
  ldx #$FA			; load -6 in x, used as offset pointer for display ram

seed:
  lda #$00			; load accumulator with zero
  sta display_top,x		; store it in display ram, 6 addresses zeroed via loop
  inx				; increment the x pointer for next memory address
  bmi seed			; is the pointer 0, no loop back to seed
  lda #$40			; load $40 into accumulator, data for 7 segment display of player character
  sta display_bottom		; store it into the start leftmost position of display ram
  lda #$FF			; load $ff into accumulator
  sta delay_disp		; and store it in the delay display variable, used to slow execution in show loop
  lda #$02			; load $02 into the accumulator
  sta player_pos		; and store in the player position variable, player vertical start position (2=middle)
  lda #$00			; load $00 into accumulator
  sta map_loc			; and store in map location offset variable
  lda #$05			; load $05 into accumulator
  sta enemy_pos			; and store it in the enemy position variable, enemy horizontal start position (5=rightmost)

speed:
  lda  #$0A			; load game speed into accumulator, default $0A, smaller=faster, larger=slower
  sta game_speed		; store in game speed variable

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
  dec game_speed		; decrement the speed variable
  bne light			; did it reach zero, no loop back to light and redraw display all over again
  lda #%00000000		; load zero into accumulator, for port a direction data, 0=input
  sta padd			; and store into port a data direction register, set all lines to inputs
  jsr getkey			; get the key being pressed by calling getkey from the kim-1 monitor rom
  cmp #03			; compare with key 3
  bne key			; if it's not key 3, then try to match another key, jump to key
  jmp down			; key 3 for down was pressed, jump to down

key:		
  cmp #07			; compare with key 7
  bne clear			; if it's not key 7, then no valid keys pressed, jump to clear
  jmp up			; key 7 for up was pressed, jump to up

clear:
  ldx #$FA			; load -6 in x, used as offset pointer for display ram

cloop:
  lda #$00			; load zero into the accumulator
  sta display_top,x		; fill the display ram with zeros, 6 addresses zeroed via loop
  inx				; increment the x pointer for next memory address 
  bmi cloop			; is the pointer 0, no loop back to cloop

pos1:
  lda player_pos		; load player position variable into accumulator
  cmp #01			; check if it's a 1, top position
  bne pos2			; it's not 1, so jump to pos2
  lda #$01			; load accumulator with a $01, to select top segment of 7 segment display
  sta display_bottom		; and store it in the bottom of display ram, leftmost position 
  jmp enemy			; jump to enemy

pos2:
  lda player_pos		; load player position variable into accumulator
  cmp #$02			; check if it's a 2, middle position
  bne pos3			; it's not 2, so jump to pos3
  lda #$40			; load accumulator with a $40, to select middle segment of 7 segment display
  sta display_bottom		; and store it in the bottom of display ram, leftmost position
  jmp enemy			; jump to enemy

pos3:
  lda #$08			; load accumulator with $08, to select bottom segment of 7 segment display
  sta display_bottom		; and store it in the bottom of display ram, leftmost position

enemy:
  lda enemy_pos			; load enemy position variable into accumulator
  cmp #$05			; compare it with $05, enemy is at rightmost position, so is a new enemy
  bne endraw			; it's not 5, enemy is not at rightmost position, so jump to endraw
  ldx map_loc			; load map location offset variable x register
  lda map,x			; load accumulator with map character stored in map ram, offset by x register
  sta enemy_char		; and store it in enemy character variable, sets enemy vertical position type

endraw:
  ldx enemy_pos			; load the enemy position variable into accumulator			
  lda enemy_char		; load the enemy character variable into the accumulator
  eor display_bottom,x		; overlay enemy character against display ram using eor
  sta display_bottom,x		; store the result in the display ram

enmove:
  dec enemy_pos			; decrement the enemy position variable
  bmi enrst			; is it negative, yes enemy has reached leftmost position, so jump to enrst
  jmp speed			; loop back for next round, jump to speed

enrst:
  jsr chkhit			; jump to chkhit subroutine, to check if enemy has hit the player
  lda #$05			; load $05 into accumulator
  sta enemy_pos			; store into enemy position variable, puts enemy back to the rightmost position
  inc map_loc			; increment map location offset variable, moves forward in the map 
  ldx map_loc			; load map location offset variable x register
  lda map,x			; load accumulator with map character stored in map ram, offset by x register
  cmp #$FF			; compare it with $FF, checking for end of map marker
  bne norst			; it's not $FF, we're not at the end of the map, jump to norst
  lda #$00			; load $00 into accumulator
  sta map_loc			; store it into map location offset variable, restarts the map

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
  lda display_bottom		; load the contents of the bottom of display ram into accumulator
  cmp #$00			; is it zero, will be so if enemy character and player position has eor'ed to zero
  beq dead			; yes it's zero, player is dead, jump to dead
  rts				; exit chkhit

dead:
  jmp dead			; player is dead, halt

