
# Directory to install toolchain to, by default inside current dir.
TOOLCHAIN = $(TOP)/xtensa-lx106-elf


# Vendor SDK version to install, see VENDOR_SDK_ZIP_* vars below
# for supported versions.
#VENDOR_SDK = git
VENDOR_SDK = 1.5.4

.PHONY: crosstool-NG toolchain sdk


TOP = $(PWD)
SHELL = /bin/bash
PATCH = patch -b -N
UNZIP = unzip -q -o
SED = gsed
VENDOR_SDK_ZIP = $(VENDOR_SDK_ZIP_$(VENDOR_SDK))
VENDOR_SDK_DIR = $(VENDOR_SDK_DIR_$(VENDOR_SDK))

VENDOR_SDK_DIR_git = ESP8266_NONOS_SDK-git
VENDOR_SDK_ZIP_1.5.4 = ESP8266_NONOS_SDK_V1.5.4_16_05_20.zip
VENDOR_SDK_DIR_1.5.4 = ESP8266_NONOS_SDK_V1.5.4_16_05_20



all: esptool standalone sdk sdk_patch $(TOOLCHAIN)/bin/xtensa-lx106-elf-gcc
	@echo
	@echo "Xtensa toolchain is built, to use it:"
	@echo
	@echo 'export PATH=$(TOOLCHAIN)/bin:$$PATH'
	@echo
	@echo "Espressif ESP8266 SDK is installed, its libraries and headers are merged with the toolchain"
	@echo

