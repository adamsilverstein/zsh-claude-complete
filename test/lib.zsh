#!/usr/bin/env zsh
# Runs one test function in a clean shell: zsh test/lib.zsh <file> <test_name>
# Each test gets a fresh temp dir, stubbed claude and curl first on PATH, no
# Anthropic credentials, and the plugin sourced with no key binding.

root="${ZSH_AI_TEST_ROOT:-${0:A:h:h}}"
TEST_TMP=$(mktemp -d -t zsh-ai-test.XXXXXX)
trap 'rm -rf "$TEST_TMP"' EXIT

export STUB_LOG="$TEST_TMP/calls.log"
: > "$STUB_LOG"
unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ZSH_AI_BACKEND ZSH_AI_DEBUG
unset STUB_CLAUDE_LOGGED_IN STUB_CLAUDE_OUT STUB_CLAUDE_EXIT STUB_CURL_OUT STUB_CURL_EXIT
path=( "$root/test/stubs" $path )

ZSH_AI_KEY="" source "$root/zsh-claude-complete.plugin.zsh"

fail() {
  print -u2 -r -- "$*"
  exit 1
}

# assert_eq <expected> <actual> [message]
assert_eq() {
  [[ "$1" == "$2" ]] || fail "${3:-values differ}"$'\n'"  expected: $1"$'\n'"  actual:   $2"
}

# assert_contains <haystack> <needle> [message]
assert_contains() {
  [[ "$1" == *"$2"* ]] || fail "${3:-missing text}"$'\n'"  looking for: $2"$'\n'"  in: $1"
}

# assert_not_contains <haystack> <needle> [message]
assert_not_contains() {
  [[ "$1" != *"$2"* ]] || fail "${3:-unexpected text}"$'\n'"  found: $2"$'\n'"  in: $1"
}

# Runs a command, capturing stdout in $OUT, stderr in $ERR and status in $RC.
run() {
  local errfile="$TEST_TMP/stderr"
  OUT=$("$@" 2>"$errfile")
  RC=$?
  ERR=$(<"$errfile")
}

# The JSON body sent by the last stubbed curl call.
curl_body() {
  print -r -- "$(<"$STUB_LOG.body")"
}

# Every header passed to the last stubbed curl call, one per line.
curl_headers() {
  local -a args
  args=( "${(@f)$(<"$STUB_LOG")}" )
  local i
  for (( i = 1; i < $#args; i++ )); do
    [[ "${args[i]}" == -H ]] && print -r -- "${args[i+1]}"
  done
}

source "$1"
"$2"
