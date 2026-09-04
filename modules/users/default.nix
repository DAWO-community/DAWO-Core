{
  flake.modules.nixos.users-basics = _: {
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
