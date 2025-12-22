# talosctl Nix Flake

A Nix flake that packages [talosctl](https://www.talos.dev/), the CLI for Talos Linux.

## Features

- Pre-built binaries from official GitHub releases
- Multi-platform support: Linux (x86_64, aarch64) and macOS (x86_64, aarch64)
- Automatic hourly updates via GitHub Actions
- Only tracks stable releases (no alpha/beta/rc)
- Shell completions for bash, zsh, and fish
- Home Manager module support

## Usage

### Run directly

```bash
nix run github:nklmilojevic/talosctl-flake -- version --client
```

### Install with nix profile

```bash
nix profile install github:nklmilojevic/talosctl-flake
```

### Add to your flake

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    talosctl.url = "github:nklmilojevic/talosctl-flake";
  };

  outputs = { nixpkgs, talosctl, ... }: {
    # Use the package directly
    packages.x86_64-linux.default = talosctl.packages.x86_64-linux.default;
  };
}
```

### Use the overlay

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    talosctl.url = "github:nklmilojevic/talosctl-flake";
  };

  outputs = { nixpkgs, talosctl, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          nixpkgs.overlays = [ talosctl.overlays.default ];
          environment.systemPackages = [ pkgs.talosctl ];
        })
      ];
    };
  };
}
```

### Home Manager module

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    talosctl.url = "github:nklmilojevic/talosctl-flake";
  };

  outputs = { nixpkgs, home-manager, talosctl, ... }: {
    homeConfigurations.myuser = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        talosctl.homeManagerModules.default
        {
          programs.talosctl.enable = true;
        }
      ];
    };
  };
}
```

## Version Updates

This flake is automatically updated hourly via GitHub Actions. The workflow:

1. Checks GitHub releases for new stable versions (excludes alpha/beta/rc)
2. Downloads binaries for all platforms
3. Computes SHA256 hashes
4. Updates `sources.json` and commits

Current version is tracked in [sources.json](./sources.json).

## Manual Update

To manually trigger an update:

1. Go to Actions > "Update talosctl version" > "Run workflow"
2. Or run locally: `bash update.sh`

## Development

Enter the dev shell:

```bash
cd dev && nix develop
```

Available tools: alejandra (formatter), deadnix (unused code), statix (linter), nil (LSP).

## License

The Nix code in this repository is provided under the MIT license.
talosctl itself is licensed under the [Mozilla Public License 2.0](https://github.com/siderolabs/talos/blob/main/LICENSE).
