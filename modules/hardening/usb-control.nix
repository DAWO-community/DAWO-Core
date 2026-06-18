{
  # USB device control (BIO/NCSC). MANDATORY-core tier.
  # Block-default + allow for already-present devices (no lockout on
  # keyboard/mouse). Norm: BIO USB device control / NCSC. Origin: DAWO-specific
  # (not in securix). See architecture.md "Key Design Decisions".
  #
  # The USBGuard policy is forced (lib.mkForce) - mandatory, not weakenable.
  # `allowlist` is the tunable; an empty list is a *defined, safe* default
  # (block-new / allow-present), not an undefined option (#8), so no warning.
  flake.modules.nixos.hardening-usb-control =
    { config, lib, ... }:
    let
      cfg = config.dawo.usbControl;
    in
    {
      options.dawo.usbControl = {
        enable = lib.mkEnableOption "USBGuard device authorization (BIO/NCSC)";
        options.allowlist = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [ ''allow id 18d1:4ee2 name "phone-tether"'' ];
          description = ''
            Extra USBGuard rules (one per line). Empty keeps the safe default:
            block newly-inserted devices, allow whatever is present at boot, so a
            fresh import never bricks its own keyboard. A host that must hotplug a
            fixed dongle adds an `allow id VID:PID` line here (lsusb for the IDs).
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        services.usbguard = {
          # Forced: the mandatory block-default policy.
          enable = lib.mkForce true;
          implicitPolicyTarget = lib.mkForce "block";
          presentDevicePolicy = lib.mkForce "allow";
          insertedDevicePolicy = lib.mkForce "block";
          IPCAllowedUsers = lib.mkForce [
            "root"
            "dawo"
          ];
          # Tunable: extra allow rules merged into the forced policy.
          rules = lib.concatStringsSep "\n" cfg.options.allowlist;
        };
      };
    };
}
