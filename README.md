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

## Versioning

`v<date>.<counter>` — the same shape the projects use for a release, with a dot
before the counter: `v2026-10-22.1`, then `v2026-10-22.2` for a second release
on the same day. `date` is `YYYY-MM-DD`; `counter` starts at 1 each day and is
one past the highest tag already cut for that date. `VERSION` holds the version
without the leading `v`, and `make next` prints the next free one.

A date and a counter say *when*, not *how much*, so the version string carries
no compatibility signal. That signal is mandatory elsewhere and is not inferred:

- Every release record declares `Impact: initial | breaking | additive |
  wording` on its own line, and `make release` refuses to tag without it.
- **breaking** — a rule reverses, or the scope of what a task authorizes
  changes. A project re-runs the affected evals before adopting it.
- **additive** — a new rule, capability, flavor, or eval case.
- **wording** — changes no behavior; a project may adopt it without an eval run.

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
