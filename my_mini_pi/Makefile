UNAME := $(shell uname -m)
ToolPath:="/tools"
downloadSRC:
	sudo apt-get update
	sudo apt-get install g++ make gawk -y
	sudo apt-get install git-core libncurses5-dev vim -y
	sudo apt-get install wget python unzip bc -y
	sudo apt-get install device-tree-compiler -y
	sudo apt-get install gcc-arm-linux-gnueabihf -y
	sudo git clone https://github.com/raspberrypi/tools /tools

env: downloadSRC
ifeq ($(UNAME),x86_64)
	$(shell echo export PATH=$(PATH):$(ToolPath)/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin >> ~/.bashrc)
else
	$(shell echo export PATH=$(PATH):$(ToolPath)/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin >> ~/.bashrc)
endif
	sudo -s source ~/.bashrc
