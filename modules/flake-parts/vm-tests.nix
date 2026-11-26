{ config, ... }:
let
  inherit (config.flake.modules) nixos;
in
{
  # Tests that boot a VM, for the promises an evaluation cannot keep. The
  # baseline in checks.nix reads the configuration; these run it. They need
  # KVM on the machine that runs `nix flake check`.
  #
  # Keep them few and aimed. Each one is here because reading the
  # configuration said it was fine and running it said otherwise.
  perSystem =
    { pkgs, ... }:
    {
      # The account lockout, through the real PAM stacks. Reading them showed
      # the rules in the right places; only running them showed that
      # pam_faillock ignored the policy in /etc and locked after three
      # attempts. It covers a local user and a directory user over SSSD, the
      # composition that broke the lockout before (#178).
      checks.pam-lockout-vm = pkgs.testers.runNixOSTest {
        name = "pam-lockout";
        nodes.machine =
          { lib, pkgs, ... }:
          let
            suffix = "dc=example,dc=org";
            certs = "${pkgs.path}/nixos/tests/common/acme/server";
          in
          {
            imports = [ nixos.hardening-pam ];
            virtualisation.memorySize = 2048;
            environment.systemPackages = [
              pkgs.pamtester
              pkgs.expect
            ];

            users.users.bob = {
              isNormalUser = true;
              password = "good-local-pass";
            };

            # The real sddm stack, which reaches login through a substack and
            # must not be listed itself.
            services.displayManager.sddm.enable = true;
            services.xserver.enable = true;
            # A stand-in for the Plasma locker stack: the core lists kde on
            # Plasma, and a full desktop would only make this slower.
            security.pam.services.kde = { };
            security.polkit.enable = true;
            dawo.pam.lockout.services = lib.mkForce [
              "login"
              "su"
              "sudo"
              "kde"
              "polkit-1"
            ];

            # su is driven as an unprivileged caller through the setuid
            # binary: as root, pam_rootok lets su through without a password.
            users.users.carol.isNormalUser = true;
            environment.etc."su-try.exp".text = ''
              set user [lindex $argv 0]
              set pw [lindex $argv 1]
              spawn su $user -c true
              expect "Password:"
              send "$pw\r"
              expect eof
              exit [lindex [wait] 3]
            '';

            # A directory user over SSSD, after nixpkgs' sssd-ldap test.
            environment.etc."cert.pem".source = "${certs}/acme.test.cert.pem";
            environment.etc."key.pem".source = "${certs}/acme.test.key.pem";
            services.openldap = {
              enable = true;
              urlList = [
                "ldap:///"
                "ldaps:///"
              ];
              settings = {
                attrs = {
                  olcTLSCACertificateFile = "/etc/cert.pem";
                  olcTLSCertificateFile = "/etc/cert.pem";
                  olcTLSCertificateKeyFile = "/etc/key.pem";
                  olcTLSVerifyClient = "never";
                };
                children = {
                  "cn=schema".includes = [
                    "${pkgs.openldap}/etc/schema/core.ldif"
                    "${pkgs.openldap}/etc/schema/cosine.ldif"
                    "${pkgs.openldap}/etc/schema/inetorgperson.ldif"
                    "${pkgs.openldap}/etc/schema/nis.ldif"
                  ];
                  "olcDatabase={1}mdb".attrs = {
                    objectClass = [
                      "olcDatabaseConfig"
                      "olcMdbConfig"
                    ];
                    olcDatabase = "{1}mdb";
                    olcDbDirectory = "/var/lib/openldap/db";
                    olcSuffix = suffix;
                    olcRootDN = "cn=admin,${suffix}";
                    olcRootPW = "rootpw";
                    olcAccess = [
                      "{0}to attrs=userPassword by self write by anonymous auth by * none"
                      "{1}to * by * read"
                    ];
                  };
                };
              };
              declarativeContents.${suffix} = ''
                dn: ${suffix}
                objectClass: top
                objectClass: dcObject
                objectClass: organization
                o: example.org

                dn: ou=accounts,${suffix}
                objectClass: top
                objectClass: organizationalUnit

                dn: uid=alice,ou=accounts,${suffix}
                objectClass: person
                objectClass: posixAccount
                userPassword: good-ldap-pass
                homeDirectory: /home/alice
                loginShell: /run/current-system/sw/bin/bash
                uidNumber: 1234
                gidNumber: 1234
                cn: alice
                sn: alice
              '';
            };
            services.sssd = {
              enable = true;
              # A test-only bind password; never put a real one in the store.
              environmentFile = "${pkgs.writeText "ldap-root" "LDAP_BIND_PW=rootpw"}";
              settings = {
                sssd = {
                  config_file_version = 2;
                  services = "nss, pam";
                  domains = "example.org";
                };
                "domain/example.org" = {
                  auth_provider = "ldap";
                  id_provider = "ldap";
                  ldap_uri = "ldaps://127.0.0.1:636";
                  ldap_tls_reqcert = "allow";
                  ldap_tls_cacert = "/etc/cert.pem";
                  ldap_search_base = suffix;
                  ldap_default_bind_dn = "cn=admin,${suffix}";
                  ldap_default_authtok_type = "password";
                  ldap_default_authtok = "$LDAP_BIND_PW";
                };
              };
            };
          };

        testScript = ''
          def auth(svc, user, pw):
              if svc == "su":
                  cmd = f"runuser -u carol -- expect /etc/su-try.exp {user} {pw}"
              else:
                  cmd = f"echo {pw} | pamtester {svc} {user} authenticate acct_mgmt"
              return machine.execute(cmd)[0] == 0

          def fails(user):
              out = machine.succeed(f"faillock --user {user}")
              return len([l for l in out.splitlines() if l.strip()[:1].isdigit()])

          def reset(user):
              machine.succeed(f"faillock --user {user} --reset")

          machine.wait_for_unit("openldap.service")
          machine.wait_for_unit("sssd.service")
          machine.wait_until_succeeds("getent passwd alice", timeout=60)

          for user, good in [("bob", "good-local-pass"), ("alice", "good-ldap-pass")]:
              with subtest(f"{user}: wrong passwords at login are counted"):
                  reset(user)
                  for _ in range(3):
                      assert not auth("login", user, "wrong")
                  assert fails(user) == 3, fails(user)
              with subtest(f"{user}: a good login clears the count"):
                  assert auth("login", user, good)
                  assert fails(user) == 0, fails(user)
              with subtest(f"{user}: a good sddm login is not counted"):
                  assert auth("sddm", user, good)
                  assert fails(user) == 0, fails(user)
              with subtest(f"{user}: a wrong password at sddm is counted once"):
                  assert not auth("sddm", user, "wrong")
                  assert fails(user) == 1, fails(user)
              for svc in ["kde", "polkit-1", "su"]:
                  with subtest(f"{user}: {svc} locks after five failures, also for the right password"):
                      reset(user)
                      for _ in range(5):
                          assert not auth(svc, user, "wrong")
                      assert fails(user) == 5, fails(user)
                      assert not auth(svc, user, good)
                      assert not auth("login", user, good)
                      reset(user)
                      assert auth(svc, user, good)

          with subtest("root is never locked"):
              machine.succeed("echo 'root:rootpass' | chpasswd")
              for _ in range(6):
                  auth("login", "root", "wrong")
              assert auth("login", "root", "rootpass")
        '';
      };
    };
}
