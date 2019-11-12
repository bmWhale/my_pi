#!/bin/bash

#create folders
mkdir -p bin sbin lib etc dev sys proc tmp var opt mnt usr home root media

#create folder and files for etc
cd etc

touch inittab
touch fstab
touch profile
touch passwd
touch group
touch shadow
touch resolv.conf
touch mdev.conf
touch inetd.conf
mkdir rc.d
mkdir init.d
touch init.d/rcS
chmod +x init.d/rcS
mkdir sysconfig
touch sysconfig/HOSTNAME

#add inittab content
echo " 
::sysinit:/etc/init.d/rcS
::askfirst:-/bin/sh
::ctrlaltdel:-/sbin/reboot
::shutdown:/bin/umount -a -r
::restart:/sbin/init" > inittab

# add rcS content
echo "
#!/bin/sh
PATH=/sbin:/bin:/usr/sbin:/usr/bin
runlevel=S
prevlevel=N
umask 022
export PATH runlevel prevlevel
mount -a
mkdir /dev/pts
mount -t devpts devpts /dev/pts
echo /sbin/mdev > /proc/sys/kernel/hotplug
mdev -s
/bin/hostname -F /etc/sysconfig/HOSTNAME
ifconfig eth0 192.168.1.78" >init.d/rcS

# add fstab content
echo "
proc     /proc   proc     defaults 0 0
sysfs    /sys    sysfs    defaults 0 0
tmpfs    /var    tmpfs    defaults 0 0
tmpfs    /tmp    tmpfs    defaults 0 0
tmpfs    /dev    tmpfs    defaults 0 0"> fstab
cd ..

# add device node
cd dev
sudo mknod console c 5 1
#chmod 777 console
sudo mknod null c 1 3
#chmod 777 null
cd ..

