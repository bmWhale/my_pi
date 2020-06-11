#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

void DoProgress( char label[], int step, int total )
{
    //progress width
    const int pwidth = 72;

    //minus label len
    int width = pwidth - strlen( label );
    int pos = ( step * width ) / total ;

    int percent = ( step * 100 ) / total;
    printf( "%s[", label );
    //fill progress bar with =
    for ( int i = 0; i < pos; i++ )  printf( "%c", '=' );
    //fill progress bar with spaces
    printf( "% *c", width - pos + 1, ']' );
    printf( " %3d%%", percent );
	printf("\r");
	fflush(stdout);

}

void DoSome()
{
    int total = 100;
    int step = 0;

    while ( step <=total )
    {
		usleep(50000);
        DoProgress( "Download: ", step, total );
        step+=1;
    }

    printf( "\n" );

}

int main()
{
    DoSome();

    return 0;
}
