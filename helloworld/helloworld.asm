; hello world demo for kim-1, by g.dandridge
;
; vim syntax asm_ca65 (https://github.com/maxbane/vim-asm_ca65)
; for vasm6502_oldstyle assembler (http://sun.hasenbraten.de/vasm/)
;
; very simple hello world print loop, outputs over the TTY interface

; setup pointers to kim-1 monitor functions

GetCh		= $1E5A			; address of getch routine in kim-1 monitor, gets character from tty into accumulator
					; note, getch not used in this demo but included for completeness 
OutCh		= $1EA0			; address of outch routine in kim-1 monitor, puts accumulator character out via the tty


; setup zero page pointers

PrintPtr	= $00


  .org $0200


start:

  jsr sub_PrintString			; call print string subroutine, to print hello world string
  .byte "Hello world",$0D,$0A,$00
  jmp start				; loop back to start

sub_PrintString:
; put the string following in-line until a NULL out to the console
; taken from http://www.6502.org/source/io/primm.htm

  pla					; get the low part of return address (data start address)
  sta PrintPtr				; store in print pointer
  pla					; get the high part of the return address (data start address)
  sta PrintPtr+1			; store in print pointer +1

sub_ps1:
  ldy #1				; fix that we're pointing one location short
  lda (PrintPtr),y			; get the next string character
  inc PrintPtr				; update the pointer
  bne sub_ps2				; if not, we're pointing to next character
  inc PrintPtr+1			; account for page crossing

sub_ps2:
  ora #0				; set flags according to contents of accumulator
  beq sub_ps3				; don't print the final NULL
  jsr OutCh				; write it out
  jmp sub_ps1				; back around

sub_ps3:
  inc PrintPtr
  bne sub_ps4
  inc PrintPtr+1			; account for page crossing

sub_ps4:
  jmp (PrintPtr)			; return to byte following final NULL
