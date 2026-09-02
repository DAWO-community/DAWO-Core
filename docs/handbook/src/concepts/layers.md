# The three layers

A DAWO device is built from three repositories stacked on top of each other.
The stack exists so that one organisation's choices never become everybody's
maintenance burden.

    DAWO Core            this repository - blocks, hardening, hardware, the update loop
      -> group overlay   what a sector shares (for example a VNG-level set)
        -> org overlay   one organisation: its applications, VPN, identity, secrets

## What belongs in which layer

**Core.** Anything every deployment needs and nothing that identifies a single
one: the boot chain, disk encryption, the desktop baseline, printing and
scanning, hardware profiles, the auto-update mechanism, the compliance tiers.
Blocks here are off unless they can be defaulted on without risking a user being
locked out of their own laptop.

**Group overlay.** Choices a sector agrees on but the core should not assume: a
shared application set, a shared trust store, a shared policy tier.

**Org overlay.** Everything that is true of exactly one organisation. Vendor
software and its licences, VDI endpoints, the identity provider, the printers,
the secrets, and the host definitions naming actual machines. The Zaanstad
overlay is the worked example: it adds Omnissa Horizon, the VPN path, and a
deploy key for its own private repository.

## Why the seam sits there

Three practical consequences, and they are the reason the split is worth the
extra repository:

- the core stays publishable. Nothing in it needs a licence agreement, a
  credential or a customer name, so it can live in the open and be reviewed by
  anyone
- an organisation can move at its own speed. An overlay pins the core revision
  it trusts; a core release does not reach a device until that overlay says so
- a bug has one home. A block that misbehaves everywhere is a core issue; a
  laptop that cannot reach a print server is an overlay issue. Nobody has to
  argue about which repository to open the ticket in

## How a device names its layers

The device follows its overlay, not the core: `dawo.autoUpdate.options.repoUrl`
points at the overlay repository, and the overlay pins the core as a flake
input. So an update to the core reaches a device in two steps that somebody
chooses, rather than one that happens on its own. See
[How a device updates itself](./auto-update.md).
