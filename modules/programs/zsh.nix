{
  flake.modules.nixos.programs-zsh =
    { config, ... }:
    {
      programs = {
        # Zsh configuration
        zsh = {
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
            update = "cd ~/Git/nixos; ulimit -n 65535; sudo nixos-rebuild switch --flake .#${config.networking.hostName}";
          };

          histSize = 10000;
          histFile = "$HOME/.zsh_history";

          promptInit = ''
            # Set-up icons for files/directories in terminal using lsd
            alias ls='lsd'
            alias l='ls -l'
            alias la='ls -a'
            alias lla='ls -la'
            alias lt='ls --tree'

            source <(fzf --zsh);
            HISTFILE=~/.zsh_history;
            HISTSIZE=10000;
            SAVEHIST=10000;
            setopt appendhistory;
          '';
        };
      };
      system.userActivationScripts.zshrc = "touch .zshrc";
    };
}
