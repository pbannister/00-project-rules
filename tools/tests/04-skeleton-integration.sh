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

# 1. Faithfulness, where it is meaningful.
#
#    "Vendoring this version changes no existing file" can only hold once the
#    skeleton already pins this version. It cannot hold while a version is being
#    prepared: the release that changes a shared rule is cut before the template
#    adopts it, so demanding it would deadlock every such release. Assert it
#    exactly when it is true, and always assert the property that matters -- a
#    complete project plus this version passes the project's own validator.
version=$(tr -d '[:space:]' < "$RULES_ROOT/VERSION")
pinned_version=$(sed -n 's/^version = //p' "$DIRECTORY_TEST/rules.lock" 2>/dev/null | head -n 1)
# --force, because this test emulates an adoption and an adoption is allowed to
# replace a file the project never pinned. A file can move from local to shared
# (evals/README.md did), which the guard reports as "unvendored and differs".
# The counts below still report what actually changed on disk.
output=$(sh "$RULES_ROOT/tools/rules-vendor.sh" "$DIRECTORY_TEST" --force 2>&1) \
    || fail "vendoring into the skeleton failed: $output"
if [ "$pinned_version" = "$version" ]; then
    printf '%s\n' "$output" | grep -Eq '0 add, 0 update' \
        || fail "the skeleton pins $version but vendoring still changed files: $output"
else
    echo "04-skeleton-integration: skeleton pins ${pinned_version:-nothing}; checking coherence only"
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
