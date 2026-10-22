#!/bin/sh
#
# rules-vendor.sh: write the pinned shared rules into a project, and record
# exactly what was written in that project's rules.lock.
#
# This is the only supported way to get shared rules into a project. It is the
# write half of the pair; scripts/rules-check.sh (vendored into the project) is
# the read half and runs in the project's own `make test`.
#
# Usage:
#
#     rules-vendor.sh PROJECT_DIR [--version V] [--dry-run] [--force]
#
#   --version V   vendor version V instead of this repository's VERSION
#   --dry-run     report what would change, write nothing
#   --force       overwrite a vendored file that was edited locally
#
# Vendoring is an upgrade, and an upgrade is a task. Run it inside a task that
# names rules.lock and the vendored paths in its TASK-FILES, and record the
# outcome under the project's records/ directory. See README.md, "Upgrading".
#
# The vendored files keep their project-relative paths (prompts/01-contract.md,
# not rules/prompts/01-contract.md). Path stability is deliberate: every rule
# file, every reference inside those files, and every existing test addresses
# them by that path, so vendoring in place costs no edits anywhere.
set -eu
LC_ALL=C
export LC_ALL

DIRECTORY_SCRIPT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
RULES_ROOT=$(CDPATH= cd -- "$DIRECTORY_SCRIPT/.." && pwd)

usage() {
    echo 'usage: rules-vendor.sh PROJECT_DIR [--version V] [--dry-run] [--force] [--prune]' >&2
    exit 2
}

die() {
    echo "rules-vendor: $1" >&2
    exit 1
}

project_arg=""
version_arg=""
dry_run=0
force=0
prune=0
while [ $# -gt 0 ]; do
    case "$1" in
        --version)
            [ $# -ge 2 ] || usage
            version_arg=$2
            shift
            ;;
        --dry-run) dry_run=1 ;;
        --force) force=1 ;;
        --prune) prune=1 ;;
        -h|--help) usage ;;
        -*) usage ;;
        *)
            [ -z "$project_arg" ] || usage
            project_arg=$1
            ;;
    esac
    shift
done

[ -n "$project_arg" ] || usage
[ -d "$project_arg" ] || die "project directory not found: $project_arg"
PROJECT_ROOT=$(CDPATH= cd -- "$project_arg" && pwd)

[ -f "$RULES_ROOT/VERSION" ] || die "no VERSION in $RULES_ROOT"
version=${version_arg:-$(tr -d '[:space:]' < "$RULES_ROOT/VERSION")}
[ -n "$version" ] || die 'empty VERSION'
[ -f "$RULES_ROOT/MANIFEST" ] || die "no MANIFEST in $RULES_ROOT"

if command -v sha256sum >/dev/null 2>&1; then
    hash_file() { sha256sum -- "$1" | cut -d' ' -f1; }
elif command -v shasum >/dev/null 2>&1; then
    hash_file() { shasum -a 256 -- "$1" | cut -d' ' -f1; }
else
    die 'no sha256sum or shasum on PATH'
fi

# The version must be a tagged release: a project pins something that exists
# and that passed this repository's own suite.
if command -v git >/dev/null 2>&1 && [ -d "$RULES_ROOT/.git" ]; then
    if ! git -C "$RULES_ROOT" rev-parse -q --verify "refs/tags/v$version" >/dev/null 2>&1; then
        echo "rules-vendor: warning: v$version is not a tag in $RULES_ROOT; a project should pin a released version" >&2
    fi
fi

FILE_LOCK="$PROJECT_ROOT/rules.lock"

DIRECTORY_TEMP=$(mktemp -d)
trap 'rm -rf "$DIRECTORY_TEMP"' EXIT HUP INT TERM

# The previous lock, keyed by path, so the report can say added/updated/stale.
: > "$DIRECTORY_TEMP/old"
if [ -f "$FILE_LOCK" ]; then
    awk 'length($1) == 64 && $2 != "" {print $2, $1}' "$FILE_LOCK" > "$DIRECTORY_TEMP/old"
fi
sort -o "$DIRECTORY_TEMP/old" "$DIRECTORY_TEMP/old"

: > "$DIRECTORY_TEMP/new"
count_added=0
count_updated=0
count_unchanged=0

