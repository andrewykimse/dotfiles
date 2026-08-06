{
  description = "andrewkim home-manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-raspberrypi = {
      url = "github:nvmd/nixos-raspberrypi";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl = {
      url = "github:nix-community/nixGL";
    };
    neovim-config.url = "github:andrewykimse/neovim-config";
    hyprland-config.url = "git+ssh://git@github.com/andrewykimse/hyprland-config";
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
    helium-browser = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ricelin = {
      url = "github:Gakuseei/Ricelin";
      flake = false;
    };
    hyprsphere = {
      url = "github:66-firebat/hyprsphere";
      flake = false;
    };
    nvibrant-src = {
      url = "github:Tremeschin/nvibrant/v1.2.1";
      flake = false;
    };
    nvidia-open-gpu-595-84 = {
      url = "github:NVIDIA/open-gpu-kernel-modules/595.84";
      flake = false;
    };
  };

  outputs = { nixpkgs, home-manager, nixgl, neovim-config, hyprland-config, monkeyterm, viaterm, mt7927-driver, btop-src, zen-browser, helium-browser, dracula-wallpaper, nixos-raspberrypi, ricelin, hyprsphere, nvibrant-src, nvidia-open-gpu-595-84, ... }:
    let
      mkHome = system: modules: extraArgs:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
          modules = [ ./modules/common.nix ] ++ modules;
          extraSpecialArgs = { inherit neovim-config btop-src zen-browser helium-browser dracula-wallpaper; nvidiaLibDir = null; } // extraArgs;
        };
    in {
      nixosConfigurations.firelink = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit mt7927-driver; };
        modules = [
          ./hosts/firelink/configuration.nix
          mt7927-driver.nixosModules.default
        ];
      };

      nixosConfigurations.roundtable = nixos-raspberrypi.lib.nixosSystem {
        nixpkgs = nixpkgs;
        modules = [
          nixos-raspberrypi.nixosModules.raspberry-pi-5.base
          ./hosts/roundtable/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              inherit neovim-config btop-src monkeyterm viaterm;
              nvidiaLibDir = null;
            };
            home-manager.users.andrewkim = import ./hosts/roundtable/home.nix;
          }
        ];
      };

      # Build with: nix build .#packages.aarch64-linux.roundtable-sd-image
      # Requires aarch64 build support — see hosts/desktop/configuration.nix.
      packages.aarch64-linux.roundtable-sd-image =
        (nixos-raspberrypi.lib.nixosSystem {
          nixpkgs = nixpkgs;
          modules = [
            nixos-raspberrypi.nixosModules.sd-image
            nixos-raspberrypi.nixosModules.raspberry-pi-5.base
            ./hosts/roundtable/configuration.nix
          ];
        }).config.system.build.sdImage;

      homeConfigurations = {
        "andrewkim@macbook" = mkHome "aarch64-darwin" [
          ./hosts/macbook/home.nix
        ] { inherit monkeyterm viaterm; };

        "andrewkim@firelink" =
          let pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };
          in mkHome "x86_64-linux" [
            ./hosts/firelink/home.nix
          ] { inherit monkeyterm viaterm ricelin hyprsphere hyprland-config; nvidiaLibDir = "${pkgs.linuxPackages.nvidiaPackages.production}/lib"; };

        "akim7@akim7-work-laptop" = mkHome "x86_64-linux" [
          ./hosts/work/home.nix
        ] { inherit nixgl monkeyterm viaterm ricelin hyprsphere hyprland-config nvibrant-src nvidia-open-gpu-595-84; nvidiaLibDir = "/usr/lib/x86_64-linux-gnu"; };

        "akim7@akim7-work-desktop" = mkHome "x86_64-linux" [
          ./hosts/work-desktop/home.nix
        ] { inherit nixgl monkeyterm viaterm ricelin hyprsphere hyprland-config; nvidiaLibDir = "/usr/lib/x86_64-linux-gnu"; };

        "deck@deckard" = mkHome "x86_64-linux" [
          ./hosts/deckard/home.nix
        ] { inherit nixgl monkeyterm viaterm; };
      };
    };
}
