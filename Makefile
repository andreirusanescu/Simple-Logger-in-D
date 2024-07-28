DMD = dmd
DFLAGS = -unittest -main

BINARY = logger

all: $(BINARY)

$(BINARY): $(BINARY).d
	$(DMD) $(DFLAGS) $(BINARY).d

clean:
	rm -f $(BINARY) $(BINARY).o
