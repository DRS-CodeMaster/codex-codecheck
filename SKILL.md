---
name: codex-codecheck
description: >
  Second opinion from OpenAI Codex (default model gpt-5.6-sol) via the official Codex CLI —
  runs on your ChatGPT account (plan quota, no API cost) or, as fallback, your own OpenAI API key.
  Code reviews (review, multi, security, optimize, mini) and free-form consultations (consult):
  have plans, refactors or architecture decisions cross-checked by a second agent.
  Triggers: "codex review", "codecheck", "/codex", "let codex check this", "review with codex",
  "ask codex", "second opinion from codex", "codex security", "codex optimize".
---

# Codex-CodeCheck v3

Codex runs as its own agent: it **reads the files itself** inside a read-only sandbox, instead of
Claude pasting code into a prompt. Claude writes the task, starts the run, waits, verifies and
presents. Codex never changes anything.

## Requirement: local shell access

Everything runs on the user's own computer. Claude needs a tool that executes local shell
commands — **Claude Code's Bash tool**, or in the Claude Desktop app a local shell connector such
as **Desktop Commander** (`start_process` / `read_process_output`). Use whichever is available.

If the only way to run code is a cloud sandbox (e.g. claude.ai in the browser, no local
connector): **stop** and tell the user this plugin needs local shell access — Claude Code, or
Claude Desktop with Desktop Commander (`npx @wonderwhy-er/desktop-commander@latest setup`).
Never try to install or run Codex inside a cloud sandbox.

## Two ways to reach Codex

| Order | Route | Cost | Set up with |
|---|---|---|---|
| 1 | **ChatGPT account** (Plus, Pro, Business …) | included in the plan's Codex quota | `codex login` (browser) |
| 2 | **OpenAI API key** | billed per token by OpenAI | `/codex:setup` → key in `~/.codex-codecheck/config.json` |

The runtime always tries the ChatGPT account first. The API key is only used when there is no
ChatGPT login, or when the account hits a usage/rate limit. Other errors never fall back — a
broken prompt is not paid for twice. Every run records its route in `route.txt`.

## Files

| Path | Purpose |
|---|---|
| `runtime/codex-run.sh` (in this skill) | runtime: route selection, reasoning effort, status |
| `runtime/schema.json` (in this skill) | enforced answer format (`--output-schema`) |
| `~/.codex-codecheck/codex-run.sh`, `schema.json` | **symlinks** to the runtime, created by setup |
| `~/.codex-codecheck/prompt.md` | the task, written by Claude for each run |
| `~/.codex-codecheck/out.json` · `status.txt` · `route.txt` · `last.log` | result · `running`/`done`/`error: …` · `chatgpt` or `api:<label>` · progress |
| `~/.codex-codecheck/config.json` | optional: API key(s) and `model` — **never show in chat** |

## Before every run (idempotent)

```bash
test -x ~/.codex-codecheck/codex-run.sh && command -v codex && codex login status
```
If the symlink is missing, the Codex CLI is missing, or `codex login status` shows no login and
`config.json` has no key → run `/codex:setup` first.

## Modes

| Mode | Use for | Reasoning | Typical time |
|---|---|---|---|
| `mini` | user says "quick" AND < 300 lines | low | ~15 s |
| `review` | one file, general review (default) | medium | 1–2 min |
| `consult` | cross-check a plan, analysis, doc or architecture decision | medium | 1–3 min |
| `multi` | 2+ related files, cross-file issues | high | 2–4 min |
| `security` | auth, login, input handling, secrets (CWE refs) | high | 2–4 min |
| `optimize` | performance, N+1, memory, queries | high | 2–4 min |

Default model: **gpt-5.6-sol**. Override per run with `CODEX_CODECHECK_MODEL=<model>` or
permanently with `"model"` in `config.json`.

## Workflow

1. **Files:** Codex reads files itself — use absolute paths. Remote files: copy them locally first.
2. **Write `~/.codex-codecheck/prompt.md`:**
   ```
   Role: <code review expert | security auditor (CWE) | performance expert | second agent reviewing Claude's plan>
   Task: <what exactly, 1–3 sentences>
   Files (read them yourself): <absolute paths>
   Context: <user intent, known issues, stack — 3–8 lines>
   Focus: <what to look at>
   Format: Answer in <user's language>. severity critical = bug/objection, warning = change
   request, info = note/agreement. line = line number or 0. reference = CWE id, impact
   (high/medium/low) or "". For consult: state clearly in summary whether you agree
   (yes / no / with conditions).
   ```
   Never put credentials or personal data into the prompt.
3. **Run** from the directory that contains the files (or a common parent):
   `~/.codex-codecheck/codex-run.sh <mode> <workdir>`
   Runs longer than ~1 minute go in the background — Bash `run_in_background`, Desktop
   Commander `start_process`, or detached with any shell tool:
   ```bash
   rm -f ~/.codex-codecheck/status.txt   # never read a stale result from a previous run
   nohup ~/.codex-codecheck/codex-run.sh <mode> <workdir> >/dev/null 2>&1 &
   ```
   Then poll `cat ~/.codex-codecheck/status.txt 2>/dev/null` until it says `done` or starts
   with `error:` (missing file or `running` = still working). While waiting, give the user a short status update about every 3 minutes.
4. **Result:** check `status.txt` and `route.txt`, then read `out.json`. On `error:` show the
   last lines of `last.log`. If the route was `api:*`, tell the user explicitly, including the
   reason from `last.log` ("ChatGPT account unavailable (…)").

## Presentation

```
## Codex <mode>: <file or topic>
gpt-5.6-sol | reasoning <low/medium/high> | <duration> s | via <ChatGPT account | API key (label)>

[CRITICAL] file:line — description (reference)
  → fix
[WARNING] …
[INFO] …

Summary: …
Top 3: 1. … 2. … 3. …
```
For `consult`: add Claude's own position afterwards — where it agrees, where not, and why.
Do not adopt findings blindly; Claude verifies disputed points itself before acting.

## Rules

1. Never show API keys in chat, argv or logs.
2. Sandbox is always `read-only`. Codex changes nothing — fixes are made by Claude afterwards.
3. Never run `codex login --with-api-key` on a machine that also uses the ChatGPT/Codex desktop
   app: it replaces the account login, and the app then bills via the API as well. Store API keys
   in `~/.codex-codecheck/config.json` instead — they are only passed to the one Codex process.
4. `high` never for `mini`; `low` only for `mini`.
5. `CODEX_CODECHECK_API_ONLY=1` only when the user explicitly asks for the API route.
