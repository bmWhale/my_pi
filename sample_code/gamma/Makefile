CC:=gcc
CFLAGS= -Wall -O -g -lrt -std=c99
OBJS=gamma.o
APP_NAME=gamma
LIBS= -lm -lrt

$(APP_NAME): $(OBJS)
	$(CC) $^ -o $@ $(LIBS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm *.o $(APP_NAME)
