#!/bin/sh
TOP=`pwd`
OUTPUT="${TOP}/output"
bootfsImg="${OUTPUT}/bootfs.img"
rootfsImg="${OUTPUT}/rootfs.img"
RTFS_P="${OUTPUT}/rootfs"
BOOT_P="${OUTPUT}/bootfs"
OVERLAYS_P="${BOOT_P}/overlays"
fwImg="${OUTPUT}/rpi-3-ext4-sysupgrade.img"
ARCH=arm
TARGET=arm-linux-gnueabihf

uid=$(id -u)
gid=$(id -g)

umount_img()
{
	echo "umount ${BOOT_P}"
	sudo /bin/umount ${BOOT_P}
	echo "umount ${RTFS_P}"
	sudo /bin/umount ${RTFS_P}
}

mount_img()
{
    mkdir -p ${RTFS_P} 
    mkdir -p ${BOOT_P}
    mkdir -p  ${OVERLAYS_P}
	mkfs.vfat -C $bootfsImg 40960
	dd if=/dev/zero of=$rootfsImg bs=262144 count=1024;
	mkfs.ext4 -L my_os -E root_owner=$uid:$gid $rootfsImg

	echo "sudo /bin/mount -t vfat -o loop -o user,rw,auto,umask=0000,uid=$uid,gid=$gid,iocharset=utf8 ${bootfsImg} ${BOOT_P}"
	sudo /bin/mount -t vfat -o loop -o user,rw,auto,umask=0000,uid=$uid,gid=$gid,iocharset=utf8 ${bootfsImg} ${BOOT_P}
	echo "sudo /bin/mount -t ext4 -o loop ${rootfsImg} ${RTFS_P}"
	sudo /bin/mount -t ext4 -o loop ${rootfsImg} ${RTFS_P}
	echo "~/bin/ptgen -o ${fwImg} -h 4 -s 63 -l 4096 -t c -p 40M -t 83 -p 256M"
	~/bin/ptgen -o ${fwImg} -h 4 -s 63 -l 4096 -t c -p 40M -t 83 -p 256M
}

dd_img()
{
	BOOTOFFSET="$(( 4*1024*1024/ 512))"
	BOOTSIZE="$(( 40*1024*1024/ 512))"
	ROOTFSOFFSET="$(((4+4+40)*1024*1024/512))"
	ROOTFSSIZE="$((268435456/ 512))"

	echo "dd bs=512 if=$bootfsImg of=${fwImg} seek=$BOOTOFFSET conv=notrunc"
	dd bs=512 if=$bootfsImg of=${fwImg} seek=$BOOTOFFSET conv=notrunc
	echo "dd bs=512 if=$rootfsImg of=${fwImg} seek=$ROOTFSOFFSET conv=notrunc"
	dd bs=512 if=$rootfsImg of=${fwImg} seek=$ROOTFSOFFSET conv=notrunc
	gzip -f -9n -c $fwImg > ${fwImg}.gz
	echo "image done"
}

install_img()
{

    echo "copy busybox"
    cp -rf busybox/_install/* ${RTFS_P}
	cp configs/post_busybox.sh ${RTFS_P}
	cd ${RTFS_P} && ./post_busybox.sh
	rm ${RTFS_P}/post_busybox.sh
	cd ${TOP}
    
    echo "copy u-boot"
    cp u-boot/u-boot.bin ${BOOT_P}
    
    echo "copy firmware"
    cp firmware/bcm2710-rpi-cm3.dtb ${BOOT_P}
    cp firmware/bcm2710-rpi-3-b-plus.dtb ${BOOT_P}
    #cp firmware/bcm2710-rpi-3-b.dtb ${BOOT_P}
    cp firmware/bootcode.bin ${BOOT_P}
    cp firmware/fixup.dat ${BOOT_P}
    cp firmware/start.elf ${BOOT_P}

    echo "install glibc"
    cd glibc/glibc-build && make install install_root=${RTFS_P}
	cd ${TOP}

    echo "copy kernel"
    make -C linux ARCH=${ARCH} CROSS_COMPILE=${TARGET}- INSTALL_MOD_PATH=${RTFS_P} modules_install
    cp linux/arch/arm/boot/zImage ${BOOT_P}
    #cp -rf linux/arch/arm/boot/dts/*.dtb ${BOOT_P}
    #cp -rf linux/arch/arm/boot/dts/overlays/*.dtb* ${OVERLAYS_P}
    #cp linux/arch/arm/boot/dts/overlays/README ${OVERLAYS_P}

    echo "copy cmdline.txt, config.txt and uboot.env"
    cp configs/cmdline.txt configs/config.txt ${BOOT_P}
    cp configs/uboot.env ${BOOT_P}
    cp configs/bcm2710-rpi-3-b-bt-miniuart.dtb ${BOOT_P}/bcm2710-rpi-3-b.dtb
    echo "deploy done........"
}

####main####
mount_img
install_img
umount_img
dd_img
