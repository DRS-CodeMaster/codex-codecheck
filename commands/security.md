# /codex:security

Dedicated security audit with CWE references.

## Usage

```
/codex:security <filepath> [additional_focus]
```

## Examples

```
/codex:security src/auth.php
/codex:security app/api.py "OAuth token handling"
```

## Steps

Follow the workflow in SKILL.md with:
- **Role:** security auditor specialising in application security
- **Mode:** `security` (reasoning high)
- **Focus:** SQL injection, XSS, CSRF, command injection · authentication and authorization
  flaws · server-side input validation · hardcoded secrets · insecure file operations and path
  traversal · session management · CORS · weak cryptography · race conditions / TOCTOU ·
  information disclosure · dependency and configuration risks
- **Severity:** critical = exploitable now · warning = potential vulnerability · info = best
  practice not followed. `reference` = CWE id (e.g. CWE-89).
- **Run:** `~/.codex-codecheck/codex-run.sh security <folder of the file>`

For several files, list all of them in the prompt and use the common parent folder.
