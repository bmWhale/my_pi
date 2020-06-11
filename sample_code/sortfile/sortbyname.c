#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <dirent.h>
#include <stdlib.h>
#include <limits.h>
#include <sys/stat.h>	
#include <stdbool.h>

#if defined(WIN32) || defined(_WIN32) 
#define PATH_SEPARATOR '\\' 
#else
#define PATH_SEPARATOR '/' 
#endif

struct find_t {
  char name[256];
  uint16_t len; 
  bool is_dir;
};

struct filecount {
  unsigned long dirs;
  unsigned long files;
};

typedef struct find_t FILE_BLOCK ;

int compare(const FILE_BLOCK** a,const FILE_BLOCK** b)
{
	int ret=0;
	uint8_t len_a = strlen((*a)->name);
	uint8_t len_b = strlen((*b)->name);
	if(len_a>len_b)
		return len_a - len_b;
	else if(len_a<len_b)
		return len_a - len_b;
	else
		return strcmp((*a)->name,(*b)->name);
}

void main(int argc,char *argv[])
{
    FILE_BLOCK f_block;        /* Define the find_t structure variable */
    int ret_code;              /* Define a variable to store the return codes */
    FILE_BLOCK ** file_block; /* Used to sort the files */
    int file_count;            /* Used to count the flies */
    int x;                     /* Counter variable */
    file_count = -1;
    FILE_BLOCK** file_list=NULL; /*arr store the pointer of data block*/

    char subpath[PATH_MAX];
    struct filecount counts;
    counts.files = 0;
    counts.dirs = 0;
    char * path =NULL;
    if(argc>1)
	 path = argv[1];
    else
	path=".";

    int isdir;
    struct dirent *ent;
    struct stat statbuf;
    DIR *dir = opendir(path);

    if(NULL==dir){
        perror(path);
	return;
    }
    /* Allocate room to hold up to 512 directory entries.  */
    file_list = (FILE_BLOCK ** ) malloc(sizeof(FILE_BLOCK * ) * 2048);
    printf("\nDirectory listing of all files in this directory ; \n\n");
    while((ent=readdir(dir)))
    {

        isdir = 0;

        sprintf(subpath, "%s%c%s", path, PATH_SEPARATOR, ent->d_name);
        if(lstat(subpath, &statbuf)) {
            perror(subpath);
            return;
        }
        if(S_ISDIR(statbuf.st_mode)) {
            isdir = 1;
        }
	if(isdir)
        {
            if(0 != strcmp("..", ent->d_name) && 0 != strcmp(".", ent->d_name)) {
		counts.dirs++;
	    }
	}
        else
	{
	    counts.files++;
	}
        if(0 != strcmp("..", ent->d_name) && 0 != strcmp(".", ent->d_name))
        {
                /* Add this filename to the file list */
                file_list[++ file_count] = (FILE_BLOCK * ) malloc (sizeof(FILE_BLOCK));
	        memset(file_list[file_count],0,sizeof(FILE_BLOCK));
		if(isdir){
        		snprintf(file_list[file_count]->name,sizeof(file_list[file_count]->name),"%s/",ent->d_name);
			file_list[file_count]->is_dir = true;
		}else{
        		snprintf(file_list[file_count]->name,sizeof(file_list[file_count]->name),"%s",ent->d_name);
			file_list[file_count]->is_dir = false;
		}
	}
	if(file_count>2048)
		break;

   }
   closedir(dir);
   /* Sort the files */
   printf("fileCount:%d\n", file_count+1);
   qsort(file_list, file_count+1, sizeof(FILE_BLOCK * ), compare);
   /* Now, iterate through the sorted array of filenames and print each entry.  */
   printf("list2[%d]:\n", file_count);
   for (x=0; x<=file_count; x++)
   {
       printf("[%d] %-12s, %s\n",x ,file_list[x]->name, file_list[x]->is_dir ? "dir":"file");
   }
   printf("list:end\n");
   printf("\nEnd of directory listing. \n" );
   if(0 < counts.files || 0 < counts.dirs) {
       printf("%s contains %lu files and %lu directories\n", path, counts.files, counts.dirs);
   }
}

