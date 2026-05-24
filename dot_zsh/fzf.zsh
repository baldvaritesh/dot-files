if command -v fzf >/dev/null 2>&1; then 
    function zvm_after_init() {
        source <(fzf --zsh)
    }
fi
