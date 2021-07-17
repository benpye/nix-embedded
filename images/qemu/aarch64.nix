{ lib, pkgs, ... }:

{

  imports = [
    ./common.nix
  ];

  # Target AArch64
  nixpkgs.crossSystem = {
    config = "aarch64-unknown-linux-gnu";
  };

}
