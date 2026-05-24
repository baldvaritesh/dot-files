alias vim="nvim"
alias s="kitten ssh"
alias git_clean='git branch --merged| egrep -v "(^\*|master|main|dev)" | xargs git branch -d'

export LESS='--no-init --quit-if-one-screen -R'
export EDITOR=nvim
export VISUAL=nvim
