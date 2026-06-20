#!/usr/bin/env bash
# =============================================================================
# deploy-resin-chronicle.sh
#
# 1. Extracts the three fixed zips into the repo, replacing old theme files
# 2. Cleans up zip files and any other non-repo artifacts
# 3. Reinstalls all themes to Sublime Text, IntelliJ IDEA, and PyCharm
# 4. Commits and pushes everything to GitHub
#
# Run from anywhere — it always operates on the repo at:
#   /Users/steven/Projects/resin-chronicle
# =============================================================================

set -euo pipefail

# ─── colors ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

log()    { echo -e "${GREEN}✓${RESET}  $1"; }
warn()   { echo -e "${YELLOW}⚠${RESET}  $1"; }
error()  { echo -e "${RED}✗${RESET}  $1"; exit 1; }
header() { echo -e "\n${CYAN}── $1 ──${RESET}"; }

REPO="/Users/steven/Projects/resin-chronicle"

# ─── IDE install paths ────────────────────────────────────────────────────────
SUBLIME_USER="$HOME/Library/Application Support/Sublime Text/Packages/User"
JB_BASE="$HOME/Library/Application Support/JetBrains"
IDEA_COLORS="$JB_BASE/IntelliJIdea2026.1/colors"
PYCHARM_COLORS="$JB_BASE/PyCharm2026.1/colors"

# ─── preflight ────────────────────────────────────────────────────────────────
header "Preflight"

[[ -d "$REPO" ]] || error "Repo not found at $REPO"
log "Repo found"

# Confirm all three zips are present
for zip in \
  "resin-chronicle-fixed-sublime.zip" \
  "resin-chronicle-fixed-jetbrains.zip" \
  "resin-chronicle-fixed-vscode.zip"
do
  [[ -f "$REPO/$zip" ]] || error "Missing zip: $zip — make sure all three are in $REPO"
done
log "All three zips present"

# ─── step 1: replace sublime/ ────────────────────────────────────────────────
header "Replacing sublime/"

rm -rf "$REPO/sublime"
log "Removed old sublime/"

# The zip contains sublime/NeonResin/... — extract to a temp dir then move
TMPDIR_ST=$(mktemp -d)
unzip -q "$REPO/resin-chronicle-fixed-sublime.zip" -d "$TMPDIR_ST"

# Find the extracted sublime folder (could be nested under a wrapper folder)
EXTRACTED_ST=$(find "$TMPDIR_ST" -maxdepth 2 -type d -name "sublime" | head -1)
[[ -n "$EXTRACTED_ST" ]] || error "Could not find 'sublime' folder inside zip"

mv "$EXTRACTED_ST" "$REPO/sublime"
rm -rf "$TMPDIR_ST"
ST_COUNT=$(find "$REPO/sublime" -name "*.sublime-color-scheme" | wc -l | tr -d ' ')
log "sublime/ replaced — $ST_COUNT themes"

# ─── step 2: replace jetbrains/ ──────────────────────────────────────────────
header "Replacing jetbrains/"

rm -rf "$REPO/jetbrains"
log "Removed old jetbrains/"

TMPDIR_JB=$(mktemp -d)
unzip -q "$REPO/resin-chronicle-fixed-jetbrains.zip" -d "$TMPDIR_JB"

EXTRACTED_JB=$(find "$TMPDIR_JB" -maxdepth 2 -type d -name "jetbrains" | head -1)
[[ -n "$EXTRACTED_JB" ]] || error "Could not find 'jetbrains' folder inside zip"

mv "$EXTRACTED_JB" "$REPO/jetbrains"
rm -rf "$TMPDIR_JB"
JB_COUNT=$(find "$REPO/jetbrains" -name "*.icls" | wc -l | tr -d ' ')
log "jetbrains/ replaced — $JB_COUNT themes"

# ─── step 3: replace vscode/themes/ ──────────────────────────────────────────
header "Replacing vscode/themes/"

rm -rf "$REPO/vscode/themes"
log "Removed old vscode/themes/"

TMPDIR_VC=$(mktemp -d)
unzip -q "$REPO/resin-chronicle-fixed-vscode.zip" -d "$TMPDIR_VC"

EXTRACTED_VC=$(find "$TMPDIR_VC" -maxdepth 3 -type d -name "themes" | head -1)
[[ -n "$EXTRACTED_VC" ]] || error "Could not find 'themes' folder inside vscode zip"

mkdir -p "$REPO/vscode"
mv "$EXTRACTED_VC" "$REPO/vscode/themes"
rm -rf "$TMPDIR_VC"
VC_COUNT=$(find "$REPO/vscode/themes" -name "*color-theme.json" | wc -l | tr -d ' ')
log "vscode/themes/ replaced — $VC_COUNT themes"

# ─── step 4: clean up zips and any non-repo artifacts ────────────────────────
header "Cleaning up"

# Remove the zip files
rm -f \
  "$REPO/resin-chronicle-fixed-sublime.zip" \
  "$REPO/resin-chronicle-fixed-jetbrains.zip" \
  "$REPO/resin-chronicle-fixed-vscode.zip"
