{
  flake.modules.nixos.users-deploy =
    { ... }:
    {
      users = {
        mutableUsers = true;
        users = {
          deploy = {
            description = "NixOS Deploy";
            home = "/home/deploy";
            group = "users";
            createHome = true;
            homeMode = "700";
            initialHashedPassword = "$y$j9T$.KcXvkwksnJKfQDUhYlJ/.$XxtOo.bm7sPdTfWH615.lvjIAmv5yYQeyG3ZBxIBMX2";
            isSystemUser = true;
            isNormalUser = false;
            # shell: default (bash). zsh is opt-in via dawo.zsh.enable.
            extraGroups = [
              "wheel"
              "podman"
              "nixbld"
            ];
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPpNXWvAu+gS5DTurz9xl9RUr/5XDzfOZlFS0lLOm9IP deploy@bitwarden"
            ];
          };
        };
      };
      nix.settings.trusted-users = [ "deploy" ];
      security.sudo.extraRules = [
        {
          users = [ "deploy" ];
          commands = [
            {
              command = "ALL";
              options = [ "NOPASSWD" ]; # don't need the ":" at the end
            }
          ];
        }
      ];
    };
}
