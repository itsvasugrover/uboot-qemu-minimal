#!/bin/bash
# setup.sh — Clone the U-Boot source tree at a specified release tag.
# Usage: ./setup.sh [--version <tag>]   (default: v2026.01)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/check-deps.sh
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/scripts/check-deps.sh"

UBOOT_TAG="v2026.01"
UBOOT_REPO="https://github.com/u-boot/u-boot.git"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version) UBOOT_TAG="$2"; shift 2 ;;
        *) log_error "Unknown argument: $1"; echo "Usage: $0 [--version <tag>]"; exit 1 ;;
    esac
done

echo ""
log_info "Checking required tools..."
check_deps git make gcc flex bison bc python3 openssl || exit 1
check_python_pkg elftools || exit 1

echo ""
log_info "Setting up U-Boot build environment (tag: ${UBOOT_TAG})..."

if [ -d "u-boot" ]; then
    log_warn "Directory 'u-boot' already exists."
    read -rp "  Re-clone? This will delete the existing directory. [y/N] " ans
    if [[ "${ans,,}" == "y" ]]; then
        rm -rf u-boot
    else
        log_info "Keeping existing u-boot directory."
        log_ok "Setup complete."
        exit 0
    fi
fi

log_info "Cloning U-Boot ${UBOOT_TAG} (shallow clone)..."
git clone -b "${UBOOT_TAG}" --depth 1 "${UBOOT_REPO}"

echo ""
log_ok "Setup complete. Run ./build.sh to compile."