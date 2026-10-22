# Agent Entry Point

This file is the entry point for a coding agent working in this repository.
It is orientation only: it points at the authoritative files and defines no
rule of its own.

This repository owns the **shared** rules. It is not a project, and it does not
hold a project's local layer (glossary, feature and task indexes, `README.md`,
`TODO.md`, site build). Those live in `00-project-skeleton` and in each project.

## Read First

- `README.md` — what this repository is, what is shared, and the two halves of
  the contract with a project (`rules-vendor.sh`, `rules-check.sh`).
- `MANIFEST` — the authoritative list of files this repository owns and
  vendors. A file in `prompts/`, `evals/`, or `tests/` that is not here is a
  defect; `tools/tests/00-manifest.sh` fails on one.
- `CHANGELOG.md` — why the current version differs from the last.

## The Invariants

- **`MANIFEST` is the only list of shared files.** Adding a shared file means
  editing `MANIFEST` in the same change.
- **A shared file is byte-identical in every project that pins this version.**
  It is copied by a tool, never edited in a project. A project customizes by
  extending (a local file that sorts after the shared one) or by recording a
  deviation in its `prompts/20-deviations.md`.
- **A rule change ships with an eval or a test.** `tests/` holds the
  machine-checkable part and `evals/` the behavioral part; `CHANGELOG.md` names
  which one a version moved.
- **A release is a tag.** A project pins a tag, so a version that was never
  tagged cannot be adopted.
- **A version is `<date>.<counter>`.** `VERSION` holds `2026-10-22.1`; the tag
  adds the `v`, and the counter is one past the highest tag for that date.
  `make next` prints the next free one. The string says *when*, not *how much*,
  so the impact is declared, never inferred: each release record carries
  `Impact: initial|breaking|additive|wording` and `make release` requires it.

## Commands

- `make test` — `tools/rules-test.sh`: this repository's tests, including the
  end-to-end check that vendors the current version into `00-project-skeleton`
  and runs the shared validator there.
- `make release` — `tools/rules-release.sh`: gates on a clean tree, a passing
  suite, a `releases/v<version>.md` record, and an existing changelog entry,
  then creates the annotated tag.

## Boundaries

- `tests/09-prompt-contract.sh`, `tests/10-prompt-validator.sh`, and
  `tests/13-corpus-coverage.sh` validate a *complete project*. They cannot run
  against this repository, which holds only the shared layer. Do not "fix" them
  to run here; `tools/tests/04-skeleton-integration.sh` runs them where they
  belong.
- This repository's own tests live in `tools/tests/`, not `tests/`, so that
  `tests/` stays exactly the vendored set.
