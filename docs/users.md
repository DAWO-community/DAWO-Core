# Users: declarative management (gitops)

Users are code. No manual `useradd`/`passwd` on the device — everything in
git. This is the "2-layer inventory" in dendritic form:

- **users/** (`modules/users/<name>.nix`) = the user inventory: one file per
  user, like the existing `users-dawo`.
- **hosts/** (`modules/hosts/clients/<host>.nix`) = the machines: a host
  imports the users that belong on it. The import list is the machine→user mapping.

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

> The generic `users-dawo` is a demo/bootstrap account with a documented
> default password (`dawo` / `dawo`) so a fresh image is loginable. It uses
> `initialHashedPassword` and `mutableUsers = true`, so change it after first
> login. For real deployments give the host its own gitops user
> (`hashedPasswordFile` via agenix) and drop `users-dawo`.

## Fully declarative (gov-proof)

Enable `users-hardened` (opt-in) → `mutableUsers = false`: nothing outside git.
**Requirement**: every login user then needs a `hashedPasswordFile`/`hashedPassword`
(no `initialHashedPassword`). Migrate first, test on a canary, keep a
recovery path. Lockout risk.

## Admins

An admin = a user with `extraGroups = [ "wheel" ]`. Combine with
`nixos-pam-u2f` (FIDO2) for strong sudo auth. SSH-only superadmin = a user with
only `openssh.authorizedKeys.keys` + `hashedPassword = "!"` (no
password login).
