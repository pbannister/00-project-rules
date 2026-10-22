#!/bin/sh
#
# A clean vendor produces a conformant project.
#
# Vendors the current version into an empty directory and asserts the result:
# a lock naming every manifest entry, files byte-identical to the source, and
# rules-check reporting the pinned version.
set -eu

DIRECTORY_SCRIPT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
RULES_ROOT=$(CDPATH= cd -- "$DIRECTORY_SCRIPT/../.." && pwd)
version=$(tr -d '[:space:]' < "$RULES_ROOT/VERSION")

fail() {
    echo "01-vendor: $1" >&2
    exit 1
}

DIRECTORY_TEST=$(mktemp -d)
trap 'rm -rf "$DIRECTORY_TEST"' EXIT HUP INT TERM

sh "$RULES_ROOT/tools/rules-vendor.sh" "$DIRECTORY_TEST" >/dev/null 2>&1 \
    || fail 'vendor refused an empty project directory'
[ -f "$DIRECTORY_TEST/rules.lock" ] || fail 'no rules.lock written'

grep -qxF "version = $version" "$DIRECTORY_TEST/rules.lock" || fail 'lock does not name the version'

count_manifest=$(grep -c . "$RULES_ROOT/MANIFEST" | tr -d ' ')
count_lock=$(awk 'length($1) == 64' "$DIRECTORY_TEST/rules.lock" | wc -l | tr -d ' ')
[ "$count_manifest" = "$count_lock" ] \
    || fail "lock lists $count_lock files, MANIFEST lists $count_manifest"

# A sampled file is byte-identical, not merely present.
cmp -s "$RULES_ROOT/prompts/01-contract.md" "$DIRECTORY_TEST/prompts/01-contract.md" \
    || fail 'vendored prompts/01-contract.md differs from the source'

output=$(sh "$DIRECTORY_TEST/scripts/rules-check.sh" "$DIRECTORY_TEST") \
    || fail "a freshly vendored project failed its own check: $output"
printf '%s\n' "$output" | grep -qF "ok (v$version" || fail "check reported the wrong version: $output"

# A second vendor is idempotent and reports no change.
output=$(sh "$RULES_ROOT/tools/rules-vendor.sh" "$DIRECTORY_TEST" 2>&1) \
    || fail 'a second vendor of an unmodified project failed'
printf '%s\n' "$output" | grep -q '0 add, 0 update' \
    || fail "re-vendoring was not a no-op: $output"

echo '01-vendor: ok'
exit 0
