# Dotfiles

## Fresh Ubuntu Setup

```sh
sudo apt update
sudo apt install -y git curl
git clone https://github.com/baldvaritesh/dot-files.git ~/dot-files
cd ~/dot-files
bash bootstrap-ubuntu.sh
```

Then review and apply dotfiles:
```sh
chezmoi init --source ~/dot-files
chezmoi diff
chezmoi apply
```
