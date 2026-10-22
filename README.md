# 00-project-rules

The shared rules, versioned and pinned. This repository is the single place a
shared rule is authored; a project consumes a copy of a *tagged version* of it
and can prove, at any time, that the copy is unmodified.

It replaces the older practice of copying `prompts/` out of
`00-project-skeleton` into each project. That practice produced, by the time
this repository was created, **18 copies of `prompts/01-contract.md` in 8
different versions**, and 4–5 variants of the validator itself.

## The two-layer model

| Layer | Lives in | Changes | Verified by |
|---|---|---|---|
| **Shared** — contract, workflow, conventions, universal rules, capabilities, flavors, `how-to-write-*`, episode templates, the eval cases, the validator | this repository | a tagged version | `scripts/rules-check.sh` |
| **Local** — glossary, feature and task indexes, `features/`, `tasks/`, episodes, `README.md`, `TODO.md`, `Makefile`, scripts, site build | the project | in the project, freely | the project's own review |

The boundary rule: *if changing it in one project should change it everywhere,
it is shared; if a project may legitimately differ, it is local.*

## The contract with a project

Two scripts, one per direction.

**Write — `tools/rules-vendor.sh`** (here) copies the tagged version into a
project and records what it wrote in that project's `rules.lock`: the version
and a SHA-256 per file.

**Read — `scripts/rules-check.sh`** (vendored into every project) reads
`rules.lock` and fails when the project no longer matches it. It runs inside the
project's own `make test`, so drift is caught where it happens rather than by a
person remembering to look.

```
make test        # in 00-project-rules: suite + end-to-end against the skeleton
make release     # tag a version, after the gates

sh tools/rules-vendor.sh ~/work/some-project --dry-run   # preview an upgrade
sh tools/rules-vendor.sh ~/work/some-project             # perform it, in a task
```

Vendored files keep their project-relative paths (`prompts/01-contract.md`, not
`rules/prompts/01-contract.md`). This is deliberate. Every rule file, every
reference inside those files, and every existing test addresses them by that
path, so vendoring in place requires no edits anywhere, and the migration of an
existing project is a copy plus a lock rather than a rewrite.

## Customizing without forking

A project has exactly three moves. Anything else is drift.

1. **Parameterize.** If a shared rule needs a project value, the shared rule
   reads a named slot; the project supplies the value. Never reword a shared
   sentence to fit one project.
2. **Extend.** Add a local file that sorts after the shared ones
   (`prompts/10-project.md`) and states only what is new.
3. **Deviate.** Record an override in `prompts/20-deviations.md`, quoting the
   exact shared line it overrides:

   ```markdown
   ## DEVIATION: no published site

   - anchor: prompts/03-conventions.md
   - quote: <one complete line, verbatim from the anchor file>
   - reason: this project produces no site, so the page rules do not apply
   - review: 2027-01-01
   ```

   The quote is an anchor, not decoration. When a later version rewrites that
   line the anchor disappears, `rules-check` fails, and someone re-reviews the
   decision. A deviation therefore cannot silently outlive the rule it
   overrode — which is the failure mode of the older "append a section to the
   shared file" pattern.

`rules-check` also refuses a local file that restates shared text: a shared
sentence must exist once, in the shared file, so a version bump updates it in
one place.

## Adopting into an existing project

A first adoption is not a copy. The project's existing rule files differ from the
tagged version by however much they drifted, so the vendor refuses to overwrite
them until a human has looked:

1. `--dry-run` shows the delta. The vendor stops at the first file that differs
   and was never vendored, on purpose: only a human can tell drift (safe to
   replace) from a local customization (not safe).
2. Review the diff. A version that is `additive` to the previous version can
   still be `breaking` for the adopting project — that is the distinction the
   impact classes exist to keep straight, and the upgrade record states the
   project's impact, not the version's.
3. `--force` adopts. Files that were never vendored are replaced.
4. `sh scripts/rules-check.sh .` finds local files that restate shared text. Fix
   each as a pointer to the authoritative file: the glossary states terms, the
   contract states rules.
5. Enable the vendored validator. It will find real, pre-existing
   non-conformance: a project that never ran it is usually far from the
   contract. That work is a separate conformance task, not part of the pin.
