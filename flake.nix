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

        # Bootstrap only: everyday tools now live in home.packages (home.nix),
        # so they're available in every repo without `nix develop`.
        packages = [
          home-manager.packages.${system}.default
        ];

        shellHook = ''
          # Add Homebrew/Linuxbrew to PATH if installed (standalone, not via Nix)
          if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
            _nix_path="$PATH"
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
            export PATH="$_nix_path:$PATH"
            unset _nix_path
          fi

          echo "✦ dotfiles bootstrap shell"
          echo "  home-manager: $(home-manager --version 2>/dev/null)"
          echo ""
          echo "Everyday tools come from home.packages in home.nix. To apply:"
          echo "  ./install.sh && home-manager switch --flake ."
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
