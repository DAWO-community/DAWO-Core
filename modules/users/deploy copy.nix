{
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
            initialHashedPassword = "$y$j9T$IqSJUSvGzjf1oaoB6AmaA.$3ruW5cHDgDb.uVid13eFAXU1AAX5woX0R2ZTjhM7jAB";
            isSystemUser = false;
            isNormalUser = true;
            shell = pkgs.zsh;
          };
        };
      };
    };
}
