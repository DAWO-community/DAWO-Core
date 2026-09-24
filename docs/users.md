# Users: declarative management (gitops)

Users are code. No manual `useradd`/`passwd` on the device - everything in
git. This is the "2-layer inventory" in dendritic form:

- **users/** (`modules/users/<name>.nix`) = the user inventory: one file per
  user, like the existing `users-dawo`.
- **hosts/** (`modules/hosts/clients/<host>.nix`) = the machines: a host
  imports the users that belong on it. The import list is the machine->user mapping.

## Adding a user

1. Create `modules/users/alice.nix`:

   ```nix
   {
     flake.modules.nixos.users-alice =
       { config, pkgs, ... }:
       {
         users.users.alice = {
           description = "Alice Jansen";
           isNormalUser = true;
           home = "/home/alice";
           shell = pkgs.zsh;
           extraGroups = [ "networkmanager" ]; # "wheel" = admin/sudo
           hashedPasswordFile = config.age.secrets."alice-password".path;
           openssh.authorizedKeys.keys = [
             "ssh-ed25519 AAAA... alice@laptop"
           ];
         };
         age.secrets."alice-password".file = ../../secrets/alice-password.age;
       };
   }
   ```

2. Add `users-alice` to the import list of the host(s) Alice is allowed on.

## Passwords: agenix (never plaintext in git)

The agenix module is already active. A password hash does **not** belong in a
`.nix` file (it ends up world-readable in the store). Instead:

```bash
mkpasswd -m yescrypt > /tmp/h        # generate hash
agenix -e secrets/alice-password.age # paste the hash, store it encrypted
```

Reference it with `hashedPasswordFile = config.age.secrets."alice-password".path`.
The host key (`age.identityPaths`, the SSH host key by default) decrypts it at
activation.

> The generic `users-dawo` is a bootstrap account so a fresh image is
> loginable. Give it your own hash with
> `dawo.bootstrapUser.initialHashedPassword`; without one it falls back to a
> password written down in this repository and warns at every build. It uses
> `initialHashedPassword` and `mutableUsers = true`, so the value applies at
> account creation only. For real deployments give the host its own gitops user
> (`hashedPasswordFile` via agenix) and set `dawo.bootstrapUser.enable = false`.

## Fully declarative (gov-proof)

Enable `users-hardened` (opt-in) -> `mutableUsers = false`: nothing outside git.
**Requirement**: every login user then needs a `hashedPasswordFile`/`hashedPassword`
(no `initialHashedPassword`). Migrate first, test on a canary, keep a
recovery path. Lockout risk.

## Login policy

`dawo.pam` sets what happens when somebody guesses, and what a password has to
look like. Both are on by default and forced on by the core profile.

    dawo.pam.lockout.attempts = 5;        # failed tries before the account locks
    dawo.pam.lockout.unlockSeconds = 600; # the lock expires on its own
    dawo.pam.quality.minLength = 12;

Two things are deliberate. root is never locked out, because the account that
fixes a locked device should not be the one that is locked. And a lockout
expires by itself, because a lock only an administrator can lift turns a typo on
a train into a day without a laptop. To see or clear one by hand:

    faillock --user <name>
    sudo faillock --user <name> --reset

The lockout applies to the console, `su`, `sudo` and whichever display manager
is enabled. A place where a password can be typed and that is not in
`dawo.pam.lockout.services` is a way around it.

## Hardware keys

`dawo.pam.u2f.enable` puts a hardware key (FIDO2) in front of login and sudo. It
is off, and it should stay off until every user of that device has an enrolled
key and the recovery path below is agreed, or it is a lockout with extra steps.

    dawo.pam.u2f.enable = true;
    dawo.pam.u2f.mode = "second-factor";   # key and password (default)
    # dawo.pam.u2f.mode = "passwordless";  # key instead of password

`second-factor` is the one that adds security: a stolen key alone opens nothing,
and neither does a password somebody watched being typed. `passwordless` is
convenience; whoever holds the key is in.

In both modes a user without an enrolled key cannot log in or use sudo. Enrol
before switching it on, two keys per user, and keep the spare somewhere else:

    pamu2fcfg > ~/.config/Yubico/u2f_keys        # first key
    pamu2fcfg -n >> ~/.config/Yubico/u2f_keys    # spare, appended

The key has to be in the device. An administrator on SSH can still log in with
their SSH key, but gets no sudo in `second-factor` mode, because there is no key
to touch at the other end.

### When a key is lost

1. The user logs in with the spare, and removes the lost key's line from
   `~/.config/Yubico/u2f_keys`.
2. No spare: turn it off for that one device in the deployment repository,
   `dawo.pam.u2f.enable = false`, and let the update loop apply it. The user
   logs in with the password, enrols new keys, and the setting goes back.
3. The device no longer updates: boot the installer, unlock the disk with the
   LUKS passphrase, and edit the user's `u2f_keys` from there.

Step 2 is the reason this works without a visit, and the reason step 3 should
be rare. Check that the update loop runs (`dawo-update-status`) before turning
keys on.

## Admins

An admin = a user with `extraGroups = [ "wheel" ]`. Combine with
`dawo.pam.u2f` (see Hardware keys) for strong sudo auth. SSH-only superadmin = a user with
only `openssh.authorizedKeys.keys` + `hashedPassword = "!"` (no
password login).
