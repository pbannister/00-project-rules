#!/bin/sh
#
# The eval-task extractor.
#
# The risk this closes is subtle and total: an eval measures whether the agent is
# steered by the rules, and it stops measuring that the moment the agent can see
# the expected behavior or the rubric. The cases are markdown that a naive slice
# mangles, so the extraction is a tool with a test rather than a shell one-liner.
set -eu

DIRECTORY_SCRIPT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
RULES_ROOT=$(CDPATH= cd -- "$DIRECTORY_SCRIPT/../.." && pwd)
SCRIPT_TASK="$RULES_ROOT/scripts/rules-eval-task.sh"

fail() {
    echo "07-eval-task: $1" >&2
    exit 1
}

DIRECTORY_TEST=$(mktemp -d)
trap 'rm -rf "$DIRECTORY_TEST"' EXIT HUP INT TERM
FILE_CASE="$DIRECTORY_TEST/case.md"

# A case shaped like the real ones: the task is fenced, the fence opens with a
# heading the naive slice stops at, and a note follows the fence.
cat > "$FILE_CASE" <<'EOF'
# Eval: example

## Case

Something is under test.

## Task given to the agent

```text
## TASK-DESCRIPTION
Do the single thing.
## TASK-VERIFY
- Run: make test
```

This note names the test the task contradicts.

## Expected behavior

- The agent does the thing.

## Scoring

- Pass or fail.
EOF

# 1. The task is the fenced block, headings inside it and all.
output=$(sh "$SCRIPT_TASK" "$FILE_CASE") || fail 'extraction failed on a well-formed case'
printf '%s\n' "$output" | grep -qF '## TASK-DESCRIPTION' \
    || fail "the task body was not extracted: $output"
printf '%s\n' "$output" | grep -qF 'Run: make test' \
    || fail "the task body was truncated: $output"

# 2. Nothing outside the fence leaks into the task -- not the note, not the
#    rubric, not the expectation.
for forbidden in 'contradicts' 'Expected behavior' 'Scoring' '```'; do
    if printf '%s\n' "$output" | grep -qF "$forbidden"; then
        fail "the extraction leaked '$forbidden' into the task: $output"
    fi
done

# 3. The note is available to the operator, and labelled as not for the agent.
note=$(sh "$SCRIPT_TASK" "$FILE_CASE" --note 2>&1 >/dev/null) \
    || fail 'extraction with --note failed'
printf '%s\n' "$note" | grep -qF 'NOT to the agent' \
    || fail "the note was not labelled: $note"
printf '%s\n' "$note" | grep -qF 'contradicts' \
    || fail "the operator note was not surfaced: $note"
if printf '%s\n' "$note" | grep -q 'TASK-DESCRIPTION'; then
    fail "the operator note contains the task body: $note"
fi

# 4. A case with no such section is an error, not an empty task.
printf '# Eval: empty\n\n## Case\n\nnothing\n' > "$DIRECTORY_TEST/bare.md"
status=0
sh "$SCRIPT_TASK" "$DIRECTORY_TEST/bare.md" >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "a case with no task section exited $status, expected 2"

echo '07-eval-task: ok'
exit 0
