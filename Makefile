a.out: vbe.s
	as -o vbe.o vbe.s
	ld -Ttext-segment=0 --oformat binary vbe.o

run: a.out
	qemu-system-i386 -fda a.out -vga std
