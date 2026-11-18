#!/usr/bin/env zsh

typeset -Ug path PATH

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

if [[ "$OSTYPE" == darwin* ]]; then
  export SSH_AUTH_SOCK="$HOME/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock"
fi

path=(
  "$HOME/.local/bin"(N-/)
  $path
)

if [[ -x /opt/homebrew/bin/brew ]]; then
  # キャッシュファイルがない場合のみ brew shellenv を実行して保存
  cache_file="${XDG_CACHE_HOME:-$HOME/.cache}/brew_shellenv.zsh"
  if [[ ! -f "$cache_file" ]]; then
    mkdir -p "${cache_file:h}"
    /opt/homebrew/bin/brew shellenv > "$cache_file"
  fi
  source "$cache_file"
fi
