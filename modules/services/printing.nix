{
  # Printing (CUPS) + network-printer discovery (Avahi/mDNS). Opt-in, off by
  # default; a workplace overlay flips dawo.printing.enable. FOSS all the way
  # (CUPS + Avahi), no proprietary print stack.
  #
  # Printing TO a network printer is outbound (IPP over TCP 631) -> works
  # through the default deny-inbound firewall untouched. Only *discovery*
  # (mDNS) needs an open port, which services.avahi.openFirewall handles (5353).
  flake.modules.nixos.services-printing =
    { config, lib, pkgs, ... }:
    let
      cfg = config.dawo.printing;
    in
    {
      options.dawo.printing = {
        enable = lib.mkEnableOption "printing (CUPS) + mDNS printer discovery";
        drivers = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = with pkgs; [
            gutenprint # broad coverage (Epson/Canon/many)
            hplip # HP inkjet/laser
          ];
          description = ''
            Extra CUPS drivers. Modern network printers speak driverless IPP
            Everywhere and need nothing here; add vendor packages only for older
            or USB models. Keep the list small -> smaller closure.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        services.printing = {
          enable = true;
          drivers = cfg.drivers;
        };

        # mDNS/Bonjour so GNOME/Plasma auto-find network printers. nssmdns4
        # resolves *.local; openFirewall opens UDP 5353 for the discovery.
        services.avahi = {
          enable = true;
          nssmdns4 = true;
          openFirewall = true;
        };

        # DE-agnostic GUI to add/manage printers (GNOME has its own panel; this
        # covers Plasma and any DE). Printer admin authenticates via polkit ->
        # wheel members (our pilot users) can add printers.
        environment.systemPackages = [ pkgs.system-config-printer ];
      };
    };
}
