Create a minimal Linux System for Raspberry pi

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
- TOOLPATH
default is 『/tools』

Boot section:   
- BOOT_P
default is 『/mnt/boot』

Rootfs section:   
- RTFS_P
default is  『/mnt/rtfs』

## setup  
make env

## download and make all
make mkall

## install to SD card  
make install
