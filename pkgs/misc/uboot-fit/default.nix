{ stdenv, lib, dtc, ubootTools }:

with lib;

{
  uboot
, itsName ? "u-boot.its"
, src ? null
, target ? "u-boot.itb"
, ubootFiles ? [ "u-boot-nodtb.bin" "u-boot.dtb" ]
, installDir ? "$out"
, ... } @args : stdenv.mkDerivation ({
  pname = "${uboot.name}-fit";
  version = uboot.version;

  nativeBuildInputs = [ dtc ubootTools ];

  inherit src;

  postPatch = ''
    cp ${concatStringsSep " " (map (x: "${uboot}/${x}") ubootFiles)} .
  '';

  buildPhase = ''
    mkimage -E -f ${itsName} -p 0x0 ${target}
  '';

  installPhase = ''
    mkdir -p ${installDir}
    cp ${target} ${installDir}/
  '';
} // args // (optionalAttrs (src == null) { unpackPhase = "true"; }))
