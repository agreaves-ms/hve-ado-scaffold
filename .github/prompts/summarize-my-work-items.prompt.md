---
mode: 'agent'
description: 'Summarize @Me work items from raw JSON and enrich with repo context'
---

# Summarize My Work Items (Resumable, With Repo Context)

You WILL read the latest raw JSON produced by `get-my-work-items` and generate a resumable summary markdown. You WILL enrich each item with repository context by scanning code and docs. You WILL present a full summary for the top recommended item and brief summaries for the rest.

## Inputs
- ${input:rawPath}: Optional path to a specific raw file. If omitted, you WILL use the most recent `.copilot-tracking/workitems/*-assigned-to-me.raw.json`, must use list_dir on `.copilot-tracking/workitems/`.
- ${input:summaryPath}: Optional output path. If omitted, you WILL write to `.copilot-tracking/workitems/YYYYMMDD-assigned-to-me.summary.md`, must use list_dir on `.copilot-tracking/workitems/` (matching the raw file date when available).
- ${input:maxItems:all}: Optional cap on items summarized in this run (default all).

## Resumable Behavior
- If the summary file already exists, you WILL load it and determine which work item IDs are already summarized.
- You WILL append new summaries for remaining items without duplicating existing entries.
- You WILL preserve existing sections and formatting.

## Summarization Content Per Item
For each item (in the server-side order from raw JSON):
- Include: `Id`, `WorkItemType`, `Title`, `State`, `Priority`, `StackRank`, `Tags`, `AssignedTo`, `ChangedDate`, `Description`, `AcceptanceCriteria`, and `Parent` (if present).
- Important details: call-outs that influence effort/sequence (e.g., blocked state, parent linkage).
- Comments: summarize the comments (author and short excerpt) to capture context or blockers. Extract any stack traces or error snippets if present.
- Stack Traces: any captured stack traces.
- Error or Issue: any captured errors.
- Repository context:
  - Derive keywords from `Title`, `Tags`, `Description`, `AcceptanceCriteria`, `WorkItemType`, any captured stack traces, and clues from comments.
  - Search the workspace for relevant files and references. Prefer exact matches, then keywords.
  - Record at most the top 10 relevant file paths with a 1-line rationale each (first header/comment line or a short heuristic).
  - Provide additional summary for all other related files.
  - Provide helpful summary for implementation details.

## Required Output Structure (Summary Markdown)
- Title: `Assigned to Me - Summary (YYYY-MM-DD)`
- Section: `Top Recommendation`
  - Full summary for the most relevant item to work on next. Default: first item from raw JSON order. You MAY boost an item if repo signals indicate strong relevance (more matches, critical tags).
- Section: `Other Items`
  - Bulleted list or short subsections with 2-3 line summaries, including key fields and 1-3 relevant file paths.
- Section: `Progress`
  - IDs summarized so far and remaining IDs (for resumability).
- Section: `Next Step - Deep Research with task-researcher`
  - Suggest the user start a new conversation using `task-researcher.chatmode.md` to perform deeper technical research and planning.
  - Must output an explicit "Handoff Payload" for the user to copy-paste into the new conversation. The Handoff Payload MUST be EXACTLY the contents of the generated `.summary.json` for this run, with NO additional fields.
  - The Handoff Payload MUST include:
    - `topRecommendation`: the primary item to work on next
    - `handoffPayloads`: a list of per-item payloads for every other summarized work item (so the user can choose any single item to research)
  - Allowed fields per item (applies to `topRecommendation` and entries under `handoffPayloads`):
    - `id` (work item id)
    - `workItemType`
    - `title`
    - `description`
    - `acceptanceCriteria`
    - `commentsRelevant` (only relevant excerpts from comments)
    - `stackTraces` (if present)
    - `errorsOrIssues` (if present; concise messages or excerpts)
    - `discoveredInfo` (all information discovered during summarization, including repository matches, notes, or context distilled by this prompt)
      - Within `discoveredInfo`, you MAY include:
        - `repoPaths`: array of objects `{ path, why }` listing the top relevant files
        - `otherRelatedFilesSummary`: array of short lines summarizing other related files not listed in `repoPaths`
        - `implementationDetails`: array of short, actionable implementation notes gleaned from the repository and comments
        - `notes`: array of additional key insights
    - `relatedItems`: array of closely related items (use the same allowed fields except `relatedItems` to avoid deep nesting)
  - Instruct the user clearly: "Start a NEW conversation with task-researcher and paste the Handoff Payload EXACTLY as shown (the full contents of the .summary.json file). You may also copy a single item payload from `handoffPayloads` if you prefer to research a different item."

