{
  description = "mise から適用する macOS の設定とアプリケーション";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nix-darwin, ... }: {
    packages.aarch64-darwin.darwin-rebuild =
      nix-darwin.packages.aarch64-darwin.darwin-rebuild;

    darwinConfigurations.default = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = {
        inherit self;
        primaryUser = builtins.getEnv "DOTFILES_USERNAME";
        userHome = builtins.getEnv "DOTFILES_HOME";
        profile = builtins.getEnv "DOTFILES_PROFILE";
        isCI = builtins.getEnv "CI" == "true";
      };
      modules = [ ./configuration.nix ];
    };
  };
}
