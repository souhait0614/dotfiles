#!/usr/bin/env zsh

function fzf_history() {
  local selected
  selected=$(history -r -n 1 | fzf --height 40% --tiebreak index --query "$LBUFFER") || return
  BUFFER="$selected"
  CURSOR=$#BUFFER
  zle reset-prompt
}
zle -N fzf_history
