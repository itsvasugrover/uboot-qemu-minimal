# Contributing to uboot-qemu-secure-boot

As a solo developer, I maintain strict development practices to ensure code quality and maintainability. This guide outlines the processes I follow for development.

## Branching Strategy

I follow a strict Gitflow workflow to maintain a clean and organized codebase:

- **`main`**: Core branch with the latest shippable code. This branch is protected and maintains linear history.
- **`develop`**: Integration branch for ongoing development.
- **`feature/*`**: Branches for developing new capabilities. Create from `develop` and merge back to `develop`.
- **`fix/*`**: Branches for bug fixes. Create from `develop` and merge back to `develop`.
- **`release/*`**: Branches for preparing a new tag. Create from `develop` and merge into both `develop` and `main`.

## Commit Guidelines

- **Signed Commits**: All commits must be signed using `git commit -s` or `git commit --signoff`.
- **Linear History**: I maintain a linear history. Only squash operations are allowed; merging and rebase is not permitted as merging creates non-linear history and rebase removes signatures.
- **Commit Messages**: Write clear, concise commit messages that describe what was changed and why.

## Development Process

1. Create a feature or fix branch from `develop`.
2. Make changes and test thoroughly.
3. Rebase onto the latest `develop` to resolve conflicts.
4. Squash commits into meaningful units.
5. Merge back to `develop` via a pull request.

## Development Environment

The fastest way to get a fully configured environment is the provided **DevContainer**:

1. Install [VS Code](https://code.visualstudio.com/) and the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).
2. Clone the repo and click **Reopen in Container**.

All required build tools, QEMU, swtpm, openssl, u-boot-tools, and shellcheck are pre-installed. See [.devcontainer/](.devcontainer/) for the full environment definition.

For native setup, see the **Prerequisites** section in [README.md](README.md).

## Script Contributions

All shell scripts must pass `shellcheck` with zero warnings before merging:

```bash
shellcheck *.sh scripts/*.sh
```

New root-level scripts and scripts in `scripts/` must:
- Begin with `set -euo pipefail`
- Source `scripts/check-deps.sh` for colored logging and dependency checking
- Use `log_info`, `log_ok`, `log_warn`, and `log_error` for all user-facing output

## Security Key Contributions

The `keys/` directory is intentionally protected by `.gitignore` for private key material. When working with signing keys:

- **Never commit** `*.key` or `*.pem` files.
- **Safe to commit** self-signed certificates (`*.crt`) used as demo/dev public keys.

## Issue Tracking

I use GitHub issues to track tasks. Issue templates are available:

- [Bug Report](.github/ISSUE_TEMPLATE/bug_report.md)
- [Feature Request](.github/ISSUE_TEMPLATE/feature_request.md)

