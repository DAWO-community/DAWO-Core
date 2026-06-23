{
  # Generic bootstrap + local break-glass admin (login dawo / dawo, in wheel).
  # OPT-OUT via dawo.bootstrapUser.enable (default true): a fresh image is
  # loginable and administerable out of the box. A real deployment with named
  # admins (wheel, agenix passwords) sets it false, so only the named users
  # exist - no documented dawo/dawo login on the device.
  #
  #   login: dawo   password: dawo   (change on first login; mutableUsers = true)
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
      options.dawo.bootstrapUser.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Create the dawo bootstrap/break-glass admin. Set false once named admins (agenix) are in place.";
      };

      config = lib.mkIf cfg.enable {
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
    };
}
