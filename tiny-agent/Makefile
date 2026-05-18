CC      = gcc
CFLAGS  = -Wall -Wextra -std=c99 -g
LDFLAGS = -lutil

SRC = src/pty.c
BIN = build/pty_test

.PHONY: all clean

all: $(BIN)

$(BIN): $(SRC) | build
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

build:
	mkdir -p build

clean:
	rm -rf build
