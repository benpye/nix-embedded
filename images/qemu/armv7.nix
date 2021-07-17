{ lib, pkgs, ... }:

{

  imports = [
    ./common.nix
  ];

  # Target ARMv7
  nixpkgs.crossSystem = {
    config = "armv7l-unknown-linux-gnueabihf";
  };

}
