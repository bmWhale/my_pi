#include <stdio.h>
#include <time.h>
int main()
{
	struct timespec	start,end;
	get_time(&start);
	printf("helloWorld\n");
	get_time(&end);
	print_time_usage(start,end);
	
}
