#!/bin/bash
set -xe

# Sync repo
repo init -u https://android.googlesource.com/platform/manifest -b android-11.0.0_r33
rm -rf .repo/local_manifests || true
git clone https://github.com/owahltinez/local_manifests .repo/local_manifests -b arpi-11
repo sync -j$(nproc)

# Patch the source
rm -rf arpi-patches || true
git clone https://github.com/owahltinez/device_arpi_rpi4 arpi-patches -b arpi-11-patches
bash .repo/local_manifests/apply_patches.sh $PWD arpi-patches

# Build Android
source build/envsetup.sh
lunch rpi4-eng
make ramdisk systemimage vendorimage -j$(nproc)
