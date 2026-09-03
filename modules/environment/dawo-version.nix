{ inputs, ... }:
{
  # Build provenance + on-device proof. Bakes the flake revision into the system
  # (system.configurationRevision, shown by `nixos-version --configuration-revision`)
  # and ships `dawo-proof`: a fastfetch panel (flake rev + desktop) plus a short
  # verification log. Run it on an installed machine and screenshot it to prove,
  # per device, exactly which flake commit + package set is running. neofetch is
  # archived upstream; fastfetch is its maintained successor.
  flake.modules.nixos.environment-dawo-version =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # Human-readable release name, cut as a git tag on the release commit. The
      # flake rev below is the exact provenance; this is the friendly version a
      # user or support desk reads off the device.
      releaseVersion = "0.1.2";
      flakeRev = inputs.self.rev or inputs.self.dirtyRev or "dirty";
      nixpkgsRev = inputs.nixpkgs.rev or inputs.nixpkgs.shortRev or "unknown";
      desktop =
        if config.dawo.desktop.plasma.enable or false then
          "KDE Plasma 6"
        else if config.dawo.desktop.gnome.enable or false then
          "GNOME"
        else
          "none";

      ffConfig = pkgs.writeText "dawo-fastfetch.jsonc" (builtins.toJSON {
        logo.source = "nixos";
        modules = [
          "title"
          "separator"
          "os"
          "kernel"
          "uptime"
          { type = "de"; key = "Desktop"; }
          { type = "custom"; format = "------------ DAWO ------------"; }
          { type = "custom"; key = "Release"; format = releaseVersion; }
          { type = "custom"; key = "Flake rev"; format = flakeRev; }
          { type = "custom"; key = "nixpkgs"; format = nixpkgsRev; }
          { type = "custom"; key = "Desktop block"; format = desktop; }
        ];
      });

      dawo-proof = pkgs.writeShellApplication {
        name = "dawo-proof";
        runtimeInputs = [ pkgs.fastfetch ];
        text = ''
          fastfetch -c ${ffConfig}
          echo
          echo "------------ verification ------------"
          echo "build:     $(readlink -f /run/current-system)"
          echo "host:      $(hostname)"
          echo "-- local accounts in wheel --"
          getent group wheel | cut -d: -f4 | tr ',' '\n' | sed 's/^/  /' || echo "  (none)"
          echo "-- agenix secrets decrypted --"
          find /run/agenix -mindepth 1 -maxdepth 1 -printf '  %f\n' 2>/dev/null || echo "  (none)"
          echo "-- hardening rules --"
          # The rules this device actually carries, from the register, rather
          # than a hand-kept list of service names. The previous version looked
          # for usbguard and auditd, which no host runs, and for a user that
          # exists in no module: it proved a configuration this repository does
          # not build.
          dawo-verify || true
          echo "-- secure boot --"
          bootctl status 2>/dev/null | grep -i 'secure boot' | sed 's/^ */  /' || true
        '';
      };
    in
    {
      system.configurationRevision = lib.mkDefault flakeRev;

      environment.etc."dawo/release".text = ''
        release=${releaseVersion}
        flake-rev=${flakeRev}
        nixpkgs-rev=${nixpkgsRev}
        nixos=${config.system.nixos.version}
        desktop=${desktop}
      '';

      environment.systemPackages = [
        pkgs.fastfetch
        dawo-proof
      ];
    };
}
