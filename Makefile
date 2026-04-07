PREFIX ?= /usr/local
BINARY = aerospace-workspace-switcher

.PHONY: install uninstall clean

$(BINARY): main.swift
	swiftc -O -o $(BINARY) main.swift -framework AppKit -framework Carbon

install: $(BINARY)
	install -d $(PREFIX)/bin
	install -m 755 $(BINARY) $(PREFIX)/bin/$(BINARY)

uninstall:
	rm -f $(PREFIX)/bin/$(BINARY)

clean:
	rm -f $(BINARY)
