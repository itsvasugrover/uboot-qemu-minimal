#!/bin/bash
# build.sh — Configure and build U-Boot for QEMU x86_64.
# Output: build/u-boot.rom    Build log: logs/build.log

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/check-deps.sh
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/scripts/check-deps.sh"

PATCH="patches/0001-x86-Increase-ACPI-table-size-for-Measured-Boot.patch"
BUILD_DIR="build"
LOG_DIR="logs"

echo ""
log_info "Checking build dependencies..."
check_deps make gcc flex bison bc python3 || exit 1
check_python_pkg elftools || exit 1
check_header Python.h openssl/ssl.h gnutls/gnutls.h || exit 1

echo ""
if [ ! -d "u-boot" ]; then
    log_error "U-Boot directory not found. Run ./setup.sh first."
    exit 1
fi

mkdir -p "${LOG_DIR}"
BUILD_LOG="${LOG_DIR}/build.log"
START_TS=$(date +%s)

log_info "Starting U-Boot build for QEMU x86_64..."
log_info "Build log → ${BUILD_LOG}"
echo ""

cd u-boot

log_info "[1/5] Cleaning previous build..."
make ARCH=x86 distclean >> "../${BUILD_LOG}" 2>&1

log_info "[2/5] Applying patches..."
if patch -N -p1 --dry-run < "../${PATCH}" > /dev/null 2>&1; then
    patch -N -p1 < "../${PATCH}" >> "../${BUILD_LOG}" 2>&1
    log_ok  "Patch applied."
else
    log_warn "Patch already applied or not applicable — skipping."
fi

log_info "[3/5] Loading base defconfig (qemu-x86_64)..."
make ARCH=x86 qemu-x86_64_defconfig >> "../${BUILD_LOG}" 2>&1

log_info "[4/5] Merging custom security config..."
./scripts/kconfig/merge_config.sh -m .config "./../config/qemu-x86_64" >> "../${BUILD_LOG}" 2>&1
make olddefconfig >> "../${BUILD_LOG}" 2>&1

log_info "[5/5] Compiling with $(nproc) thread(s)..."
make ARCH=x86 -j"$(nproc)" >> "../${BUILD_LOG}" 2>&1

cd ..

mkdir -p "${BUILD_DIR}"
cp u-boot/u-boot.rom "${BUILD_DIR}/u-boot.rom"

END_TS=$(date +%s)
ELAPSED=$((END_TS - START_TS))
ROM_KB=$(du -k "${BUILD_DIR}/u-boot.rom" | cut -f1)

echo ""
log_ok "Build SUCCESS in ${ELAPSED}s — ${BUILD_DIR}/u-boot.rom: ${ROM_KB} KB"