#!/bin/bash
#
# Copyright (C) 2021 Oscar Wahltinez
# Copyright (C) 2020 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
set -e

# Variables
IMGSIZE=${1:-"8"}

DATE=`date +%Y-%m-%d`
IMGNAME=$DATE-rpi4.img
BUILD_OUTPUT="./out/target/product/rpi4"
KERNEL_VERSION="4525dbb/2021-04-10-rpi4-kernel-5.10-4525dbb"
KERNEL_BINARIES="https://github.com/rpi-atv/kernel_manifest/releases/download/${KERNEL_VERSION}.zip"

if [ `id -u` != 0 ]; then
	echo "Must be root to run script!"
	exit
fi

if [ -f $IMGNAME ]; then
	echo "Overwriting existing image file..."
	rm -rf $IMGNAME
fi

echo "Creating image file $IMGNAME..."
dd if=/dev/zero of=$IMGNAME bs=1M count=$(echo "$IMGSIZE*1024" | bc)
sync
echo "Creating partitions..."
(
echo o
echo n
echo p
echo 1
echo
echo +128M
echo n
echo p
echo 2
echo
echo +1024M
echo n
echo p
echo 3
echo
echo +128M
echo n
echo p
echo
echo
echo t
echo 1
echo c
echo a
echo 1
echo w
) | fdisk $IMGNAME
sync
LOOPDEV=`kpartx -av $IMGNAME | awk 'NR==1{ sub(/p[0-9]$/, "", $3); print $3 }'`
sync
if [ -z "$LOOPDEV" ]; then
	echo "Unable to find loop device!"
	kpartx -d $IMGNAME
	exit
fi
echo "Image mounted as $LOOPDEV"
sleep 5

mkfs.fat -F 32 /dev/mapper/${LOOPDEV}p1 -n boot
mkfs.ext4 /dev/mapper/${LOOPDEV}p2 -L system
mkfs.ext4 /dev/mapper/${LOOPDEV}p3 -L vendor
mkfs.ext4 /dev/mapper/${LOOPDEV}p4 -L userdata
# resize2fs /dev/mapper/${LOOPDEV}p4 1343228
echo "Copying system..."
dd if="$BUILD_OUTPUT/system.img" of=/dev/mapper/${LOOPDEV}p2 bs=1M

echo "Copying vendor..."
dd if="$BUILD_OUTPUT/vendor.img" of=/dev/mapper/${LOOPDEV}p3 bs=1M

echo "Copying boot..."
mkdir -p sdcard/boot
sync
mount /dev/mapper/${LOOPDEV}p1 sdcard/boot
sync
cp device/arpi/rpi4/boot/* sdcard/boot

echo "Copying kernel and ramdisk..."
curl -sSL "$KERNEL_BINARIES" -o /tmp/kernel.zip
rm -rf /tmp/kernel || true
mkdir -p /tmp/kernel && unzip /tmp/kernel.zip -d /tmp/kernel/
mkdir -p sdcard/boot/overlays
cp /tmp/kernel/Image.gz sdcard/boot/
cp /tmp/kernel/bcm2711-rpi-4-b.dtb sdcard/boot/
cp /tmp/kernel/vc4-kms-v3d-pi4.dtbo sdcard/boot/overlays/
cp "$BUILD_OUTPUT/ramdisk.img" sdcard/boot/

sync
umount /dev/mapper/${LOOPDEV}p1
rm -rf sdcard
kpartx -d $IMGNAME
sync
echo "Done, created $IMGNAME!"
