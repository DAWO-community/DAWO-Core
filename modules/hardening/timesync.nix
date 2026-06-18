{
  # NTP via chrony - reliable time is a precondition for usable logs.
  # MANDATORY-core tier. Norm: BIO (time sync for log correlation).
  # See architecture.md "Key Design Decisions".
  #
  # chrony itself is forced on; the server list is a suggested default a host
  # may swap for an internal NTP. An empty list is rejected at build time
  # (#8: no silently-undefined options - empty servers = no time = broken logs).
  flake.modules.nixos.hardening-timesync =
    { config, lib, ... }:
    let
      cfg = config.dawo.timesync;
    in
    {
      options.dawo.timesync = {
        enable = lib.mkEnableOption "NTP time synchronization via chrony (BIO)";
        options.servers = lib.mkOption {
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
            assertion = cfg.options.servers != [ ];
            message = "dawo.timesync.options.servers must list at least one NTP server (empty = no time sync = unusable log correlation).";
          }
        ];

        services.chrony = {
          enable = lib.mkForce true;
          servers = cfg.options.servers;
        };
      };
    };
}
