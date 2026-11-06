# Object index — where each object family lives

Status: analysis. Written after the object model was derived from the prompt
corpus in `08-language-krank` (`dataflow.in/object-model.json`,
`documents/12-object-model.md`).

## The question

Does the object model suggest a directory organization for `prompts/`?

## The current axes

The tree is organized by **authority and applicability**, the two axes the
contract's authority table uses:

- root — the contract, the workflow, and the conventions (always loaded);
- `common/` — global failure-prevention rules (always loaded);
- `capabilities/` — optional conventions, loaded only for a task that touches one;
- `flavors/` — language naming and formatting conventions;
- `features/` — feature requirements (a precedence class);
- `episodes/` — episode templates;
- `how-to-write-*` — authoring guides, which are conventions for the human.

The object model is a **content** axis: what a file talks about. It cuts across
these directories.

## Where the objects live

| Object family | Files |
|---|---|
| Governance: rule, precedence, override, feature, requirement | `01-contract.md`, `features/`, `how-to-write-features.md` |
| Work: task, operation, path, plan, acceptance, verification | `01-contract.md`, `02-workflow.md`, `how-to-write-tasks.md` |
| Episodes: episode, phase | `episodes/`, `how-to-write-episodes.md` |
| Records and release: record, incident, commit, branch, tag, version, release, changelog, lock | `02-workflow.md`, `capabilities/02-version-information.md`, `capabilities/04-release-and-publishing.md`, `records/README.md` |
| Artifacts and pipeline: document, stage, work_product, dataset, provenance | `capabilities/01-generated-documentation.md`, `capabilities/03-generated-data-products.md`, `capabilities/05-pinned-dependencies.md` |
| Execution: agent, sandbox, boundary, credential, session, goal, delegation, failure, layer | `capabilities/06-execution-boundary.md` through `09-failure-attribution.md` |
| Paths and pages: path, directory, page, page_set, nav, dashboard | `03-conventions.md`, `flavors/01-semantic-sort-naming.md`, `features/02-project-pages.md` |
| Discourse: ambiguity, assumption, delta, untrusted content, privacy, risk | `common/01-universal-rules.md`, `01-contract.md` |
| No object: glossary, orientation | `common/03-glossary.md`, `README.md` |

## Verdict: an index, not a reorganization

- The contract is multi-object by design (governance, work, paths, output,
  safety); splitting it by object would fragment the authority the contract
  exists to establish.
- The authoritative-file rule makes one file the owner of a precedence class;
  the first question a reader asks is "which file governs?", not "where are
  paths defined?".
- A move is a breaking change: `MANIFEST`, `rules.lock` digests, every project's
  vendored paths, every reference, and the loader depend on the path.
- The navigation benefit is delivered by an object-first index (this document),
  which is additive.

## The one split the model does suggest

Status: deferred 2026-11-06. Tracked in `00-project-skeleton/TODO.md`.

`capabilities/` mixes two families:

- artifacts and pipeline: `01` generated documentation, `02` version, `03` data
  products, `04` release, `05` pinned dependencies;
- execution: `06` boundary, `07` session, `08` delegation, `09` failure.

If a major version is planned, split it into `capabilities/artifacts/` and
`capabilities/execution/`. That is the only directory change the content axis
argues for, and it is a migration, not a rename: update `MANIFEST`, the authority
table, the loader list, every reference, and each project's `rules.lock` in one
release.

## Recommendation

1. Keep the current directories.
2. Keep this index current as files and objects change.
3. Split `capabilities/` only when a major version is already being cut for
   another reason; the readability gain does not pay for the migration alone.
4. Do not move the glossary: it is descriptive, but the workflow loads it as a
   reference, and `prompts/` is where the loader looks.
