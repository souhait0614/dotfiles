# dotfiles

[![CI Status](https://img.shields.io/github/actions/workflow/status/souhait0614/dotfiles/ci.yaml?style=flat-square&label=CI)](https://github.com/souhait0614/dotfiles/actions/workflows/ci.yaml)

## これは何

すえ用の [chezmoi](https://www.chezmoi.io) なdotfilesです。

以下の環境を管理します。

- chezmoi
- Lix
- nix-darwin（macOSのみ）
- Homebrew

Apple Silicon Macと、arm64またはx86_64のLinuxに対応しています。Intel
Macはサポート対象外です。

## 使い方

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply souhait0614
```

初期化時にセットアップのプリセットを選択します。`Custom`を選択すると、sudoの使用とHomebrewのコマンドを手動で設定できます。sudoを許可しない場合、Lix、Homebrew、nix-darwinの新規インストールはスキップされます。

バージョンやツールごとの設定は`home/.chezmoidata/`、端末ごとの値はchezmoiの設定ファイル内の`data`で管理します。共通CLIはNix、macOSアプリとmacOS固有ツールはHomebrewで管理します。

OSとアーキテクチャの条件分岐には、`home/.chezmoi.toml.tmpl`で生成する`platform`を使用します。対応する値は`darwin-arm64`、`linux-arm64`、`linux-x86_64`です。

- `versions.toml`: Renovateなどで更新するバージョン
- `lix.toml`: Lixの配布元
- `homebrew.toml`: Homebrewの導入、tap、formula、cask設定
- `nix.toml`: macOSとLinuxで共通利用するCLIパッケージとmacOSフォント

## メモ

```sh
# LinuxのCLIパッケージを再ビルドする
mkdir -p "$HOME/.local/state/nix/profiles"
nix build "$HOME/.config/nix#default" \
  --out-link "$HOME/.local/state/nix/profiles/dotfiles-cli"

# macOSのnix-darwin設定を手動で再適用する
sudo nix run "$HOME/.config/nix#darwin-rebuild" -- \
  switch --flake "$HOME/.config/nix#$(hostname -s)"
```

## :miteru_sakananoonigiri:

- [cffnpwr/dotfiles](https://github.com/cffnpwr/dotfiles)
- [taiyme/dotfiles](https://github.com/taiyme/dotfiles)

## ライセンス

[MIT License](./LICENSE)
