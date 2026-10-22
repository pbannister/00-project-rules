#!/bin/sh
#
# The conformance reporter.
#
# The validator states one finding per line, in file order. This tool's job is to
# turn that into the shape of the work: which actions, touching which files. It
# reports and never repairs, so the test asserts that a clean project is quiet, a
# broken one is grouped by action, and no file is modified.
set -eu

DIRECTORY_SCRIPT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
RULES_ROOT=$(CDPATH= cd -- "$DIRECTORY_SCRIPT/../.." && pwd)
SKELETON=${SKELETON_DIR:-"$RULES_ROOT/../00-project-skeleton"}
SCRIPT_CONFORM="$RULES_ROOT/scripts/rules-conform.sh"

if [ ! -d "$SKELETON" ]; then
    echo "SKIP: skeleton not available at $SKELETON"
    exit 0
fi

fail() {
    echo "06-conform: $1" >&2
    exit 1
}

DIRECTORY_TEST=$(mktemp -d)
trap 'rm -rf "$DIRECTORY_TEST"' EXIT HUP INT TERM
DIRECTORY_ROOT="$DIRECTORY_TEST/project"
mkdir -p "$DIRECTORY_ROOT"
cp -R "$SKELETON/." "$DIRECTORY_ROOT/"
rm -rf "$DIRECTORY_ROOT/.git"

# 1. A conformant project is quiet, and says so.
output=$(sh "$SCRIPT_CONFORM" "$DIRECTORY_ROOT") \
    || fail "a clean project did not exit 0: $output"
printf '%s\n' "$output" | grep -q 'ok (nothing to conform' \
    || fail "a clean project did not report ok: $output"
printf '%s\n' "$output" | grep -q 'pinned 2026-' \
    || fail "the pinned version was not reported: $output"

# 2. Three different failures, in three different places, collapse to three
#    actions -- and each action names the file it touches.
printf 'x\n' > "$DIRECTORY_ROOT/NOTES.md"
python3 - "$DIRECTORY_ROOT" <<'PY'
import re
import sys
root = sys.argv[1]
task = f"{root}/prompts/tasks/01-site-build-implement.md"
text = open(task, encoding="utf-8").read()
text = re.sub(r"^## TASK-VERIFY\s*$.*?(?=^## |\Z)", "", text, flags=re.S | re.M)
open(task, "w", encoding="utf-8").write(text)
feature = f"{root}/prompts/features/01-site-build.md"
lines = [re.sub(r"^- `SITE-BUILD-R\d{3}` — ", "- ", line)
         for line in open(feature, encoding="utf-8").read().splitlines()]
open(feature, "w", encoding="utf-8").write("\n".join(lines) + "\n")
PY
git -C "$DIRECTORY_ROOT" init -q
git -C "$DIRECTORY_ROOT" add -A

if output=$(sh "$SCRIPT_CONFORM" "$DIRECTORY_ROOT" 2>&1); then
    fail 'a non-conformant project exited 0'
fi
for expected in 'requirement identifiers' 'task format' 'structure declaration'; do
    printf '%s\n' "$output" | grep -qF "$expected" \
        || fail "the action '$expected' was not reported: $output"
done
printf '%s\n' "$output" | grep -qF 'prompts/tasks/01-site-build-implement.md' \
    || fail "the task file was not named: $output"
printf '%s\n' "$output" | grep -qF 'NOTES.md' \
    || fail "the stray root file was not named: $output"

# 3. The default is a summary; --verbose is the evidence, per finding.
output=$(sh "$SCRIPT_CONFORM" "$DIRECTORY_ROOT" --verbose 2>&1 || true)
printf '%s\n' "$output" | grep -qF 'Every finding, by action' \
    || fail "verbose mode did not enumerate the findings: $output"
printf '%s\n' "$output" | grep -qF 'requirement without an identifier' \
    || fail "verbose mode lost the individual findings: $output"

# 4. It reports; it does not repair. The files are exactly as this test left them.
printf '%s\n' 'x' > "$DIRECTORY_TEST/expected-notes"
if ! cmp -s "$DIRECTORY_TEST/expected-notes" "$DIRECTORY_ROOT/NOTES.md"; then
    fail 'the reporter modified a file it was only reading'
fi

# 5. A project with no validator is an environment error, not a conformance one.
mkdir -p "$DIRECTORY_TEST/bare"
status=0
sh "$SCRIPT_CONFORM" "$DIRECTORY_TEST/bare" >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "a project without the validator exited $status, expected 2"

echo '06-conform: ok'
exit 0
