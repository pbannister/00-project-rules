#!/bin/sh
#
# End to end: the shared layer plus a real project is a conformant project.
#
# The vendored tests validate a complete project, so they cannot run against
# this repository. This test builds the thing they need: a copy of
# 00-project-skeleton (a complete project) with the current version vendored
# in. Two properties fall out.
#
#   1. Faithfulness. Vendoring into the skeleton changes nothing, which is only
#      true while this repository's shared files are exactly the files the
#      skeleton already had. A drift between the two is a defect in whichever
#      one is older.
#   2. Coherence. The shared validator accepts the result, so the vendored set
#      is internally consistent and complete enough for a project to adopt.
#
# The skeleton is a sibling directory. When it is absent the test skips rather
# than fails, because a standalone checkout of this repository is legitimate.
set -eu

DIRECTORY_SCRIPT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
RULES_ROOT=$(CDPATH= cd -- "$DIRECTORY_SCRIPT/../.." && pwd)
SKELETON=${SKELETON_DIR:-"$RULES_ROOT/../00-project-skeleton"}

if [ ! -d "$SKELETON" ]; then
    echo "SKIP: skeleton not available at $SKELETON"
    exit 0
fi

fail() {
    echo "04-skeleton-integration: $1" >&2
    exit 1
}

DIRECTORY_TEST=$(mktemp -d)
trap 'rm -rf "$DIRECTORY_TEST"' EXIT HUP INT TERM

cp -R "$SKELETON/." "$DIRECTORY_TEST/"
rm -rf "$DIRECTORY_TEST/.git"

# 1. Faithfulness: no pre-existing shared file has to change to reach this
#    version. Once the skeleton pins a version itself, a clean vendor must also
#    add nothing at all; before it does, the gate script is a legitimate
#    addition, which is why the stronger assertion is conditional.
pinned=0
[ -f "$DIRECTORY_TEST/rules.lock" ] && pinned=1
output=$(sh "$RULES_ROOT/tools/rules-vendor.sh" "$DIRECTORY_TEST" 2>&1) \
    || fail "vendoring into the skeleton failed: $output"
printf '%s\n' "$output" | grep -Eq '0 update' \
    || fail "this repository has drifted from the skeleton: $output"
if [ "$pinned" -eq 1 ]; then
    printf '%s\n' "$output" | grep -Eq '0 add, 0 update' \
        || fail "the skeleton is pinned but vendor still had to add files: $output"
fi

# 2. Coherence: the project's own check passes, and the validator agrees.
sh "$DIRECTORY_TEST/scripts/rules-check.sh" "$DIRECTORY_TEST" >/dev/null \
    || fail 'the vendored skeleton failed rules-check'

if output=$(cd "$DIRECTORY_TEST" && sh tests/09-prompt-contract.sh 2>&1); then
    :
else
    printf '%s\n' "$output" | sed 's/^/04-skeleton-integration: /' >&2
    fail 'the shared validator rejected a complete project with this version vendored in'
fi

if output=$(cd "$DIRECTORY_TEST" && sh tests/13-corpus-coverage.sh 2>&1); then
    :
else
    printf '%s\n' "$output" | sed 's/^/04-skeleton-integration: /' >&2
    fail 'corpus coverage failed against a complete project with this version vendored in'
fi

echo '04-skeleton-integration: ok'
exit 0
