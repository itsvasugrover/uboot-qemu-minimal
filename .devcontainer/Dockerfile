FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core build toolchain
    gcc \
    make \
    flex \
    bison \
    bc \
    # U-Boot host-tool dependencies
    python3 \
    python3-dev \
    python3-pip \
    python3-setuptools \
    python3-pyelftools \
    swig \
    # Crypto and FIT image signing
    openssl \
    libssl-dev \
    libgnutls28-dev \
    # U-Boot user tools (mkimage, dumpimage, etc.)
    u-boot-tools \
    # x86_64 emulation
    qemu-system-x86 \
    # TPM 2.0 software emulator
    swtpm \
    swtpm-tools \
    # Device tree compiler
    device-tree-compiler \
    # Script linting (development)
    shellcheck \
    # Utilities
    git \
    curl \
    gnupg \
    ca-certificates \
    xz-utils \
    binutils \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Give the pre-existing 'ubuntu' user (UID 1000) passwordless sudo and
# add it to the kvm group so ./qemu.sh can use /dev/kvm when exposed.
RUN echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu \
    && chmod 0440 /etc/sudoers.d/ubuntu \
    && (getent group kvm || groupadd kvm) \
    && usermod -aG kvm ubuntu

USER ubuntu
WORKDIR /workspace
