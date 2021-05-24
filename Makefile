TOOL_NAME = crop-scale
VERSION = 0.0.1

PREFIX = /usr/local
INSTALL_PATH = $(PREFIX)/bin/$(TOOL_NAME)
BUILD_PATH = .build/release/$(TOOL_NAME)
TAR_FILENAME = $(TOOL_NAME)-$(VERSION).tar.gz

.PHONY: build

install: build
	install -d "$(PREFIX)/bin"
	install -C -m 755 $(BUILD_PATH) $(INSTALL_PATH)

build:
	swift build --disable-sandbox -c release

uninstall:
	rm -f $(INSTALL_PATH)

lint:
	swiftlint autocorrect --quiet
	swiftlint lint --quiet

get_sha:
	wget https://github.com/doozmen/$(TOOL_NAME)/archive/$(VERSION).tar.gz -O $(TAR_FILENAME)
	shasum -a 256 $(TAR_FILENAME)
	rm $(TAR_FILENAME)
