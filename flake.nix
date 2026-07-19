{
  description = "Personal dotfiles — Nix dev shell + symlink installer";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-26.05";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, home-manager }:
    let
      pkgsFor = system: import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      forAllSystems = flake-utils.lib.eachDefaultSystem;
    in
    (forAllSystems (system: {
      devShells.default = (pkgsFor system).mkShell {
        name = "dotfiles-dev";

        packages = with pkgsFor system; [
          git
          zsh
          vim
          tmux
          starship
          fzf
          ripgrep
          fd
          wezterm
        ];

        shellHook = ''
          # Add Homebrew/Linuxbrew to PATH if installed (standalone, not via Nix)
          if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
            _nix_path="$PATH"
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
            export PATH="$_nix_path:$PATH"
            unset _nix_path
          fi

          echo "✦ dotfiles dev shell activated"
          echo "  git:      $(git --version 2>/dev/null)"
          echo "  zsh:      $(zsh --version 2>/dev/null)"
          echo "  vim:      $(vim --version 2>/dev/null | head -1)"
          echo "  tmux:     $(tmux -V 2>/dev/null)"
          echo "  wezterm:  $(wezterm --version 2>/dev/null)"
          echo "  starship: $(starship --version 2>/dev/null | head -1)"
          echo "  fzf:      $(fzf --version 2>/dev/null)"
          echo "  rg:       $(rg --version 2>/dev/null | head -1)"
          echo "  fd:       $(fd --version 2>/dev/null)"
          echo ""
          echo "Run ./install.sh to symlink config files into \$HOME"
        '';
      };
    }))
    // {
      homeConfigurations."adunner" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [ ./home.nix ];
      };
    };
}
