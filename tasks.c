
#define COLOR_GREEN   	0x02   /*绿色*/
#define COLOR_Magenta   0x05   /*Magenta 紫红色的；洋红色的*/

struct Task
{
	
};

extern void print_string_with_color(unsigned char * string, unsigned char color);

void start_multitasks(){
	print_string_with_color("start_process!!!",COLOR_Magenta);
	// 增加TSS全局描述符
	//   1.准备一个进程体process0
	//   2.初始化进程表
	return;
}

void task0() {
    while(1){
		print_string_with_color("000000000000000000",COLOR_GREEN);
    }
	return;
}

void task1() {
    while(1){
		print_string_with_color("1",COLOR_Magenta);
    }
	return;
}