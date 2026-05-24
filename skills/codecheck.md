# Codex-CodeCheck Skill

AI-powered code review using OpenAI gpt-5.3-codex model family.
Analyzes code for security vulnerabilities, performance issues, and quality problems.

## Overview

Codex-CodeCheck sends source code files to OpenAI o4-mini (single file) or gpt-5.3-codex (multi-file/deep analysis) for autonomous analysis.
The model returns structured findings (severity, line number, description, fix suggestion)
which are presented directly in the chat.

## Requirements

- OpenAI API Key (user provides their own)
- Key must be stored in a file at: ~/.codex-codecheck/config.json
- Run /codex:setup to configure

## Supported Languages

PHP, JavaScript, TypeScript, Python, HTML, CSS, JSON, XML, SQL, Markdown, YAML, Go, Rust, Java, C#

## How It Works

1. Read the source file(s) from disk
2. Send to OpenAI o4-mini (single) or gpt-5.3-codex (multi) via Chat Completions API
3. Parse JSON response with findings
4. Present findings sorted by severity in chat

## Automatic Mode Selection

| Condition | Mode | reasoning_effort | max_tokens | timeout |
|-----------|------|-----------------|------------|---------|
| 1 file, under 1000 lines | o4-mini | medium | 16000 | 60s |
| 1 file, 1000+ lines | o4-mini | high | 32000 | 120s |
| 2+ files | gpt-5.3-codex | high | 32000 | 180s |

Claude determines the mode automatically based on file count and line count.
The user does not need to specify the mode.

## Config File

Located at: ~/.codex-codecheck/config.json

```json
{
  "openai_api_key": "sk-proj-...",
  "model": "o4-mini",
  "default_focus": "Security, Performance, Code Quality, Best Practices"
}
```

## API Call Pattern

All commands use the same core pattern:

1. Read config: ~/.codex-codecheck/config.json
2. Read source file(s) into /tmp/codex_input.txt
3. Write Python review script to /tmp/codex_review.py
4. Execute: python3 /tmp/codex_review.py (timeout: 120-180s)
5. Parse JSON response and present findings

## Response Format

The API must return valid JSON with this structure:

Single file:
```json
{
  "findings": [
    {
      "severity": "critical|warning|info",
      "zeile": 42,
      "beschreibung": "Description of the issue",
      "fix_vorschlag": "Suggested fix"
    }
  ],
  "fazit": "Overall summary",
  "top3": ["Action 1", "Action 2", "Action 3"]
}
```

Multi-file adds a "datei" field per finding:
```json
{
  "findings": [
    {
      "datei": "path/to/file.php",
      "severity": "warning",
      "zeile": 10,
      "beschreibung": "...",
      "fix_vorschlag": "..."
    }
  ],
  "fazit": "...",
  "top3": ["...", "...", "..."]
}
```

## Presentation Format

Single file:
```
## CodeCheck: <filename> (<lines> lines)
Model: gpt-5.3-codex / gpt-5.3-codex | Reasoning: medium/high | Focus: <focus>

[CRITICAL] Line XX: Description
  Fix: Suggestion

[WARNING] Line XX: Description
  Fix: Suggestion

[INFO] Line XX: Description
  Fix: Suggestion

Summary: <fazit>

Top 3 Actions:
1. ...
2. ...
3. ...
```

Multi-file groups findings by file and adds a Cross-File Issues section.

## Rules

1. Never show the API key in chat
2. Always check config exists before running — if not, prompt user to run /codex:setup
3. All calls are synchronous — no background processes
4. timeout_ms: 60000 (single file) / 180000 (multi-file or large file)
5. Findings sorted by severity: critical -> warning -> info
6. File content always via /tmp/codex_input.txt — never inline in Python strings
7. o4-mini uses reasoning_effort: medium (default) or high (1000+ lines)
8. Multi-file/security/optimize always use gpt-5.3-codex with reasoning_effort: high