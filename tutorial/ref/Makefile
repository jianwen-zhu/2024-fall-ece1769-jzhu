CC=g++
CFLAGS=-c -Wall
LDFLAGS=
SOURCES=dot_prod.c dot_prod_tb.c
OBJECTS=$(SOURCES:.cpp=.o)
EXECUTABLE=dot_prod

all: $(SOURCES) $(EXECUTABLE)
    
$(EXECUTABLE): $(OBJECTS)
	$(CC) $(LDFLAGS) $(OBJECTS) -o $@

.cpp.o:
	$(CC) $(CFLAGS) $< -o $@
