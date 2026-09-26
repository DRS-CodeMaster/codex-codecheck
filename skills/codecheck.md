# Codex-CodeCheck Skill

Second opinion from OpenAI Codex (default gpt-5.6-sol) via the Codex CLI — on the user's
ChatGPT account first, their own OpenAI API key only as fallback.

Requires local shell access: Claude Code, or Claude Desktop with a local shell connector such
as Desktop Commander. Not usable from a cloud sandbox alone.

The full workflow, modes, prompt template, presentation format and rules are in the plugin's
root `SKILL.md` (`${CLAUDE_PLUGIN_ROOT}/SKILL.md`). Read it before the first run.

Commands: `/codex:setup`, `/codex:review`, `/codex:multi`, `/codex:security`,
`/codex:optimize`, `/codex:consult`.
