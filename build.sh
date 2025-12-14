#!/bin/bash
# build.sh - Configure and Build U-Boot for QEMU ARM64

echo ">>> Initializing U-Boot Build Environment..."

# 0. Check if u-boot directory exists
if [ ! -d "u-boot" ]; then
    echo "Error: U-Boot directory not found. Run setup.sh first."
    exit 1
fi

# 1. Source the environment into a specific build directory
cd u-boot
make ARCH=arm CROSS_COMPILE=aarch64-linux-gnu- distclean
make ARCH=arm CROSS_COMPILE=aarch64-linux-gnu- qemu_arm64_defconfig
make ARCH=arm CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)

echo ">>> U-Boot Build Complete."

# 2. Copy the U-Boot binary to the build directory
mkdir -p ../build
cp u-boot.bin ../build/u-boot.bin

echo ">>> U-Boot binary copied to build directory."