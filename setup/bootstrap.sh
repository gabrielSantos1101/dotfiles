#!/usr/bin/env bash
# Bootstrap a fresh Linux machine with these dotfiles.
# Run on a new machine after the base OS (and Omarchy, if using it) is installed.
set -euo pipefail

REPO_URL="https://github.com/gabrielSantos1101/dotfiles.git"

echo "==> Installing chezmoi (if missing)"
if ! command -v chezmoi >/dev/null 2>&1; then
  export PATH="$HOME/.local/bin:$PATH"
  sh -c "$(curl -fsSL https://get.chezmoi.io)" -- -b "$HOME/.local/bin"
fi

echo "==> Cloning and applying dotfiles"
chezmoi init "$REPO_URL"
chezmoi apply

echo "==> Done."
echo "    On Omarchy this should run AFTER the base Omarchy config is generated."
echo "    Restart your shell (or run: source ~/.zshrc) to pick up the changes."