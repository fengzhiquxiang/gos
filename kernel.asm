%include "pm.mac"

%define INIT_ADDR 0x7E00

%define COLOR_GREEN 0x02 ;  Green
%define COLOR_Cyan  0x03 ;  Cyan
%define COLOR_RED   0x04 ;  red
%define COLOR_White 0x0F ;  White

%define ROWS 80
%define ROWZ 2*ROWS
%define COLUMNS 25


[BITS 32]

[SECTION .text]
    extern c_start             ;out
    extern print_a
    extern print_string_with_color  ;  void print_string_with_color(unsigned char * string, unsigned char color);
    extern init8259a
    extern  start_clock

    global kernel_entry     ;entry
    global display_x    ;define vari
    global display_y    ;define vari

    kernel_entry:
        ;register initia
        mov eax,  0x10   
        mov ds,   ax     
        mov es,   ax    
        mov fs ,  ax 
        mov ss,   ax    
        mov eax,  0x18  
        mov gs,   ax       
        mov esp,  0xA0000  

        ;call c_start
        
        
        ;call print_a

        ;  void print_string_with_color(unsigned char * string, unsigned char color);
        ;push COLOR_RED
        ;push string1
        ;call print_string_with_color
        ;add esp, 0x08
        ;  void print_string_with_color(unsigned char * string, unsigned char color);
        ;push COLOR_Cyan
        ;push string1
        ;call print_string_with_color
        ;add esp, 0x08    

    init_idt:
        ;prepare for load idt pointer
        xor eax,eax
        mov ax,ds
        shl eax,4
        add eax,idt;idt base address
        mov dword [idtPtr+2],eax;init base address
        ;close interrupt
        cli
        ;load idt pointer
        lidt [idtPtr]
    ;init idt OKkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk

        call init8259a
        ;call start_clock
        int 0x20;clock
        int 0x80;user
        int 0x49;all
        int 0x58;all

        hlt
    here:		
        jmp here

    display_x: dd 0
    display_y: dd 0

    string0: db "all interrupts handler!",0x0a,0x00
    string1: db "clock interrupt!",0x0a,0x00
    string2: db "now is in normal",0x0a,0x00
    string3: db "now is user interrupt",0x0a,0x00
    ;string1_addr equ string1-$$+INIT_ADDR

    ALIGN 32
    idt:
        ;门    目标选择子 偏移        DCount   属性
    %rep 64;=0x40
        Gate   0x08,      idtHandler, 0,       DA_386IGate
    %endrep
 int20h:Gate   0x08,      clockHandler, 0,       DA_386IGate
    %rep 95; =0x60-1
       Gate   0x08,      idtHandler, 0,       DA_386IGate
    %endrep
int80h: Gate   0x08,      userHandler, 0,       DA_386IGate

    idtLen  equ  $-idt
    idtPtr  dw   idtLen-1;段界限
            dd   0; base address

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    _idtHandler:
    idtHandler equ  _idtHandler - $$ + INIT_ADDR
        ;  void print_string_with_color(unsigned char * string, unsigned char color);
        push COLOR_White
        push string0
        call print_string_with_color
        add esp, 0x08

        iretd

    _clockHandler:
    clockHandler equ  _clockHandler - $$ + INIT_ADDR
        ;  void print_string_with_color(unsigned char * string, unsigned char color);
        push COLOR_RED
        push string1
        call print_string_with_color
        add esp, 0x08

        iretd

    _userHandler:
    userHandler equ  _userHandler - $$ + INIT_ADDR
        ;  void print_string_with_color(unsigned char * string, unsigned char color);
        push COLOR_GREEN
        push string3
        call print_string_with_color
        add esp, 0x08

        iretd
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<        