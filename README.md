# dotfiles

Nix home-manager configuration for macOS and NixOS.

## Structure

```
.
├── flake.nix              # entry point, defines per-host configurations
├── flake.lock             # pinned input versions
├── modules/
│   └── common.nix         # shared config across all machines
└── hosts/
    ├── macbook/
    │   └── home.nix       # macOS-specific config
    └── desktop/
        └── home.nix       # NixOS desktop-specific config
```

## Hosts

| Name | System | Flake target |
|------|--------|--------------|
| macbook | aarch64-darwin | `andrewkim@macbook` |
| desktop | x86_64-linux | `andrewkim@desktop` |

## Usage

### Prerequisites

**macOS** — install Nix via the [Determinate Systems installer](https://determinate.systems/nix/):
```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

**NixOS** — Nix is already available. Enable flakes in `configuration.nix`:
```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

### First-time setup

```sh
git clone git@github.com:andrewkim/dotfiles ~/.config/home-manager
cd ~/.config/home-manager
nix run home-manager/master -- switch --flake .#andrewkim@macbook
```

### Applying changes

```sh
home-manager switch --flake ~/.config/home-manager#andrewkim@macbook
# or on the desktop:
home-manager switch --flake ~/.config/home-manager#andrewkim@desktop
```

### Updating inputs

```sh
nix flake update
home-manager switch --flake ~/.config/home-manager#andrewkim@macbook
git add flake.lock && git commit -m "update flake inputs"
```

### Rolling back

```sh
home-manager generations         # list generations
home-manager switch --switch-generation <n>
```
