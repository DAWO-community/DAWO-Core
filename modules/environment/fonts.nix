{
  flake.modules.nixos.environment-fonts =
    { pkgs, ... }:
    {
      # FONTS
      fonts.packages = with pkgs; [
        corefonts
        inter
        noto-fonts
        fira-code
        noto-fonts-cjk-sans
        font-awesome
        terminus_font
        victor-mono
      ];
    };
}
