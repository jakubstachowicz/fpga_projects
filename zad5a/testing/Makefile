CC = gcc
CFLAGS = -Wall -O2

TARGET = uart_parser

all: $(TARGET)

$(TARGET): parser.tab.c lex.yy.c
	$(CC) $(CFLAGS) -o $@ $^

parser.tab.c parser.tab.h: parser.y
	bison -d parser.y

lex.yy.c: lexer.l parser.tab.h
	flex lexer.l

clean:
	rm -f parser.tab.c parser.tab.h lex.yy.c $(TARGET)

