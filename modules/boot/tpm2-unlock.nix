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
  # Boot state). The passphrase keyslot stays as break-glass.
  #
  # PCR 7 ONLY, and that is a decision, not an oversight (#111): PCR 7 measures
  # the firmware's Secure Boot policy (which keys and binaries firmware
  # accepts), not the boot chain itself. With Secure Boot enforced that is
  # "anything the firmware refuses to run cannot have asked the TPM for the key",
  # which covers the initrd-replacement attack this block exists for. PCRs 4 and
  # 11 (bootloader/UKI) would bind tighter but break on every kernel generation
  # and make the passphrase the daily unlock again - the opposite of the goal.
  # Revisit only if a signed-boot bypass surfaces; until then PCR 7 + Secure Boot
  # is the accepted pair, and the assertion below refuses the half of the pair
  # that is not a guarantee on its own.
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
          (see docs/secureboot-tpm.md), and requires dawo.secureboot.enable:
          PCR 7 only measures anything with Secure Boot on, so the TPM would
          otherwise hand the key to whatever booted (#111)'';
        device = lib.mkOption {
          type = lib.types.str;
          default = "crypted-main";
          description = "LUKS mapper name. The disko single-nvme-luks layout uses crypted-main.";
        };
      };

      config = lib.mkIf cfg.enable {
        # The two together are the guarantee; either alone is not. Without
        # Secure Boot the TPM releases the disk key to an initrd anyone with
        # physical access could have swapped in, so this fails the build
        # instead of shipping a lock that opens for whoever holds the laptop.
        assertions = [
          {
            # A consumer without the secureboot block has no Secure Boot, so
            # attrByPath defaulting to false makes the assertion refuse.
            assertion = lib.attrByPath [ "dawo" "secureboot" "enable" ] false config;
            message = ''
              dawo.diskUnlock.tpm2.enable requires dawo.secureboot.enable:
              TPM2 unlock is bound to PCR 7, which only measures the boot
              chain when Secure Boot is on. Turn on Secure Boot (enroll the
              sbctl keys first - see docs/secureboot-tpm.md) or leave the disk
              on the typed passphrase.
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
