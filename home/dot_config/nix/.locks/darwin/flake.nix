{
  # Renovateが隣接するflake.lockを検出・更新するためのマニフェスト。
  # inputsは../../flake.nix.tmplのDarwin向け定義と同期する。
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { ... }: { };
}