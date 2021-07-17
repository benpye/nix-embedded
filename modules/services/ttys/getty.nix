{ config, lib, pkgs, ... }:

with lib;

let

  buildGettyService = name: value: {
    name = "getty_${value.tty}";
    value = {
      script = let
        baudRates = concatStringsSep "," (map (s: toString s) value.serialSpeed);
        extraArgs = concatStringsSep " " value.extraArgs;
      in
        ''
          exec ${pkgs.busybox}/sbin/getty -l ${value.loginProgram} -L ${baudRates} ${extraArgs} ${value.tty} ${value.termType}
        '';
    };
  };

  gettyOpts = { name, ... }: {
    options = {
      enable = mkEnableOption "getty";

      tty = mkOption {
        type = types.str;
        description = ''
          The tty to listen on. If undefined, the name of the attribute set
          will be used.
        '';
      };

      termType = mkOption {
        type = types.str;
        default = "";
        description = ''
          Terminal type.
        '';
        example = "vt220";
      };

      loginProgram = mkOption {
        type = types.path;
        default = "${pkgs.busybox}/bin/login";
        description = ''
          Login program to run from getty.
        '';
      };

      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Additional arguments passed to agetty.
        '';
        example = [ "--nohostname" ];
      };

      serialSpeed = mkOption {
        type = types.listOf types.int;
        default = [ 115200 57600 38400 9600 ];
        example = [ 38400 9600 ];
        description = ''
            Bitrates to allow for agetty's listening on serial ports. Listing more
            bitrates gives more interoperability but at the cost of long delays
            for getting a sync on the line.
        '';
      };
    };

    config = {
      tty = mkDefault name;
    };

  };

in

{

  ###### interface

  options = {

    services.getty = mkOption {
      default = {};
      type =  with types; attrsOf (submodule gettyOpts);
      description = "Definition of getty instances.";
    };

  };


  ###### implementation

  config = {

    runit.services = mapAttrs' buildGettyService (filterAttrs (n: v: v.enable) config.services.getty);

  };

}
