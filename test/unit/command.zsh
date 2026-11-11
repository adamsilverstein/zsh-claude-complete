# The Enter fallback: running "AI <request>" as a command.

test_pushes_generated_command_to_next_prompt() {
  export STUB_CLAUDE_LOGGED_IN=true STUB_CLAUDE_OUT='du -sh *'
  AI show folder sizes </dev/null
  assert_eq 0 $?
  local pushed
  read -z pushed
  assert_eq 'du -sh *' "$pushed"
}

test_signed_out_without_terminal_shows_hint() {
  export STUB_CLAUDE_LOGGED_IN=false
  run AI show folder sizes </dev/null
  assert_eq 1 "$RC"
  assert_contains "$OUT" "not signed in"
  assert_contains "$ERR" "zsh_ai_login"
}
