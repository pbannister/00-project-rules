#!/bin/sh
#
# The local layer: extending is allowed, restating is not, deviations expire.
#
# A project may add a local prompt file. It may not copy a shared sentence into
# it, because the copy stops tracking the shared file. A project may override a
# shared rule, but only against a quote of the text it overrode, so a later
# version that rewrites that text invalidates the override instead of silently
# inheriting a stale decision.
set -eu

DIRECTORY_SCRIPT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
RULES_ROOT=$(CDPATH= cd -- "$DIRECTORY_SCRIPT/../.." && pwd)

fail() {
    echo "03-overlay: $1" >&2
    exit 1
}

DIRECTORY_TEST=$(mktemp -d)
trap 'rm -rf "$DIRECTORY_TEST"' EXIT HUP INT TERM

sh "$RULES_ROOT/tools/rules-vendor.sh" "$DIRECTORY_TEST" >/dev/null 2>&1 \
    || fail 'vendor failed while building the fixture'

# A distinctive shared line, taken from the source of truth rather than typed
# here, so this test keeps working when the sentence is reworded.
shared_line=$(awk 'length($0) >= 40 {print; exit}' "$DIRECTORY_TEST/prompts/03-conventions.md")
[ -n "$shared_line" ] || fail 'no usable shared line in prompts/03-conventions.md'

# 1. A local file that merely extends the rules is accepted.
cat > "$DIRECTORY_TEST/prompts/10-project.md" <<'EOF'
# Project Conventions

This project adds one rule of its own.
EOF
output=$(sh "$DIRECTORY_TEST/scripts/rules-check.sh" "$DIRECTORY_TEST") \
    || fail "an ordinary local file was rejected: $output"

# 2. A local file that copies a shared sentence is refused, and named.
printf '%s\n' "$shared_line" >> "$DIRECTORY_TEST/prompts/10-project.md"
if output=$(sh "$DIRECTORY_TEST/scripts/rules-check.sh" "$DIRECTORY_TEST" 2>&1); then
    fail 'a local file restating shared text was accepted'
fi
printf '%s\n' "$output" | grep -qF 'restates shared rule text' \
    || fail "the restatement was not explained: $output"
printf '%s\n' "$output" | grep -qF 'prompts/10-project.md' \
    || fail "the restatement did not name the file: $output"

# 3. A recorded deviation anchored on live text is accepted.
cat > "$DIRECTORY_TEST/prompts/10-project.md" <<'EOF'
# Project Conventions

This project adds one rule of its own.
EOF
cat > "$DIRECTORY_TEST/prompts/20-deviations.md" <<EOF
## DEVIATION: no published site

- anchor: prompts/03-conventions.md
- quote: $shared_line
- reason: this project produces no site, so the page rules do not apply
- review: 2027-01-01
EOF
output=$(sh "$DIRECTORY_TEST/scripts/rules-check.sh" "$DIRECTORY_TEST") \
    || fail "a valid deviation was rejected: $output"
printf '%s\n' "$output" | grep -qF '1 deviation' || fail "the deviation was not counted: $output"

# 4. A deviation whose anchor text is gone is stale, and the check says so.
sed -i 's/^- quote: .*/- quote: text that appears in no pinned file at all/' \
    "$DIRECTORY_TEST/prompts/20-deviations.md"
if output=$(sh "$DIRECTORY_TEST/scripts/rules-check.sh" "$DIRECTORY_TEST" 2>&1); then
    fail 'a stale deviation anchor was accepted'
fi
printf '%s\n' "$output" | grep -qF 'anchor is stale' \
    || fail "the stale anchor was not explained: $output"

# 5. A deviation may not anchor a file that is not pinned, which would make the
#    anchor unfalsifiable.
cat > "$DIRECTORY_TEST/prompts/20-deviations.md" <<'EOF'
## DEVIATION: anchoring a local file

- anchor: prompts/10-project.md
- quote: This project adds one rule of its own.
- reason: an anchor must be checkable against a pinned version
- review: 2027-01-01
EOF
if output=$(sh "$DIRECTORY_TEST/scripts/rules-check.sh" "$DIRECTORY_TEST" 2>&1); then
    fail 'a deviation anchored on a local file was accepted'
fi
printf '%s\n' "$output" | grep -qF 'not a pinned shared file' \
    || fail "the unpinned anchor was not explained: $output"

echo '03-overlay: ok'
exit 0
