UNAME := $(shell uname -m)
ToolPath:="/tools"
boot_p="/mnt/boot/"
rtfs_p="/mnt/rtfs/"
overlays_p="$(boot_p)/overlays/"

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
	$(shell echo export PATH=$(PATH):$(ToolPath)/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin >> ~/.bashrc)
else
	$(shell echo export PATH=$(PATH):$(ToolPath)/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin >> ~/.bashrc)
endif
	sudo -s source ~/.bashrc
	
clonesrc:
	git clone git://git.busybox.net/busybox
	git clone --depth=1 https://github.com/raspberrypi/linux
	git clone git://git.denx.de/u-boot.git
	svn export https://github.com/raspberrypi/firmware/trunk/boot firmware
	mkdir glibc
	wget http://ftp.gnu.org/gnu/libc/glibc-2.25.tar.xz -P glibc
		
installsd:
	$(info create output folder)
	mkdir -p output/boot output/rootfs output/boot/overlays
	
	$(info copy busybox)
	sudo cp -rf busybox/_install/* $(rtfs_p)
	
	$(info copy u-boot)
	sudo cp u-boot/u-boot.bin $(boot_p)
	
	$(info copy firmware)
	sudo cp -rf firmware/* $(boot_p)
		
	$(info install glibc)
	cd glibc/glibc-build && sudo make install install_root=$(rtfs_p)

	$(info copy kernel)
	sudo $(MAKE) -C linux ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=$(rtfs_p) modules_install
	sudo linux/scripts/mkknlimg linux/arch/arm/boot/zImage $(boot_p)/kernel7.img 
	sudo cp -rf linux/arch/arm/boot/dts/*.dtb $(boot_p)
	sudo cp -rf linux/arch/arm/boot/dts/overlays/*.dtb* $(overlays_p)
	sudo cp linux/arch/arm/boot/dts/overlays/README $(overlays_p)

	$(info copy cmdline.txt and config.txt)
	sudo cp configs/cmdline.txt configs/config.txt $(boot_p)

	$(info deploy done........)

mkglibc:
	export TARGET=arm-linux-gnueabihf
	cd glibc && tar -xJf glibc-2.25.tar.xz
	mkdir glibc/glibc-build
	cd glibc/glibc-build && ../glibc-2.25/configure $(TARGET) --target=$(TARGET) --build=$(MACHTYPE) --prefix= --enable-add-ons && make	

mkoutput:
	$(info create output folder)
	mkdir -p output/boot output/rootfs output/boot/overlays
	
	$(info copy busybox)
	sudo cp -rf busybox/_install/* output/boot/
	
	$(info copy u-boot)
	sudo cp u-boot/u-boot.bin output/boot/
	
	$(info copy firmware)
	sudo cp -rf firmware/* output/boot/
	
	$(info install glibc)
	cd glibc/glibc-build && make install install_root=output/rootfs

	$(info copy kernel)
	sudo $(MAKE) -C linux ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=output/rootfs modules_install
	sudo linux/scripts/mkknlimg linux/arch/arm/boot/zImage output/boot/kernel7.img 
	sudo cp -rf linux/arch/arm/boot/dts/*.dtb output/boot/
	sudo cp -rf linux/arch/arm/boot/dts/overlays/*.dtb* output/boot/overlays/
	sudo cp linux/arch/arm/boot/dts/overlays/README output/boot/overlays/
	
	$(info deploy done........)
mkbusy:
	cp configs/.config_busybox_pi2 busybox/.config
	$(MAKE) -C busybox ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-
	$(MAKE) -C busybox install
	cp configs/post_busybox.sh busybox
	cd busybox && sudo ./post_busybox.sh

mkkernel:
	$(MAKE) -C linux ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcm2709_defconfig
	$(MAKE) -C linux -j 8 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage modules dtbs

mkuboot:
	$(MAKE) -C u-boot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- rpi_2_defconfig
	$(MAKE) -C u-boot -j 8 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- all

distclean:
	sudo rm -rf linux u-boot busybox firmware output


mkall: clonesrc mkbusy mkkernel mkuboot

	
