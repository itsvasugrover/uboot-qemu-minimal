#!/bin/bash
# setup.sh - Download dependencies


echo ">>> Setting up U-Boot Build Environment..."

# Clone U-Boot repository
if [ ! -d "u-boot" ]; then
    echo "Cloning U-Boot repository..."
    git clone -b v2025.10 --depth 1 https://github.com/u-boot/u-boot.git
else
    echo "U-Boot repository already exists."
fi


echo ">>> Setup complete."