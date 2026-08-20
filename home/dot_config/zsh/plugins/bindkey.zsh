#!/usr/bin/env zsh

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
