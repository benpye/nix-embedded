self: super: {
  pkgsCross = super.pkgsCross // {
    zynq-baremetal = import super.path {
      crossSystem = {
        config = "arm-none-eabihf";
        libc = "newlib";
        gcc = {
          cpu = "cortex-a9";
          fpu = "vfpv3";
        };
      };
      localSystem = { inherit (super.hostPlatform) config; };
    };
  };
}
