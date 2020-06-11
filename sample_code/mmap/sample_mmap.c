#include <unistd.h>
#include <stdio.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <stdlib.h>

typedef struct{
	int integer;
	char string[24];
} RECORD;

#define NRECORDS (100)

int main()
{
	RECORD record, *mapped;
	int i, f;
	FILE *fp;
#if 0
	//1.
	fp = fopen("records.dat","w+");
	for(i=0;i<NRECORDS;i++)
	{
		record.integer = i;
		sprintf(record.string,"RECORD-%d",i);
		printf("record.string: %s\n", record.string);
		fwrite(&record,sizeof(record),1,fp);
	}
	fclose(fp);
#elif 0
	//2.
	fp = fopen("records.dat","r+");
	fseek(fp,43*sizeof(record),SEEK_SET);
	fread(&record,sizeof(record),1,fp);

	record.integer = 143;
	sprintf(record.string,"RECORD-%d",record.integer);

	fseek(fp,43*sizeof(record),SEEK_SET);
	fwrite(&record,sizeof(record),1,fp);
	fclose(fp);
#else
	//3.
	f = open("records.dat",O_RDWR);
	mapped = (RECORD *) mmap(0, NRECORDS*sizeof(record), PROT_READ|PROT_WRITE,MAP_SHARED,f,0);

	mapped[43].integer = 243;
	sprintf(mapped[43].string,"RECORD-%d",mapped[43].integer);

	msync((void *)mapped, NRECORDS*sizeof(record), MS_ASYNC);
	munmap((void*)mapped, NRECORDS*sizeof(record));
	close(f);
#endif
	exit(0);
}
