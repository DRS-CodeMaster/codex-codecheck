# /codex:review

Review a single source code file for security, performance, and quality issues.

## Usage

```
/codex:review <filepath> [focus]
```

## Arguments

- `filepath` (required): Path to the file to review
- `focus` (optional): Custom focus areas. Default: "Security, Performance, Code Quality, Best Practices"

## Examples

```
/codex:review src/auth.php
/codex:review app/utils.py "SQL Injection, Input Validation"
/codex:review server.js "Error Handling, Memory Leaks"
```

## Steps

1. Check config exists (~/.codex-codecheck/config.json) — if not, run /codex:setup
2. Read the file and count lines
3. If 1000+ lines: switch to o4-mini with reasoning_effort: high
4. Save file content to /tmp/codex_input.txt
5. Write /tmp/codex_review.py with:
   - model: o4-mini
   - reasoning_effort: medium (or high for 1000+ lines)
   - max_completion_tokens: 16000 (or 32000 for large files)
   - developer prompt: code review expert, JSON-only response
   - user prompt: file path + focus + code content
6. Execute: python3 /tmp/codex_review.py (timeout_ms: 60000 or 180000)
7. Parse JSON and present findings sorted by severity

## Developer Prompt

```
You are a code review expert. Analyze the code thoroughly.
Respond ONLY with valid JSON (no Markdown, no backticks):
{"findings": [{"severity": "critical|warning|info", "zeile": INT,
"beschreibung": "...", "fix_vorschlag": "..."}],
"fazit": "...", "top3": ["...", "...", "..."]}
```