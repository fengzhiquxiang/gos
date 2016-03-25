; boot.asm

BaseOfLoaderPhyAddr equ 0x07c00

[SECTION .text]
org  0x7c00

start:
  xor ax, ax      ;mov ax, 0x0
  mov ds, ax
  mov es, ax 
  mov ss, ax 

  mov ax, BaseOfLoaderPhyAddr
  mov sp, ax   

  ; 清屏
  mov   ax, 0600h      ; AH = 6,  AL = 0h
  mov   bx, 0700h      ; 黑底白字(BL = 07h)
  mov   cx, 0       ; 左上角: (0, 0)
  mov   dx, 0184fh     ; 右下角: (80, 50)
  int   10h         ; int 10h

  call read_fd

  ; 下面准备跳入保护模式 -------------------------------------------
  ; 关中断
  cli
  ; 加载 GDTR
  lgdt  [GdtPtr]
  ; 打开地址线A20
  in al, 92h
  or al, 00000010b
  out   92h, al

  ; 准备切换到保护模式
  mov   eax, cr0
  or eax, 1
  mov   cr0, eax

  ; 真正进入保护模式
  jmp   dword SelectorFlatC:0x7e00


hang:
  jmp hang

%include "pm.mac"

; GDT ----------------------------------------------------------------------------------------
;                     段基址,      段界限,   属性                                 -
GDT:     Descriptor        0,           0,   0                             ; 空描述符   -
FLAT_C:  Descriptor        0,     0fffffh,   DA_CR  | DA_32 | DA_LIMIT_4K ;|DA_DRW ; 0 ~ 4G     -
FLAT_RW: Descriptor        0,     0fffffh,   DA_DRW | DA_32 | DA_LIMIT_4K  ; 0 ~ 4G     -
VIDEO:   Descriptor  0B8000h,      0ffffh,   DA_DRW ;| DA_DPL3              ; 显存首地址 -
; GDT END-------------------------------------------------------------------------------------

GdtLen  equ $ - GDT
GdtPtr  dw GdtLen - 1                          ; 段界限
        dd GDT;+ BaseOfLoaderPhyAddr           ; 基地址


; GDT 选择子 ---------------------------------------------
SelectorFlatC     equ   FLAT_C   - GDT             ;-
SelectorFlatRW    equ   FLAT_RW  - GDT             ;-
SelectorVideo     equ   VIDEO    - GDT ;+ SA_RPL3   ;-
; GDT 选择子 end------------------------------------------



; read sector 2 to memory 从cl/ch/dh/dl指向的扇区开始读取al个扇区的数据到es:bx指向的缓冲区
read_fd:
    xor ax, ax
    mov al, 12h   ; al=要读扇区数
    mov ch, 00000000b   ;ch=磁道号,CL - 位7、6是磁道号高2位
    mov cl, 00000010b   ;cl=起始扇区号,CL - 位5~0表示扇区号（从1开始）
                  ;mov cx, 0x0002 ;CH，10位磁道号低8位
                 ;CL - 位7、6是磁道号高2位
                 ;CL - 位5~0表示扇区号（从1开始）
                 ;本指令表示读取0号驱动器0号磁道第2号扇区
                 ;第1扇区就是boot扇区
    mov dh, 00h   ;dh=磁头号
    mov dl, 00h   ;dl=驱动器号 硬盘是0x80 软盘是0x0
    mov bx, 0x7e00 ;es:bx=数据缓冲区  放到7e00处
    mov ah, 02h
    int 13h
    jc read_fd
    ret
;end of read_fd

times 510-($-$$) db 0
db 0x55
db 0xAA