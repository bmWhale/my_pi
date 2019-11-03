#!/bin/sh
bootfsImg="bootfs.img"
rootfsImg="rootfs.img"
fwImg="rpi-3-ext4-sysupgrade.img.gz"
localBootfs="./bootfs/"
localRootfs="./rootfs/"
mntBootfs="./mntbootfs"
mntRootfs="./mntrootfs"

uid=$(id -u)
gid=$(id -g)

rm $bootfsImg 
mkfs.vfat -C $bootfsImg 40960
echo "
sudo mount -t vfat -o loop -o user,rw,auto,umask=0000,uid=$uid,gid=$gid,iocharset=utf8 ${bootfsImg} ${mntBootfs}
"
sudo mount -t vfat -o loop -o user,rw,auto,umask=0000,uid=$uid,gid=$gid,iocharset=utf8 ${bootfsImg} ${mntBootfs}
cp -fr ${localBootfs}* ${mntBootfs}
sudo umount ${mntBootfs}

rm $rootfsImg
dd if=/dev/zero of=$rootfsImg bs=134217728 count=1;
mkfs.ext4 -F -m0 $rootfsImg
echo "sudo mount -t ext4 -o loop ${rootfsImg} ${mntRootfs}"
sudo mount -t ext4 -o loop ${rootfsImg} ${mntRootfs}
cp -fr ${localRootfs}* ${mntRootfs}
sudo umount ${mntRootfs}
#mcopy -i $bootImg ${boot}COPYING.linux ::
#mcopy -i $bootImg ${boot}bootcode.bin ::
#mcopy -i $bootImg ${boot}start.elf ::
#mcopy -i $bootImg ${boot}start_cd.elf ::
#mcopy -i $bootImg ${boot}start_x.elf ::
#mcopy -i $bootImg ${boot}fixup.dat ::
#mcopy -i $bootImg ${boot}fixup_cd.dat ::
#mcopy -i $bootImg ${boot}fixup_x.dat ::
#mcopy -i $bootImg ${boot}cmdline.txt ::
#mcopy -i $bootImg ${boot}config.txt ::
#mcopy -i $bootImg ${boot}zImage ::

~/bin/ptgen -o ${fwImg} -h 4 -s 63 -l 4096 -t c -p 20M -t 83 -p 128M

BOOTOFFSET="$(( 4194304/ 512))"
BOOTSIZE="$(( 20971520/ 512))"
ROOTFSOFFSET="$((29360128/ 512))"
ROOTFSSIZE="$((134217728/ 512))"

echo "dd bs=512 if=$bootfsImg of=${fwImg} seek=$BOOTOFFSET conv=notrunc"
dd bs=512 if=./$bootfsImg of=./${fwImg} seek=$BOOTOFFSET conv=notrunc
echo "dd bs=512 if=$rootfsImg of=${fwImg} seek=$ROOTFSOFFSET conv=notrunc"
dd bs=512 if=$rootfsImg of=${fwImg} seek=$ROOTFSOFFSET conv=notrunc
echo "image done"
#gzip -f -9n -c $fwImg

