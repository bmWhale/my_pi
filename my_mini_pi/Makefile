UNAME := $(shell uname -m)
ToolPath:="/tools"



defaults:
	$(info "no defaults target")

updatePackages:
	sudo apt-get update
	sudo apt-get install g++ make gawk -y
	sudo apt-get install git-core libncurses5-dev vim -y
	sudo apt-get install wget python unzip bc -y
	sudo apt-get install device-tree-compiler -y
	sudo apt-get install gcc-arm-linux-gnueabihf -y
	sudo git clone https://github.com/raspberrypi/tools /tools

env: updatePackages
ifeq ($(UNAME),x86_64)
	$(shell echo export PATH=$(PATH):$(ToolPath)/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin >> ~/.bashrc)
else
	$(shell echo export PATH=$(PATH):$(ToolPath)/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin >> ~/.bashrc)
endif
	sudo -s source ~/.bashrc
	
cloneSRC:
	git clone git://git.busybox.net/busybox
	git clone --depth=1 https://github.com/raspberrypi/linux
	git clone git://git.denx.de/u-boot.git
	git clone https://github.com/raspberrypi/firmware.git

mkbusy:
	cp configs/.config_busybox_pi2 busybox/.config
	$(MAKE) -C busybox ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-
	$(MAKE) -C busybox install
	cp configs/post_busybox.sh busybox
	cd busybox && sudo ./post_busybox.sh

test:

mkkernel:

mkuboot:

mkall:

