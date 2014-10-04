#!/bin/bash 

export packages="nmap openssh-server mc sudo gcc make autoconf autoheader"
export architecture="armel"
export dist="squeeze"
export LOGIN=`whoami`
sudo apt-get install debootstrap qemu-kvm qemu-system-arm
sudo su

cd ~
mkdir -p arm-stuff
cd arm-stuff/
#mkdir -p kernel
mkdir -p rootfs
cd rootfs

###  1   ####
sudo debootstrap --foreign --arch $architecture $dist $dist-$architecture http://mirror.yandex.ru/debian
cp /usr/bin/qemu-arm-static $dist-$architecture/usr/bin/

### 2    ####
cd ~/arm-stuff/rootfs
LANG=C chroot $dist-$architecture /debootstrap/debootstrap --second-stage

cat << EOF > $dist-$architecture/etc/apt/sources.list
deb http://ftp.ru.debian.org/debian  $dist main contrib non-free
deb http://security.debian.org/ $dist/updates main contrib non-free
EOF

echo "NAS-$dist" > $dist-$architecture/etc/hostname

cat << EOF > $dist-$architecture/etc/network/interfaces
auto lo
iface lo inet loopback
auto eth0
iface eth0 inet dhcp
EOF

cat << EOF > $dist-$architecture/etc/resolv.conf
nameserver 192.168.1.1
nameserver 8.8.8.8
EOF

###  3  ########

export MALLOC_CHECK_=0 # workaround for LP: #520465
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive

mount -t proc proc $dist-$architecture/proc
mount -o bind /dev/ $dist-$architecture/dev/
mount -o bind /dev/pts $dist-$architecture/dev/pts

cat << EOF > $dist-$architecture/debconf.set
console-common console-data/keymap/policy select Select keymap from full list
console-common console-data/keymap/full select en-latin1-nodeadkeys
EOF

cat << EOF > $dist-$architecture/third-stage
#!/bin/bash
#dpkg-divert --add --local --divert /usr/sbin/invoke-rc.d.chroot --rename /usr/sbin/invoke-rc.d
#cp /bin/true /usr/sbin/invoke-rc.d

apt-get update
apt-get install locales-all
#locale-gen ru_RU.UTF-8

debconf-set-selections /debconf.set
rm -f /debconf.set
apt-get update
apt-get -y install git-core binutils ca-certificates initramfs-tools uboot-mkimage
apt-get -y install locales console-common less nano git
echo "root:toor" | chpasswd
sed -i -e 's/KERNEL!="eth*|/KERNEL!="/' /lib/udev/rules.d/75-persistent-net-generator.rules
rm -f /etc/udev/rules.d/70-persistent-net.rules
apt-get --yes --force-yes install $packages

#rm -f /usr/sbin/invoke-rc.d
#dpkg-divert --remove --rename /usr/sbin/invoke-rc.d

rm -f /third-stage
EOF

chmod +x $dist-$architecture/third-stage
LANG=C chroot $dist-$architecture /third-stage

###  cleanup ###

cat << EOF > $dist-$architecture/cleanup
#!/bin/bash
rm -rf /root/.bash_history
apt-get update
apt-get clean
mkdir -p /home/$LOGIN
rm -f cleanup
EOF

chmod +x $dist-$architecture/cleanup
LANG=C chroot $dist-$architecture /cleanup
##############


umount $dist-$architecture/proc
umount $dist-$architecture/dev/pts
umount $dist-$architecture/dev/

cd ..
