---
description: Run home-manager switch for this dotfiles flake
allowed-tools: [Bash]
---

# home-manager switch

Run the appropriate home-manager switch command for the current machine.

## Instructions

1. Run `nh home switch --impure --no-nom ~/sources/dotfiles`.

   `nh` auto-detects the `homeConfigurations` attribute as `<username>@<hostname>`, which matches this flake's naming for every host, so no `--configuration` flag is needed. Pass `-c <user>@<host>` only if auto-detection fails. The flake outputs are:
   - `akim7@akim7-work-laptop`, `akim7@akim7-work-desktop`
   - `andrewkim@firelink`, `andrewkim@macbook`
   - `deck@deckard`

2. `--impure` is required on the work and deckard machines because of nixGL, and is harmless elsewhere. `--no-nom` keeps the build output readable outside a TTY — drop it if a human is watching.

3. Report the result, including the package diff `nh` prints. If it fails, show the relevant error output.
