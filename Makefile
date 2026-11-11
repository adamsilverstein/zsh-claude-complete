.PHONY: test test-unit test-install test-live lint install

# Offline checks: no Claude login, API key, or network needed.
test: lint test-unit test-install

lint:
	zsh -n zsh-claude-complete.plugin.zsh test/*.zsh test/unit/*.zsh test/live/*.zsh
	sh -n install.sh test/stubs/claude test/stubs/curl

test-unit:
	zsh test/run.zsh

test-install:
	zsh test/install.zsh

# Calls Claude for real: needs Claude Code signed in or ANTHROPIC_API_KEY.
test-live:
	zsh test/live/login-guidance.zsh
	zsh test/live/smoke.zsh

# Loads this clone from ~/.zshrc.
install:
	./install.sh
