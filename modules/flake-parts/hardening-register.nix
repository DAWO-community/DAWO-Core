{ lib, ... }:
{
  # The hardening register: every rule the image can apply, as data.
  #
  # A rule is one decision, not a block of them. It carries the configuration
  # that applies it, a check that proves it on the device, and the metadata that
  # says what it is and where it comes from. Files under modules/hardening/rules
  # add to this set and import-tree picks them up; nothing has to be listed
  # twice.
  #
  # See modules/hardening/hardening.md for the shape of a rule, and ADR-0010 for
  # why the unit is a rule rather than a block.
  options.flake.dawo.rules = lib.mkOption {
    type = with lib.types; lazyAttrsOf anything;
    default = { };
    description = "Hardening rules, keyed by id (kebab-case, prefixed by subject).";
  };
}
