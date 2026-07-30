{
  flake.modules.nixos.environment-fonts =
    { pkgs, ... }:
    {
      # FONTS
      fonts.packages = with pkgs; [
        corefonts
        inter
        noto-fonts
        noto-fonts-color-emoji # color emoji (fontconfig emoji fallback) - else tofu in chat/web
        fira-code
        noto-fonts-cjk-sans
        font-awesome
        terminus_font
        victor-mono
      ];
    };
}
