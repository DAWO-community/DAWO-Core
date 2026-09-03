{
  # The screen lock. First rule in the register that brings configuration with
  # it, and the most everyday control there is: a workplace laptop left open in
  # a cafe, a train, or a meeting room somebody else walks into.
  #
  # It sets both desktops at once, on purpose. The Plasma file means nothing on
  # a GNOME device and the dconf lock means nothing on a Plasma one, so neither
  # needs to know which desktop it is on, and neither can be forgotten when a
  # host switches.
  flake.dawo.rules."desktop-idle-lock" = {
    title = "The screen locks itself after five minutes";
    severity = "baseline";
    tags = [ "desktop" ];
    compliance = [ "bio" ];
    why = ''
      Everything else on this list assumes the attacker is not already sitting
      at the keyboard. This is the one that assumes they might be, and it costs
      a user five minutes of typing their password now and then.
    '';
    config =
      { lib, ... }:
      let
        gv = lib.gvariant;
        seconds = 300;
      in
      {
        # GNOME. Locked, so the setting is not a suggestion a user can undo in
        # the settings panel.
        programs.dconf.enable = true;
        programs.dconf.profiles.user.databases = [
          {
            settings = {
              "org/gnome/desktop/session".idle-delay = gv.mkUint32 seconds;
              "org/gnome/desktop/screensaver" = {
                lock-enabled = true;
                lock-delay = gv.mkUint32 0;
              };
            };
            locks = [
              "/org/gnome/desktop/session/idle-delay"
              "/org/gnome/desktop/screensaver/lock-enabled"
            ];
          }
        ];

        # Plasma. kscreenlocker reads minutes, and the [$i] marker is how KDE
        # says immutable: the entry is greyed out in system settings rather than
        # silently overwritten by the user's own file.
        environment.etc."xdg/kscreenlockerrc".text = ''
          [Daemon][$i]
          Autolock=true
          LockGrace=0
          Timeout=${toString (seconds / 60)}
        '';
      };
    verify = ''
      grep -qx "Timeout=5" /etc/xdg/kscreenlockerrc 2>/dev/null \
        || grep -rqs "idle-delay" /etc/dconf/db/*.d/locks 2>/dev/null
    '';
  };
}
