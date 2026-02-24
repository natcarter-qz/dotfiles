#!/bin/bash

# Download and install Tokyo Night Dark theme (not on Open VSX so we need the .vsix)
THEME_URL="https://marketplace.visualstudio.com/_apis/public/gallery/publishers/drewxs/vsextensions/tokyo-night-dark/latest/vspackage"
VSIX="/tmp/tokyo-night-dark.vsix"

# Marketplace returns gzip-compressed content
curl -sL "$THEME_URL" | gunzip > "$VSIX" 2>/dev/null || curl -sL -o "$VSIX" "$THEME_URL"

# Install for VS Code and local Cursor
cursor --install-extension "$VSIX" 2>/dev/null ||
	code --install-extension "$VSIX" 2>/dev/null || true

# Install into Cursor's remote server extensions directory.
# On remote hosts like Gitpod, the cursor CLI doesn't exist and the
# code CLI installs into VS Code's server — not Cursor's.
mkdir -p "$HOME/.cursor-server/extensions"
code --extensions-dir "$HOME/.cursor-server/extensions" \
	--install-extension "$VSIX" 2>/dev/null || true

rm -f "$VSIX"

SETTINGS_DIR="$(dirname "$0")"

# Apply settings to local Cursor/VS Code
mkdir -p "$HOME/.config/Cursor/User"
cp "$SETTINGS_DIR/cursor-settings.json" "$HOME/.config/Cursor/User/settings.json"

# Apply settings to Cursor remote server (for Gitpod/SSH remotes)
if [ -d "$HOME/.cursor-server/data/Machine" ]; then
	python3 -c "
import json, sys
machine = '$HOME/.cursor-server/data/Machine/settings.json'
dotfile = '$SETTINGS_DIR/cursor-settings.json'
with open(machine) as f: existing = json.load(f)
with open(dotfile) as f: overrides = json.load(f)
existing.update(overrides)
with open(machine, 'w') as f: json.dump(existing, f, indent=4)
" 2>/dev/null || true
fi
