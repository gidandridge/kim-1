; game map for spacegame for kim-1, by g.dandridge
;
; vim syntax asm_ca65 (https://github.com/maxbane/vim-asm_ca65)
; for vasm6502_oldstyle assembler (http://sun.hasenbraten.de/vasm/)
;

  .org $0100

; map data, $01=top, $40=middle, $08=bottom, $FF=end

  .byte $40,$01,$08,$08,$40,$01,$40,$08,$01,$40,$01,$08,$40,$40,$01,$08,$01,$08,$40,$01,$FF
