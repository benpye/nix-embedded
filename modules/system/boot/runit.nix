{ config, lib, pkgs, ... }:

with lib;

let

  buildServiceFiles = name: value: {
    "sv/${value.name}/run".source = pkgs.writeShellScript value.name value.script;

    # Symlink to writable mount point
    "sv/${value.name}/supervise".source = "/run/sv.${value.name}";
  };

  serviceOpts = { name, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        description = ''
          The name of the service. If undefined, the name of the attribute set
          will be used.
        '';
      };

      script = mkOption {
        type = types.lines;
        default = "";
        description = "Shell commands executed as the service's main process.";
      };
    };

    config = {
      name = mkDefault name;
    };

  };

in
{
  options = {
    runit.services = mkOption {
      default = {};
      type =  with types; attrsOf (submodule serviceOpts);
      description = "Definition of init services.";
    };
  };

  config =
  {
    environment.etc = mkMerge (mapAttrsToList buildServiceFiles config.runit.services);

    system.build.init = pkgs.writeShellScript "init"
    ''
      export PATH=/sw/sbin:/sw/bin
      export HOME=/
      export SHELL=${pkgs.runtimeShell}

      mount -t proc proc /proc
      mount -t sysfs sys /sys
      mkdir /dev/pts /dev/shm
      mount -t devpts devpts /dev/pts
      mount -t tmpfs tmpfs /run
      mount -t tmpfs tmpfs /dev/shm
      mount -t tmpfs tmpfs /tmp

      exec ${pkgs.busybox}/sbin/runsvdir -P /var/service
    '';
  };
}
