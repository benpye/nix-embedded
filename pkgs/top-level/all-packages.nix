{ pkgs }:

with pkgs;

{
  buildUBootFit = (callPackage ../misc/uboot-fit {});

  inherit (callPackage ../misc/zynq-fsbl {})
    buildFsbl
    fsblZed
    fsblZc702
    fsblZc706;
}
