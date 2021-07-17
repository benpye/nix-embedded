{ config, lib, pkgs, ... }:

with lib;

let

  buildUdhcpcService = name: value: {
    name = "udhcpc_${value.interface}";
    value = {
      script = let
        args = [ "--foreground" "--interface=\"${value.interface}\"" ]
          ++ optional (value.clientId != null) "--clientid=\"${value.clientId}\""
          ++ optional (value.hostName != null) "--hostname=\"${value.hostName}\""
          ++ optional (value.request != null) "--request=\"${value.request}\"";
      in
        ''
          exec ${pkgs.busybox}/sbin/udhcpc ${concatStringsSep " " args}
        '';
    };
  };

  udhcpcOpts = { name, ... }: {
    options = {
      enable = mkEnableOption "udhcp client";

      interface = mkOption {
        type = types.str;
        description = ''
          The interface to configure. If undefined, the name of the attribute
          set will be used.
        '';
      };

      clientId = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Client identifier.
        '';
      };

      hostName = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Client hostname.
        '';
      };

      request = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          IP address to request.
        '';
      };
    };

    config = {
      interface = mkDefault name;
    };

  };

in

{

  ###### interface

  options = {

    services.udhcpc = mkOption {
      default = {};
      type =  with types; attrsOf (submodule udhcpcOpts);
      description = "Definition of udhcpc instances.";
    };

  };


  ###### implementation

  config = {

    runit.services = mapAttrs' buildUdhcpcService (filterAttrs (n: v: v.enable) config.services.udhcpc);

  };

}
