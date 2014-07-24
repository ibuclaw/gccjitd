
SOURCES = gccjit/c.d gccjit/d.d
OBJECTS = gccjit/c.o gccjit/d.o
LIBRARY = libgccjitd.a

AR = ar -r
RM = rm -f

DC = gdc
DFLAGS = -frelease -O2 -g

all: $(LIBRARY)

$(LIBRARY): $(OBJECTS)
	$(AR) $@ $(OBJECTS)
%.o: %.d
	$(DC) $(DFLAGS) -o $@ -c $<
clean:
	$(RM) $(LIBRARY) $(OBJECTS)
