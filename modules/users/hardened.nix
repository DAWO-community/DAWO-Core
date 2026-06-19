{
  # OPTIONAL (opt-in). Fully declarative users - no runtime drift
  # (gitops/gov-proof: a user created/changed outside git disappears
  # on the next rebuild).
  # Standard: BIO access control. Origin: securix/bureautix inventory (users-as-code).
  # See docs/standards.md.
  #
  # NOTE (lockout risk): with mutableUsers=false every login user MUST have a
  # `hashedPassword`/`hashedPasswordFile`. `initialHashedPassword` no longer
  # works then. Migrate your users to `hashedPasswordFile` (agenix) first -
  # see docs/users.md - before enabling this. Canary + recovery path first.
  flake.modules.nixos.users-hardened =
    { lib, ... }:
    {
      users.mutableUsers = lib.mkForce false;
    };
}
