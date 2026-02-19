# /codex:security

Dedicated security audit of source code files. Focuses exclusively on vulnerabilities and attack vectors.

## Usage

```
/codex:security <filepath> [additional_focus]
```

## Arguments

- `filepath` (required): Path to the file to audit
- `additional_focus` (optional): Extra areas to check beyond default security focus

## Examples

```
/codex:security src/auth.php
/codex:security app/api.py "OAuth token handling"
/codex:security server.js "Rate limiting, CORS"
```

## Steps

Same as /codex:review but with:
- reasoning_effort: always high (security requires deep analysis)
- max_completion_tokens: 32000
- Specialized security-focused developer prompt

## Developer Prompt

```
You are a security auditor specializing in application security.
Perform a thorough security audit of this code. Check for:
- SQL Injection, XSS, CSRF, Command Injection
- Authentication and Authorization flaws
- Input validation gaps (server-side)
- Hardcoded secrets, API keys, credentials
- Insecure file operations and path traversal
- Session management issues
- CORS misconfiguration
- Insecure cryptography or hashing
- Race conditions and TOCTOU vulnerabilities
- Information disclosure (error messages, debug output, internal paths)
- Dependency and configuration risks

Rate severity strictly:
- critical: Exploitable vulnerability, immediate risk
- warning: Potential vulnerability, needs investigation
- info: Security best practice not followed

Respond ONLY with valid JSON (no Markdown, no backticks):
{"findings": [{"severity": "critical|warning|info", "zeile": INT,
"beschreibung": "...", "fix_vorschlag": "...", "cwe": "CWE-XXX"}],
"fazit": "...", "top3": ["...", "...", "..."]}
```

## Presentation

Same format as /codex:review but with CWE references:

```
## Security Audit: <filename>
Model: o3-mini | Reasoning: high

[CRITICAL] Line XX: Description (CWE-89)
  Fix: Suggestion

[WARNING] Line XX: Description (CWE-79)
  Fix: Suggestion
```

## Notes

- Security audit always uses reasoning_effort: high regardless of file size
- Findings include CWE (Common Weakness Enumeration) identifiers when applicable
- Multi-file security audit: use /codex:multi with focus "Security Audit"