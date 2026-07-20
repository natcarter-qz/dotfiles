#!/bin/bash

# Runs at Gitpod workspace init — before the VS Code server or its `code`
# CLI exist — so everything here writes ~/.vscode-server paths directly,
# which the server picks up when it installs on first connect.

SETTINGS_DIR="$(dirname "$0")"

# Pre-seed VS Code machine settings (merge, creating the file if needed)
MACHINE_DIR="$HOME/.vscode-server/data/Machine"
mkdir -p "$MACHINE_DIR"
python3 - "$SETTINGS_DIR/vscode-settings.json" "$MACHINE_DIR/settings.json" <<'EOF'
import json, sys
src, dst = sys.argv[1], sys.argv[2]
try:
    with open(dst) as f:
        settings = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    settings = {}
with open(src) as f:
    settings.update(json.load(f))
with open(dst, 'w') as f:
    json.dump(settings, f, indent=4)
EOF

# Install the Dracula theme by unpacking its .vsix straight into the
# server's extensions dir (no `code` CLI exists at init time)
EXT_ID="dracula-theme.theme-dracula"
EXT_DIR="$HOME/.vscode-server/extensions"
if ! ls -d "$EXT_DIR/$EXT_ID"-* >/dev/null 2>&1; then
	URL="https://marketplace.visualstudio.com/_apis/public/gallery/publishers/dracula-theme/vsextensions/theme-dracula/latest/vspackage"
	VSIX="$(mktemp)"
	# Marketplace returns gzip-compressed content
	curl -sL "$URL" | gunzip > "$VSIX" 2>/dev/null || curl -sL -o "$VSIX" "$URL"
	python3 - "$VSIX" "$EXT_DIR" "$EXT_ID" <<'EOF'
import json, os, shutil, sys, tempfile, zipfile
vsix, ext_dir, ext_id = sys.argv[1], sys.argv[2], sys.argv[3]
tmp = tempfile.mkdtemp()
zipfile.ZipFile(vsix).extractall(tmp)
with open(f'{tmp}/extension/package.json') as f:
    version = json.load(f)['version']
os.makedirs(ext_dir, exist_ok=True)
shutil.move(f'{tmp}/extension', f'{ext_dir}/{ext_id}-{version}')
shutil.rmtree(tmp, ignore_errors=True)
EOF
	rm -f "$VSIX"
fi
