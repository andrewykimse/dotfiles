---
description: Run home-manager switch for this dotfiles flake
allowed-tools: [Bash]
---

# home-manager switch

Run the appropriate home-manager switch command for the current machine.

## Instructions

1. Detect which host configuration to use based on the current hostname and user:
   - `akim7@work` → `home-manager switch --flake ~/sources/dotfiles#akim7@work --impure`
   - `andrewkim@desktop` → `home-manager switch --flake ~/sources/dotfiles#andrewkim@desktop`
   - `andrewkim@macbook` → `home-manager switch --flake ~/sources/dotfiles#andrewkim@macbook`

2. The `--impure` flag is required on the work machine because of nixGL dependencies.

3. Run the command and report the result. If it fails, show the relevant error output.
