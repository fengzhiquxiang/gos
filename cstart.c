typedef	unsigned int		unsigned32;
typedef	unsigned short		unsigned16;
typedef	unsigned char		unsigned8;
typedef	 int		signed32;
typedef	 short		signed16;
typedef	 char		signed8;

/* 门描述符 */
typedef struct gate
{
	unsigned16	offset_low;	/* Offset Low */
	unsigned16	selector;	/* The selector is a 16 bit value and must point to a valid selector in your GDT. */
	unsigned8	dcount;		/* 该字段只在调用门描述符中有效。
				如果在利用调用门调用子程序时引起特权级的转换和堆栈的改变，需要将外层堆栈中的参数复制到内层堆栈。
				该双字计数字段就是用于说明这种情况发生时，要复制的双字参数的数量。 */
	unsigned8	attr;		/* P(1) DPL(2) DT(1) TYPE(4) */
	unsigned16	offset_high;	/* Offset High */
	/*			
	type_attr is specified here:
		
	   7                           0
	+---+---+---+---+---+---+---+---+
	| P |  DPL  | S |    GateType   |
	+---+---+---+---+---+---+---+---+
	The bit fields mean:
							IDT entry, Interrupt Gates
	Name		Bit		Full Name					Description
	Offset		48..63	Offset 16..31				Higher part of the offset.
	P			47		Present						Set to 0 for unused interrupts or for Paging.
	DPL			45,46	Descriptor Privilege Level	Gate call protection. Specifies which privilege Level the calling Descriptor minimum should have. So hardware and CPU interrupts can be protected from being called out of userspace.
	S			44		Storage Segment				Set to 0 for interrupt gates (see below).
	Type		40..43	Gate Type 0..3				Possible IDT gate types :
													0b0101		0x5	5	80386 32 bit task gate
													0b0110		0x6	6	80286 16-bit interrupt gate
													0b0111		0x7	7	80286 16-bit trap gate
													0b1110		0xE	14	80386 32-bit interrupt gate
													0b1111		0xF	15	80386 32-bit trap gate
	0			32..39	Unused 0..7					Have to be 0.
	Selector	16..31	Selector 0..15				Selector of the interrupt function (to make sense - the kernel's selector). The selector's descriptor's DPL field has to be 0.
	Offset		0..15	Offset 0..15				Lower part of the interrupt function's offset address (also known as pointer).
	*/
}Gate;

#define halt() __asm__ ("cli;hlt\n\t");

#define DISPLAY_INIT_POSITION   0xb8000
#define POSITION(py)            (DISPLAY_INIT_POSITION+py)    
#define DISPLAY_CLOUMN  80
#define DISPLAY_ROWS   	25
#define LINE_CHARS   	DISPLAY_CLOUMN*2        /*每一行的字符数*/

/*偏移计算公式,row=0表示第一行,cloumn从0开始*/
#define DISPLAY_POSITION(row,cloumn)  (row*LINE_CHARS+cloumn*2)

#define COLOR_GREEN   	0x02   /*绿色*/
#define COLOR_CYAN   	0x03   /*青色*/  
#define COLOR_RED   	0x04  /*红色*/
#define COLOR_WHITE   	0x0f  /*白色*/
// 0 - Black
// 1 - Blue
// 2 - Green
// 3 - Cyan
// 4 - Red
// 5 - Magenta
// 6 - Brown
// 7 - Light Gray
// 8 - Dark Gray
// 9 - Light Blue
// 10 - Light Green
// 11 - Light Cyan
// 12 - Light Red
// 13 - Light Magenta
// 14 - Light Brown
// 15 - White
extern void print_string_with_color(unsigned char * string, unsigned char color);
void print_string(unsigned char color, unsigned int py, unsigned char* str);
void print_string_with_row_cloumn(unsigned char color, unsigned int row, unsigned int cloumn , unsigned char* str);
void print_append(unsigned char color, unsigned char* string);
void print_start_with_zzz();

static inline unsigned8 inb(unsigned16 port);
static inline void outb(unsigned16 port, unsigned8 val);
void getScancode();/*get keyboard input*/

