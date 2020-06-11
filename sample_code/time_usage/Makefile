INCLUDE_PATH?=.
CFLAGS?=-Wall -g -O
LIBS?= -lrt
CC?=gcc

SOURCE = $(wildcard *.c)
OBJS = $(patsubst %.c,%.o,$(SOURCE))

APP_NAME=test

.PHONY: all clean

all: $(APP_NAME)

$(APP_NAME): $(OBJS)
	$(CC) $(OBJS) $(LIBS) -o $@ $^

%.o: %.c
	$(CC) -I$(INCLUDE_PATH) $(CFLAGS) -c -o $@ $<
clean:
	rm -r *.o $(APP_NAME) 
