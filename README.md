# KIM-1
Code for the KIM-1 microcomputer by MOS Technologies.

If you wish to know more about the KIM-1 then Hans Otten has produced an excellent online resource which can be found at http://retro.hansotten.nl/6502-sbc/kim-1-manuals-and-software/.

## Overview
Contained here is a collection of programs I've written for the KIM-1 microcomputer by MOS Technologies. The KIM-1 is a single board microcomputer that was introduced in 1975.

The programs here are presented in three formats:
- assembly language (asm)
- machine code (hex)
- paper tape (ptp)

### Assembly language (asm)
Full assembly language with comments is provided. You can compile these to machine code using a suitable cross compiler. I use the vasm assembler (http://sun.hasenbraten.de/vasm/) and am using a Linux development environment. I have found that vasm can be located in the repositories of most Linux distributions.

I typically compile the assembly language using the following command:
```
vasm6502_oldstyle -Fbin -dotdir input.6502 -o output.bin
```
This compiles to binary format enabling dot directives to be used in the source.

### Machine code (hex)
Human readable machine code is provided in hexadecimal format. Allowing you to read the code and key it directly into a KIM-1 using the KIM-1 key pad. To produce this file I use the hexdump command that is provided in most Linux distributions. 

Typically I use this command:
```
hexdump -C <source.bin> > <destination.hex>
```
Substituting <source.bin> for the name of a binary file containing the previously complied assembly language and <destination.hex> with the destination file name. I then edit the destination file removing the unneeded ASCII notation and also updating the address indexes to match the intended target location of the code in RAM.

### Paper tape (ptp)
Finally paper tape files are provided. These are ASCII files in the MOS Technologies paper tape format supported by the KIM-1. The KIM-1 can load these files over a suitable RS232 interface using the built in monitor ROM. Use the 'L' command and then send the file as ASCII. Note during transmission the KIM-1 will require a short delay after each character and slightly longer delay at the end of each line.

These files have been produced using the srecrod tools available in many Linux distributions. I used the following command:
```
srec_cat <input.bin> -binary -offset 0x200 -o <output.ptp> -MOS_Technologies
```
Substituting <input.bin> with a suitable binary formatted machine code file and <output.ptp> with the target name of for the new paper tape file.

Once created this can be sent to a KIM-1 over RS232. The KIM-1 needs to be given the 'L' command at the terminal. From Linux the file can then be sent with:
```
ascii-xfr -s -l 100 -c 10 file.ptp > /dev/ttyUSB0
```
The ascii-xfr command is included with the srecord tools (see above). The '-l 100 -c 10' directive instructs a line feed delay of 100ms and a character delay of 5ms.

## Editing assembly with vim
I use the vim editor on Linux when writing 6502 assembly language.

I find that Max Bane's vim syntax highlighting intended for the CA65 cross complier works well https://github.com/maxbane/vim-asm_ca65.
