{ config, lib, pkgs, modules, baseModules, nixos-unstable, ... }:

with lib;

let

  systemBuilder = ''
      mkdir -p $out/dev $out/lib $out/proc $out/run $out/sbin $out/sys $out/tmp $out/var

      ln -s ${config.system.path} $out/sw
      ln -s ${config.system.build.etc}/etc $out/etc
      ln -s ${config.system.build.init} $out/sbin/init

      ln -s ${config.system.build.modules}/lib/modules $out/lib/modules
      ln -s ${config.system.build.modules}/lib/firmware $out/lib/firmware

      ln -s /etc/sv $out/var/service

      echo -n "$nixosLabel" > $out/nixos-version
    '';

  baseSystem = pkgs.stdenvNoCC.mkDerivation {
    name = "nixos-system-${config.system.name}-${config.system.nixos.label}";
    buildCommand = systemBuilder;
    nixosLabel = config.system.nixos.label;
  };

  # Handle assertions and warnings

  failedAssertions = map (x: x.message) (filter (x: !x.assertion) config.assertions);

  baseSystemAssertWarn = if failedAssertions != []
    then throw "\nFailed assertions:\n${concatStringsSep "\n" (map (x: "- ${x}") failedAssertions)}"
    else showWarnings config.warnings baseSystem;

  # Replace runtime dependencies
  system = fold ({ oldDependency, newDependency }: drv:
      pkgs.replaceDependency { inherit oldDependency newDependency drv; }
    ) baseSystemAssertWarn config.system.replaceRuntimeDependencies;

in

{

  options = {

    system.build = mkOption {
      internal = true;
      default = {};
      type = types.attrs;
      description = ''
        Attribute set of derivations used to setup the system.
      '';
    };

    system.replaceRuntimeDependencies = mkOption {
      default = [];
      example = lib.literalExample "[ ({ original = pkgs.openssl; replacement = pkgs.callPackage /path/to/openssl { }; }) ]";
      type = types.listOf (types.submodule (
        { ... }: {
          options.original = mkOption {
            type = types.package;
            description = "The original package to override.";
          };

          options.replacement = mkOption {
            type = types.package;
            description = "The replacement package.";
          };
        })
      );
      apply = map ({ original, replacement, ... }: {
        oldDependency = original;
        newDependency = replacement;
      });
      description = ''
        List of packages to override without doing a full rebuild.
        The original derivation and replacement derivation must have the same
        name length, and ideally should have close-to-identical directory layout.
      '';
    };

    system.name = mkOption {
      type = types.str;
      default = "unnamed";
      defaultText = '''networking.hostName' if non empty else "unnamed"'';
      description = ''
        The name of the system used in the <option>system.build.toplevel</option> derivation.
        </para><para>
        That derivation has the following name:
        <literal>"nixos-system-''${config.system.name}-''${config.system.nixos.label}"</literal>
      '';
    };

  };

  config = {
    system.build.root = system;
  };

}
