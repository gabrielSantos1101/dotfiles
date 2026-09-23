# dotfiles

Personal dev-environment dotfiles managed with [chezmoi].

Nothing about the desktop/theme here — just the tools I use to code:
shell (zsh), editor (Neovim/LazyVim), terminals, and small utilities.

## Contents

- `~/.zshrc`, `~/.config/starship.toml` — shell + prompt
- `~/.config/nvim` — Neovim (LazyVim starter + personal tweaks)
- `~/.config/alacritty` — terminal emulator
- `~/.config/zellij` — terminal multiplexer (config + layouts)
- `~/.config/tmux` — tmux as fallback
- `~/.config/btop`, `~/.config/lazygit`, `~/.config/mise` — dev tools
- `~/.config/git` — git aliases & defaults
- `setup/` — bootstrap script for a fresh machine

## Restore on a new machine

```bash
sh -c "$(curl -fsSL https://get.chezmoi.io)" -- -b "$HOME/.local/bin"
chezmoi init https://github.com/gabrielSantos1101/dotfiles.git
chezmoi apply
```

On Omarchy, run this *after* installing Omarchy (it generates the base
configs that the dotfiles override).

## Updating after a config change

```bash
chezmoi add ~/.config/zellij/config.kdl   # capture a change
chezmoi cd && git add -A && git commit    # commit
chezmoi update                            # on other machines: pull + apply
```

[chezmoi]: https://www.chezmoi.io