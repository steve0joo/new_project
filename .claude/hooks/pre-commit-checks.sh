#!/usr/bin/env bash
# Pre-commit checks, wired as a Claude Code PreToolUse(Bash) hook.
#
# Fires before any Bash tool call. It only acts when the command is a `git commit`
# (including compound commands like `git add -A && git commit -m ...`); everything
# else passes straight through. On a commit it runs this project's checks and, if any
# fail, exits 2 to BLOCK the commit and feed the reason back to Claude.
#
#   lint  -> npx prettier --check  (format gate; auto-fix with: npx prettier --write .)
#   test  -> node --check on the inline <script> JS of each *.html  (syntax gate)
#   build -> none; this is a static site, so there is nothing to build
#
# Exit codes: 0 = allow the commit, 2 = block it.

set -uo pipefail

# Move to the project root so relative paths and npx resolve correctly.
cd "${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}" || exit 0

# --- Decide whether this invocation is a git commit -------------------------
payload="$(cat)"
cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null)"

case "$cmd" in
  *"git commit"*) : ;;        # a commit -> run the checks below
  *) exit 0 ;;                # anything else -> allow without doing work
esac
# Don't gate help/usage invocations.
case "$cmd" in
  *"git commit"*--help*|*"git commit"*" -h"*) exit 0 ;;
esac

block() {
  echo "" >&2
  echo "❌ pre-commit 검사 실패: $1" >&2
  echo "   커밋이 차단되었습니다. 위 문제를 고친 뒤 다시 커밋하세요." >&2
  exit 2
}

log_dir="$(mktemp -d)"
trap 'rm -rf "$log_dir"' EXIT

# --- 1) lint: prettier format check -----------------------------------------
# --ignore-unknown skips files prettier has no parser for (e.g. *.sql).
if ! npx --yes prettier --check . --ignore-unknown >"$log_dir/prettier.log" 2>&1; then
  cat "$log_dir/prettier.log" >&2
  block "prettier 포맷 검사 (자동 수정: npx prettier --write .)"
fi

# --- 2) test: syntax-check inline JS in every HTML file ---------------------
shopt -s nullglob
for html in *.html; do
  js="$log_dir/$(basename "$html").inline.js"
  # Capture text between a bare <script> ... </script> (the inline app script).
  # The CDN <script src=...> tag has attributes, so /<script>/ won't match it.
  awk '/<script>/{f=1; next} /<\/script>/{f=0} f' "$html" >"$js"
  if [ -s "$js" ]; then
    if ! node --check "$js" >"$log_dir/node.log" 2>&1; then
      cat "$log_dir/node.log" >&2
      block "$html 의 인라인 JavaScript 문법 오류"
    fi
  fi
done

# --- 3) build: nothing to do for a static site ------------------------------

echo "✅ pre-commit: lint + 문법 검사 통과" >&2
exit 0
