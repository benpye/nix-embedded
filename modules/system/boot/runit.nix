{ config, lib, pkgs, ... }:

with lib;

{
  options = {

  };

  config =
  {
    environment.etc."sv/getty_AMA0/run".source = pkgs.writeShellScript "getty"
    ''
      exec ${pkgs.busybox}/sbin/getty -n -l ${pkgs.runtimeShell} -L 115200 ttyAMA0 vt220
    '';

    environment.etc."sv/udhcpc_eth0/run".source = pkgs.writeShellScript "udhcpc"
    ''
      exec ${pkgs.busybox}/sbin/udhcpc --foreground --interface="eth0"
    '';

    # environment.etc."sv/librespot/run".source = pkgs.writeShellScript "librespot"
    # ''
    #   exec ${pkgs.librespot}/bin/librespot -n "Hello world!" -b 320 -c /run/librespot
    # '';

    # environment.etc."sv/shairport-sync/run".source = pkgs.writeShellScript "shairport-sync"
    # ''
    #   exec ${pkgs.shairport-sync}/bin/shairport-sync -u
    # '';

    # environment.etc."sv/dbus/run".source = pkgs.writeShellScript "dbus"
    # ''
    #   exec ${pkgs.dbus.daemon}/libexec/dbus-daemon-launch-helper
    # '';

    # environment.etc."sv/avahi/run".source = pkgs.writeShellScript "avahi"
    # ''
    #   exec ${pkgs.avahi}/sbin/avahi-daemon
    # '';

    environment.etc."resolv.conf".source = "/run/resolv.conf";
    environment.etc."sv/getty_AMA0/supervise".source = "/run/sv.getty_AMA0";
    environment.etc."sv/udhcpc_eth0/supervise".source = "/run/sv.udhcpc_eth0";
    # environment.etc."sv/librespot/supervise".source = "/run/sv.librespot";
    # environment.etc."sv/shairport-sync/supervise".source = "/run/sv.shairport-sync";
    # environment.etc."sv/avahi/supervise".source = "/run/sv.avahi";
    # environment.etc."sv/dbus/supervise".source = "/run/sv.dbus";

    # environment.etc."avahi/avahi-daemon.conf".text = ''
    # [server]
    # host-name=HelloWorld
    # use-ipv4=yes
    # use-ipv6=yes
    # '';

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
