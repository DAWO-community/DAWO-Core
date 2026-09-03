{
  # Generic bootstrap + local break-glass admin, in wheel.
  # OPT-OUT via dawo.bootstrapUser.enable (default true): a fresh image is
  # loginable and administerable out of the box. A real deployment with named
  # admins (wheel, agenix passwords) sets it false, so only the named users
  # exist and no bootstrap login remains on the device.
  #
  # The account existing is the point: DAWO has to be installable by somebody
  # with no technical knowledge, and an image nobody can log into fails that
  # before it starts. So the default stays.
  #
  # What is a deployment choice is the password.
  # dawo.bootstrapUser.initialHashedPassword takes one this deployment owns.
  # Without it the account falls back to the password written down here, which
  # is right for a first install and wrong for a device in use, so that case
  # warns at build time until somebody either sets a hash, turns the account
  # off, or acknowledges the default on purpose.
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

        acknowledgeDefaultPassword = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Say out loud that this deployment means to ship the password
            documented in this module, and silence the warning about it.

            The account exists so that somebody with no technical knowledge
            ends up with a machine they can log into, which is worth keeping.
            This option is how a deployment separates "we chose this" from
            "nobody looked".
          '';
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
        warnings =
          lib.optional (cfg.initialHashedPassword == "" && !cfg.acknowledgeDefaultPassword)
            ''
              dawo.bootstrapUser is enabled with the password documented in this
              module, so this device has a local administrator anyone can log in
              as. That is the intended default for a first install and not for a
              device in use.

              Set dawo.bootstrapUser.initialHashedPassword, or disable the
              account once a named admin works, or set
              dawo.bootstrapUser.acknowledgeDefaultPassword to say this
              deployment means it.
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
