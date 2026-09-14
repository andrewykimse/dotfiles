# dotfiles

Nix home-manager configuration for macOS and NixOS.

## Structure

```
.
├── flake.nix              # entry point, defines per-host configurations
├── flake.lock             # pinned input versions
├── modules/
│   ├── common.nix         # shared config across all machines
│   └── hyprland.nix       # Hyprland + waybar + anyrun + mako
└── hosts/
    ├── macbook/
    │   ├── configuration.nix  # nix-darwin system-level config
    │   └── home.nix           # home-manager config (imported as a module)
    ├── desktop/
    │   └── home.nix       # NixOS desktop-specific config
    └── work/
        └── home.nix       # Ubuntu 24.04 (nixGL wrappers, Hyprland)
```

## Hosts

| Name | System | Flake target |
|------|--------|--------------|
| macbook | aarch64-darwin | `darwinConfigurations.macbook` |
| desktop | x86_64-linux | `andrewkim@desktop` |
| work | x86_64-linux (Ubuntu 24.04) | `akim7@work` |

The macbook is nix-darwin (system config + home-manager as a module), not standalone home-manager like the other hosts — see below for its own bootstrap/switch commands.

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

**macbook (nix-darwin):**
```sh
git clone git@github.com:andrewkim/dotfiles ~/sources/dotfiles
cd ~/sources/dotfiles
sudo nix run nix-darwin -- switch --flake .#macbook
```
If this errors with "Unexpected files in /etc, aborting activation", rename the listed files with a `.before-nix-darwin` suffix (per the error's own instructions) and re-run.

**Everything else (standalone home-manager):**
```sh
git clone git@github.com:andrewkim/dotfiles ~/.config/home-manager
cd ~/.config/home-manager
nix run home-manager/master -- switch --flake .#andrewkim@desktop
```

### Applying changes

```sh
# macbook:
sudo darwin-rebuild switch --flake ~/sources/dotfiles#macbook
# or: sudo nh darwin switch ~/sources/dotfiles

# desktop:
home-manager switch --flake ~/.config/home-manager#andrewkim@desktop
# work (Ubuntu 24.04, requires --impure for nixGL):
home-manager switch --flake ~/.config/home-manager#akim7@work --impure
```

### Updating inputs

```sh
nix flake update
home-manager switch --flake ~/.config/home-manager#andrewkim@macbook
git add flake.lock && git commit -m "update flake inputs"
```

### Hyprland on Ubuntu 24.04 (work host)

Hyprland is installed via Nix and wrapped with nixGL for GPU access. After the first `home-manager switch`, create a one-time symlink so GDM shows it as a session option:

```sh
sudo ln -sf /home/akim7/.local/share/wayland-sessions/hyprland.desktop /usr/share/wayland-sessions/hyprland.desktop
```

This only needs to be run once — the desktop file uses `~/.nix-profile/bin/Hyprland` which stays valid across rebuilds.

Hyprlock requires a PAM entry to authenticate. Nix's hyprlock links against Nix's libpam which can't load system PAM/NSS modules (pam_sss, libnss_sss), so we use `pam_exec` to delegate auth to the system via `pamtester`:

```sh
sudo apt install pamtester
printf '#%%PAM-1.0\nauth required pam_exec.so expose_authtok /home/akim7/.local/bin/hyprlock-auth\naccount required pam_permit.so\n' | sudo tee /etc/pam.d/hyprlock
```

### Rolling back

```sh
# macbook:
sudo darwin-rebuild --list-generations
sudo darwin-rebuild switch --switch-generation <n>

# everything else:
home-manager generations         # list generations
home-manager switch --switch-generation <n>
```
