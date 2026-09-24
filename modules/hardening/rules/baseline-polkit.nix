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
        notification somebody clicks away on a train.
      '';
      config = _: {
        security.polkit.extraConfig = ''
          // Firmware updates: an administrator, always.
          polkit.addRule(function(action, subject) {
            if (action.id.indexOf("org.freedesktop.fwupd.") === 0) {
              return polkit.Result.AUTH_ADMIN;
            }
          });
        '';
      };
      verify = ''grep -q "org.freedesktop.fwupd" /etc/polkit-1/rules.d/*.rules 2>/dev/null'';
    };

    "polkit-keeps-removable-media" = {
      title = "A user can still use a USB stick";
      severity = "baseline";
      tags = [ "desktop" ];
      why = ''
        Written down as a decision rather than left as an accident. Mounting
        removable media stays with the person at the keyboard: the control for
        what may be plugged in is usbguard, and taking the mount away as well
        would cost the user their work without adding anything.
      '';
      config = _: {
        security.polkit.extraConfig = ''
          // Removable media stays with the active local session. Deliberate:
          // usbguard decides what may be plugged in, this decides who may open
          // it once it is.
          polkit.addRule(function(action, subject) {
            if (action.id.indexOf("org.freedesktop.udisks2.filesystem-mount") === 0
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
