{
  # TPM2 auto-unlock of the LUKS root - opt-in, default off.
  #
  # Off (default): the disk is unlocked by typing the LUKS passphrase at boot.
  # Nothing to brick; ships safely in the image.
  #
  # dawo.diskUnlock.tpm2.enable = true: systemd-stage-1 tries the TPM2 device for
  # the root volume, so an enrolled machine unlocks WITHOUT a typed passphrase -
  # the UX win for the pilot. This only enables the unlock PATH; the key must be
  # enrolled once on the device (systemd-cryptenroll, bound to PCR 7 = the Secure
  # Boot state). The passphrase keyslot stays as break-glass. Best paired with
  # dawo.secureboot.enable, since PCR 7 is only meaningful with Secure Boot on.
  #
  # On-device ceremony + recovery: see docs/secureboot-tpm.md. Enabling this flag
  # WITHOUT enrolling first is harmless (it just falls back to the passphrase).
  #
  # Enabling it without Secure Boot is NOT harmless, and the build refuses it:
  # PCR 7 measures the Secure Boot state, so with Secure Boot off the TPM has
  # nothing to check and releases the key to whoever powers the machine on.
  flake.modules.nixos.boot-tpm2-unlock =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.dawo.diskUnlock.tpm2;
    in
    {
      options.dawo.diskUnlock.tpm2 = {
        enable = lib.mkEnableOption ''
          TPM2 auto-unlock of the LUKS root (PCR 7); passphrase kept as
          break-glass. Requires a one-time on-device systemd-cryptenroll first
          (see docs/secureboot-tpm.md)'';
        allowWithoutSecureBoot = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Allow TPM2 unlock on a device without Secure Boot.

            Off, because that combination unlocks the disk for anyone who
            presses the power button. It exists so a bench machine can say so
            out loud instead of the assertion being edited out of the module.
          '';
        };

        device = lib.mkOption {
          type = lib.types.str;
          default = "crypted-main";
          description = "LUKS mapper name. The disko single-nvme-luks layout uses crypted-main.";
        };
      };

      config = lib.mkIf cfg.enable {
        # PCR 7 measures the Secure Boot state and its key database, and nothing
        # else. With Secure Boot off there is nothing meaningful in it, so the
        # TPM hands the key to whoever presses the power button: the disk is
        # encrypted on paper and open in practice. The two belong together, and
        # the build says so rather than a comment hoping somebody read it.
        assertions = [
          {
            assertion = config.dawo.secureboot.enable || cfg.allowWithoutSecureBoot;
            message = ''
              dawo.diskUnlock.tpm2.enable is on while dawo.secureboot.enable is
              off. The TPM would then release the disk key on any boot, because
              PCR 7 measures Secure Boot state and there is none to measure.

              Turn on dawo.secureboot.enable, or set
              dawo.diskUnlock.tpm2.allowWithoutSecureBoot if this device is a
              bench machine where that is the point.
            '';
          }
        ];

        # systemd in stage-1 is required to talk to the TPM at unlock time.
        boot.initrd.systemd.enable = true;
        # Try the TPM2 device for this volume; falls back to the passphrase if the
        # TPM has no enrollment or PCR 7 changed (Secure Boot off/modified).
        boot.initrd.luks.devices.${cfg.device}.crypttabExtraOpts = [ "tpm2-device=auto" ];
      };
    };
}
