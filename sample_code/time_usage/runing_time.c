#include <stdlib.h>
#include <stdio.h>
#include <time.h>

struct timespec diff(struct timespec start, struct timespec end) {
  struct timespec temp;
  if ((end.tv_nsec-start.tv_nsec)<0) {
    temp.tv_sec = end.tv_sec-start.tv_sec-1;
    temp.tv_nsec = 1000000000+end.tv_nsec-start.tv_nsec;
  } else {
    temp.tv_sec = end.tv_sec-start.tv_sec;
    temp.tv_nsec = end.tv_nsec-start.tv_nsec;
  }
  return temp;
}

void print_time_usage(struct timespec start, struct timespec end)
{
  double time_used;
  struct timespec temp;
  temp = diff(start, end);
  time_used = temp.tv_sec + (double) temp.tv_nsec / 1000000000.0;

  printf("Time = %f\n", time_used);

}

void get_time(struct timespec * time)
{
	clock_gettime(CLOCK_MONOTONIC, time);
}
