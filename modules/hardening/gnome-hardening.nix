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
      cfg = config.dawo.desktop.gnome.hardening;
      gv = lib.gvariant;
    in
    {
      # Renamed in 0.2: the block sat at dawo.gnomeHardening, which matched
      # neither its subject nor any other block's naming. Kept for one release.
      imports = [
        (lib.mkRenamedOptionModule
          [ "dawo" "gnomeHardening" "enable" ]
          [ "dawo" "desktop" "gnome" "hardening" "enable" ]
        )
        (lib.mkRenamedOptionModule
          [ "dawo" "gnomeHardening" "options" "idleLockSeconds" ]
          [ "dawo" "desktop" "gnome" "hardening" "idleLockSeconds" ]
        )
      ];

      options.dawo.desktop.gnome.hardening = {
        enable = lib.mkEnableOption "locked GNOME hardening dconf profile (opt-in)";
        idleLockSeconds = lib.mkOption {
          type = lib.types.ints.positive;
          default = 300;
          description = "Idle seconds before the screen locks (must be > 0).";
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.idleLockSeconds > 0;
            message = "dawo.desktop.gnome.hardening.idleLockSeconds must be > 0.";
          }
        ];

        programs.dconf.enable = true;
        programs.dconf.profiles.user.databases = [
          {
            settings = {
              "org/gnome/desktop/session".idle-delay = gv.mkUint32 cfg.idleLockSeconds;
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
              # Shell extensions are unvetted code running in the session; off.
              "org/gnome/shell".disable-user-extensions = true;
            };
            locks = [
              "/org/gnome/desktop/screensaver/lock-enabled"
              "/org/gnome/desktop/session/idle-delay"
              "/org/gnome/desktop/privacy/remember-recent-files"
              "/org/gnome/desktop/lockdown/disable-user-switching"
              "/org/gnome/desktop/lockdown/disable-command-line"
              "/org/gnome/shell/disable-user-extensions"
            ];
          }
        ];
      };
    };
}
