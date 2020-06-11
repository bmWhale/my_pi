#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
int   max_in  = 255, // Top end of INPUT range
      max_out = 255; // Top end of OUTPUT range
int gamma_table[256]={}; 
void gen_gamma(float gamma) {
  printf("const uint8_t PROGMEM gamma[] = {");
  for(int i=0; i<=max_in; i++) {
    if(i > 0) printf(",");
    if((i & 15) == 0) printf("\n  ");
    int val = (int)(pow((float)i / (float)max_in, gamma) * max_out + 0.5);
    printf("%3d",val);
    gamma_table[i]=val;
  }
  printf(" };\n");
}

void gen_file(float gamma)
{
	char file_name[256]={};
	char *p;
	FILE *fp;
	char buf[256]={};

	snprintf(file_name,sizeof(file_name),"gamma_%2.1f",gamma);
	p = strchr(file_name,'.');
	if(p) *p=95;

	printf("Store to file: %s\n", file_name);
	if(!(fp = fopen(file_name,"w")))
		perror("open file error\n");

	for(int i=0; i<(max_out+1);i++)
	{
		snprintf(buf,sizeof(buf),"GammaLEVEL0_%d=0x00%02x%02x%02x\n",i,gamma_table[i],gamma_table[i],gamma_table[i]);
		printf("%s\n", buf);
		fwrite(buf,strlen(buf),1,fp);
	}

	if(fp) fclose(fp);

}

int main(int argc, char * argv[])
{
	float gamma   = 2.0; // Correction factor
	if(!argv[1]) 
		printf("argv1 = NULL; use default gamma 2.0\n");
	else
		gamma = atof(argv[1]);
	printf("Generate gamma = %2.1f\n",gamma );
	gen_gamma(gamma);
	gen_file(gamma);
	printf("Done\n");
}
