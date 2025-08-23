---
mode: "agent"
description: "Retrieve ALL @Me work items (prioritized types first, then fallback) using search_workitem with paging; progressively persist raw + hydrated JSON and output summary table."
---

# Get My Work Items (Full Retrieval, Progressive Raw Export)

You WILL retrieve all work items assigned to the current user (`@Me`) within the specified Azure DevOps project using ONLY the provided Azure DevOps tools. High-level flow: search (with optional fallback) -> progressive raw persistence -> per-item hydration (individual `wit_get_work_item` calls) -> final summary/table. Detailed steps are defined in Phases and Outputs sections.

NO local re-ordering beyond natural server return order. NO reliance on saved queries. DO NOT use `wit_my_work_items` anywhere.

## Inputs

- ${input:project:edge-ai}: Azure DevOps project name or ID (REQUIRED)
- ${input:types:Bug, Task}: Comma-separated prioritized Work Item Types to fetch first (case-insensitive). Default: Bug, Task.
- ${input:fallbackTypes:User Story}: Comma-separated secondary Work Item Types to fetch ONLY IF the first pass returns zero results. Default: User Story.
- ${input:states:Active, New}: (Optional) Comma-separated workflow states to include. If empty, include all states. Default restricts to Active, New.
- ${input:areaPath}: (Optional) Area Path filter. If supplied, include only work items under this Area Path (exact or descendant as supported by search behavior).
- ${input:iterationPath}: (Optional) IterationPath filter. When provided, you MUST append ` IterationPath:"${input:iterationPath}"`to the`searchText` (note the leading space) so that server-side search scopes results to that iteration. Do NOT add if empty.
- ${input:fields}: (Optional) Explicit additional fields to hydrate (beyond defaults) when calling `wit_get_work_item` for each work item.
- ${input:pageSize:200}: Page size for each `search_workitem` call (attempt to use 200; adjust down only if API enforces a lower maximum).

## Outputs

You MUST produce and/or update the following artifacts (referenced in Detailed Required Behavior):

1. Progressive Raw JSON Artifact (Search Phase): `.copilot-tracking/workitems/{YYYYMMDD}-assigned-to-me.raw.json` containing minimal fields for each discovered work item plus search metadata. (See Outputs JSON Structure.)
2. Hydrated JSON (Same File, Updated): Same path; enriched fields merged batch-wise; includes `hydration` status section and completion flags.
3. Conversation Summary Table: Markdown table (ID | Type | Title | Tags | Priority | Stack Rank) with `<br />` inserted for Title wrapping (~70 char boundaries) and between tag tokens.
4. Completion Summary: Count of hydrated work items, JSON file path, whether fallback types were used, and the table (or explicit statement that none were found).

### Outputs JSON Structure (Search Phase Minimal)

```json
{
  "project": "${input:project}",
  "timestamp": "<ISO8601>",
  "usedFallback": false,
  "search": {
    "types": ["Bug", "Task"],
    "fallbackTypes": ["User Story"],
    "states": ["Active", "New"],
    "areaPath": null,
    "iterationPath": null,
    "pageSize": 200,
    "completed": false
  },
  "idsOrdered": [123, 124],
  "items": [
    {
      "id": 123,
      "fields": {
        "System.Id": 123,
        "System.WorkItemType": "Bug",
        "System.Title": "...",
        "System.State": "Active",
        "System.Tags": "...",
        "System.CreatedDate": "...",
        "System.ChangedDate": "..."
      }
    }
  ]
}
```

### Outputs JSON Structure (Post-Hydration Additions)

```json
{
  "hydration": { "remainingIds": [], "completed": true },
  "search": { "completed": true /* other unchanged keys */ }
  /* items now have additional hydrated fields like Priority / StackRank */
}
```

## Phases (Overview)

0. List Dir Existing Workitems (update or create raw file)
1. Build Search Criteria (construct filters & searchText)
2. First Pass Search (prioritized types paging)
3. Fallback Pass (only if first produced zero items)
4. Progressive Raw Persistence (see Outputs)
5. Hydration (individual per-item enrichment)
6. Progressive Hydrated Persistence (status + merge after each item)
7. Final Output Table & Completion Summary

## Minimal Search Field Capture

From each `search_workitem` result you MUST extract and store only these fields initially:

```
System.Id,
System.WorkItemType,
System.Title,
System.State,
System.Tags,
System.CreatedDate,
System.ChangedDate
```

