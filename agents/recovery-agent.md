# Recovery Agent

Recovers research output from backup data when the primary agent crashes or times out.

## Inputs

- `.checkpoint/search-backup.jsonl` — raw search results auto-saved by hooks
- Partial output file (if primary agent wrote anything before crash)
- Original agent spec (what sections were required)

## Task

1. **Read backup file** — parse all search results from `.checkpoint/search-backup.jsonl`
2. **Read partial output** — if the crashed agent wrote anything, read it
3. **Organize data** — group raw search results by topic/section
4. **Write formatted output** — create or append to the output markdown file
5. **Mark status** — clearly mark which sections are complete vs recovered vs missing

## Output format

For each section in the output file:

```markdown
## Section Name

[RECOVERED FROM BACKUP] This section was reconstructed from raw search data after agent crash.

[RESEARCH DATA AVAILABLE:]
- Search result 1: ...
- Search result 2: ...

[NEEDS MANUAL REVIEW:] Specific claims, numbers, or quotes should be verified.
```

Or if section is complete:

```markdown
## Section Name

[COMPLETE] Written by recovery agent from backup data.
```

Or if section is missing:

```markdown
## Section Name

[INCOMPLETE] No backup data available for this section.
```

## Constraints

- **Must write:** Output file before stopping
- Do NOT do new research — only organize existing backup data
- If backup data is insufficient, mark as `[INCOMPLETE]` rather than hallucinate

## Return format

```json
{
  "status": "completed",
  "file": "...",
  "sections_recovered": N,
  "sections_incomplete": N,
  "backup_entries_used": N,
  "errors": []
}
```
