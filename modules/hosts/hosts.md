# Hosts
The final declaration of specific server and client machines using the system modules.

## Key Files
- `hosts/` contains individual NixOS host configurations in flake format.

## Responsibilities
- Machine naming and identifying hardware.
- Selecting which global modules are applied to a host.
- Setting host-specific IPs or unique secrets (via generators).
