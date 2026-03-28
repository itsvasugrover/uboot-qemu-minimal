#!/bin/bash
# gen-keys.sh — Generate an RSA-4096 key pair and self-signed X.509 certificate
#               for FIT image signing and U-Boot verified boot.
#
# Usage: ./scripts/gen-keys.sh [key-name]   (default: dev)
#
# Output:
#   keys/<name>.key  — RSA-4096 private key   ← NEVER commit this
#   keys/<name>.crt  — Self-signed X.509 cert ← safe to commit

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/check-deps.sh
# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/check-deps.sh"

KEY_NAME="${1:-dev}"
KEYS_DIR="${REPO_ROOT}/keys"
KEY_FILE="${KEYS_DIR}/${KEY_NAME}.key"
CERT_FILE="${KEYS_DIR}/${KEY_NAME}.crt"

check_deps openssl || exit 1
echo ""

mkdir -p "$KEYS_DIR"

if [ -f "$KEY_FILE" ] || [ -f "$CERT_FILE" ]; then
    log_warn "Keys already exist: ${KEY_FILE}, ${CERT_FILE}"
    read -rp "  Overwrite? [y/N] " ans
    if [[ "${ans,,}" != "y" ]]; then
        log_info "Aborted."
        exit 0
    fi
fi

log_info "Generating RSA-4096 private key → ${KEY_FILE}"
openssl genrsa -out "$KEY_FILE" 4096

log_info "Generating self-signed X.509 certificate (10-year validity) → ${CERT_FILE}"
openssl req -batch -new -x509 -days 3650 \
    -subj "/CN=u-boot-fit-signing-${KEY_NAME}/O=uboot-qemu-secure-boot/C=US" \
    -key "$KEY_FILE" \
    -out "$CERT_FILE"

chmod 600 "$KEY_FILE"
chmod 644 "$CERT_FILE"

echo ""
log_ok "Key pair generated successfully."
log_ok "  Private key  : ${KEY_FILE}   ← KEEP SECRET — never commit!"
log_ok "  Certificate  : ${CERT_FILE}  ← safe to commit"
echo ""
log_info "Next steps:"
log_info "  1. Sign a FIT image     : ./scripts/sign-fit.sh <image.itb> ${KEY_NAME}"
log_info "  2. Embed public key into U-Boot DTB for runtime verification:"
log_info "       mkimage -F -k keys/ -K u-boot/u-boot.dtb -r <image.itb>"
log_info "  3. Rebuild U-Boot to bake the certificate into the ROM:"
log_info "       ./build.sh"
