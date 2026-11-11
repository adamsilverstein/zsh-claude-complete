#!/usr/bin/env zsh
# Verifies the guidance shown when Claude Code is not logged in.
# An empty CLAUDE_CONFIG_DIR makes the claude CLI report "not logged in"
# without touching the real login, so this runs safely anywhere.
# Usage: zsh test/live/login-guidance.zsh
here="${0:A:h}"
ZSH_AI_KEY="" source "$here/../../zsh-claude-complete.plugin.zsh"

tmp=$(mktemp -d -t zsh-ai-login.XXXXXX)
trap 'rm -rf "$tmp"' EXIT

export CLAUDE_CONFIG_DIR="$tmp"
unset ZSH_AI_BACKEND ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN

# Without Claude Code installed, the plugin stops at "claude CLI not found"
# before the login check, so stand in a signed-out claude.
if (( ! $+commands[claude] )); then
  mkdir "$tmp/bin"
  print -r -- $'#!/bin/sh\n[ "$1 $2" = "auth status" ] && echo \'{"loggedIn": false}\'\nexit 1' > "$tmp/bin/claude"
  chmod +x "$tmp/bin/claude"
  path=("$tmp/bin" $path)
  rehash
fi

print -r -- "backend: $(_zsh_ai_backend)"
[[ "$(_zsh_ai_backend)" == cli ]] || { print "FAIL: expected cli backend when no key is set" >&2; exit 1; }

if _zsh_ai_logged_in; then
  print "FAIL: _zsh_ai_logged_in returned true for an empty config dir" >&2; exit 1
fi

out=$(zsh_ai_generate "list files" 2>&1)
rc=$?
print -r -- "output:  $out"
(( rc != 0 )) || { print "FAIL: expected non-zero exit when not logged in" >&2; exit 1; }
[[ "$out" == *"zsh_ai_login"* ]] || { print "FAIL: guidance should mention zsh_ai_login" >&2; exit 1; }
[[ "$out" == *"browser"* ]] || { print "FAIL: guidance should mention the browser login" >&2; exit 1; }
print "OK"
