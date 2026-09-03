{
  # What a person sitting at the machine may do without proving who they are.
  #
  # There were no polkit rules at all, so the stock desktop policy applied and
  # nobody had decided anything. These two rules decide the cases that matter on
  # a fleet laptop and leave the rest alone, because polkit is where a hardening
  # pass can quietly make a device unusable.
  flake.dawo.rules = {
    "polkit-firmware-needs-admin" = {
      title = "Flashing firmware asks for an administrator";
      severity = "baseline";
      tags = [ "desktop" ];
      compliance = [ "bio" ];
      why = ''
        Firmware survives a reinstall and sits under everything else on the
        device. On a managed fleet that is an operator's decision, not a
        notification somebody clicks away on a train. A UEFI or dbx update
        also changes PCR 7, so on a device with TPM2 unlock it brings back
        the passphrase prompt, which the operator has to be ready for.

        fwupd already asks for an administrator for everything else. Only
        the three actions it allows an active user by default, which change
        the firmware on the device, are taken away. Refreshing metadata and
        reading device state stay as they are, so Discover and the refresh
        timer keep working.
      '';
      config = _: {
        security.polkit.extraConfig = ''
          // Firmware changes: an administrator, always. These are the fwupd
          // actions its own policy allows an active user; the rest already
          // ask for an administrator, and refresh and read stay open.
          polkit.addRule(function(action, subject) {
            if (action.id == "org.freedesktop.fwupd.update-internal-trusted"
                || action.id == "org.freedesktop.fwupd.update-hotplug-trusted"
                || action.id == "org.freedesktop.fwupd.modify-device") {
              return polkit.Result.AUTH_ADMIN;
            }
          });
        '';
      };
      verify = ''grep -q "org.freedesktop.fwupd.update-internal-trusted" /etc/polkit-1/rules.d/*.rules 2>/dev/null'';
    };

    "polkit-keeps-removable-media" = {
      title = "A user can still use a USB stick";
      severity = "baseline";
      tags = [ "desktop" ];
      why = ''
        Written down as a decision rather than left as an accident. Mounting
        removable media stays with the person at the keyboard. What may be
        plugged in at all is usbguard's job, at the hardened level
        (usb-block-new-devices); taking the mount away as well would cost the
        user their work without adding anything. Only the removable-media
        action is matched: mounting a system disk, or a disk of another seat
        or user, keeps asking for an administrator.
      '';
      config = _: {
        security.polkit.extraConfig = ''
          // Removable media stays with the active local session. Deliberate:
          // usbguard decides what may be plugged in, this decides who may open
          // it once it is. An exact match: a prefix would also take in
          // filesystem-mount-system, -other-seat and -other-user, which
          // udisks gives to an administrator only.
          polkit.addRule(function(action, subject) {
            if (action.id == "org.freedesktop.udisks2.filesystem-mount"
                && subject.local && subject.active) {
              return polkit.Result.YES;
            }
          });
        '';
      };
      verify = ''grep -q "udisks2.filesystem-mount" /etc/polkit-1/rules.d/*.rules 2>/dev/null'';
    };
  };
}
