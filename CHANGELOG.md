# Changelog

All notable changes to this project will be documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).  
This project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

- Fix `CONFIG_BOOTDELAY` mismatch between README and config (was `3`, is `5`)
- Document keyed autoboot passphrase (`stop`) in README
- Fix TPM state directory (`/tmp/uboot-qemu-tpm0`) not cleaned up on `qemu.sh` exit
- Add `.github/pull_request_template.md` enforcing Gitflow and shellcheck requirements
- Add verified-boot CI workflow that exercises the full FIT signing path
- Add negative test: unsigned/wrong-key FIT boot must be rejected

---

## [0.1.0] — 2026-04-11

Initial public release of the U-Boot QEMU Secure Boot reference implementation.

### Added

- **Verified Boot (FIT Image Signing)** — RSA-4096 / RSASSA-PSS kernel verification via `scripts/gen-keys.sh`, `scripts/make-demo-fit.sh`, `scripts/embed-key.sh`, `scripts/sign-fit.sh`
- **TPM 2.0 Measured Boot** — swtpm integration; firmware + DTB extended into SHA-256/384/512 PCR banks; 8 KB TCG2 event log
- **EFI Secure Boot** — `CONFIG_EFI_SECURE_BOOT` + `CONFIG_EFI_TCG2_PROTOCOL` enabled
- **Console Lockdown** — Keyed autoboot with SHA-256-hashed passphrase; `CONFIG_AUTOBOOT_KEYED` + `CONFIG_AUTOBOOT_ENCRYPTION`
- **Environment Protection** — `CONFIG_ENV_IS_NOWHERE` + `CONFIG_ENV_WRITEABLE_LIST` prevent runtime tampering
- **ACPI Table Patch** — Expand ACPI table from 192 KB to 200 KB for TPM2 ACPI table headroom
- **DevContainer** — Ubuntu 24.04 base with all 19 build/emulation dependencies pre-installed; zero-setup onboarding
- **Hardened scripts** — `setup.sh`, `build.sh`, `qemu.sh`, `clean.sh` with `set -euo pipefail`, colored logging, and shellcheck compliance
- **CI workflows** — Build validation, QEMU smoke test, shellcheck linting on every push/PR to `main` and `develop`
- **Gitflow governance** — `CONTRIBUTING.md` with branch naming, signed-commit, and squash-merge requirements
- **GitHub issue templates** — Bug report, feature request, documentation, question, performance

### Architecture

- Target: QEMU x86_64
- Bootloader: U-Boot v2026.01 (`qemu-x86_64_defconfig` + 72 custom config options)
- TPM: swtpm via MMIO (`-tpmdev emulator` + `-device tpm-tis`)
- Signing: RSA-4096 X.509 certificate embedded into U-Boot DTB at link time
- Boot image: 128 KB raw virtio block device containing signed FIT image

[Unreleased]: https://github.com/itsvasugrover/uboot-qemu-secure-boot/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/itsvasugrover/uboot-qemu-secure-boot/releases/tag/v0.1.0
