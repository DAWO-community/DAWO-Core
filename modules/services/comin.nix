{
  flake.modules.nixos.services-comin =
    {
      inputs,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        inputs.comin.nixosModules.comin
      ];

      services.comin = {
        enable = true;
        desktop.enable = true;
        exporter = {
          listen_address = "127.0.0.1";
          openFirewall = false;
          port = 4243;
        };
        postDeploymentCommand = pkgs.writers.writeBash "export" "systemctl start comin-push.service";
        desktop.title = "NixOS Updater";
        remotes = [
          {
            name = "code-overheid";
            url = "https://code.overheid.nl/MinBZK/DAWO-NixOS.git";
            branches.main.name = "main";
            poller.period = 1800;
          }
        ];
      };
      # systemd.timers."comin-push" = {
      #   wantedBy = [ "timers.target" ];
      #   timerConfig = {
      #     OnCalendar = "*:0/30:00"; # Every 30 minutes
      #     Persistent = true;
      #     Unit = "comin-push.service";
      #   };
      # };

      # systemd.services."comin-push" = {
      #   script = ''
      #     ${lib.getExe pkgs.curl} http://127.0.0.1:4243/metrics | ${lib.getExe pkgs.curl} -X POST --data-binary @- https://prompush.realiz-it.nl/metrics/job/comin-$(hostnamectl hostname)-$(cat /sys/class/dmi/id/chassis_serial)
      #   '';
      #   serviceConfig = {
      #     Type = "oneshot";
      #     User = "root";
      #   };
      # };
    };
}
