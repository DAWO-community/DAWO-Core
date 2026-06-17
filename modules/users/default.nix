{
  flake.modules.nixos.users-basics =
    { ... }:
    {
      users = {
        mutableUsers = true;
        users = {
          root = {
            hashedPassword = "!";
          };
        };
      };
    };
}
