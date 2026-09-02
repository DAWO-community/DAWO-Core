{
  # Workplace-baseline coverage gate. `nix flake check` fails if a host is missing
  # a functionality the baseline promises - the class of gap that shipped silent
  # GNOME audio and a missing CUPS. Cheap eval-time assertions on a Plasma and a
  # GNOME host (no VM boot). Add a line whenever a new baseline is promised, so
  # "we forgot to enable X" cannot slip through.
  flake =
    { lib, config, ... }:
    let
      hosts = {
        plasma = config.nixosConfigurations.dawo-hp-probook-4g1i;
        gnome = config.nixosConfigurations.dawo-t495s-gnome;
      };
      pkgs = hosts.plasma.pkgs;
      hasFont = cfg: needle: lib.any (p: lib.hasInfix needle (p.name or "")) cfg.config.fonts.packages;
      hasPkg = cfg: needle: lib.any (p: lib.hasInfix needle (p.name or "")) cfg.config.environment.systemPackages;
      claims = name: cfg: [
        { n = "${name}: PipeWire audio"; ok = cfg.config.services.pipewire.enable; }
        { n = "${name}: SANE scanning"; ok = cfg.config.hardware.sane.enable; }
        { n = "${name}: NetworkManager"; ok = cfg.config.networking.networkmanager.enable; }
        { n = "${name}: no generic autoUpgrade (comin only)"; ok = !cfg.config.system.autoUpgrade.enable; }
        { n = "${name}: color emoji font"; ok = hasFont cfg "noto-fonts-color-emoji"; }
        { n = "${name}: dawo-update-status shipped"; ok = hasPkg cfg "dawo-update-status"; }
      ];
      fails = lib.filter (c: !c.ok) (lib.concatLists (lib.mapAttrsToList claims hosts));
    in
    {
      checks.x86_64-linux.workplace-baseline =
        if fails == [ ] then
          pkgs.runCommand "workplace-baseline-ok" { } "echo 'workplace baseline OK' > $out"
        else
          throw "workplace-baseline GAP(s): ${lib.concatMapStringsSep "; " (c: c.n) fails}";
    };
}
