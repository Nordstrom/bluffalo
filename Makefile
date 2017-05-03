TEMPORARY_FOLDER?=/tmp/Bluffalo.dst
PREFIX?=/usr/local
BUILD_TOOL?=xcodebuild

XCODEFLAGS= DSTROOT=$(TEMPORARY_FOLDER)

BINARIES_FOLDER=$(PREFIX)/bin

BLUFFALO_EXECUTABLE=$(TEMPORARY_FOLDER)/usr/local/bin/Bluffalo


all:
	$(BUILD_TOOL) $(XCODEFLAGS) build

clean:
	rm -rf "$(TEMPORARY_FOLDER)"
	$(BUILD_TOOL) $(XCODEFLAGS) -configuration Debug clean
	$(BUILD_TOOL) $(XCODEFLAGS) -configuration Release clean


uninstall:
	rm -f "$(BINARIES_FOLDER)/bluffalo”

installables: clean
	$(BUILD_TOOL) $(XCODEFLAGS) install

	mkdir -p "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)"
	mv -f "$(BLUFFALO_EXECUTABLE)" "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)/Bluffalo"

prefix_install: installables
	mkdir -p "$(BINARIES_FOLDER)"
	cp -f "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)/Bluffalo" "$(BINARIES_FOLDER)/"
