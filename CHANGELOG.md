# Changelog

All notable changes to the shared rules are recorded here. The format follows
Keep a Changelog.

A version is `<date>.<counter>`: `2026-10-22.1`, then `.2` for a second release
on the same day, as the other projects tag releases. A date and a counter say
*when*, not *how much*, so every entry states its **impact** and every entry
that is not wording names the test or eval that covers it. The impact classes
and what a project must do about each are in `README.md`.

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
