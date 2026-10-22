#!/bin/sh
#
# The eval-task extractor.
#
# The risk this closes is subtle and total: an eval measures whether the agent is
# steered by the rules, and it stops measuring that the moment the agent can see
# the expected behavior or the rubric. The cases are markdown that a naive slice
# mangles, so the extraction is a tool with a test rather than a shell one-liner.
#
# The second risk is quieter: a case written against the skeleton's file set
# cannot run in a project that diverged, and a run against a missing prop
# produces a confident, meaningless report rather than a failure. `## Requires`
# exists so the tool can refuse instead.
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
DIRECTORY_PROJECT="$DIRECTORY_TEST/project"
mkdir -p "$DIRECTORY_PROJECT/evals" "$DIRECTORY_PROJECT/scripts"
FILE_CASE="$DIRECTORY_PROJECT/evals/case.md"

# A case shaped like the real ones: prerequisites declared, the task fenced, the
# fence opening with a heading a naive slice stops at, and a note after the fence.
cat > "$FILE_CASE" <<'EOF'
# Eval: example

## Case

Something is under test.

## Requires

- `scripts/present.sh`

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

# 1. A missing prerequisite is a refusal, not an empty task.
status=0
output=$(sh "$SCRIPT_TASK" "$FILE_CASE" 2>&1) || status=$?
[ "$status" -eq 2 ] || fail "a missing prerequisite exited $status, expected 2"
printf '%s\n' "$output" | grep -qF 'does not carry scripts/present.sh' \
    || fail "the missing prerequisite was not named: $output"
printf '%s\n' "$output" | grep -qF 'not a failure' \
    || fail "the refusal did not say what it means: $output"

# 2. With the prerequisite present, the task is the fenced block.
: > "$DIRECTORY_PROJECT/scripts/present.sh"
output=$(sh "$SCRIPT_TASK" "$FILE_CASE") || fail 'extraction failed on a satisfied case'
printf '%s\n' "$output" | grep -qF '## TASK-DESCRIPTION' \
    || fail "the task body was not extracted: $output"
printf '%s\n' "$output" | grep -qF 'Run: make test' \
    || fail "the task body was truncated: $output"

# 3. Nothing outside the fence leaks into the task.
for forbidden in 'contradicts' 'Expected behavior' 'Scoring' '```'; do
    if printf '%s\n' "$output" | grep -qF "$forbidden"; then
        fail "the extraction leaked '$forbidden' into the task: $output"
    fi
done

# 4. The note is available to the operator, and labelled as not for the agent.
note=$(sh "$SCRIPT_TASK" "$FILE_CASE" --note 2>&1 >/dev/null) \
    || fail 'extraction with --note failed'
printf '%s\n' "$note" | grep -qF 'NOT to the agent' \
    || fail "the note was not labelled: $note"
printf '%s\n' "$note" | grep -qF 'contradicts' \
    || fail "the operator note was not surfaced: $note"
if printf '%s\n' "$note" | grep -q 'TASK-DESCRIPTION'; then
    fail "the operator note contains the task body: $note"
fi

# 5. A case that declares Nothing runs anywhere.
cat > "$DIRECTORY_PROJECT/evals/portable.md" <<'EOF'
# Eval: portable

## Case

The absent file is the subject.

## Requires

- Nothing. The absent file is the subject of the case.

## Task given to the agent

```text
## TASK-DESCRIPTION
Report the missing file.
```
EOF
sh "$SCRIPT_TASK" "$DIRECTORY_PROJECT/evals/portable.md" >/dev/null \
    || fail 'a case requiring nothing was refused'

# 6. A case with no task section is an error, not an empty task.
printf '# Eval: empty\n\n## Case\n\nnothing\n' > "$DIRECTORY_PROJECT/evals/bare.md"
status=0
sh "$SCRIPT_TASK" "$DIRECTORY_PROJECT/evals/bare.md" >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "a case with no task section exited $status, expected 2"

echo '07-eval-task: ok'
exit 0
