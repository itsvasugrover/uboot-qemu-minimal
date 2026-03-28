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
            type = "kernel";
            arch = "x86";
            os = "linux";
            compression = "none";
            load = <0x01000000>;
            entry = <0x01000000>;
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
echo ""
log_info "Next step — sign it:"
log_info "  ./scripts/sign-fit.sh build/boot.itb dev"
