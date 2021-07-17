{ config, lib, pkgs, modules, baseModules, nixos-unstable, ... }:

with lib;

let

  pkgs2storeContents = l : map (x: { object = x; symlink = "none"; }) l;

  squashfs = system: (pkgs.callPackage ../../lib/make-squashfs.nix {
    contents = [
      {
        source = "${system}/.";
        target = "./";
      }
    ];
    storeContents = pkgs2storeContents [
      system
    ];
  });

in

{

  config = {
    system.build.squashfs = squashfs config.system.build.root;
  };

}
