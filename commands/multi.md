# /codex:multi

Review several related files together, including cross-file issues.

## Usage

```
/codex:multi <file1> <file2> [file3...] [focus]
```

## Examples

```
/codex:multi src/auth.php src/config.php
/codex:multi app/api.py app/models.py app/utils.py "API security, data validation"
```

## Steps

Follow the workflow in SKILL.md with:
- **Role:** code review expert for multi-file systems
- **Focus:** per-file issues plus cross-file dependencies, shared references, consistency
  between files (default: "Security, Performance, Code Quality, Cross-File Dependencies")
- **Mode:** `multi` (reasoning high)
- **Run:** `~/.codex-codecheck/codex-run.sh multi <common parent folder>`

Present findings grouped by file, then a "Cross-file issues" section.
