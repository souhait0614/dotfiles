#!/usr/bin/env zsh

eval "$(mise activate zsh)"

mkdir -p "$XDG_STATE_HOME/zsh"
export HISTFILE="$XDG_STATE_HOME/.zsh_history"
export HISTSIZE=1000
export SAVEHIST=100000

setopt hist_ignore_dups extended_history hist_ignore_all_dups hist_ignore_space
setopt hist_verify hist_reduce_blanks hist_save_no_dups hist_no_store hist_expand share_history

sheldon_source="$(sheldon source)" || return
eval "$sheldon_source"
unset sheldon_source

if [[ -r "$HOME/.orbstack/shell/init.zsh" ]]; then
  source "$HOME/.orbstack/shell/init.zsh"
fi

if [[ -r "$ZDOTDIR/.zshrc.local" ]]; then
  source "$ZDOTDIR/.zshrc.local"
fi
