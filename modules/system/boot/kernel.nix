{ config, lib, pkgs, ... }:

with lib;

let

  inherit (config.boot) kernelPatches;
  inherit (config.boot.kernel) features randstructSeed;
  inherit (config.boot.kernelPackages) kernel;

in

{

  ###### interface

  options = {

    boot.kernel.features = mkOption {
      default = {};
      example = literalExample "{ debug = true; }";
      internal = true;
      description = ''
        This option allows to enable or disable certain kernel features.
        It's not API, because it's about kernel feature sets, that
        make sense for specific use cases. Mostly along with programs,
        which would have separate nixos options.
        `grep features pkgs/os-specific/linux/kernel/common-config.nix`
      '';
    };

    boot.kernelPackages = mkOption {
      default = pkgs.linuxPackages;
      type = types.unspecified // { merge = mergeEqualOption; };
      apply = kernelPackages: kernelPackages.extend (self: super: {
        kernel = super.kernel.override {
          inherit randstructSeed;
          kernelPatches = super.kernel.kernelPatches ++ kernelPatches;
          features = lib.recursiveUpdate super.kernel.features features;
        };
      });
      # We don't want to evaluate all of linuxPackages for the manual
      # - some of it might not even evaluate correctly.
      defaultText = "pkgs.linuxPackages";
      example = literalExample "pkgs.linuxPackages_2_6_25";
      description = ''
        This option allows you to override the Linux kernel used by
        NixOS.  Since things like external kernel module packages are
        tied to the kernel you're using, it also overrides those.
        This option is a function that takes Nixpkgs as an argument
        (as a convenience), and returns an attribute set containing at
        the very least an attribute <varname>kernel</varname>.
        Additional attributes may be needed depending on your
        configuration.  For instance, if you use the NVIDIA X driver,
        then it also needs to contain an attribute
        <varname>nvidia_x11</varname>.
      '';
    };

    boot.kernelPatches = mkOption {
      type = types.listOf types.attrs;
      default = [];
      example = literalExample "[ pkgs.kernelPatches.ubuntu_fan_4_4 ]";
      description = "A list of additional patches to apply to the kernel.";
    };

    boot.kernel.randstructSeed = mkOption {
      type = types.str;
      default = "";
      example = "my secret seed";
      description = ''
        Provides a custom seed for the <varname>RANDSTRUCT</varname> security
        option of the Linux kernel. Note that <varname>RANDSTRUCT</varname> is
        only enabled in NixOS hardened kernels. Using a custom seed requires
        building the kernel and dependent packages locally, since this
        customization happens at build time.
      '';
    };

    boot.kernelParams = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Parameters added to the kernel command line.";
    };

    boot.consoleLogLevel = mkOption {
      type = types.int;
      default = 4;
      description = ''
        The kernel console <literal>loglevel</literal>. All Kernel Messages with a log level smaller
        than this setting will be printed to the console.
      '';
    };

    boot.kernelModules = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        The set of kernel modules to be made available in the image.
      '';
    };

  };


  ###### implementation

  config = {
    system.build = {
      inherit kernel;

      # TODO: Support additional firmware packages;
      modules = pkgs.makeModulesClosure {
        inherit kernel;
        rootModules = config.boot.kernelModules;
        firmware = kernel;
      };
    };

    boot.kernelParams =
      [ "loglevel=${toString config.boot.consoleLogLevel}" ];
  };

}
