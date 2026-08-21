#!/usr/bin/env zsh

zmodload zsh/terminfo

# Ctrl+Right: 行頭へ移動
bindkey "^[[1;5D"     beginning-of-line
# Ctrl+Left: 行末へ移動
bindkey "^[[1;5C"     end-of-line
# Alt+Left: 前の単語へ移動
bindkey "^[[1;3D"     backward-word
# Alt+Right: 次の単語へ移動
bindkey "^[[1;3C"     forward-word
# Alt+Backspace: 前の単語を削除
bindkey "^[^?"        backward-kill-word

# Ctrl+R
bindkey '^R' fzf_history
# Up
# NOTE: SSH先や TERM の違いで上矢印が normal mode (^[[A) と
# application mode (^[OA) のどちらで送られるか変わるため、両方と
# terminfo の kcuu1 を保険としてバインドする
bindkey '^[[A' fzf_history
bindkey '^[OA' fzf_history
if [[ -n "${terminfo[kcuu1]}" ]]; then
  bindkey "${terminfo[kcuu1]}" fzf_history
fi
