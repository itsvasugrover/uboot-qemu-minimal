#!/bin/bash
# qemu.sh - Run QEMU for a built U-Boot binary

BUILD_DIR="build/"

if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: Build directory '$BUILD_DIR' not found."
    echo "Run: ./build.sh first."
    exit 1
fi

echo ">>> Starting QEMU for U-Boot..."
qemu-system-aarch64 -M virt -nographic -cpu cortex-a57 -m 512M -bios "${BUILD_DIR}u-boot.bin"