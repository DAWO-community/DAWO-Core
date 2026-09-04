{
  # Application sets as blocks. The generic baseline ships only universal
  # tools (see environment-dawo-pkgs); app sets are off by default and a host or
  # overlay enables what it needs. The exception is dawo.apps.security, which is
  # opt-out: a password manager is a security control, not a taste.
  # Vendor/org-specific apps (microsoft-edge, teams-for-linux) are NOT here -
  # they live in the consuming organisation's overlay.
  # The office suite is swappable (libreoffice | collabora) so a
  # deployment can switch with one line. (EuroOffice is a candidate to add once
  # it is solid; OnlyOffice is deliberately excluded - sovereignty concern.)
  flake.modules.nixos.apps-sets =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.dawo.apps;
      officePkg =
        {
          inherit (pkgs) libreoffice;
          collabora = pkgs.collabora-desktop;
        }
        .${cfg.office.suite};
    in
    {
      options.dawo.apps = {
        office.enable = lib.mkEnableOption "office suite + mail (Thunderbird)";
        office.suite = lib.mkOption {
          type = lib.types.enum [
            "libreoffice"
            "collabora"
          ];
          default = "libreoffice";
          description = "Office suite installed when dawo.apps.office is enabled. Collabora resonates more with users coming from Windows.";
        };
        comms.enable = lib.mkEnableOption "communication apps (Element)";
        creative.enable = lib.mkEnableOption "creative apps (GIMP, Inkscape, Krita, Penpot)";
        media.enable = lib.mkEnableOption "media player (VLC)";
        dev.enable = lib.mkEnableOption "developer tools (VSCodium, Nix toolchain, gcc)";
        security.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Password manager (KeePassXC). The one set that is opt-out: without a password manager people reuse passwords or write them down, so a deployment has to say no on purpose (e.g. it ships an organisation-wide vault).";
        };
      };

      config = lib.mkMerge [
        (lib.mkIf cfg.office.enable {
          environment.systemPackages = [
            officePkg
            pkgs.thunderbird
          ];
        })
        (lib.mkIf cfg.comms.enable {
          environment.systemPackages = [ pkgs.element-desktop ];
        })
        (lib.mkIf cfg.creative.enable {
          environment.systemPackages = with pkgs; [
            gimp-with-plugins
            inkscape
            krita
            penpot-desktop
          ];
        })
        (lib.mkIf cfg.media.enable {
          environment.systemPackages = [ pkgs.vlc ];
        })
        (lib.mkIf cfg.security.enable {
          environment.systemPackages = [ pkgs.keepassxc ];
        })
        (lib.mkIf cfg.dev.enable {
          environment.systemPackages = with pkgs; [
            ctags
            direnv
            gcc
            nil
            nixd
            nixfmt
            nix-search-cli
            uv
            vscodium
          ];
        })
      ];
    };
}
