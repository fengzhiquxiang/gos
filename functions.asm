%define ROWS 80
%define ROWZ 2*ROWS
%define COLUMNS 25

[BITS 32]

[SECTION .text]
    ; 导入全局变量
    extern  display_x
    extern  display_y
    
    ; 导出函数
    global	write_mem8
    global  print_a
    global  print_string_with_color
    global  io_delay
    global  init8259a
    global  start_clock
    global  restart_clock

    init8259a:
        ; 1. 往端口20h(主片)或A0h(从片)写入ICW1
        mov al,   00010001b
        out 0x20, al   ;00010001  =  11h
        call io_delay
        out 0xA0, al
        call io_delay

        ; 2. 往端口21h(主片)或A1h(从片)写入ICW2
        mov al, 00100000b;100000=0x20 IRQ0对应中断向量0x20
        out 0x21, al
        call io_delay
        mov al, 00101000b;00101000=0x28 IRQ8对应中断向量0x28
        out 0xA1, al
        call io_delay

        ; 3. 往端口21h(主片)或A1h(从片)写入ICW3
        mov al, 00000100b
        out 0x21, al
        call io_delay
        mov al, 00000010b
        out 0xA1, al
        call io_delay

        ; 4. 往端口21h(主片)或A1h(从片)写入ICW4
        mov al, 00000001b
        out 0x21, al
        call io_delay
        out 0xA1, al
        call io_delay

        ret

    start_clock:
        mov al, 11111110b   ;only clock interrupt
        out 0x21, al        ;master 8259 OCW1
        call io_delay

        mov al, 11111111b   ;close all interrupt in slave 8259
        out 0xA1, al        ;slave 8259  OCW1
        call io_delay

        ret

    restart_clock:
        mov al, 0x20; EOI
        out 0x20, al
        ret

    io_delay:
        nop
        nop
        nop
        nop
        ret

    ; ========================================================================
    ;                  void write_mem8(int addr, int data);
    ; ========================================================================
    write_mem8:
        mov ecx,[esp+4]   ;[esp+8]中存放的是地址，将其读入ecx
        mov al, [esp+8]   ;[esp+16]中存放的是数据，将其读入al
        mov [ecx],al
        ret

    print_a:
        ;mov eax, dword [display_y]
        ;mov ecx, ROWZ
        ;mul ecx
        ;mov ebx, dword [display_x]
        ;add eax, ebx
        ;mov edi, eax
        mov al, 'x'    
        mov ah, 0x0f   ;不是青色 土红色
        xor edi, edi
        mov [gs:edi], ax        
        ret
        
    ; ========================================================================
    ; void print_string_with_color(unsigned char * string, unsigned char color);
    ; ========================================================================
    print_string_with_color:
            mov esi, dword [esp+4]   ;[esp+4]中存放的是地址，将其读入eax
        .loop:
            cmp byte [esi], 0x00
            jz   .end
            cmp byte [esi], 0x0a    ;如果是换行符 \n ，就跳到下一行开头
            jnz .display
            inc dword [display_y]   ;next line display
            mov dword [display_x], 0
            inc esi
            jmp .loop
        .display:
            mov bl,  byte [esi]
            mov eax, dword [display_y]  ;上次在哪行显示
            mov ecx, ROWZ
            mul ecx
            add eax, dword [display_x]
            mov edi, eax
            mov bh,  byte  [esp+8]    ;颜色
            mov bl, byte [esi]
            mov [gs:edi], bx
            inc esi
            inc dword [display_x]
            inc dword [display_x]
            cmp dword [display_x], ROWZ
            jb  .loop
            mov dword [display_x], 0
            inc dword [display_y]   ;next line display
            jmp .loop
        .end:
            ret   
            
        
        
        
        
        
        
        
        
        