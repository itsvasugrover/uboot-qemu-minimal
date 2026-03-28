# uboot-qemu-secure-boot

[![Build](https://github.com/itsvasugrover/uboot-qemu-secure-boot/actions/workflows/build.yml/badge.svg)](https://github.com/itsvasugrover/uboot-qemu-secure-boot/actions/workflows/build.yml)
[![ShellCheck](https://github.com/itsvasugrover/uboot-qemu-secure-boot/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/itsvasugrover/uboot-qemu-secure-boot/actions/workflows/shellcheck.yml)
[![QEMU Smoke Test](https://github.com/itsvasugrover/uboot-qemu-secure-boot/actions/workflows/qemu-smoke-test.yml/badge.svg)](https://github.com/itsvasugrover/uboot-qemu-secure-boot/actions/workflows/qemu-smoke-test.yml)
[![Open in Dev Containers](https://img.shields.io/static/v1?label=Dev%20Containers&message=Open&color=blue&logo=visualstudiocode)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/itsvasugrover/uboot-qemu-secure-boot)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A minimal, security-hardened U-Boot build and test environment targeting **QEMU x86_64** with full **TPM 2.0** (via swtpm), **Measured Boot**, **FIT Image Signing** (RSA-4096), and **UEFI Secure Boot** support. Designed as a firmware security reference for automotive and embedded Linux platforms.

## Table of Contents

- [Architecture](#architecture)
- [Security Features](#security-features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Scripts Reference](#scripts-reference)
- [Secure Boot Workflow](#secure-boot-workflow)
- [Configuration Guide](#configuration-guide)
- [TPM PCR Layout](#tpm-pcr-layout)
- [Testing Workflows Locally](#testing-workflows-locally)
- [Contributing](#contributing)
- [License](#license)

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Host Machine                                            │
│                                                          │
│  ┌───────────────────────────────────────────────────┐  │
│  │  QEMU x86_64                                       │  │
│  │                                                    │  │
│  │   ┌──────────────────┐    ┌─────────────────────┐ │  │
│  │   │  U-Boot ROM      │◄──►│  swtpm              │ │  │
│  │   │  (2 MB)          │    │  TPM 2.0 emulator   │ │  │
│  │   │                  │    │  Unix socket        │ │  │
│  │   │  • Measured Boot │    └─────────────────────┘ │  │
│  │   │  • FIT Signing   │                             │  │
│  │   │  • EFI SecureBoot│                             │  │
│  │   └──────────────────┘                             │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Security Features

| Feature | Status | Details |
|---|---|---|
| TPM 2.0 (swtpm) | Enabled | MMIO interface; SHA-256/384/512 PCR banks |
| Measured Boot | Enabled | Firmware + DTB measured into TPM PCRs via TCG2 |
| FIT Image Signing | Enabled | RSA-4096, RSASSA-PSS, SHA-256 |
| EFI Secure Boot | Enabled | UEFI signature database + TCG2 protocol |
| TCG2 Event Log | Enabled | 8 KB event log buffer |
| Environment Protection | Enabled | `ENV_IS_NOWHERE` + `ENV_WRITEABLE_LIST` |
| ACPI Table | Patched | 200 KB (up from 192 KB — headroom for TPM2 ACPI table) |

## Prerequisites

### DevContainer (Recommended — zero setup)

Open the repository in VS Code and click **Reopen in Container**.  
All tools are pre-installed. See [.devcontainer/](.devcontainer/) for the full environment definition.

[![Open in Dev Containers](https://img.shields.io/static/v1?label=Dev%20Containers&message=Open&color=blue&logo=visualstudiocode)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/itsvasugrover/uboot-qemu-secure-boot)

### Native (Ubuntu 24.04)

| Tool | Purpose |
|---|---|
| `gcc`, `make`, `flex`, `bison`, `bc` | U-Boot build toolchain |
| `python3` + `pyelftools` | U-Boot host scripts |
| `openssl`, `libssl-dev` | Key generation and FIT signing |
| `u-boot-tools` (mkimage) | FIT image assembly and signing |
| `qemu-system-x86_64` | x86_64 emulation |
| `swtpm`, `swtpm-tools` | TPM 2.0 software emulator |
| `device-tree-compiler` | DTB inspection and manipulation |
| `shellcheck` | Script linting (development) |

**One-liner install:**

```bash
sudo apt-get install -y gcc make flex bison bc \
    python3 python3-dev python3-pip python3-setuptools swig \
    openssl libssl-dev libgnutls28-dev u-boot-tools \
    qemu-system-x86 swtpm swtpm-tools \
    device-tree-compiler python3-pyelftools shellcheck
```

## Quick Start

```bash
# 1. Clone U-Boot source (shallow, tag v2026.01)
./setup.sh

# 2. Build U-Boot ROM with security config applied
./build.sh

# 3. Run in QEMU with software TPM 2.0
./qemu.sh

# 4. Clean all build artefacts
./clean.sh
```

## Scripts Reference

| Script | Description |
|---|---|
| `setup.sh [--version TAG]` | Clone U-Boot at a given tag. Prompts before re-cloning. |
| `build.sh` | Clean → patch → defconfig → merge config → compile. Logs to `logs/build.log`. |
| `qemu.sh [--no-tpm] [--no-kvm] [--boot-img FILE]` | Launch QEMU with swtpm. Auto-detects KVM; falls back to TCG. Pass `--boot-img` to enable verified boot. |
| `clean.sh [--build\|--logs\|--uboot\|--all] [--force]` | Selective cleanup with confirmation prompt. |
| `scripts/check-deps.sh` | Shared helper: colored logging + `check_deps` function (source only). |
| `scripts/gen-keys.sh [name]` | Generate RSA-4096 key pair + X.509 cert in `keys/`. |
| `scripts/make-demo-fit.sh` | Assemble a demo FIT image (`build/boot.itb`) and raw boot disk (`build/boot.img`). |
| `scripts/embed-key.sh [name]` | Sign FIT image, embed cert into U-Boot DTB, re-link ROM. Run after `build.sh` + `make-demo-fit.sh`. |
| `scripts/sign-fit.sh [image.itb] [name]` | Sign and verify a FIT image with keys from `keys/`. |

## Secure Boot Workflow

FIT image signing allows U-Boot to cryptographically verify a payload before executing it. The signing certificate is embedded in the U-Boot ROM at build time — U-Boot will **refuse to boot** any image not signed with the embedded key.

### Quick demo (5 commands)

```bash
# 1. Generate RSA-4096 key pair
./scripts/gen-keys.sh dev

# 2. Build U-Boot ROM (generates u-boot.dtb needed for cert embedding)
./build.sh

# 3. Assemble a demo FIT image + raw boot disk
./scripts/make-demo-fit.sh

# 4. Sign FIT, embed cert into DTB, re-link ROM
./scripts/embed-key.sh dev

# 5. Boot — U-Boot verifies the FIT image before loading
./qemu.sh --boot-img build/boot.img
```

Expected output in U-Boot serial console:
```
## Loading kernel from FIT Image at 01000000 ...
   Using 'conf-1' configuration
   Verifying Hash Integrity ... sha256,rsa4096:dev+ OK
   Loading Kernel Image ...
```

`sha256,rsa4096:dev+ OK` confirms the signature verified against the certificate baked into the ROM.

### What each step does

| Step | Script | What it produces |
|---|---|---|
| 1 | `gen-keys.sh` | `keys/dev.key` (private), `keys/dev.crt` (X.509 cert) |
| 2 | `build.sh` | `build/u-boot.rom`, `u-boot/u-boot.dtb` |
| 3 | `make-demo-fit.sh` | `build/boot.itb` (unsigned FIT), `build/boot.img` (raw disk) |
| 4 | `embed-key.sh` | `build/boot.itb` (signed FIT), `u-boot.dtb` with cert, `build/u-boot.rom` with cert baked in |
| 5 | `qemu.sh --boot-img` | U-Boot reads disk, verifies FIT, prints `OK` or `Signature check Failed!` |

> **Note:** Steps 2 and 4 both run `make`. Step 2 is a full build (distclean). Step 4 is an incremental re-link only — it takes ~2 seconds because only the DTB-linked objects are rebuilt.

### For a real kernel

Replace `make-demo-fit.sh` with your own `boot.its` pointing at a real `Image`/`uImage`, then run `embed-key.sh` and `qemu.sh --boot-img` as above. The FIT source template is in [the scripts reference](#scripts-reference).

## Configuration Guide

Custom options live in [config/qemu-x86_64](config/qemu-x86_64) and are merged on top of the upstream `qemu-x86_64_defconfig` at build time.

| Option | Value | Notes |
|---|---|---|
| `CONFIG_ROM_SIZE` | `2097152` | 2 MB ROM image |
| `CONFIG_BAUDRATE` | `115200` | UART baud rate |
| `CONFIG_BOOTDELAY` | `3` | 3-second autoboot countdown |
| `CONFIG_FIT_SIGNATURE` | `y` | Enforce FIT image signature verification |
| `CONFIG_FIT_RSASSA_PSS` | `y` | RSASSA-PSS padding (recommended over PKCS#1 v1.5) |
| `CONFIG_RSA_VERIFY_WITH_PKEY` | `y` | Verify against embedded X.509 public key |
| `CONFIG_TPM_V2` + `CONFIG_TPM2_MMIO` | `y` | TPM 2.0 via MMIO |
| `CONFIG_MEASURED_BOOT` | `y` | Extend TPM PCRs with firmware measurements |
| `CONFIG_TPM2_EVENT_LOG_SIZE` | `8192` | 8 KB TCG2 event log |
| `CONFIG_EFI_SECURE_BOOT` | `y` | UEFI Secure Boot variable enforcement |
| `CONFIG_EFI_TCG2_PROTOCOL` | `y` | EFI TCG2 (TCG PC Client Platform specification) |
| `CONFIG_ENV_IS_NOWHERE` | `y` | No persistent environment — prevents `saveenv` tampering |
| `CONFIG_ENV_WRITEABLE_LIST` | `y` | Restricts `setenv` to an explicit allowlist |

## TPM PCR Layout

Standard TCG PC Client Platform PCR assignments used by U-Boot's measured boot:

| PCR | Content |
|---|---|
| 0 | Core Root of Trust for Measurement — BIOS/ROM code |
| 1 | Platform configuration (SMBIOS, ACPI tables) |
| 2 | ROM code — option ROMs |
| 3 | ROM configuration and data |
| 4 | IPL code — bootloader (U-Boot itself) |
| 5 | IPL configuration — U-Boot environment |
| 7 | Secure Boot state and key database |
| 8–15 | Reserved for OS and application use |

> Read PCR values at runtime:
> - U-Boot shell: `tpm pcr_read 0`
> - Host (after boot): `tpm2_pcrread` (tpm2-tools)

## Testing Workflows Locally

Use [`act`](https://github.com/nektos/gh-act) to run GitHub Actions workflows locally via Docker before pushing.

**Install once:**

```bash
gh extension install https://github.com/nektos/gh-act
```

**Run each workflow:**

```bash
# Lint all shell scripts
gh act push -W .github/workflows/shellcheck.yml -P ubuntu-24.04=ghcr.io/catthehacker/ubuntu:act-24.04

# Build U-Boot ROM
gh act push -W .github/workflows/build.yml -P ubuntu-24.04=ghcr.io/catthehacker/ubuntu:act-24.04

# Boot smoke test in QEMU (TCG mode, 30 s timeout)
gh act push -W .github/workflows/qemu-smoke-test.yml -P ubuntu-24.04=ghcr.io/catthehacker/ubuntu:act-24.04
```

> Artifact upload steps are automatically skipped when running under `act` (the `ACT` env var is set by the runner).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the Gitflow workflow, signed-commit requirements, and branch naming conventions.

## License

MIT — see [LICENSE](LICENSE).
