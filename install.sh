#!/bin/bash

# Install Dracula theme. VS Code pulls it straight from the
# Microsoft Marketplace, so no .vsix download is needed.
code --install-extension dracula-theme.theme-dracula 2>/dev/null || true

SETTINGS_DIR="$(dirname "$0")"

# Apply settings to local VS Code
mkdir -p "$HOME/.config/Code/User"
cp "$SETTINGS_DIR/vscode-settings.json" "$HOME/.config/Code/User/settings.json"

# Apply settings to the VS Code server (for Gitpod/SSH remotes)
if [ -d "$HOME/.vscode-server/data/Machine" ]; then
	python3 -c "
import json
machine = '$HOME/.vscode-server/data/Machine/settings.json'
dotfile = '$SETTINGS_DIR/vscode-settings.json'
with open(machine) as f: existing = json.load(f)
with open(dotfile) as f: overrides = json.load(f)
existing.update(overrides)
with open(machine, 'w') as f: json.dump(existing, f, indent=4)
" 2>/dev/null || true
fi
