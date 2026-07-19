{ config, pkgs, ... }:

{
  home.username = "adunner";
  home.homeDirectory = "/home/adunner";
  home.stateVersion = "26.05";

  nixpkgs.config.allowUnfree = true;

  targets.genericLinux.enable = true;

  home.sessionVariables = {
    EDITOR = "vim";
    VISUAL = "vim";
  };

  home.sessionPath = [ "$HOME/.local/bin" ];

  home.packages = with pkgs; [
    jq
    htop
    starship
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initContent = ''
      # Ghost text autosuggestion colour
      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=blue"

      # Ctrl+F to accept autosuggestion (ghost text)
      bindkey '^f' autosuggest-accept

      # Homebrew/Linuxbrew
      if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
      fi

      # Starship prompt
      if command -v starship &>/dev/null; then
        eval "$(starship init zsh)"
      fi

      # fzf keybindings
      if command -v fzf &>/dev/null; then
        source <(fzf --zsh)
      fi
    '';

    history = {
      size = 10000;
      save = 10000;
      path = "$HOME/.zsh_history";
      share = true;
      ignoreAllDups = true;
      extended = true;
    };

    setOptions = [
      "AUTO_CD"
    ];

    shellAliases = {
      

      ".." = "cd ..";
      
      
      add = "git add";
      commit = "git commit";
      push = "git push";
      diff = "git diff";
};
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[➜](bold purple)";
        error_symbol = "[➜](bold red)";
      };
      cmd_duration = {
        format = "[⏱ $duration]($style)";
      };
    };
  };

  home.file.".config/wezterm" = {
    source = config.lib.file.mkOutOfStoreSymlink "/home/adunner/github/AdamDunn1437/dotfiles/home/.config/wezterm";
  };

  programs.home-manager.enable = true;
}
