{
  # Zsh, opt-in (default off; bash is the default shell). A host or user that
  # wants zsh flips dawo.zsh.enable. Quality-of-life only - no hardcoded per-user
  # paths.
  flake.modules.nixos.programs-zsh =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.dawo.zsh;
    in
    {
      options.dawo.zsh.enable = lib.mkEnableOption "Zsh as an interactive shell (opt-in)";

      config = lib.mkIf cfg.enable {
        # fzf for the prompt's history widget (not in the base since the base is
        # lean and zsh is opt-in).
        environment.systemPackages = [ pkgs.fzf ];

        programs.zsh = {
          enable = true;
          enableCompletion = true;
          ohMyZsh = {
            enable = true;
            plugins = [ "git" ];
            theme = "agnoster";
          };

          autosuggestions.enable = true;
          syntaxHighlighting.enable = true;

          shellAliases = {
            ll = "ls -l";
            edit = "sudo -e";
          };

          histSize = 10000;
          histFile = "$HOME/.zsh_history";

          promptInit = ''
            source <(fzf --zsh);
            HISTFILE=~/.zsh_history;
            HISTSIZE=10000;
            SAVEHIST=10000;
            setopt appendhistory;
          '';
        };
        system.userActivationScripts.zshrc = "touch .zshrc";
      };
    };
}
