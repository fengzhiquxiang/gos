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
    extern   start_clock
    extern restart_clock
    extern start_multitasks
    extern task0
    extern task0_address

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

    reload_gdt:
        lgdt  [GdtPtr]
        jmp SelectorFlatC:haha
    haha:
        ;call print_a

;        void print_string_with_color(unsigned char * string, unsigned char color);
        ;push COLOR_RED
        ;push string1
        ;call print_string_with_color
        ;add esp, 0x08

    init_idt:
        ;prepare for load idt pointer
        ;xor eax,eax
        ;mov ax,ds
        ;shl eax,4
        ;add eax,idt;idt base address
        ;mov dword [idtPtr+2],eax;init base address
        ;close interrupt

        ;load idt pointer
        lidt [idtPtr]
    ;init idt OKkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk

        call init8259a
        sti
        call start_clock
        ;int 0x20;clock
        ;int 0x80;user
        ;int 0x1f;all
        ;int 0x00;test 0

        ;call c_start
;processsssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss
    ; Load LDT
        mov ax, SelectorLDT
        lldt    ax
        mov ax, SelectorTSS
        ltr ax
    ;call start_process
        ;jmp SelectorTSS1:0
        ;jmp SelectorLDTP0:TASK0ADDRESS
        ;push    SelectorStack3
        ;push    TopOfStack3
        ;push    SelectorCodeRing3
        ;push    0
        ;retf

;processsssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss
        hlt
    here:		
        jmp here

    display_x: dd 0
    display_y: dd 0

    string0: db "all interrupts handler!",0x0a,0x00
    string1: db "clock interrupt!",0x0a,0x00
    string2: db "now is in normal",0x0a,0x00
    string3: db "now is user interrupt",0x0a,0x00
    string4: db "TASK00000000000000",0x0a,0x00
    string5: db "idt 0 test0Handler!!",0x0a,0x00
    string6: db "jmp SelectorTSS:0 but jmp to int20h!",0x0a,0x00
    ;string1_addr equ string1-$$+INIT_ADDR

; idt gate
;iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
ALIGN 32
    idt:
        ;门    目标选择子 偏移        DCount   属性
  int00h:Gate   0x08,      test0Handler, 0,       DA_386IGate
    %rep 30;   60h=0x40
        Gate   0x08,      test1Handler, 0,       DA_386IGate
    %endrep
 int1fh:Gate   0x08,      test1Handler, 0,       DA_386IGate
 int20h:Gate   0x08,      clockHandler, 0,       DA_386IGate
    %rep 95; =0x60-1
       Gate   0x08,      idtHandler, 0,       DA_386IGate
    %endrep
int80h: Gate   0x08,      userHandler, 0,       DA_386IGate

    idtLen  equ  $-idt
    idtPtr  dw   idtLen-1;段界限
            dd   idt; base address
;iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii

; idt handler
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
        cli
        hlt
        call restart_clock

        iretd

    _userHandler:
    userHandler equ  _userHandler - $$ + INIT_ADDR
        ;  void print_string_with_color(unsigned char * string, unsigned char color);
        push COLOR_GREEN
        push string3
        call print_string_with_color
        add esp, 0x08

        iretd
    _test0Handler:
    test0Handler equ  _test0Handler - $$ + INIT_ADDR
        ;  void print_string_with_color(unsigned char * string, unsigned char color);
        push COLOR_Cyan
        push string6
        call print_string_with_color
        add esp, 0x08

        iretd
    _test1Handler:
    test1Handler equ  _test1Handler - $$ + INIT_ADDR
        ;  void print_string_with_color(unsigned char * string, unsigned char color);
        push COLOR_Cyan
        push string5
        call print_string_with_color
        add esp, 0x08

        iretd
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<   

; new GDT ----------------------------------------------------------------------------------------
;                         段基址,      段界限,   属性                                 -
GDT:       Descriptor          0,           0,   0                             ; 空描述符   -
FLAT_C:    Descriptor          0,     0fffffh,   DA_CR  | DA_32 | DA_LIMIT_4K ;|DA_DRW ; 0 ~ 4G     -
FLAT_RW:   Descriptor          0,     0fffffh,   DA_DRW | DA_32 | DA_LIMIT_4K  ; 0 ~ 4G     -
VIDEO:     Descriptor    0B8000h,      0ffffh,   DA_DRW ;| DA_DPL3              ; 显存首地址 -
DESC_TSS:  Descriptor TSSADDRESS,    TSSLen-1,   DA_386TSS
DESC_TSS1: Descriptor TSS1ADDRESS,    TSS1Len-1,   DA_386TSS
LDT_IN_GDT:Descriptor LDTADDRESS,    LDTLen-1,   DA_LDT    ; LDT
; GDT END-------------------------------------------------------------------------------------

GdtLen  equ $ - GDT
GdtPtr  dw GdtLen - 1                          ; 段界限
        dd GDT;+ BaseOfLoaderPhyAddr           ; 基地址


