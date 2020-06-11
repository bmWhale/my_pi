#include <sys/types.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <linux/fs.h>

int main(void)
{
    pid_t pid;
    int i;

    /* create new process */
    pid = fork();
    if(pid == -1)
        return -1;
    else if(pid != 0)
        exit(EXIT_SUCCESS);

    /* create new session and process group */
    //if(setsid() == -1)
    //    return -1;

    /* set the working directory to the root directory */
    if(chdir("/") == -1)
        return -1;
    int maxfd = sysconf(_SC_OPEN_MAX);
    /* close all open files --NR_OPEN is overkill, but works */
    for(i = 0; i < maxfd ; i++) close(i);

    /* redirect fd's 0,1,2 to /dev/null */
    open("/dev/null", O_RDWR); /* stdin */
    dup(0);                    /* stdout */
    dup(0);                    /* stderr */

    /* do its daemon thing ... */
    for(;;) sleep(1);
    return 0;
}
