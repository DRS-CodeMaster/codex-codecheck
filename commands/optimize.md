# /codex:optimize

Dedicated performance optimization analysis. Focuses on speed, memory, efficiency, and scalability.

## Usage

```
/codex:optimize <filepath> [additional_focus]
```

## Arguments

- `filepath` (required): Path to the file to optimize
- `additional_focus` (optional): Extra areas beyond default optimization focus

## Examples

```
/codex:optimize src/query-builder.php
/codex:optimize app/data_processor.py "Memory usage, batch processing"
/codex:optimize api/search.js "Database queries, caching"
```

## Steps

Same as /codex:review but with:
- reasoning_effort: always high (optimization requires deep analysis)
- max_completion_tokens: 32000
- Specialized optimization-focused developer prompt

## Developer Prompt

```
You are a performance optimization expert.
Analyze this code for performance issues and optimization opportunities. Check for:
- Unnecessary database queries (N+1 problem, missing indexes)
- Redundant computations and loops
- Memory inefficiency (large arrays, unclosed resources, memory leaks)
- Missing caching opportunities
- Inefficient string operations
- Blocking I/O that could be async
- Unoptimized regular expressions
- Excessive API calls that could be batched
- Missing pagination for large datasets
- Suboptimal data structures
- Dead code and unused variables
- Opportunity for lazy loading or deferred execution

For each finding, estimate the impact:
- critical: Major performance bottleneck, noticeable user impact
- warning: Measurable inefficiency, should be optimized
- info: Minor optimization opportunity or best practice

Respond ONLY with valid JSON (no Markdown, no backticks):
{"findings": [{"severity": "critical|warning|info", "zeile": INT,
"beschreibung": "...", "fix_vorschlag": "...", "impact": "high|medium|low"}],
"fazit": "...", "top3": ["...", "...", "..."]}
```

## Presentation

Same format as /codex:review but with impact rating:

```
## Optimization: <filename>
Model: o3-mini | Reasoning: high

[CRITICAL] Line XX: Description (Impact: high)
  Fix: Suggestion

[WARNING] Line XX: Description (Impact: medium)
  Fix: Suggestion
```

## Notes

- Optimization always uses reasoning_effort: high regardless of file size
- Findings include impact rating (high/medium/low)
- Multi-file optimization: use /codex:multi with focus "Performance Optimization"