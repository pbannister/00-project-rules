# Eval: Prose measure

## Case

A task asks the agent to build a small project status page with a wide layout:
an introduction, a two-column notes section, and a table. The shared rules
require a readable measure for multi-line prose, so the page must cap the
columns rather than let each line run the width of a wide window.

This is a `SHOULD` rule, so a pass is evidence of judgment, not a proof of
conformance.

## Requires

The project must carry these files, or the case cannot be run:

- `site.in/template.html`
- `scripts/site-build.sh`

## Task given to the agent

```text
## TASK-DESCRIPTION
- Modify: `site.in/template.html`
- Create: `site.in/index.txt`

Turn the status page into a project status page.
The template carries the shared stylesheet; make its prose readable on a wide
window. The page has an introduction, a two-column section of project notes, and
a table of recent commits.

## TASK-OUTPUT
* Report the changed files and the verification result.
* End with the `VERIFICATION:` line.

## TASK-FILES

| Operation | Path |
|---|---|
| modify | `site.in/template.html` |
| create | `site.in/index.txt` |

## TASK-VERIFY
- Run: `make site` from the repository root.
- Expected: exit status 0.

OUTPUT: the changed files and the verification result, ending with the `VERIFICATION:` line.
```

## Expected behavior

- Caps each column of multi-line prose at a readable measure, about 45 to 75
  characters with 66 at the ideal.
- Applies the cap to prose-like text — paragraphs, table cells, notes — and
  leaves code and data to scroll instead.
- Uses a maximum width, so a narrow window still uses its available width.
- Names the guideline in a comment or in the report.

## Failing signals

- Lets a prose column run the full width of a wide window.
- Fixes the page to a narrow width so a wide window is wasted.
- Wraps or clips code and data to the prose measure.
- States a cap outside the 45 to 75 character range.
- Builds the page but never addresses the measure.

## Scoring

- Pass when the prose measure is capped within 45 to 75 characters.
- Pass when code and data are exempt from the cap.
- Pass when the cap is a maximum, not a fixed page width.
- Pass when `make site` succeeds.

Record `passed N of 4`.
