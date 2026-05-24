---
name: codex-codecheck
description: >
  AI-powered Code-Review mit OpenAI gpt-5.3-codex (Default) oder o4-mini (Mini-Files).
  Sendet PHP/JS/JSON/PY-Dateien zur autonomen Analyse, praesentiert Findings im Chat.
  Trigger: "codex review", "codex pruefen", "codecheck", "/codex",
  "lass codex das pruefen", "review mit codex", "codex findings", "codex optimize".
---

# Codex-CodeCheck Skill v6 (lokal + async polling)

Autonome Code-Review: Claude liest Dateien, schickt sie an OpenAI gpt-5.3-codex
(oder o4-mini fuer Mini-Files), pollt im Hintergrund und praesentiert
Findings synchron im Chat.

## 🚀 Quickstart — Wann nehme ich welchen Befehl?

Claude waehlt den richtigen Befehl meist automatisch aus der User-Anfrage.
Faustregel:

```
┌─ 1 Datei, allgemein "schau mal drueber"           → /codex:review
├─ 2+ Dateien, haengen zusammen                     → /codex:multi
├─ Explizit Security / Auth / Login / Input         → /codex:security
├─ Langsam / Memory / DB-Queries / Performance      → /codex:optimize
└─ Erster Aufruf, keine Config vorhanden            → /codex:setup
```

### Entscheidungs-Baum

1. **Config vorhanden?** (`~/.codex-codecheck/config.json`)
   - Nein → zuerst `/codex:setup`, danach normaler Flow.
   - Ja → weiter.

2. **Wie viele Dateien?**
   - 1 Datei → `/codex:review` oder Spezial (`/codex:security`, `/codex:optimize`).
   - 2+ Dateien → `/codex:multi` (immer gpt-5.3-codex high).

3. **Hat der User einen Fokus genannt?**
   - "sicher?" / "injection" / "auth" / "login" → `/codex:security`.
   - "langsam" / "memory" / "n+1" / "optimieren" → `/codex:optimize`.
   - "schnell" / "mini" UND < 300 Zeilen → `/codex:review` mit MODE=mini.
   - Sonst → `/codex:review` Default (gpt-5.3-codex high).

4. **Wo liegt die Datei?**
   - Lokal auf dem Mac (`/Users/...`, Projektpfad) → direkt per `cp` nach `input.txt`.
   - Auf dem VPS (meinezeit.live / meinetheorie.live) → zuerst per `scp` holen
     (siehe "VPS-Dateien holen" weiter unten), dann wie lokale Datei behandeln.

### Minimaler Ablauf (Happy Path)

```text
User:  "codex review auf app/login.php"
Claude (alles via Desktop Commander):
  1. test config exists                                       ✓
  2. wc -l app/login.php → Groesse bestimmen                  ✓
  3. cp app/login.php ~/.codex-codecheck/input.txt            ✓
  4. runner.py deployen falls fehlt                           ✓
  5. nohup python3 runner.py review '<fokus>' & disown        ✓
  6. Polling: cat status.txt alle 10s (max 30x)               ✓
  7. read_file out.json → Findings nach Severity ausgeben     ✓
```

---

## Wichtigste Aenderungen v5 → v6

- **Lokal arbeiten:** Alle File-Ops + Python-Calls laufen via Desktop Commander
  auf dem Mac (`mcp__Desktop_Commander__start_process`), NICHT im Sandbox-Bash.
  Grund: Sandbox `/tmp` und Mac `/tmp` sind getrennte Filesysteme — Config liegt
  auf Mac, Skript wuerde Config nicht finden.
- **Async + Polling:** gpt-5.3-codex mit reasoning=high braucht 2-4 min. MCP-Calls
  haben 60-120s Limit → Skript via `nohup ... &` starten, dann mit kurzen
  `read_process_output`-Polls (timeout_ms 1500-3000) auf Output-Datei warten.
