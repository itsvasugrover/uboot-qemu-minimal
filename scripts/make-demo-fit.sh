#!/bin/bash
# make-demo-fit.sh — Assemble a minimal demo FIT image for signing tests.
#
# Creates a synthetic 4 KB random payload, writes a boot.its source file,
# and assembles build/boot.itb — ready to be signed by scripts/sign-fit.sh.
#
# Usage: ./scripts/make-demo-fit.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/check-deps.sh
# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/check-deps.sh"

BUILD_DIR="${REPO_ROOT}/build"
PAYLOAD="demo-payload.bin"          # relative — mkimage resolves /incbin/ from cwd
ITS_FILE="${BUILD_DIR}/boot.its"
ITB_FILE="${BUILD_DIR}/boot.itb"

check_deps mkimage dd || exit 1
echo ""

mkdir -p "${BUILD_DIR}"

log_info "Creating 4 KB random demo payload → ${BUILD_DIR}/${PAYLOAD}"
dd if=/dev/urandom of="${BUILD_DIR}/${PAYLOAD}" bs=4096 count=1 2>/dev/null

log_info "Writing FIT source → ${ITS_FILE}"
cat > "${ITS_FILE}" << 'ITS'
/dts-v1/;
/ {
    description = "Demo FIT image — signing test only, not a real kernel";
    #address-cells = <1>;

    images {
        kernel {
            description = "Demo payload (synthetic)";
            data = /incbin/("demo-payload.bin");
            type = "standalone";
            arch = "x86";
            os = "u-boot";
            compression = "none";
            load = <0x02000000>;
            entry = <0x02000000>;
            hash-1 {
                algo = "sha256";
            };
        };
    };

    configurations {
        default = "conf-1";
        conf-1 {
            description = "Demo boot configuration";
            kernel = "kernel";
            signature-1 {
                algo = "sha256,rsa4096";
                key-name-hint = "dev";
                sign-images = "kernel";
            };
        };
    };
};
ITS

log_info "Assembling FIT image → ${ITB_FILE}"
# mkimage resolves /incbin/ paths relative to its working directory
(cd "${BUILD_DIR}" && mkimage -f boot.its boot.itb)

echo ""
log_ok "FIT image assembled: ${ITB_FILE}"

# Create a raw disk image: 128 KB of zeros with the ITB written at offset 0.
# QEMU passes this to U-Boot as a virtio block device (-drive if=virtio).
IMG_FILE="${BUILD_DIR}/boot.img"
log_info "Creating raw boot disk image → ${IMG_FILE}"
dd if=/dev/zero  of="${IMG_FILE}" bs=65536 count=2 2>/dev/null
dd if="${ITB_FILE}" of="${IMG_FILE}" bs=512 conv=notrunc 2>/dev/null
log_ok "Boot disk image created: ${IMG_FILE}"

echo ""
log_info "Next steps:"
log_info "  1. Build U-Boot (if not done):       ./build.sh"
log_info "  2. Embed key + relink ROM:            ./scripts/embed-key.sh"
log_info "  3. Boot with verified image:          ./qemu.sh --boot-img build/boot.img"
