{
  # USB device control, at the hardened level rather than the baseline.
  #
  # Deliberate: a device that refuses a stick or a dongle out of the box reads
  # as broken to the person holding it, and the core has to be installable
  # without somebody there to explain. A deployment that wants it says so.
  flake.dawo.rules."usb-block-new-devices" = {
    title = "Newly plugged USB devices are blocked until allowed";
    severity = "hardened";
    tags = [ "usb" ];
    compliance = [ "bio" ];
    why = ''
      A USB port is the one opening in a laptop that a passer-by can reach
      without a password. USBGuard blocks what is plugged in after boot and
      leaves what was already there alone, so a keyboard keeps working and a
      stick from a conference does not.

      Off in the baseline because it costs the user something real: the stick
      they meant to use is refused too, until an operator allows it.
    '';
    config =
      { lib, ... }:
      {
        dawo.usbControl.enable = lib.mkDefault true;
      };
    verify = "systemctl is-active --quiet usbguard";
  };
}
