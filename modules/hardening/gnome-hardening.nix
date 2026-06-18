{
  # GNOME desktop hardening (BIO/NCSC). OPT-IN tier (default off).
  # Ships a locked dconf profile: automatic screen lock, privacy (no recent-file
  # history, clean trash and temp), and lockdown (no user switching, no command
  # line). The keys are locked so a user cannot relax them. Only meaningful with
  # desktop-gnome. Norm: NCSC end-user device + CIS GNOME. See architecture.md
  # "Key Design Decisions".
  flake.modules.nixos.hardening-gnome =
    { config, lib, ... }:
    let
      cfg = config.dawo.gnomeHardening;
      gv = lib.gvariant;
    in
    {
      options.dawo.gnomeHardening = {
        enable = lib.mkEnableOption "locked GNOME hardening dconf profile (opt-in)";
        options.idleLockSeconds = lib.mkOption {
          type = lib.types.ints.positive;
          default = 300;
          description = "Idle seconds before the screen locks (must be > 0).";
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.options.idleLockSeconds > 0;
            message = "dawo.gnomeHardening.options.idleLockSeconds must be > 0.";
          }
        ];

        programs.dconf.enable = true;
        programs.dconf.profiles.user.databases = [
          {
            settings = {
              "org/gnome/desktop/session".idle-delay = gv.mkUint32 cfg.options.idleLockSeconds;
              "org/gnome/desktop/screensaver" = {
                lock-enabled = true;
                lock-delay = gv.mkUint32 0;
              };
              "org/gnome/desktop/privacy" = {
                remember-recent-files = false;
                remove-old-trash-files = true;
                remove-old-temp-files = true;
                report-technical-problems = false;
              };
              "org/gnome/desktop/lockdown" = {
                disable-user-switching = true;
                disable-lock-screen = false;
                disable-command-line = true;
              };
            };
            locks = [
              "/org/gnome/desktop/screensaver/lock-enabled"
              "/org/gnome/desktop/session/idle-delay"
              "/org/gnome/desktop/privacy/remember-recent-files"
              "/org/gnome/desktop/lockdown/disable-user-switching"
              "/org/gnome/desktop/lockdown/disable-command-line"
            ];
          }
        ];
      };
    };
}
