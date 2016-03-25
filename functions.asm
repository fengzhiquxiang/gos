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
            
        
        
        
        
        
        
        
        
        