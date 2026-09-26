# /codex:review

Review a single file for bugs, security, performance and code quality.

## Usage

```
/codex:review <filepath> [focus]
```

- `filepath` (required): file to review
- `focus` (optional): default "Correctness, Security, Performance, Code Quality, Best Practices"
- If the user says "quick" and the file has fewer than 300 lines, use mode `mini` instead.

## Examples

```
/codex:review src/auth.php
/codex:review app/utils.py "SQL injection, input validation"
```

## Steps

Follow the workflow in SKILL.md with:
- **Role:** code review expert
- **Mode:** `review` (reasoning medium) — or `mini` (low) for quick checks
- **Run:** `~/.codex-codecheck/codex-run.sh review <folder of the file>`

Present findings sorted by severity (critical → warning → info), with the route (ChatGPT account or API key).
