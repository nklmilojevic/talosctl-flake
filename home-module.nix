{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.talosctl;
in
{
  options.programs.talosctl = {
    enable = lib.mkEnableOption "talosctl - CLI for Talos Linux";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      defaultText = lib.literalExpression "pkgs.callPackage ./package.nix { }";
      description = "The talosctl package to use.";
    };

    enableBinSymlink = lib.mkOption {
      type = lib.types.bool;
      default = pkgs.stdenv.isLinux;
      description = ''
        Whether to create a symlink at ~/.local/bin/talosctl.
        Enabled by default on Linux to ensure the binary is in a standard location.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file.".local/bin/talosctl" = lib.mkIf cfg.enableBinSymlink {
      source = "${cfg.package}/bin/talosctl";
    };
  };
}
