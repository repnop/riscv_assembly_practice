#!/usr/bin/fish
mkdir -p obj
mkdir -p out
riscv64-unknown-elf-as src/$argv.s -o obj/$argv.o -march=rv64gc -mabi=lp64 --fatal-warnings -g
riscv64-unknown-elf-ld -static -nostdlib -Tlink.ld obj/$argv.o -o out/$argv --fatal-warnings
qemu-system-riscv64 -machine virt -cpu rv64 -m 128M -nographic -serial mon:stdio -bios none -kernel out/$argv -gdb tcp::1234 -S