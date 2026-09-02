# How a device updates itself

A DAWO device updates by following a git branch. There is no update server, no
agent that takes instructions, and nothing that reaches into the laptop: the
device polls a repository, and when a new commit is there it builds that
configuration and switches to it.

The mechanism is [comin](https://github.com/nlewo/comin), wrapped as the
`dawo.autoUpdate` block (`modules/services/auto-update.nix`).

## The options

    dawo.autoUpdate = {
      enable = true;                                            # on by default in the generic profile
      options.repoUrl = "https://codeberg.org/DAWO/DAWO-Core.git";
      options.branch = "main";
      options.pollSeconds = 1800;
    };

`repoUrl` is the repository this device follows. A bare device follows the core;
a real deployment points it at its own overlay, which pins the core as an input,
so the overlay decides which core revision reaches the laptop.

## What actually happens on a poll

1. comin fetches the branch with its own git client, as root
2. if the revision changed, it evaluates the configuration for this hostname
3. it builds the closure, and activates it
4. the boot entry is written, so the new generation survives a reboot

A branch can be marked `test` instead of `switch`, in which case the new
configuration is activated but the boot default is left alone. That is the safe
way to try something on one machine: a reboot returns it to where it was.

## Two things that surprise people

**comin does not advance the system profile.** `/nix/var/nix/profiles/system`
keeps pointing at the last manual `nixos-rebuild`, and comin's own profile
directory is not readable. So `nixos-rebuild list-generations` will name a stale
generation "Current" on a device that is in fact perfectly up to date, and
`nixos-rebuild switch --rollback` would roll back to the wrong thing. Roll back
through the boot menu.

**The pull and the rebuild authenticate separately.** A netrc gives *nix* a
credential, which is what nix needs to fetch a private flake input during the
rebuild. comin does not fetch through nix - it clones the repository itself,
with its own git client and its own credential. A deployment whose overlay is
private therefore authenticates for the rebuild and not for the pull that
triggers it, and comin logs the failed poll at error level and goes back to
sleep. The device simply stops moving, and nothing on screen says so. This is
issue #95; the core is gaining an option for it.

## Seeing whether it works

The failure mode above is silent by construction, which is why the state has to
be readable on the device itself rather than only in a fleet console. Whatever
you use, check two different things: that the service is running, and that its
last successful fetch is recent. A device with a healthy service and a fetch
from three weeks ago is a device that has stopped updating.
