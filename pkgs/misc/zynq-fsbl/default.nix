{ stdenv, lib, pkgsCross, writeShellScriptBin, fetchFromGitHub }:

let
  defaultVersion = "2020.3";
  defaultSrc = fetchFromGitHub {
    owner = "Xilinx";
    repo = "embeddedsw";
    rev = "xilinx-v${defaultVersion}";
    sha256 = "1d1qwz3wzns56kil4na2rs8yz26l49ah9m3376nf468i7sxl6fwy";
  };

  # The makefiles expect arm-none-eabi- and hard float - make them use
  # arm-none-eabihf- instead.
  wrappedGcc = writeShellScriptBin "arm-none-eabi-gcc" ''exec arm-none-eabihf-gcc "$@"'';
  wrappedAr = writeShellScriptBin "arm-none-eabi-ar" ''exec arm-none-eabihf-ar "$@"'';

  buildFsbl = {
    version ? null
  , src ? null
  , installDir ? "$out"
  , board
  , extraPatches ? []
  , extraMakeFlags ? []
  , extraMeta ? {}
  , ... } @ args: stdenv.mkDerivation ({
    pname = "zynq-fsbl-${board}";

    version = if src == null then defaultVersion else version;

    src = if src == null then defaultSrc else src;

    patches = extraPatches;

    postPatch = ''
      patchShebangs lib/sw_apps/zynq_fsbl/misc/copy_bsp.sh

      for x in lib/sw_apps/zynq_fsbl/src/Makefile lib/sw_apps/zynq_fsbl/misc/copy_bsp.sh lib/bsp/standalone/src/arm/cortexa9/gcc/Makefile; do
        substituteInPlace $x \
          --replace arm-none-eabi- arm-none-eabihf-
      done
    '';

    nativeBuildInputs = [
      pkgsCross.zynq-baremetal.buildPackages.gcc
      pkgsCross.zynq-baremetal.buildPackages.binutils
    ];

    # hardeningDisable = [ "all" ];

    buildPhase = ''
      echo $PATH
      type -a make
      cd lib/sw_apps/zynq_fsbl/src
      make BOARD=${board} ${toString extraMakeFlags}
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p ${installDir}
      cp fsbl.elf ${installDir}

      runHook postInstall
    '';

    doCheck = false;
    dontFixup = true;

    meta = with lib; {
      homepage = "https://github.com/Xilinx/embeddedsw";
      description = "First stage boot loader for Xilinx Zynq SoCs";
      license = licenses.mit;
      maintainers = with maintainers; [ benpye ];
    } // extraMeta;
  } // removeAttrs args [ "extraMeta" ]);

in {
  inherit buildFsbl;

  fsblZed = buildFsbl {
    board = "zed";
  };

  fsblZc702 = buildFsbl {
    board = "zc702";
  };

  fsblZc706 = buildFsbl {
    board = "zc706";
  };
}
