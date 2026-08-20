# fzf-tab

# `git checkout` 補完時のソートを無効化
zstyle ':completion:*:git-checkout:*' sort false
# グループ表示を有効化するために説明の表示形式を設定
# NOTE: ここではエスケープシーケンス（例: '%F{red}%d%f'）を使わないこと。fzf-tab に無視される
zstyle ':completion:*:descriptions' format '[%d]'
# ファイル名の色付けを有効化するため list-colors を設定
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# zsh の補完メニュー表示を無効化し、fzf-tab が曖昧でないプレフィックスを取得できるようにする
zstyle ':completion:*' menu no
# cd 補完時に eza でディレクトリ内容をプレビュー
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
# カスタム fzf フラグ
# NOTE: fzf-tab はデフォルトでは FZF_DEFAULT_OPTS に従わない
zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:accept
# fzf-tab を FZF_DEFAULT_OPTS に従わせる
# NOTE: 一部フラグがこのプラグインを壊すため、予期しない動作になる可能性あり。Aloxaf/fzf-tab#455 を参照
zstyle ':fzf-tab:*' use-fzf-default-opts yes
# `<` と `>` でグループ切り替え
zstyle ':fzf-tab:*' switch-group '<' '>'