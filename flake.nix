{
  description = "A very basic flake";

  inputs = {
    nixos = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
  };

  outputs = { self, nixos }: {

    images =
    {
      config = (nixos.lib.nixosSystem {
        system = "x86_64-linux";
        extraArgs = {
          inherit nixos;
        };
        baseModules = (import ./modules/modules-list.nix) ++ [
          # Essential NixOS modules.
          "${nixos}/nixos/modules/misc/assertions.nix"
          "${nixos}/nixos/modules/misc/ids.nix"
          "${nixos}/nixos/modules/misc/label.nix"
          "${nixos}/nixos/modules/misc/nixpkgs.nix"
          "${nixos}/nixos/modules/misc/version.nix"

          ({ ... }: {
            nixpkgs.overlays = (import ./overlays);
          })
        ];
        modules = [
          ./images/qemu/aarch64.nix
        ];
      }).config;
    };
  };
}
