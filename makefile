ASM = nasm -Iinclude/ 

ASMFLAGS = -f elf32  

LD=ld
CC=gcc
CPP=gcc -E -nostdinc -Iinclude

CFLAGS=-W -nostdlib -nostdinc  -I include -std=gnu99
#CFLAGS+= -Wno-int-to-pointer-cast  -Wno-pointer-to-int-cast
CFLAGS+= -m32
#-Wall -pedantic -W是警告选项，
#-nostdlib告诉GCC不要用标准库，
#-nostdinc -Iinclude 告诉GCC应该在目录include下寻找头文件而不搜索标准头文件目录，
#-Wno-long-long禁止关于long long不是C89标准的警告，
#-fomit-frame-pointer很重要，否则info不能正确的处理栈帧。 -fomit-frame-pointer -mpush-args


LDFLAGS= --oformat binary  -e kernel_entry -Ttext 0x7e00 
LDFLAGS+= -m elf_i386 
# LDFLAGS=--oformat binary -N -e pm_mode -Ttext 0x0000

#--oformat binary表示要GCC产生一个纯粹的没有文件头和其它信息的“平坦”二进制文件，
#   就想DOS下的.com一样。没有这个选项，ld默认使用ELF格式(取决于你的系统设置)，
#   但BIOS可不认得ELF是什么东西。
#   在这段代码里你可能不需要-N这个选项，单位了将来的方便还是放在这里。
#    它让代码区可读可写，因为我不设置单独的数据区，在后面的章节中我将会在代码区中执行写入操作。

#-e start命名一个入口点，它告诉连接器应该在start处开始执行代码。

#-Ttext 0x7c00将代码区的基地址设置为7C00，它是引导扇区被载入内存的初始地址。
#    代码区中所有的代码地址都将被加上7C00。例如start的地址将是7C00，
#    而结束标识AA55的地址是7C00+1FE = 7DFE。

#.s.o:
#	${ASM} -a $< -o $*.o >$*.map

all: gos.fd gos.hd

gos.fd: boot.bin kernel
	cat boot.bin kernel > gos.bin
	#假定内核就80个扇区
	dd if=gos.bin of=gos.fd bs=512 count=80 conv=notrunc
	cp gos.fd gos.img


gos.hd: boothd.bin kernel
	cat boothd.bin kernel > gos.bin
	#假定内核就80个扇区
	dd if=gos.bin of=gos.hd bs=512 count=80 conv=notrunc	

boot.bin: boot.asm
	${ASM} boot.asm -o boot.bin -l boot.lst

boothd.bin: boot.asm
	${ASM} boothd.asm -o boothd.bin -l boothd.lst	

kernel: kernel.asm functions.asm cstart.c
	${ASM} ${ASMFLAGS} kernel.asm -o kernel.o -l kernel.lst
	${CC} ${CFLAGS} -c cstart.c -o cstart.o
	${ASM}  ${ASMFLAGS}  functions.asm -o functions.o -l functions.lst
	${LD} ${LDFLAGS} kernel.o  cstart.o  functions.o -o kernel

clean:
	rm -f *.bin kernel *.o *.img *.elf *.map *.lst
