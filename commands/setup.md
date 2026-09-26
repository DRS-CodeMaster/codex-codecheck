# /codex:setup

First-time setup for Codex-CodeCheck. Safe to run again at any time.

## Usage

```
/codex:setup
```

## Steps

1. **Codex CLI.** Check `command -v codex && codex --version`. If missing, ask the user, then
   install: `npm install -g @openai/codex` (needs Node.js 18+).

2. **Link the runtime.** Find this skill's `runtime/` folder — `${CLAUDE_PLUGIN_ROOT}/runtime`
   when installed as a plugin, otherwise `~/.claude/skills/codex-codecheck/runtime`. Then:
   ```bash
   R=<runtime folder>; C=~/.codex-codecheck
   mkdir -p $C && chmod +x $R/codex-run.sh
   ln -sfn $R/codex-run.sh $C/codex-run.sh && ln -sfn $R/schema.json $C/schema.json
   ```

3. **Choose how to reach Codex.** Run `codex login status`.
   - Shows **"Logged in using ChatGPT"** → done, reviews use the ChatGPT plan. Mention that an
     API key can be added later as fallback for when the plan's limit is reached.
   - Otherwise ask the user which way they want:

   **A) ChatGPT account (recommended if they have Plus, Pro or Business).** The user runs
   `codex login` in their own terminal (in Claude Code: `! codex login`). It opens the browser;
   they sign in with their ChatGPT account. Afterwards `codex login status` must show ChatGPT.
   No API cost — reviews count against the plan's Codex quota.

   **B) OpenAI API key (pay per token).** The user creates a key at
   platform.openai.com → API keys. Store it without it ever appearing in chat or argv — ask the
   user to paste it into a file themselves, or read it from stdin:
   ```bash
   mkdir -p ~/.codex-codecheck && cd ~/.codex-codecheck
   python3 -c "import json,getpass;k=getpass.getpass('OpenAI API key: ');json.dump({'openai_api_keys':[{'label':'primary','key':k}],'model':'gpt-5.6-sol'},open('config.json','w'),indent=2)"
   chmod 600 config.json
   ```
   Several keys are allowed (`openai_api_keys` list, tried in order when one is out of quota).
   Alternatively the runtime also accepts `$OPENAI_API_KEY`.
   Do **not** use `codex login --with-api-key` if the user also runs the ChatGPT/Codex desktop
   app — it would switch the app to API billing too.

   Both A and B together is the best setup: account first, key only as fallback.

4. **Test run** (mini mode, a few seconds):
   ```bash
   printf 'print("hello")\n' > /tmp/cck_test.py
   printf 'Role: code review expert\nTask: quick review.\nFiles (read them yourself): /tmp/cck_test.py\nFormat: Answer in English. line = line number or 0. reference = "".\n' > ~/.codex-codecheck/prompt.md
   ~/.codex-codecheck/codex-run.sh mini /tmp; cat ~/.codex-codecheck/status.txt ~/.codex-codecheck/route.txt
   ```
   Report `done` plus the route (`chatgpt` or `api:<label>`), or the last lines of `last.log`.

## Notes

- Never display an API key back to the user.
- If `config.json` already exists, ask before overwriting it.
- Everything is stored locally on the user's machine only.
