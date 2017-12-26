all: boot

boot: boot.nasm
	nasm -f bin boot.nasm

run: boot
	qemu-system-x86_64 boot

# This can blow away your hdd if used incorrectly.
# install: boot
# 	dd if=boot of=/dev/xyz bs=1048576

