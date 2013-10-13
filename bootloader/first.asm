;ATTENTION! If you copy this to your MBR it will destroy(fill with zeroes) your partition table! Be careful!

[bits 16] ;CPU start's in real mode, which is 16bit.
[org 0x7C00] ;BIOS will load this bootloader to memory at 0x7C00, so we must set orgin

entry_point:

jmp start ;skip data section, go to code

%include "bootloader/bpb.inc" ;MUST BE EXACTLY HERE! 

%include "bootloader/rm_stdio.inc"

;some data
	msg_hello	db 'First stage bootloader version 2.67 welcomes you, master.', 13, 10, 0
	msg_jump	db "Fasten your seatbelt, we're going to the second stage bootloader.", 13, 10, 10, 0
	
	read_pocket:
		db	0x10	; size of pocket
		db	0		; const 0
		dw	4		; number of sectors to transfer
		dw	0x1000, 0x0000	; address to write (segment:offset but because its little endian its offset, segment)
		dd	1		; LBA - from 0 so it's 2 sector
		dd	0		; upper LBA

			
;General memory map in real mode:
;0x00000000 - 0x000003FF - Real Mode Interrupt Vector Table
;0x00000400 - 0x000004FF - BIOS Data Area
;0x00000500 - 0x00007BFF - Unused
;0x00007C00 - 0x00007DFF - Our Bootloader
;0x00007E00 - 0x0009FFFF - Unused
;0x000A0000 - 0x000BFFFF - Video RAM (VRAM) Memory
;0x000B0000 - 0x000B7777 - Monochrome Video Memory
;0x000B8000 - 0x000BFFFF - Color Video Memory
;0x000C0000 - 0x000C7FFF - Video ROM BIOS
;0x000C8000 - 0x000EFFFF - BIOS Shadow Area
;0x000F0000 - 0x000FFFFF - System BIOS

;start bootloader exec
start:					
	
	;----------------------------------------------------
	; SETUP SEGMENT REGISTERS, STACK and direction flag  |
	;----------------------------------------------------
	
	; Disable interrupts
	cli
	
	; Setup stack
	xor ax, ax
	mov ss, ax
	mov sp, 0x900 ; 0x900 to 0x500. 

	; Setup other segment regs
	mov es, ax
	mov ds, ax
	
	; Enable interrupts
	sti
	
	; Clear direction flag
	cld

	;----------------------------------------------------
	; 				PRINT WELCOME STRING 				 |
	;----------------------------------------------------
	
	mov si, msg_hello
	call puts16
	
	;----------------------------------------------------
	; 			LOAD SECOND STAGE TO MEMORY				 |
	;----------------------------------------------------
	;read second stage bootloader from drive #0
	mov	si, read_pocket
	mov	ah, 0x42	; extension(0x42h == LBA)
	mov	dl, 0x80	; drive number (0x80 is drive #0)
	int	0x13
	 
	;----------------------------------------------------
	; 				ENTER TO SECOND STAGE!				 |
	;----------------------------------------------------
	;print message - if loading fails we will know.
	mov si, msg_jump
	call puts16

	;jump!
	mov ax, 0x1000
	jmp ax

;fill rest of bootsector with zeroes PARTITION TABLE WILL BE DESTROYED IF YOU COPY THIS TO BOOTSECTOR!
times (510-($-entry_point)) db 0 ; $ is current line adress.

;bootsector signature
db 0x55
db 0xAA