standalone: sdk sdk_patch toolchain
	@echo "Installing vendor SDK headers into toolchain sysroot"
	@cp -Rf sdk/include/* $(TOOLCHAIN)/xtensa-lx106-elf/sysroot/usr/include/
	@echo "Installing vendor SDK libs into toolchain sysroot"
	@cp -Rf sdk/lib/* $(TOOLCHAIN)/xtensa-lx106-elf/sysroot/usr/lib/
	@echo "Installing vendor SDK linker scripts into toolchain sysroot"
	@$(SED) -e 's/\r//' sdk/ld/eagle.app.v6.ld | sed -e 's|0x40240000, len = 0x3C000|0x40210000, len = 0x6C000|' | sed -e s@../ld/@@ >$(TOOLCHAIN)/xtensa-lx106-elf/sysroot/usr/lib/eagle.app.v6.ld
	@$(SED) -e 's/\r//' sdk/ld/eagle.app.v6.new.1024.app1.ld | sed -e s@../ld/@@ >$(TOOLCHAIN)/xtensa-lx106-elf/sysroot/usr/lib/eagle.app.v6.new.1024.app1.ld
	@$(SED) -e 's/\r//' sdk/ld/eagle.app.v6.new.1024.app2.ld | sed -e s@../ld/@@ >$(TOOLCHAIN)/xtensa-lx106-elf/sysroot/usr/lib/eagle.app.v6.new.1024.app2.ld
	@$(SED) -e 's/\r//' sdk/ld/eagle.app.v6.new.2048.ld | sed -e s@../ld/@@ >$(TOOLCHAIN)/xtensa-lx106-elf/sysroot/usr/lib/eagle.app.v6.new.2048.ld
	@$(SED) -e 's/\r//' sdk/ld/eagle.app.v6.new.512.app1.ld | sed -e s@../ld/@@ >$(TOOLCHAIN)/xtensa-lx106-elf/sysroot/usr/lib/eagle.app.v6.new.512.app1.ld
	@$(SED) -e 's/\r//' sdk/ld/eagle.app.v6.new.512.app2.ld | sed -e s@../ld/@@ >$(TOOLCHAIN)/xtensa-lx106-elf/sysroot/usr/lib/eagle.app.v6.new.512.app2.ld
	@$(SED) -e 's/\r//' sdk/ld/eagle.app.v6.old.1024.app1.ld | sed -e s@../ld/@@ >$(TOOLCHAIN)/xtensa-lx106-elf/sysroot/usr/lib/eagle.app.v6.old.1024.app1.ld
	@$(SED) -e 's/\r//' sdk/ld/eagle.app.v6.old.1024.app2.ld | sed -e s@../ld/@@ >$(TOOLCHAIN)/xtensa-lx106-elf/sysroot/usr/lib/eagle.app.v6.old.1024.app2.ld
	@$(SED) -e 's/\r//' sdk/ld/eagle.app.v6.old.512.app1.ld | sed -e s@../ld/@@ >$(TOOLCHAIN)/xtensa-lx106-elf/sysroot/usr/lib/eagle.app.v6.old.512.app1.ld
	@$(SED) -e 's/\r//' sdk/ld/eagle.app.v6.old.512.app2.ld | sed -e s@../ld/@@ >$(TOOLCHAIN)/xtensa-lx106-elf/sysroot/usr/lib/eagle.app.v6.old.512.app2.ld
	@$(SED) -e 's/\r//' sdk/ld/eagle.rom.addr.v6.ld >$(TOOLCHAIN)/xtensa-lx106-elf/sysroot/usr/lib/eagle.rom.addr.v6.ld
	@cp $(VENDOR_SDK_DIR)/tools/gen_appbin.py $(TOOLCHAIN)/bin/
	@chmod +x $(TOOLCHAIN)/bin/gen_appbin.py

clean: clean-sdk
	$(MAKE) -C crosstool-NG clean MAKELEVEL=0
	-rm -rf crosstool-NG/.build/src
	-rm -f crosstool-NG/local-patches/gcc/4.8.5/1000-*
	-rm -rf $(TOOLCHAIN)

clean-sdk:
	rm -rf $(VENDOR_SDK_DIR)
	rm -f sdk
	rm -f .sdk_patch_$(VENDOR_SDK)

clean-sysroot:
	rm -rf $(TOOLCHAIN)/xtensa-lx106-elf/sysroot/usr/lib/*
	rm -rf $(TOOLCHAIN)/xtensa-lx106-elf/sysroot/usr/include/*


esptool: toolchain
	cp esptool/esptool.py $(TOOLCHAIN)/bin/

toolchain: $(TOOLCHAIN)/bin/xtensa-lx106-elf-gcc

$(TOOLCHAIN)/bin/xtensa-lx106-elf-gcc: crosstool-NG/ct-ng
	cp -f 1000-mforce-l32.patch crosstool-NG/local-patches/gcc/4.8.5/
	$(MAKE) -C crosstool-NG -f ../Makefile _toolchain

_toolchain:
	./ct-ng xtensa-lx106-elf
	$(SED) -r -i.org s%CT_PREFIX_DIR=.*%CT_PREFIX_DIR="$(TOOLCHAIN)"% .config
	$(SED) -r -i s%CT_INSTALL_DIR_RO=y%"#"CT_INSTALL_DIR_RO=y% .config
	cat ../crosstool-config-overrides >> .config
	./ct-ng build


crosstool-NG: crosstool-NG/ct-ng

crosstool-NG/ct-ng: crosstool-NG/bootstrap
	$(MAKE) -C crosstool-NG -f ../Makefile _ct-ng

_ct-ng:
	./bootstrap
	./configure --prefix=`pwd`
	$(MAKE) MAKELEVEL=0
	$(MAKE) install MAKELEVEL=0

crosstool-NG/bootstrap:
	@echo "You cloned without --recursive, fetching submodules for you."
	git submodule update --init --recursive

sdk: $(VENDOR_SDK_DIR)/.dir
	ln -snf $(VENDOR_SDK_DIR) sdk

$(VENDOR_SDK_DIR)/.dir: $(VENDOR_SDK_ZIP)
	$(UNZIP) $^
	-mv License $(VENDOR_SDK_DIR)
	touch $@


$(VENDOR_SDK_DIR_git)/.dir:
	touch $@

$(VENDOR_SDK_DIR_1.5.4)/.dir: $(VENDOR_SDK_ZIP_1.5.4)
	$(UNZIP) $^
	mv ESP8266_NONOS_SDK $(VENDOR_SDK_DIR_1.5.4)
	rm release_note.txt
	touch $@

sdk_patch: $(VENDOR_SDK_DIR)/.dir .sdk_patch_$(VENDOR_SDK)

.sdk_patch_git:
	$(PATCH) -d $(VENDOR_SDK_DIR) -p1 < c_types-c99_sdk_2.patch
	@touch $@

.sdk_patch_1.5.4:
	$(PATCH) -d $(VENDOR_SDK_DIR) -p1 < c_types-c99.patch
	@touch $@

ESP8266_NONOS_SDK_V1.5.4_16_05_20.zip:
	wget --content-disposition "http://bbs.espressif.com/download/file.php?id=1469"
