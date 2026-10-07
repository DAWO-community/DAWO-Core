# Running in a QEMU VM

If you already have Nix installed, it is very easy to spin up a DAWO instance
in a QEMU VM to get a taste of what the system looks like.

Build the VM with:

    nixos-rebuild build-vm --flake .#dawo-qemu

And then start it with:

    ./result/bin/run-dawo-qemu-vm

You can log in with password 'dawo'.

## Limitations

This will put you 'straight into' a DAWO installation,
so you will not experience the fleet manager, 'inspoel'
process, disko disk auto-partitioning or TPM/SecureBoot
support.
