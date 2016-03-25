; boot.asm
org  07c00h
jmp start
%include "pm.mac"

BaseOfLoaderPhyAddr equ 0x07c00
PM_START            equ 0x200

; GDT ----------------------------------------------------------------------------------------
;                          段基址,      段界限,   属性                                 -
GDT:          Descriptor        0,           0,   0                             ; 空描述符   -
DESC_FLAT_C:  Descriptor        0,     0fffffh,   DA_CR  | DA_32 | DA_LIMIT_4K ;|DA_DRW ; 0 ~ 4G     -
DESC_FLAT_RW: Descriptor        0,     0fffffh,   DA_DRW | DA_32 | DA_LIMIT_4K  ; 0 ~ 4G     -
DESC_VIDEO:   Descriptor  0B8000h,      0ffffh,   DA_DRW ;| DA_DPL3              ; 显存首地址 -
; GDT END-------------------------------------------------------------------------------------

GdtLen      equ   $ - GDT
GdtPtr      dw GdtLen - 1                          ; 段界限
            dd GDT;+ BaseOfLoaderPhyAddr           ; 基地址


; GDT 选择子 ---------------------------------------------
SelectorFlatC     equ   DESC_FLAT_C   - GDT             ;-
SelectorFlatRW    equ   DESC_FLAT_RW  - GDT             ;-
SelectorVideo     equ   DESC_VIDEO    - GDT + SA_RPL3   ;-
; GDT 选择子 end------------------------------------------


start:
mov ax, 0x0
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

;设置显示模式
;mov ah,  00h       ;入口参数：AH＝00H
;mov al,  02h       ;AL＝ 显示器模式，见下表所示
                   ;  出口参数：无
                   ;  可用的显示模式如下所列：
                   ;  00H：40×25 16色 文本
                   ;  01H：40×25 16 色 文本
                   ;  02H：80×25 16色 文本
                   ;  03H: 80×25 16色 文本
                   ;  04H：320×200 4色
;int 10h

;获取当前显示模式
;mov ah,  0fh
;int 10h

;光标归位
;mov   bh, 00h      ; BH＝显示页码
;mov   dx, 0000h      ; DH＝行(Y坐标) DL＝列(X坐标)
;int   02h         ; int 10h

;使用BIOS的0x10中断向屏幕打印一个字符
;mov ah, 0x0e
;mov al, '!'
;int 0x10
;mov ah, 0x0e
;mov al, '?'
;int 0x10

;call display
;jmp $
;加载img里的kernel.bin 进内存

   ; reset floppy
   ; xor ah, ah  ; ah=00h      al=驱动器号（0表示A盘） 
   ; xor dl,  dl
   ; int 13h

 call read_fd

;进入保护模式，执行kernel代码
      ; 1、初始化GDT描述符
      ; 2、加载gdtr
      ; 3、打开A20地址线
      ; 4、设置寄存器cr0的PE位为1，使之运行于保护模式
      ; 5、执行跳转指令，让系统进入保护模式

      ; 初始化 32 位代码段描述符
      ; xor eax, eax
      ; mov ax, cs
      ; shl eax, 4
      ; add eax, DESC_FLAT_C
      ; mov word [DESC_FLAT_C + 2], ax
      ; shr eax, 16
      ; mov byte [DESC_FLAT_C + 4], al
      ; mov byte [DESC_FLAT_C + 7], ah


      ; 下面准备跳入保护模式 -------------------------------------------

      ; 加载 GDTR
         lgdt  [GdtPtr]

      ; 关中断
         cli

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

display:
   mov   ax, BootMessage
   mov   bp, ax                        ; ES:BP = 串地址
   mov   cx, BootMessageLength         ; CX为字符串长度
   mov   ax, 01301h     ; AH = 13,BIOS的10H中断的13号中断用于显示字符串  
                        ;AL = 01h AL＝显示方式
                                    ;如果AL＝0，表示目标字符串仅仅包含字符，属性在BL中包含，不移动光标
                                    ;如果AL＝1，表示目标字符串仅仅包含字符，属性在BL中包含，移动光标
                                    ;如果AL＝2，表示目标字符串包含字符和属性，不移动光标
                                    ;如果AL＝3，表示目标字符串包含字符和属性，移动光标
   mov   bh, 0h      ; 页号为0(BH = 0) 黑底红字(BL = 0Ch,高亮)
   mov   bl, 01110000b   ;如果AL的BIT1为0或1，则BL表示显示属性。属性为：
                      ;｜BIT7｜BIT6｜BIT5｜BIT4｜BIT3｜BIT2｜BIT1｜BIT0｜ BL
                      ;  BIT7：背景是否闪烁。0不闪烁，1闪烁
                      ;  BIT6~BIT4为背景色，分别为RGB，000为黑色，111为白色
                      ;  BIT3为1，则前景色加亮，为0则不加亮
                      ;  BIT2－BIT0为前景色，意义同背景色
   mov   dh, 0        ; DH表示在第几行显示（0为第一行）
   mov   dl, 0       ;DL表示在第几列显示（0为第一列）
   int   10h         ; int 10h
   ret
;end of display

;; in:  ax: LBA address, starts from 0
    ;;    es:bx address for reading sector
read_sect:
    push ax
    push cx
    push dx
    push bx

    mov  ax,  si   
    xor  dx,  dx
    mov  bx,  18  ; 18 sectors per track 
          ; for floppy disk
    div   bx
    inc   dx
    mov   cl, dl  ; cl=sector number
    xor   dx,  dx
    mov   bx,  2  ; 2 headers per track 
          ; for floppy disk
    div   bx

    mov   dh,  dl   ; head
    xor   dl,  dl   ; driver
    mov   ch,  al   ; cylinder
    pop   bx        ; save to es:bx
rp_read:
    mov  al, 0x1    ;  read 1 sector
    mov  ah, 0x2
    int 0x13
    jc  rp_read
    pop   dx
    pop   cx
    pop   ax
    ret
; end of read_sect

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
    mov dl, 80h   ;dl=驱动器号 硬盘是0x80 软盘是0x0
    mov bx, 0x7e00 ;es:bx=数据缓冲区  放到7e00处
    mov ah, 02h
    int 13h
    jc read_fd
    ret
;end of read_fd

BootMessage db 'Hello gos!!!!!!!!!!!!!!!!!!'
BootMessageLength equ $-BootMessage

times 510-($-$$) db 0
db 0x55
db 0xAA