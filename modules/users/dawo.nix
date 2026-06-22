{
  # Generic demo/bootstrap user. The default password is documented so a fresh
  # image is actually loginable (the previous hash had no known plaintext).
  #
  #   login: dawo   password: dawo
  #
  # initialHashedPassword only applies at first creation and mutableUsers = true,
  # so change it after first login (passwd). For real deployments give the host
  # its own gitops user (hashedPasswordFile via agenix) and drop this one; see
  # docs/users.md.
  #
  # wheel: this bootstrap user is the local break-glass admin. With root locked
  # (users-basics sets hashedPassword "!"), if dawo were not in wheel a host with
  # no other admin and no deploy key would be impossible to administer locally -
  # exactly the lockout we hit. dawo in wheel means the documented dawo/dawo
  # login can always sudo. A real deployment replaces this with named admins
  # (wheel, agenix passwords) and can drop dawo.
  flake.modules.nixos.users-dawo =
    { ... }:
    {
      users = {
        mutableUsers = true;
        users = {
          dawo = {
            description = "DAWO";
            home = "/home/dawo";
            group = "users";
            extraGroups = [ "wheel" ];
            createHome = true;
            homeMode = "700";
            # yescrypt hash of "dawo" (documented default; change on first login).
            initialHashedPassword = "$y$j9T$10bcN0cBIS0Tky6KQt/QF1$kEEq8BickyLduybuTVEZnxgt5yj1yZQph.HNuRQ2fs/";
            isSystemUser = false;
            isNormalUser = true;
            # shell: default (bash). zsh is opt-in via dawo.zsh.enable.
          };
        };
      };
    };
}
