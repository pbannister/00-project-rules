#!/bin/sh
#
# rules-release.sh: gate a version and tag it.
#
# A project pins a tag, so the tag is the only thing that can reach a project.
# Everything that must be true before a rule change escapes this repository is
# checked here, in one place, and the tag is created only after all of it holds.
#
# Usage: rules-release.sh [--dry-run]
set -eu
LC_ALL=C
export LC_ALL

DIRECTORY_SCRIPT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
RULES_ROOT=$(CDPATH= cd -- "$DIRECTORY_SCRIPT/.." && pwd)

dry_run=0
show_next=0
case "${1:-}" in
    --dry-run) dry_run=1 ;;
    --next) show_next=1 ;;
esac

fail() {
    echo "rules-release: $1" >&2
    echo 'rules-release: NOT RELEASED' >&2
    exit 1
}

version=$(tr -d '[:space:]' < "$RULES_ROOT/VERSION")
[ -n "$version" ] || fail 'VERSION is empty'

# A version is <date>.<counter>: YYYY-MM-DD, a dot, and a counter that starts
# at 1 each day. VERSION holds it without the leading "v"; the tag adds the "v".
case "$version" in
    *[!0-9.-]*) fail "VERSION is not <date>.<counter> (YYYY-MM-DD.N): $version" ;;
esac
printf '%s\n' "$version" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}\.[1-9][0-9]*$' \
    || fail "VERSION is not <date>.<counter> (YYYY-MM-DD.N): $version"
date_part=${version%.*}

cd "$RULES_ROOT"

command -v git >/dev/null 2>&1 || fail 'git is not available'
[ -d .git ] || fail 'not a git repository'

# The counter is per date, so the next version on this date is one past the
# highest tag already cut for it.
next_counter() {
    highest=$(git tag -l "v$date_part.*" | sed 's/.*\.//' | grep -E '^[0-9]+$' | sort -n | tail -n 1)
    echo $(( ${highest:-0} + 1 ))
}

if [ "$show_next" -eq 1 ]; then
    echo "$date_part.$(next_counter)"
    exit 0
fi

# 1. A dirty tree means the tag would not describe what was tested.
if [ -n "$(git status --porcelain)" ]; then
    git status --short
    fail 'the working tree is dirty; commit before releasing'
fi

# 2. The release record is the evidence that the behavioral bar was met. The
#    suite proves the machine-checkable part; only a person can record that the
#    evals in evals/ were run and what they showed.
#
#    The date-and-counter version says when, not how much, so the impact has to
#    live somewhere else and be stated, not inferred.
FILE_RECORD="releases/v$version.md"
[ -f "$FILE_RECORD" ] || fail "no release record: $FILE_RECORD (record the eval results before releasing)"
[ -s "$FILE_RECORD" ] || fail "the release record is empty: $FILE_RECORD"
grep -Eq '^Impact: (initial|breaking|additive|wording)$' "$FILE_RECORD" \
    || fail "$FILE_RECORD must declare 'Impact: initial|breaking|additive|wording' on its own line (the version string does not carry it)"
grep -qF "## [$version]" CHANGELOG.md || fail "CHANGELOG.md has no entry for $version"

# 3. The suite passes.
sh tools/rules-test.sh || fail 'the test suite failed'

# 4. The tag does not already exist.
if git rev-parse -q --verify "refs/tags/v$version" >/dev/null 2>&1; then
    fail "tag v$version already exists; the next version for $date_part is $date_part.$(next_counter)"
fi

if [ "$dry_run" -eq 1 ]; then
    echo "rules-release: dry run: v$version is ready to tag"
    exit 0
fi

git tag -a "v$version" -m "v$version: $(sed -n 's/^## \[[^]]*\] - //p' CHANGELOG.md | head -n 1)"
echo "rules-release: tagged v$version"
echo "rules-release: next: sh $RULES_ROOT/tools/rules-vendor.sh <project>   # one project, in a task"
exit 0
