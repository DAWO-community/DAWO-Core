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
            # No keys in the generic core. SSH admin/deploy keys are added by the
            # organisation overlay (e.g. Zaanstad), per ADR-0001/0003.
            openssh.authorizedKeys.keys = [ ];
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
