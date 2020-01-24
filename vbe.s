	//////////////////////////////////////////////////
	//
	// Sector 0 (MBR)
	//
	//////////////////////////////////////////////////
	
	.code16

	// set graphics segment (always using %gs)
	mov $0xB800, %ax
	mov %ax, %gs

	// set stack segment
	mov $0x9000, %ax
	mov %ax, %ss
	mov $0, %sp

	call clear

	// read 16 sectors from floppy 0
	mov $0x4000, %ax
	mov %ax, %es
	mov $0x0, %bx
	mov $0x02, %ah
	mov $16, %al
	mov $1, %cx
	mov $0, %dx
	int $0x13

	// set data segment
	mov $0x4000, %ax
	mov %ax, %ds

	// print "Hello!" on screen
	mov $h0, %si
	mov $0, %di
	call write

	// jump to sector 2
	ljmp $0x4000, $0x400

write:
	mov $0x20, %dh
.write_loop:
	mov (%si), %dl
	cmp $0, %dl
	je .write_end
	mov %dx, %gs:(%di)
	inc %si
	add $2, %di
	jmp .write_loop
.write_end:
	ret

to_hex_char:
	cmp $10, %dl
	jge .hex_letter
	add $'0, %dl
	ret
.hex_letter:
	add $'A-10, %dl
	ret

write_hex8:
	mov $0x20, %dh
	mov %al, %dl
	and $0x0F, %dl
	call to_hex_char
	mov %dx, %gs:2(%di)
	mov %al, %dl
	shr $4, %dl
	call to_hex_char
	mov %dx, %gs:(%di)
	ret

write_hex16:
	add $4, %di
	call write_hex8
	mov %ah, %al
	sub $4, %di
	call write_hex8
	ret

clear:
	mov $80*24, %cx
	mov $0, %di
.clear_loop:
	movb $0, %gs:(%di)
	inc %di
	loop .clear_loop
	ret

	.org 0x1FE
	.word 0xAA55

	
	//////////////////////////////////////////////////
	//
	// Sector 1 (Data)
	//
	//////////////////////////////////////////////////

h0:	.string "Hello!"
h2:	.string "Hello from sector 2!"
emsg:	.string "ERROR"
char_x:	.string "x"
buf:	.zero 32

	.org 0x400

	
	//////////////////////////////////////////////////
	//
	// Sector 2
	//
	//////////////////////////////////////////////////

	mov $h2, %si
	mov $160, %di
	call write

	// get VESA mode information
	mov $0x2000, %ax
	mov %ax, %es
	movl $0x32454256, %es:0
	mov $0x4F00, %ax
	mov $0, %di
	int $0x10

	mov %es:14, %ax
	mov %ax, %bx
	mov %es:16, %ax
	mov %ax, %fs

	mov $480, %di
.mode_loop:
	mov %fs:(%bx), %cx
	cmp $0xFFFF, %cx
	je .halt
	mov $0x4F01, %ax
	push %di
	push %fs
	push %bx
	mov $0x1000, %di
	int $0x10
	pop %bx
	pop %fs
	pop %di
	cmp $0x004F, %ax
	jne .error
	mov %es:0x1012, %ax
	call write_hex16
	mov $char_x, %si
	add $8, %di
	call write
	mov %es:0x1014, %ax
	call write_hex16

	add $2, %bx
	add $10, %di
	jmp .mode_loop
	
.halt:
	hlt
	jmp .halt

.error:
	mov $emsg, %si
	mov $320, %di
	call write
	jmp .halt
