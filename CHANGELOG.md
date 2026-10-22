# Changelog

All notable changes to the shared rules are recorded here. The format follows
Keep a Changelog.

A version is `<date>.<counter>`: `2026-10-22.1`, then `.2` only for the initial
build-out or a correction — one release a day is the aim. The shape is
deliberately unlike a project's `v<date>-<branch>`, because this repository has no
branches. A date and a counter say *when*, not *how much*, so every entry states
its **impact**, and every entry that is not wording or internal names the test or
eval that covers it. The impact classes are in `README.md`.

## [2026-10-22.14] - 2026-10-22

Impact: wording — one sentence in the conventions; no rule changes meaning.

### Changed

- `prompts/03-conventions.md` no longer tells a project to keep a fork of shared
  text in sync with `scripts/skeleton-diff.sh`. That script is superseded by
  `scripts/rules-check.sh`, which fails on an edited vendored file rather than
  reporting drift after the fact. The advice now describes what the system
  actually permits: extend in a local file, or record a deviation.

### Removed

- The last reference to `scripts/skeleton-diff.sh` from the shared set. The script
  is a template artifact, and projects carrying it delete it themselves; leaving a
  shared rule pointing at a script some projects no longer have is precisely the
  dangling-instruction defect this library exists to prevent.

## [2026-10-22.13] - 2026-10-22

Impact: additive — a project may now extend the test helpers; nothing else moves.

### Fixed

- `tests/lib/test_helpers.sh` is vendored, so a project that had extended it lost
  its additions the moment it adopted: `gnome-appimage-integration` carried a
  79-line helper, the vendor replaced it with the 35-line shared one, and nineteen
  tests failed at once. The shared helper now sources an optional, project-owned
  `tests/lib/project_helpers.sh`, so extensions survive every upgrade.

### Added

- `tests/README.md` documents the extension point and the four shared functions,
  including `skip_unless_tool`, which the vendored tests rely on.

## [2026-10-22.12] - 2026-10-22

Impact: additive — the adversarial corpus now runs in projects that do not carry
the skeleton's local corpus.

### Fixed

- `tests/10-prompt-validator.sh` mutated `prompts/features/01-site-build.md` and
  `prompts/tasks/01-site-build-implement.md`, which are skeleton files: a project
  without them failed all 54 cases with `sed: can't read`, for a reason unrelated
  to the checks. The corpus now synthesizes its own fixture every time, under
  reserved numbers (`89-`) and reserved identifiers (`FIXTURE-R`), so it neither
  collides with a project's corpus nor drifts with it.
- Two cases that relied on `02-project-pages.md` depending on a skeleton feature
  now add that dependency to the fixture copy themselves, which is where a
  mutation belongs.

### Note

This is the fifth instance of one defect, and the guard added in `2026-10-22.11`
did not catch it: `tests/` was exempted because its fixture paths look like
references. The exemption was right for generated fixtures and wrong for a test
that hardcodes a project file. The corpus now has no such paths.

## [2026-10-22.11] - 2026-10-22

Impact: wording — one dependency edge removed from a shared feature, and a guard.

### Fixed

- `prompts/features/02-project-pages.md` depended on `01-site-build.md`, a
  skeleton feature, so every project without that feature failed check 10 on a
  locked file. The dependency is now `None`; a project that models its site build
  as a feature references it from the task.
- Eval cases `01` and `05` named `01-site-build.md` too. They now name
  `02-project-pages.md`, which ships with the rules.

### Added

- `tools/tests/08-shared-references.sh`: no shared file may name a
  project-specific feature. This is the crisp half of a defect that has now
  recurred four times — a shared artifact assuming the template's inventory — and
  it is the first guard that catches it before a project does.

## [2026-10-22.10] - 2026-10-22

Impact: wording — two examples and a reporting tool; no rule changed.

### Fixed

