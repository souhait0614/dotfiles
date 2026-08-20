{
  # Renovateが隣接するflake.lockを検出・更新するためのマニフェスト。
  # inputsは../../flake.nix.tmplのLinux向け定義と同期する。
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { ... }: { };
}