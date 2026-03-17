#!/bin/bash
# build.sh - Configure and Build U-Boot for QEMU x86_64

# Stop execution if any command fails
set -e

echo ">>> Initializing U-Boot Build Environment..."

# 0. Check if u-boot directory exists
if [ ! -d "u-boot" ]; then
    echo "Error: U-Boot directory not found. Run setup.sh first."
    exit 1
fi

# 1. Source the environment into a specific build directory
cd u-boot
make ARCH=x86 distclean
patch -N -p1 < ../patches/0001-x86-Increase-ACPI-table-size-for-Measured-Boot.patch || true
make ARCH=x86 qemu-x86_64_defconfig
./scripts/kconfig/merge_config.sh -m .config ./../config/qemu-x86_64
make olddefconfig
make ARCH=x86 -j$(nproc)

echo ">>> U-Boot Build Complete."

# 2. Copy the U-Boot binary to the build directory
mkdir -p ../build
cp u-boot.rom ../build/u-boot.rom

echo ">>> U-Boot binary copied to build directory."