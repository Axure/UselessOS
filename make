#!/usr/bin/bash

nasm bootloader/first.asm -f bin -o build/bootsector.bin
nasm bootloader/second.asm -f bin -o build/secondStage.bin
nasm kernel/kernel.asm -f bin -o build/KRNL.SYS
