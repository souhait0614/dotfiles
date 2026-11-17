# dotfiles

[![CI Status](https://img.shields.io/github/actions/workflow/status/souhait0614/dotfiles/ci.yaml?style=flat-square&label=CI)](https://github.com/souhait0614/dotfiles/actions/workflows/ci.yaml)

## これは何

すえ用の [mise](https://mise.jdx.dev/) な dotfiles です。

以下の環境を管理します。

- mise
- Lix（macOS のみ）
- nix-darwin（macOS のみ）
- Homebrew（macOS のみ）
- apm（agent skills）

Apple Silicon Mac と、arm64 または x86_64 の Linux に対応しています。Intel Mac と NixOS はサポート対象外です。

## 使い方

mise 2026.11.8 以降と Bash・curl・Git を用意し、復号鍵をあらかじめ `~/.dotfiles-encrypt-key.txt` に配置します。macOS では Command Line Tools（`xcode-select --install`）も必要です。

```sh
# souhait・work_a・work_p から対話で選択して適用
bash scripts/bootstrap.sh

# プロファイルを指定して適用
bash scripts/bootstrap.sh souhait

# 保存済みのプロファイルで再適用
mise bootstrap
```

配置したファイルの一部はこのリポジトリへのシンボリックリンクになるため、セットアップ後もリポジトリを残してください。

### プロファイルの切り替え

端末ごとの差分はルートの [mise.souhait.toml](./mise.souhait.toml)、[mise.work_a.toml](./mise.work_a.toml)、[mise.work_p.toml](./mise.work_p.toml) で管理します。選択したプロファイルは `~/.config/mise/miserc.local.toml` に保存されます。

```sh
# 対話で選択して切り替え
mise run profile

# プロファイルを指定して切り替え
mise run profile work_a
```

各プロファイルの `vars.git_profile` は mise の age 暗号化機能で暗号化しており、適用時に `~/.config/git/profile.gitconfig` へ復号・展開されます。Git 設定を更新する場合は次のコマンドで再暗号化し、該当プロファイルの `[vars]` を更新します。

```sh
mise set --file /tmp/encrypted-profile.toml --age-encrypt \
  --age-key-file ~/.dotfiles-encrypt-key.txt --stdin git_profile \
  < ~/.config/git/profile.gitconfig
```

### 旧環境（chezmoi + Nix）からの移行

旧 chezmoi のソースディレクトリの外にこのリポジトリをクローンして実行します。旧設定を `~/.local/state/dotfiles-migration/backup.*` に退避したあと、nix-darwin と Nix/Lix をアンインストールして新環境をセットアップします。

```sh
# 変更内容を確認
bash scripts/migrate.sh --dry-run

# 移行を実行
bash scripts/migrate.sh
```

## 構成

- [mise.toml](./mise.toml): dotfiles のリンク・テンプレート配置と bootstrap タスクの定義
- [home/.config/mise/conf.d/default/mise.toml](./home/.config/mise/conf.d/default/mise.toml): 共通で利用する CLI ツールとシェルエイリアス
- [nix-darwin/](./nix-darwin/): macOS のシステム設定と Homebrew パッケージ（[homebrew.toml](./nix-darwin/homebrew.toml)）
- [home/.apm/apm.yml](./home/.apm/apm.yml): エージェント用の skill 定義

## 開発メモ

コミットメッセージの検査（commitlint）とフォーマット（oxfmt）には Node.js と pnpm を使います。依存関係を導入すると Lefthook の Git フックが有効になります。

```sh
# 開発用ツールと Git フックの導入
mise install node pnpm
mise exec -- pnpm install --frozen-lockfile

# フォーマットの実行・確認
mise exec -- pnpm fmt
mise exec -- pnpm fmt:check

# macOS 設定・シェルプラグイン・agent skills の再適用
mise run bootstrap
```

## :miteru_sakananoonigiri:

- [cffnpwr/dotfiles](https://github.com/cffnpwr/dotfiles)
- [taiyme/dotfiles](https://github.com/taiyme/dotfiles)

## ライセンス

[MIT License](./LICENSE)
