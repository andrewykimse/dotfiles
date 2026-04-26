{
  description = "andrewkim home-manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      mkHome = system: modules:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          modules = [ ./modules/common.nix ] ++ modules;
        };
    in {
      homeConfigurations = {
        "andrewkim@macbook" = mkHome "aarch64-darwin" [
          ./hosts/macbook/home.nix
        ];

        "andrewkim@desktop" = mkHome "x86_64-linux" [
          ./hosts/desktop/home.nix
        ];
      };
    };
}