- `prompts/how-to-write-tasks.md` and `prompts/episodes/01-episode-template.md`
  used `prompts/features/01-site-build.md` as an illustrative example. That file
  is a skeleton feature, not a shared one, and the validator resolves every
  backticked path, so any project without it failed check 2 on two shared files
  it could not edit. The example is now a placeholder, which check 2 ignores by
  design.

### Added

- `rules-conform` gained two categories found by the same pre-flight: feature
  format (a missing Purpose, Requirements, Behavior, or Dependencies section) and
  numbering (two features claiming the same number). Both previously fell through
  to "other", which told the reader nothing.

## [2026-10-22.9] - 2026-10-22

Impact: additive — an adopter must run `rules-vendor.sh --prune` once and update
local references to the renamed file.

### Changed

- `prompts/common/02-universal-rules.md` is now
  `prompts/common/01-universal-rules.md`, filling the slot left when
  `01-requirements.md` was retired. Content is unchanged; every reference in the
  shared set is updated. A project's local files may still name the old path --
  the glossary typically does, and the validator reports it as an unresolved
  reference.

### Added

- `tools/rules-vendor.sh --prune` removes a file the project's lock named but the
  current version no longer carries. Without it a rename leaves two copies of a
  rule set behind, and the validator reports the leftover as a duplicate. The
  flag is opt-in: without it the leftover is reported and never deleted.
- Each eval case declares `## Requires`, and `scripts/rules-eval-task.sh` refuses
  a case whose prerequisites the project does not carry. A run against a missing
  prop is not a failure; it is not a run.
- `documents/eval-portability.md` scopes the rewrite that follows: five of six
  cases operate on skeleton-only files, so most adopters can run one.

## [2026-10-22.8] - 2026-10-22

Impact: additive — a project gains the eval method and an extractor; no rule
changes.

### Added

- `evals/README.md` joins the shared set. It was never vendored, so adopting
  projects received six eval cases and no instructions for running them. Every
  project that adopted before this version has cases it cannot use.
- `scripts/rules-eval-task.sh` prints a case's task text and nothing else.
  `--note` prints the operator note to standard error, labelled.
- `tools/tests/07-eval-task.sh` proves the extraction keeps the task, drops the
  note, the rubric and the expectation, and refuses a case with no task section.

### Fixed

- The method now states the two traps found by trying to extract a task by hand:
  the task is a fenced block that opens with `## TASK-DESCRIPTION`, so a naive
  slice returns ```` ```text ````; and prose after the fence is a note to the
  operator, which in one case names the test the task contradicts.
- The method now requires auditing that the agent did not read `evals/` during
  the run, and explains why the directory cannot simply be removed: `rules-check`
  verifies every vendored file.

## [2026-10-22.7] - 2026-10-22

Impact: additive — a project gains a reporting tool; no rule changes.

### Added

- `scripts/rules-conform.sh` runs the validator and groups its findings by the
  action that fixes them, naming the files each action touches, with `--verbose`
  for every finding. Read-only: it reports, it never repairs.
- `tools/tests/06-conform.sh` proves a clean project is quiet, three failures in
  three places collapse to three actions, verbose mode keeps the evidence, the
  reporter modifies no file, and a project without the validator exits 2.

## [2026-10-22.6] - 2026-10-22

Impact: wording — no instruction an agent follows changed.

### Fixed

- `tests/10-prompt-validator.sh` builds each fixture from `git ls-files` instead
  of copying the working tree. The validator reads only tracked files, so
  untracked bytes were pure cost: on a project with 3.9 GB of ignored research
  evidence, 54 cases copied about 210 GB per run. The suite went from ~10 minutes
  to 6.4 seconds, with the same 54 rejections and 6 acceptances.

## [2026-10-22.5] - 2026-10-22

Impact: wording — no instruction an agent follows changed.

### Fixed

- `tests/10-prompt-validator.sh` force-adds the fixture it creates in three
  cases. A project may ignore any of those names — the canary ignores
  `config.json` because it holds a device password — and an ignored fixture made
  a rejection case pass silently, which is a test failing green.

## [2026-10-22.4] - 2026-10-22

Impact: additive — a project may now declare its own root files; a project that
declares nothing behaves exactly as before.

The canary stopped here: the contract promised projects could declare extra root
files, and the validator implemented no such declaration, so any project with a
`LICENSE`, a `pyproject.toml`, or its own `research/` failed the structure checks
outright. `LICENSE` alone blocked essentially every real project.

### Added

- `tests/09-prompt-contract.sh` reads `## Project Structure` from local rule
  files numbered after the shared ones (`prompts/1x-…`), and treats each
  backticked path as permitted by checks 9 and 14. Shared files are never read,
  so a declaration cannot be smuggled into a vendored file.
