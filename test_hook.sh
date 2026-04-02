#!/usr/bin/env bash
set -euo pipefail

# Test harness for the git push PreToolUse hook regex.
# Validates that the regex blocks pushes to main/master
# but allows pushes to branches containing "main"/"master" as substrings.

PATTERN='git[[:space:]]+push[[:space:]].*[[:space:]:/+](main|master)([[:space:]]|$)'

pass=0
fail=0

assert_blocked() {
  local cmd="$1"
  if echo "$cmd" | grep -qE "$PATTERN"; then
    echo "PASS (blocked): $cmd"
    pass=$((pass + 1))
  else
    echo "FAIL (expected blocked, got allowed): $cmd"
    fail=$((fail + 1))
  fi
}

assert_allowed() {
  local cmd="$1"
  if echo "$cmd" | grep -qE "$PATTERN"; then
    echo "FAIL (expected allowed, got blocked): $cmd"
    fail=$((fail + 1))
  else
    echo "PASS (allowed): $cmd"
    pass=$((pass + 1))
  fi
}

echo "=== Should be BLOCKED ==="
assert_blocked "git push origin main"
assert_blocked "git push origin master"
assert_blocked "git push -u origin main"
assert_blocked "git push --force origin main"
assert_blocked "git push --force origin master"
assert_blocked "git push origin test-results:main"
assert_blocked "git push origin feature:master"
assert_blocked "git push origin refs/heads/main"
assert_blocked "git push origin refs/heads/master"
assert_blocked "git push origin +main"
assert_blocked "git push origin +master"
assert_blocked "git push origin +refs/heads/main"
assert_blocked "git push origin HEAD:refs/heads/main"
assert_blocked "git push origin +HEAD:refs/heads/main"
assert_blocked "git push origin abc123:refs/heads/main"

echo ""
echo "=== Should be ALLOWED ==="
assert_allowed "git push -u origin deps/aiohttp-3.13.5-remaining"
assert_allowed "git push -u origin HEAD"
assert_allowed "git push origin feature/maintain-state"
assert_allowed "git push origin fix/mainframe-bug"
assert_allowed "git push"
assert_allowed "git push -u origin deps/update-mainline-config"
assert_allowed "git push origin feature/remaster-audio"

echo ""
echo "=== Results: $pass passed, $fail failed ==="
if [ "$fail" -gt 0 ]; then
  exit 1
fi
