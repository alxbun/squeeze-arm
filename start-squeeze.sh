#!/bin/bash 

export architecture="armel"
export dist="squeeze"
export MALLOC_CHECK_=0 # workaround for LP: #520465
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive

cd ~/arm-stuff/rootfs


sudo mount -t proc proc $dist-$architecture/proc
sudo mount -o bind /dev/ $dist-$architecture/dev/
sudo mount -o bind /dev/pts $dist-$architecture/dev/pts

LANG=C sudo chroot $dist-$architecture /bin/bash


sudo umount $dist-$architecture/proc
sudo umount $dist-$architecture/dev/pts
sudo umount $dist-$architecture/dev/

cd ..