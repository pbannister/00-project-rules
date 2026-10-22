#!/bin/sh
#
# rules-release.sh: gate a version and tag it.
#
# A project pins a tag, so the tag is the only thing that can reach a project.
# Everything that must be true before a rule change escapes this repository is
# checked here, in one place, and the tag is created only after all of it holds.
#
# Three house rules are enforced here rather than remembered:
#
#   * Branchless. This repository keeps exactly one branch and releases from
#     it. No branch name ever appears in a tag, which is why the tag is
#     <date>.<counter> and not the <date>-<branch> a project's release uses.
#   * One release a day. A second tag on the same date is refused unless
#     --same-day is passed. During the initial build-out that is expected; it
#     is not the way to run this repository later.
#   * Stated impact. The version carries no compatibility signal, so the
#     release record must say what the change does to a consuming project, and
#     an `internal` claim is checked against what actually changed.
#
# Usage: rules-release.sh [--dry-run | --next | --same-day]
set -eu
LC_ALL=C
export LC_ALL

DIRECTORY_SCRIPT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
RULES_ROOT=$(CDPATH= cd -- "$DIRECTORY_SCRIPT/.." && pwd)

dry_run=0
show_next=0
same_day=0
while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) dry_run=1 ;;
        --next) show_next=1 ;;
        --same-day) same_day=1 ;;
        -h|--help)
            echo 'usage: rules-release.sh [--dry-run | --next | --same-day]' >&2
            exit 2
            ;;
        *)
            echo "rules-release: unknown argument: $1" >&2
            exit 2
            ;;
    esac
    shift
done

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
today=$(date -u +%Y-%m-%d)

cd "$RULES_ROOT"

command -v git >/dev/null 2>&1 || fail 'git is not available'
[ -d .git ] || fail 'not a git repository'

# The counter is per date, so the next version on a date is one past the highest
# tag already cut for it.
counter_after() {
    highest=$(git tag -l "v$1.*" | sed 's/.*\.//' | grep -E '^[0-9]+$' | sort -n | tail -n 1)
    echo $(( ${highest:-0} + 1 ))
}
next_counter() {
    counter_after "$date_part"
}

# The date in a version is the day the release is cut, so --next reports today,
# not the date of the last release. Without this, the morning after a release
# would suggest another tag on the old date, which is the habit the house rules
# exist to prevent.
if [ "$show_next" -eq 1 ]; then
    echo "$today.$(counter_after "$today")"
    exit 0
fi

# 0. A release is dated the day it is cut. A version carrying another date makes
#    the tag say something untrue about when the rules changed.
[ "$date_part" = "$today" ] \
    || fail "VERSION is dated $date_part; a release is dated the day it is cut ($today). Set VERSION to $today.$(counter_after "$today")."

# 1. Branchless: exactly one branch exists and HEAD is on it. A tag made from a
#    side branch or a detached checkout is a release nobody can reproduce.
#    Detachment is reported first: a clone of a tag has no branch at all, and
#    "found 0 branches" would name the symptom rather than the cause.
branch=$(git symbolic-ref --short -q HEAD) \
    || fail 'HEAD is detached; a release must be made on the one branch'
branch_count=$(git for-each-ref --format='%(refname:short)' refs/heads | wc -l | tr -d ' ')
[ "$branch_count" -eq 1 ] \
    || fail "this repository is branchless: exactly one branch may exist, found $branch_count (this is not where feature branches belong)"
[ "$branch" = "$(git for-each-ref --format='%(refname:short)' refs/heads | head -n 1)" ] \
    || fail "HEAD is on '$branch', which is not the repository's single branch"

# 2. A dirty tree means the tag would not describe what was tested.
if [ -n "$(git status --porcelain)" ]; then
    git status --short
    fail 'the working tree is dirty; commit before releasing'
fi

# 3. The release record is the evidence that the behavioral bar was met. The
#    suite proves the machine-checkable part; only a person can record that the
#    evals in evals/ were run and what they showed.
FILE_RECORD="releases/v$version.md"
[ -f "$FILE_RECORD" ] || fail "no release record: $FILE_RECORD (record the eval results before releasing)"
[ -s "$FILE_RECORD" ] || fail "the release record is empty: $FILE_RECORD"

# The date-and-counter version says when, not how much, so the impact has to
# live somewhere else and be stated, not inferred. `internal` is permitted only
# when no shared file changed, so the claim is checked rather than believed.
impact=$(sed -n 's/^Impact: //p' "$FILE_RECORD" | head -n 1)
case "$impact" in
    initial|breaking|additive|wording|internal) ;;
    '') fail "$FILE_RECORD declares no 'Impact:' line; state initial|breaking|additive|wording|internal" ;;
    *) fail "$FILE_RECORD declares an unknown Impact: '$impact'" ;;
esac
if [ "$impact" = internal ]; then
    previous_tag=$(git describe --tags --abbrev=0 HEAD 2>/dev/null || true)
    if [ -n "$previous_tag" ]; then
        changed=$(git diff --name-only "$previous_tag" HEAD | grep -Fx -f MANIFEST || true)
        [ -z "$changed" ] \
            || fail "Impact is 'internal' but shared files changed since $previous_tag: $(echo $changed | tr '\n' ' ')"
    fi
fi
grep -qF "## [$version]" CHANGELOG.md || fail "CHANGELOG.md has no entry for $version"

# 4. The suite passes.
sh tools/rules-test.sh || fail 'the test suite failed'

# 5. The version is untagged, and it is the only release for its date unless
#    --same-day says otherwise. One release a day is the aim; the counter exists
#    for the initial build-out and for the rare correction, not for routine use.
if git rev-parse -q --verify "refs/tags/v$version" >/dev/null 2>&1; then
    fail "tag v$version already exists; the next version for $date_part is $date_part.$(next_counter)"
fi
if [ "$same_day" -eq 0 ]; then
    existing=$(git tag -l "v$date_part.*" | head -n 1)
    if [ -n "$existing" ]; then
        fail "one release a day: $existing already covers $date_part. Pass --same-day only for the initial build-out or a correction, not as routine."
    fi
fi

if [ "$dry_run" -eq 1 ]; then
    echo "rules-release: dry run: v$version is ready to tag"
    exit 0
fi

git tag -a "v$version" -m "v$version: $(sed -n 's/^## \[[^]]*\] - //p' CHANGELOG.md | head -n 1)"
echo "rules-release: tagged v$version"
echo "rules-release: next: sh $RULES_ROOT/tools/rules-vendor.sh <project>   # one project, in a task"
exit 0
