# Dotfiles

## Fresh Ubuntu Setup

```sh
sudo apt update
sudo apt install -y git curl
git clone https://github.com/baldvaritesh/dot-files.git ~/dot-files
cd ~/dot-files
bash scripts/bootstrap-ubuntu.sh
```

## 1Password SSH Agent

After bootstrap finishes, sign in to the 1Password desktop app and enable:

```text
Settings -> Developer -> SSH Agent
```

Create the SSH agent config:

```sh
mkdir -p ~/.config/1Password/ssh
nvim ~/.config/1Password/ssh/agent.toml
```

Example:

```toml
[[ssh-keys]]
item = "Github Private Key"
vault = "Personal"

[[ssh-keys]]
item = "AWS Private Key"
vault = "Work"
```

Use the exact item names from 1Password. Restart 1Password or toggle the SSH agent off and on after editing the file.
Verify the agent (Note that the SSH_AUTH_SOCK) will be needed to talk to the 1password agent:

```sh
SSH_AUTH_SOCK="$HOME/.1password/agent.sock" ssh-add -L
```

SSH host entries should use:

```sshconfig
IdentityAgent ~/.1password/agent.sock
```

## Setup using chezmoi

Then review and apply dotfiles:

```sh
chezmoi init --source ~/dot-files
chezmoi diff
chezmoi apply
```
