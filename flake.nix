{
  description = "andrewkim home-manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-config.url = "github:andrewykimse/neovim-config";
    monkeyterm.url = "github:andrewykimse/monkeyterm";
    viaterm.url = "github:andrewykimse/viaterm";
  };

  outputs = { nixpkgs, home-manager, neovim-config, monkeyterm, viaterm, ... }:
    let
      mkHome = system: modules: extraArgs:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          modules = [ ./modules/common.nix ] ++ modules;
          extraSpecialArgs = { inherit neovim-config; } // extraArgs;
        };
    in {
      homeConfigurations = {
        "andrewkim@macbook" = mkHome "aarch64-darwin" [
          ./hosts/macbook/home.nix
        ] { inherit monkeyterm viaterm; };

        "andrewkim@desktop" = mkHome "x86_64-linux" [
          ./hosts/desktop/home.nix
        ] { inherit monkeyterm viaterm; };

        "akim7@work" = mkHome "x86_64-linux" [
          ./hosts/work/home.nix
        ] { inherit monkeyterm viaterm; };
      };
    };
}
