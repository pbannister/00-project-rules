#!/bin/sh
#
# rules-eval-task.sh: print the task text of an eval case, and nothing else.
#
# Read-only. Never reads standard input.
#
# Usage: rules-eval-task.sh CASE_FILE [--note]
#
# Why this exists: an eval case is not a task. It is a task, the behavior it
# should produce, the signals that mean it failed, and the scoring rubric. Only
# the task may be handed to the agent under test; handing the rest measures
# whether the agent can read its own answer key.
#
# Two traps this closes, both found by trying to extract a task by hand:
#
#   1. The task is wrapped in a fenced block that itself opens with
#      "## TASK-DESCRIPTION". Taking "the text up to the next ## heading" stops
#      at that line and yields the string "```text" instead of a task.
#   2. Prose after the closing fence belongs to the case, not the task. In one
#      case it states which test the task contradicts -- exactly the thing the
#      agent must not be told.
#
# So: the fenced block is the task, and anything outside it in the same section
# is a note to the operator. --note prints that note to standard error, clearly
# labelled, for the person scoring.
set -eu
LC_ALL=C
export LC_ALL

usage() {
    echo 'usage: rules-eval-task.sh CASE_FILE [--note]' >&2
    exit 2
}

file_case=""
show_note=0
for arg in "$@"; do
    case "$arg" in
        --note) show_note=1 ;;
        -h|--help) usage ;;
        -*) usage ;;
        *)
            [ -z "$file_case" ] || usage
            file_case=$arg
            ;;
    esac
done

[ -n "$file_case" ] || usage
[ -f "$file_case" ] || {
    echo "rules-eval-task: no such case file: $file_case" >&2
    exit 2
}

command -v python3 >/dev/null 2>&1 || {
    echo 'rules-eval-task: python3 is required' >&2
    exit 2
}

python3 - "$file_case" "$show_note" <<'PY'
import re
import sys

path, show_note = sys.argv[1], sys.argv[2] == "1"
HEADING = "## Task given to the agent"

lines = open(path, encoding="utf-8").read().splitlines()
start = next((i for i, line in enumerate(lines) if line.strip() == HEADING), None)
if start is None:
    print(f"rules-eval-task: {path} has no '{HEADING}' section", file=sys.stderr)
    sys.exit(2)

# The section ends at the next level-two heading that is not inside a fence.
body, in_fence = [], False
for line in lines[start + 1:]:
    if line.lstrip().startswith("```"):
        in_fence = not in_fence
        body.append(line)
        continue
    if not in_fence and re.match(r"^## ", line):
        break
    body.append(line)

task, note, in_task = [], [], False
saw_fence = False
for line in body:
    if line.lstrip().startswith("```"):
        in_task = not in_task
        saw_fence = True
        continue
    (task if in_task else note).append(line)

task_text = "\n".join(task).strip()
note_text = "\n".join(line for line in note if line.strip()).strip()

if not saw_fence:
    # No fence: the section is the task, but say so, because a note cannot then
    # be told apart from the task.
    task_text = "\n".join(body).strip()
    print(f"rules-eval-task: {path}: no fenced block; printed the whole section -- "
          f"check it for operator notes before handing it over", file=sys.stderr)
elif not task_text:
    print(f"rules-eval-task: {path}: the fenced block is empty", file=sys.stderr)
    sys.exit(2)

if show_note:
    if note_text:
        print("rules-eval-task: note to the operator, NOT to the agent:", file=sys.stderr)
        for line in note_text.splitlines():
            print(f"  {line}", file=sys.stderr)
    else:
        print("rules-eval-task: no operator note outside the fence", file=sys.stderr)

print(task_text)
PY
