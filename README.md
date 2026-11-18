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

Apple Silicon Mac と、arm64 または x86_64 の Linux（WSL を含む）に対応しています。Intel Mac と NixOS はサポート対象外です。

## 使い方

mise 2026.11.8 以降と Zsh・Bash・curl・Git を用意し、ログインシェルを Zsh に設定します。復号鍵はあらかじめ `~/.dotfiles-encrypt-key.txt` に配置してください。macOS では Command Line Tools（`xcode-select --install`）も必要です。

```sh
# souhait・work_a・work_p から対話で選択して適用
bash scripts/bootstrap.sh

# プロファイルを指定して適用
bash scripts/bootstrap.sh souhait

# 保存済みのプロファイルで再適用
mise bootstrap
```

配置したファイルの一部はこのリポジトリへのシンボリックリンクになるため、セットアップ後もリポジトリを残してください。

macOS では Bitwarden の SSH エージェントを使用します。`SSH_AUTH_SOCK` は Zsh の起動時に設定されます。

### WSL

シンボリックリンクやファイル権限を扱うため、ホームディレクトリとチェックアウトは `/mnt/c` などの Windows ドライブではなく、WSL の Linux ファイルシステム上に置いてください。mise・Zsh・Bash・curl・Git は WSL 内に用意し、ログインシェルも WSL 内の Zsh に設定してください。

`bash scripts/bootstrap.sh souhait` と `bash scripts/migrate.sh` は WSL では `~/.ssh` の管理をスキップするか確認します。Windows と `~/.ssh` を共有しているなら、そのまま Enter を押してください。スキップ時は SSH 設定の配置や権限変更だけでなく、移行時の SSH 設定の退避も行いません。Windows 側の SSH エージェントの設定は変更しません。

`--yes`、`--dry-run`、端末入力のない実行では、指定がなければ SSH をスキップします。WSL 専用の `~/.ssh` に適用する場合は `DOTFILES_SSH=apply bash scripts/bootstrap.sh souhait --yes` と指定できます。`DOTFILES_SSH=skip` を指定すると、対話なしで SSH をスキップします。どちらの指定も移行スクリプトで使えます。

`mise bootstrap` による再適用では保存済みのプロファイルと SSH の選択を使います。WSL で選択をまだ保存していない場合や変更する場合は、`bash scripts/bootstrap.sh souhait` を実行してください。

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

### キー割り当て

macOS のキー割り当ては [scripts/karabiner.mts](./scripts/karabiner.mts) で管理します。[karabiner.ts](https://github.com/evan-liu/karabiner.ts) を使い、bootstrap 時に Karabiner-Elements の設定を生成します。

- Caps Lock → Control
- Fn → Command
- 左 Command の単押しで英数、右 Command の単押しでかなに切り替え
- Command + Q の2度押しで終了

変更後は次のコマンドで依存関係を導入し、設定を再生成できます。Linux ではスキップします。

```sh
mise run karabiner
```

生成時に `~/.config/karabiner/karabiner.json` 全体を置き換えるため、GUI 側だけで加えた変更は保持されません。

### 旧環境（chezmoi + Nix）からの移行

旧 chezmoi のソースディレクトリの外にこのリポジトリをクローンして実行します。旧設定を `~/.local/state/dotfiles-migration/backup.*` に退避したあと、nix-darwin と Nix/Lix をアンインストールして新環境をセットアップします。

Nix/Lix の削除はシステム全体と他のユーザーに影響します。Nix ストアはバックアップされません。削除に使うインストーラーと記録は `~/.local/state/dotfiles-migration/uninstaller.*` に保存されます。中断後に未マウントの Nix Store ボリュームが残っている場合は、旧環境の削除を完了してから再実行してください。

macOS の `/etc/pam.d/sudo_local` に既存の通常ファイルがある場合は、内容を確認してから別名に退避してください。既存の退避ファイルを上書きしないでください。

```sh
# 変更内容を確認
bash scripts/migrate.sh --dry-run

# 移行を実行
bash scripts/migrate.sh
```

## 構成

- [mise.toml](./mise.toml): dotfiles のリンク・テンプレート配置と bootstrap タスクの定義
- [home/.config/mise/conf.d/default/mise.toml](./home/.config/mise/conf.d/default/mise.toml): 共通で利用する CLI ツールとシェルエイリアス
- [nix-darwin/](./nix-darwin/): macOS のシステム設定・フォント・Homebrew パッケージ
  - [fonts.toml](./nix-darwin/fonts.toml): Nix の属性名で指定するフォント一覧。`.` 区切りの属性名にも対応
  - [homebrew.toml](./nix-darwin/homebrew.toml): Homebrew パッケージ一覧
    - macOS では、一覧にない Homebrew パッケージを検出すると、削除せずに設定の適用を中止します。プリインストール済みのパッケージがある CI ランナーでは、このチェックを行いません。
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

# TypeScript の型検査
mise exec -- pnpm typecheck

# macOS 設定・シェルプラグイン・agent skills の再適用
mise run bootstrap
```

## :miteru_sakananoonigiri:

- [cffnpwr/dotfiles](https://github.com/cffnpwr/dotfiles)
- [taiyme/dotfiles](https://github.com/taiyme/dotfiles)

## ライセンス

[MIT License](./LICENSE)