unsigned int current_row = 0;
unsigned int current_column = 0;

/*由这个函数开始*/
void c_start() {
    
    // print_string_with_row_cloumn(COLOR_GREEN,0,0,"modify and reload gdt");
    // print_string_with_row_cloumn(COLOR_RED,4,0,"\nhahaha\nheheh\n");
	print_string_with_color("\nin c print char",COLOR_GREEN);
    print_append(COLOR_GREEN,"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nc code test!\n");
    // getScancode();


    // print_append(COLOR_GREEN,"vv");
    // print_append(COLOR_GREEN,"xx");
   
	// halt();

	return;
}

void print_start_with_zzz(){
	print_append(COLOR_GREEN,"\nzzz -->: ");
	return;
}

/*
PS/2 keyboard code.
Dependencies:
inb function and scancode table.
*/
void getScancode()
{
	print_start_with_zzz();
	unsigned8 sc=0;
	while(1){
		if(inb(0x64) & 0x1){
			sc=inb(0x60);
			if(sc==45){
				print_append(COLOR_CYAN, "x");
			}
			if(sc==2){
				print_append(COLOR_CYAN, "1");
			}
			if(sc==28){
				print_append(COLOR_CYAN, "\nend of input");
				print_start_with_zzz();
				// break;
			}
			if(sc==47){
				break;
			}	
		}
		
	}
}

// char getchar()
// {
// 	return scancode[getScancode()+1];
// }

static inline void outb(unsigned16 port, unsigned8 val)
{
    asm volatile ( "outb %0, %1" : : "a"(val), "Nd"(port) );
    /* 
	 *	d  The d register. 
	 *	N  Unsigned 8-bit integer constant (for in and out instructions). 
     * There's an outb %al, $imm8  encoding, for compile-time constant port numbers that fit in 8b.  (N constraint).
     * Wider immediate constants would be truncated at assemble-time (e.g. "i" constraint).
     * The  outb  %al, %dx  encoding is the only option for all other cases.
     * %1 expands to %dx because  port  is a uint16_t.  %w1 could be used if we had the port number a wider C type 
     */
}
// INx
// Receives a 8/16/32-bit value from an I/O location. Traditional names are inb, inw and inl respectively.
static inline unsigned8 inb(unsigned16 port)
{
    unsigned8 ret;
    asm volatile ( "inb %[port], %[result]"
                   : [result] "=a"(ret)   // using symbolic operand names as an example, mainly because they're not used in order
                   : [port] "Nd"(port) );
    return ret;
}

/*
	;如果AL的BIT1为0或1，则BL表示显示属性。属性为：
	;｜BIT7｜BIT6｜BIT5｜BIT4｜BIT3｜BIT2｜BIT1｜BIT0｜ BL
	;  BIT7：背景是否闪烁。0不闪烁，1闪烁
	;  BIT6~BIT4为背景色，分别为RGB，000为黑色，111为白色
	;  BIT3为1，则前景色加亮，为0则不加亮
	;  BIT2－BIT0为前景色，意义同背景色
*/

void print_append(unsigned char color, unsigned char* string)
{
	print_string_with_row_cloumn(color,current_row,current_column,string);
	return;
}


void print_string_with_row_cloumn(unsigned char color, unsigned int row, unsigned int cloumn , unsigned char* str)
{
	current_row = row;
	current_column = cloumn;
	unsigned int py = DISPLAY_POSITION(current_row,current_column);
	print_string(color,py,str);
    return;
}

void print_string(unsigned char color, unsigned int py, unsigned char* str)
{
	unsigned char * p = (unsigned char*)POSITION(py);  /*放置要显示的字符*/
													   /*下一个放置要显示的字符的属性*/
	while(1){

		if (*str=='\n'){
			current_row++;
			current_column = 0;	
			p = (unsigned char *)POSITION(DISPLAY_POSITION(current_row,current_column));
			++str;
		}

		if (*str==0)
		{
			break;
		}

		*p++=*str;
		*p++=color;
		str++;
		if (current_column<DISPLAY_CLOUMN){
			++current_column;
		}else{
			++current_row;
			current_column = 0;
		}
	}
    return;
}