- `prompts/01-contract.md` section 7 states where the declaration goes and its
  shape.
- `tools/tests/05-declaration.sh` asserts both halves: undeclared files and
  directories are still refused, declared ones are accepted, and a renamed
  heading is not a declaration.

## [2026-10-22.3] - 2026-10-22

Impact: additive — a new permitted root file, and no rule reverses.

Found by pinning the skeleton, which is what a pilot is for: the validator
refused `rules.lock` at the project root, because contract section 7 enumerates
the canonical root files and the lock was not among them. Pinning produces that
file in every adopting project, so it belongs in the list rather than in each
project's local declaration.

### Added

- `prompts/01-contract.md` section 7: `rules.lock` is a canonical root-level
  file — the one root file a project must not edit.
- `tools/tests/04-skeleton-integration.sh` asserts faithfulness only when the
  skeleton already pins the version under test. Requiring it unconditionally
  deadlocks a release: the release that changes a shared rule is cut before the
  template adopts it.

## [2026-10-22.2] - 2026-10-22

Impact: internal — no shared file changed; only the release gate and the
documentation did.

### Added

- The release gate enforces the house rules instead of trusting memory: exactly
  one branch with the release made on it, one release per date unless
  `--same-day` is passed, and an impact claim that `internal` cannot fake.
- `Impact: internal`, for a release that touches no shared file. It is checked by
  diffing `MANIFEST` against the previous tag, so a real rule change cannot be
  labelled housekeeping in order to skip eval scrutiny.
- `make next`, which prints the next free version, and `make release-same-day`,
  the explicit exception.

## [2026-10-22.1] - 2026-10-22

Impact: initial — the first release, with no earlier version to differ from.

### Added

- The shared rule set as a versioned, tagged repository, extracted from
  `00-project-skeleton`: `prompts/` (contract, workflow, conventions, universal
  rules, nine capability conventions, two flavors, four `how-to-write-*` files,
  two episode templates, the project-pages feature), `evals/` (six cases),
  `tests/` (the contract validator, its adversarial corpus, corpus coverage,
  and the shared helpers), plus `records/README.md` and `tests/README.md`.
- `MANIFEST`, the authoritative list of shared files, with
  `tools/tests/00-manifest.sh` failing when a file in the shared tree is
  missing from it or an entry names no file.
- `tools/rules-vendor.sh` (write) and `scripts/rules-check.sh` (read): a
  SHA-256 lock per project, verification in the project's own `make test`, a
  refusal to overwrite a locally edited vendored file, and deviation anchors
  that expire when the rule they overrode is rewritten.
- `tools/rules-release.sh`, which gates a version on a clean tree, a passing
  suite, a changelog entry, and a `releases/v<version>.md` record before
  tagging.

### Changed

- Nothing. v2026-10-22.1 is a faithful extraction: every vendored file is byte-
  identical to the file `00-project-skeleton` already carried, which
  `tools/tests/04-skeleton-integration.sh` asserts by vendoring into a copy of
  the skeleton and requiring `0 add, 0 update`.

### Notes

- Downstream projects are not migrated by this release. At extraction there were
  18 copies of `01-contract.md` in 8 versions across 16 projects; reconciling
  each is a recorded upgrade, not a bulk copy.
