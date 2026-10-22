#!/bin/sh
#
# Project structure declarations.
#
# The contract lets a project declare extra root files and directories, because a
# real project has a LICENSE, a pyproject.toml, or a research/ tree that the
# shared list cannot know about. Until this existed, such a project could never
# conform: the root-file and top-level-directory checks rejected it outright.
#
# Two properties matter, and this test asserts both:
#   1. Without a declaration, an extra root file or directory is still refused.
#      The declaration must be a deliberate statement, not a hole.
#   2. With a declaration in a local rule file, the same project validates.
#
# The fixture is a copy of 00-project-skeleton with a git repository, because the
# root-structure checks read `git ls-files`.
set -eu

DIRECTORY_SCRIPT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
RULES_ROOT=$(CDPATH= cd -- "$DIRECTORY_SCRIPT/../.." && pwd)
SKELETON=${SKELETON_DIR:-"$RULES_ROOT/../00-project-skeleton"}

if [ ! -d "$SKELETON" ]; then
    echo "SKIP: skeleton not available at $SKELETON"
    exit 0
fi

fail() {
    echo "05-declaration: $1" >&2
    exit 1
}

DIRECTORY_TEST=$(mktemp -d)
trap 'rm -rf "$DIRECTORY_TEST"' EXIT HUP INT TERM
DIRECTORY_ROOT="$DIRECTORY_TEST/project"

mkdir -p "$DIRECTORY_ROOT"
cp -R "$SKELETON/." "$DIRECTORY_ROOT/"
rm -rf "$DIRECTORY_ROOT/.git"

# The project's own state: a licence, a dependency manifest, and a research tree.
printf 'MIT\n' > "$DIRECTORY_ROOT/LICENSE"
printf '[project]\nname = "canary"\n' > "$DIRECTORY_ROOT/pyproject.toml"
mkdir -p "$DIRECTORY_ROOT/research"
printf 'notes\n' > "$DIRECTORY_ROOT/research/notes.md"

git -C "$DIRECTORY_ROOT" init -q
git -C "$DIRECTORY_ROOT" add -A

# 1. Undeclared, the extras are refused -- for the right reasons.
if output=$(sh "$RULES_ROOT/tests/09-prompt-contract.sh" "$DIRECTORY_ROOT" 2>&1); then
    fail 'an undeclared root file and directory were accepted'
fi
printf '%s\n' "$output" | grep -qF 'root file is not permitted by contract section 7: LICENSE' \
    || fail "the undeclared root file was not refused: $output"
printf '%s\n' "$output" | grep -qF 'top-level directory is not permitted by contract section 7: research/' \
    || fail "the undeclared directory was not refused: $output"
printf '%s\n' "$output" | grep -qF 'root file is not permitted by contract section 7: pyproject.toml' \
    || fail "the second undeclared root file was not refused: $output"

# 2. Declared in a local rule file numbered after the shared ones, they pass.
cat > "$DIRECTORY_ROOT/prompts/10-project.md" <<'EOF'
# Project Structure

This project keeps three things the shared rules cannot know about.

## Project Structure

- `LICENSE` — the licence this project ships under.
- `pyproject.toml` — the dependency manifest.
- `research/` — background notes that ship with the project.
EOF
git -C "$DIRECTORY_ROOT" add -A

if ! output=$(sh "$RULES_ROOT/tests/09-prompt-contract.sh" "$DIRECTORY_ROOT" 2>&1); then
    printf '%s\n' "$output" | sed 's/^/05-declaration: /' >&2
    fail 'a declared root file or directory was still refused'
fi

# 3. The section heading is the trigger and must be exact. A near-miss heading is
#    not a declaration, so the project silently falls back to being refused --
#    which is visible, rather than silently accepted.
sed -i 's/^## Project Structure$/## Project Structure (shared)/' \
    "$DIRECTORY_ROOT/prompts/10-project.md"
git -C "$DIRECTORY_ROOT" add -A
if output=$(sh "$RULES_ROOT/tests/09-prompt-contract.sh" "$DIRECTORY_ROOT" 2>&1); then
    fail 'a declaration was honoured after the section heading was renamed'
fi
printf '%s\n' "$output" | grep -qF 'root file is not permitted' \
    || fail "the renamed section was not refused for the right reason: $output"

echo '05-declaration: ok'
exit 0
