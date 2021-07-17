{ lib, pkgs, ... }:

{

  # Do not include all kernel modules.
  boot.kernelPackages = pkgs.linuxPackages.extend (self: super: {
    kernel = super.kernel.override { autoModules = false; };
  });

  # Enable getty on serial.
  services.getty.ttyAMA0 = {
    enable = true;
    termType = "vt220";
    loginProgram = pkgs.runtimeShell;
    serialSpeed = [ 115200 ];
    extraArgs = [ "-n" ];
  };

  # Enable DHCP client on eth0.
  services.udhcpc.eth0.enable = true;

}
