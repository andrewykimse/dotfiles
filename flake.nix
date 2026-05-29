{
  description = "andrewkim home-manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-config.url = "github:andrewykimse/neovim-config";
    monkeyterm.url = "github:andrewykimse/monkeyterm";
    viaterm.url = "github:andrewykimse/viaterm";
    mt7927-driver.url = "github:cmspam/mt7927-nixos";
    btop-src.url = "github:andrewykimse/btop";
    btop-src.flake = false;
    dracula-wallpaper.url = "github:dracula/wallpaper";
    dracula-wallpaper.flake = false;
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
  };

  outputs = { nixpkgs, home-manager, nixgl, neovim-config, monkeyterm, viaterm, mt7927-driver, btop-src, zen-browser, dracula-wallpaper, nixos-hardware, ... }:
    let
      mkHome = system: modules: extraArgs:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
          modules = [ ./modules/common.nix ] ++ modules;
          extraSpecialArgs = { inherit neovim-config btop-src zen-browser dracula-wallpaper; nvidiaLibDir = null; } // extraArgs;
        };
    in {
      nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit mt7927-driver; };
        modules = [
          ./hosts/desktop/configuration.nix
          mt7927-driver.nixosModules.default
        ];
      };

      nixosConfigurations.roundtable = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          nixos-hardware.nixosModules.raspberry-pi-5
          ./hosts/roundtable/configuration.nix
        ];
      };

      # Build with: nix build .#packages.aarch64-linux.roundtable-sd-image
      # Requires aarch64 build support — see hosts/desktop/configuration.nix.
      packages.aarch64-linux.roundtable-sd-image =
        (nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
            nixos-hardware.nixosModules.raspberry-pi-5
            ./hosts/roundtable/configuration.nix
          ];
        }).config.system.build.sdImage;

      homeConfigurations = {
        "andrewkim@macbook" = mkHome "aarch64-darwin" [
          ./hosts/macbook/home.nix
        ] { inherit monkeyterm viaterm; };

        "andrewkim@desktop" =
          let pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };
          in mkHome "x86_64-linux" [
            ./hosts/desktop/home.nix
          ] { inherit monkeyterm viaterm; nvidiaLibDir = "${pkgs.linuxPackages.nvidiaPackages.production}/lib"; };

        "akim7@work" = mkHome "x86_64-linux" [
          ./hosts/work/home.nix
        ] { inherit nixgl monkeyterm viaterm; nvidiaLibDir = "/usr/lib/x86_64-linux-gnu"; };

        "akim7@work-desktop" = mkHome "x86_64-linux" [
          ./hosts/work-desktop/home.nix
        ] { inherit monkeyterm viaterm; nvidiaLibDir = "/usr/lib/x86_64-linux-gnu"; };
      };
    };
}
