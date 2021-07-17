{ config, lib, utils, pkgs, ... }:

with lib;

let
  ids = config.ids;
  cfg = config.users;

  # Check whether a password hash will allow login.
  allowsLogin = hash:
    hash == "" # login without password
    || !(lib.elem hash
      [ null   # password login disabled
        "!"    # password login disabled
        "!!"   # a variant of "!"
        "*"    # password unset
      ]);

  passwordDescription = ''
    The options <option>hashedPassword</option>,
    <option>password</option> and <option>passwordFile</option>
    controls what password is set for the user.
    <option>hashedPassword</option> overrides both
    <option>password</option> and <option>passwordFile</option>.
    <option>password</option> overrides <option>passwordFile</option>.
    If none of these three options are set, no password is assigned to
    the user, and the user will not be able to do password logins.
    If the option <option>users.mutableUsers</option> is true, the
    password defined in one of the three options will only be set when
    the user is created for the first time. After that, you are free to
    change the password with the ordinary user management commands. If
    <option>users.mutableUsers</option> is false, you cannot change
    user passwords, they will always be set according to the password
    options.
  '';

  hashedPasswordDescription = ''
    To generate a hashed password run <literal>mkpasswd -m sha-512</literal>.

    If set to an empty string (<literal>""</literal>), this user will
    be able to log in without being asked for a password (but not via remote
    services such as SSH, or indirectly via <command>su</command> or
    <command>sudo</command>). This should only be used for e.g. bootable
    live systems. Note: this is different from setting an empty password,
    which ca be achieved using <option>users.users.&lt;name?&gt;.password</option>.

    If set to <literal>null</literal> (default) this user will not
    be able to log in using a password (i.e. via <command>login</command>
    command).
  '';

  userOpts = { name, config, ... }: {

    options = {

      name = mkOption {
        type = types.str;
        apply = x: assert (builtins.stringLength x < 32 || abort "Username '${x}' is longer than 31 characters which is not allowed!"); x;
        description = ''
          The name of the user account. If undefined, the name of the
          attribute set will be used.
        '';
      };

      description = mkOption {
        type = types.str;
        default = "";
        example = "Alice Q. User";
        description = ''
          A short description of the user account, typically the
          user's full name.  This is actually the “GECOS” or “comment”
          field in <filename>/etc/passwd</filename>.
        '';
      };

      uid = mkOption {
        type = types.int;
        description = ''
          The account UID.
        '';
      };

      isSystemUser = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Indicates if the user is a system user or not. This option
          only has an effect if <option>uid</option> is
          <option>null</option>, in which case it determines whether
          the user's UID is allocated in the range for system users
          (below 500) or in the range for normal users (starting at
          1000).
          Exactly one of <literal>isNormalUser</literal> and
          <literal>isSystemUser</literal> must be true.
        '';
      };

      isNormalUser = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Indicates whether this is an account for a “real” user. This
          automatically sets <option>group</option> to
          <literal>users</literal>, <option>createHome</option> to
          <literal>true</literal>, <option>home</option> to
          <filename>/home/<replaceable>username</replaceable></filename>,
          <option>useDefaultShell</option> to <literal>true</literal>,
          and <option>isSystemUser</option> to
          <literal>false</literal>.
          Exactly one of <literal>isNormalUser</literal> and
          <literal>isSystemUser</literal> must be true.
        '';
      };

      group = mkOption {
        type = types.str;
        apply = x: assert (builtins.stringLength x < 32 || abort "Group name '${x}' is longer than 31 characters which is not allowed!"); x;
        default = "nogroup";
        description = "The user's primary group.";
      };

      extraGroups = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "The user's auxiliary groups.";
      };

      home = mkOption {
        type = types.path;
        default = "/var/empty";
        description = "The user's home directory.";
      };

      shell = mkOption {
        type = types.nullOr (types.either types.shellPackage types.path);
        default = pkgs.runtimeShell;
        defaultText = "pkgs.runtimeShell";
        example = literalExample "pkgs.bashInteractive";
        description = ''
          The path to the user's shell. Can use shell derivations,
          like <literal>pkgs.bashInteractive</literal>. Don’t
          forget to enable your shell in
          <literal>programs</literal> if necessary,
          like <code>programs.zsh.enable = true;</code>.
        '';
      };

      hashedPassword = mkOption {
        type = with types; nullOr str;
        default = null;
        description = ''
          Specifies the hashed password for the user.
          ${passwordDescription}
          ${hashedPasswordDescription}
        '';
      };

    };

    config = mkMerge
      [ { name = mkDefault name; }
        (mkIf config.isNormalUser {
          group = mkDefault "users";
          home = mkDefault "/home/${config.name}";
          isSystemUser = mkDefault false;
        })
      ];

  };

  groupOpts = { name, ... }: {

    options = {

      name = mkOption {
        type = types.str;
        description = ''
          The name of the group. If undefined, the name of the attribute set
          will be used.
        '';
      };

      gid = mkOption {
        type = types.int;
        description = ''
          The group GID.
        '';
      };

      members = mkOption {
        type = with types; listOf str;
        default = [];
        description = ''
          The user names of the group members, added to the
          <literal>/etc/group</literal> file.
        '';
      };

    };

    config = {
      name = mkDefault name;
    };

  };

  idsAreUnique = set: idAttr: !(fold (name: args@{ dup, acc }:
    let
      id = builtins.toString (builtins.getAttr idAttr (builtins.getAttr name set));
      exists = builtins.hasAttr id acc;
      newAcc = acc // (builtins.listToAttrs [ { name = id; value = true; } ]);
    in if dup then args else if exists
      then builtins.trace "Duplicate ${idAttr} ${id}" { dup = true; acc = null; }
      else { dup = false; acc = newAcc; }
    ) { dup = false; acc = {}; } (builtins.attrNames set)).dup;

  uidsAreUnique = idsAreUnique (filterAttrs (n: u: u.uid != null) cfg.users) "uid";
  gidsAreUnique = idsAreUnique (filterAttrs (n: g: g.gid != null) cfg.groups) "gid";

