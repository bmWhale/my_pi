UNAME := $(shell uname -m)
TOOLPATH := /tools
ARCH := arm
TARGET := arm-linux-gnueabihf
GLIBC_V := 2.25
BUSY_VER := 1_31_stable
KERNEL_VER := rpi-4.9.y
UBOOT_VER := v2019.10-rc4

defaults:
		$(info "no defaults target")

updatePackages:
	sudo apt-get update
	sudo apt-get install g++ make gawk -y
	sudo apt-get install git-core libncurses5-dev vim -y
	sudo apt-get install wget python unzip bc -y
	sudo apt-get install device-tree-compiler -y
	sudo apt-get install gcc-arm-linux-gnueabihf -y
	sudo apt-get install subversion -y
	sudo git clone https://github.com/raspberrypi/tools /tools

env: updatePackages
ifeq ($(UNAME),x86_64)
	$(shell echo export PATH=$(PATH):$(TOOLPATH)/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin >> ~/.bashrc)
else
	$(shell echo export PATH=$(PATH):$(TOOLPATH)/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin >> ~/.bashrc)
endif
	sudo -s source ~/.bashrc

clonesrc:
ifeq (,$(wildcard ./busybox))
	git clone git://git.busybox.net/busybox -b $(BUSY_VER)
endif
ifeq (,$(wildcard ./linux))
	git clone --depth=1 https://github.com/raspberrypi/linux -b $(KERNEL_VER)
endif
ifeq (,$(wildcard ./u-boot))
	git clone git://git.denx.de/u-boot.git
	cd u-boot && git checkout tags/$(UBOOT_VER) -b $(UBOOT_VER)
endif
ifeq (,$(wildcard ./firmware))
	svn export https://github.com/raspberrypi/firmware/trunk/boot firmware
endif
ifeq (,$(wildcard ./glibc))
	mkdir glibc
	wget http://ftp.gnu.org/gnu/libc/glibc-$(GLIBC_V).tar.xz -P glibc
endif

install:
	mkdir -p $(RTFS_P) 
	mkdir -p $(BOOT_P)
	$(info remove boot/*)
	rm -r $(BOOT_P)/*
	
	$(info remove rtfs/*)
	rm -r $(RTFS_P)/*
	
	$(info create output folder)
	mkdir -p  $(OVERLAYS_P)
	
	$(info copy busybox)
	cp -rf busybox/_install/* $(RTFS_P)
	
	$(info copy u-boot)
	cp u-boot/u-boot.bin $(BOOT_P)
	
	$(info copy firmware)
	cp -rf firmware/* $(BOOT_P)
		
	$(info install glibc)
	cd glibc/glibc-build && make install install_root=$(RTFS_P)

	$(info copy kernel)
	$(MAKE) -C linux ARCH=$(ARCH) CROSS_COMPILE=$(TARGET)- INSTALL_MOD_PATH=$(RTFS_P) modules_install
	cp linux/arch/arm/boot/zImage $(BOOT_P)
	cp -rf linux/arch/arm/boot/dts/*.dtb $(BOOT_P)
	cp -rf linux/arch/arm/boot/dts/overlays/*.dtb* $(OVERLAYS_P)
	cp linux/arch/arm/boot/dts/overlays/README $(OVERLAYS_P)

	$(info copy cmdline.txt, config.txt and uboot.env)
	cp configs/cmdline.txt configs/config.txt $(BOOT_P)
	cp configs/uboot.env $(BOOT_P)
	$(info deploy done........)

.PHONY:glibc
glibc:
	cd glibc && tar -xJf glibc-$(GLIBC_V).tar.xz
	mkdir glibc/glibc-build
	cd glibc/glibc-build && ../glibc-$(GLIBC_V)/configure $(TARGET) --target=$(TARGET) --build=$(MACHTYPE) --prefix= --enable-add-ons && make	

.PHONY: busybox
busybox:
	$(MAKE) -C busybox ARCH=$(ARCH) CROSS_COMPILE=$(TARGET)- defconfig
	$(MAKE) -C busybox ARCH=$(ARCH) CROSS_COMPILE=$(TARGET)-
	$(MAKE) -C busybox ARCH=$(ARCH) CROSS_COMPILE=$(TARGET)- install

.PHONY: linux
linux:
	$(MAKE) -C linux ARCH=$(ARCH) CROSS_COMPILE=$(TARGET)- bcm2709_defconfig
	$(MAKE) -C linux ARCH=$(ARCH) CROSS_COMPILE=$(TARGET)- zImage modules dtbs

.PHONY: uboot
uboot:
	$(MAKE) -C u-boot ARCH=$(ARCH) CROSS_COMPILE=$(TARGET)- rpi_2_defconfig
	$(MAKE) -C u-boot ARCH=$(ARCH) CROSS_COMPILE=$(TARGET)- all

.PHONY: distclean
distclean:
	rm -r linux u-boot busybox firmware output glibc

.PHONY: clean
clean:
	$(MAKE) -C busybox  clean
	$(MAKE) -C u-boot clean
	$(MAKE) -C linux clean
	rm -r glibc/glibc-build/*
	$(info clean done...)

.PHONY: all
all: clonesrc busybox glibc linux uboot	

.PHONY: gen_img
gen_img:
	mkdir -p output
	cp configs/post_rpi3_img.sh output
	sh output/post_rpi3_img.sh
