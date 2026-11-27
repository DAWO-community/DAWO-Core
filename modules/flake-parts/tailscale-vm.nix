{ config, ... }:
{
  # The Tailscale block against a self-hosted Headscale, in VMs. Two peers
  # import only services-tailscale; the auth key arrives at runtime, as a
  # secret manager would deliver it. What evaluation cannot show: that the
  # device joins by itself through --login-server, that the peers reach each
  # other, and that the key stays out of the store. Needs KVM.
  perSystem =
    { pkgs, ... }:
    let
      tls = pkgs.runCommand "headscale-cert" { nativeBuildInputs = [ pkgs.openssl ]; } ''
        openssl req -x509 -newkey rsa:2048 -sha256 -days 365 -nodes \
          -out cert.pem -keyout key.pem \
          -subj '/CN=headscale' -addext "subjectAltName=DNS:headscale"
        mkdir -p $out
        cp key.pem cert.pem $out
      '';
      peer = {
        imports = [ config.flake.modules.nixos.services-tailscale ];
        dawo.tailscale = {
          enable = true;
          options.loginServer = "https://headscale";
          options.authKeyFile = "/run/ts-authkey";
        };
        security.pki.certificateFiles = [ "${tls}/cert.pem" ];
      };
    in
    {
      checks.tailscale-vm = pkgs.testers.runNixOSTest {
        name = "tailscale";
        nodes = {
          peer1 = peer;
          peer2 = peer;
          headscale = {
            services.headscale = {
              enable = true;
              port = 8080;
              settings = {
                server_url = "https://headscale";
                prefixes.v4 = "100.64.0.0/10";
                derp.server = {
                  enabled = true;
                  region_id = 999;
                  stun_listen_addr = "0.0.0.0:3478";
                };
                derp.urls = [ ];
                dns = {
                  base_domain = "tailnet";
                  override_local_dns = false;
                };
              };
            };
            services.nginx = {
              enable = true;
              virtualHosts.headscale = {
                addSSL = true;
                sslCertificate = "${tls}/cert.pem";
                sslCertificateKey = "${tls}/key.pem";
                locations."/" = {
                  proxyPass = "http://127.0.0.1:8080";
                  proxyWebsockets = true;
                };
              };
            };
            networking.firewall.allowedTCPPorts = [
              80
              443
            ];
            networking.firewall.allowedUDPPorts = [ 3478 ];
            environment.systemPackages = [ pkgs.headscale ];
          };
        };
        testScript = ''
          start_all()
          headscale.wait_for_unit("headscale")
          headscale.wait_for_open_port(443)
          headscale.succeed("headscale users create test")
          key = headscale.succeed("headscale preauthkeys -u 1 create --reusable").strip()

          for p in (peer1, peer2):
              with subtest(f"{p.name} joins by itself once the key file appears"):
                  p.wait_for_unit("tailscaled")
                  p.succeed(f"install -m 0400 /dev/stdin /run/ts-authkey <<< '{key}'")
                  p.succeed("systemctl restart tailscaled-autoconnect")
                  p.wait_until_succeeds("tailscale status --json | grep -q '\"BackendState\": \"Running\"'")

              with subtest(f"{p.name} sends no logs upstream and trusts nothing new"):
                  p.succeed("systemctl show tailscaled -p Environment | grep -q TS_NO_LOGS_NO_SUPPORT=true")
                  p.fail("nft list ruleset | grep -q tailscale0")
                  p.fail("nft list ruleset | grep -q 41641")

              with subtest(f"{p.name} keeps the key out of the store"):
                  p.fail("grep -rlF -- \"$(cat /run/ts-authkey)\" /nix/store/*tailscale* 2>/dev/null | grep -q .")

          with subtest("the peers reach each other over the tailnet"):
              peer1.wait_until_succeeds("tailscale ping peer2", timeout=120)
              peer2.wait_until_succeeds("tailscale ping peer1", timeout=120)
              headscale.succeed("headscale nodes list | grep -q peer1")
        '';
      };
    };
}
