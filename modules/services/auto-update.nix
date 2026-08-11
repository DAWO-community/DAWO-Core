{
  # Fleet auto-update via comin (git-driven reconcile). Tracks a flake on
  # Codeberg and rebuilds the device when new commits land.
  #
  # A bare device tracks the upstream core (DAWO-NixOS). A workplace points
  # repoUrl at its own overlay flake, which consumes the core as an input, so
  # the chosen overlay is pulled in on every update. Follows the dawo.<block>
  # interface; replaces the hard-wired services-comin.
  flake.modules.nixos.services-auto-update =
    {
      config,
      inputs,
      lib,
      ...
    }:
    let
      cfg = config.dawo.autoUpdate;
    in
    {
      imports = [ inputs.comin.nixosModules.comin ];

      options.dawo.autoUpdate = {
        enable = lib.mkEnableOption "git-driven auto-update via comin";
        options.repoUrl = lib.mkOption {
          type = lib.types.str;
          default = "https://codeberg.org/DAWO/DAWO-Core.git";
          description = ''
            Git repository to track. A bare device tracks the upstream core; a
            workplace points this at its own overlay flake (which consumes the
            DAWO core as an input) so the chosen overlay rides along.

            The default is the address the core moved to. A device that was
            imaged before the move and never had this set keeps polling the old
            one until it takes an update that carries this change, which it
            cannot take from a repository that no longer moves: such a device
            has to be pointed at the new URL by hand once.
          '';
        };
        options.branch = lib.mkOption {
          type = lib.types.str;
          default = "main";
          description = "Branch to follow on repoUrl.";
        };
        options.pollSeconds = lib.mkOption {
          type = lib.types.ints.positive;
          default = 1800;
          description = "Poll interval in seconds (must be > 0).";
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.options.repoUrl != "";
            message = "dawo.autoUpdate.options.repoUrl must be set (the image/overlay flake to track).";
          }
        ];

        services.comin = {
          enable = true;
          remotes = [
            {
              name = "dawo-image";
              url = cfg.options.repoUrl;
              branches.main.name = cfg.options.branch;
              poller.period = cfg.options.pollSeconds;
            }
          ];
        };
      };
    };
}