log "Zip files removed"

# Remove any stray macOS metadata
find "$REPO" -name ".DS_Store" -delete 2>/dev/null && log ".DS_Store files removed" || true
find "$REPO" -name "__MACOSX" -type d -exec rm -rf {} + 2>/dev/null || true

# Remove any other stray zips that shouldn't be in the repo
find "$REPO" -maxdepth 1 -name "*.zip" -delete 2>/dev/null || true

log "Cleanup done"

# ─── step 5: install to Sublime Text ─────────────────────────────────────────
header "Installing to Sublime Text"

mkdir -p "$SUBLIME_USER"
find "$REPO/sublime" -name "*.sublime-color-scheme" -exec cp {} "$SUBLIME_USER/" \;
INSTALLED_ST=$(find "$SUBLIME_USER" -name "*.sublime-color-scheme" | wc -l | tr -d ' ')
log "Sublime Text — $INSTALLED_ST themes installed to Packages/User"

# ─── step 6: install to JetBrains ────────────────────────────────────────────
header "Installing to JetBrains IDEs"

# IntelliJ IDEA
mkdir -p "$IDEA_COLORS"
find "$REPO/jetbrains" -name "*.icls" -exec cp {} "$IDEA_COLORS/" \;
INSTALLED_IDEA=$(find "$IDEA_COLORS" -name "*.icls" | wc -l | tr -d ' ')
log "IntelliJ IDEA — $INSTALLED_IDEA themes installed"

# PyCharm
mkdir -p "$PYCHARM_COLORS"
find "$REPO/jetbrains" -name "*.icls" -exec cp {} "$PYCHARM_COLORS/" \;
INSTALLED_PC=$(find "$PYCHARM_COLORS" -name "*.icls" | wc -l | tr -d ' ')
log "PyCharm — $INSTALLED_PC themes installed"

# Auto-detect any other JetBrains IDEs and install there too
OTHER_IDES=$(ls "$JB_BASE" | grep -vE "^(IntelliJIdea|PyCharm|Toolbox|Daemon|consentOptions|PrivacyPolicy|crl|acp|bl|PrivacyPolicy)" | grep -E "^[A-Z]" || true)

if [[ -n "$OTHER_IDES" ]]; then
  while IFS= read -r ide_dir; do
    colors_path="$JB_BASE/$ide_dir/colors"
    if [[ -d "$JB_BASE/$ide_dir" ]]; then
      mkdir -p "$colors_path"
      find "$REPO/jetbrains" -name "*.icls" -exec cp {} "$colors_path/" \;
      INSTALLED_OTHER=$(find "$colors_path" -name "*.icls" | wc -l | tr -d ' ')
      log "$ide_dir — $INSTALLED_OTHER themes installed"
    fi
  done <<< "$OTHER_IDES"
fi

# ─── step 7: VS Code note ─────────────────────────────────────────────────────
header "VS Code"

# VS Code themes are live via --extensionDevelopmentPath so no copy needed.
# The repo folder IS the extension — saving files here updates VS Code instantly.
log "VS Code reads directly from $REPO/vscode — already updated"
warn "If VS Code Extension Dev window is closed, relaunch it with:"
warn "  code --extensionDevelopmentPath=$REPO/vscode"

# ─── step 8: git commit and push ─────────────────────────────────────────────
header "Git commit and push"

cd "$REPO"

# Make sure we're on main
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" != "main" ]]; then
  warn "Current branch is '$CURRENT_BRANCH', not 'main'. Switching to main."
  git checkout main
fi

git add -A
git status --short

# Only commit if there are staged changes
if git diff --cached --quiet; then
  warn "Nothing to commit — repo is already up to date"
else
  git commit -m "fix: selection visibility and caret contrast across all 35 themes

- Selection background was matching or exceeding foreground brightness in
  33 of 35 themes, making highlighted text invisible
- Caret was blending into selection (as low as 1.01:1) in the same themes
- Fixed by alpha-blending each theme's selection hue at 20-35% onto the
  background, preserving the theme's color identity while restoring legibility
- Worst case resolved: Neon Resin Mono selection contrast 1.01:1 → 5.10:1
- Caret contrast against selection now >= 3.0:1 across all themes
- All three IDE formats regenerated from fixed Sublime source"

  git push origin main
  log "Pushed to github.com/CyberSteveon/resin-chronicle"
fi

# ─── summary ──────────────────────────────────────────────────────────────────
header "Done"

echo ""
echo "  Sublime Text : $ST_COUNT themes → Packages/User"
echo "  IntelliJ IDEA: $JB_COUNT themes → colors/"
echo "  PyCharm      : $JB_COUNT themes → colors/"
echo "  VS Code      : $VC_COUNT themes → live via extension dev path"
echo "  GitHub       : pushed to main ✓"
echo ""
echo -e "  ${YELLOW}Restart IDEA and PyCharm${RESET} if they were open during install."
echo -e "  Themes appear under ${CYAN}Settings → Editor → Color Scheme${RESET}."
echo ""
