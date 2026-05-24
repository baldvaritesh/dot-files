path_prepend() {
    [ -d "$1" ] || return
    case ":$PATH:" in
        *":$1:"*) ;;
        *) export PATH="$1:$PATH" ;;
    esac
}
path_append() {
    [ -d "$1" ] || return
    case ":$PATH:" in
        *":$1:"*) ;;
        *) export PATH="$PATH:$1" ;;
    esac
}

path_prepend "$HOME/.npm-global/bin"
