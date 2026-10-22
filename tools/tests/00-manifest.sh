#!/bin/sh
#
# Manifest integrity.
#
# The MANIFEST is the authoritative list of files this repository owns and
# vendors. Two failure modes matter: a file in the shared tree that the
# MANIFEST forgot (it would never reach a project, so the project silently
# lacks a rule), and a MANIFEST entry with no file behind it (vendoring fails
# in a project, far from the cause). Both fail here instead.
set -eu

DIRECTORY_SCRIPT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
RULES_ROOT=$(CDPATH= cd -- "$DIRECTORY_SCRIPT/../.." && pwd)

fail() {
    echo "00-manifest: $1" >&2
    exit 1
}

version=$(tr -d '[:space:]' < "$RULES_ROOT/VERSION")
[ -n "$version" ] || fail 'VERSION is empty'
printf '%s\n' "$version" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}\.[1-9][0-9]*$' \
    || fail "VERSION is not <date>.<counter> (YYYY-MM-DD.N): $version"

# 1. Every entry exists.
while read -r rel; do
    [ -n "$rel" ] || continue
    [ -f "$RULES_ROOT/$rel" ] || fail "MANIFEST names a missing file: $rel"
done < "$RULES_ROOT/MANIFEST"

# 2. No entry is listed twice.
duplicates=$(sort "$RULES_ROOT/MANIFEST" | uniq -d)
[ -z "$duplicates" ] || fail "MANIFEST lists a path twice: $duplicates"

# 3. Every file in the shared tree is listed. records/ is exempt: it may hold
#    this repository's own records, and only records/README.md is shared.
for directory in prompts evals tests; do
    find "$RULES_ROOT/$directory" -type f \
        | sed "s#^$RULES_ROOT/##" | sort > "/tmp/00-manifest.$$.found"
    while read -r rel; do
        [ -n "$rel" ] || continue
        grep -qxF -- "$rel" "$RULES_ROOT/MANIFEST" \
            || fail "file in the shared tree is not in MANIFEST: $rel"
    done < "/tmp/00-manifest.$$.found"
    rm -f "/tmp/00-manifest.$$.found"
done

# 4. The changelog records this version.
grep -qF "## [$version]" "$RULES_ROOT/CHANGELOG.md" \
    || fail "CHANGELOG.md has no entry for $version"

echo '00-manifest: ok'
exit 0
