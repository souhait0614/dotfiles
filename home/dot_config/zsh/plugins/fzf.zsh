#!/usr/bin/env zsh

# Fuzzy search through command history

function fzf_history() {
  BUFFER=$(history -r -n 1 | fzf --layout reverse --height 40% --tiebreak index --query "$LBUFFER")
  CURSOR=$#BUFFER
  zle clear-screen
}
zle -N fzf_history

# Bindings
bindkey '^R' fzf_history