[org 0x100000]			; Kernel starts at 1 MB
[bits 32]			

jmp	kmain				; jump to entry point

%include "kernel/stdio.inc"

;----------------------------------------------------------
;TEH EPIC MEMORY MAP:
;	0x500 - 0x1000  - unused
;	0x1000 - 0x11AA and grows - STAGE 2 & 3.
;	0x11AA - 0x3000 - should be reserved for future bootloader code.
;	0x3000 - 0x5000 - kernel image in real mode
;	0x3000 - 0x90000 - stack.
;	0x90000 - 0x100000 - unused space
;	HERE WE ARE!
;	0x100000 - 0xFFFFFFFF -  Kernel and free space! 
;-----------------------------------------------------------

kmain:	
	call	purplescreen

	cli
	hlt



