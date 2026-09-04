{
  # USB device control (BIO/NCSC). Opt-in, and that is a decision rather than an
  # omission: blocking a stick or a dongle out of the box is the kind of default
  # that makes a device feel broken to the person using it, and DAWO has to be
  # installable by somebody who will not go looking for the reason. A deployment
  # that wants it turns it on, per device or per fleet.
  #
  # The header used to say MANDATORY-core tier while no host imported the block
  # at all, which is the worst of both: a claim in a comment and nothing on the
  # device. It is selectable through the register now, at the hardened level.
  #
  # Block-default + allow for already-present devices (no lockout on
  # keyboard/mouse). Norm: BIO USB device control / NCSC.
  #
  # Once on, the USBGuard policy itself is forced (lib.mkForce): a deployment
  # chooses whether to run it, not how much of it to run. `allowlist` is the
  # tunable; an empty list is a defined, safe default (block-new /
  # allow-present).
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