while read -r rel; do
    [ -n "$rel" ] || continue
    case "$rel" in
        /*|*..*|*\ *) die "MANIFEST contains an unusable path: $rel" ;;
    esac

    source_file="$RULES_ROOT/$rel"
    [ -f "$source_file" ] || die "MANIFEST names a missing file: $rel"
    dest_file="$PROJECT_ROOT/$rel"
    expected=$(hash_file "$source_file")
    previous=$(awk -v p="$rel" '$1 == p {print $2}' "$DIRECTORY_TEMP/old" | head -n 1)

    dest_exists=0
    if [ -f "$dest_file" ]; then
        dest_exists=1
    fi
    content_differs=0
    if [ "$dest_exists" -eq 1 ] && ! diff -q "$source_file" "$dest_file" >/dev/null 2>&1; then
        content_differs=1
    fi

    if [ "$content_differs" -eq 1 ]; then
        if [ -z "$previous" ]; then
            # A file that was never vendored is either the drift this tool exists
            # to replace, or a local customization. Only a human knows which, so
            # the first adoption is explicit: --force, after reviewing the diff.
            if [ "$force" -eq 0 ]; then
                die "refusing to overwrite $rel: it exists, is not vendored, and differs from v$version (review the diff, then pass --force to adopt)"
            fi
            echo "rules-vendor: adopting over an unvendored file: $rel" >&2
        else
            if [ "$(hash_file "$dest_file")" != "$previous" ] && [ "$force" -eq 0 ]; then
                die "refusing to overwrite a local edit of a vendored file: $rel (record the change, then pass --force)"
            fi
            [ "$(hash_file "$dest_file")" = "$previous" ] \
                || echo "rules-vendor: overwriting local edit: $rel" >&2
        fi
    fi

    # Classify by what changes on disk, not by lock membership. A file that is
    # byte-identical and merely newly locked has not changed, and reporting it
    # as an addition would inflate every first vendor and every upgrade review.
    if [ "$dest_exists" -eq 0 ]; then
        count_added=$((count_added + 1))
        echo "rules-vendor: add      $rel"
    elif [ "$content_differs" -eq 1 ]; then
        count_updated=$((count_updated + 1))
        echo "rules-vendor: update   $rel"
    else
        count_unchanged=$((count_unchanged + 1))
    fi

    printf '%s  %s\n' "$expected" "$rel" >> "$DIRECTORY_TEMP/new"

    if [ "$dry_run" -eq 0 ]; then
        mkdir -p "$(dirname -- "$dest_file")"
        cp "$source_file" "$dest_file"
    fi
done < "$RULES_ROOT/MANIFEST"

sort -k2 -o "$DIRECTORY_TEMP/new" "$DIRECTORY_TEMP/new"

# A file locked before and absent from the MANIFEST is reported, never deleted:
# removing a rule file is a decision for a human.
awk '{print $1}' "$DIRECTORY_TEMP/old" | sort > "$DIRECTORY_TEMP/old.paths"
awk '{print $2}' "$DIRECTORY_TEMP/new" | sort > "$DIRECTORY_TEMP/new.paths"
comm -23 "$DIRECTORY_TEMP/old.paths" "$DIRECTORY_TEMP/new.paths" > "$DIRECTORY_TEMP/stale"
count_stale=$(wc -l < "$DIRECTORY_TEMP/stale" | tr -d ' ')
count_pruned=0
while read -r rel; do
    [ -n "$rel" ] || continue
    # A shared file that was renamed or dropped leaves a copy behind. Two copies
    # of a rule set disagree the moment either is edited, and the validator
    # reports the leftover as a duplicate, so --prune removes it. It only ever
    # removes a path this project's own lock named, never a local file.
    if [ "$prune" -eq 1 ] && [ -f "$PROJECT_ROOT/$rel" ] && [ "$dry_run" -eq 0 ]; then
        rm -f "$PROJECT_ROOT/$rel"
        count_pruned=$((count_pruned + 1))
        echo "rules-vendor: prune    $rel (no longer in v$version)"
        continue
    fi
    echo "rules-vendor: stale    $rel (locked before, absent from v$version; delete it, or pass --prune)" >&2
done < "$DIRECTORY_TEMP/stale"

if [ "$dry_run" -eq 1 ]; then
    echo "rules-vendor: dry run: would write v$version: $count_added add, $count_updated update, $count_unchanged unchanged, $count_stale stale, $count_pruned pruned"
    exit 0
fi

{
    echo '# rules.lock -- generated by 00-project-rules/tools/rules-vendor.sh'
    echo '# Do not edit this file, and do not edit any file it lists.'
    echo '# Upgrade through a task that records the change under records/.'
    echo "version = $version"
    echo "source = 00-project-rules"
    echo "vendored = $(date -u +%Y-%m-%d)"
    cat "$DIRECTORY_TEMP/new"
} > "$DIRECTORY_TEMP/lock"
mv "$DIRECTORY_TEMP/lock" "$FILE_LOCK"

echo "rules-vendor: wrote v$version to $PROJECT_ROOT: $count_added add, $count_updated update, $count_unchanged unchanged, $count_stale stale, $count_pruned pruned"
echo "rules-vendor: next: sh $PROJECT_ROOT/scripts/rules-check.sh $PROJECT_ROOT"
