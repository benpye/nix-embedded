{ ... }:

{
  # Symlink resolv.conf to /run so that it may be modified.
  environment.etc."resolv.conf".source = "/run/resolv.conf";
}
