# Architecture

DAWO NixOS follows a modular, flake-based approach to infrastructure management. The codebase is designed to be dry (Don't Repeat Yourself) by leveraging the `modules` directory.

## Components
- **Flakes**: Definition of inputs (other repositories/overlays) and outputs (the final sets).
- **Modules**: Composable units of configuration in `/modules`.
- **Hosts**: Terminal definitions of how specific machines combine modules into a bootable system.
- **Disko**: Integrated storage management for persistent data layers.

## Data Flow
1. **Input Resolution**: `flake.nix` pulls in remote inputs and local files.
2. **Configuration Assembly**: Host definitions select specific modules from `/modules`.
3. **Build Pipeline**: The Nix build system resolves all dependencies and generates the final filesystem tree.
4. **Deployment**: Resulting configurations are applied to hardware (via `disko` or direct boot).

## Key Design Decisions
- **Modularity Over Monoliths**: Every logical component is a separate module in `/modules`. 
- **Flake Pinning**: Ensuring all dependencies are locked via flake pins for reproducible builds.
- **Disko Integration**: Decoupling storage management from the NixOS system config to allow better lifecycle control of disks.
