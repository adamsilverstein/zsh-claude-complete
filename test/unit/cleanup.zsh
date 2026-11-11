# Turning the model's reply into a single editable command line.

test_plain_command_passes_through() {
  export STUB_CLAUDE_LOGGED_IN=true STUB_CLAUDE_OUT='ls -la'
  assert_eq 'ls -la' "$(zsh_ai_generate list files)"
}

test_code_fences_are_stripped() {
  export STUB_CLAUDE_LOGGED_IN=true STUB_CLAUDE_OUT=$'```bash\nls -la\n```'
  assert_eq 'ls -la' "$(zsh_ai_generate list files)"
}

test_multiple_lines_are_joined() {
  export STUB_CLAUDE_LOGGED_IN=true STUB_CLAUDE_OUT=$'cd /tmp\n\nls'
  assert_eq 'cd /tmp; ls' "$(zsh_ai_generate go to tmp and list)"
}

test_surrounding_whitespace_is_trimmed() {
  export STUB_CLAUDE_LOGGED_IN=true STUB_CLAUDE_OUT=$'  \n pwd \n'
  assert_eq 'pwd' "$(zsh_ai_generate where am i)"
}

test_blank_reply_is_an_error() {
  export STUB_CLAUDE_LOGGED_IN=true STUB_CLAUDE_OUT=$'```\n```'
  run zsh_ai_generate list files
  assert_eq 1 "$RC"
  assert_contains "$ERR" "no command generated"
}
