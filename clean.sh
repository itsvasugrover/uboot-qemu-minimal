#!/bin/bash
# clean.sh - Clean build directories

echo ">>> Removing entire u-boot directory..."
rm -rf u-boot/
echo ">>> Removing build directory..."
rm -rf build/
echo ">>> Removing logs directory..."
rm -rf logs/
echo ">>> Cleanup complete."