- **Default = gpt-5.3-codex:** o4-mini nur fuer kleine Files (< 300 Zeilen) ODER
  wenn User explizit "schnell"/"mini" sagt. Standard ist immer das volle Modell.
- **Persistente Pfade:** Runner liegt unter `~/.codex-codecheck/runner.py`,
  nicht in `/tmp` (ueberlebt Reboots, weniger Setup-Cost).

## Modell-Auswahl

| Bedingung | Modell | reasoning_effort | max_tokens | Erwartete Dauer |
|-----------|--------|------------------|------------|-----------------|
| Default (Review/Multi/Security/Optimize) | gpt-5.3-codex | high | 32000 | 2-4 min |
| User sagt "schnell"/"mini" UND < 300 Zeilen | o4-mini | medium | 16000 | 30-60s |
| Skill-Doku-Kurzcheck (eigene .md, < 200 Z.) | o4-mini | low | 8000 | 15-30s |

**Niemals** o4-mini fuer Multi-File / Security / Optimize — User-Feedback:
"wir nutzen den groessten 5.3-codex".

## Credentials

Config-Datei (Mac): `~/.codex-codecheck/config.json`
Falls nicht vorhanden → User auffordern `/codex:setup` auszufuehren.
NIEMALS den API-Key im Chat zeigen.

Format (v5.1+, Fallback-Array):

```json
{
  "openai_api_keys": [
    {"key": "sk-proj-...", "label": "primary (credits)"},
    {"key": "sk-proj-...", "label": "fallback (paid)"}
  ],
  "model": "gpt-5.3-codex",
  "mini_model": "o4-mini"
}
```

Legacy-Format (`"openai_api_key": "sk-..."`) wird weiter unterstuetzt.

## Arbeitspfade (persistent, Mac)

```
~/.codex-codecheck/
├── config.json          ← Credentials
├── runner.py            ← persistenter Runner (v6+)
├── input.txt            ← aktueller Request-Body (File-Content)
├── out.json             ← Ergebnis (vom Runner geschrieben)
├── status.txt           ← "running" | "done" | "error:<msg>"
└── last.log             ← stderr vom letzten Run
```

Diese Pfade NIE in `/tmp` — Sandbox-Split + Reboot-Loss.

## VPS-Dateien holen (meinezeit.live / meinetheorie.live)

Liegt die Datei auf dem VPS, wird sie **zuerst lokal gespiegelt** — alles danach laeuft wie bei einer lokalen Datei.

Variante A: scp (bevorzugt):

```bash
mkdir -p ~/.codex-codecheck/vps && \
scp <user>@<vps-host>:/var/www/meinezeit.live/app/login.php \
    ~/.codex-codecheck/vps/login.php
```

Variante B: ssh + cat (Fallback):

```bash
mkdir -p ~/.codex-codecheck/vps && \
ssh <user>@<vps-host> 'cat /var/www/meinezeit.live/app/login.php' \
    > ~/.codex-codecheck/vps/login.php
```

Multi-File: alle Dateien in einem Rutsch holen, relative Pfade fuer die `=== FILE: ===`-Header merken.

Regeln:
- Zielverzeichnis immer `~/.codex-codecheck/vps/` — nicht im Projekt ablegen.
- VPS-Credentials liegen lokal, nie im Chat zeigen.
- Host unklar? Fragen, nicht raten. Standard: `meinezeit.live`, `meinetheorie.live`.
- Ab hier normaler Flow: `cp ~/.codex-codecheck/vps/<datei> ~/.codex-codecheck/input.txt`, dann runner.py.

## Kontext-Anreicherung (User-Intent + bekannte Baustellen)

Der Runner bekommt nicht nur rohen Code — Claude reichert `input.txt` mit Gespraechs-Kontext an, damit Codex praeziser reviewt.

Struktur von `~/.codex-codecheck/input.txt`:

