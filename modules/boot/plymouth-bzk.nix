{
  flake.modules.nixos.boot-plymouth-bzk = _: {
    # Plymouth config
    boot.plymouth.enable = true;
    boot.plymouth.theme = "bgrt";
    boot.plymouth.logo = ../../artwork/icons/logo-rijksoverheid.png;

    boot.initrd.verbose = false;

    # Enable "Silent Boot"
    boot.consoleLogLevel = 0;
    boot.kernelParams = [
      "plymouth.use-simpledrm"
      "quiet"
      "splash"
    ];
  };
}
