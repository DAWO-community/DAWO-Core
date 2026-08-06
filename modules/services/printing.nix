{
  # Printing (CUPS) + network-printer discovery (Avahi/mDNS). Opt-in, off by
  # default; a workplace overlay flips dawo.printing.enable. FOSS all the way
  # (CUPS + Avahi), no proprietary print stack.
  #
  # Printing TO a network printer is outbound (IPP over TCP 631) -> works
  # through the default deny-inbound firewall untouched. Only *discovery*
  # (mDNS) needs an open port, which services.avahi.openFirewall handles (5353).
  #
  # `drivers` names a set rather than taking a package list. The person who
  # decides whether a fleet needs vendor drivers is not the person who knows
  # which nixpkgs attributes provide them, and the decision is the same for
  # every device in a deployment: take the driver-less path, or carry the
  # vendor set for older hardware. A package list encodes the implementation
  # of that decision instead of the decision.
  flake.modules.nixos.services-printing =
    { config, lib, pkgs, ... }:
    let
      cfg = config.dawo.printing;
    in
    {
      options.dawo.printing = {
        enable = lib.mkEnableOption "printing (CUPS) on this device";

        discover = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Find printers announced on the local network automatically
            (mDNS/IPP). Off means only printers configured centrally are
            available - the right choice for a site that publishes its printers
            from a server, and for a laptop that should not answer for printers
            on whatever network it happens to be on.
          '';
        };

        drivers = lib.mkOption {
          type = lib.types.enum [ "open" "broad" ];
          default = "open";
          description = ''
            Driver set. `open` covers the standard IPP Everywhere / PostScript
            path most office printers speak. `broad` adds vendor driver packages
            for older hardware, at the cost of a considerably larger system
            closure on every device that has it.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        services.printing = {
          enable = true;
          # Driver-less IPP Everywhere first; the broad set is opt-in because it
          # pulls a large amount of vendor code onto every device in the fleet.
          drivers =
            if cfg.drivers == "broad" then
              (with pkgs; [ gutenprint gutenprintBin hplip splix brlaser ])
            else
              (with pkgs; [ gutenprint ]);
        };

        # Discovery needs mDNS resolution in NSS, not just an avahi daemon:
        # without it a printer announces itself and nothing on the device can
        # resolve the name it announces.
        services.avahi = lib.mkIf cfg.discover {
          enable = true;
          nssmdns4 = true;
          openFirewall = true;
        };

        # A DE-agnostic printer GUI, but only where the desktop lacks one.
        # GNOME ships its own printer panel, so installing this there gives a
        # user two different dialogues for the same job.
        environment.systemPackages =
          lib.mkIf (config.dawo.desktop.plasma.enable or false)
            [ pkgs.system-config-printer ];
      };
    };
}
