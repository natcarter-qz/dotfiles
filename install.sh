#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p "$HOME/.zshrc.d"
for f in zshrc.d/*.zsh; do
  ln -sfn "$PWD/$f" "$HOME/.zshrc.d/$(basename "$f")"
done