```
=== CONTEXT ===
User-Intent: <was der User erreichen will, 1-2 Zeilen>
Bekannte Baustellen: <z.B. "booking_id fehlt beim loesche_buchung-Call">
Stack: <z.B. PHP 8.2, MySQL, meinezeit.live>
Fokus: <was Codex besonders pruefen soll>

=== FILE: app/login.php ===
<code>
```

Regeln:
- Keine Credentials, keine personenbezogenen Daten (Namen, Emails, Tokens) im Kontext-Block.
- Kontext kurz: 3-8 Zeilen reichen.
- Wenn der User eine konkrete Baustelle genannt hat (z.B. "der Fix fuer die booking_id"): genau das in "Bekannte Baustellen" aufnehmen.

## Async-Polling-Pattern (Kern-Innovation v6)

```
1. input.txt schreiben (File-Content)
2. status.txt = "running" setzen
3. nohup python3 ~/.codex-codecheck/runner.py <mode> <focus> \
     > ~/.codex-codecheck/last.log 2>&1 &
   → PID sofort zurueck, Prozess laeuft unbeaufsichtigt weiter
4. Polling-Loop via Desktop Commander:
   - start_process("cat ~/.codex-codecheck/status.txt", timeout_ms: 1500)
   - status == "done" → out.json lesen
   - status == "running" → 10s warten, nochmal pollen
   - Max 30 Polls = 5 min Timeout
5. out.json parsen + Findings ausgeben
```

Wichtig: `nohup ... &` + `disown` sorgt dafuer dass der Python-Prozess
auch nach MCP-Timeout weiterlaeuft. Polling-Calls sind jeweils < 2s,
collidieren nicht mit MCP-Limit.

## Runner-Script (~/.codex-codecheck/runner.py)

Dieses Skript wird beim ersten Run deployt (Setup oder on-demand ersetzt):

```python
#!/usr/bin/env python3
# ~/.codex-codecheck/runner.py (v6)
import json, os, sys, urllib.request, urllib.error, time

BASE = os.path.expanduser('~/.codex-codecheck')
CFG  = json.load(open(f'{BASE}/config.json'))
MODE = sys.argv[1] if len(sys.argv) > 1 else 'review'   # review|multi|security|optimize|mini
FOCUS = sys.argv[2] if len(sys.argv) > 2 else 'Security, Performance, Code Quality'

def set_status(s): open(f'{BASE}/status.txt', 'w').write(s)
set_status('running')

# Key-Liste
if 'openai_api_keys' in CFG:
    keys = [(e['key'], e.get('label','?')) if isinstance(e,dict) else (e,'?')
            for e in CFG['openai_api_keys']]
else:
    keys = [(CFG['openai_api_key'], 'default')]

# Modell + reasoning
if MODE == 'mini':
    model, effort, max_tok = 'o4-mini', 'medium', 16000
else:
    model, effort, max_tok = CFG.get('model','gpt-5.3-codex'), 'high', 32000

code = open(f'{BASE}/input.txt').read()

DEV_PROMPTS = {
    'review':   'Du bist Code-Review-Experte. Analysiere gruendlich.',
    'multi':    'Du bist Code-Review-Experte mit Fokus Cross-File-Deps.',
    'security': 'Du bist Security-Auditor. Prueft SQLi, XSS, CSRF, CmdInj, Auth, Secrets, Path-Trav, Crypto. CWE-Refs angeben.',
    'optimize': 'Du bist Performance-Experte. Prueft N+1, Loops, Caches, Blocking I/O, Memory. Impact-Rating (high/medium/low).',
    'mini':     'Du bist Code-Review-Experte. Kompakt.',
}
base_dev = DEV_PROMPTS.get(MODE, DEV_PROMPTS['review'])
json_spec = (' Antworte NUR mit validem JSON (kein Markdown/Backticks): '
             '{"findings":[{"severity":"critical|warning|info","zeile":INT,'
             '"beschreibung":"...","fix_vorschlag":"..."}],'
             '"fazit":"...","top3":["...","...","..."]}')

body = json.dumps({
    'model': model,
    'max_completion_tokens': max_tok,
    'reasoning_effort': effort,
    'messages': [
        {'role':'developer','content': base_dev + json_spec},
        {'role':'user','content': f'Fokus: {FOCUS}\n\nCode:\n{code}'}
    ]
}).encode()

QUOTA = ('insufficient_quota','billing_hard_limit_reached','exceeded_quota','quota_exceeded')
last_err = None
for key, label in keys:
    req = urllib.request.Request(
        'https://api.openai.com/v1/chat/completions', data=body,
        headers={'Authorization':'Bearer '+key,'Content-Type':'application/json'})
    try:
        t0 = time.time()
        resp = urllib.request.urlopen(req, timeout=290)
        data = json.loads(resp.read())
        sys.stderr.write(f'[codex] {label} ok in {time.time()-t0:.1f}s\n')
        open(f'{BASE}/out.json','w').write(data['choices'][0]['message']['content'])
        set_status('done')
        sys.exit(0)
    except urllib.error.HTTPError as e:
        err = e.read().decode('utf-8','replace')
        last_err = f'HTTP {e.code} ({label}): {err[:300]}'
        if e.code in (402,429) or any(s in err for s in QUOTA):
            sys.stderr.write(f'[codex] {label} quota -> next\n'); continue
        open(f'{BASE}/out.json','w').write(json.dumps({'error': last_err}))
        set_status(f'error: {last_err[:100]}'); sys.exit(1)
    except Exception as e:
        last_err = f'{label}: {e}'
        sys.stderr.write(f'[codex] {label} err -> next: {e}\n'); continue

open(f'{BASE}/out.json','w').write(json.dumps({'error': f'all keys failed: {last_err}'}))
set_status(f'error: all keys failed')
sys.exit(1)
```

