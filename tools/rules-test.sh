#!/bin/sh
#
# rules-test.sh: run this repository's own tests.
#
# The vendored tests under tests/ (09, 10, 13) validate a *complete project*:
# they require the local layer (glossary, feature and task indexes, README), so
# they cannot run against this repository, which holds only the shared layer.
# tools/tests/04-skeleton-integration.sh runs them where they belong, against a
# real project with v<version> vendored in.
#
# Runs every test, reports PASS/FAIL, and exits nonzero when any failed.
set -eu

DIRECTORY_SCRIPT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
RULES_ROOT=$(CDPATH= cd -- "$DIRECTORY_SCRIPT/.." && pwd)

count_pass=0
count_fail=0
count_skip=0

for test_file in "$RULES_ROOT"/tools/tests/[0-9][0-9]-*.sh; do
    [ -f "$test_file" ] || continue
    name=$(basename "$test_file")
    if output=$(cd "$RULES_ROOT" && sh "$test_file" 2>&1); then
        case "$output" in
            SKIP:*) count_skip=$((count_skip + 1)); printf 'SKIP %s -- %s\n' "$name" "${output#SKIP: }" ;;
            *) count_pass=$((count_pass + 1)); printf 'PASS %s\n' "$name" ;;
        esac
    else
        count_fail=$((count_fail + 1))
        printf 'FAIL %s\n' "$name"
        printf '%s\n' "$output" | sed 's/^/     /'
    fi
done

echo "rules-test: $count_pass passed, $count_fail failed, $count_skip skipped"
[ "$count_fail" -eq 0 ] || exit 1
exit 0
