# DAWO Core Repository

This repository contains the core NixOS configurations for the DAWO infrastructure. It utilizes a flake-based build system to provide reproducible and modular environment definitions across various hosts and services.

A [DAWO community](https://dawo.community) project.

## Notice
DAWO Core has moved from https://code.overheid.nl to [Codeberg](https://codeberg.org/DAWO/DAWO-Core) to facilitate community collaboration.
    
Backup copies are available on:
- https://code.overheid.nl/MinBZK/DAWO-NixOS
- https://github.com/DAWO-community/DAWO-Core

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Key Concepts
- **Flakes**: The foundation of the repo, used for pinning inputs and defining outputs.
- **Modules**: The primary way configurations are organized, allowing for composable building blocks.
- **Multi-Tenancy**: Specifically designed to handle diverse roles, from `desktops` to core `services`.

## Entry Points
- [`flake.nix`](https://codeberg.org/DAWO/DAWO-Core/src/branch/main/flake.nix) - The primary build entry point and input definitions.
- [`modules/`](https://codeberg.org/DAWO/DAWO-Core/src/branch/main/modules) - The directory containing all modular configurations.

## High-Level Architecture
See [architecture.md](architecture.md).

## Module Map
| Module                                              | Purpose                                                      |
| --------------------------------------------------- | ------------------------------------------------------------ |
| [`boot`](modules/boot/boot.md)                      | Bootloader and initial kernel parameters.                    |
| [`desktops`](modules/desktops/desktops.md)          | GUI environments and workspace setups.                       |
| [`environment`](modules/environment/environment.md) | Global environment variables, apps and shell configurations. |
| [`hardware`](modules/hardware/hardware.md)          | Platform-specific machine hardware definitions.              |
| [`hosts`](modules/hosts/hosts.md)                   | The ultimate definition of specific server/client instances. |
| [`networking`](modules/networking/networking.md)    | Network interfaces, WiFi, and VPN configurations.            |
| [`nixos`](modules/nixos/nixos.md)                   | Core NixOS system-level overrides.                           |
| [`programs`](modules/programs/programs.md)          | General software package management and configuration.       |
| [`services`](modules/services/services.md)          | Daemon processes and background services.                    |
| [`users`](modules/users/users.md)                   | User accounts, groups, and sudoer permissions.               |

