#!/usr/bin/env zsh
# Smoke test: source the plugin and generate a command without zle.
# Usage: zsh test/live/smoke.zsh [prompt]
set -e
here="${0:A:h}"
ZSH_AI_KEY="" source "$here/../../zsh-claude-complete.plugin.zsh"

prompt="${1:-list the five largest files in the current directory}"
print -r -- "backend: $(_zsh_ai_backend)  model: $ZSH_AI_MODEL"
print -r -- "prompt:  $prompt"
cmd=$(zsh_ai_generate "$prompt")
print -r -- "command: $cmd"

[[ -n "$cmd" ]] || { print "FAIL: empty command" >&2; exit 1; }
[[ "$cmd" != *'```'* ]] || { print "FAIL: code fence leaked" >&2; exit 1; }
print "OK"
