# dotfiles の作業指示

## 構成

- 対象は Apple Silicon macOS と arm64 / x86_64 Linux（WSL を含む）。ユーザー環境は両方で mise が管理し、Lix・nix-darwin・Homebrew によるシステム設定は macOS のみに適用する。
- [ルートの mise.toml](./mise.toml) は bootstrap、Node.js・pnpm、`home/` からの配置方法を定義する。Zsh や共通 Git 設定はシンボリックリンク、APM・Claude・Copilot 設定はコピー、SSH は権限を指定して配置する。[配布用の mise.toml](./home/.config/mise/conf.d/default/mise.toml) は日常使う CLI とエイリアスを定義する。編集は配布元で行い、リンクの参照先となるチェックアウトは残す。
- [bootstrap.sh](./scripts/bootstrap.sh) は `souhait`、`work_a`、`work_p` のいずれかを選び、`mise -E <profile> bootstrap --save-env` で `~/.config/mise/miserc.local.toml` に保存する。`pre-dotfiles` フックでプロファイルを検査し、macOS では未管理の `/etc/pam.d/sudo_local` が通常ファイルとして残っていれば適用を止める。プロファイルを増やすときは、`mise.<profile>.toml` に加えて `bootstrap.sh` の選択・検査と、[setup-nix-darwin.sh](./scripts/setup-nix-darwin.sh)、[configuration.nix](./nix-darwin/configuration.nix) の許可リストを更新する。
- WSL では bootstrap と移行で SSH の適用可否を選び、非対話時は既定でスキップする。選択は `skip-ssh` または `apply-ssh` をプロファイルに追加して保存する。スキップ時は移行の退避対象から SSH を外し、[mise.skip-ssh.toml](./mise.skip-ssh.toml) で権限だけを管理する項目も含めて無効にする。SSH の配置項目を追加するときは無効化する項目も更新する。
- bootstrap のタスクは macOS のシステム設定、Karabiner 設定の生成、`sheldon lock`、`apm install -g` の順に実行する。macOS 専用の処理は Linux でスキップする。`interactive = true` は `sudo` の端末入力に必要なので維持する。`mise run bootstrap` はこのタスクだけを再実行し、dotfiles の配置には `mise bootstrap` を使う。
- [bootstrap CI](./.github/workflows/ci.yaml) は Linux と macOS で `bash scripts/bootstrap.sh souhait --yes` を実行する。`DOTFILES_ENCRYPT_KEY` を `MISE_AGE_KEY` として渡し、fork の PR と Dependabot はスキップする。macOS ではシステム設定を実際に適用し、`CI=true` では App Store アプリだけを Homebrew の導入対象から外す。[commitlint CI](./.github/workflows/commitlint.yaml) は別に動き、push の最新コミットまたは PR のコミット範囲を検査する。

## 開発メモ

以下はリポジトリルートで実行する。mise は [mise.toml](./mise.toml) の `min_version` 以上を使う。macOS の bootstrap には Command Line Tools も必要。

独立したビルド工程やユニットテストはない。統合テストは上記の bootstrap CI。

```sh
mise install node pnpm
mise exec -- pnpm install --frozen-lockfile
mise exec -- pnpm typecheck                   # TypeScript の型検査（成果物の生成なし）
mise exec -- pnpm fmt:check                   # 全体の整形を検査
mise exec -- pnpm fmt:check README.md         # 1 ファイルの整形を検査
mise exec -- pnpm commitlint --last --verbose # 最新の 1 コミットを検査
bash -n scripts/migrate.sh                    # 1 スクリプトの構文を検査
bash scripts/bootstrap.sh --check souhait    # プロファイルと macOS の PAM を事前検査
```

WSL で事前検査する場合は `bash scripts/bootstrap.sh --check souhait,skip-ssh` のように SSH の選択も渡す。

適用せずに確認するには `mise -E souhait bootstrap --only task --dry-run --yes` でタスクをプレビューし、移行には `bash scripts/migrate.sh --dry-run` を使う。Nix の設定だけを確認するときは、`DOTFILES_USERNAME`・`DOTFILES_HOME`・`DOTFILES_PROFILE` を渡し、`nix eval --impure "path:$PWD/nix-darwin#darwinConfigurations.default.config.fonts.packages"` のように対象の属性を評価する。bootstrap・移行・`mise run karabiner` の実適用は検証のために普段使いの環境で実行しない。

## 変更時の規約

- `mise.<profile>.toml` の `vars.git_profile` は age で暗号化する。mise が [Tera テンプレート](./home/.config/git/profile.gitconfig.tera)を `~/.config/git/profile.gitconfig` に権限 `0600` で展開し、共通の Git 設定が読み込む。鍵の既定パスは `~/.dotfiles-encrypt-key.txt`。平文や復号鍵はコミットせず、更新手順は [README](./README.md#プロファイルの切り替え) に従う。
- macOS のパッケージとフォントは [homebrew.toml](./nix-darwin/homebrew.toml) と [fonts.toml](./nix-darwin/fonts.toml) で管理する。フォント名は `ibm-plex.sans-jp` のような nixpkgs の属性パス。初回導入用の Lix バージョンは [lix-version](./nix-darwin/lix-version)、適用後の Lix は flake で固定した nixpkgs から取得する。`openssl@3` は Sheldon の実行時依存。APM は Linux arm64 の glibc 互換性を保つため `pypi:apm-cli` を使い、[Renovate](./renovate.json) が Lix と APM 専用 Python のバージョンも追跡する。
- [Karabiner の設定元](./scripts/karabiner.mts) は Node.js で直接実行する。`mise run karabiner` は macOS で `~/.config/karabiner/karabiner.json` 全体を置き換える。Zsh の初期化は `home/.zshenv` が `ZDOTDIR` を設定し、配下の `.zprofile` と `.zshrc` が mise を有効化する。Bitwarden の `SSH_AUTH_SOCK` は macOS の `.zshenv` で設定する。
- [migrate.sh](./scripts/migrate.sh) は macOS 標準の Bash でも動くようにする。既存設定の退避後、nix-darwin → Nix/Lix の順で削除する。アンインストーラーと receipt は `/nix` の外にコピーしてから実行し、古い Nix Store の APFS ボリュームが残っていれば再導入を止める。`cleanup-complete` 以降の再実行では新しい Nix を削除しない。Nix の削除は全ユーザーに影響し、ストアは退避しない。
- `pnpm-lock.yaml` は pnpm 本体とプロジェクト依存を別の YAML ドキュメントに持つ。更新には mise で固定した pnpm を使う。依存導入時に `prepare` が Lefthook を設定し、pre-commit がステージ済みファイルを oxfmt で整形して再ステージする。コミットメッセージは Conventional Commits に従う。[個人用 Copilot 設定](./home/.copilot/copilot-instructions.md) に合わせ、明示的な依頼がない限り `Co-authored-by` は付けない。
