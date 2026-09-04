# Pitfalls

Things that cost somebody hours, written down so they cost the next person
minutes. Each one is here because it actually happened, not because it might.

The pattern is the same in most of them: something reports success while being
wrong, and the wrongness is invisible until a machine somewhere behaves
differently from the machine you tested on.

## CI can be green over a core that does not evaluate

A fixed-output derivation is content addressed. Once a path exists in the
runner's store, Nix trusts it and never fetches it again, whatever happened to
the URL it came from.

So when `nix-maid` resolved a package through a tarball that later returned 404,
`main` stopped evaluating on every fresh machine while CI stayed green on the
runner that still had the tarball. Same commit, different answer, decided by the
runner's store rather than by the code.

**How to recognise it.** A failure that comes and goes across runs of code that
did not change. Compare durations: a job dying in three seconds is hitting a
missing path, one dying at thirty is getting further in.

**What to do.** Anything an evaluation reaches for is a flake input, pinned in
`flake.lock`. Where an upstream resolves something through its own mechanism,
take that dependency into our lock and pass it in. See ADR-0007.

## A dirty working tree changes every relative path

`builtins.getFlake` on a dirty git tree copies the working tree to the store, so
every relative path inside the flake resolves to a new store path. A wallpaper
that nobody touched gets a new hash because an unrelated file changed.

**How to recognise it.** A comparison that says everything changed when you
changed one thing.

**What to do.** When comparing built configurations before and after a refactor,
normalise store paths out of the comparison, or commit both sides first. And
compare the rendered data, not the hash of the toplevel: `dawo-version.nix`
stamps the flake revision into the system, so that hash moves on every commit by
design.

## comin does not advance the system profile

comin sets its own profile under `/nix/var/nix/profiles/system-profiles/comin`,
a directory that is mode 0000. `/nix/var/nix/profiles/system` keeps pointing at
the last manual `nixos-rebuild`.

So on a device that comin manages, `nixos-rebuild list-generations` names a stale
generation "Current", and `nixos-rebuild switch --rollback` rolls back to the
wrong thing.

**What to do.** Read `/run/current-system`, which is world readable and is the
truth about this boot. Roll back through the boot menu.

## The pull and the rebuild authenticate separately

A netrc gives *nix* a credential, which is what nix needs to fetch a private
flake input during a rebuild. comin does not fetch through nix: it clones the
repository itself, with its own git client and its own credential.

A deployment with a private overlay therefore authenticates for the rebuild and
not for the pull that triggers it. comin logs the failed poll at error level and
goes back to sleep, so the only symptom is a device that quietly stops moving.
A fleet sat six weeks on an old generation this way.

**Second trap behind the first.** comin hands `auth.username` to go-git as the
SSH user, where it *replaces* the user named in the URL. Its default is `comin`,
an account on no forge, so a correct deploy key still fails with

    ssh: handshake failed: ... no supported methods remain

and the error points at the key.

## Never deploy the core's own host configuration onto an overlay device

`deploy .#dawo-t495s` works, and on a device that belongs to an organisation
overlay it takes away everything the overlay added: the mesh network, the
operator's SSH keys, the open port 22, the users, the agenix secrets, comin
itself and the printers. The device is then reachable only from its own keyboard.

**What to do.** Test a core branch through the overlay, with the core input
overridden:

    nixos-rebuild test --flake "<overlay>#<host>" \
      --override-input dawo "git+https://codeberg.org/DAWO/DAWO-Core.git?ref=<branch>"

That also tests the combination that actually ships, rather than the core alone.

## An option rename can break the evaluation it is meant to protect

`lib.mkRenamedOptionModule` fails the whole evaluation when its *new* option does
not exist in that configuration. Putting all the renames in one module therefore
breaks every host that does not import every renamed block, which is most of
them, because half the blocks are opt-in.

**What to do.** Put a rename in the module that declares its target.

## Formatting caches lie about how much is unformatted

treefmt caches per file, so a first local `nix fmt` can report fewer changes than
the sandboxed `nix flake check` finds, and the check then fails on a tree you
just formatted.

**What to do.** `nix fmt -- --no-cache` before pushing.

## Plasma numbers its panels arithmetically

The desktop containment is `screen + 1`, the panel is `(screen + 1) * 100`, an
applet is that panel number plus its position, and a nested applet takes the
applet id and adds two more digits.

Worth knowing because it means a per-screen layout is one definition and a list,
not one copy per screen. It used to be five copies of about 180 lines, which is
five chances to change one and forget the rest.

**What to do when changing it.** Compare the rendered
`plasma-org.kde.plasma.desktop-appletsrc` before and after as parsed data. Two
mistakes were caught that way in one afternoon: applet ids concatenated instead
of added, and an `installPhase` mangled to `stallPhase`, which an evaluation
accepts and a build does not.
