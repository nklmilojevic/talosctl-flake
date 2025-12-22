{
  description = "talosctl - CLI for Talos Linux";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem =
        { pkgs, system, ... }:
        {
          packages = {
            talosctl = pkgs.callPackage ./package.nix { };
            default = pkgs.callPackage ./package.nix { };
          };
        };

      flake = {
        overlays.default = final: prev: {
          talosctl = final.callPackage ./package.nix { };
        };

        homeManagerModules.default = import ./home-module.nix;
      };
    };
}