in {

  ###### interface

  options = {

    users.enforceIdUniqueness = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to require that no two users/groups share the same uid/gid.
      '';
    };

    users.users = mkOption {
      default = {};
      type = with types; attrsOf (submodule userOpts);
      example = {
        alice = {
          uid = 1234;
          description = "Alice Q. User";
          home = "/home/alice";
          group = "users";
          extraGroups = ["wheel"];
          shell = "/bin/sh";
        };
      };
      description = ''
        Additional user accounts to be created automatically by the system.
        This can also be used to set options for root.
      '';
    };

    users.groups = mkOption {
      default = {};
      example =
        { students.gid = 1001; };
      type = with types; attrsOf (submodule groupOpts);
      description = ''
        Additional groups to be created automatically by the system.
      '';
    };

  };


  ###### implementation

  config = {

    users.users = {
      root = {
        uid = ids.uids.root;
        description = "System administrator";
        home = "/";
        shell = mkDefault pkgs.runtimeShell;
        group = "root";
      };
      nobody = {
        uid = ids.uids.nobody;
        isSystemUser = true;
        description = "Unprivileged account (don't use!)";
        group = "nogroup";
      };
    };

    users.groups = {
      root.gid = ids.gids.root;
      wheel.gid = ids.gids.wheel;
      disk.gid = ids.gids.disk;
      kmem.gid = ids.gids.kmem;
      tty.gid = ids.gids.tty;
      floppy.gid = ids.gids.floppy;
      uucp.gid = ids.gids.uucp;
      lp.gid = ids.gids.lp;
      cdrom.gid = ids.gids.cdrom;
      tape.gid = ids.gids.tape;
      audio.gid = ids.gids.audio;
      video.gid = ids.gids.video;
      dialout.gid = ids.gids.dialout;
      nogroup.gid = ids.gids.nogroup;
      users.gid = ids.gids.users;
      nixbld.gid = ids.gids.nixbld;
      utmp.gid = ids.gids.utmp;
      adm.gid = ids.gids.adm;
      input.gid = ids.gids.input;
      kvm.gid = ids.gids.kvm;
      render.gid = ids.gids.render;
      shadow.gid = ids.gids.shadow;
    };

    environment.etc.passwd.text = let
      groupToGid = mapAttrs' (name: group: {
        name = group.name;
        value = group.gid;
      }) cfg.groups;
    in
      concatStringsSep "\n" (mapAttrsToList (name: user:
        "${user.name}:x:${toString user.uid}:${toString groupToGid.${user.group}}:${user.description}:${user.home}:${user.shell}"
      ) cfg.users);

    environment.etc.shadow.text =
      concatStringsSep "\n" (mapAttrsToList (name: user: let
        hashedPassword = if user.hashedPassword != null then
          user.hashedPassword
        else "!";
      in "${user.name}:${hashedPassword}:1:::::") cfg.users);

    environment.etc.group.text = concatStringsSep "\n" (mapAttrsToList (name: group:
      "${group.name}:x:${toString group.gid}:${concatStringsSep "," group.members}"
    ) cfg.groups);

    assertions = [
      { assertion = !cfg.enforceIdUniqueness || (uidsAreUnique && gidsAreUnique);
        message = "UIDs and GIDs must be unique!";
      }
    ] ++ flatten (flip mapAttrsToList cfg.users (name: user:
      [
        {
        assertion = (user.hashedPassword != null)
        -> (builtins.match ".*:.*" user.hashedPassword == null);
        message = ''
            The password hash of user "${user.name}" contains a ":" character.
            This is invalid and would break the login system because the fields
            of /etc/shadow (file where hashes are stored) are colon-separated.
            Please check the value of option `users.users."${user.name}".hashedPassword`.'';
          }
          {
            assertion = let
              xor = a: b: a && !b || b && !a;
              isEffectivelySystemUser = user.isSystemUser || (user.uid != null && user.uid < 500);
            in xor isEffectivelySystemUser user.isNormalUser;
            message = ''
              Exactly one of users.users.${user.name}.isSystemUser and users.users.${user.name}.isNormalUser must be set.
            '';
          }
        ]
    ));

    warnings =
      builtins.filter (x: x != null) (
        flip mapAttrsToList cfg.users (_: user:
        # This regex matches a subset of the Modular Crypto Format (MCF)[1]
        # informal standard. Since this depends largely on the OS or the
        # specific implementation of crypt(3) we only support the (sane)
        # schemes implemented by glibc and BSDs. In particular the original
        # DES hash is excluded since, having no structure, it would validate
        # common mistakes like typing the plaintext password.
        #
        # [1]: https://en.wikipedia.org/wiki/Crypt_(C)
        let
          sep = "\\$";
          base64 = "[a-zA-Z0-9./]+";
          id = "[a-z0-9-]+";
          value = "[a-zA-Z0-9/+.-]+";
          options = "${id}(=${value})?(,${id}=${value})*";
          scheme  = "${id}(${sep}${options})?";
          content = "${base64}${sep}${base64}";
          mcf = "^${sep}${scheme}${sep}${content}$";
        in
        if (allowsLogin user.hashedPassword
            && user.hashedPassword != ""  # login without password
            && builtins.match mcf user.hashedPassword == null)
        then ''
          The password hash of user "${user.name}" may be invalid. You must set a
          valid hash or the user will be locked out of their account. Please
          check the value of option `users.users."${user.name}".hashedPassword`.''
        else null
      ));

  };

}