Store them under an `items` array with structure:

```json
{
  "id": <System.Id>,
  "fields": {
    "System.Id": <number>,
    "System.WorkItemType": "",
    "System.Title": "",
    "System.State": "",
    "System.Tags": "",
    "System.CreatedDate": "",
    "System.ChangedDate": ""
  }
}
```

Do NOT include other fields until hydration.

## Default Hydration Fields

Always request (unless user overrides with `${input:fields}` which are added to this set) for EVERY `wit_get_work_item` call:

```json
[
  "System.Id",
  "System.WorkItemType",
  "System.Title",
  "System.State",
  "System.Parent",
  "System.Tags",
  "Microsoft.VSTS.Common.StackRank",
  "Microsoft.VSTS.Common.Priority",
  "Microsoft.VSTS.TCM.ReproSteps",
  "System.AssignedTo",
  "System.ChangedDate",
  "System.CreatedDate"
]
```

You MUST append any user-provided `${input:fields}` (deduplicate) to the default list. Use a single ordered deduplicated list (defaults first, then user extras) for every `wit_get_work_item` call. If some already exist from minimal capture, they remain and will simply be overwritten if server returns a value.

## Detailed Required Behavior

### 0. List Dir Existing Workitems

You must first `list_dir` on `.copilot-tracking/workitems` and identify if there is already an existing `.copilot-tracking/workitems/{YYYYMMDD}-assigned-to-me.raw.json` file that you will be updating (if exists) or creating (if not existing).

### 1. Build Search Criteria

Parse `${input:types}` and `${input:fallbackTypes}` into two ordered, case-insensitive sets (trim whitespace). Parse `${input:states}` similarly (unless blank). Build `searchText` ALWAYS including `a: @Me`. If `${input:iterationPath}` present, append ` IterationPath:"${input:iterationPath}"` exactly (space-prefixed) to `searchText`. (If state filters provided, use `state` parameter; do NOT redundantly embed state text inside `searchText`).

### 2. First Pass Search (Prioritized Types)

Call `search_workitem` repeatedly with:

- `project`: array containing `${input:project}`
- `searchText`: must include `a: @Me`
- `workItemType`: array of prioritized types (parsed from `${input:types}`) OR omit if empty after parsing
- `state`: array of states if provided
- `areaPath`: pass only if `${input:areaPath}` provided
- `top`: `${input:pageSize}`
- `skip`: advance by `${input:pageSize}` until a page returns fewer than `${input:pageSize}` or zero

After each page:

- Append new minimal item objects to in-memory list (skip duplicates by `System.Id`).
- Immediately (progressively) persist updated raw file (see Persistence) so progress survives interruptions.

### 3. Optional Fallback Pass

If, after exhausting paging for prioritized types, zero items were collected, perform the same paging logic using fallback types list (`${input:fallbackTypes}`). Reinitialize paging counters but reuse the SAME output file (overwrite structure with empty items first if not yet written). Mark a boolean `"usedFallback": true` in the JSON (include this key only if fallback was used).

### 4. Progressive Raw Persistence (See Outputs: Progressive Raw JSON Artifact)

File path: `.copilot-tracking/workitems/{YYYYMMDD}-assigned-to-me.raw.json` (UTC date). Ensure folder exists. JSON structure (during search phase, before hydration):

```json
{
  "project": "${input:project}",
  "timestamp": "<ISO8601>",
  "usedFallback": <boolean or omitted>,
  "search": {
    "types": ["..."],
    "fallbackTypes": ["..."],
    "states": ["..."] ,
    "areaPath": "<area or null>",
    "iterationPath": "<iteration or null>",
    "pageSize": <number>,
    "completed": false
  },
  "idsOrdered": [<id,...>],
  "items": [ { "id": <id>, "fields": { /* minimal fields only */ } } ]
}
```

Update after each page: refresh `timestamp`, append to `items`, recalc `idsOrdered` (ordered by initial encounter). Keep `search.completed = false` until hydration finishes.

### 5. Hydration (See Outputs: Hydrated JSON)

After all search pages (and fallback if used) complete AND there is at least one item:

- Initialize `hydration.remainingIds` to all `idsOrdered` (if not already present) and persist.
- Iterate `idsOrdered` in order. For each id, call `wit_get_work_item` with the full deduplicated field list.
- Merge returned field values into the corresponding `items[i].fields` (do not remove previously stored minimal fields).
- After EACH successful item hydration, remove that id from `hydration.remainingIds`, update `timestamp`, and persist (Progressive Hydrated Persistence).
- Preserve original ordering: DO NOT reorder `idsOrdered` or `items`; only augment fields. If a `wit_get_work_item` call fails, surface the error and stop (leave remaining ids intact for potential retry in a subsequent run).

