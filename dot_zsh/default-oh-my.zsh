export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(
    zsh-vi-mode
)
if [ -r "$ZSH/oh-my-zsh.sh" ]; then
    source "$ZSH/oh-my-zsh.sh"
else
    print "Oh My Zsh not found at $ZSH. Run scripts/bootstrap-ubuntu.sh first." >&2
fi
