# zsh-claude-complete

Type a plain-English request, press TAB, get a shell command written by Claude.

```
$ AI find files over 100MB modified this week<TAB>
$ find . -type f -size +100M -mtime -7
```

The buffer is replaced with the generated command. Nothing runs until you press Enter, so you can edit it first.

Inspired by [tott/zsh-ai-complete](https://github.com/tott/zsh-ai-complete), which targets OpenAI-compatible APIs. This plugin talks to Claude instead, either through the Anthropic API or through Claude Code.

## Requirements

- zsh
- One of:
  - **Anthropic API**: `curl`, `jq`, and `ANTHROPIC_API_KEY` set (an `ANTHROPIC_AUTH_TOKEN` OAuth bearer token also works)
  - **Claude Code**: the `claude` CLI installed and logged in

## Install

Clone and source the plugin from `.zshrc`:

```zsh
git clone https://github.com/adamsilverstein/zsh-claude-complete ~/.zsh/zsh-claude-complete
echo 'source ~/.zsh/zsh-claude-complete/zsh-claude-complete.plugin.zsh' >> ~/.zshrc
```

Or with a plugin manager, point it at the repo and it will pick up `zsh-claude-complete.plugin.zsh`.

Set your key if you want the API backend:

```zsh
export ANTHROPIC_API_KEY=sk-ant-...
```

Reload the shell.

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
| `ZSH_AI_BACKEND` | `api` if `ANTHROPIC_API_KEY` or `ANTHROPIC_AUTH_TOKEN` is set, else `cli` | `api` (Anthropic Messages API via curl) or `cli` (`claude -p`) |
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

# Force Claude Code even when an API key is present
export ZSH_AI_BACKEND=cli
```

## Speed

The defaults are tuned for latency: Sonnet, thinking off, low effort, short output cap. The `api` backend is the faster of the two because the `cli` backend pays several seconds of Claude Code startup on every request. If you have an API key, set it and the plugin will prefer the API automatically.

## How it works

The plugin sends a short system prompt with your OS, zsh version, and working directory, plus your request. The reply is stripped of code fences and blank lines, multi-line output is joined with `; `, and the result replaces the buffer.

With the `api` backend the request body is built with `jq`, so quotes and newlines in your request are always valid JSON. With the `cli` backend it calls `claude -p` with no tools and no session persistence, so nothing is executed and nothing is saved.

## Testing

`test/smoke.zsh` sources the plugin and generates a command for a fixed prompt on whichever backend is configured:

```zsh
zsh test/smoke.zsh
ZSH_AI_BACKEND=cli zsh test/smoke.zsh
```

## License

MIT
