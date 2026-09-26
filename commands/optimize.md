# /codex:optimize

Dedicated performance analysis: speed, memory, efficiency, scalability.

## Usage

```
/codex:optimize <filepath> [additional_focus]
```

## Examples

```
/codex:optimize src/query-builder.php
/codex:optimize app/data_processor.py "memory usage, batch processing"
```

## Steps

Follow the workflow in SKILL.md with:
- **Role:** performance optimization expert
- **Mode:** `optimize` (reasoning high)
- **Focus:** N+1 queries and missing indexes · redundant computation and loops · memory
  inefficiency and leaks · missing caching · blocking I/O that could be async · expensive
  regular expressions · API calls that could be batched · missing pagination · unsuitable data
  structures · dead code · lazy-loading opportunities
- **Severity:** critical = major bottleneck with user impact · warning = measurable
  inefficiency · info = minor opportunity. `reference` = impact high / medium / low.
- **Run:** `~/.codex-codecheck/codex-run.sh optimize <folder of the file>`
