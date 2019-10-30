UNAME := $(shell uname -m)
TOOLPATH := /tools
SD := /dev/sdd
BOOT_P := ./boot
RTFS_P := ./rootfs
OVERLAYS_P := $(BOOT_P)/overlays/
ARCH := arm
TARGET := arm-linux-gnueabihf
GLIBC_V := 2.25
BUSY_VER := 1_26_stable
KERNEL_VER := rpi-4.9.y
UBOOT_VER := v2017.03-rc3
defaults:
		$(info "no defaults target")

mountsd:
	sudo mount $(SD)1 $(BOOT_P)
	sudo mount $(SD)2 $(RTFS_P)

umountsd:
	sudo umount $(SD)1 
	sudo umount $(SD)2

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
	git clone git://git.busybox.net/busybox -b $(BUSY_VER)
	git clone --depth=1 https://github.com/raspberrypi/linux -b $(KERNEL_VER)	
	git clone git://git.denx.de/u-boot.git
	cd u-boot && git checkout tags/$(UBOOT_VER) -b $(UBOOT_VER)
	svn export https://github.com/raspberrypi/firmware/trunk/boot firmware
	mkdir glibc
	wget http://ftp.gnu.org/gnu/libc/glibc-$(GLIBC_V).tar.xz -P glibc
		
install:
	mkdir -p $(RTFS_P) 
	mkdir -p $(BOOT_P)
	$(info remove boot/*)
	rm -rf $(BOOT_P)/*
	
	$(info remove rtfs/*)
	rm -rf $(RTFS_P)/*
	
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

mkglibc:
	cd glibc && tar -xJf glibc-$(GLIBC_V).tar.xz
	mkdir glibc/glibc-build
	cd glibc/glibc-build && ../glibc-$(GLIBC_V)/configure $(TARGET) --target=$(TARGET) --build=$(MACHTYPE) --prefix= --enable-add-ons && make	

mkbusy:
	$(MAKE) -C busybox ARCH=$(ARCH) CROSS_COMPILE=$(TARGET)- defconfig
	$(MAKE) -C busybox ARCH=$(ARCH) CROSS_COMPILE=$(TARGET)-
	$(MAKE) -C busybox ARCH=$(ARCH) CROSS_COMPILE=$(TARGET)- install
	cp configs/post_busybox.sh busybox
	cd busybox && ./post_busybox.sh

mkkernel:
	$(MAKE) -C linux ARCH=$(ARCH) CROSS_COMPILE=$(TARGET)- bcm2709_defconfig
	$(MAKE) -C linux ARCH=$(ARCH) CROSS_COMPILE=$(TARGET)- zImage modules dtbs

mkuboot:
	$(MAKE) -C u-boot ARCH=$(ARCH) CROSS_COMPILE=$(TARGET)- rpi_2_defconfig
	$(MAKE) -C u-boot ARCH=$(ARCH) CROSS_COMPILE=$(TARGET)- all

distclean:
	sudo rm -rf linux u-boot busybox firmware output glibc

clean:
	sudo $(MAKE) -C busybox  clean
	sudo $(MAKE) -C u-boot clean
	sudo $(MAKE) -C linux clean
	sudo rm -rf glibc/glibc-build/*
	$(info clean done...)	
mkall: clonesrc mkbusy mkglibc mkkernel mkuboot

	
