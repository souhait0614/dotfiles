#!/usr/bin/env zsh

# Fuzzy search through command history
function fzf_history() {
  BUFFER=$(history -r -n 1 | fzf --height 40% --tiebreak index --query "$LBUFFER")
  CURSOR=$#BUFFER
  zle reset-prompt
}
zle -N fzf_history

# Ctrl+R
bindkey '^R' fzf_history
# Up arrow
bindkey '^[[A' fzf_history