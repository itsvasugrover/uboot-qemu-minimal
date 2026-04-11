## Summary

<!-- What does this PR do and why? Link to the relevant issue if applicable. -->

Closes #

## Type of change

- [ ] `feature/*` — new capability
- [ ] `fix/*` — bug fix
- [ ] `release/*` — version bump / CHANGELOG update
- [ ] docs / config only

## Checklist

**Required before merge:**

- [ ] Branch created from `develop` and targets `develop` (or `main` for a release)
- [ ] All commits are signed (`git commit -s`)
- [ ] Commits are squashed into meaningful units — no "WIP" or "fix typo" commits
- [ ] `shellcheck *.sh scripts/*.sh` passes with zero warnings
- [ ] `./build.sh` completes without errors
- [ ] `./qemu.sh` boots successfully in TCG mode

**If touching the verified boot path (FIT signing / key embedding):**

- [ ] `./scripts/gen-keys.sh dev` → `./build.sh` → `./scripts/make-demo-fit.sh` → `./scripts/embed-key.sh dev` → `./qemu.sh --boot-img build/boot.img` runs end-to-end
- [ ] Serial output shows `sha256,rsa4096:dev+ OK`
- [ ] No `*.key` or `*.pem` files are staged

**If touching the config (`config/qemu-x86_64`):**

- [ ] README Configuration Guide table updated to match any changed values

## Testing notes

<!-- Describe how you tested this. Include relevant serial log snippets or CI run links. -->
