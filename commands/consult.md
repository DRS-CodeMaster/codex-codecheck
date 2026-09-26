# /codex:consult

Let Codex cross-check a plan, analysis, refactoring idea, document or architecture decision —
a structured second opinion from another agent.

## Usage

```
/codex:consult <topic or question> [files...]
```

## Examples

```
/codex:consult "Is this migration plan safe?" docs/migration.md
/codex:consult "Should we split this service?" src/billing/
```

## Steps

1. Write the plan or question Claude wants checked into a file (e.g. `/tmp/cck_plan.md`) if it
   only exists in the chat.
2. Follow the workflow in SKILL.md with:
   - **Role:** second agent reviewing Claude's plan
   - **Mode:** `consult` (reasoning medium)
   - **Format addition:** severity critical = objection · warning = change request ·
     info = agreement or note. The summary must state clearly: agree yes / no / with conditions.
   - **Run:** `~/.codex-codecheck/codex-run.sh consult <folder with the files>`
3. Present Codex's view, then Claude's own position: where both agree, where not, and why.
