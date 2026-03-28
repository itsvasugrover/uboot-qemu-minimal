#!/bin/bash
# embed-key.sh — Sign a FIT image, embed the public certificate into the
#                U-Boot DTB, and re-link U-Boot so the certificate is baked
#                into the ROM. Run this AFTER ./build.sh and
#                ./scripts/make-demo-fit.sh.
#
# Usage: ./scripts/embed-key.sh [key-name]   (default: dev)
#
# The key-name MUST match the one passed to ./scripts/make-demo-fit.sh so
# that the key-name-hint written into the ITS matches the key used to sign.
#
# Prerequisites:
#   keys/<name>.key   — from ./scripts/gen-keys.sh [key-name]
#   build/boot.itb    — from ./scripts/make-demo-fit.sh [key-name]
#   u-boot/u-boot.dtb — from ./build.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/check-deps.sh
# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/check-deps.sh"

KEY_NAME="${1:-dev}"
KEYS_DIR="${REPO_ROOT}/keys"
ITB="${REPO_ROOT}/build/boot.itb"
DTB="${REPO_ROOT}/u-boot/u-boot.dtb"
UBOOT_DIR="${REPO_ROOT}/u-boot"
BUILD_DIR="${REPO_ROOT}/build"
LOG_DIR="${REPO_ROOT}/logs"
EMBED_LOG="${LOG_DIR}/embed-key.log"

echo ""
check_deps mkimage make || exit 1
echo ""

# Validate prerequisites
MISSING=0
for entry in \
    "${KEYS_DIR}/${KEY_NAME}.key:Run ./scripts/gen-keys.sh ${KEY_NAME}" \
    "${ITB}:Run ./scripts/make-demo-fit.sh" \
    "${DTB}:Run ./build.sh"; do
    FILE="${entry%%:*}"
    HINT="${entry##*:}"
    if [ ! -f "$FILE" ]; then
        log_error "Required file not found: ${FILE}"
        log_info  "  ${HINT}"
        MISSING=$((MISSING + 1))
    fi
done
[ "$MISSING" -ne 0 ] && exit 1

mkdir -p "${LOG_DIR}"

log_info "[1/3] Signing FIT image and embedding certificate into U-Boot DTB..."
log_info "      FIT image : ${ITB}"
log_info "      Key       : ${KEYS_DIR}/${KEY_NAME}.key"
log_info "      DTB       : ${DTB}"
mkimage -F -k "${KEYS_DIR}" -K "${DTB}" -r "${ITB}" 2>&1 | tee -a "${EMBED_LOG}"
log_ok  "Signature written to FIT image; certificate embedded in DTB"

# Refresh boot.img with the signed ITB (make-demo-fit.sh wrote it before signing)
IMG_FILE="${BUILD_DIR}/boot.img"
if [ -f "${IMG_FILE}" ]; then
    log_info "Refreshing boot disk image with signed FIT..."
    dd if="${ITB}" of="${IMG_FILE}" bs=512 conv=notrunc 2>/dev/null
    log_ok  "Boot disk updated: ${IMG_FILE}"
fi

echo ""
log_info "[2/3] Re-linking U-Boot to bake certificate into ROM (incremental)..."
make -C "${UBOOT_DIR}" ARCH=x86 -j"$(nproc)" >> "${EMBED_LOG}" 2>&1
log_ok  "U-Boot re-linked successfully"

echo ""
log_info "[3/3] Copying updated ROM to build/..."
cp "${UBOOT_DIR}/u-boot.rom" "${BUILD_DIR}/u-boot.rom"
ROM_KB=$(du -k "${BUILD_DIR}/u-boot.rom" | cut -f1)
log_ok  "ROM updated: ${BUILD_DIR}/u-boot.rom (${ROM_KB} KB)"

echo ""
log_ok  "Verified boot artefacts ready:"
log_info "  Signed FIT image  : build/boot.itb"
log_info "  Boot disk image   : build/boot.img"
log_info "  ROM with cert     : build/u-boot.rom"
echo ""
log_info "Boot with verified image:"
log_info "  ./qemu.sh --boot-img build/boot.img"
