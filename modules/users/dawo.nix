{
  # Generic bootstrap + local break-glass admin, in wheel.
  # OPT-OUT via dawo.bootstrapUser.enable (default true): a fresh image is
  # loginable and administerable out of the box. A real deployment with named
  # admins (wheel, agenix passwords) sets it false, so only the named users
  # exist and no bootstrap login remains on the device.
  #
  # The password is a deployment choice, not a constant. Without
  # dawo.bootstrapUser.initialHashedPassword the account falls back to a
  # password that is written down in this repository, which is fine on a bench
  # and is not fine on a device that leaves it. That case warns at build time,
  # loudly, every time.
  #
  # wheel: with root locked (users-basics sets hashedPassword "!"), a host with
  # no admin and no deploy key cannot be administered locally - the lockout we
  # hit. So whoever you keep MUST be in wheel: dawo here, or a named admin in the
  # overlay. Do not drop dawo until a named wheel admin is proven to work.
  flake.modules.nixos.users-dawo =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.dawo.bootstrapUser;
    in
    {
      options.dawo.bootstrapUser = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Create the dawo bootstrap/break-glass admin. Set false once named admins (agenix) are in place.";
        };

        initialHashedPassword = lib.mkOption {
          type = lib.types.str;
          default = "";
          example = "$y$j9T$...";
          description = ''
            Hash for the bootstrap account's first password, as `mkpasswd`
            prints it. Empty falls back to the hash of the word written in this
            module, which every reader of the repository knows.

            It applies at account creation only (`mutableUsers = true`), so
            changing it later does not reach a device that already exists.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        warnings = lib.optional (cfg.initialHashedPassword == "") ''
          dawo.bootstrapUser is enabled with the password documented in this
          repository. That is a local administrator anyone can log in as. Set
          dawo.bootstrapUser.initialHashedPassword, or disable the account,
          before this device leaves the bench.
        '';

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
              # Fallback: the yescrypt hash of the word "dawo". Only reached
              # when a deployment set no hash of its own, and the warning above
              # fires whenever that happens.
              initialHashedPassword =
                if cfg.initialHashedPassword != "" then
                  cfg.initialHashedPassword
                else
                  "$y$j9T$10bcN0cBIS0Tky6KQt/QF1$kEEq8BickyLduybuTVEZnxgt5yj1yZQph.HNuRQ2fs/";
              isSystemUser = false;
              isNormalUser = true;
              # shell: default (bash). zsh is opt-in via dawo.zsh.enable.
            };
          };
        };
      };
    };
}
