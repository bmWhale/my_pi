Create a minimal Linux System for Raspberry pi 2

# Usage


## modify Version  
If you wanna change the version/branch of any component, just modify 4 variables in Makefile   
- GLIBC_V
- BUSY_VER
- KERNEL_VER
- BOOT_VER

Current versions are :   
- GLIBC_V := 2.25
- BUSY_VER := 1_26_stable
- KERNEL_VER := rpi-4.9.y
- UBOOT_VER := v2017.03-rc3

## Some default paths:      
Kernel toolchain path:   
- TOOLPATH <br>
default is 『/tools』

Boot section:   
- BOOT_P <br>
default is 『/mnt/boot』

Rootfs section:   
- RTFS_P <br>
default is  『/mnt/rtfs』

SD card:
- SD <br>
default is 『/dev/sdd』

## setup  
This target will install all the development tools and toolchains for this project.
```
sudo make env
```

## download and make all
This target will clone all projects(busybox, kernel, u-boot, rpi firwarm, glibc) as spicific versions/branches, and build all projects as architecture - 『arm』 and ABI - 『arm-linux-gnueabihf』.
```
make mkall
```

## install to SD card  
Install all needed conmponents to your SD card.
```
sudo make install
```

## mount and umount SD card
Just for my convenience in developing this project.
```
sudo make mountsd
sudo make umountsd
```




