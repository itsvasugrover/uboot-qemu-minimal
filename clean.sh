#!/bin/bash
# clean.sh — Remove build artefacts.
# Usage: ./clean.sh [--build] [--logs] [--uboot] [--all] [--force]
#        Default (no flags): remove all, with confirmation prompt.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/check-deps.sh
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/scripts/check-deps.sh"

CLEAN_UBOOT=0
CLEAN_BUILD=0
CLEAN_LOGS=0
FORCE=0

# Default: clean everything
if [ $# -eq 0 ]; then
    CLEAN_UBOOT=1; CLEAN_BUILD=1; CLEAN_LOGS=1
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --uboot) CLEAN_UBOOT=1 ;;
        --build) CLEAN_BUILD=1 ;;
        --logs)  CLEAN_LOGS=1 ;;
        --all)   CLEAN_UBOOT=1; CLEAN_BUILD=1; CLEAN_LOGS=1 ;;
        --force) FORCE=1 ;;
        *)
            log_error "Unknown argument: $1"
            echo "Usage: $0 [--uboot] [--build] [--logs] [--all] [--force]"
            exit 1
            ;;
    esac
    shift
done

TARGETS=()
[ "$CLEAN_UBOOT" -eq 1 ] && TARGETS+=("u-boot/")
[ "$CLEAN_BUILD" -eq 1 ] && TARGETS+=("build/")
[ "$CLEAN_LOGS"  -eq 1 ] && TARGETS+=("logs/")

if [ ${#TARGETS[@]} -eq 0 ]; then
    log_warn "Nothing selected. Use --uboot, --build, --logs, or --all."
    exit 0
fi

echo ""
log_warn "Will delete: ${TARGETS[*]}"

if [ "$FORCE" -eq 0 ]; then
    read -rp "  Continue? [y/N] " ans
    if [[ "${ans,,}" != "y" ]]; then
        log_info "Aborted."
        exit 0
    fi
fi

for target in "${TARGETS[@]}"; do
    if [ -e "$target" ]; then
        rm -rf "$target"
        log_ok "Removed: ${target}"
    else
        log_info "Already clean: ${target}"
    fi
done

echo ""
log_ok "Clean complete."