#!/usr/bin/env bash
set -euo pipefail

log() {
    printf '\n==> %s\n' "$*"
}

validate_inputs() {
    SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
    REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
    PACKAGES_COMMON="${1:-$REPO_ROOT/packages/apt-common.txt}"
    if [ ! -f "$PACKAGES_COMMON" ]; then
        echo "Package file not found: $PACKAGES_COMMON" >&2
        exit 1
    fi
}

install_apt_packages() {
    log "Installing apt packages from $PACKAGES_COMMON"
    sudo apt update
    grep -vE '^\s*(#|$)' "$PACKAGES_COMMON" | xargs -r sudo apt-get install -y
}

github_latest_release() {
    local repo=$1
    curl -fsSL "https://api.github.com/repos/$repo/releases/latest"
}

github_latest_tag() {
    local repo=$1
    github_latest_release "$repo" | jq -r '.tag_name | sub("^v"; "")'
}

github_latest_asset_url() {
    local repo=$1
    local asset_regex=$2
    github_latest_release "$repo" | jq -r --arg regex "$asset_regex" '
        .assets[]
        | select(.name | test($regex))
        | .browser_download_url
    ' | head -n 1
}

install_deb_from_github_latest() {
    local name=$1
    local command_name=$2
    local repo=$3
    local asset_regex=$4
    local current_version=""
    local latest_version
    local url
    local deb_path

    latest_version="$(github_latest_tag "$repo")"
    if command -v "$command_name" >/dev/null 2>&1; then
        current_version="$("$command_name" --version | head -n 1 | grep -Eo '[0-9]+(\.[0-9]+)+' | head -n 1 || true)"
    fi

    if [ "$current_version" = "$latest_version" ]; then
        log "$name $latest_version already installed"
        return
    fi

    url="$(github_latest_asset_url "$repo" "$asset_regex")"
    if [ -z "$url" ]; then
        echo "Could not find release asset for $name in $repo matching $asset_regex" >&2
        exit 1
    fi

    log "Installing $name $latest_version from GitHub"
    deb_path="$(mktemp "/tmp/${name}.XXXXXX.deb")"
    curl -fsSL "$url" -o "$deb_path"
    sudo apt install -y "$deb_path"
    rm -f "$deb_path"
}

install_fzf_from_github_latest() {
    local current_version=""
    local latest_version
    local url
    local archive_path
    local extract_dir

    latest_version="$(github_latest_tag "junegunn/fzf")"
    if command -v fzf >/dev/null 2>&1; then
        current_version="$(fzf --version | head -n 1 | grep -Eo '[0-9]+(\.[0-9]+)+' | head -n 1 || true)"
    fi

    if [ "$current_version" = "$latest_version" ]; then
        log "fzf $latest_version already installed"
        return
    fi

    url="$(github_latest_asset_url "junegunn/fzf" '^fzf-.*-linux_amd64\.tar\.gz$')"
    if [ -z "$url" ]; then
        echo "Could not find fzf linux amd64 release asset" >&2
        exit 1
    fi

    log "Installing fzf $latest_version from GitHub"
    archive_path="$(mktemp /tmp/fzf.XXXXXX.tar.gz)"
    extract_dir="$(mktemp -d /tmp/fzf.XXXXXX)"
    curl -fsSL "$url" -o "$archive_path"
    tar -xzf "$archive_path" -C "$extract_dir"
    sudo install -m 0755 "$extract_dir/fzf" /usr/local/bin/fzf
    rm -rf "$archive_path" "$extract_dir"
}

install_modern_cli_tools() {
    install_deb_from_github_latest \
        "ripgrep" \
        "rg" \
        "BurntSushi/ripgrep" \
        '^ripgrep_.*_amd64\.deb$'

    install_deb_from_github_latest \
        "fd" \
        "fd" \
        "sharkdp/fd" \
        '^fd_.*_amd64\.deb$'

    install_fzf_from_github_latest
}

install_1password_app() {
    if command -v 1password >/dev/null 2>&1; then
        log "1Password app already installed"
        return
    fi
    log "Installing 1Password app"
    curl -fsSL https://downloads.1password.com/linux/debian/amd64/stable/1password-latest.deb -o /tmp/1password-latest.deb
    sudo apt install -y /tmp/1password-latest.deb
}

install_1password_cli() {
    if command -v op >/dev/null 2>&1; then
        log "1Password CLI already installed"
        return
    fi
    log "Installing 1Password CLI"
    # existing official repo install block here
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
        sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg && \
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
        sudo tee /etc/apt/sources.list.d/1password.list && \
        sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/ && \
        curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
        sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol && \
        sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22 && \
        curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
        sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg && \
        sudo apt update && sudo apt install 1password-cli -y
}

install_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
      log "Oh My Zsh already installed"
      return
    fi
    log "Installing Oh My Zsh"
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_zsh_vi_mode() {
    local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    local plugin_dir="$zsh_custom/plugins/zsh-vi-mode"
    if [ -d "$plugin_dir/.git" ]; then
      log "zsh-vi-mode already installed"
      return
    fi
    log "Installing zsh-vi-mode"
    mkdir -p "$zsh_custom/plugins"
    git clone https://github.com/jeffreytse/zsh-vi-mode "$plugin_dir"
}

print_next_steps() {
    cat <<EOF
    ==> Bootstrap complete
    Next steps:
    1. Sign in to 1Password
        Open the 1Password app and sign in. Then verify the CLI:
        $ op whoami
        If this fails, enable 1Password CLI integration in the 1Password app.
    2. Verify GitHub SSH access
        If using the 1Password SSH agent, enable it in the 1Password app.
        Then run:
        $ ssh -T git@github.com
    3. Preview dotfile changes with chezmoi
        From this repo:
        $ chezmoi init --source "$REPO_ROOT"
        $ chezmoi diff
    4. Apply dotfiles only after reviewing the diff
        $ chezmoi apply
    5. Start a new zsh shell
        $ zsh -l
    6. Change the default shell only after zsh works
        $ chsh -s "\$(command -v zsh)"

    Notes:
    - This script installs prerequisites only.
    - It does not apply chezmoi.
    - It does not change your default shell.
    - It does not create or restore secrets.
    - Private values should come from 1Password or ~/.zshrc.local.
EOF
}

main() {
    validate_inputs "$@"
    install_apt_packages
    install_modern_cli_tools
    install_1password_app
    install_1password_cli
    install_oh_my_zsh
    install_zsh_vi_mode
    print_next_steps
}

main "$@"
