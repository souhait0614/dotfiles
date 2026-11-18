#!/usr/bin/env zsh

zmodload zsh/terminfo

bindkey "^[[1;5D" beginning-of-line
bindkey "^[[1;5C" end-of-line
bindkey "^[[1;3D" backward-word
bindkey "^[[1;3C" forward-word
bindkey "^[^?" backward-kill-word

bindkey '^R' fzf_history
bindkey '^[[A' fzf_history
bindkey '^[OA' fzf_history
if [[ -n "${terminfo[kcuu1]:-}" ]]; then
  bindkey "${terminfo[kcuu1]}" fzf_history
fi
