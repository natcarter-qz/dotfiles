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

# Install extensions by unpacking their .vsix straight into the server's
# extensions dir (no `code` CLI exists at init time). Third arg is the
# targetPlatform for platform-specific extensions.
EXT_DIR="$HOME/.vscode-server/extensions"
install_extension() {
	PUBLISHER="$1" NAME="$2" PLATFORM="$3"
	ls -d "$EXT_DIR/$PUBLISHER.$NAME"-* >/dev/null 2>&1 && return
	URL="https://marketplace.visualstudio.com/_apis/public/gallery/publishers/$PUBLISHER/vsextensions/$NAME/latest/vspackage${PLATFORM:+?targetPlatform=$PLATFORM}"
	VSIX="$(mktemp)"
	# Marketplace returns gzip-compressed content
	curl -sL "$URL" | gunzip > "$VSIX" 2>/dev/null || curl -sL -o "$VSIX" "$URL"
	python3 - "$VSIX" "$EXT_DIR" "$PUBLISHER.$NAME" "$PLATFORM" <<'EOF'
import json, os, shutil, sys, tempfile, zipfile
vsix, ext_dir, ext_id, platform = sys.argv[1:5]
tmp = tempfile.mkdtemp()
zipfile.ZipFile(vsix).extractall(tmp)
with open(f'{tmp}/extension/package.json') as f:
    version = json.load(f)['version']
suffix = f'-{platform}' if platform else ''
os.makedirs(ext_dir, exist_ok=True)
shutil.move(f'{tmp}/extension', f'{ext_dir}/{ext_id}-{version}{suffix}')
shutil.rmtree(tmp, ignore_errors=True)
EOF
	rm -f "$VSIX"
}

install_extension drewxs tokyo-night-dark
install_extension anthropic claude-code

# Prebuild clones can be hours stale — bring the workspace repo current,
# using the repo's own `git up` alias when it defines one
if [ -n "$GITPOD_REPO_ROOT" ]; then
	(
		cd "$GITPOD_REPO_ROOT" || exit
		if git config --get alias.up >/dev/null; then
			git up
		else
			git pull --prune
		fi
	) || true
fi

# Extend workspace timeout (Flex `gitpod` CLI, falling back to classic `gp`)
gitpod timeout set 8h 2>/dev/null || gp timeout set 8h || true

# Interactive-shell tweaks, appended to zshrc once
if ! grep -q git-cram "$HOME/.zshrc" 2>/dev/null; then
	cat >> "$HOME/.zshrc" <<'EOF'

# --- from dotfiles ---
alias git-cram='git add . && git commit --amend --no-verify && git push --force-with-lease --no-verify'
(( $+functions[_zsh_autosuggest_disable] )) && _zsh_autosuggest_disable
EOF
fi
