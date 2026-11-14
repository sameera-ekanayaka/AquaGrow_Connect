#!/bin/sh
# Checks one commit message against the team rules (see CONTRIBUTING.md).
#
#   sh tool/check_commit_message.sh <file-with-message>
#
# Rules:
#   1. Subject follows Conventional Commits:  type(scope): summary
#      type is one of: feat fix docs style refactor perf test build ci chore revert
#   2. Subject is at most 100 characters (aim for 72).
#   3. The message never names an AI tool or assistant, and has no
#      AI "Co-authored-by" trailer.
# Merge and revert commits created by Git are allowed as they are.

msg_file="$1"
subject=$(grep -v '^#' "$msg_file" | sed -n '1p')

case "$subject" in
  "Merge "*|"Revert \""*) exit 0 ;;
esac

fail() {
  echo "COMMIT REJECTED: $1" >&2
  echo "  Subject was: $subject" >&2
  echo "  See CONTRIBUTING.md, section 'Commit messages'." >&2
  exit 1
}

echo "$subject" | grep -Eq '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-z0-9-]+\))?!?: [^ ].*' \
  || fail "subject must look like 'feat(crops): add harvest passport QR'"

[ "${#subject}" -le 100 ] || fail "subject is longer than 100 characters"

banned='claude|anthropic|chatgpt|openai|gpt-?[0-9]|copilot|gemini|codex|cursor ai|windsurf|bard|llm|ai[- ]generated|generated (by|with) ai|ai assistant|ai agent'
if grep -v '^#' "$msg_file" | grep -Eiq "$banned"; then
  fail "commit messages must not mention AI tools or assistants"
fi

exit 0
