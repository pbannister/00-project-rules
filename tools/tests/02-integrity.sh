#!/bin/sh
#
# Integrity: a project that no longer matches its pin is refused.
#
# The three ways a project drifts, and the refusal each one earns: an edited
# vendored file, a deleted vendored file, and a project that never pinned
# anything. The vendor tool must also refuse to overwrite the edit, because a
# silent overwrite would erase the evidence instead of reporting it.
set -eu

DIRECTORY_SCRIPT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
RULES_ROOT=$(CDPATH= cd -- "$DIRECTORY_SCRIPT/../.." && pwd)

fail() {
    echo "02-integrity: $1" >&2
    exit 1
}

expect_failure() {
    # expect_failure <label> <expected message> <command...>
    label=$1
    expected=$2
    shift 2
    if output=$("$@" 2>&1); then
        fail "$label: expected a failure, got success: $output"
    fi
    printf '%s\n' "$output" | grep -qF "$expected" \
        || fail "$label: refusal did not say '$expected': $output"
}

new_project() {
    directory=$(mktemp -d)
    sh "$RULES_ROOT/tools/rules-vendor.sh" "$directory" >/dev/null 2>&1 \
        || fail 'vendor failed while building the fixture'
    printf '%s\n' "$directory"
}

DIRECTORY_A=$(new_project)
DIRECTORY_B=$(new_project)
DIRECTORY_C=$(mktemp -d)
trap 'rm -rf "$DIRECTORY_A" "$DIRECTORY_B" "$DIRECTORY_C"' EXIT HUP INT TERM

# 1. An edited vendored file is drift, and the check names the file.
printf '\nlocal note\n' >> "$DIRECTORY_A/prompts/03-conventions.md"
expect_failure 'edited vendored file' 'modified: prompts/03-conventions.md' \
    sh "$DIRECTORY_A/scripts/rules-check.sh" "$DIRECTORY_A"

# 2. A deleted vendored file is reported as missing, not as a crash.
rm "$DIRECTORY_B/prompts/common/02-universal-rules.md"
expect_failure 'deleted vendored file' 'missing: prompts/common/02-universal-rules.md' \
    sh "$DIRECTORY_B/scripts/rules-check.sh" "$DIRECTORY_B"

# 3. A project with no lock is refused outright.
expect_failure 'missing lock' 'no rules.lock' \
    sh "$RULES_ROOT/scripts/rules-check.sh" "$DIRECTORY_C"

# 4. Vendoring over an edit is refused unless forced.
expect_failure 'vendor over a local edit' 'refusing to overwrite a local edit' \
    sh "$RULES_ROOT/tools/rules-vendor.sh" "$DIRECTORY_A"

# 5. Forcing restores the pinned text, and the check passes again.
sh "$RULES_ROOT/tools/rules-vendor.sh" "$DIRECTORY_A" --force >/dev/null 2>&1 \
    || fail 'vendor --force failed'
sh "$DIRECTORY_A/scripts/rules-check.sh" "$DIRECTORY_A" >/dev/null \
    || fail 'the project did not return to conformance after --force'

echo '02-integrity: ok'
exit 0