6. `scripts/rules-conform.sh` is the tool for that work. It runs the validator
   and groups the findings by the action that fixes them, then names the files
   each action touches — so "twelve tasks need the same four sections" appears
   as one item, not sixty. `--verbose` lists every finding. It reports and never
   repairs: a tool that rewrote requirement identifiers would be inventing the
   requirements it claims to check.

Also: the vendored tests claim `tests/09-`, `10-`, and `13-`, so a project's own
pin test takes the lowest free slot in the `00`–`09` band.

**Declaring what a project has.** A real project carries files the shared list
cannot know about — a licence, a dependency manifest, its own research tree. It
declares them in a local rule file numbered after the shared ones, in a
`## Project Structure` section, one backticked path per line:

```markdown
## Project Structure

- `LICENSE` — the licence this project ships under.
- `pyproject.toml` — the dependency manifest.
- `research/` — background notes; a directory takes a trailing slash.
```

The validator reads only local rule files, never a vendored one, so a declaration
cannot be smuggled into a shared file. `tools/tests/05-declaration.sh` asserts
both halves: undeclared is still refused, declared is accepted. This is what the
contract already promised; until `2026-10-22.4` the validator implemented no such
thing, and a project carrying a `LICENSE` could not conform at all — which is
where the first canary attempt stopped.

## Versioning

`v<date>.<counter>`: `v2026-10-22.1`. `date` is `YYYY-MM-DD`; `counter` starts at
1 each day and is one past the highest tag already cut for that date. `VERSION`
holds the version without the leading `v`, and `make next` prints the next free
one.

This tag shape is **deliberately unlike a project's**. A project's release tag is
`v<date>-<branch>` (`prompts/capabilities/04-release-and-publishing.md`), because
a project releases an artifact *from a branch*. This repository has no branches
and never releases from one, so a branch cannot appear in its tags. The dot
before the counter is the visible difference, and it is what tells you at a
glance which kind of tag you are looking at — a library version or an artifact
release. Do not unify them.

### House rules

- **Branchless.** Exactly one branch exists, and a release is made on it. The
  gate refuses a second branch and refuses a detached HEAD, so there is nowhere
  for a feature branch to appear. Nothing in a tag, a commit, or a release record
  names a branch.
- **One release a day.** The counter is an escape hatch, not a cadence. The gate
  refuses a second tag on the same date unless `--same-day` is passed, which
  exists for the initial build-out and for a correction that cannot wait. Routine
  changes wait for the next day rather than spend a counter.
- **Stated impact.** The version says *when*, not *how much*, so the impact is
  declared and checked, never inferred. Every release record carries one of:

  | `Impact:` | Meaning for a consuming project |
  |---|---|
  | `initial` | the first release; nothing to differ from |
  | `breaking` | a rule reverses or authorization changes — re-run the affected evals before adopting |
  | `additive` | a new rule, capability, flavor, or eval case |
  | `wording` | changes no behavior; adopt without an eval run |
  | `internal` | no shared file changed at all |

  `internal` is checked rather than believed: the gate diffs `MANIFEST` against
  the previous tag and refuses the claim if any shared file moved. That stops a
  real rule change from being labelled as housekeeping and skipping eval
  scrutiny.

Every change that is not wording names, in `CHANGELOG.md`, the test or eval that
covers it. `make release` refuses to tag without a `releases/v<version>.md`
record, which is where the behavioral eval results go — the suite proves the
machine-checkable part, and only a person can record that the cases in `evals/`
were run and what they showed.

## What is deliberately not here

- **Scaffolding.** `00-project-skeleton` holds `AGENTS.md`, the glossary stub,
  the document indexes, `scripts/`, `site.in/`, the `Makefile`, and the
  project-side tests. Those are seeded once into a new project and never
  re-synced; they are not rules.
- **The local layer of any project**, including this repository's own targets.

`records/README.md` and `tests/README.md` *are* here: they define the record
forms and the test numbering bands, which are uniform across projects.

## Known state at v2026-10-22.1

v2026-10-22.1 is a faithful extraction: its files are byte-identical to what
`00-project-skeleton` already carried, so adopting it changes no rule. The
projects that were copied earlier are not automatically brought up to date — each
one is a separate upgrade, recorded, because the differences between the 8
variants are real (the oldest copies are missing the safety-precedence level and
the workflow-authorization wording entirely). See `releases/v2026-10-22.1.md`.
