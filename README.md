# Download Android source with local_manifests
Refer to http://source.android.com/source/downloading.html

```sh
repo init -u https://android.googlesource.com/platform/manifest -b android-s-preview-1
git clone https://github.com/rpi-atv/local_manifests .repo/local_manifests -b arpi-12
repo sync
```

If you are using a filesystem that is not case sensitive (the default in macOS) then you
need to first create a case sensitive disk image, mount it, and download the code there:

```sh
hdiutil create -type SPARSE -fs 'Case-sensitive Journaled HFS+' -size 250g ~/android.dmg.sparseimage
```

Refer to https://source.android.com/setup/build/initializing.

# Patch framework source
From the source code root folder, run:

```sh
git clone https://github.com/rpi-atv/local_manifests arpi-patches -b arpi-12-patches
bash apply_patches.sh
```

# Build Android source
Continue build referring to http://source.android.com/source/building.html

```sh
source build/envsetup.sh
lunch rpi4-eng
make ramdisk systemimage vendorimage
```

Use -j[n] option with make, if build host has a good number of CPU cores.

# Create img file
From the source code root folder, run:

```sh
bash create-image.sh 8
```

This will create a file named `${date}-rpi4.img`.

The argument to the script indicates the size in GB of the resulting image, use a size appropriate
for your SD card.

# Using Docker
Alternatively, you can use Docker to build this project.

```sh
docker pull rpiatv/builder
docker run --memory 16G -v ${PWD}:/root -i rpiatv/builder /bin/bash < ./build.sh
docker run --privileged -v ${PWD}:/root -i rpiatv/builder /bin/bash < ./create-image.sh
```
