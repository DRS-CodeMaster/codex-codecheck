# /codex:multi

Review multiple files together with cross-file dependency analysis.

## Usage

```
/codex:multi <file1> <file2> [file3...] [focus]
```

## Arguments

- `file1, file2, ...` (required): Paths to files to review together
- `focus` (optional): Custom focus areas. Default: "Security, Performance, Code Quality, Cross-File Dependencies, Best Practices"

## Examples

```
/codex:multi src/auth.php src/config.php
/codex:multi app/api.py app/models.py app/utils.py "API Security, Data Validation"
/codex:multi server.js routes/users.js middleware/auth.js
```

## Steps

1. Check config exists — if not, run /codex:setup
2. Read all files
3. Combine into /tmp/codex_input.txt with separators:
   === FILE: path/to/file1.php ===
   <content>

   === FILE: path/to/file2.php ===
   <content>
4. Write /tmp/codex_review.py with:
   - model: o3-mini
   - reasoning_effort: high (always for multi-file)
   - max_completion_tokens: 32000
   - developer prompt: cross-file review expert
   - user prompt: all files + focus
5. Execute: python3 /tmp/codex_review.py (timeout_ms: 180000)
6. Parse JSON and present findings grouped by file, then cross-file issues

## Developer Prompt

```
You are a code review expert. You receive multiple files.
Analyze each file AND check cross-file dependencies,
shared references, and consistency between files.
Respond ONLY with valid JSON (no Markdown, no backticks):
{"findings": [{"datei": "path", "severity": "critical|warning|info",
"zeile": INT, "beschreibung": "...", "fix_vorschlag": "..."}],
"fazit": "...", "top3": ["...", "...", "..."]}
```