{ stdenv, squashfsTools, closureInfo

, # The files and directories to be placed in the tarball.
  # This is a list of attribute sets {source, target} where `source'
  # is the file system object (regular file or directory) to be
  # grafted in the file system at path `target'.
  contents
, # The root directory of the squashfs filesystem is filled with the
  # closures of the Nix store paths listed here.
  storeContents ? []
, # Compression parameters.
  # For zstd compression you can use "zstd -Xcompression-level 6".
  comp ? "xz -Xdict-size 100%"

  # Extra commands to be executed before archiving files
, extraCommands ? ""

  # Extra mksquashfs arguments
, extraArgs ? ""
}:

let
  symlinks = map (x: x.symlink) storeContents;
  objects = map (x: x.object) storeContents;
in

stdenv.mkDerivation {
  name = "squashfs.img";
  builder = ./make-squashfs.sh;
  nativeBuildInputs = [ squashfsTools ];

  inherit comp extraCommands extraArgs;

  # !!! should use XML.
  sources = map (x: x.source) contents;
  targets = map (x: x.target) contents;

  closureInfo = closureInfo {
    rootPaths = objects;
  };
}
