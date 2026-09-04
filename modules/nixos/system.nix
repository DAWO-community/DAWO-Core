{
  flake.modules.nixos.nixos-system = _: {
    # No generic auto-upgrade: DAWO updates come from comin (dawo.autoUpdate,
    # the git-driven pull-deploy). Running system.autoUpgrade alongside it is a
    # second mechanism rebuilding the machine (and it fails nightly with no
    # channel/flake configured). comin is the single update source.
    system.autoUpgrade.enable = false;
    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It's perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "26.05"; # Did you read the comment?
  };
}
