# Backend selection and plugin loading.

test_defaults_to_cli_without_credentials() {
  assert_eq cli "$(_zsh_ai_backend)"
}

test_api_key_selects_api() {
  ANTHROPIC_API_KEY=sk-test
  assert_eq api "$(_zsh_ai_backend)"
}

test_auth_token_selects_api() {
  ANTHROPIC_AUTH_TOKEN=tok
  assert_eq api "$(_zsh_ai_backend)"
}

test_explicit_backend_wins_over_key() {
  ANTHROPIC_API_KEY=sk-test
  ZSH_AI_BACKEND=cli
  assert_eq cli "$(_zsh_ai_backend)"
}

test_unknown_backend_is_an_error() {
  ZSH_AI_BACKEND=bogus
  run zsh_ai_generate "list files"
  assert_eq 1 "$RC"
  assert_contains "$ERR" "unknown backend 'bogus'"
}

test_empty_prompt_is_an_error() {
  run zsh_ai_generate
  assert_eq 1 "$RC"
  assert_contains "$ERR" "empty prompt"
}

test_prefix_command_is_defined() {
  (( $+functions[AI] )) || fail "AI function not defined"
}

test_custom_prefix_defines_that_command() {
  ZSH_AI_PREFIX=ask ZSH_AI_KEY="" source "$root/zsh-claude-complete.plugin.zsh"
  (( $+functions[ask] )) || fail "ask function not defined"
}

test_defaults() {
  assert_eq claude-sonnet-5 "$ZSH_AI_MODEL"
  assert_eq low "$ZSH_AI_EFFORT"
  assert_eq disabled "$ZSH_AI_THINKING"
  assert_eq 512 "$ZSH_AI_MAX_TOKENS"
}
