{
  # Tailscale mesh, opt-in (dawo.tailscale). Joins the device to a tailnet
  # run by the organisation, typically a self-hosted Headscale, so it can be
  # reached and administered across networks nobody here runs.
  #
  # Two choices are made here rather than left to nixpkgs' defaults:
  #   - The coordination server is required. The client's default is
  #     Tailscale Inc's service; using it is allowed, but it has to be named.
  #   - Upstream logging is off. The client otherwise sends its logs to
  #     Tailscale Inc, whichever coordination server it uses.
  #
  # The mesh interface is not trusted by the firewall, and no port is opened:
  # what a peer may reach is decided per service, as on any other network.
  flake.modules.nixos.services-tailscale =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.dawo.tailscale;
    in
    {
      options.dawo.tailscale = {
        enable = lib.mkEnableOption "the Tailscale client, joined to the organisation's tailnet";
        options.loginServer = lib.mkOption {
          type = lib.types.str;
          default = "";
          example = "https://headscale.example.org";
          description = ''
            The coordination server, usually a self-hosted Headscale. Required:
            to use Tailscale Inc's service, name it
            (https://controlplane.tailscale.com).
          '';
        };
        options.authKeyFile = lib.mkOption {
          type = lib.types.nullOr lib.types.externalPath;
          default = null;
          example = "/run/agenix/tailscale-authkey";
          description = ''
            File holding a pre-authorised auth key, read at runtime and never
            copied into the Nix store. Set, the device joins on its own at
            boot; null, an administrator joins it once with
            `sudo tailscale up --login-server <loginServer>`.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = lib.hasPrefix "https://" cfg.options.loginServer;
            message = "dawo.tailscale: set dawo.tailscale.options.loginServer to the coordination server, starting with https:// (https://controlplane.tailscale.com for Tailscale's own).";
          }
        ];

        services.tailscale = {
          enable = true;
          disableUpstreamLogging = true;
          inherit (cfg.options) authKeyFile;
          extraUpFlags = [ "--login-server=${cfg.options.loginServer}" ];
        };
      };
    };
}
