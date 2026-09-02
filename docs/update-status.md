# Is this device still being updated?

A device updates itself: comin polls the repository the workplace follows and
rebuilds when a commit lands. The failure that matters is the silent one - the
service stops, or the pull is refused, and the laptop keeps working while it
stops receiving fixes. `dawo-update-status` answers that in one screen, and
needs no sudo.

```
$ dawo-update-status
DAWO automatische updates op zaanstad-wilmar

  Update-dienst      actief sinds 2026-08-28 09:14 (3 dagen geleden)
  Volgt              ssh://git@codeberg.org/DAWO/DAWO-Zaanstad.git (release/0.1.2)
  Laatste controle   2026-08-31 08:02 (12 minuten geleden)
  Laatste update     2026-08-31 16:25 (2 uur geleden)
  Draait nu          /nix/store/...-nixos-system-zaanstad-wilmar-25.11
  Herstart nodig     nee

  Alles in orde.
  Details voor support: dawo-update-status --log
```

The two lines that carry the diagnosis are **Laatste controle** (did the poll
reach the repository) and **Laatste update** (did a rebuild actually land). A
service that is active while "Laatste controle" is days old is the shape the
fleet had all of August: comin was running and its pull was being refused.

- `--log` - the last 50 journal lines of the comin unit. Readable by root and
  by wheel; a plain user gets told to prefix `sudo`.
- `--json` - comin's own state, unfiltered, for a support ticket.

## Where the numbers come from

comin's gRPC socket (`/var/lib/comin/grpc.sock`, world-accessible) supplies the
poll and deployment state. When the socket does not answer - comin dead, or a
comin too old for the subcommand - the script falls back to systemd for the
service and to `/run/current-system` for what this boot is running, so it still
reports on a device where the update loop itself is what broke.

Deliberately NOT read: `/nix/var/nix/profiles/system`. comin does not advance
it. It sets its own profile in `/nix/var/nix/profiles/system-profiles/comin`
(and that directory is mode 0000, so a user cannot read it either), which means
the system profile on a comin device still points at the last *manual*
nixos-rebuild. Two consequences worth knowing:

- `nixos-rebuild list-generations` names a stale generation "Current" there.
  Believe `dawo-update-status` and the comin journal, not that table.
- **Roll back through the boot menu, not `nixos-rebuild switch --rollback`.**
  comin installs boot entries from its own profile, so the boot menu holds the
  real previous deployments; `--rollback` would return the device to whatever
  manual generation the system profile last recorded.

"Herstart nodig" compares the booted kernel, initrd and modules against the
current system: a kernel update is only live after a reboot.

## Desktop notifications (opt-in)

comin can also notify on the desktop while it builds and deploys:

```nix
dawo.autoUpdate.desktopNotifications.enable = true;
```

Off by default. It also fires a notification at every graphical login, which is
noise on a device that updates cleanly. Turn it on where an update is being
watched - a canary, or a device under investigation.