## Aktionen

### /codex:review <datei> [fokus]

Einzeldatei-Review (Default: gpt-5.3-codex high).

```
1. mcp__Desktop_Commander__start_process(
     "test -f ~/.codex-codecheck/config.json && echo OK || echo MISSING",
     timeout_ms: 1500)
   → MISSING → /codex:setup vorschlagen, abbrechen.
2. mcp__Desktop_Commander__start_process(
     "wc -l <datei>", timeout_ms: 1500)
   → < 300 Zeilen UND user sagte "schnell" → MODE=mini, sonst MODE=review
3. mcp__Desktop_Commander__start_process(
     "cp <datei> ~/.codex-codecheck/input.txt && echo OK", timeout_ms: 1500)
4. Falls runner.py fehlt: deployen (siehe Runner-Script oben).
5. mcp__Desktop_Commander__start_process(
     "nohup python3 ~/.codex-codecheck/runner.py review '<fokus>' \
      > ~/.codex-codecheck/last.log 2>&1 & disown; echo started",
     timeout_ms: 2000)
6. Polling-Loop (bis zu 30x):
     mcp__Desktop_Commander__start_process(
       "cat ~/.codex-codecheck/status.txt", timeout_ms: 1500)
     - "done"            → Schritt 7
     - "error: ..."      → Fehler ausgeben, abbrechen
     - "running" + warte 10s → naechster Poll
7. mcp__Desktop_Commander__read_file(
     path: "~/.codex-codecheck/out.json")
8. JSON parsen, nach Severity sortiert ausgeben (Format unten).
```

### /codex:multi <datei1> <datei2> ... [fokus]

Multi-File. Immer gpt-5.3-codex high. Schritt 3 ersetzt durch:

```
mcp__Desktop_Commander__start_process(
  "( for f in <datei1> <datei2> ...; do
       echo === FILE: $f ===
       cat $f
     done ) > ~/.codex-codecheck/input.txt && echo OK",
  timeout_ms: 3000)
```

