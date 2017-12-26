[BITS 16]
org 0x7c00

boot:
    jmp 0x0:here ;Ensure cs:ip is 0x0000:7c00
here:
    mov ax,0x0000
    mov ds,ax
    call print_ip
    call print_cs
    call print_ds
    call print_ss
    call print_sp
    mov ax,(0x7c00+510-space)
    mov bx, str_spaceleft
    call print_prefix

    mov dl,0x80
    call read_disk
    mov dl,0x00
    call read_disk
    jmp $

; prints the contents of ax to the console

str_floppy_active: db "floppy in use", 0x0d, 0x0a, 0
str_hdd_active: db "hdd in use", 0x0d, 0x0a, 0
str_floppy_fail: db "fail floppy stat", 0x0d, 0x0a, 0
str_hdd_fail: db "fail hdd stat", 0x0d, 0x0a, 0
str_readsuccess: db "read disk success: ",0
str_readfail: db "failed to read disk: ",0
str_ax: db "ax: ",0
str_ip: db "ip: ",0
str_cs: db "cs: ",0
str_ss: db "ss: ",0
str_sp: db "sp: ",0
str_ds: db "ds: ",0
str_spaceleft: db "space left: ",0
str_badsig: db "bad disk signature for device: ",0

print_ip:
    mov ax,[esp]
    mov bx,str_ip
    jmp print_prefix
print_ax:
    mov bx,str_ax
    jmp print_prefix
print_cs:
    mov bx,str_cs
    mov ax,cs
    jmp print_prefix
print_ds:
    mov ax,ds
    mov bx,str_ds
    jmp print_prefix
print_ss:
    mov ax,ss
    mov bx,str_ss
    jmp print_prefix
print_sp:
    mov ax,sp
    mov bx,str_sp
    jmp print_prefix

print_prefix:
    push ax
    call print_cstr
    pop ax
    jmp print_16bit_val
    ret

print_cstr:
    mov al,[ds:bx]
    and al,al
    jnz _print_cstr_loop
retf_01:
    ret
_print_cstr_loop:
    inc bx
    push bx
    call pchar
    pop bx
    jmp print_cstr

print_16bit_val:
    push ax

    mov al,'0'
    call pchar
    mov al,'x'
    call pchar

    pop ax
    push ax

    shr ax, 12
    call tohex
    call pchar

    pop ax
    push ax
    shr ax, 8
    call tohex
    call pchar

    pop ax
    push ax
    shr ax, 4
    call tohex
    call pchar

    pop ax
    push ax
    call tohex
    call pchar

    mov al, 0x0a
    call pchar
    mov al, 0x0d
    call pchar
    
    pop ax

; converts al into a hex digit in al
tohex:
    and al,0x0f
    cmp al,0x09
    jle digit
    add al,0x57
    ret
digit:
    add al, 0x30
    ret

; print the contents of al
pchar:
    mov ah, 0x0e
    mov bh, 0x00
    mov bl, 0x07
    int 0x10
    ret

; dl = disk number. 0x80 for hdd, 0x00 for fd0
read_disk:
    push dx
    mov ax,0x1000
    mov es,ax ;es:bx is the location to put the data
    mov ah,0x02 ;magic number for 'read drive'
    mov al,0x80 ;sector read count. 128x512 = 64KiB (single segment of memory)
    mov ch,0x00 ;cylinder
    mov cl,0x02 ;sector
    mov dh,0x00 ;head
    mov bx,0x0000
    int 0x13
    pop dx
    jc read_failed ;carry flag is set if there was an error

    mov ax,[es:0000]
    cmp ax,0xbeef
    je read_disk_success
    mov bx,str_badsig
    mov ax,dx
    and ax,0xff
    call print_prefix
    ret

read_disk_success:
    mov ax,dx
    and ax,0xff
    mov bx,str_readsuccess
    call print_prefix
    jmp 0x1000:0x0002

read_failed:
    mov bx,str_readfail
    jmp print_prefix
    ret

space:
times 510-($-$$) db 0

db 0x55
db 0xaa

; Expected to be loaded at 0x10000
section main_disk vstart=0

magic:
    dw 0xbeef
secondsector:
    mov ax,cs
    mov ds,ax
    mov bx,str_hello_world
    call print_cstr2
    jmp $

; print the contents of al
pchar2:
    mov ah, 0x0e
    mov bh, 0x00
    mov bl, 0x07
    int 0x10
    ret

print_cstr2:
    mov al,[bx]
    and al,al
    jnz _print_cstr_loop2
    ret
_print_cstr_loop2:
    inc bx
    push bx
    call pchar2
    pop bx
    jmp print_cstr2



str_hello_world: db "hello from the second sector of the disk!", 0

times 1048576-($-$$) db 0
