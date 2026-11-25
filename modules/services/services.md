# Services
Daemon and system service definitions for the entire infrastructure.

## Key Files
- `services/` contains configurations for web servers, databases, metrics, etc.

## Responsibilities
- Systemd unit management.
- Container orchestrators (Docker / Podman).
- Deployment automation services.
- Monitoring stacks (Prometheus / Grafana).

## Tailscale (`dawo.tailscale`, opt-in)

Joins the device to the organisation's tailnet, usually on a self-hosted
Headscale:

    dawo.tailscale = {
      enable = true;
      options.loginServer = "https://headscale.example.org";
      options.authKeyFile = "/run/agenix/tailscale-authkey"; # optional
    };

- `loginServer` is required. To use Tailscale's own service, name it:
  `https://controlplane.tailscale.com`.
- With `authKeyFile`, the device joins on its own at boot. Use a reusable,
  pre-authorised key, and provide the file through agenix or another runtime
  secret; it is never copied into the Nix store. Without it, an administrator
  joins the device once with `sudo tailscale up --login-server <loginServer>`.
- Upstream logging to Tailscale Inc is off. The client can still reach
  Tailscale Inc's servers in one case: while it cannot resolve the coordination
  server, it asks Tailscale's DERP servers for bootstrap DNS. Make sure the
  coordination server resolves on every network the device uses.
- The firewall does not trust the mesh interface and opens no port for it.
  Direct connections are set up by NAT traversal; when that fails, traffic goes
  through the coordination server's relays.