; GDT 选择子 ---------------------------------------------
SelectorFlatC     equ   FLAT_C   - GDT              ;1*8
SelectorFlatRW    equ   FLAT_RW  - GDT              ;2*8
SelectorVideo     equ   VIDEO    - GDT ;+ SA_RPL3   ;3*8
SelectorTSS       equ  DESC_TSS  - GDT              ;4*8
SelectorTSS1      equ  DESC_TSS1 - GDT              ;5*8
SelectorLDT       equ LDT_IN_GDT - GDT              ;6*8
; GDT 选择子 end------------------------------------------

;[BITS   32]
TSS:
TSSADDRESS equ $-$$+INIT_ADDR
    DW  0           ; Previous Task Link
    DW  0           ; Reserved 
    DD  0           ; ESP0
    DW  0           ; SS0
    DW  0           ; Reserved 
    DD  0           ; ESP1
    DW  0           ; SS1
    DW  0           ; Reserved 
    DD  0           ; ESP2
    DW  0           ; SS2
    DW  0           ; Reserved 
    DD  0           ;CR3 (PDBR)
    DD  0           ;EIP
    DD  0           ;EFLAGS
    DD  0           ;EAX
    DD  0           ;ECX
    DD  0           ;EDX
    DD  0           ;EBX
    DD  0           ;ESP
    DD  0           ;EBP
    DD  0           ;ESI
    DD  0           ;EDI
    DW  0           ; ES
    DW  0           ; Reserved 
    DW  0           ; CS
    DW  0           ; Reserved 
    DW  0           ; SS
    DW  0           ; Reserved 
    DW  0           ; DS
    DW  0           ; Reserved 
    DW  0           ; FS
    DW  0           ; Reserved 
    DW  0           ; GS
    DW  0           ; Reserved 
    DW  0           ; LDT Segment Selector
    DW  0           ; Reserved 
    DW  0           ; Reserved
    DW  0x4000           ; I/O Map Base Address 
    
TSSLen      equ $ - TSS     ;must have a value equal to or greater than 103

TSS1:
TSS1ADDRESS equ $-$$+INIT_ADDR
    DW  0           ; Previous Task Link
    DW  0           ; Reserved 
    DD  0           ; ESP0
    DW  0           ; SS0
    DW  0           ; Reserved 
    DD  0           ; ESP1
    DW  0           ; SS1
    DW  0           ; Reserved 
    DD  0           ; ESP2
    DW  0           ; SS2
    DW  0           ; Reserved 
    DD  0           ;CR3 (PDBR)
    DD  TASK0ADDRESS           ;EIP
    DD  0           ;EFLAGS
    DD  0           ;EAX
    DD  0           ;ECX
    DD  0           ;EDX
    DD  0           ;EBX
    DD  0           ;ESP
    DD  0           ;EBP
    DD  0           ;ESI
    DD  0           ;EDI
    DW  SelectorFlatRW           ; ES
    DW  0           ; Reserved 
    DW  SelectorFlatC           ; CS
    DW  0           ; Reserved 
    DW  SelectorFlatRW           ; SS
    DW  0           ; Reserved 
    DW  SelectorFlatRW           ; DS
    DW  0           ; Reserved 
    DW  SelectorFlatRW           ; FS
    DW  0           ; Reserved 
    DW  SelectorVideo           ; GS
    DW  0           ; Reserved 
    DW  0           ; LDT Segment Selector
    DW  0           ; Reserved 
    DW  0           ; Reserved
    DW  0x4000           ; I/O Map Base Address 
    
TSS1Len      equ $ - TSS1     ;must have a value equal to or greater than 103

;ALIGN   32
LDT:
LDTADDRESS equ $-$$+INIT_ADDR
;                            段基址       段界限      属性
;LDT_P0: Descriptor TASK0ADDRESS, TASK0Len - 1, DA_C + DA_32 ; Code, 32 位
LDT_P0_RW: Descriptor TASK0_RWADDRESS, TASK0_RWLen - 1, DA_DRW  ; Code, 32 位
;LDT_P0: Descriptor 0,     0fffffh,   DA_CR  | DA_32 | DA_LIMIT_4K

LDTLen      equ $ - LDT
; LDT 选择子
;SelectorLDTP0    equ LDT_P0    - LDT + SA_TIL
SelectorLDTP0_RW    equ LDT_P0_RW    - LDT + SA_TIL
; END of [SECTION .ldt]

TASK0:
TASK0ADDRESS equ $-$$+INIT_ADDR
    ;print_a:
        mov al, 'x'    
        mov ah, 0x0f   ;土红色
        xor edi, edi
        mov [gs:edi], ax        
        ;ret
        ;call task0
    hlt
    jmp $
TASK0Len equ $ - TASK0

TASK0_RW:
TASK0_RWADDRESS equ $-$$+INIT_ADDR
    times 1024 db 0
TASK0_RWLen equ $ - TASK0_RW
; END 