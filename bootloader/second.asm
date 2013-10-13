[bits 16] ; still in real mode.
[org 1000h] ; first stage bootloader loads this to 0x0:1000h

entry_point:
	jmp start

	str_welcome		db "I'm second stage bootloader ver. 2.08, we're going to 32 bit world!", 13, 10, 0

	%include "bootloader/rm_stdio.inc" 
	%include "bootloader/gdt.inc"	
	%include "bootloader/A20.inc"
	%include "bootloader/FAT12.asm"
	loadingMsg db 0x0D, 0x0A, "Searching for kernel...", 0x00
	msgFailure db 0x0D, 0x0A, "FATAL: MISSING OR CURRUPT KRNL.SYS. Press Any Key to Reboot", 0x00

	%define KERNEL_PMODE_BASE_PTR 0x100000 	;where kernel will be copied after going to protected mode.
	%define KERNEL_RMODE_BASE_PTR 0x3000 	; where kernel will be temporally loaded in real mode
	kernelName db "KRNL    SYS" 	; kernel name (Must be 11 bytes)
	kernelSize db 0 	;size of kernel in bytes

start:
	;print welcome
	mov si, str_welcome
	call puts16

	cli	;disable interrupts - in protected mode we cannot access to IVT and any interrupt will give us triple fault
 
	call	installGDT		
	call	enableA20	

	;==================-----------------------------------------;
	; Loading kernel. |											;
	;==================											;
	call	LoadRoot		; initialize filesystem				;
																;
	mov	bx, 0													;			
    mov	bp, KERNEL_RMODE_BASE_PTR								;
	mov	si, kernelName											;
	call	LoadFile											;
																;
	mov	dword [kernelSize], ecx									;
	cmp	ax, 0			; Test for success						;
	je	enterPMODE												;
																;
	mov	si, msgFailure											;
	call	puts16												;
	mov	ah, 0													;
	int     0x16                    ; await keypress			;
	int     0x19                    ; warm boot computer		;
	;------------------------------------------------------------

enterPMODE:
		mov	eax, cr0		
		or	eax, 1
		mov	cr0, eax
		 
		jmp	0x8:stage3		; far jump to fix CS. 0x8 is offset in GDT, not offset like in real mode.

;********************************************
; 			STAGE 3 ENTRY POINT!			|
;********************************************

[bits 32]
%include "bootloader/stdio.inc" ;protected mode stdio subroutines
hello32bitWorld db "After a long travel, we're in the protected mode. Yay!", 0

stage3:
	;fix rest of segment registers
	mov		eax, 0x10		; set data segments to data selector (0x10)
	mov		ds, ax
	mov		ss, ax
	mov		es, ax
	mov		esp, 0x90000		; stack begins from 0x90000. Grows downwards.
 
	;----------------------------------------------------------
	;TEH EPIC MEMORY MAP:
	;	0x500 - 0x1000  - unused
	;	0x1000 - 0x11AA and grows - STAGE 2 & 3.
	;	Here we are now!
	;	0x11AA - 0x3000 - should be reserved for future code.
	;	0x3000 - 0x5000 - kernel image in real mode
	;	0x3000 - 0x90000 - stack.
	;	0x90000 - 0x100000 - unused space
	;	0x100000 - 0xFFFFFFFF -  Kernel and free space! 
	;-----------------------------------------------------------

	call cls

	mov esi, hello32bitWorld
	call puts32

copyKernel:
  	 mov	eax, dword [kernelSize]
  	 movzx	ebx, word [bpbBytesPerSector]
  	 mul	ebx
  	 mov	ebx, 4
  	 div	ebx
   	 cld
   	 mov    esi, KERNEL_RMODE_BASE_PTR
   	 mov	edi, KERNEL_PMODE_BASE_PTR
   	 mov	ecx, eax
   	 rep	movsd                   ; copy image to its protected mode address

	;---------------------------------------;
	;   JUMP TO KERNEL LAND!				;
	;---------------------------------------;
	jmp	0x08:KERNEL_PMODE_BASE_PTR; jump to our kernel! Note: This assumes Kernel's entry point is at 1 MB

	
	;*******************************************************
	;	Stop execution
	;*******************************************************

	hlt
		
