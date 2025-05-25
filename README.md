# dotfiles

[![CI Status](https://img.shields.io/github/actions/workflow/status/souhait0614/dotfiles/ci.yaml?style=flat-square&label=CI)](https://github.com/souhait0614/dotfiles/actions/workflows/ci.yaml)

## これは何

すえ用の [chezmoi](https://www.chezmoi.io) なdotfiles

arm64なmacOSとx64なLinuxでの使用を想定しています

## 使い方

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply souhait0614
```

## メモ

```sh
# .Brewfile を更新する
brew bundle dump --file="$(chezmoi source-path)/dot_Brewfile_macos" --no-vscode --force
```

## :miteru_sakananoonigiri:

- [cffnpwr/dotfiles](https://github.com/cffnpwr/dotfiles)
- [taiyme/dotfiles](https://github.com/taiyme/dotfiles)

## ライセンス

[MIT License](./LICENSE)
