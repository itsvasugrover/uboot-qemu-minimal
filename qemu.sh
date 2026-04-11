#!/bin/bash
# qemu.sh — Launch QEMU x86_64 with U-Boot ROM and optional swtpm (TPM 2.0).
# Usage: ./qemu.sh [--no-tpm] [--no-kvm] [--serial-log FILE] [--boot-img FILE]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/check-deps.sh
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/scripts/check-deps.sh"

BUILD_DIR="build"
LOG_DIR="logs"
TPM_DIR="/tmp/uboot-qemu-tpm0"
TPM_SOCK="${TPM_DIR}.sock"

USE_TPM=1
USE_KVM=1
SERIAL_LOG=""
BOOT_IMG=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-tpm)    USE_TPM=0 ;;
        --no-kvm)    USE_KVM=0 ;;
        --serial-log)
            if [[ $# -lt 2 || "$2" == --* ]]; then
                log_error "--serial-log requires a FILE argument"
                echo "Usage: $0 [--no-tpm] [--no-kvm] [--serial-log FILE] [--boot-img FILE]"
                exit 1
            fi
            SERIAL_LOG="$2"; shift ;;
        --boot-img)
            if [[ $# -lt 2 || "$2" == --* ]]; then
                log_error "--boot-img requires a FILE argument"
                echo "Usage: $0 [--no-tpm] [--no-kvm] [--serial-log FILE] [--boot-img FILE]"
                exit 1
            fi
            BOOT_IMG="$2"; shift ;;
        *) log_error "Unknown argument: $1"; echo "Usage: $0 [--no-tpm] [--no-kvm] [--serial-log FILE] [--boot-img FILE]"; exit 1 ;;
    esac
    shift
done

echo ""
if [ "$USE_TPM" -eq 1 ]; then
    check_deps qemu-system-x86_64 swtpm || exit 1
else
    check_deps qemu-system-x86_64 || exit 1
fi
echo ""

if [ ! -f "${BUILD_DIR}/u-boot.rom" ]; then
    log_error "u-boot.rom not found at ${BUILD_DIR}/u-boot.rom. Run ./build.sh first."
    exit 1
fi

mkdir -p "${LOG_DIR}"

# Auto-detect KVM availability
if [ "$USE_KVM" -eq 1 ] && ! [ -r /dev/kvm ]; then
    log_warn "KVM not available — falling back to TCG (software emulation)."
    USE_KVM=0
fi

# Cleanup on exit
SWTPM_PID=""
cleanup() {
    if [ -n "$SWTPM_PID" ] && kill -0 "$SWTPM_PID" 2>/dev/null; then
        log_info "Stopping swtpm (PID: ${SWTPM_PID})..."
        kill "$SWTPM_PID" 2>/dev/null || true
        wait "$SWTPM_PID" 2>/dev/null || true
    fi
    rm -f "$TPM_SOCK"
    rm -rf "$TPM_DIR"
}
trap cleanup EXIT INT TERM

if [ "$USE_TPM" -eq 1 ]; then
    mkdir -p "$TPM_DIR"
    rm -f "$TPM_SOCK"
    log_info "Starting swtpm   (log: ${LOG_DIR}/swtpm.log)..."
    swtpm socket \
        --tpmstate dir="$TPM_DIR" \
        --ctrl type=unixio,path="$TPM_SOCK" \
        --tpm2 \
        --log level=5 > "${LOG_DIR}/swtpm.log" 2>&1 &
    SWTPM_PID=$!

    # Wait up to 5 s for the Unix socket to appear
    for i in {1..10}; do
        [ -S "$TPM_SOCK" ] && break
        sleep 0.5
        if [ "$i" -eq 10 ]; then
            log_error "swtpm socket not ready after 5 s. Check ${LOG_DIR}/swtpm.log."
            exit 1
        fi
    done
    log_ok "swtpm ready   (PID: ${SWTPM_PID}, socket: ${TPM_SOCK})"
fi

# Assemble QEMU arguments
# shellcheck disable=SC2054  # commas are part of QEMU argument values, not array separators
if [ -n "$SERIAL_LOG" ]; then
    # Write serial directly to file — no TTY required (for CI/Docker)
    SERIAL_OPT=(-display none -serial "file:${SERIAL_LOG}")
    log_info "Serial log       : ${SERIAL_LOG}"
else
    # Interactive: map serial to stdio via -nographic
    SERIAL_OPT=(-nographic)
fi

QEMU_ARGS=(
    "${SERIAL_OPT[@]}"
    -m 512M
    -smp 1
    -nic none
    -no-reboot
    -bios "${BUILD_DIR}/u-boot.rom"
    -d "cpu_reset,int"
    -D "${LOG_DIR}/qemu.log"
)

if [ "$USE_KVM" -eq 1 ]; then
    QEMU_ARGS+=(-enable-kvm -cpu host)
    log_info "KVM acceleration : enabled"
else
    QEMU_ARGS+=(-cpu qemu64)
    log_info "KVM acceleration : disabled (TCG)"
fi

if [ "$USE_TPM" -eq 1 ]; then
    # shellcheck disable=SC2054  # commas are part of QEMU argument values, not array separators
    QEMU_ARGS+=(
        -chardev "socket,id=chrtpm,path=${TPM_SOCK}"
        -tpmdev "emulator,id=tpm0,chardev=chrtpm"
        -device "tpm-tis,tpmdev=tpm0"
    )
    log_info "TPM 2.0          : enabled"
else
    log_warn "TPM 2.0          : disabled (--no-tpm)"
fi

if [ -n "$BOOT_IMG" ]; then
    if [ ! -f "$BOOT_IMG" ]; then
        log_error "Boot image not found: ${BOOT_IMG}"
        log_info  "Run ./scripts/make-demo-fit.sh then ./scripts/embed-key.sh first."
        exit 1
    fi
    # shellcheck disable=SC2054  # commas are part of QEMU argument values
    QEMU_ARGS+=(-drive "file=${BOOT_IMG},format=raw,if=virtio")
    log_info "Verified boot    : enabled (${BOOT_IMG})"
else
    log_info "Verified boot    : disabled (no --boot-img)"
fi

log_info "QEMU log         : ${LOG_DIR}/qemu.log"
echo ""
log_info "Launching QEMU x86_64..."
echo ""

qemu-system-x86_64 "${QEMU_ARGS[@]}"

echo ""
log_ok "QEMU exited cleanly. Logs in ${LOG_DIR}/."