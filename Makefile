PREFIX ?= /usr/local
BINARY = aerospace-workspace-switcher
TESTING_FLAGS = -Xswiftc -F -Xswiftc /Library/Developer/CommandLineTools/Library/Developer/Frameworks \
	-Xlinker -rpath -Xlinker /Library/Developer/CommandLineTools/Library/Developer/Frameworks

.PHONY: install uninstall clean test

$(BINARY): Sources/WorkspaceSwitcherCore/*.swift Sources/aerospace-workspace-switcher/*.swift Package.swift
	swift build -c release
	cp .build/release/$(BINARY) ./$(BINARY)

install: $(BINARY)
	install -d $(PREFIX)/bin
	install -m 755 $(BINARY) $(PREFIX)/bin/$(BINARY)

uninstall:
	rm -f $(PREFIX)/bin/$(BINARY)

test:
	swift test $(TESTING_FLAGS)

clean:
	swift package clean
	rm -f $(BINARY)
