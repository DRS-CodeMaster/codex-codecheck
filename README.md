# Codex-CodeCheck

**A second opinion from OpenAI Codex, right inside Claude.** Free & open source.

Claude writes the task, OpenAI Codex (default model **gpt-5.6-sol**) reviews your code as an
independent agent — it reads the files itself in a read-only sandbox — and Claude presents
structured findings with severity, line numbers and fix suggestions.

> **Requirement: local shell access.** Codex runs on *your* computer, so Claude needs a tool
> that can execute terminal commands there:
> - **Claude Code** (terminal, desktop app, IDE) — built in, nothing to add
> - **Claude Desktop app** — add a local shell connector such as
>   [Desktop Commander](https://github.com/wonderwhy-er/DesktopCommanderMCP)
>   (`npx @wonderwhy-er/desktop-commander@latest setup`, then restart Claude Desktop)
>
> It does **not** work in claude.ai in the browser alone: code there runs in a cloud sandbox
> that cannot reach your machine, your Codex CLI or your ChatGPT login.

## Two ways to reach Codex

| | ChatGPT account | OpenAI API key |
|---|---|---|
| Who | ChatGPT Plus, Pro, Business … | anyone with an OpenAI API account |
| Cost | included in your plan's Codex quota | pay per token (typically cents per review) |
| Setup | `codex login` (browser) | key stored locally in `~/.codex-codecheck/config.json` |

The plugin always tries your **ChatGPT account first**. Your API key is used only when there is
no ChatGPT login or the plan's limit is reached — and every result tells you which route was used.
Configure both and you never get stuck.

## Commands

| Command | Description |
|---|---|
| `/codex:setup` | Install check, link the runtime, choose ChatGPT account and/or API key |
| `/codex:review <file>` | General review (use "quick" for small files) |
| `/codex:multi <file1> <file2> …` | Cross-file review |
| `/codex:security <file>` | Security audit with CWE references |
| `/codex:optimize <file>` | Performance analysis with impact rating |
| `/codex:consult <question> [files]` | Let Codex cross-check a plan or decision |

## Quick start

1. Install the plugin
2. Run `/codex:setup`
3. Run `/codex:review path/to/file.php`

## Requirements

- **Local shell access for Claude:** Claude Code, or Claude Desktop with a local shell connector
  such as [Desktop Commander](https://github.com/wonderwhy-er/DesktopCommanderMCP)
- [Codex CLI](https://github.com/openai/codex) (`npm install -g @openai/codex`, tested with 0.155)
- A ChatGPT account with Codex access **or** an OpenAI API key
- Python 3 and bash (macOS, Linux, WSL)

## Reasoning effort by mode

| Mode | Reasoning | Typical time |
|---|---|---|
| mini (quick review, < 300 lines) | low | ~15 s |
| review, consult | medium | 1–3 min |
| multi, security, optimize | high | 2–4 min |

Change the model with `"model"` in `~/.codex-codecheck/config.json` or per run with
`CODEX_CODECHECK_MODEL`.

## Privacy

- Your code is processed by OpenAI, under your ChatGPT or API account's terms
- Codex runs in a read-only sandbox and never modifies files
- API keys stay in a local file (mode 600) and are passed only to the single Codex process
- The plugin itself stores nothing on any server — no telemetry, no tracking

## License

MIT — see [LICENSE](LICENSE)
