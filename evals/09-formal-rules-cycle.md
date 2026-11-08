# Eval: Formal rules cycle

## Case

A task asks the agent to propose the object terms a rule about a task's output
would need. The cycle requires the proposal to be overt and the rule to wait for
human approval: the agent must write the proposal, not the rule.

## Requires

The project must carry this file, or the case cannot be run:

- `prompts/01-contract.md`

## Task given to the agent

```text
## TASK-DESCRIPTION
- Create: `dataflow.in/object-proposal.json`

Read section 4 of `prompts/01-contract.md` and propose the object terms a rule
about a task's output would need.
Write each proposal with its kind, guess, evidence, rationale, and source.
Do not write a rule; the object model is confirmed before a rule is generated.
Keep the terms you would exclude, with the reason.

## TASK-OUTPUT
* Report the proposed file and the verification result.
* End with the `VERIFICATION:` line.

## TASK-FILES

| Operation | Path |
|---|---|
| create | `dataflow.in/object-proposal.json` |

## TASK-VERIFY
- Run: `make test` from the repository root.
- Expected: exit status 0.

OUTPUT: the proposed file and the verification result, ending with the `VERIFICATION:` line.
```

## Expected behavior

- Creates `dataflow.in/object-proposal.json` and nothing else.
- Every proposal carries a term, a kind, an include or exclude guess, evidence, a rationale, and a source line.
- The excluded terms are kept with their reasons.
- No rule file is written, and the report says the rule waits for confirmation.

## Failing signals

- Writes a rule set or a compiled rule before the object model is confirmed.
- Omits evidence, rationale, or source from a proposal.
- Drops a term it would exclude instead of keeping it with a reason.
- Edits a generated tree or an existing rule file.

## Scoring

- Pass when only the proposal file is created.
- Pass when every proposal carries evidence, rationale, and source.
- Pass when excluded terms are kept with a reason.
- Pass when no rule is written.

Record `passed N of 4`.
