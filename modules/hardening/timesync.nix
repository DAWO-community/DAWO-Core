{
  # NTP via chrony - reliable time is a precondition for usable logs.
  # MANDATORY-core tier. Norm: BIO (time sync for log correlation).
  # See architecture.md "Key Design Decisions".
  #
  # chrony itself is forced on; the server list is a suggested default a host
  # may swap for an internal NTP. An empty list is rejected at build time
  # (#8: no silently-undefined options - empty servers = no time = broken logs).
  #
  # Laptops suspend, and a suspended clock drifts. Two settings keep it honest
  # (#49): the clock may be stepped at any moment instead of only during the
  # first few updates after start, and chronyd is restarted on resume so it
  # re-measures the offset right away instead of waiting for its poll interval.
  flake.modules.nixos.hardening-timesync =
    { config, lib, ... }:
    let
      cfg = config.dawo.timesync;

      sleepTargets = [
        "suspend.target"
        "hibernate.target"
        "hybrid-sleep.target"
        "suspend-then-hibernate.target"
      ];
    in
    {
      # Renamed in 0.2: the `options` level went away. Kept for one release.
      imports = [
        (lib.mkRenamedOptionModule
          [ "dawo" "timesync" "options" "servers" ]
          [ "dawo" "timesync" "servers" ]
        )
      ];

      options.dawo.timesync = {
        enable = lib.mkEnableOption "NTP time synchronization via chrony (BIO)";
        servers = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "ntp.time.nl"
            "0.nl.pool.ntp.org"
            "1.nl.pool.ntp.org"
          ];
          description = "NTP servers (must be non-empty). Override per organisation (e.g. an internal NTP).";
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.servers != [ ];
            message = "dawo.timesync.servers must list at least one NTP server (empty = no time sync = unusable log correlation).";
          }
        ];

        services.chrony = {
          enable = lib.mkForce true;
          servers = cfg.servers;

          # The NixOS default is `makestep 0.1 3`: after three steps chronyd only
          # ever slews, which crawls back a post-resume offset of minutes or hours
          # at ~1 part in 12. We want `makestep 1.0 -1` - step on any error above a
          # second, without a limit on how often. The limit is typed as a positive
          # integer upstream, so -1 cannot go through services.chrony.makestep and
          # the directive is written out by hand instead.
          makestep.enable = false;
          extraConfig = ''
            makestep 1.0 -1
          '';
        };

        # A step needs a fresh measurement, and chronyd will not take one until
        # its next poll - up to ~17 minutes on a settled client. Restarting it
        # after a resume forces that measurement straight away. A unit that is
        # `after` and `wantedBy` a sleep target runs on the way back up, which is
        # the recipe from systemd.special(7). try-restart is a no-op if chronyd
        # is not running.
        systemd.services."chrony-resume" = {
          description = "Re-sync the system clock after resume";
          after = sleepTargets;
          wantedBy = sleepTargets;
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${config.systemd.package}/bin/systemctl try-restart chronyd.service";

            # It asks systemd to restart one unit and does nothing else, so it
            # gets nothing else: no write access, no home, no capabilities.
            # Talking to systemd goes over /run/systemd/private, which a
            # read-only filesystem does not block.
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            ProtectKernelTunables = true;
            ProtectKernelModules = true;
            ProtectControlGroups = true;
            RestrictAddressFamilies = [ "AF_UNIX" ];
            NoNewPrivileges = true;
            CapabilityBoundingSet = "";
          };
        };
      };
    };
}
