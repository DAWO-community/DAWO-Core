{
  # Boot loader, with Secure Boot as an opt-in.
  #
  # Default (dawo.secureboot.enable = false): plain systemd-boot. A device boots
  # straight away after a fresh nixos-anywhere install - no key ceremony, nothing
  # to brick.
  #
  # dawo.secureboot.enable = true: lanzaboote-signed UKI boot. This REQUIRES sbctl
  # keys present at pkiBundle and enrolled in firmware first (see docs/deploy.md);
  # enabling it without enrolled keys is what leaves a device unbootable. So Secure
  # Boot is a deliberate second step, flipped once the keys are in place.
  flake.modules.nixos.boot-loader =
    {
      config,
      pkgs,
      lib,
      inputs,
      ...
    }:
    let
      cfg = config.dawo.secureboot;
    in
    {
      imports = [
        inputs.lanzaboote.nixosModules.lanzaboote
      ];

      options.dawo.secureboot = {
        enable = lib.mkEnableOption "lanzaboote Secure Boot (requires sbctl keys enrolled at pkiBundle)";
        pkiBundle = lib.mkOption {
          type = lib.types.str;
          default = "/var/lib/sbctl";
          description = "Directory holding the sbctl PKI bundle used to sign boot files.";
        };
      };

      config = lib.mkMerge [
        {
          # Common to both loaders.
          boot.initrd.systemd.enable = true;
          boot.loader.efi.canTouchEfiVariables = true;
          # Boot menu hidden; press a key during boot to reveal the generation list.
          boot.loader.timeout = lib.mkDefault 0;
        }

        (lib.mkIf (!cfg.enable) {
          # Reliable default: systemd-boot, no signing.
          boot.loader.systemd-boot.enable = true;
          boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;
        })

        (lib.mkIf cfg.enable {
          # Hardened: lanzaboote. systemd-boot must be off; lanzaboote replaces it.
          boot.loader.systemd-boot.enable = lib.mkForce false;
          boot.loader.systemd-boot.configurationLimit = 5;
          boot.lanzaboote = {
            enable = true;
            pkiBundle = cfg.pkiBundle;
          };
          environment.systemPackages = with pkgs; [
            sbctl
            tpm2-tools
            tpm2-tss
          ];
        })
      ];
    };
}
