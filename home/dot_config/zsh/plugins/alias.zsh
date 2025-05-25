#!/bin/zsh

# alias
alias ls="eza --git"
alias la="eza -a --git"
alias ll="eza -ahl --git"
alias lt="eza -T -L 3 -a -I 'node_modules|.git|.cache'"
alias lta="eza -T -a -I 'node_modules|.git|.cache' --color=always | less -r"
alias l="clear && ls"
alias tree="lt"
alias code="code-insiders"