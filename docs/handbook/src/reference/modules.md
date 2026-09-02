# Module map

Every capability in the core is a block under `modules/<category>/`, exposed as
`flake.modules.nixos.<category>-<name>` and configured under `dawo.<block>`. The
category pages below are the ones kept in the module directories themselves, so
this map cannot drift from the tree it describes.

Hardware has its own page: see [Hardware support](./hardware.md).


## boot

{{#include ../../../../modules/boot/boot.md}}

## desktops

{{#include ../../../../modules/desktops/desktops.md}}

## environment

{{#include ../../../../modules/environment/environment.md}}

## flake-parts

{{#include ../../../../modules/flake-parts/flake-parts.md}}

## hosts

{{#include ../../../../modules/hosts/hosts.md}}

## localization

{{#include ../../../../modules/localization/localization.md}}

## maid

{{#include ../../../../modules/maid/maid.md}}

## networking

{{#include ../../../../modules/networking/networking.md}}

## nixos

{{#include ../../../../modules/nixos/nixos.md}}

## programs

{{#include ../../../../modules/programs/programs.md}}

## services

{{#include ../../../../modules/services/services.md}}

## users

{{#include ../../../../modules/users/users.md}}
