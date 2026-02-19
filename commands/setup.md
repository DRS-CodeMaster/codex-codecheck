# /codex:setup

First-time setup for Codex-CodeCheck. Stores the user's OpenAI API key.

## Usage

```
/codex:setup
```

## Steps

1. Ask the user for their OpenAI API key
2. Create directory: ~/.codex-codecheck/
3. Write config file: ~/.codex-codecheck/config.json

```json
{
  "openai_api_key": "<USER_KEY>",
  "model": "o3-mini",
  "default_focus": "Security, Performance, Code Quality, Best Practices"
}
```

4. Verify the key works by making a test call:

```python
import json, urllib.request
req = urllib.request.Request(
    'https://api.openai.com/v1/models',
    headers={'Authorization': 'Bearer <USER_KEY>'}
)
resp = urllib.request.urlopen(req, timeout=10)
print('OK' if resp.status == 200 else 'FAILED')
```

5. Report success or failure to the user

## Notes

- Never display the API key back to the user after storing
- If config already exists, ask if user wants to overwrite
- Key is stored locally on the user's machine only