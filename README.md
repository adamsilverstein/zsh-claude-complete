# zsh-claude-complete

Type a plain-English request, press TAB, get a shell command written by Claude.

```
$ AI find files over 100MB modified this week<TAB>
$ find . -type f -size +100M -mtime -7
```

The buffer is replaced with the generated command. Nothing runs until you press Enter, so you can edit it first.

Inspired by [tott/zsh-ai-complete](https://github.com/tott/zsh-ai-complete), which targets OpenAI-compatible APIs. This plugin talks to Claude instead, either through your Claude account via Claude Code or through the Anthropic API.

## Requirements

- zsh
- One of:
  - **Claude account** (no API key): the `claude` CLI from [Claude Code](https://claude.com/claude-code). The plugin walks you through the browser sign-in.
  - **Anthropic API**: `curl`, `jq`, and `ANTHROPIC_API_KEY` set (an `ANTHROPIC_AUTH_TOKEN` OAuth bearer token also works)

## Install

Clone and source the plugin from `.zshrc`:

```zsh
git clone https://github.com/adamsilverstein/zsh-claude-complete ~/.zsh/zsh-claude-complete
echo 'source ~/.zsh/zsh-claude-complete/zsh-claude-complete.plugin.zsh' >> ~/.zshrc
```

Or with a plugin manager, point it at the repo and it will pick up `zsh-claude-complete.plugin.zsh`.

Reload the shell.

### Sign in with your Claude account

No API key is needed. If Claude Code is not signed in yet, the first request tells you so. Run:

```zsh
zsh_ai_login
```

This opens the Claude sign-in page in your browser. Sign in with your Claude account, return to the terminal, and the plugin confirms which account it is using. Pressing Enter on an `AI ...` line while signed out offers to start the same sign-in for you.

The account backend always ignores `ANTHROPIC_API_KEY`, so it uses your Claude subscription even when a key is exported.

### Or use an API key

If `ANTHROPIC_API_KEY` is set, the plugin uses the Anthropic API directly instead. This is the faster path and bills API usage:

```zsh
export ANTHROPIC_API_KEY=sk-ant-...
```

## Usage

```
AI <what you want> <TAB>
```

TAB behaves normally for any buffer that does not start with `AI `.

Pressing Enter instead of TAB also works. `AI` is defined as a command, so the generated line is pushed onto the next prompt for you to edit or run:

```
$ AI find files over 100MB modified this week
$ find . -type f -size +100M -mtime -7█
```

The generator is also a plain function, useful in scripts or to preview without zle:

```zsh
zsh_ai_generate "count lines in all markdown files under docs"
```

## Configuration

All options are environment variables. Set them before or after sourcing.

| Variable | Default | Meaning |
| --- | --- | --- |
| `ZSH_AI_BACKEND` | `api` if `ANTHROPIC_API_KEY` or `ANTHROPIC_AUTH_TOKEN` is set, else `cli` | `cli` (your Claude account via `claude -p`) or `api` (Anthropic Messages API via curl) |
| `ZSH_AI_MODEL` | `claude-sonnet-5` | Model id passed to either backend |
| `ZSH_AI_EFFORT` | `low` | Effort level passed to either backend. Low keeps TAB snappy |
| `ZSH_AI_THINKING` | `disabled` | Thinking mode for the api backend, `disabled` or `adaptive` |
| `ZSH_AI_MAX_TOKENS` | `512` | Output cap, api backend only |
| `ZSH_AI_PREFIX` | `AI` | Trigger word at the start of the buffer |
| `ZSH_AI_KEY` | `^I` (TAB) | Key to bind. Set to an empty string to bind nothing and call `bindkey` yourself |
| `ZSH_AI_DEBUG` | unset | File path. When set, the last raw response is written there |

Examples:

```zsh
# Smarter but slower
export ZSH_AI_MODEL=claude-opus-5
export ZSH_AI_THINKING=adaptive

# Cheapest and fastest
export ZSH_AI_MODEL=claude-haiku-4-5

# Keep TAB for normal completion, use Ctrl-X Ctrl-A instead
export ZSH_AI_KEY='^X^A'

# Use your Claude account even when an API key is present
export ZSH_AI_BACKEND=cli
```

## Speed

The defaults are tuned for latency: Sonnet, thinking off, low effort, short output cap. The `api` backend is the faster of the two. The `cli` backend pays Claude Code startup on every request, but it runs with settings, hooks, plugins, and MCP servers skipped, which brings a typical request down to roughly two to three seconds instead of six or more. If you have an API key, set it and the plugin will prefer the API automatically.

## How it works

The plugin sends a short system prompt with your OS, zsh version, and working directory, plus your request. The reply is stripped of code fences and blank lines, multi-line output is joined with `; `, and the result replaces the buffer.

With the `api` backend the request body is built with `jq`, so quotes and newlines in your request are always valid JSON. With the `cli` backend it first checks `claude auth status` (about a tenth of a second), then calls `claude -p` with no tools, no settings, no MCP servers, and no session persistence, so nothing is executed and nothing is saved. If you are signed out it stops with a pointer to `zsh_ai_login` instead of making a request.

## Testing

`test/smoke.zsh` sources the plugin and generates a command for a fixed prompt on whichever backend is configured. `test/login-guidance.zsh` points Claude Code at an empty config directory to check the signed-out message without touching your real login:

```zsh
zsh test/smoke.zsh
ZSH_AI_BACKEND=cli zsh test/smoke.zsh
zsh test/login-guidance.zsh
```

## Credits

Inspired by tott's zsh-ai-complete, which introduced the "type a request, press TAB" idea for OpenAI-compatible APIs: https://github.com/tott/zsh-ai-complete. This is a separate implementation targeting Claude.

## License

MIT
