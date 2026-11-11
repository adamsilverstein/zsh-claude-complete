# The cli backend: Claude Code headless mode.

test_passes_prompt_and_fast_flags() {
  export STUB_CLAUDE_LOGGED_IN=true STUB_CLAUDE_OUT='ls'
  ZSH_AI_MODEL=claude-haiku-4-5 ZSH_AI_EFFORT=medium
  run zsh_ai_generate 'say "hi"'
  assert_eq 0 "$RC" "$ERR"
  local call=$(grep -- '\[-p\]' "$STUB_LOG")
  assert_contains "$call" '[-p] [say "hi"]'
  assert_contains "$call" '[--model] [claude-haiku-4-5]'
  assert_contains "$call" '[--effort] [medium]'
  assert_contains "$call" '[--tools] []'
  assert_contains "$call" '[--setting-sources] []'
  assert_contains "$call" '[--strict-mcp-config]'
  assert_contains "$call" '[--no-session-persistence]'
  assert_contains "$call" '[--system-prompt] [You translate'
}

test_strips_api_credentials_from_claude() {
  export STUB_CLAUDE_LOGGED_IN=true STUB_CLAUDE_OUT='ls'
  export ANTHROPIC_API_KEY=sk-secret ANTHROPIC_AUTH_TOKEN=tok-secret
  ZSH_AI_BACKEND=cli
  run zsh_ai_generate list files
  assert_eq 0 "$RC" "$ERR"
  assert_not_contains "$(<$STUB_LOG)" sk-secret
  assert_not_contains "$(<$STUB_LOG)" tok-secret
}

test_signed_out_points_to_login() {
  export STUB_CLAUDE_LOGGED_IN=false
  run zsh_ai_generate list files
  assert_eq 1 "$RC"
  assert_contains "$ERR" "zsh_ai_login"
  assert_not_contains "$(<$STUB_LOG)" '[-p]' "should not call claude -p when signed out"
}

test_missing_claude_points_to_install() {
  path=( /usr/bin /bin )
  rehash
  run _zsh_ai_generate_cli "list files" "system"
  assert_eq 1 "$RC"
  assert_contains "$ERR" "claude CLI not found"
}

test_claude_failure_is_reported() {
  export STUB_CLAUDE_LOGGED_IN=true STUB_CLAUDE_EXIT=1
  run zsh_ai_generate list files
  assert_eq 1 "$RC"
  assert_contains "$ERR" "claude -p failed"
}

test_debug_file_gets_raw_reply() {
  export STUB_CLAUDE_LOGGED_IN=true STUB_CLAUDE_OUT=$'```\nls\n```'
  ZSH_AI_DEBUG="$TEST_TMP/debug.txt"
  run zsh_ai_generate list files
  assert_contains "$(<$ZSH_AI_DEBUG)" '```'
}

test_login_when_already_signed_in() {
  export STUB_CLAUDE_LOGGED_IN=true
  run zsh_ai_login
  assert_eq 0 "$RC"
  assert_contains "$OUT" "already signed in"
  assert_not_contains "$(<$STUB_LOG)" '[auth] [login]'
}

test_login_failure_is_reported() {
  export STUB_CLAUDE_LOGGED_IN=false STUB_CLAUDE_LOGIN_EXIT=1
  run zsh_ai_login
  assert_eq 1 "$RC"
  assert_contains "$(<$STUB_LOG)" '[auth] [login]'
  assert_contains "$ERR" "sign-in did not complete"
}