## Machine-Readable Summary (summary.json)
You WILL also produce a machine-readable JSON artifact alongside the markdown summary. Write to `.copilot-tracking/workitems/YYYYMMDD-assigned-to-me.summary.json` (match the date used for the markdown file). The JSON MUST contain ONLY the allowed fields per item and no others, and MUST enable both the top recommendation and alternative single-item handoffs. Use this shape:

<!-- <schema-summary-json> -->
```json
{
  "date": "YYYY-MM-DD",
  "topRecommendation": {
    "id": 0,
    "workItemType": "",
    "title": "",
    "description": "",
    "acceptanceCriteria": "",
    "commentsRelevant": [
      { "excerpt": "", "attribution": "Author <email>", "date": "YYYY-MM-DD" }
    ],
    "stackTraces": ["<trace line 1>\n<trace line 2>"],
    "errorsOrIssues": ["short error description or excerpt"],
    "discoveredInfo": {
      "repoPaths": [{ "path": "src/...", "why": "short rationale" }],
      "otherRelatedFilesSummary": ["file pattern or folder - why relevant"],
      "implementationDetails": ["helpful implementation detail 1", "detail 2"],
      "notes": ["key insight 1", "key insight 2"]
    },
    "relatedItems": [
      { "id": 0, "workItemType": "", "title": "", "description": "", "acceptanceCriteria": "", "commentsRelevant": [], "stackTraces": [], "errorsOrIssues": [], "discoveredInfo": { "repoPaths": [], "otherRelatedFilesSummary": [], "implementationDetails": [], "notes": [] } }
    ]
  },
  "handoffPayloads": [
    { "id": 0, "workItemType": "", "title": "", "description": "", "acceptanceCriteria": "", "commentsRelevant": [], "stackTraces": [], "errorsOrIssues": [], "discoveredInfo": { "repoPaths": [], "otherRelatedFilesSummary": [], "implementationDetails": [], "notes": [] },
      "relatedItems": [ { "id": 0, "workItemType": "", "title": "", "description": "", "acceptanceCriteria": "", "commentsRelevant": [], "stackTraces": [], "errorsOrIssues": [], "discoveredInfo": { "repoPaths": [], "otherRelatedFilesSummary": [], "implementationDetails": [], "notes": [] } } ]
    }
  ]
}
```
<!-- </schema-summary-json> -->
Notes:
- `handoffPayloads` MUST include an entry for every summarized work item other than the `topRecommendation`, so users can copy any single payload.
- `relatedItems` MUST list closely related tasks (for example: same Parent/Epic/Feature or directly linked items) to provide optional, contextual multi-item research.
- Keep `commentsRelevant` concise, focusing only on actionable or context-setting excerpts. Include `stackTraces` only when observed.
- Include `errorsOrIssues` when there are explicit errors, exceptions, or user-reported issues; keep excerpts short and informative.
- Use `discoveredInfo.otherRelatedFilesSummary` for summarizing relevant files beyond the top list, and `discoveredInfo.implementationDetails` for practical notes that will help implementation.

## File Operations
1. Load raw JSON from `${input:rawPath}` or discover the latest file.
2. Prepare/update `${input:summaryPath}`; ensure `.copilot-tracking/workitems/` exists.
3. Write or append summaries as described. Maintain idempotency across runs.
4. Also write `.copilot-tracking/workitems/YYYYMMDD-assigned-to-me.summary.json` using only the allowed fields defined above, including `topRecommendation` and `handoffPayloads` (each with their own `relatedItems`).
5. Print the final `${input:summaryPath}` and the path to the `.summary.json` file, plus counts of summarized vs remaining items.

## Edge Cases
- Raw file missing or empty: inform the user and stop.
- No repository matches: still produce summaries; mark `No strong file matches found` under relevant files.
- Interrupted runs: subsequent runs MUST pick up remaining items without duplication.
