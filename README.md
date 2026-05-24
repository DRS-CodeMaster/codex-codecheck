# Codex-CodeCheck

**Free & open source** — no subscription required. Uses your own OpenAI API key. Typical cost: **$0.01–0.03 per review**.

AI-powered code review plugin that combines Claude's orchestration with OpenAI gpt-5.3-codex's deep reasoning. Two AI powerhouses reviewing your code together.

## What it does

Codex-CodeCheck analyzes your source code for security vulnerabilities, performance bottlenecks, and code quality issues. Claude reads and understands your codebase, then sends it to OpenAI's gpt-5.3-codex model for an independent, autonomous analysis. Results are returned as structured findings with severity ratings and fix suggestions — directly in your chat.

## Commands

| Command | Description |
|---------|-------------|
| `/codex:setup` | Configure your OpenAI API key (first-time setup) |
| `/codex:review <file>` | General code review (security + performance + quality) |
| `/codex:multi <file1> <file2> ...` | Cross-file review with dependency analysis |
| `/codex:security <file>` | Dedicated security audit with CWE references |
| `/codex:optimize <file>` | Dedicated performance optimization analysis |

## Quick Start

1. Install the plugin
2. Run `/codex:setup` and enter your OpenAI API key
3. Run `/codex:review path/to/your/file.php`

## Requirements

- OpenAI API key with access to gpt-5.3-codex model
- Python 3 installed on your machine

## Supported Languages

PHP, JavaScript, TypeScript, Python, HTML, CSS, JSON, XML, SQL, Markdown, YAML, Go, Rust, Java, C#, and more.

## Smart Mode Selection

The plugin automatically adjusts its analysis depth:

| Condition | Reasoning Effort | Notes |
|-----------|-----------------|-------|
| Small file (<1000 lines) | medium | Fast, cost-efficient |
| Large file (1000+ lines) | high | Deep analysis |
| Multiple files | high | Cross-file references |
| Security audit | high | Always thorough |
| Optimization audit | high | Always thorough |

## Cost

**This plugin is 100% free.** No subscription, no hidden fees, no premium tier.

You only pay OpenAI directly for API usage (bring your own key). Typical costs:
- Small file (medium reasoning): ~$0.01-0.03
- Large file (high reasoning): ~$0.05-0.15
- Multi-file review: ~$0.10-0.30

That's cents, not dollars. A full month of daily reviews typically costs less than a coffee.

## Privacy

- Your code is sent to OpenAI's API for analysis
- Your API key is stored locally on your machine only
- No data is stored on any server
- No telemetry or tracking

## License

MIT