{
  description = "A very basic flake";

  inputs = {
    nixos = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
  };

  outputs = { self, nixos }: {

    images =
    let
      config = (nixos.lib.nixosSystem {
        system = "x86_64-linux";
        extraArgs = {
          inherit nixos;
        };
        baseModules = (import ./modules/modules-list.nix) ++ [
          # Essential NixOS modules.
          "${nixos}/nixos/modules/misc/nixpkgs.nix"
          "${nixos}/nixos/modules/misc/label.nix"
          "${nixos}/nixos/modules/misc/version.nix"
          "${nixos}/nixos/modules/misc/assertions.nix"

          ({ ... }: {
            nixpkgs.crossSystem = { system = "aarch64-linux"; config = "aarch64-unknown-linux-gnu"; };
            nixpkgs.overlays = (import ./overlays) ++ [
              (self: super: rec {
                # busybox = super.busybox.overrideAttrs (oldAttrs: {
                #   # This should be done in extraConfig however we cannot pass
                #   # a string with double quotes contained through Kconfig.
                #   makeFlags = [ "CFLAGS=-DBB_ADDITIONAL_PATH='\":/sw/sbin:/sw/bin\"'" ];
                # });
                # linuxEmbeddedKernel = super.linuxPackages_latest.kernel.override {
                #   autoModules = false;
                #   structuredExtraConfig = with super.lib.kernel; {
                #     OVERLAY_FS = yes;
                #   };
                # };

                # shairport-sync = super.shairport-sync.overrideAttrs (oldAttrs: {
                #   configureFlags = [ "--with-alsa" "--with-avahi" "--with-ssl=openssl" "--with-soxr" "--without-configfiles" "--sysconfdir=/etc" ];
                #   buildInputs = [ super.openssl super.avahi super.alsaLib super.popt super.libconfig super.soxr super.libdaemon ];
                # } );
              })
            ];
          })
        ];
        modules = [
          # ({ lib, config, pkgs, ... }: {
          #   # environment.systemPackages = [ pkgs.alsaUtils ];

          #   environment.etc = {
          #     passwd.text = ''
          #       root:x:0:0:System administrator:/:${pkgs.runtimeShell}
          #       avahi:x:100:100:Avahi Daemon:/:/sbin/nologin
          #     '';

          #     group.text = ''
          #       root:x:0:
          #       audio:x:1:
          #       avahi:x:100:
          #     '';
          #   };
          # })
        ];
      }).config;
    in
    {
      squashfs = config.system.build.squashfs;
      image = config.system.build.systemImage;
    };
  };
}
