# Eval portability — scope

Status: scoped, not started. Written after an eval run was attempted in
`09-language-elseon` and produced no data.

## The finding

An eval case is a task plus a rubric, and most of the tasks operate on a real
project file. The cases were written against `00-project-skeleton`'s inventory,
and they were then shipped to every adopting project as shared files. A project
that did not keep that inventory cannot run them.

| Case | Prop it operates on | Present in the skeleton | Projects carrying it |
|---|---|---|---|
| `01-malformed-task-refusal` | `scripts/site-verify.sh` | no — **absence is the subject** | all (portable) |
| `02-scope-discipline` | `scripts/status.sh` | yes | 2 of 9 surveyed |
| `03-verification-honesty` | `scripts/status.sh`, `tests/12-status.sh` | yes | 2 of 9 |
| `04-prompt-injection` | `scripts/status.sh` | yes | 2 of 9 |
| `05-acceptance-remains-human` | `scripts/status.sh` | yes | 2 of 9 |
| `06-credential-boundary` | `scripts/site-state-fetch.sh` | yes | 4 of 9 |

So a typical adopter receives six cases and can validly run **one**.

`2026-10-22.9` makes this visible rather than silent: each case declares
`## Requires`, and `scripts/rules-eval-task.sh` refuses a case whose
prerequisites are absent. That prevents a wasted session, but it does not give
the project a behavioral bar.

## Why it matters

The eval set is the only behavioral evidence in the system. Tests prove the
prompt artifacts are internally consistent; they cannot show how a model behaves
under them. If the cases only run on the template, then the projects that ship —
the diverged ones — are exactly the ones with no behavioral check, and the
adoption's `breaking` classification stays unverified there.

## Options

**A. Rewrite the props against files every project has.** `prompts/`, `AGENTS.md`,
`TODO.md`, `records/`. Most cases test prompt-governed behavior — scope, refusal,
honesty, injection resistance, acceptance — and the prop is only a stage.
Cost: rewriting the task text of roughly four cases, and losing realism in two
where the prop carries the point (see below).

**B. Keep the props, declare prerequisites.** Done in `.9`. Cost: already paid.
Consequence: the bar stays where the inventory survives.

**C. Let each project write its own cases.** Cost: repeated work and a
single-source violation, since the rules are shared and the bar should be too.

## Recommendation

A hybrid, by what each case actually tests:

- **Portable now (rewrite in A):** `02`, `04`, `05` — the prop is incidental.
- **Conditional (keep, declared):** `03` depends on contradicting a *real* test,
  which is the mechanism; `06` needs a script that handles a credential, and a
  synthetic stand-in would test less.
- **Already portable:** `01`.

That yields four cases runnable anywhere and two that declare their dependence.

## Decisions needed before starting

1. Accept the hybrid, or require all six to be portable?
2. For `06`: is a synthetic credential-handling script acceptable as the prop, or
   must it be a real one?
3. Should an adoption be considered verified only when at least the portable set
   has been run, and does that become a gate in the adoption task rather than a
   project TODO item?

## Not in scope

Rewriting the cases, running any eval, and changing the `evals/` classification.
