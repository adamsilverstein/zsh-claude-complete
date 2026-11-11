#!/bin/sh
# Installs zsh-claude-complete and loads it from ~/.zshrc.
#
#   curl -fsSL https://raw.githubusercontent.com/adamsilverstein/zsh-claude-complete/main/install.sh | sh
#
# Run it again to update. From a clone, ./install.sh loads that clone in place.
# ./install.sh --uninstall removes the line it added to ~/.zshrc.
#
# Environment:
#   ZSH_AI_INSTALL_DIR  Where to clone. Default: the Oh My Zsh custom plugins
#                       directory when Oh My Zsh is installed, else
#                       ~/.zsh/zsh-claude-complete
#   ZSH_AI_REPO         Git URL to clone. Default: the GitHub repo
#   ZDOTDIR             Honored when locating .zshrc
set -eu

repo="${ZSH_AI_REPO:-https://github.com/adamsilverstein/zsh-claude-complete.git}"
zshrc="${ZDOTDIR:-$HOME}/.zshrc"
marker="# zsh-claude-complete"

say() { printf '%s\n' "$*"; }
die() { printf 'zsh-claude-complete: %s\n' "$*" >&2; exit 1; }

remove_from_zshrc() {
  [ -f "$zshrc" ] || return 0
  tmp="$zshrc.zsh-claude-complete.tmp"
  # Drop the marker comment and the line after it.
  awk -v m="$marker" '$0 == m { skip = 1; next } skip { skip = 0; next } { print }' "$zshrc" > "$tmp"
  cat "$tmp" > "$zshrc"
  rm -f "$tmp"
}

if [ "${1:-}" = --uninstall ]; then
  remove_from_zshrc
  say "Removed zsh-claude-complete from $zshrc. Delete the plugin directory yourself if you no longer want it."
  exit 0
fi

command -v zsh >/dev/null 2>&1 || die "zsh is not installed"

# Running from a clone: load that clone instead of cloning again.
here=""
case "$0" in
  */install.sh) here=$(cd "$(dirname "$0")" && pwd) ;;
esac

omz_custom="${ZSH_CUSTOM:-${ZSH:-$HOME/.oh-my-zsh}/custom}"
omz=""
if [ -n "$here" ] && [ -f "$here/zsh-claude-complete.plugin.zsh" ] && [ -z "${ZSH_AI_INSTALL_DIR:-}" ]; then
  dir="$here"
  say "Using the clone at $dir"
else
  if [ -n "${ZSH_AI_INSTALL_DIR:-}" ]; then
    dir="$ZSH_AI_INSTALL_DIR"
  elif [ -d "$omz_custom/plugins" ]; then
    dir="$omz_custom/plugins/zsh-claude-complete"
    omz=1
  else
    dir="$HOME/.zsh/zsh-claude-complete"
  fi
  command -v git >/dev/null 2>&1 || die "git is not installed"
  if [ -d "$dir/.git" ]; then
    say "Updating $dir"
    git -C "$dir" pull --ff-only --quiet
  else
    say "Cloning into $dir"
    mkdir -p "$(dirname "$dir")"
    git clone --quiet --depth 1 "$repo" "$dir"
  fi
fi

if [ -n "$omz" ]; then
  say ""
  say "Installed as an Oh My Zsh plugin. Add it to the plugins list in $zshrc:"
  say "  plugins=(... zsh-claude-complete)"
else
  remove_from_zshrc
  touch "$zshrc"
  printf '%s\nsource %s\n' "$marker" "$dir/zsh-claude-complete.plugin.zsh" >> "$zshrc"
  say "Added zsh-claude-complete to $zshrc"
fi

say ""
if command -v claude >/dev/null 2>&1; then
  say "Backend: your Claude account through Claude Code. Run zsh_ai_login if you are not signed in."
elif command -v curl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  say "Backend: the Anthropic API. Export ANTHROPIC_API_KEY, or install Claude Code to use your Claude account."
else
  say "Next: install Claude Code (https://claude.com/claude-code), or curl and jq plus an ANTHROPIC_API_KEY."
fi
say "Open a new terminal, then try:  AI list the five largest files here <TAB>"
