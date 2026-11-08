# Feature: Formal Rules Cycle

## Purpose

A project that turns prose into formal rules runs one cycle. The model reads the
prose and proposes an object model and rules; the human reviews the proposals and
may revise the prose; the approved object model generates the rule set and a
reduced form of the prose; and later work uses the reduced prose and the rules
instead of rereading the full text. The cycle keeps the model's guesses overt and
the human's judgment authoritative. The reference project implements the engine as
krank; the cycle itself is engine-neutral.

## Requirements

- `FORMAL-RULES-R001` — The model must propose an object and a rule with an explicit guess, evidence, and a rationale, and must name the prose line each rests on.
- `FORMAL-RULES-R002` — A proposal must carry a human status; an excluded term is kept with its reason rather than dropped, so a later pass does not re-propose it.
- `FORMAL-RULES-R003` — The human must approve the object model before rule generation; only a confirmed object may appear in a rule, and a rule that names an unconfirmed type is refused.
- `FORMAL-RULES-R004` — The approved object model must drive rule generation; the rule set and the reduced prose must be generated into one tree, with a manifest and a source digest per entry.
- `FORMAL-RULES-R005` — The generated tree is derived output; it is regenerated from the prose and the approved rules, and never edited by hand.
- `FORMAL-RULES-R006` — Later iterations must read the reduced prose and the rule set, run the rules against the project's facts with a deterministic engine, and report the decision.
- `FORMAL-RULES-R007` — A rule change is exceptional in a mature project; a rule change ships with the test or eval that covers it.
- `FORMAL-RULES-R008` — No interface may reimplement the cycle; a surface renders the shared object model, the catalog, the generated tree, and the check.

## Behavior

- A proposal is not an object until a human confirms it; the interface shows the evidence and rationale beside each proposal.
- The reduced prose and the rule set are built together, so a rule marker and a covered line cannot disagree.
- A later iteration reads the reduced prose, runs the rule set, and reports a decision; it does not reread the full prose.
- Revising the prose returns the cycle to the proposal step, so evidence and rules are re-derived rather than patched.

## Dependencies

- None.
