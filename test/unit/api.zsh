# The api backend: Anthropic Messages API through curl.

ok_response='{"content":[{"type":"text","text":"ls -la"}],"stop_reason":"end_turn"}'

test_sends_key_and_json_body() {
  export ANTHROPIC_API_KEY=sk-test STUB_CURL_OUT=$ok_response
  run zsh_ai_generate 'say "hi" & bye'
  assert_eq 0 "$RC" "$ERR"
  assert_eq 'ls -la' "$OUT"

  local headers=$(curl_headers)
  assert_contains "$headers" 'x-api-key: sk-test'
  assert_contains "$headers" 'anthropic-version: 2023-06-01'
  assert_contains "$headers" 'content-type: application/json'

  local body=$(curl_body)
  assert_eq 'say "hi" & bye' "$(print -r -- $body | jq -r '.messages[0].content')"
  assert_eq claude-sonnet-5 "$(print -r -- $body | jq -r .model)"
  assert_eq 512 "$(print -r -- $body | jq -r .max_tokens)"
  assert_eq low "$(print -r -- $body | jq -r .output_config.effort)"
  assert_eq disabled "$(print -r -- $body | jq -r .thinking.type)"
  assert_contains "$(print -r -- $body | jq -r .system)" "You translate"
}

test_options_reach_the_body() {
  export ANTHROPIC_API_KEY=sk-test STUB_CURL_OUT=$ok_response
  ZSH_AI_MODEL=claude-opus-5 ZSH_AI_THINKING=adaptive ZSH_AI_MAX_TOKENS=2048 ZSH_AI_EFFORT=high
  run zsh_ai_generate list files
  local body=$(curl_body)
  assert_eq claude-opus-5 "$(print -r -- $body | jq -r .model)"
  assert_eq adaptive "$(print -r -- $body | jq -r .thinking.type)"
  assert_eq 2048 "$(print -r -- $body | jq -r .max_tokens)"
  assert_eq high "$(print -r -- $body | jq -r .output_config.effort)"
}

test_auth_token_uses_bearer() {
  export ANTHROPIC_AUTH_TOKEN=tok STUB_CURL_OUT=$ok_response
  run zsh_ai_generate list files
  assert_eq 0 "$RC" "$ERR"
  local headers=$(curl_headers)
  assert_contains "$headers" 'Authorization: Bearer tok'
  assert_contains "$headers" 'anthropic-beta: oauth-2025-04-20'
  assert_not_contains "$headers" 'x-api-key'
}

test_joins_text_blocks() {
  export ANTHROPIC_API_KEY=sk-test
  export STUB_CURL_OUT='{"content":[{"type":"thinking","thinking":"hmm"},{"type":"text","text":"ls "},{"type":"text","text":"-la"}]}'
  assert_eq 'ls -la' "$(zsh_ai_generate list files)"
}

test_api_error_message_is_shown() {
  export ANTHROPIC_API_KEY=sk-test
  export STUB_CURL_OUT='{"type":"error","error":{"type":"authentication_error","message":"invalid x-api-key"}}'
  run zsh_ai_generate list files
  assert_eq 1 "$RC"
  assert_contains "$ERR" "invalid x-api-key"
}

test_refusal_is_reported() {
  export ANTHROPIC_API_KEY=sk-test
  export STUB_CURL_OUT='{"content":[],"stop_reason":"refusal"}'
  run zsh_ai_generate list files
  assert_eq 1 "$RC"
  assert_contains "$ERR" "declined"
}

test_network_failure_is_reported() {
  export ANTHROPIC_API_KEY=sk-test STUB_CURL_EXIT=7
  run zsh_ai_generate list files
  assert_eq 1 "$RC"
  assert_contains "$ERR" "request failed"
}

test_debug_file_gets_raw_response() {
  export ANTHROPIC_API_KEY=sk-test STUB_CURL_OUT=$ok_response
  ZSH_AI_DEBUG="$TEST_TMP/debug.json"
  run zsh_ai_generate list files
  assert_eq "$ok_response" "$(<$ZSH_AI_DEBUG)"
}