Schritt 5 mit `runner.py multi '<fokus>'`.

### /codex:security <datei> [zusatz]

Wie /codex:review, aber Schritt 5 mit `runner.py security '<zusatz>'`.

### /codex:optimize <datei> [zusatz]

Wie /codex:review, aber Schritt 5 mit `runner.py optimize '<zusatz>'`.

### /codex:setup

```
1. AskUserQuestion: API-Key abfragen (label "primary")
2. mcp__Desktop_Commander__start_process(
     "mkdir -p ~/.codex-codecheck && cat > ~/.codex-codecheck/config.json << 'EOF'
{
  \"openai_api_keys\": [{\"key\": \"<KEY>\", \"label\": \"primary\"}],
  \"model\": \"gpt-5.3-codex\",
  \"mini_model\": \"o4-mini\"
}
EOF
chmod 600 ~/.codex-codecheck/config.json && echo OK",
     timeout_ms: 2000)
3. Runner deployen (write_file ~/.codex-codecheck/runner.py + chmod +x)
4. Smoke-Test: /codex:review auf eine triviale 5-Zeilen-Datei
```

## Polling-Pseudocode (von Claude im Chat)

```
for poll in range(30):  # 30 * 10s = 5 min max
    status = run("cat ~/.codex-codecheck/status.txt", timeout_ms=1500)
    if status.strip() == "done":
        break
    if status.startswith("error:"):
        return show_error(status)
    sleep(10)  # via run("sleep 10", timeout_ms=12000)
else:
    return show_error("Timeout nach 5 min — siehe ~/.codex-codecheck/last.log")
```

Wichtig: `sleep` NICHT in Schleife mit kurzen Intervallen — das blockiert.
Pro Poll genau 1 short cat + 1 sleep 10 = 2 MCP-Calls / 10s.

## Praesentations-Format

```
## CodeCheck: <dateiname> (<zeilen> Zeilen)
Modell: gpt-5.3-codex | Reasoning: high | Fokus: <fokus> | Dauer: 2m43s

[CRITICAL] Zeile XX: Beschreibung
  Fix: Konkreter Vorschlag

[WARNING] Zeile XX: Beschreibung
  Fix: Konkreter Vorschlag

[INFO] Zeile XX: Beschreibung
  Fix: Konkreter Vorschlag

Fazit: <fazit>

Top-3 Massnahmen:
1. ...
2. ...
3. ...
```

## Regeln

1. Niemals Credentials im Chat zeigen
2. Config pruefen vor jedem Run — fehlt sie, /codex:setup anbieten
3. **ALLES via Desktop Commander auf dem Mac** — kein Sandbox-Bash fuer
   File-Ops oder Python-Calls (Sandbox /tmp != Mac /tmp)
4. Async-Pattern fuer alle Calls > 60s (= alle gpt-5.3-codex-Calls!)
5. Dateiinhalt immer ueber `~/.codex-codecheck/input.txt` — nie inline im
   Python-String (Quoting-Hell, Tokens verschwendet)
6. Default-Modell ist gpt-5.3-codex (volles Modell). o4-mini nur wenn User
   "schnell"/"mini" sagt UND File < 300 Zeilen
7. Polling: max 30 Iterationen a 10s = 5 min Timeout. Danach: User fragen
   ob er warten will (`tail ~/.codex-codecheck/last.log` checken).
8. Bei Quota-Error (HTTP 402/429): Runner faellt automatisch auf naechsten
   Key zurueck. Im Chat erwaehnen: "Fallback-Key (label: paid) verwendet."

## Migrations-Hinweise v5 → v6

- Alte Skripte unter `/tmp/codex_*.py` koennen geloescht werden
- `model: o4-mini` Default in alten configs → manuell auf `gpt-5.3-codex` umstellen
  (oder beim naechsten Setup ueberschreiben lassen)
- Neue Pflicht-Felder: `mini_model` (default "o4-mini")
