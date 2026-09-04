# Maid

The Plasma workspace as a user first meets it: branding, the panel layout, and
the settings a fresh account starts with, applied through
[nix-maid](https://codeberg.org/viperML/nix-maid).

## Key Files
- `dawo-generic.nix` - the whole workspace. Named "generic" for historical
  reasons; it is Plasma-specific throughout and is gated on
  `dawo.desktop.plasma.enable`.

## Responsibilities
- Branding: the account picture, and the wallpaper on the desktop and the lock
  screen.
- The panel: one definition, rendered once per screen.
- Defaults a fresh account starts with: fonts, cursor theme, effects.
- A oneshot that removes stale KDE files from home directories on activation,
  so a setting this module drops does not survive in a user's own file.

## Why the panel is generated
Plasma numbers containments per screen: the desktop is `screen+1`, the panel is
`(screen+1)*100`, an applet is that panel number plus its position, and a nested
applet adds two more digits. Everything follows from the screen index, so five
screens is one definition and a list, not five copies. It used to be five copies
of about 180 lines each, which is five chances to change one and forget the
other four.

The test when this changes: the rendered
`plasma-org.kde.plasma.desktop-appletsrc` before and after has to be identical,
compared as data rather than read by eye.

## What this does not do
It does not decide which desktop runs; that is `desktop-select`. It does not
set the screen lock, which is a hardening rule, so that it applies to GNOME too.
