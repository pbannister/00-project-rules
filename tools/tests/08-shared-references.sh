#!/bin/sh
#
# Shared files must not name project-specific features.
#
# The recurring defect in this library is a shared document that depends on the
# template's inventory: an example pointing at the skeleton's site-build feature,
# a dependency edge to it, an eval task that modifies a skeleton script. Each
# instance is invisible in every project that happens to carry the file and fails
# in every project that does not -- and each cost a release to discover.
#
# This is the crisp half of the rule: a feature file is project-specific by
# definition, so a shared file may only name a feature that is itself shared.
set -eu

DIRECTORY_SCRIPT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
RULES_ROOT=$(CDPATH= cd -- "$DIRECTORY_SCRIPT/../.." && pwd)

fail() {
    echo "08-shared-references: $1" >&2
    exit 1
}

count=0
while read -r rel; do
    [ -n "$rel" ] || continue
    [ -f "$RULES_ROOT/$rel" ] || continue
    # A test synthesises its fixtures, so the paths it writes are not references
    # to files a project must carry.
    case "$rel" in tests/*) continue ;; esac
    for token in $(grep -oE 'prompts/features/[A-Za-z0-9._-]+\.md' "$RULES_ROOT/$rel" | sort -u); do
        grep -qxF -- "$token" "$RULES_ROOT/MANIFEST" && continue
        # The feature index is required by convention in every project.
        case "$token" in prompts/features/00-*.md) continue ;; esac
        fail "$rel names $token, which is project-specific; a shared file may only name a shared feature"
    done
    count=$((count + 1))
done < "$RULES_ROOT/MANIFEST"

echo "08-shared-references: ok ($count shared files, no project-specific feature references)"
exit 0