### 6. Progressive Hydrated Persistence (See Outputs: Hydrated JSON)

Same file path. Add or update:

- `hydration`: { "remainingIds": [<ids not yet hydrated>], "completed": false }
- After EACH successful `wit_get_work_item` call, remove the hydrated id from `remainingIds` and persist.
- When `remainingIds` becomes empty: set `hydration.completed = true` and `search.completed = true`.
- Ensure final JSON includes `Microsoft.VSTS.Common.Priority` and `Microsoft.VSTS.Common.StackRank` when present (some types may omit one or both - retain null/undefined absence rather than fabricating default values).

### 7. Final Output Table (See Outputs: Conversation Summary Table)

After hydration completes (or if zero items found), output to the conversation:

- A markdown table with columns: ID | Type | Title | Tags | Priority | Stack Rank
- For Title: Replace long text by inserting `<br />` every ~70 characters at natural space boundaries (best-effort) to wrap.
- For Tags: If empty or null, leave cell blank. Otherwise split semicolon- or comma-delimited tag strings (trim whitespace) into separate lines joined by `<br />`.
- If Priority or Stack Rank missing, display `-`.

### Error Handling

- If any tool call fails, surface the raw error content and stop further processing (persist whatever progress already written if possible before aborting).
- If all searches return zero items, write a valid JSON file with empty arrays and mark both `search.completed` and `hydration.completed` = true, then output an empty table notice.

## Edge Cases & Rules

- Duplicate IDs across pages MUST NOT produce duplicate entries (ignore subsequent occurrences).
- Case-insensitive matching for type and state inputs; preserve original server-returned casing in stored fields.
- If `${input:states}` is empty or omitted, do not pass the `state` parameter (retrieve all states, then store them as-is).
- If both prioritized and fallback passes are empty, do not perform hydration phase.
- NEVER invoke `wit_my_work_items`, `wit_get_query`, or `wit_get_query_results_by_id` in this prompt.
- ALWAYS progressively persist after each page and each individual hydration call.

## Final JSON (Post-Hydration) Example (abridged)

```json
{
  "project": "edge-ai",
  "timestamp": "2025-08-22T12:34:56Z",
  "search": {
    "completed": true,
    "pageSize": 200,
    "types": ["Bug", "Task"],
    "fallbackTypes": ["User Story"],
    "states": ["Active", "New"],
    "areaPath": null,
    "iterationPath": null
  },
  "hydration": { "completed": true },
  "idsOrdered": [123, 124],
  "items": [
    {
      "id": 123,
      "fields": {
        "System.Id": 123,
        "System.WorkItemType": "Bug",
        "System.Title": "Fix critical race condition in data pipeline",
        "System.State": "Active",
        "System.Tags": "backend;performance",
        "System.CreatedDate": "2025-08-20T10:11:12Z",
        "System.ChangedDate": "2025-08-22T09:05:00Z",
        "Microsoft.VSTS.Common.Priority": 1,
        "Microsoft.VSTS.Common.StackRank": 12345
      }
    }
  ]
}
```

## Completion Summary Requirements (See Outputs: Completion Summary)

When done, provide:

- Count of work items hydrated
- Path to JSON file
- Whether fallback types were used
- The markdown table described above (or a statement that none were found)

## Compliance Checklist (Self-Evaluate Before Responding)

- [ ] No disallowed tools used (`wit_my_work_items`, query tools)
- [ ] Paging implemented for full retrieval
- [ ] Progressive persistence after each page & each individual hydration call
- [ ] Minimal fields captured before hydration
- [ ] Hydration merges additional fields (priority, stack rank, etc.) via per-item `wit_get_work_item`
- [ ] Ordering preserved during hydration (no reordering of idsOrdered/items)
- [ ] Fallback logic executed only if first pass empty
- [ ] Output table with `<br />` formatting for Title/Tags
- [ ] Empty / null tags produce blank cell (no placeholders)
- [ ] JSON includes completion flags
- [ ] No client-side reordering
- [ ] IterationPath appended to searchText only when input provided
- [ ] Outputs section artifacts produced (raw JSON, hydrated JSON updates, summary table, completion summary)
