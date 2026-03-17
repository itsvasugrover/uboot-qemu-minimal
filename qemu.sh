#!/bin/bash
# qemu.sh - Run QEMU with automated swtpm and logging

BUILD_DIR="build/"
LOG_DIR="logs/"
TPM_DIR="/tmp/tpm0"
TPM_SOCK="${TPM_DIR}-sock"

# Ensure directories exist
mkdir -p "$BUILD_DIR"
mkdir -p "$LOG_DIR"
mkdir -p "$TPM_DIR"

if [ ! -f "${BUILD_DIR}u-boot.rom" ]; then
    echo "Error: u-boot.rom not found. Run ./build.sh first."
    exit 1
fi

# Clean up any orphaned socket from a previous bad shutdown
rm -rf "$TPM_SOCK"

echo ">>> Starting swtpm in the background..."
swtpm socket \
  --tpmstate dir="$TPM_DIR" \
  --ctrl type=unixio,path="$TPM_SOCK" \
  --tpm2 \
  --log level=10 > "${LOG_DIR}swtpm.log" 2>&1 &
SWTPM_PID=$!

# Give swtpm a second to initialize the socket
sleep 1

echo ">>> Starting QEMU for U-Boot..."
qemu-system-x86_64 \
  -enable-kvm \
  -cpu host \
  -nographic \
  -m 512M \
  -smp 1 \
  -nic none \
  -no-reboot \
  -bios "${BUILD_DIR}u-boot.rom" \
  -chardev socket,id=chrtpm,path="$TPM_SOCK" \
  -tpmdev emulator,id=tpm0,chardev=chrtpm \
  -device tpm-tis,tpmdev=tpm0 \
  -d cpu_reset,int \
  -D "${LOG_DIR}qemu.log"

# Cleanup happens automatically when QEMU exits or is killed
echo ">>> QEMU exited. Cleaning up swtpm (PID: $SWTPM_PID)..."
kill $SWTPM_PID 2>/dev/null
rm -f "$TPM_SOCK"
echo ">>> Done. Logs saved in ${LOG_DIR}."