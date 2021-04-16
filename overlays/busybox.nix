self: super: rec {
  # Make busybox a valid shell package.
  busybox = super.busybox // {
    shellPath = "/bin/sh";
  };

  # Use busybox for all runtime shells.
  runtimeShellPackage = busybox;
}
