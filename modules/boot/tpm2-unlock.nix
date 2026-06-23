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
        device = lib.mkOption {
          type = lib.types.str;
          default = "crypted-main";
          description = "LUKS mapper name. The disko single-nvme-luks layout uses crypted-main.";
        };
      };

      config = lib.mkIf cfg.enable {
        # systemd in stage-1 is required to talk to the TPM at unlock time.
        boot.initrd.systemd.enable = true;
        # Try the TPM2 device for this volume; falls back to the passphrase if the
        # TPM has no enrollment or PCR 7 changed (Secure Boot off/modified).
        boot.initrd.luks.devices.${cfg.device}.crypttabExtraOpts = [ "tpm2-device=auto" ];
      };
    };
}
