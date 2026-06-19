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
  flake.modules.nixos.users-dawo =
    { pkgs, ... }:
    {
      users = {
        mutableUsers = true;
        users = {
          dawo = {
            description = "DAWO";
            home = "/home/dawo";
            group = "users";
            createHome = true;
            homeMode = "700";
            # yescrypt hash of "dawo" (documented default; change on first login).
            initialHashedPassword = "$y$j9T$10bcN0cBIS0Tky6KQt/QF1$kEEq8BickyLduybuTVEZnxgt5yj1yZQph.HNuRQ2fs/";
            isSystemUser = false;
            isNormalUser = true;
            shell = pkgs.zsh;
          };
        };
      };
    };
}
