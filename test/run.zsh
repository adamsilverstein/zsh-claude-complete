#!/usr/bin/env zsh
# Offline test runner. Needs zsh and jq; never calls Claude or the network.
# `claude` and `curl` are replaced by the stubs in test/stubs.
#
# Usage: zsh test/run.zsh [test/unit/<file>.zsh ...]
emulate -L zsh
setopt extended_glob

root="${0:A:h:h}"
files=( "$@" )
(( $#files )) || files=( "$root"/test/unit/*.zsh )

(( $+commands[jq] )) || { print -u2 "jq is required to run the tests"; exit 2; }

integer passed=0 failed=0
for file in $files; do
  print -r -- "${file:t}"
  # List the test_* functions the file defines, in file order.
  tests=( ${(f)"$(zsh -fc "source ${(q)file}; print -l \${(ok)functions[(I)test_*]}")"} )
  for t in $tests; do
    out=$(ZSH_AI_TEST_ROOT="$root" zsh -f "$root/test/lib.zsh" "$file" "$t" 2>&1)
    if (( $? == 0 )); then
      (( passed++ ))
      print -r -- "  ok   $t"
    else
      (( failed++ ))
      print -r -- "  FAIL $t"
      print -r -- "$out" | sed 's/^/      /'
    fi
  done
done

print
print -r -- "$passed passed, $failed failed"
(( failed == 0 ))
