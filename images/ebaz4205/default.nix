{ lib, pkgs, ... }:

let

  ubootEbaz4205 = pkgs.buildUBoot {
    filesToInstall = [ "spl/boot.bin" "u-boot-nodtb.bin" "u-boot.dtb" ];

    defconfig = "xilinx_zynq_virt_defconfig";

    extraPatches = [ ./uboot/add_zynq-ebaz4205-dtb.patch ];

    extraConfig = ''
      CONFIG_DEFAULT_DEVICE_TREE="zynq-ebaz4205"
    '';

    extraMakeFlags = [ "u-boot-nodtb.bin" "u-boot.dtb" "spl/boot.bin" ];

    postPatch = ''
      mkdir -p board/xilinx/zynq/zynq-ebaz4205
      cp ${./uboot/ps7_init_gpl.c} board/xilinx/zynq/zynq-ebaz4205/ps7_init_gpl.c
      cp ${./uboot/ps7_init_gpl.h} board/xilinx/zynq/zynq-ebaz4205/ps7_init_gpl.h
      cp ${./uboot/zynq-ebaz4205.dts} arch/arm/dts/zynq-ebaz4205.dts

      patchShebangs tools
    '';
  };

in
{

  # Do not include all kernel modules.
  boot.kernelPackages = pkgs.linuxPackages.extend (self: super: {
    kernel = super.kernel.override { autoModules = false; };
  });

  # Target ARMv7
  nixpkgs.crossSystem = {
    config = "armv7l-unknown-linux-gnueabihf";
  };

  # Enable getty on serial.
  services.getty.ttyPS0 = {
    enable = true;
    termType = "vt220";
    loginProgram = pkgs.runtimeShell;
    serialSpeed = [ 115200 ];
    extraArgs = [ "-n" ];
  };

  # Enable DHCP client on eth0.
  services.udhcpc.eth0.enable = true;

  system.build.test = ubootEbaz4205;

  system.build.test2 = pkgs.buildUBootFit {
    uboot = ubootEbaz4205;
    src = ./uboot-fit;
    itsName = "ebaz4205.its";
  };

}
