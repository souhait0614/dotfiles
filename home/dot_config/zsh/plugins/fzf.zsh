#!/usr/bin/env zsh

# Fuzzy search through command history
function fzf_history() {
  BUFFER=$(history -r -n 1 | fzf --height 40% --tiebreak index --query "$LBUFFER")
  CURSOR=$#BUFFER
  zle reset-prompt
}
zle -N fzf_history