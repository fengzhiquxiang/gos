typedef	unsigned int		unsigned32;
typedef	unsigned short		unsigned16;
typedef	unsigned char		unsigned8;
typedef	 int		signed32;
typedef	 short		signed16;
typedef	 char		signed8;


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


unsigned int current_row = 0;
unsigned int current_column = 0;

/*由这个函数开始*/
void c_start() {
    
	print_string_with_color("\nin c print char",COLOR_GREEN);
    print_append(COLOR_GREEN,"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nc code test!\n");
    
	return;
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
		jj:
		if (*str==0){
			break;
		}

		if(*str == '\n') {
			current_row++;
			current_column = 0;	
			p = (unsigned char *)POSITION(DISPLAY_POSITION(current_row,current_column));
			++str;
			goto jj;
		}

		*p++=*str++;
		*p++=color;
		if (current_column<DISPLAY_CLOUMN){
			++current_column;
		}else{
			++current_row;
			current_column = 0;
		}
	}
    return;
}
