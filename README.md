# U-Boot QEMU Minimal

A minimal setup for building and running U-Boot in QEMU for ARM64, targeted at automotive applications.

## Prerequisites

- Git
- QEMU (qemu-system-aarch64)
- aarch64-linux-gnu-gcc cross-compiler

## Setup

Clone the U-Boot repository:

```bash
./setup.sh
```

## Build

Configure and build U-Boot for QEMU ARM64:

```bash
./build.sh
```

This will create the U-Boot binary in the `build/` directory.

## Run

Start QEMU with the built U-Boot:

```bash
./qemu.sh
```

## Clean

Remove the cloned U-Boot repository:

```bash
./clean.sh
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.