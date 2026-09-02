# DAWO Core

DAWO Core is the NixOS workplace image that Dutch public bodies build their
laptops from. It is a library of blocks, not a finished product: an organisation
composes the blocks it wants in a thin overlay of its own, and everything that
is specific to one organisation stays there rather than here.

This handbook is the operator and architecture documentation for that core. It
is written for three readers, and each of them can stop after their own part:

- somebody installing or updating a device, who wants the commands and the order
  they go in
- somebody deciding whether to adopt DAWO, who wants to know how it is put
  together and what it refuses to do
- somebody extending the core with a new block, who needs the conventions before
  writing the first line

## What it is

A device built from this repository boots a hardened, encrypted, reproducible
NixOS: LUKS on disk, systemd-boot, a managed set of applications, and an update
loop that pulls a new revision from git and switches to it without anybody
touching the laptop. Secure Boot, TPM2 unlock and the compliance profiles are
available and off by default, because a wrong default here locks a user out of
their own machine.

## What it is not

It is not an image with one organisation's applications in it, not a fleet
manager, and not a place for anything that cannot be published. Vendor software,
VPN endpoints, identity servers and secrets live in an overlay. The control
plane that ships updates and reports on the fleet is a separate project
(Sextant), and a device does not need it to work.

## How to read this

Start at [Install a device](./operators/deploy.md) if a laptop is waiting.
Start at [Blocks, tiers and consumers](./concepts/architecture.md) if the
question is how the thing is put together. The
[Module map](./reference/modules.md) is the index of what exists.

Every page in this book is generated from the documentation in the repository
itself, so a page and the code it describes move together. Where a page is thin,
that is a real gap and not a rendering problem; the honest place to report it is
the issue tracker.
