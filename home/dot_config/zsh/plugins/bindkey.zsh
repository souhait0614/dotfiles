#!/bin/zsh

# Key bindings
bindkey "^A"          beginning-of-line
bindkey "^E"          end-of-line
bindkey "^[[1;5C"     beginning-of-line
bindkey "^[[1;5D"     end-of-line
bindkey "^[f"         forward-word
bindkey "^[b"         backward-word
bindkey "^[[1;3C"     forward-word
bindkey "^[[1;3D"     backward-word
bindkey "^[^?"        backward-kill-word
bindkey "^[[killline" vi-kill-line
bindkey "^I"          menu-select
bindkey "^R"          fzf-select-history
bindkey "^X"          fzf-cd-src
bindkey "^F"          fzf-cdr

bindkey               "$terminfo[kcbt]" menu-select
bindkey -M menuselect              "^I" menu-complete
bindkey -M menuselect "$terminfo[kcbt]" reverse-menu-complete