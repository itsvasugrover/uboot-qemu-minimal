#!/bin/bash
# check-deps.sh — Shared helper: colored logging and dependency checker.
# Source this file from other scripts; do not execute it directly.
#
#   From root-level scripts:    source "${SCRIPT_DIR}/scripts/check-deps.sh"
#   From scripts/ subdirectory: source "${REPO_ROOT}/scripts/check-deps.sh"

# Color codes (disabled automatically when not writing to a terminal)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' CYAN='' NC=''
fi

log_info()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[ OK ]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERR ]${NC}  $*" >&2; }

# check_deps <tool> [tool ...]
# Prints a status line for each tool. Returns 1 if any are missing.
check_deps() {
    local missing=0
    for tool in "$@"; do
        if command -v "$tool" > /dev/null 2>&1; then
            log_ok "${tool} — $(command -v "$tool")"
        else
            log_error "Missing: ${tool}"
            missing=$((missing + 1))
        fi
    done
    if [ "$missing" -ne 0 ]; then
        log_error "$missing required tool(s) not found. Install them and retry."
        return 1
    fi
    return 0
}

# check_python_pkg <import_name> [import_name ...]
# Verifies each package is importable by the system python3.
# Falls back to checking pipx-installed packages and warns if found there —
# pipx isolation means U-Boot's make will still fail; use apt/pip3 for build deps.
# e.g. check_python_pkg elftools  (package: pyelftools)
check_python_pkg() {
    local missing=0
    for pkg in "$@"; do
        if python3 -c "import ${pkg}" > /dev/null 2>&1; then
            log_ok  "python3:${pkg} — importable"
        elif command -v pipx > /dev/null 2>&1 && pipx list 2>/dev/null | grep -qi "${pkg}"; then
            log_warn "python3:${pkg} — found in pipx but NOT in system Python"
            log_warn "  U-Boot's make calls 'python3 -c \"import ${pkg}\"' directly."
            log_warn "  Install system-wide:  sudo apt install python3-${pkg}"
            log_warn "                     or pip3 install ${pkg}"
        else
            log_error "Missing Python package: ${pkg}  (apt: python3-${pkg}  or  pip3 install ${pkg})"
            missing=$((missing + 1))
        fi
    done
    if [ "$missing" -ne 0 ]; then
        log_error "$missing Python package(s) not found."
        return 1
    fi
    return 0
}

# check_header <header> [header ...]
# Verifies C headers exist in standard include paths (covers -dev packages).
# e.g. check_header openssl/ssl.h gnutls/gnutls.h Python.h
check_header() {
    local missing=0
    # Build search path: standard dirs + python3's versioned include dir
    local search_dirs=(/usr/include /usr/local/include)
    local pyinc
    pyinc=$(python3 -c "import sysconfig; print(sysconfig.get_path('include'))" 2>/dev/null || true)
    [ -n "$pyinc" ] && search_dirs+=("$pyinc")

    for hdr in "$@"; do
        local found=0
        for dir in "${search_dirs[@]}"; do
            if [ -f "${dir}/${hdr}" ]; then
                log_ok  "header:${hdr} — ${dir}/${hdr}"
                found=1
                break
            fi
        done
        if [ "$found" -eq 0 ]; then
            log_error "Missing C header: ${hdr}  (install the corresponding -dev package)"
            missing=$((missing + 1))
        fi
    done
    if [ "$missing" -ne 0 ]; then
        log_error "$missing header(s) not found."
        return 1
    fi
    return 0
}
