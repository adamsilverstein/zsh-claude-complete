#!/usr/bin/env zsh
# Exercises install.sh against a throwaway HOME and a local clone of this repo.
# Usage: zsh test/install.zsh
emulate -L zsh
root="${0:A:h:h}"
tmp=$(mktemp -d -t zsh-ai-install.XXXXXX)
trap 'rm -rf "$tmp"' EXIT

fail() { print -u2 -r -- "FAIL: $*"; exit 1; }

# A bare repo stands in for GitHub; it carries the working tree's files.
src="$tmp/src"
git clone --quiet "$root" "$src"
rsync -a --exclude .git "$root"/ "$src"/ 2>/dev/null || cp -R "$root"/. "$src"/
git -C "$src" add -A && git -C "$src" -c user.name=t -c user.email=t@t commit --quiet -m wip --allow-empty

export HOME="$tmp/home" ZSH_AI_REPO="file://$src"
unset ZDOTDIR ZSH ZSH_CUSTOM ZSH_AI_INSTALL_DIR
mkdir -p "$HOME"
print 'export EXISTING=1' > "$HOME/.zshrc"

# Piped install, the way the README's one-liner runs it.
sh < "$root/install.sh" >/dev/null || fail "install exited non-zero"
dir="$HOME/.zsh/zsh-claude-complete"
[[ -f "$dir/zsh-claude-complete.plugin.zsh" ]] || fail "plugin not cloned to $dir"
grep -qx "source $dir/zsh-claude-complete.plugin.zsh" "$HOME/.zshrc" || fail "source line missing"
grep -qx 'export EXISTING=1' "$HOME/.zshrc" || fail "existing .zshrc content lost"

# Running again updates without adding a second source line.
sh < "$root/install.sh" >/dev/null || fail "second install exited non-zero"
(( $(grep -c "zsh-claude-complete.plugin.zsh" "$HOME/.zshrc") == 1 )) || fail "source line duplicated"

# The installed plugin loads in an interactive shell and defines its commands.
out=$(zsh -i -c 'print -r -- ${+functions[zsh_ai_generate]} ${+functions[AI]} $widgets[_zsh_ai_widget]' 2>&1)
[[ "$out" == *"1 1 user:_zsh_ai_widget"* ]] || fail "plugin did not load: $out"

# Uninstall removes only what install added.
sh "$root/install.sh" --uninstall >/dev/null || fail "uninstall exited non-zero"
! grep -q "zsh-claude-complete" "$HOME/.zshrc" || fail "source line still present"
grep -qx 'export EXISTING=1' "$HOME/.zshrc" || fail "uninstall removed other lines"

# With Oh My Zsh present it installs as a plugin and leaves .zshrc alone.
mkdir -p "$HOME/.oh-my-zsh/custom/plugins"
sh < "$root/install.sh" >/dev/null || fail "omz install exited non-zero"
[[ -f "$HOME/.oh-my-zsh/custom/plugins/zsh-claude-complete/zsh-claude-complete.plugin.zsh" ]] || fail "not installed as an omz plugin"
! grep -q "zsh-claude-complete" "$HOME/.zshrc" || fail "omz install edited .zshrc"

print "install: OK"
